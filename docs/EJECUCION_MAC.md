# Ejecución del proyecto en macOS / iOS

> Guía rápida para correr el cliente Flutter MyAccess IJL en la Mac disponible por tiempo limitado.

## Requisitos previos en la Mac

1. **Xcode** instalado desde App Store o Apple Developer.
2. **CocoaPods** instalado:
   ```bash
   sudo gem install cocoapods
   ```
3. **Flutter SDK** instalado y en el `PATH`:
   ```bash
   flutter doctor
   ```
4. **Git** configurado para clonar/pull la rama `feature/firebase-setup`.

## Pasos para ejecutar

### 1. Obtener el código

```bash
git clone <repo-url> /path/local
# o si ya está clonado:
git fetch origin
git checkout feature/firebase-setup
git pull origin feature/firebase-setup
```

### 2. Instalar dependencias

```bash
cd /path/local
flutter pub get
```

### 3. Instalar pods de iOS

```bash
cd ios
pod install --repo-update
cd ..
```

> Si `pod install` falla por versiones, intenta:
> ```bash
> pod update
> ```

### 4. Abrir en Xcode

```bash
open ios/Runner.xcworkspace
```

Dentro de Xcode:

1. Selecciona el **Team** de Apple Developer en `Runner > Signing & Capabilities`.
2. Verifica que el **Bundle Identifier** sea `com.ijl.clienteFlutterMyaccess`.
3. Asegúrate de que `ios/Runner/GoogleService-Info.plist` esté incluido en el target `Runner`.

### 5. Ejecutar en simulador o dispositivo físico

Opción A — desde terminal:

```bash
flutter run
```

Opción B — desde Xcode:

1. Selecciona el dispositivo/simulador objetivo.
2. Presiona `Cmd + R`.

### 6. Solución de problemas comunes

| Síntoma | Solución |
|---------|----------|
| `Firebase configuration not found` | Verifica que `GoogleService-Info.plist` esté en `ios/Runner/` y agregado al target. |
| `No code signing identities found` | Registra un Apple Developer Team en Xcode. |
| `CocoaPods could not find compatible versions` | Ejecuta `pod repo update && pod install` nuevamente. |
| Error de bundle ID | Cambia el bundle ID en Xcode a `com.ijl.clienteFlutterMyaccess`. |
| Error de red al backend | Verifica que la Mac tenga acceso a la red y que el backend esté corriendo. |

## Build de release iOS

```bash
flutter build ios --release
# o para IPA:
flutter build ipa --release
```

## Notas importantes

- Este proyecto usa **Firebase Auth + Google Sign-In**. En iOS se requiere configurar el `CFBundleURLTypes` en `Info.plist` cuando se implemente la Fase 3 (Auth).
- La configuración de Firebase ya está generada (`lib/firebase_options.dart` y `GoogleService-Info.plist`). No ejecutar `flutterfire configure` nuevamente salvo que se cambie el proyecto Firebase.
- Para pruebas rápidas usa el simulador; para Google Sign-In real se necesita un dispositivo físico con una cuenta de Google válida.
