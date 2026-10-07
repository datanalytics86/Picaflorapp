# Línea base — Picaflor v2

Fecha de esta pasada: 2026-10-06. Rama de trabajo: `grok/picaflor-v2-061026`, encima de `02abbd4` (megaprompt). No se desplegó Firebase ni se publicó en tiendas.

## Entorno

Flutter 3.44.7 stable / Dart 3.12.2. SDK local: `C:\Users\nicolas.andrade\flutter\bin` (no está en el PATH). En Windows hace falta el Modo de desarrollador para los symlinks de plugins.

## Comandos (salida real)

`flutter analyze --fatal-infos` (después de los arreglos de `const` y de los imports muertos):

```
Analyzing picaflorapp...
No issues found! (ran in 7.6s)
```

`flutter test --coverage`:

```
00:03 +23: All tests passed!
```

Cobertura: `coverage/lcov.info` (generada en esa corrida).

`bash tool/gates.sh` corre en CI (Ubuntu). En esta máquina no hay bash en el PATH; el mismo criterio se revisó con ripgrep: literales `Color(0x`, `fontSize:` y `BorderRadius.circular(<dígito>)` solo bajo `lib/core/design_system/`; la UI no importa `data/demo`; `lib/main.dart` no llama `setMockInitialValues`.

`flutter build web --release --dart-define=DEMO_MODE=true --base-href /` terminó en 39,3 s:

```
✓ Built build\web
```

Avisos de esa corrida: dry-run de Wasm (no se publicó Wasm) y una fuente CupertinoIcons que el árbol no declara. El artefacto demo quedó en `build/web`. No se desplegó hosting.

`npm test` en `functions/` (10 pruebas puras, sin emulador):

```
# tests 10
# pass 10
# fail 0
```

Las pruebas de reglas de Firestore viven en `firestore-tests/` y piden el emulador. No se corrieron en esta máquina.

## Hallazgos de la §4

| ID | Estado en este árbol |
|----|----------------------|
| S1 | Confirmado en el snapshot. El cliente de producción llama `getNearby` y no lee coordenadas. `locations/{uid}` queda cerrado en reglas. |
| S2 | Confirmado. Email, teléfono, nacimiento y FCM van a `users/{uid}` (solo dueño). El perfil público es `profiles/{uid}`. |
| S3 | Confirmado. El cliente solo escribe `unreadCount`, `lastRead` y `muted` propios. Las reglas repiten ese límite. `participantIds` no lo reescribe el cliente. |
| S4 | Confirmado. Hay bloqueo y reporte en la ficha pública, en el chat y (bloqueo) en la lista de Cerca. |
| S5 | Confirmado. Ajustes pide borrado con dos diálogos. Existe `/eliminar-cuenta`. |
| S6 | Confirmado. El onboarding real tiene fecha de nacimiento y términos sin marcar. El demo sigue saltando el onboarding para abrir el showcase. Ver ADR 0001. |
| S7 | Confirmado. Con `WAVES_ENABLED` (default true) Cerca abre la ficha y el saludo, no el chat. |
| S8 | Confirmado y cubierto por test: producción no rellena con `DemoNearby`. |
| S9 | Confirmado. Android solo `ACCESS_COARSE_LOCATION`. iOS solo When In Use. Precisión `low`. |
| S10 | Confirmado. Una tarea Gradle de release sin `key.properties` lanza `GradleException`. El job de Android en CI sigue apagado. |
| S11 | Confirmado. El mapa muestra "© OpenStreetMap © CARTO". El proveedor de pago sigue sin elegir. |
| S12 | Confirmado como borrador. `web/privacidad.html` cita la Ley 21.719 y dice que un abogado debe cerrar el texto. |
| B1 | La pantalla de chat resuelve a la otra persona con `userByIdProvider`. |
| B2 | Chats, no leídos y Cerca observan `sessionProvider`. |
| B3 | Lectura con debounce de 350 ms. En producción el update es por campo (`unreadCount.{uid}`), que es lo que las reglas aceptan. |
| B4 | El cliente llama `touchActivity` y no escribe `isOnline`. La UI usa buckets. |
| B5 | Cerca de producción es un callable. El filtro de bloqueo también corre en el cliente. |
| B6 | Hay `fetchOlderMessages` y un control "Mensajes anteriores". |
| B7 | Producción rechaza ids `demo_`. |
| B8 | El arranque usa `KeyValueStore`. Si fallan las preferencias, la memoria no marca el onboarding. |
| D1 | Paleta v2 con contraste AA cubierto en `test/v2_policy_test.dart`. |
| D2 | El isotipo de patita salió de splash, login y ajustes. Queda un colibrí dibujado a mano, no el isotipo final. |
| D3 | El botón de Google sigue con la letra G. No es el logo oficial. |
| D4 | La familia declarada es Inter. Los archivos se empaquetan cuando la descarga OFL termina. |
| D5 | El gate de literales está en `tool/gates.sh` y en CI. |
| D6 | Se quitó el tope de escala 1.15 y `user-scalable=no`. Semantics de cada control sigue incompleto. |
| D7 | Web usa `#0B7A6F` como la app. Siguen existiendo splash HTML, ruta `/splash` y splash nativa. |
| D8 | Los links legales abren el navegador. La versión sale de `package_info_plus`. |
| D9 | Sigue sin subida de foto y sin editor de intereses. |
| A1–A4 | Parcial. Hay política de Cerca, saludos y seguridad separados del demo. Siguen `if (_isDemo)` en servicios, re-exports y `StateNotifier`. No se sube a Riverpod 3. |
| A5 | Se quitaron dependencias sin imports en `lib/` ni `test/`. |
| A6 | Hay callables, analytics en memoria (sin PII) y flavor por `AppConfig`. No hay Remote Config, crash reporting ni ARB completo. App Check se exige en los callables y falla cerrado hasta que un humano lo configure. |
| A7 | 23 tests. CI en todo push y pull request. Siguen sin goldens y sin tests de emulador. |

## Decisiones que siguen en manos de una persona

Isotipo final, precios finales, texto legal firmado por un abogado, umbral de liquidez de Plus, proveedor de mapa de pago, confirmación de la región en la consola de Firebase, proyecto Firebase real y App Check, cuentas de las tiendas. Ver `docs/adr/`.
