# Reglas ProGuard/R8 para builds release con minify activado.
# NOTA: actualmente el release corre con shrink=false (ver gradle.properties)
# porque R8/shrinkResources de Flutter 3.44 eliminaba los recursos de
# google-services y Firebase no inicializaba. Estas reglas son el punto de
# partida para reactivar minify en el futuro; requieren validación en físico.

# --- Firebase / Google Play Services ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Crashlytics necesita los nombres de clase/line numbers para desofuscar.
-keepattributes SourceFile,LineNumberTable,*Annotation*,Signature,InnerClasses,EnclosingMethod

# --- flutter_local_notifications (receivers por reflexión) ---
-keep class com.dexterous.** { *; }

# --- workmanager: el callbackDispatcher de Dart se invoca por nombre ---
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class * extends androidx.work.ListenableWorker { *; }

# --- flutter_secure_storage (crypto/keystore) ---
-keep class com.it_nomads.fluttersecurestorage.** { *; }
