# Guia de implementacion de correos con MailerSend

## Objetivo

Este documento describe **todo el flujo real usado en este proyecto** para enviar correos con MailerSend en Laravel 12, incluyendo:

- paquetes instalados,
- variables de entorno,
- configuracion Laravel,
- disparadores (observers, listeners, commands y controllers),
- templates/mensajes,
- colas,
- y logging de resultado en base de datos.

---

## 1) Paquetes usados en este proyecto

En `composer.json` se usa el driver oficial de MailerSend para Laravel:

- `mailersend/laravel-driver:^3.1`

Tambien existen dependencias de transporte HTTP que ayudan al ecosistema de mail/transports:

- `symfony/http-client`
- `nyholm/psr7`
- `php-http/guzzle7-adapter`

Referencia:

- `composer.json`

---

## 2) Variables .env necesarias

En `.env.example` se define que el mailer por defecto es MailerSend:

```env
MAIL_MAILER=mailersend
MAIL_FROM_ADDRESS="checador@ijl.com.mx"
MAIL_FROM_NAME="${APP_NAME}"
MAILERSEND_API_KEY=
```

### Importante sobre secretos

- `MAILERSEND_API_KEY` es un **dato secreto** en `.env`.
- No debe subirse a git ni documentarse con su valor real.
- Solo se documenta su existencia y uso.

Referencias:

- `.env.example`

---

## 3) Configuracion Laravel para MailerSend

### 3.1 Mailer por defecto y mailer `mailersend`

Archivo: `config/mail.php`

- `default` usa `env('MAIL_MAILER', 'mailersend')`
- existe el mailer:

```php
'mailersend' => [
    'transport' => 'mailersend',
],
```

### 3.2 Credencial del servicio

Archivo: `config/services.php`

```php
'mailersend' => [
    'key' => env('MAILERSEND_API_KEY'),
],
```

Con esto, el driver toma el API key desde `.env`.

---

## 4) Requisito externo en MailerSend

Aunque no vive en el codigo, para que funcione en produccion:

1. Crear API token en MailerSend.
2. Verificar dominio/remitente en MailerSend.
3. Asegurar que `MAIL_FROM_ADDRESS` pertenezca a un dominio/identidad valida en MailerSend.

---

## 5) Flujo general de envio de correo en este proyecto

Patron general:

1. Ocurre un evento del negocio (crear usuario, asistencia, comando, accion manual).
2. Se dispara `notify(...)` o `Mail::to(...)->send(...)`.
3. Laravel usa el mailer por defecto (`mailersend`).
4. Si es Notification con `ShouldQueue`, el trabajo entra a la cola.
5. `LogEmailNotification` registra estado en tabla `email_logs`.

---

## 6) Disparadores y flujos implementados

## 6.1 Notificaciones por asistencia de maestros (Notification + mail)

### Trigger

- Observer `TeacherAttendanceObserver@created` envia:
  - `TeacherAttendanceNotification`

Archivo:

- `app/Observers/TeacherAttendanceObserver.php`

### Notification

Archivo: `app/Notifications/TeacherAttendanceNotification.php`

- Implementa `ShouldQueue`.
- `via()` habilita canal `mail` solo si:
  - `settings.email_notifications_enabled = true`
  - `settings.email_notifications_teachers_enabled = true`
  - el notifiable tiene email.
- `toMail()` arma asunto y contenido dinamico (entrada/salida, horario, estatus).

### Modelo notifiable

- `Teacher` usa trait `Notifiable`.

Archivo:

- `app/Models/Teacher.php`

---

## 6.2 Notificacion por falta de entrada (command + Notification mail)

### Trigger manual/programado

- Comando: `app:notify-missing-teacher-attendance`
- Clase: `NotifyMissingTeacherAttendance`

Archivo:

- `app/Console/Commands/NotifyMissingTeacherAttendance.php`

Hace query de maestros sin entrada hoy y para cada uno ejecuta:

- `$teacher->notify(new TeacherMissingAttendanceNotification);`

### Notification

Archivo: `app/Notifications/TeacherMissingAttendanceNotification.php`

- Implementa `ShouldQueue`.
- Solo canal `mail` bajo las mismas banderas de settings y con email.

---

## 6.3 Notificacion por falta de salida (command + Notification mail)

### Trigger manual/programado

- Comando: `app:notify-missing-teacher-checkout`
- Clase: `NotifyMissingTeacherCheckout`

Archivo:

- `app/Console/Commands/NotifyMissingTeacherCheckout.php`

Detecta maestros con entrada pero sin salida y envia:

- `$teacher->notify(new TeacherMissingCheckoutNotification);`

### Notification

Archivo: `app/Notifications/TeacherMissingCheckoutNotification.php`

- Implementa `ShouldQueue`.
- Usa canal `mail` segun settings + email.

---

## 6.4 Correo de bienvenida de usuario (evento Registered + Notification mail)

### Flujo

1. Al crear usuario en Filament (`CreateUser`), se dispara evento `Registered`.
2. Existe listener `SendWelcomeNotification` que llama:
   - `$event->user->notify(new WelcomeNotification(...));`
3. `WelcomeNotification` usa canal `mail` e implementa `ShouldQueue`.

Archivos:

- `app/Filament/Resources/Users/Pages/CreateUser.php`
- `app/Listeners/SendWelcomeNotification.php`
- `app/Notifications/WelcomeNotification.php`
- `app/Actions/Fortify/CreateNewUser.php` (tambien guarda password plano en memoria para el correo de bienvenida)

> Nota: este correo incluye credenciales en el mensaje. Debe tratarse como informacion sensible.

---

## 6.5 Envio de QR por correo (Controller + Mailable)

### Trigger HTTP

- Ruta POST: `teachers/{teacher}/send-qr`
- Metodo: `TeacherController@sendQr`

Archivos:

- `routes/web.php`
- `app/Http/Controllers/TeacherController.php`

### Envio

```php
Mail::to($teacher->email)->send(new TeacherQrMail($teacher));
```

Mailable:

- `app/Mail/TeacherQrMail.php`
  - subject: `Tu Codigo QR de Acceso`
  - markdown view: `emails.teachers.qr`
  - adjunta PNG del QR generado dinamicamente.

Vista:

- `resources/views/emails/teachers/qr.blade.php`

---

## 6.6 Envio de resumen de asistencia (Command + Mailable)

### Trigger

- Comando: `attendance:send-report`
- Clase: `SendAttendanceSummaryReport`

Archivo:

- `app/Console/Commands/SendAttendanceSummaryReport.php`

### Flujo

1. Ejecuta `attendance:summary`.
2. Construye colecciones de resumen/ausentes/retardos.
3. Toma destinatarios desde `config('settings.correos_informe')`.
4. Envia mailable:

```php
Mail::to($recipients)->send(new AttendanceSummaryReport(...));
```

Mailable + vista:

- `app/Mail/AttendanceSummaryReport.php`
- `resources/views/emails/attendance-summary.blade.php`
- correos destino en `config/settings.php` (`correos_informe`).

---

## 7) Activacion/desactivacion funcional desde Settings

La pagina Filament de configuracion controla banderas en tabla `settings`:

- `email_notifications_enabled`
- `email_notifications_teachers_enabled`

Archivo:

- `app/Filament/Pages/Settings.php`

Modelo helper para persistencia:

- `app/Models/Setting.php`

Migracion de tabla:

- `database/migrations/2026_02_13_103523_create_settings_table.php`

---

## 8) Logging y trazabilidad de correos

Se registra estado de notificaciones de correo en DB:

- Listener: `LogEmailNotification`
- Eventos escuchados:
  - `NotificationSending`
  - `NotificationSent`
  - `NotificationFailed`
- Estados usados en `email_logs`:
  - `queued`
  - `sent`
  - `failed`

Archivos:

- `app/Listeners/LogEmailNotification.php`
- `app/Providers/AppServiceProvider.php` (registro de listeners)
- `app/Models/EmailLog.php`
- `database/migrations/2026_02_02_154543_create_email_logs_table.php`
- `database/migrations/2026_02_16_131058_add_body_to_email_logs_table.php`

UI de consulta en panel Filament:

- `app/Filament/Resources/EmailLogs/EmailLogResource.php`

---

## 9) Colas: requisito para que `ShouldQueue` funcione

Muchas notificaciones de correo implementan `ShouldQueue`, por lo tanto:

- `QUEUE_CONNECTION=database` (en `.env.example`)
- migracion de jobs existente:
  - `database/migrations/0001_01_01_000002_create_jobs_table.php`

Debes tener un worker corriendo:

```bash
php artisan queue:work
```

En desarrollo, el script `composer dev` ya levanta cola con `queue:listen`.

---

## 10) Programacion automatica (scheduler)

En `routes/console.php` ya estan definidos cron jobs relacionados con correos:

- `attendance:send-report`
- `app:notify-missing-teacher-attendance`
- `app:notify-missing-teacher-checkout` (actualmente comentado)

Para que corran en servidor, se requiere el cron del scheduler de Laravel (`schedule:run`).

---

## 11) Checklist rapido de implementacion en un ambiente nuevo

1. Instalar dependencias Composer.
2. Configurar `.env` con:
   - `MAIL_MAILER=mailersend`
   - `MAIL_FROM_ADDRESS`
   - `MAIL_FROM_NAME`
   - `MAILERSEND_API_KEY` (secreto)
3. Verificar dominio/remitente en MailerSend.
4. Ejecutar migraciones (`settings`, `jobs`, `email_logs`, etc).
5. Levantar worker de cola (`queue:work`).
6. Verificar toggles de correo en pagina de Settings.
7. Probar un flujo real:
   - crear usuario (WelcomeNotification), o
   - enviar QR desde maestros, o
   - correr `attendance:send-report`.
8. Confirmar resultado en `email_logs` (Filament Resource: Registros de Correo).

---

## 12) Comandos utiles de prueba

```bash
php artisan config:clear
php artisan cache:clear
php artisan queue:work
php artisan attendance:send-report
php artisan app:notify-missing-teacher-attendance
```

Si no se reflejan cambios de frontend en panel, ejecutar build/dev segun entorno.
