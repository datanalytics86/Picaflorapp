# Picaflor 🐦

App Flutter + Firebase para conocer gente cerca en el **Gran Santiago**.

Diseño minimalista estilo Fintual/BCI: whitespace generoso, Poppins, cards suaves, textos en español chileno.

## Estado del código

| Capa | Estado |
|------|--------|
| Design system (colors, typography, theme, spacing) | ✅ |
| Widgets Tier 1 | ✅ |
| AuthService (email, Google, Apple, phone) | ✅ |
| LocationService (ubicación aproximada) | ✅ |
| UserService / ChatService | ✅ |
| Providers Riverpod | ✅ |
| Nearby + demos fallback | ✅ |
| Chat list / Chat / Profile / Settings | ✅ |
| Router + redirects auth | ✅ |
| **Modo demo sin Firebase** (default) | ✅ |

## Modo demo (sin Firebase)

Por defecto la app arranca en **demo** (`AppConfig.demoMode = true`):

- No inicializa Firebase
- Login con botón **“Entrar en demo”** (o cualquier correo/clave válidos)
- Teléfono demo: código SMS `123456`
- Gente cerca, chats y mensajes en memoria (con auto-respuesta)
- Ubicación: GPS real si hay permiso; si no, centro de Santiago

```powershell
# Demo (default)
flutter run

# Producción con Firebase
flutter run --dart-define=DEMO_MODE=false
```

## Setup rápido

> **Windows:** activa *Modo de desarrollador* (symlinks para plugins):
> `start ms-settings:developers` → activar **Modo de desarrollador**.

```powershell
# Si flutter no está en PATH:
$env:Path = "C:\Users\nicolas.andrade\flutter\bin;" + $env:Path

cd C:\Users\nicolas.andrade\Documents\picaflorapp

# Plataformas android/ios/web ya generadas; si faltan:
# flutter create . --project-name picaflorapp --org com.picaflor.app

flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
flutter run
```

### Firebase Console

1. **Authentication**: Email/Password, Google, Apple, Phone  
2. **Firestore**: crear DB + pegar `firestore.rules`  
3. **iOS**: Sign in with Apple capability  
4. **Android**: SHA-1 en Firebase para Google / Phone  

### Permisos de ubicación

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Picaflor usa tu zona aproximada para mostrarte gente cerca en Santiago.</string>
```

## Privacidad de ubicación

- Nunca se guardan coordenadas exactas.
- `LocationService.fuzz` redondea a grilla ~150 m.
- Las distancias en UI son aproximadas (`muy cerca`, `~200 m`).

## Rutas

| Path | Pantalla |
|------|----------|
| `/splash` | Splash |
| `/onboarding` | 2 slides |
| `/login` | Email / teléfono / Google / Apple |
| `/home` | Nearby |
| `/chat-list` | Lista de chats |
| `/chat/:id` | Chat 1:1 |
| `/profile` | Perfil |
| `/settings` | Ajustes |

## Estructura

```
lib/
  main.dart
  router/app_router.dart
  core/theme|utils|constants/
  models/
  services/
  providers/
  widgets/          # Tier 1
  screens/          # implementación
  features/*/screens/  # re-exports
  data/demo_nearby.dart
```
