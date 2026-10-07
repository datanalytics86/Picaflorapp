# Picaflor — guía de deploy

Checklist para dejar la app en producción (web + Android + Firebase).

## 0. Prerrequisitos

- Flutter stable (`flutter doctor` sin errores críticos)
- Cuenta Firebase
- (Android) Android Studio / SDK + keystore
- (iOS) Mac + Xcode + Apple Developer
- Node.js (CLI de Firebase): `npm i -g firebase-tools`

## 1. Firebase (una vez, lo hace una persona)

No crear el proyecto ni desplegar desde un agente sin un sí explícito. Región prevista: `southamerica-east1` (ADR 0005). Los callables exigen App Check y fallan si no está (ADR 0003).

```bash
firebase login
firebase use <proyecto-existente>

# FlutterFire genera lib/firebase_options.dart + google-services.json
dart pub global activate flutterfire_cli
flutterfire configure --project=picaflorapp
```

En **Firebase Console**:

| Servicio | Acción |
|----------|--------|
| Authentication | Email/Password, Google, Phone (y Apple si iOS) |
| Firestore | Crear DB (production mode) |
| Storage | Crear bucket (avatares) |
| Google Sign-In Android | Agregar SHA-1/SHA-256 del keystore release |

Desplegar reglas e índices:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

Eso publica reglas y las Functions de Cerca, saludos, bloqueo, borrado, export, actividad y el webhook. No correrlo hasta tener App Check y la región confirmada.

## 2. Web (más rápido de publicar)

```powershell
# Demo (sin backend real) — ideal para landing / QA
.\scripts\build_web.ps1 -DemoMode true

# Producción con Firebase
.\scripts\build_web.ps1 -DemoMode false

firebase deploy --only hosting
```

URL típica: `https://picaflorapp.web.app`

### GitHub Actions

1. Genera service account JSON en Firebase → Project settings → Service accounts  
2. Secret `FIREBASE_SERVICE_ACCOUNT` en el repo  
3. Actions → **Deploy Web (Firebase Hosting)** → Run workflow  

CI en cada push: analyze + test + build web (artifact `web-demo`).

## 3. Android (Play Store / APK)

```powershell
# Keystore (una vez)
mkdir keystore -ErrorAction SilentlyContinue
keytool -genkey -v -keystore keystore/picaflor-release.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias picaflor

# Firma
copy android\key.properties.example android\key.properties
# edita passwords y storeFile

# google-services.json debe estar en android/app/ (flutterfire configure lo pone)

.\scripts\build_apk.ps1 -DemoMode false
# → build/app/outputs/flutter-apk/app-release.apk

# App Bundle para Play:
flutter build appbundle --release --dart-define=DEMO_MODE=false
```

`applicationId`: `com.picaflor.app.picaflorapp`  
`minSdk`: 23  

## 4. iOS (App Store)

```bash
# En Mac
flutterfire configure   # genera GoogleService-Info.plist
# Xcode: Signing & Capabilities → Sign in with Apple
# Info.plist ya tiene NSLocationWhenInUseUsageDescription

flutter build ipa --release --dart-define=DEMO_MODE=false
```

Bundle id sugerido: `com.picaflor.app` (ajustar en Xcode si difiere).

## 5. Variables de build

| Define | Default | Uso |
|--------|---------|-----|
| `DEMO_MODE` | `true` | Sin Firebase, datos en memoria |
| `PRIVACY_POLICY_URL` | `https://picaflor.app/privacidad` | Store / Ajustes |
| `TERMS_URL` | `https://picaflor.app/terminos` | Store / Ajustes |
| `SUPPORT_EMAIL` | `hola@picaflor.app` | Contacto |
| `PLUS_ENABLED` | `false` | Lista de espera. No cobra |
| `WAVES_ENABLED` | `true` | Saludo antes del chat |
| `MAP_TILE_URL` | CARTO | Teselas. Hace falta atribución |

Ejemplo:

```bash
flutter build web --release \
  --dart-define=DEMO_MODE=false \
  --dart-define=PRIVACY_POLICY_URL=https://tudominio.cl/privacidad
```

## 6. Checklist pre-launch

- [ ] `flutterfire configure` → `firebase_options.dart` real  
- [ ] `DefaultFirebaseOptions.isConfigured == true`  
- [ ] Auth methods habilitados  
- [ ] `firebase deploy --only firestore:rules,firestore:indexes,storage,functions`  
- [ ] Build con `DEMO_MODE=false`  
- [ ] SHA-1 release en Firebase (Google/Phone Android)  
- [ ] Keystore backup seguro  
- [ ] Política de privacidad publicada  
- [ ] Probar: login, nearby, chat, perfil, logout  
- [ ] App Check en cada app (los callables lo exigen)
- [ ] Data Safety: ubicación aproximada, no precisa
- [ ] Página `/eliminar-cuenta` publicada junto al hosting
- [ ] Texto legal revisado por un abogado (el HTML del repo es borrador)
- [ ] Keystore de release presente. Sin `android/key.properties` el build de release aborta  

## 7. Demo vs producción

| | Demo | Producción |
|--|------|------------|
| `DEMO_MODE` | `true` | `false` |
| Firebase | no | sí |
| Login | “Entrar en demo” / cualquier email | real |
| Nearby / chat | memoria + auto-reply | Firestore |
| Banner debug | sí | no (release) |

## 8. Troubleshooting

- **Analyzer OK pero tests fallan en Windows con espacios en path**: trabaja desde un junction sin espacios (`C:\src\Picaflorapp`) o habilita Developer Mode.  
- **Firestore index required**: abre el link del error o corre `firebase deploy --only firestore:indexes`.  
- **Google Sign-In Android**: falta SHA-1 del keystore que firma el APK.  
- **Phone auth**: reCAPTCHA / SafetyNet; prueba en dispositivo real.
