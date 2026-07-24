# Picaflor 🐦

App Flutter + Firebase para conocer gente cerca en el **Gran Santiago**.

Diseño minimalista estilo Fintual/BCI: whitespace generoso, Poppins, cards suaves, textos en español chileno.

> **Deploy:** ver [DEPLOY.md](./DEPLOY.md) — checklist completo web / Android / iOS / Firebase.

## Estado

| Capa | Estado |
|------|--------|
| Design system + widgets | ✅ |
| Auth (email, Google, Apple, phone) + demo | ✅ |
| Location approx (~150 m fuzz) | ✅ |
| Nearby + chat + perfil + settings | ✅ |
| Router + redirects | ✅ |
| Firestore rules + indexes + Storage rules | ✅ |
| Android release (minSdk 23, ProGuard, signing) | ✅ |
| Web PWA + Firebase Hosting config | ✅ |
| CI (analyze / test / build web) | ✅ |
| Firebase real (`flutterfire configure`) | ⬜ manual |
| Keystore / Play Store / App Store | ⬜ manual |

## Modo demo (default)

Por defecto `DEMO_MODE=true` (sin Firebase):

- Login: **Entrar en demo** o cualquier correo/clave válidos  
- SMS demo: código `123456`  
- Nearby, chats y auto-reply en memoria  
- Ubicación: GPS real o centro de Santiago  

```powershell
flutter pub get
flutter run

# Producción
flutter run --dart-define=DEMO_MODE=false
```

## Setup rápido

> **Windows:** activa *Modo de desarrollador* (symlinks de plugins):  
> `start ms-settings:developers`

```powershell
# PATH de Flutter si hace falta
$env:Path = "C:\src\flutter\bin;" + $env:Path

cd C:\src\Picaflorapp   # o la ruta de tu clone
flutter pub get
flutter analyze
flutter test

# Web
.\scripts\build_web.ps1

# Android (requiere SDK)
.\scripts\build_apk.ps1
```

### Firebase

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
firebase deploy --only firestore:rules,firestore:indexes,storage,hosting
```

Detalle en [DEPLOY.md](./DEPLOY.md).

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
| `/settings` | Ajustes + legal |

## Estructura

```
lib/
  main.dart
  router/app_router.dart
  core/config|theme|utils|constants/
  models/ services/ providers/ widgets/ screens/
  data/demo_store.dart · demo_nearby.dart
```

## Privacidad de ubicación

- Nunca se guardan coordenadas exactas  
- `LocationService.fuzz` redondea a grilla ~150 m  
- UI: `muy cerca`, `cerca`, `~200 m`, etc.  

## Licencia

Privado / uso del proyecto Picaflor.
