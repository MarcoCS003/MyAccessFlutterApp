Hallazgo clave: el primer envío devolvió "error":"NotRegistered", y tras refrescar la sesión en el dispositivo, el segundo devolvió success:true. Eso confirma exactamente la causa raíz.
Causa raíz
El token FCM del dispositivo caducó/no estaba actualizado en el usuario padre (marcocarrascodev@gmail.com). Cuando el token de FCM ya no es válido, Firebase responde NotRegistered. Al refrescar la sesión en la app, esta reenvió el fcm_token nuevo al backend (vía login o updateFcmToken), y a partir de ahí los pushes llegaron.
Por eso las del maestro sí llegaban (la cuenta maestra sí tenía su token vigente) y las del padre no: mismo dispositivo, dos cuentas, cada una con su propio fcm_token; el del padre estaba obsoleto.
Por qué importa y cómo evitarlo
El código ya maneja parte de esto: en FcmNotificationService::sendToDevice, cuando el error contiene UNREGISTERED, se llama a clearToken() que pone fcm_token = null. Pero Firebase aquí respondió NotRegistered (no UNREGISTERED), y str_contains($errorMessage, 'UNREGISTERED') no lo detecta → el token obsoleto se queda en la BD y el usuario deja de recibir notificaciones hasta que la app lo refresca.
Dos recomendaciones (sin tocar dependencias):
1. Ampliar la limpieza de token para cubrir también NotRegistered:
if (str_contains($errorMessage, 'UNREGISTERED') || str_contains($errorMessage, 'NotRegistered')) {
    $this->clearToken($fcmToken);
}
Así, cuando un token caduque, el backend lo limpia y la app vuelve a mandar uno nuevo al hacer login.
2. Asegurar que la app envíe el fcm_token en cada login (ya lo hace AuthController::login línea 72-73), y que al abrir la app llame a updateFcmToken si el token cambió (Firebase lo rota periódicamente).
¿Quieres que aplique el fix del punto 1 (ampliar clearToken para NotRegistered) con su test?