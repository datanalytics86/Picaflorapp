# Picaflor 🐦

App Flutter + Firebase para conocer gente cerca en el **Gran Santiago**.

Diseño sobrio (la barra de calidad es la de un producto financiero chileno, sin copiar marcas): espacio en blanco, Inter, bordes finos, textos en español chileno. La privacidad manda: la coordenada exacta no vive en un documento que el cliente pueda leer.

> **Deploy:** ver [DEPLOY.md](./DEPLOY.md) — checklist completo web / Android / iOS / Firebase.

## Estado

| Capa | Estado |
|------|--------|
| Design system v2 + gate de literales | ✅ en esta rama |
| Auth + demo | ✅ |
| Cerca por buckets, sin coordenada en el cliente | ✅ |
| Saludo, bloqueo, reporte, borrar cuenta, Plus en espera | ✅ |
| Firestore rules + Functions (sin deploy) | ✅ código, ⬜ deploy |
| Android release sin keystore | falla a propósito |
| CI (gates, analyze, test, web) en todo push y PR | ✅ |
| Firebase real, App Check, tiendas | ⬜ una persona |

Detalle de la pasada: [docs/BASELINE.md](docs/BASELINE.md) y [docs/PLAN.md](docs/PLAN.md).

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
| `/onboarding` | 2 slides + edad y términos |
| `/plus` | Lista de espera Plus |
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
