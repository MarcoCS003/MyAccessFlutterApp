# Reporte técnico: Envío de notificaciones push vía FCM

Fecha: 2026-07-18 · Basado en lectura estática del código (con referencias `archivo:línea`). No se ejecutó un envío real contra FCM.

## 1. Arquitectura general

El envío de push usa **FCM HTTP v1 API** de forma manual: sin SDK de Firebase para PHP (no hay `kreait/firebase-php`); se obtiene un access token OAuth2 con `google/auth` (^1.50, `composer.json:13`) y se hace `POST` con `Http` de Laravel.

Existen **dos mecanismos coexistiendo**, pero solo el primero se usa en la práctica:

| Mecanismo | Componentes | Estado |
|---|---|---|
| Job + Service | `SendAttendancePushJob` → `FcmNotificationService` | **Activo** (asistencias) |
| Canal de notificaciones | `FcmChannel` + `toFcm()` en Notifications | **Sin llamadores reales** |

### Flujo activo (asistencias)

```
POST /api/access  ──►  StudentAttendance/TeacherAttendance::create()
(AccessController.php:95,110)            │
                                         ▼
              Observer created()  ──►  SendAttendancePushJob::dispatch()
              (StudentAttendanceObserver.php:36,     cola "notifications"
               TeacherAttendanceObserver.php:31)            │
                                                            ▼
                              queue:work --queue=notifications,default
                                                            │
                                                            ▼
                              FcmNotificationService::sendToUsers/sendToDevice()
                              (app/Services/FcmNotificationService.php:27)
                                                            │
                                                            ▼
                         POST https://fcm.googleapis.com/v1/projects/{project_id}/messages:send
```

También disparan asistencias (y por tanto push) los comandos `ProcessHolidays.php:50` y `GenerateManualTeacherAttendance.php:76`, y `TeacherAttendancesTable.php:148` (solo teachers). En esos casos el envío viene **solo del observer**; en `/api/access` hay un **segundo dispatch idéntico** desde `AccessController::enqueueAttendancePush()` (`AccessController.php:119,152,181`) — ver §6.

### Flujo por canal Laravel (no usado)

`app/Channels/FcmChannel.php` usa `routeNotificationForFcm()` + `$notification->toFcm()`. No se activa nunca en el flujo de asistencias: los `via()` de `TeacherAttendanceNotification.php:35` y `StudentAttendanceNotification.php:38` solo añaden `FcmChannel` si el notifiable es `User`, pero los observers notifican a `Teacher` (`TeacherAttendanceObserver.php:47`) y `Guardian` (`StudentAttendanceObserver.php:55`). `SendPushNotification` no tiene ningún llamador en el código.

### Endpoint de prueba

`POST /api/send-push` → `NotificationController::sendPush()` (`app/Http/Controllers/NotificationController.php:12`) → `FcmNotificationService::sendToDevice()`, **síncrono y sin autenticación** (`routes/api.php:19`).

## 2. Entradas (inputs)

### Endpoints de tokens FCM

| Método / URI | Auth | Controller@método | Payload validado | Respuesta |
|---|---|---|---|---|
| `POST /api/auth/register` (alias `POST /api/register`) | no | `AuthController@register` (`AuthController.php:23`) | `name` req · `email` req/unique · `password` req/confirmed · `role` req (solo `parent`) · `teacher_id` nullable · **`fcm_token` nullable\|string** (`:31`) | 201 `{user, access_token}` |
| `POST /api/auth/login` (alias `POST /api/login`) | `throttle:login` | `AuthController@login` (`:56`) | `email`, `password`, **`fcm_token` nullable\|string** (`:61`); si viene, sobrescribe `users.fcm_token` (`:72`) | 200 `{user, access_token}` · 401 credenciales |
| `POST /api/update-fcm-token` | `auth:sanctum` | `AuthController@updateFcmToken` (`:88`) | **`fcm_token` required\|string** (`:91`) | 200 `{message: "FCM token actualizado exitosamente"}` |
| `POST /api/send-push` | **no** | `NotificationController@sendPush` | sin `validate()`: `token` (req manual, 400 si falta), `title` (default "¡Hola desde Laravel 12!"), `body` (default "Esta es una notificación push de prueba."), `data` array opcional | 200 `{name: message_id}` · 400/500 `{error}` |

**No existe** endpoint para eliminar el token ni logout API; la limpieza solo ocurre automáticamente cuando FCM responde `UNREGISTERED`.

### Almacenamiento de tokens

- Tabla `users`, columna **`fcm_token` VARCHAR nullable** — un solo token por usuario, se sobrescribe en cada login (`database/migrations/2026_03_17_132212_add_fcm_token_to_users_table.php:14`).
- Incluido en `User::$fillable` (`app/Models/User.php:34`).
- Destinatarios de una asistencia:
  - Alumno → `User::students()` belongsToMany por pivot `student_user` (`User.php:88`; `Student.php:306`).
  - Profesor → `Teacher::users()` hasMany por `users.teacher_id` (`Teacher.php:183`).

### Entradas del Job

`SendAttendancePushJob::__construct(array $userIds, string $title, string $body, array $data = [])` (`app/Jobs/SendAttendancePushJob.php:24`).

| Campo de `data` | Student | Teacher |
|---|---|---|
| `type` | `student_attendance` | `teacher_attendance` |
| id | `student_id` (string) | `teacher_id` (string) |
| `attendance_type` | `entry` \| `exit` | `entry` \| `exit` |
| `recorded_at` | ISO8601 | ISO8601 |

## 3. Salidas (outputs)

### Payload exacto enviado a FCM (`FcmNotificationService.php:41-65`)

```json
{
  "message": {
    "token": "<fcm_token del usuario>",
    "notification": { "title": "...", "body": "..." },
    "data": { "type": "student_attendance", "student_id": "10", "attendance_type": "exit", "recorded_at": "2026-07-18T14:32:00-06:00" },
    "android": {
      "priority": "high",
      "notification": { "channel_id": "default", "sound": "default" }
    },
    "apns": { "payload": { "aps": { "sound": "default", "badge": 1 } } }
  }
}
```

- Todos los valores de `data` se convierten a string (`array_map('strval')`) y el array se castea a objeto para que vacío serialice como `{}` (`:48`).
- **Destinatarios**: siempre token individual, un POST por usuario (`sendToUsers`, `:148`). No hay topics ni multicast.

### Ejemplos de título/cuerpo

| Caso | title | body |
|---|---|---|
| Salida de alumno | `Salida de Pedro Pérez` | `Pedro Pérez registró Salida a las 14:32` |
| Entrada de profesor | `Entrada registrada` | `Nombre Apellido — 07:30` |

### Manejo de la respuesta de FCM

- **Éxito**: `Log::info('Push enviado exitosamente', ...)` con token truncado a 12 chars y `name` (message id) (`:75`). Retorna `{success, message_id, error}`.
- **Fallo HTTP**: `Log::error('Error enviando push FCM', [status, error])` (`:90`). Si el mensaje contiene **`UNREGISTERED`, se limpia el token** (`users.fcm_token = null`, `:95`, `clearToken()` `:199`).
- **Excepción**: `Log::error('Excepción enviando push: ...')` (`:105`). Sin reintentos a nivel servicio.
- El job loguea `warning` ante fallos parciales (`SendAttendancePushJob.php:57`).

## 4. Configuración y colas

- `config/services.php:47`: `services.firebase.project_id` (env `FIREBASE_PROJECT_ID`, default `notificacionesapptutores`) y `services.firebase.credentials_path` (env `FIREBASE_CREDENTIALS_PATH`; default del Service: `storage/app/firebase/credentials.json`, `FcmNotificationService.php:19`). Ambas en `.env.example:78-79`.
- Access token OAuth2 cacheado **3300 s (55 min)** en clave `fcm_access_token` (`FcmNotificationService.php:175`).
- Settings en BD (gestionables en Filament `app/Filament/Pages/Settings.php:78-91`): `fcm_notifications_enabled`, `fcm_notifications_students_enabled`, `fcm_notifications_teachers_enabled`, más toggles por nivel `student_notifications_level_{nivel}_enabled`.
- Cola: `QUEUE_CONNECTION=database` por defecto (`config/queue.php:16`). El job va a la cola **`notifications`**; el worker activo corre con `--queue=notifications,default --tries=1`.

## 5. Inconsistencias detectadas

### Internas del código (más relevantes)

1. **Push duplicado en `/api/access`**: el `create()` dispara el observer (job nº 1) y `AccessController.php:119` despacha un segundo job idéntico (`:152` teacher, `:181` student). Cada escaneo QR envía **dos notificaciones iguales** al mismo usuario.
2. **`enqueueAttendancePush()` ignora los toggles** (`AccessController.php:135-192`): no consulta ningún `Setting`. Los observers sí consultan `fcm_notifications_students/teachers_enabled`, pero **nadie consulta el master `fcm_notifications_enabled`**. Apagar FCM en Filament solo elimina uno de los dos envíos duplicados.
3. **Toggles por nivel ignorados**: `student_notifications_level_*_enabled` solo se lee en `StudentAttendanceNotification::via():43`, camino por el que nunca pasa el FCM real.
4. **Camino FcmChannel roto si se usara**: los `toFcm()` de ambas attendance notifications no envuelven en `message` e incluyen `sound` dentro de `notification` (inválido en FCM v1); `FcmChannel.php:51` espera `$messageData['message']['token']`. `SendPushNotification` sí envuelve en `message` — dos formatos incompatibles para el mismo canal.
5. **Código muerto**: `SendPushNotification`, `FcmNotificationService::sendToTeacher()` y `sendToAll()`, `Teacher::routeNotificationForFcm()` y `Guardian::routeNotificationForFcm()` (devuelve `null`, `Guardian.php:30`).
6. **`/api/send-push` público**: cualquiera puede enviar pushes arbitrarios a cualquier token.
7. **Un solo token por usuario**: login desde un segundo dispositivo deja al primero sin pushes.

### Código vs. documentación existente

| Doc | Afirma | Realidad |
|---|---|---|
| `API_DOCUMENTATION.md:228,356` | Existe `POST /api/auth/google-login` (con `fcm_token`) | No existe la ruta ni el método |
| `fcm-notification-flow.md:163-181` | `data` con `event`, `student_name`, `timestamp`, `screen` | El flujo real envía `{type, student_id\|teacher_id, attendance_type, recorded_at}` (claves del `toFcm()` muerto) |
| `fcm-notification-flow.md:224` | `User::$fillable` incluye `avatar` | No lo incluye (`User.php:34`) |
| `fcm-notification-flow.md:293` | Notifications "duales FCM + WhatsApp" | Por el flujo actual nunca emiten FCM (notifiable no es `User`) |
| `documentacion_firebase_notificaciones.md:55` | Caché del access token "1 hora" | 3300 s = 55 min |
| `config_notificaciones_FCM.md:15` | Faltan los toggles FCM en Filament Settings | Ya implementados (`Settings.php:78-91`) — doc obsoleto |
| `procesos_cola.md:27` | Sin `QUEUE_CONNECTION` los jobs corren síncronos | El default es `database` |
| `procesos_cola.md:111` | "Timeout 90s" | Es `retry_after: 90` (`config/queue.php:43`), no timeout del job |
| `API_DOCUMENTATION.md:428` | Error 500 "Firebase credentials file not found" en `/api/send-push` | El service devuelve "No se pudo obtener access token de Firebase" |
