# Auditoría de la ejecución v1 (rama `grok/picaflor-v2-061026`, commit `155b6f6`)

> Generado el 07-10-2026 a partir de 8 lentes independientes de auditoría, con verificación adversarial de los P0/P1 de código
> (lentes Flutter, Backend y Cumplimiento v1). Las lentes de estrategia (escala, monetización, Tier-1, orquestación y
> production readiness) no pasan por verificación adversarial: sus cifras marcadas "supuesto" se validan en la tarea correspondiente.
> Los IDs se usan en `docs/v2/TASKS.yaml` (campo `closes`) y en `docs/v2/STATUS.md`. Las líneas citadas corresponden a `155b6f6`.

## Resumen

| Lente | Prefijo | Hallazgos | P0 | P1 | P2 | Verificación |
|-------|---------|-----------|----|----|----|--------------|
| Código Flutter (lib/, test/, CI) | FL | 31 | 5 | 20 | 6 | confirmed: 22, partial: 3 |
| Backend Firebase (reglas, Functions, índices) | BE | 27 | 7 | 14 | 6 | sin verificar: 21 |
| Cumplimiento del megaprompt v1 | CV | 26 | 7 | 15 | 4 | sin verificar: 22 |
| Escalabilidad y costo | SC | 25 | 5 | 17 | 3 | no aplica (estrategia) |
| Monetización y crecimiento | MO | 19 | 1 | 14 | 4 | no aplica (estrategia) |
| Producto y diseño Tier-1 | T1 | 34 | 6 | 23 | 5 | no aplica (estrategia) |
| Orquestación multi-agente y ejecución de Grok | AG | 18 | 4 | 12 | 2 | no aplica (estrategia) |
| Production readiness: SRE, seguridad, QA y cumplimiento | PR | — | — | — | — | sin resultado |
| **Total** | | **180** | **35** | **115** | **30** | |

Nota: varias lentes reportan el mismo problema desde ángulos distintos (por ejemplo App Check aparece como FL-01, BE-02, CV-07 y SC-04).
Los IDs consolidados de la §2 de las Instrucciones v2 (V-01..V-16) agrupan esos duplicados.

## FL · Código Flutter (lib/, test/, CI)

**Veredicto de la lente**

Veredicto de la lente Flutter: el commit 155b6f6 cambia bien la dirección (Cerca por callable sin coordenadas, sin relleno demo en prod, providers atados a sessionProvider, sin setMockInitialValues, COARSE/WhenInUse, guard de keystore, Inter empaquetada, url_launcher/package_info), pero en producción real la app no funciona de punta a punta, y varios "Hecho" de BASELINE/PLAN son falsos o tramposos. Hay 5 P0 encadenados. (1) Los 8 callables exigen App Check y el cliente no tiene firebase_app_check, así que fallan Cerca, saludos, bloqueo, borrado y export. (2) La fecha de nacimiento solo queda en las preferencias locales, y getNearby oculta a todos los que no tienen birthDate, así que Cerca queda siempre vacía. (3) updateProfile manda 'updatedAt' y las reglas de profiles lo rechazan: editar el perfil y el toggle de visibilidad dan PERMISSION_DENIED. (4) No existe una UI para recibir o aceptar saludos (respondWave nunca se llama), así que con WAVES_ENABLED=true (el default) nadie puede abrir un chat. (5) Eliminar cuenta llama a touchActivity al cerrar sesión y recrea users/{uid} y profiles/{uid}. A esto se suman la paginación con huecos, el markRead que no corre con 80 o más mensajes y además pierde la carrera contra el trigger, una presencia "activa ahora" eterna (regresión de B4), un onboarding cuyo botón Siguiente del paso 2 está roto y un design system que solo existe de nombre (las referencias a AppColors subieron de 279 a 289 y los isDark de 204 a 210; hay 1 componente Pf* de 22). El gate pasa porque mide lo que no corresponde y los tests nuevos son de funciones puras o de código muerto (0 widget tests). En monetización el cliente no tiene base: flags de compilación, ningún entitlement, una lista de espera que no registra nada, un incógnito gratis vía toggle y un radio de 10 km gratis que el servidor corta en silencio. Para Tier 1, v2 debe exigir tests de contrato cliente↔reglas↔functions, widget tests por flujo, gates con ratchet y un loop de saludo completo verificado en emulador.

**Lo que está bien y se preserva**

- B2 resuelto: userChatsProvider, totalUnreadProvider y Cerca observan sessionProvider.select((s) => s?.uid) (lib/providers/chat_provider.dart:13,31; lib/providers/nearby_provider.dart:36,72).
- S8 en Cerca: el camino remoto ya no rellena con DemoNearby; los estados vacío y error son honestos (lib/providers/nearby_provider.dart:78-106, lib/core/privacy/nearby_policy.dart).
- S1 en cliente: Cerca de producción usa el callable getNearby y no lee coordenadas de otros; los pines se dibujan desde el bucket (DisplayPin) y no desde la posición real (lib/services/user_service_live.dart:112-160, lib/core/privacy/display_pin.dart).
- S3 alineado: sendTextMessage solo crea el mensaje y deja el chat al trigger; markChatAsRead actualiza por FieldPath solo la clave propia, lo que coincide con chatMetaUpdateOk (lib/services/chat_service_live.dart:95-125).
- B8: se eliminó setMockInitialValues; el fallback es MemoryKeyValueStore sin marcar el onboarding, detrás de la interfaz KeyValueStore (lib/main.dart:127-137, lib/core/prefs/key_value_store.dart).
- S9: solo ACCESS_COARSE_LOCATION y When In Use; precisión LocationAccuracy.low (android/app/src/main/AndroidManifest.xml, ios/Runner/Info.plist, lib/services/geo_locator_bridge.dart:96).
- S10: una tarea Gradle *Release sin key.properties lanza GradleException (android/app/build.gradle.kts:74-83).
- D6 parcial: se quitó el clamp de textScaler 1.15 y user-scalable=no (lib/main.dart:194, web/index.html:10).
- D8: los links legales abren el navegador con url_launcher y la versión sale de package_info_plus (lib/screens/settings/settings_screen.dart:385-409).
- Inter empaquetada de verdad: 4 TTF válidos (Inter 4.001) + OFL, declarados en pubspec.yaml con pesos 400/500/600/700.
- Paleta v2 en un solo archivo (PfPalette), con contrastes AA de los pares base testeados; las burbujas propias en dark usan onBrandDark sobre brandDark (lib/widgets/chat_bubble.dart:43-45).
- Sin loop de markRead: el debounce de 350 ms y _lastMarkedMessageId evitan reescrituras en bucle (lib/screens/chat/chat_screen.dart:70-80).
- Los ids de motivos de reporte coinciden exactamente con la whitelist de las reglas (lib/features/safety/report_reasons.dart vs firestore.rules:183).
- A5: se quitaron las dependencias muertas (google_fonts, uuid, permission_handler, riverpod_generator, etc.).
- Patita reemplazada por un isotipo placeholder (PfMark) con Semantics; la web y el manifest se alinearon a #0B7A6F.

**Hallazgos**

### FL-01 · P0 · bug · ✅ confirmado
**App Check exigido en los 8 callables, pero el cliente Flutter no lo implementa**

- **Evidencia:** functions/src/https.ts:5-8 (enforceAppCheck: true); pubspec.yaml sin firebase_app_check; lib/firebase_boot.dart:8-18 solo llama Firebase.initializeApp; docs/adr/0003-app-check-fail-closed.md
- **Detalle:** En producción getNearby, updateLocation, touchActivity, sendWave, blockUser, deleteAccount y exportMyData responden 'unauthenticated' porque las requests no llevan token de App Check. Cerca muestra 'No pudimos cargar…', los saludos lanzan una excepción no capturada y eliminar cuenta falla sin feedback. El ADR 0003 dice que basta con que un humano registre las apps en la consola, y eso es falso: falta código cliente (FirebaseAppCheck.instance.activate con Play Integrity, App Attest/DeviceCheck y reCAPTCHA Enterprise en web).
- **Recomendación:** v2: agregar firebase_app_check y activarlo en initFirebase según plataforma y flavor (debug provider en dev, con token documentado). Agregar un test de integración contra el emulador de functions con enforceAppCheck que pruebe que una llamada sin token falla y una con token pasa. Corregir el ADR 0003.

### FL-02 · P0 · bug · ✅ confirmado
**La fecha de nacimiento nunca llega al servidor y getNearby oculta a todos: Cerca queda siempre vacía en producción**

- **Evidencia:** lib/screens/onboarding/onboarding_screen.dart:63-69 (solo prefs.setString(keyBirthDate)); grep 'birthDate' en lib/ no encuentra escrituras a Firestore; functions/src/pure/nearbyFilter.ts:40 ('Missing birth dates … are always hidden')
- **Detalle:** Una persona adulta completa el onboarding y su birthDate queda solo en las preferencias del dispositivo. filterNearbyPeople descarta a todo candidato sin users/{uid}.birthDate, así que ningún usuario real aparece jamás en Cerca. Los rules tests siembran birthDate con privilegios de admin (firestore-tests/rules.test.ts:36-37), lo que oculta el problema.
- **Recomendación:** Crear un callable acceptOnboarding({birthDate, termsVersion, privacyVersion, analyticsConsent}) que valide 18+ en el servidor, escriba users/{uid}.birthDate (inmutable: las reglas niegan que el cliente escriba birthDate) y consents{version, ts}. El router exige ese estado del servidor, no el flag del dispositivo. Test e2e en emulador: alta → onboarding → otro usuario lo ve en getNearby.

### FL-03 · P0 · bug · ✅ confirmado
**updateProfile escribe 'updatedAt' en profiles/{uid} y las reglas lo rechazan: no se puede editar el perfil ni cambiar la visibilidad**

- **Evidencia:** lib/services/user_service_live.dart:83-91 (data incluye 'updatedAt'); firestore.rules:69-71 (profileClientKeys no incluye updatedAt) y :136-138 (affectedKeys().hasOnly(profileClientKeys()))
- **Detalle:** Guardar el perfil (lib/providers/user_provider.dart:65), el toggle 'Visible cerca de mí' (profile_screen.dart:261) y _upsertProfile al loguear (auth_service_live.dart:329,333) terminan en PERMISSION_DENIED. La UI muestra 'No se pudo guardar. Revisa tu conexión.', un error engañoso. Los rules tests no prueban la escritura del dueño con el payload real que arma Dart.
- **Recomendación:** Quitar updatedAt del payload del cliente o agregarlo a las reglas con request.time. Agregar tests de contrato: los payloads que produce el código Dart se exportan como fixtures JSON y firestore-tests los usa en casos allow, y así para cada escritura del cliente (users, profiles, chats meta, messages, reports, blocks).

### FL-04 · P0 · gap · ✅ confirmado
**No hay UI para recibir ni aceptar saludos: el loop central queda roto con WAVES_ENABLED=true (default)**

- **Evidencia:** grep respondWave en lib/: solo lib/services/safety_service_live.dart:20; MemoryWaves.incomingPending (lib/features/waves/wave_models.dart:39) no se usa; no hay query a la colección 'waves' en lib/
- **Detalle:** Cerca abre la ficha y 'Saludar' llama a sendWave. La persona saludada no tiene dónde ver el saludo (falta la fila 'Saludos nuevos' en Chats) ni cómo aceptarlo, así que nunca se crea un chat. Como las reglas impiden que el cliente cree chats (firestore.rules:155), en producción no existe ninguna forma de iniciar una conversación. BASELINE marca S7 como 'Confirmado' y PLAN marca las fases 4 y 5 como 'Hecho'.
- **Recomendación:** Crear WavesRepository con stream de waves where to==uid && status=='pending', una sección 'Saludos nuevos (n)' en Chats con Aceptar/Ignorar (respondWave) y navegación al chat devuelto, más los estados del lado emisor (pendiente/aceptado). Widget test + test en emulador del loop completo: saludar → aceptar → chat visible para ambos → mensaje.

### FL-05 · P0 · compliance · ✅ confirmado
**Eliminar cuenta recrea users/{uid} y profiles/{uid} justo después del borrado y no maneja errores**

- **Evidencia:** lib/screens/settings/settings_screen.dart:477-479 (deleteAccount → signOut sin try/catch); lib/services/auth_service.dart:228-233 (signOut llama setOnlineStatus); lib/services/user_service_live.dart:106-110 (setOnlineStatus → touchActivity); functions/src/touchActivity.ts:11-17 (set merge users/ y profiles/); functions/src/deleteAccount.ts:48-53
- **Detalle:** Escenario: deleteAccount borra users, profiles y Auth, y después el cliente hace signOut → touchActivity con el ID token todavía válido (hasta 1 h; onCall no revisa revocación por defecto) → set merge recrea users/{uid}{lastActiveAt} y profiles/{uid}{activityBucket:'ahora'}. Quedan registros residuales ligados al uid, lo que incumple Apple 5.1.1(v) y la Ley 21.719. Si el callable falla (FL-01, red), la excepción escapa: no hay snackbar, no se cierra la sesión y la persona no sabe si se borró. Tampoco se limpian las prefs locales (birth_date, consents), SafetyController ni memoryWaves. (Supuesto a confirmar en el emulador: que el token del uid borrado siga aceptándose en el callable.)
- **Recomendación:** Después de borrar, signOut solo local (sin touchActivity, que nunca debería ir en signOut) y limpiar prefs y estado en memoria. try/catch con mensaje es-CL y reintento. touchActivity debe verificar con checkRevoked o con la existencia de Auth antes de escribir. Test en emulador: después de deleteAccount + signOut no existe ningún documento con el uid.

### FL-06 · P1 · bug · ✅ confirmado
**Onboarding: 'Siguiente' en el paso 2 llama a _finish y muestra 'Picaflor es para mayores de 18' sin avanzar**

- **Evidencia:** lib/screens/onboarding/onboarding_screen.dart:81-91 (_next compara con _pages.length - 1 == 1, pero _stepCount == 3); :231 onPressed: _next; :54-57
- **Detalle:** En la página 1 (la segunda), _page < 1 es falso, así que _next() llama a _finish(). Con birthDate null aparece el toast 'Picaflor es para mayores de 18.' y la persona no avanza. Solo llega al paso de edad deslizando o con 'Saltar'. Es el primer contacto con la app en producción y un widget test lo habría detectado.
- **Recomendación:** Usar _stepCount en _next y deshabilitar 'Empezar' hasta tener una fecha válida y los términos aceptados. Agregar un widget test obligatorio que recorra las 3 páginas con el botón y pruebe el bloqueo sin edad o sin términos.

### FL-07 · P1 · bug · ✅ confirmado
**Paginación de mensajes con huecos, cursor por timestamp y markRead/autoscroll muertos con 80 mensajes o más**

- **Evidencia:** lib/screens/chat/chat_screen.dart:102-148 (_older + live), :208-216 (dispara solo si nextLen > prevLen); lib/services/chat_service_live.dart:65-67 (limit 80), :128-141 (startAfter([Timestamp]))
- **Detalle:** (a) Huecos: con un chat de 100 mensajes, la ventana viva es M21..M100; 'Mensajes anteriores' trae M1..M20; llega M101, la ventana pasa a M22..M101 y M21 desaparece de la pantalla. Cada mensaje nuevo abre otro hueco. (b) Con la ventana llena (80), un mensaje nuevo no cambia la longitud: no se ejecuta _scheduleMarkRead ni _scrollToEnd, así que B3 sigue abierto en cualquier chat largo. (c) startAfter con un Timestamp en vez de startAfterDocument (como pedía B6) salta mensajes con el mismo timestamp; en web DateTime trunca a milisegundos. (d) Los mensajes con createdAt null (escritura pendiente) se ordenan como epoch 0 y saltan al tope cuando _older no está vacío.
- **Recomendación:** Usar un repositorio de mensajes paginado con DocumentSnapshot (startAfterDocument/endBeforeDocument), una cola viva anclada al documento más antiguo cargado (sin límite deslizante) y dedupe por id. markRead se dispara cuando cambia el id del último mensaje entrante, no la longitud. Widget test con 120 mensajes: cargar anteriores + 5 entrantes → 125 mensajes contiguos y unreadCount=0.

### FL-08 · P1 · bug · ✅ confirmado
**markRead del cliente compite con el trigger onMessageCreated: el chat abierto queda con mensajes no leídos**

- **Evidencia:** lib/screens/chat/chat_screen.dart:75-79 (debounce 350 ms); functions/src/onMessageCreated.ts:46-52 (unreadCount.<uid> increment después); lib/services/chat_service_live.dart:115-121
- **Detalle:** El receptor ve el mensaje por snapshot en menos de 1 s y escribe unreadCount=0 a los 350 ms. El trigger (cold start de varios segundos en southamerica-east1) incrementa después a 1. Con el chat abierto, el badge de no leídos sigue en 1. BASELINE marca B3 como resuelto. El trigger ignora lastRead.
- **Recomendación:** Calcular los no leídos en el servidor en relación con lastRead.<uid> (no incrementar si lastRead >= createdAt del mensaje) o derivar los no leídos en el cliente como el conteo de mensajes posteriores a lastRead. Test en emulador con el orden invertido (markRead antes que el trigger).

### FL-09 · P1 · bug · ✅ confirmado
**Presencia falsa otra vez (regresión de B4): profiles.activityBucket se fija en 'ahora' y nunca decae; touchActivity nunca corre en uso normal**

- **Evidencia:** functions/src/touchActivity.ts:10-17 (bucket='ahora' constante); lib/screens/chat/chat_screen.dart:253-254 y lib/widgets/public_profile_sheet.dart:31-33 leen user.activityBucket del perfil; lib/services/auth_service_live.dart:323-344 (touch solo al re-loguear con un perfil existente); lib/services/auth_service.dart:228-233 (touch al hacer signOut)
- **Detalle:** El header del chat y la ficha muestran 'activa ahora' para siempre, mientras la tarjeta de Cerca (bucket calculado por getNearby) puede decir 'activa esta semana': hay inconsistencia visible. Además: (a) un usuario nuevo (rama createUser) nunca llama touchActivity, así que no tiene lastActiveAt y queda filtrado de Cerca (nearbyFilter.ts:42); (b) con la sesión persistida no se vuelve a llamar, y a los 7 días desaparece de Cerca aunque use la app a diario; (c) cerrar sesión marca actividad.
- **Recomendación:** No persistir activityBucket. Exponer lastActiveAt grueso (redondeado al día) o calcular el bucket en el servidor en cada lectura. touchActivity con AppLifecycleListener (resume), con throttle de 15 min, y en el alta, nunca en signOut. Test: un perfil inactivo 8 días muestra 'sin actividad reciente'.

### FL-10 · P1 · bug · 🟡 parcial
**Cerca: getNearby corre antes que updateLocation (carrera), con timeout de 4 s silenciado y un refresh que probablemente no vuelve a consultar**

- **Evidencia:** lib/providers/location_provider.dart:150-162 (state con ubicación + unawaited(_syncLocationToProfile)), :186-203 (timeout 4 s, catch vacío); functions/src/getNearby.ts:41-44 (invalid 'Location is not set'); lib/screens/nearby/nearby_screen.dart:136-140 (invalidate(nearbyUsersProvider) no invalida _nearbyUsersRemoteProvider)
- **Detalle:** Primer uso: hasLocation pasa a true → el FutureProvider llama getNearby antes de que el callable updateLocation termine → 'Location is not set' → error 'No pudimos cargar…'. Usuarios recurrentes: la primera consulta usa el geohash viejo. updateLocation con 4 s de timeout ante cold start + App Check falla en silencio y la persona queda invisible. 'Actualizar' invalida el Provider envoltorio; como la ubicación difuminada no cambia, el FutureProvider privado probablemente no se recalcula (supuesto de semántica de Riverpod 2, verificar con un test).
- **Recomendación:** Modelar un locationSyncProvider (AsyncNotifier) del que dependa nearby y que espere a updateLocation antes de llamar a getNearby, con reintento y backoff. Refresh explícito que invalide el provider remoto. Timeouts ≥ 10 s con mensaje. Test con ProviderContainer y fakes que fuerce el orden.
- **Verificación (partial):** Real: en el primer uso, getNearby compite con updateLocation. Si locations/{uid} todavía no existe, getNearby lanza invalid-argument y Cerca muestra 'No pudimos cargar'. En usuarios recurrentes, la primera consulta usa el geohash anterior. Los errores de updateLocation se silencian (catch vacío), incluido el resource-exhausted del rate limit de 20 s (updateLocation.ts:31-33). Exagerado: el timeout de 4 s es solo del lado del cliente y no aborta la escritura en el servidor, así que un cold start lento no deja a la persona invisible. Solo queda invisible si el callable falla de verdad (App Check/FL-01, red o rate limit). Que 'Actualizar' no vuelva a consultar sigue siendo un supuesto sobre Riverpod 2: refresh() no cambia lat/lon/hasLocation si la ubicación difuminada es la misma, e invalidate(nearbyUsersProvider) no invalida _nearbyUsersRemoteProvider.

### FL-11 · P1 · scalability · ✅ confirmado
**getNearbyUsers hace N+1 lecturas secuenciales de perfiles (hasta 50) en cada refresh**

- **Evidencia:** lib/services/user_service_live.dart:126-136 (await getUser(uid) dentro del for); lib/providers/nearby_provider.dart:87 (timeout 8 s), :73 (watch safetyControllerProvider re-ejecuta todo al bloquear)
- **Detalle:** Con 50 personas son 50 round-trips en serie (~4-7 s en 4G) dentro de un timeout de 8 s, así que en zonas densas lo probable es 'failed' y un estado de error. Cada lectura de profiles cuesta además 2 exists() en las reglas (blockedEitherWay). Un bloqueo re-dispara el callable completo. Con el costo del servidor (hasta 9×150 docs de locations + 3×N getAll) no escala a miles de usuarios activos.
- **Recomendación:** Que getNearby devuelva un resumen público (displayName, edad, foto, intereses, buckets) paginado con cursor, filtrar los bloqueos localmente fuera del FutureProvider y cachear con TTL. Presupuesto en v2: ≤ 1 callable + 0 lecturas extra por refresh; medir lecturas por sesión en una prueba de carga en el emulador.

### FL-12 · P1 · compliance · ✅ confirmado
**Age gate y consentimiento burlables: por dispositivo, sin servidor, sin versión y sin retiro**

- **Evidencia:** lib/router/app_router.dart:83-87 (onboardingDone es pref del dispositivo); lib/screens/onboarding/onboarding_screen.dart:63-69; functions/src/waves.ts:24-60 (sendWave no valida la edad del emisor); lib/screens/settings/settings_screen.dart (no hay toggle de métricas)
- **Detalle:** La cuenta A completa el onboarding y luego la cuenta B entra en el mismo dispositivo sin declarar nunca su edad. B no aparece en Cerca, pero puede saludar a cualquiera porque sendWave no revisa birthDate. El rechazo de menores no es persistente: basta elegir otra fecha. Términos y analytics quedan como bool locales sin versión ni timestamp ni uid, así que no se puede demostrar el consentimiento ante la Ley 21.719 (vigencia plena el 1-12-2026). No hay forma de retirar el consentimiento de métricas.
- **Recomendación:** Dejar el gate atado a la cuenta y aplicado en el servidor (FL-02). Todas las callables sociales (sendWave, respondWave, getNearby) exigen un adulto verificado en el servidor. Persistir el bloqueo por intento de menor (flag local + servidor). consents{terms:{v,ts}, privacy:{v,ts}, analytics:{granted,ts}} con retiro en Ajustes. Widget test del cambio de cuenta.

### FL-13 · P1 · bug · ✅ confirmado
**SafetyController solo en memoria, global entre cuentas y sin manejo de errores; el reporte depende del bloqueo**

- **Evidencia:** lib/features/safety/safety_controller.dart:8-40 (Set en memoria, ChangeNotifierProvider sin dispose por sesión, add optimista sin rollback); lib/widgets/public_profile_sheet.dart:72-80,140-170 (sin try/catch); lib/screens/chat/chat_screen.dart:160-168; lib/screens/chat/chat_list_screen.dart:297-312
- **Detalle:** (a) Al reiniciar la app, la lista de bloqueados queda vacía en el cliente porque no se hidrata desde blocks/{uid}/blocked. (b) Si A bloquea a X, cierra sesión y entra B en el mismo dispositivo, X queda oculto para B. (c) Si el callable blockUser falla, el UI ya dice 'Bloqueaste', no hay rollback y la excepción no se captura. (d) report() bloquea siempre (alsoBlock=true sin opción en la UI) y antes de enviar el reporte: si el bloqueo falla, el reporte nunca se envía. Faltan el texto para 'Otro', las refs (chatId/messageId) y la lista de bloqueados con desbloqueo en Ajustes (§5.5). El mensaje 'Lo revisamos en menos de 24 h' promete un SLA sin herramienta de moderación.
- **Recomendación:** SafetyRepository por sesión (se invalida con uid), stream de blocks desde Firestore, enviar el reporte primero y bloquear como opción explícita ('Además, bloquear'), errores mapeados con rollback, PfReportSheet con texto libre y refs. Pantalla 'Usuarios bloqueados'. Tests de widget y en emulador.

### FL-14 · P1 · bug · ✅ confirmado
**Errores de saludo sin mapear y estado de saludos global en memoria; plus fijo en false**

- **Evidencia:** lib/features/waves/wave_actions.dart:22-43 (memoryWaves global, live.sendWave lanza FirebaseFunctionsException); lib/widgets/public_profile_sheet.dart:107-127 (solo on WaveException, plus: false fijo); functions/src/waves.ts:56-70 (already-exists, resource-exhausted, permission-denied)
- **Detalle:** Cuando el servidor rechaza un saludo (duplicado después de reiniciar la app, cuota diaria, bloqueo, App Check), el botón 'Saludar' lanza una excepción no capturada y no muestra feedback; en release falla en silencio. memoryWaves es un singleton de proceso: no se reinicia al cambiar de cuenta y bloquea re-saludar aunque el saludo previo ya se haya aceptado o ignorado. El cliente nunca lee entitlements, así que los usuarios de Plus quedan limitados en el cliente.
- **Recomendación:** Mapear los códigos de FirebaseFunctionsException a copy es-CL. resource-exhausted abre el paywall con trigger 'wave_limit'. Quitar memoryWaves en prod (estado desde un stream de waves). entitlementProvider desde entitlements/{uid}. Tests unitarios del mapeo.

### FL-15 · P1 · bug · ✅ confirmado
**Un chat recién aceptado no aparece en la lista: watchUserChats ordena por lastMessageAt y respondWave no lo escribe**

- **Evidencia:** lib/services/chat_service_live.dart:44-46 (orderBy('lastMessageAt')); functions/src/waves.ts:130-136 (tx.set del chat sin lastMessageAt)
- **Detalle:** Firestore excluye de un orderBy los documentos que no tienen el campo. Aunque exista una UI de aceptar (FL-04), ninguno de los dos verá el chat nuevo en 'Chats' hasta que alguien envíe un mensaje por otra vía.
- **Recomendación:** respondWave escribe lastMessageAt=createdAt (o el cliente ordena por updatedAt, con índice compuesto). Test en emulador: aceptar → el chat aparece en watchUserChats de ambos.

### FL-16 · P1 · bug · ✅ confirmado
**Con WAVES_ENABLED=false no se puede abrir ningún chat nuevo y el estado bloqueado no existe en el modelo**

- **Evidencia:** lib/screens/nearby/nearby_screen.dart:197-221 (rama _openChat); lib/services/chat_service_live.dart:17-40 (get de un doc inexistente y set del cliente); firestore.rules:154-155 (read requiere resource; create: if false); lib/models/chat_model.dart (sin campo status)
- **Detalle:** El flag promete un camino alternativo que en prod da permission-denied ('No se pudo abrir el chat.'). Tras un bloqueo (status='blocked'), el chat sigue en la lista, el composer sigue activo y al enviar aparece el genérico 'No se pudo enviar'; ninguna de las dos personas entiende qué pasó.
- **Recomendación:** Eliminar el camino de chat en frío o moverlo a un callable con las mismas validaciones. Agregar status a ChatModel, ocultar o atenuar los chats bloqueados, deshabilitar el composer con un banner. Matriz de flags testeada (on/off) en CI.

### FL-17 · P1 · monetization · ✅ confirmado
**Plus sin base en el cliente: lista de espera que no registra nada, flags de compilación, sin entitlements, sin triggers e incógnito y radio regalados**

- **Evidencia:** lib/screens/plus/plus_screen.dart:45-66 (snackbar 'Quedaste en la lista de espera' sin escritura; texto de dev con RevenueCat; 'precios propuestos, no finales' visible); lib/core/config/app_config.dart:53-62 (bool.fromEnvironment); lib/core/constants/santiago_bounds.dart:22 (slider hasta 10000) vs functions/src/pure/distance.ts:33-39 (cap gratis 5000); functions/src/getNearby.ts (no lee la visibilidad del que llama); lib/screens/profile/profile_screen.dart:261-275
- **Detalle:** (a) 'Avisarme' confirma la inscripción sin guardarla ni medirla: es engañoso y se pierde la señal de demanda de la Fase L. (b) plus_enabled/waves_enabled no se pueden encender por comuna o cohorte sin una release (el megaprompt pedía Remote Config). (c) Una persona gratis que mueve el slider a 10 km ve '10 km' y recibe en silencio solo 5 km: no hay paywall. (d) El toggle gratis 'Visible' en false oculta a la persona y aun así puede usar getNearby, o sea, el 'Modo incógnito' que Plus vende sale gratis. (e) El paywall no tiene selector de plan, equivalente mensual tabular ni links a Términos/Privacidad (Apple 3.1.2), y 'Restaurar compras' es un snackbar.
- **Recomendación:** MonetizationRepository (Demo/RevenueCat) + entitlementProvider; Remote Config para los flags con defaults seguros; waitlist/{uid} + evento paywall_viewed{trigger}; triggers de cuota, radio > 5 km (candado en el slider) e incógnito; el servidor exige isVisible del que llama o Plus para ver sin aparecer; paywall completo según §7.4 con tests de widget.

### FL-18 · P1 · false_claim · 🟡 parcial
**Design system v2 'Hecho' solo de nombre: AppColors e isDark aumentaron y solo existe 1 componente Pf***

- **Evidencia:** git grep AppColors. en lib/screens + lib/widgets: 279 → 289; isDark: 204 → 210; context.pf/Pf* fuera del DS solo en splash_screen.dart y picaflor_avatar.dart; lib/core/design_system/components/ solo tiene pf_mark.dart; docs/PLAN.md:11 ('Hecho. Goldens no')
- **Detalle:** §5.3 prohibía que los widgets leyeran AppColors o hicieran isDark ? … : …. Grok convirtió AppColors en un alias de PfPalette y dejó los 289 usos. AppShadows multicapa sigue con 13 usos. Para pasar el gate se borraron 29 'fontSize:' en pantallas y widgets y solo se agregaron 14 estilos de token: _BrandMark ('P') ya no escala con size (lib/screens/shell/main_shell.dart:312-318) y se perdieron los tamaños de desktop de los headers (nearby/chat_list/profile). No hay cifras tabulares (0 FontFeature en lib/).
- **Recomendación:** Exigir en v2 la biblioteca Pf* de §5.4 con goldens. Migración por pantalla con un ratchet: un archivo baseline con el conteo de AppColors/isDark/Colors. que el CI obliga a bajar en cada PR hasta llegar a 0. Reemplazar cada fontSize borrado por un estilo de token, nunca borrarlo sin reemplazo.
- **Verificación (partial):** Todo verificado salvo un dato: el uso de Pf* fuera del DS no está 'solo en splash_screen.dart y picaflor_avatar.dart'. Aparece en 4 archivos: PfMark en login_screen.dart:185, settings_screen.dart:222 y splash_screen.dart:64; PfType en splash_screen.dart:33 y picaflor_avatar.dart:183. No hay ningún uso de context.pf. La conclusión ('Hecho' solo de nombre) se mantiene.

### FL-19 · P1 · process · ✅ confirmado
**tool/gates.sh tiene falsos negativos sistemáticos y no mide la regla del design system**

- **Evidencia:** tool/gates.sh:7-24; resultados: 35 'Colors.*' literales, 3 'Radius.circular(<n>)' (lib/widgets/chat_bubble.dart:71-72, lib/core/theme/app_theme.dart:282), 289 AppColors y 210 isDark en la UI, 18 letterSpacing literales, 0 chequeo de strings; el gate sale con exit 0
- **Detalle:** El gate solo busca Color(0x, fontSize: y BorderRadius.circular(<dígito>), así que deja pasar Colors.white, Radius.circular(18), AppColors.* directos, isDark, EdgeInsets o SizedBox numéricos y textos hardcodeados. El gate de PII es de una sola línea: no ve debugPrint multilínea, no mira uid, phone ni name, y no revisa developer.log. Con pipefail, si grep falla con exit 2 (por ejemplo si falta lib), el gate pasa como 'sin coincidencias'. setMockInitialValues solo se revisa en main.dart. BASELINE presenta D5 como resuelto 'en CI'.
- **Recomendación:** Reescribir los gates en Dart (custom_lint o un script con package:analyzer basado en AST) con reglas: no AppColors/isDark/Colors.* (salvo transparent) ni literales numéricos de radio, color o tipografía fuera de design_system; no Text('literal') fuera de l10n; logs sin identificadores. Incluir tests del propio gate con fixtures que deben fallar.

### FL-20 · P1 · process · ✅ confirmado
**Los tests nuevos son de funciones puras o de código muerto: 0 widget tests y ninguno toca los flujos rotos**

- **Evidencia:** test/v2_policy_test.dart (8 tests); test/*.dart suman 23 tests y 0 testWidgets; MemoryAnalytics (app_analytics.dart) no se usa en lib/; NearbyPolicy.resolve recibe demoPeople: const [] fijo (lib/providers/nearby_provider.dart:104-110)
- **Detalle:** 'production nearby never fills with demo people' prueba una función pura que el provider ya llama con demoPeople vacío: no prueba el provider. El test de analytics prueba una clase que la app nunca instancia. El de MemoryKeyValueStore es tautológico (escribe false y lee false). El de contraste valida pares de tokens, no los usos reales (ver FL-22). Ningún test cubre onboarding (FL-06), chat (FL-07), settings/borrado (FL-05) ni ficha y saludo (FL-14).
- **Recomendación:** v2 exige un widget test por pantalla y estado (loading/vacío/error/datos/offline), tests de providers con ProviderContainer y fakes de repositorio (incluido un 'prod no resuelve Demo*'), golden tests con Inter cargada y meetsGuideline (contraste, tap target, labels), y cobertura ≥ 80% en domain/application con umbral en CI.

### FL-21 · P1 · ops · ✅ confirmado
**El CI no corre format, functions, reglas ni builds nativos; Flutter sin versión fija**

- **Evidencia:** .github/workflows/ci.yml:1-37 (sin dart format, sin job de functions ni firestore-tests, sin umbral de coverage, android-release con if: false, sin iOS); subosito/flutter-action con channel: stable sin flutter-version
- **Detalle:** El fallo verificado de 'npm run build' en functions (TS2441) no lo detecta el CI porque no hay job de functions. Las líneas >80 en archivos nuevos (p. ej. lib/features/safety/safety_controller.dart:61, lib/screens/chat/chat_screen.dart:95) harían fallar 'dart format --set-exit-if-changed' (probable; no hay dart en el contenedor). Sin una versión de Flutter fija, los builds no son reproducibles. on: [push, pull_request] sin concurrency duplica las corridas.
- **Recomendación:** Jobs obligatorios: format, analyze, test con coverage y umbral, gates; functions (npm ci, lint, build, test); emulador de reglas y functions; build apk --debug/--release sin firma con un keystore de prueba efímero y build ios --no-codesign; flutter-version fijada; concurrency. Gate de merge: todos en verde.

### FL-22 · P1 · design · 🟡 parcial
**Contraste insuficiente en dark mode en código nuevo y en colores de marca fijos**

- **Evidencia:** lib/widgets/public_profile_sheet.dart:93-97 (AppColors.lightTextSecondary #4A5363 fijo, también en dark); AppColors.primary = PfPalette.brand #0B7A6F usado como texto o ícono en ambos temas (p. ej. lib/screens/chat/chat_screen.dart:326-329)
- **Detalle:** #4A5363 sobre la superficie dark #12171E da ≈2.3:1 (calculado con WCAG 2.x), así que 'Tu ubicación exacta nunca se comparte' es ilegible en dark. #0B7A6F sobre #0B0F14 da ≈3.7:1, bajo AA para texto normal. El test de contraste solo valida pares de tokens y no detecta usos cruzados entre temas.
- **Recomendación:** Los widgets solo usan context.pf.colors (tokens resueltos por tema). Golden y meetsGuideline(textContrastGuideline) en light y dark para cada pantalla.
- **Verificación (partial):** Confirmado el caso principal: 'Tu ubicación exacta nunca se comparte' queda en 2.32:1 en dark. #0B7A6F también falla AA (3.45-3.69:1) cuando se usa como texto en dark, por ejemplo en el título seleccionado del selector de tema (settings_screen.dart:374). El ejemplo citado (chat_screen.dart:326-329) es un ícono decorativo sobre un círculo tintado (≈3.3:1), que cumple el 3:1 de WCAG 1.4.11 para no-texto, así que no es evidencia de la violación.

### FL-23 · P1 · gap · ✅ confirmado
**Accesibilidad y l10n prácticamente sin hacer: 2 Semantics en todo lib/, 0 ARB, tap targets < 48**

- **Evidencia:** grep 'Semantics(|semanticLabel|semanticsLabel' en lib = 2; no existe lib/l10n ni l10n.yaml; lib/screens/chat/chat_screen.dart:224-227 (IconButton atrás sin tooltip); lib/screens/nearby/nearby_screen.dart:632-633 (38×38); lib/widgets/picaflor_person_card.dart:331 (44×44)
- **Detalle:** TalkBack y VoiceOver leen 'botón' sin etiqueta en el back del chat, el avatar con punto de actividad no tiene semántica y el botón de Google lee 'Google' dos veces. Todo el copy nuevo está hardcodeado. Con la escala de texto ahora libre, no hay ninguna prueba al 200%.
- **Recomendación:** ARB es_CL + gen-l10n y un gate de strings. Semantics/tooltip en cada control accionable, tamaño mínimo 48. Tests con androidTapTargetGuideline, iOSTapTargetGuideline y labeledTapTargetGuideline, más goldens a 2.0 en onboarding, login, Cerca, chat y paywall.

### FL-24 · P1 · compliance · ✅ confirmado
**Requisitos de tienda pendientes en la capa Flutter: botón de Google no oficial, SIWA sin entitlement, sin push y sin crash reporting**

- **Evidencia:** lib/screens/auth/login_screen.dart:488-494 (Text('G')); find ios -name '*.entitlements' → vacío; pubspec.yaml sin firebase_messaging ni firebase_crashlytics; functions/src/onMessageCreated.ts:56-73 envía push a fcmTokens que el cliente nunca registra
- **Detalle:** La 'G' en texto incumple las guías de marca de Google Sign-In (D3 sigue abierto según el propio BASELINE). Sign in with Apple sin la capability falla en iOS (preexistente, bloquea el lanzamiento en iOS). Sin firebase_messaging, los saludos y mensajes no notifican y el loop de liquidez muere. Sin crash reporting no hay calidad medible.
- **Recomendación:** Usar el asset oficial de Google o google_sign_in con un botón conforme; Runner.entitlements con com.apple.developer.applesignin; firebase_messaging con registro de tokens en users/{uid}.fcmTokens (permiso contextual tras el primer saludo); Crashlytics sin PII; PrivacyInfo.xcprivacy si corresponde (supuesto, verificar).

### FL-25 · P1 · ops · ✅ confirmado
**DEMO_MODE sigue en true por defecto y el DemoGuard solo actúa con FLAVOR=prod explícito**

- **Evidencia:** lib/core/config/app_config.dart:14-17 (defaultValue: true), :47-50 (FLAVOR default 'dev'); lib/core/privacy/nearby_policy.dart:57-66; .github/workflows/deploy-web.yml (demo_mode default 'true', channelId: live, projectId: picaflorapp)
- **Detalle:** 'flutter build appbundle --release' sin defines (con keystore) genera un binario demo con perfiles inventados que pasa el guard, porque FLAVOR=dev. Así, S8 puede llegar a la tienda por un descuido de configuración. El dominio de producción, donde vive /privacidad para las fichas de tienda, sirve el demo por defecto.
- **Recomendación:** Flavors reales con --dart-define-from-file=env/<flavor>.json y FLAVOR obligatorio en release (kReleaseMode && !kIsWeb && demoMode && FLAVOR!='dev' → crash al arrancar, y también un check en Gradle/Xcode). Demo web en un sitio o canal de Hosting separado con un banner 'Demo'. Test del guard con matriz de defines.

### FL-26 · P2 · design
**Etiquetas de distancia con precisión falsa e incoherentes con los buckets; atribución del mapa duplicada**

- **Evidencia:** lib/services/user_service_live.dart:150 (distanceMeters = displayMeters(bucket)); lib/screens/nearby/nearby_screen.dart:1069 (formatApproxDistance); lib/core/utils/location_privacy.dart:84-97; lib/widgets/nearby_map.dart:217-262
- **Detalle:** El bucket km5 (2,5 a 6 km) se muestra como '~4,5 km', km10 como '~8,0 km' y very_close como 'cerca'; mientras tanto DistanceBuckets.label dice '~5 km', '~10 km' y 'muy cerca'. Eso aparenta una precisión que no existe. El mapa muestra dos atribuciones (la vieja '© OpenStreetMap' sin CARTO en light y la nueva). Con MAP_TILE_URL de otro proveedor sigue diciendo '© CARTO'.
- **Recomendación:** Las tarjetas, la ficha y el mapa usan solo DistanceBuckets.label. Atribución única que se derive del proveedor configurado.

### FL-27 · P2 · scalability
**Listeners que se acumulan y suscripciones que pueden quedar abiertas**

- **Evidencia:** lib/providers/user_provider.dart:8-13 (StreamProvider.family sin autoDispose); lib/services/chat_service.dart:56-70,73-87,113-127 (Stream.multi asigna onCancel después de await _ensureLive)
- **Detalle:** Cada perfil visto (Cerca, chats, ficha) deja un listener de Firestore vivo mientras dure la app, y sigue vivo después del logout (errores de permiso, costo). Si el stream se cancela mientras carga la librería diferida, la suscripción interna nunca se cancela. Preexistente, pero el código nuevo lo amplifica.
- **Recomendación:** autoDispose + keepAlive con TTL; asignar onCancel antes del await y cancelar al completar; invalidar todo lo que depende de la sesión al cambiar el uid.

### FL-28 · P2 · compliance
**Exportar mis datos muestra un Map.toString() en un diálogo**

- **Evidencia:** lib/screens/settings/settings_screen.dart:411-433
- **Detalle:** No es un formato estructurado ni descargable o compartible (la portabilidad de la Ley 21.719 pide un formato estructurado y de uso común). Con datos grandes el diálogo no sirve. La copia del subtítulo menciona 'producción' al usuario final.
- **Recomendación:** Generar JSON (y opcionalmente un ZIP con los mensajes) y ofrecerlo vía share_plus o descarga en web; enviar el evento export_requested sin PII; copy revisado.

### FL-29 · P2 · design
**Detalles de UX: X del paywall inútil por deep link, CTA 'Chatear' que abre la ficha, 'Mensajes anteriores' siempre visible y autoscroll forzado**

- **Evidencia:** lib/screens/plus/plus_screen.dart:18-22 (maybePop); lib/widgets/picaflor_person_card.dart:308,323 ('Chatear'); lib/screens/chat/chat_screen.dart:365-377,208-214
- **Detalle:** En web, al abrir /plus directamente la X no hace nada. Con los saludos activos, el CTA dice 'Chatear' pero abre la ficha. El botón 'Mensajes anteriores' aparece aunque haya menos de 80 mensajes. Cada mensaje entrante lleva el scroll al final aunque la persona esté leyendo el historial.
- **Recomendación:** canPop ? pop : go(home); CTA 'Saludar'; paginación por scroll hacia arriba que solo se ofrece cuando hay más; autoscroll solo si ya se estaba al final y, si no, una píldora de 'nuevos mensajes'.

### FL-30 · P2 · ops
**La región está hardcodeada como const aunque el ADR dice 'alinear el define'; falta evaluar Santiago**

- **Evidencia:** lib/core/config/app_config.dart:75 (const 'southamerica-east1' sin fromEnvironment); docs/adr/0005-region-southamerica-east1.md
- **Detalle:** No se puede cambiar por flavor sin tocar código. Los datos y la latencia quedan en São Paulo. Hay que verificar si Firestore y Functions de 2.ª gen están disponibles en southamerica-west1 (Santiago) para la residencia de datos y la latencia (supuesto a verificar en la consola).
- **Recomendación:** String.fromEnvironment('FUNCTIONS_REGION') por flavor; decisión humana documentada con una medición de latencia.

### FL-31 · P2 · bug
**KeyValueStore: timeout de 500 ms que cae a memoria en silencio**

- **Evidencia:** lib/main.dart:127-137
- **Detalle:** En dispositivos lentos o en el primer arranque web, SharedPreferences puede tardar más de 500 ms: la persona vuelve a pasar por el onboarding, pierde el tema y el radio, y todo lo que escriba en esa sesión se pierde. No hay telemetría de ese fallback.
- **Recomendación:** Timeout ≥ 2 s o SharedPreferencesWithCache/Async; si se cae a memoria, reintentar en segundo plano y migrar; registrar un evento no-PII 'prefs_fallback'.

**Requisitos que esta lente exige para la v2**

- Contrato cliente↔reglas↔functions: cada escritura Firestore y cada payload de callable que produce el código Dart se exporta como fixture JSON y firestore-tests/functions lo prueba en casos allow/deny en el emulador. CI rojo si diverge (cubre FL-03, FL-15, FL-16).
- App Check en el cliente: firebase_app_check activado por plataforma y flavor (Play Integrity, App Attest y reCAPTCHA Enterprise en web; debug provider en dev), con un test de integración contra functions con enforceAppCheck.
- Onboarding atado a la cuenta: callable acceptOnboarding que valida 18+ en el servidor, escribe users/{uid}.birthDate inmutable y consents{terms,privacy,analytics}{version,ts}. El router decide con ese estado del servidor. Widget test del cambio de cuenta en el mismo dispositivo y del botón Siguiente en los 3 pasos.
- Loop de saludo completo y verificable: un stream de saludos entrantes, 'Saludos nuevos (n)' con Aceptar/Ignorar (respondWave), un chat que aparece para ambos (lastMessageAt seteado), errores de FirebaseFunctionsException mapeados a es-CL y resource-exhausted que abre el paywall. Test e2e en el emulador de saludar → aceptar → chatear → bloquear → reportar → eliminar cuenta.
- Eliminar cuenta: borrado + signOut solo local (sin touchActivity), limpieza de prefs y del estado de sesión, errores con UI y reintento; test en emulador que verifique que no queda ningún documento con el uid después del flujo completo.
- Presencia: nada de activityBucket persistido; lastActiveAt escrito al reanudar la app (throttle de 15 min) y en el alta, nunca en signOut; el bucket se calcula al leer. Test de un perfil inactivo 8 días.
- Chat: paginación con DocumentSnapshot (startAfterDocument) sin ventana deslizante, dedupe por id, markRead por cambio del último id entrante y no leídos calculados respecto de lastRead en el servidor. Widget test con 120 mensajes + 5 entrantes = 125 contiguos y unread=0 con el chat abierto.
- Cerca: getNearby se ejecuta después de que updateLocation confirma (dependencia explícita en un AsyncNotifier), devuelve el resumen público (sin N+1), refresh real y caché con TTL. Presupuesto: 1 callable + 0 lecturas extra por refresh, medido en el emulador.
- Seguridad por sesión: SafetyRepository hidratado desde blocks/, invalidado al cambiar el uid, con rollback ante error. El reporte se envía primero y el bloqueo es opcional ('Además, bloquear'); texto libre para 'Otro'; refs a chat/mensaje; pantalla de Usuarios bloqueados con desbloqueo; ChatModel.status con el composer deshabilitado cuando está bloqueado.
- Monetización en el cliente: MonetizationRepository (Demo/RevenueCat), entitlementProvider desde entitlements/{uid}, flags en Remote Config con defaults seguros, waitlist persistida + evento, triggers de cuota, radio > 5 km e incógnito, servidor que niega 'ver sin aparecer' a quien no tiene Plus, y paywall según §7.4 con links legales, selector de plan y cifras tabulares. Sin textos de dev visibles.
- Design system real: la biblioteca Pf* de §5.4 con goldens light/dark a 1.0, 1.3 y 2.0; los widgets solo consumen context.pf.*; un ratchet en CI con baseline de AppColors/isDark/Colors. que solo puede bajar hasta 0; ningún fontSize borrado sin reemplazarlo por un estilo de token.
- Gates basados en AST (custom_lint o analyzer) con tests de fixtures que deben fallar: colores, radios y tipografía literales, AppColors e isDark fuera del DS, Text('literal') fuera de l10n, logs con uid/email/lat/lon/token, imports de demo desde la UI o los providers de prod.
- Accesibilidad y l10n: ARB es_CL + gen-l10n con cero strings en widgets; Semantics/tooltip en todo control accionable; mínimo 48 dp; meetsGuideline de contraste y tap targets (android, iOS, labeled) en cada widget test de pantalla.
- Tests reales: un widget test por pantalla y estado, tests de providers con ProviderContainer y fakes (incluido 'prod no resuelve Demo*'), cobertura ≥ 80% en domain/application con umbral en CI. Se prohíben los tests de código muerto y los tautológicos.
- CI completo y reproducible: Flutter fijado, dart format, analyze --fatal-infos, test con coverage y umbral, gates, job de functions (npm ci, lint, build, test), emulador de reglas y functions, builds de Android e iOS sin firma, concurrency; deploy del demo a un sitio o canal separado del dominio de producción.
- Guard de release: FLAVOR obligatorio vía --dart-define-from-file; crash al arrancar si kReleaseMode && demoMode en móvil; check equivalente en Gradle/Xcode; región de functions por define y decisión documentada (evaluar southamerica-west1).
- Requisitos de tienda en el cliente: botón de Google oficial, entitlement de Sign in with Apple, firebase_messaging con registro de tokens y permiso contextual, Crashlytics sin PII, export de datos en JSON compartible y etiquetas de distancia derivadas solo de los buckets.
- Cada 'Hecho' en BASELINE/PLAN se respalda con la salida de un comando o test que lo pruebe; A12 (red team) adjunta intentos concretos (cambio de cuenta, cuota, bloqueo, borrado, 120 mensajes, 200% de texto).

**Cifras clave**

| Métrica | Valor | Base |
|---------|-------|------|
| Callables con enforceAppCheck que usa el cliente sin SDK de App Check | 8 (getNearby, updateLocation, touchActivity, sendWave, respondWave, blockUser, deleteAccount, exportMyData) | functions/src/https.ts:7 + grep httpsCallable en lib/; pubspec.yaml sin firebase_app_check |
| Tests Flutter totales / widget tests | 23 / 0 (8 nuevos en v2_policy_test.dart) | grep -cE '^\s*(test|testWidgets)\(' test/*.dart |
| Referencias AppColors. en screens/widgets antes → después | 279 → 289 | git grep -c 'AppColors\.' 02abbd4 vs HEAD -- lib/screens lib/widgets |
| Usos de isDark en screens/widgets antes → después | 204 → 210 | git grep -c isDark 02abbd4 vs HEAD |
| Componentes Pf* implementados / pedidos en §5.4 | 1 (PfMark) / ~22 | find lib/core/design_system/components |
| Líneas 'fontSize:' borradas en screens/widgets vs estilos de token agregados | 29 borradas / 14 agregadas | git diff 02abbd4 HEAD -- lib/screens lib/widgets | grep |
| Literales que el gate no detecta | 35 Colors.*, 3 Radius.circular(n), 18 letterSpacing literales | grep sobre HEAD fuera de lib/core/design_system; tool/gates.sh sale con exit 0 |
| Semantics/semanticLabel en todo lib/ | 2 | grep -rn 'Semantics(|semanticLabel|semanticsLabel' lib |
| Archivos ARB de l10n | 0 | lib/l10n no existe |
| Lecturas secuenciales de perfil por refresh de Cerca | hasta 50 (N+1) dentro de un timeout de 8 s | lib/services/user_service_live.dart:126-136, lib/providers/nearby_provider.dart:87 |
| Ventana viva de mensajes / tamaño de página | 80 / 40 | lib/services/chat_service_live.dart:65; lib/services/chat_service.dart:94-97 |
| Contraste de lightTextSecondary sobre la superficie dark (ficha pública) | ≈2.3:1 | cálculo WCAG 2.x #4A5363 vs #12171E (supuesto: la superficie del sheet es surfaceDark) |
| Contraste de brand #0B7A6F como texto sobre canvas dark | ≈3.7:1 | cálculo WCAG 2.x #0B7A6F vs #0B0F14 |
| Radio gratis permitido en el slider vs cap del servidor | 10.000 m vs 5.000 m (corte silencioso) | lib/core/constants/santiago_bounds.dart:22; functions/src/pure/distance.ts:33-39 |
| Tiempo de debounce de markRead vs cold start del trigger | 350 ms vs varios segundos (carrera) | lib/screens/chat/chat_screen.dart:76; latencia del trigger supuesta |

## BE · Backend Firebase (reglas, Functions, índices)

**Veredicto de la lente**

Veredicto backend: Grok cerró bien S1-S3 en las reglas. `locations` es solo para el servidor, `users` es privado y el chat usa `diff().affectedKeys()` con `participantIds` y `status` inmutables. Los 11 tests de reglas pasan 11/11 en el emulador (lo verifiqué). Pero el backend NO es lanzable ni tier-1:
(1) El build de functions falla (TS2441), no hay predeploy y el CI no tiene ningún job de backend.
(2) Todos los callables exigen App Check, pero el cliente no integra `firebase_app_check`, así que en producción Cerca, saludos, bloqueo, borrado de cuenta y export fallan.
(3) Las reglas niegan los payloads reales del cliente: `updateProfile` siempre envía `updatedAt` y queda DENY (verificado en el emulador).
(4) `birthDate` nunca llega a Firestore y `getNearby` oculta a quien no la tiene, así que Cerca queda vacía para todos.
(5) La ubicación se puede trilaterar a la celda p7 (~127x153 m) en ≤9 sondas (~3 min). Lo simulé con el código de Grok (30/30 objetivos) porque `updateLocation` acepta cualquier coordenada y `getNearby` no tiene rate limit.
(6) El bucle de saludos no está conectado en producción (los saludos entrantes salen de memoria).
(7) El runtime es Node 20 (EOL).
Además, `getNearby` no escala: hasta ~6.400 lecturas por llamada, trunca usuarios en zonas densas y cubre solo el 5,8% del radio de 10 km que se le vende a Plus. Plus tiene bypass (incógnito gratis), el webhook de RevenueCat pisa Plus al comprar un boost y no usa Secret Manager, y `deleteAccount` y `exportMyData` están incompletos para la Ley 21.719. Hice 20 sondas adversariales sobre las reglas: 8 permitieron escrituras que deberían negarse y 2 negaron escrituras legítimas del cliente.

**Lo que está bien y se preserva**

- S1 a nivel de reglas: `locations/{uid}` tiene read/write false y solo escribe el Admin SDK (firestore.rules:143-145). Verificado: un cliente no lee ni escribe locations.
- S2: `users/{uid}` solo lo lee el dueño (firestore.rules:119-128). Email y tokens FCM salen del documento público y `profiles/{uid}` es un perfil mínimo.
- S3 resuelto bien: `chatMetaUpdateOk` usa `diff().affectedKeys().hasOnly(['unreadCount','lastRead','muted'])`, `participantIds` y `status` son inmutables y `mapDiffOnlySelf` deja tocar solo la clave propia (firestore.rules:87-117). Verificado: cambiar el unreadCount del otro o el status da DENY.
- Hay catch-all `/{document=**}` en deny. `waves`, `entitlements` y `webhookEvents` no aceptan escrituras del cliente. `list` sobre `profiles` queda negado (verificado), así que no hay enumeración masiva por query.
- El rate limit de `updateLocation` es real y persistente: lee `locations/{uid}.updatedAt` dentro de una transacción (updateLocation.ts:28-33). No es in-memory por instancia.
- El fuzz y el geohash p7 se calculan en el servidor, y `updateLocation` borra `latitude`/`longitude`/`isOnline` heredados de `users` (updateLocation.ts:38-46).
- `getNearby` filtra bloqueos en ambos sentidos, recencia ≤7 días, 18+, incógnito con excepción por saludo, y devuelve solo `{uid, distanceBucket, activityBucket}` (getNearby.ts:131-183, pure/nearbyFilter.ts).
- Webhook: `timingSafeEqual`, falla cerrado si no hay secreto, autentica antes de tocar Firebase e idempotencia transaccional por `event.id` (pure/webhookAuth.ts, revenuecatWebhook.ts:42-57).
- Push sin contenido: título y cuerpo genéricos, y `data` lleva solo `chatId` (pure/push.ts).
- `respondWave` es transaccional (lee antes de escribir), usa un chatId determinístico, revisa bloqueos y solo el receptor responde (waves.ts:86-142).
- `deleteAccount` pide `confirm: 'ELIMINAR'`, borra Auth al final (se puede reintentar) y anonimiza los mensajes propios.
- La lógica pura está separada y testeada (10 tests). El cupo diario se calcula en America/Santiago. Los logs no tienen PII.
- Decisión de App Check fail-closed documentada en un ADR (0003). Está bien en principio.

**Hallazgos**

### BE-01 · P0 · ops · sin verificar
**Build de functions roto, sin predeploy y sin CI de backend: deploy no reproducible**

- **Evidencia:** functions/src/pure.test.ts:23 (`const require = createRequire(__filename)` → TS2441, reproducido con tsc --outDir en scratch); functions/tsconfig.json:18 incluye src/**/*.ts (tests incluidos); firebase.json:9-21 sin `predeploy`; .github/workflows/ci.yml sin ningún job de functions ni firestore-tests; docs/BASELINE.md:36-44 (solo se corrió npm test)
- **Detalle:** `npm run build` sale con código ≠0. Si se agrega el predeploy estándar (lint+build), `firebase deploy` falla. Sin predeploy se despliega un `lib/` local que está en .gitignore, así que no hay build reproducible desde un clone limpio. Como el CI no corre lint, build, tests ni el emulador, el error llegó a la rama sin detectarse. `npm run lint` (tsc --noEmit) pasa y da falsa confianza.
- **Recomendación:** Crear tsconfig.build.json que excluya src/**/*.test.ts (o renombrar `require` en el test). Agregar en firebase.json `predeploy: ["npm --prefix \"$RESOURCE_DIR\" run lint", "npm --prefix \"$RESOURCE_DIR\" run build"]`. Crear un job CI `backend` con npm ci, lint, build, test y `firebase emulators:exec --only firestore,storage,auth,functions` corriendo las reglas y la integración; el job bloquea el merge. Criterio: `npm run build` sale con 0 en CI, con el log adjunto.

### BE-02 · P0 · bug · sin verificar
**Callables con enforceAppCheck:true pero el cliente no integra App Check: todos los callables fallan en producción**

- **Evidencia:** functions/src/https.ts:5-8 (`enforceAppCheck: true` en callableOptions, usado por los 9 callables); pubspec.yaml (bloque dependencies) sin firebase_app_check; `grep -rn AppCheck lib web` → 0 resultados; docs/adr/0003-app-check-fail-closed.md
- **Detalle:** En producción, updateLocation, getNearby, sendWave, respondWave, blockUser, deleteAccount, exportMyData y touchActivity responden `unauthenticated`/App Check inválido. Cerca, el bucle de saludos, el bloqueo, el borrado de cuenta (Apple 5.1.1(v) y política de Google Play) y el export (Ley 21.719) no funcionan. El ADR lo atribuye a la configuración de consola, pero falta el SDK en el cliente: no basta con 'que el humano lo configure'.
- **Recomendación:** Integrar `firebase_app_check` (Play Integrity en Android, App Attest con fallback DeviceCheck en iOS, reCAPTCHA Enterprise en web, proveedor debug en dev/emulador) antes de cualquier llamada. Forzar App Check también en Firestore y Storage (pasos en DEPLOY.md). Usar `consumeAppCheckToken: true` en deleteAccount, sendWave y exportMyData. Criterio: test de humo contra el emulador y un staging real que llame cada callable con token válido (OK) y sin token (rechazado).

### BE-03 · P0 · bug · sin verificar
**Las reglas de profiles niegan los payloads reales del cliente: no se puede editar perfil, visibilidad ni foto**

- **Evidencia:** lib/services/user_service_live.dart:83-91 (`updateProfile` siempre agrega 'updatedAt'); lib/services/user_service_live.dart:44 (`createUser` agrega 'age'); firestore.rules:69-71 (`profileClientKeys` sin updatedAt ni age) y 136-138. Verificado en el emulador: set merge {isVisible:false, updatedAt} → DENY; create con age → DENY; sin updatedAt → ALLOW
- **Detalle:** Toda edición de perfil, el toggle 'Visible en Cerca' y la foto desde Google/Apple (auth_service_live.dart:333) fallan con PERMISSION_DENIED en producción. El cliente traga el error con debugPrint. Los tests de reglas no lo detectaron porque no usan los payloads del cliente. Además, `age` no puede vivir en profiles, así que la tarjeta 'Camila, 29' de la spec no se puede mostrar.
- **Recomendación:** Alinear el contrato: o `updatedAt` en profileClientKeys con `== request.time`, o que el cliente no lo envíe. `age` (o ageBucket) lo escribe solo el servidor, derivado de birthDate. Agregar tests de contrato: por cada escritura del cliente, un test de reglas con el payload EXACTO que arma el código Dart (allow) y variantes maliciosas (deny).

### BE-04 · P0 · bug · sin verificar
**birthDate nunca se persiste en Firestore y getNearby oculta a quien no la tiene: Cerca vacía para todos**

- **Evidencia:** lib/screens/onboarding/onboarding_screen.dart:63-69 (birthDate solo va a SharedPreferences); `grep birth lib/services` → 0 escrituras; functions/src/pure/nearbyFilter.ts:40 (`if (!candidate.birthDate || !isAdult(...)) continue`); getNearby.ts:169 lee users.birthDate
- **Detalle:** En producción ningún usuario tiene `users/{uid}.birthDate`, así que `filterNearbyPeople` descarta a todos y Cerca siempre devuelve []. Tampoco se guardan consentimientos en el servidor. La verificación 18+ existe solo en el dispositivo y se pierde al reinstalar.
- **Recomendación:** Crear el callable `completeOnboarding({birthDate, consents:{terms,privacy,analytics,version}})`: valida 18+ en el servidor, escribe birthDate (inmutable después), deriva `profiles.age`, registra el consentimiento append-only con serverTimestamp, y el cliente lo llama antes de habilitar Cerca. Test de integración en el emulador: un usuario recién onboardeado y visible aparece en getNearby de otro usuario cercano.

### BE-05 · P0 · security · sin verificar
**Trilateración: la celda p7 de cualquier usuario (~127×153 m) se recupera en ≤9 sondas; también se puede scrapear el directorio**

- **Evidencia:** functions/src/updateLocation.ts:13-20 + pure/grid.ts:13-27 (acepta cualquier lat/lon del planeta, sin límites de servicio ni chequeo de velocidad); pure/rateLimit.ts:1 (solo 20 s); getNearby.ts:30-183 (sin rate limit, devuelve uid + distanceBucket calculado entre centros de celdas p7); pure/distance.ts:22-29 (umbral de 150 m). Simulación con las funciones de Grok: 30/30 objetivos localizados a su celda p7 exacta, mediana 8 y máximo 9 sondas (≈3 min por cuenta)
- **Detalle:** Un atacante con sesión mueve su posición declarada (cada 20 s y a cualquier punto), llama getNearby sin límite y observa el bucket del uid objetivo. La búsqueda adaptativa fija la celda exacta. De noche esa celda es la cuadra de la casa de la víctima, y con varias cuentas el ataque se paraleliza. Además, como getNearby devuelve uids y `profiles` se puede leer por uid, recorrer Santiago (~20 posiciones) arma un directorio completo de nombres, fotos y zonas. El threat model (docs/security/threat-model.md) no lo contempla. S1 queda cerrado en las reglas, pero sigue abierto por esta vía.
- **Recomendación:** (a) updateLocation: polígono o bbox del Gran Santiago en el servidor, velocidad plausible (p. ej. ≤150 km/h entre updates; si no se cumple, se rechaza y la cuenta queda congelada 10 min), máximo ~20 celdas distintas por día. (b) Distancia calculada desde la celda de consulta p6 del que mira (no desde su p7) con bucket mínimo 'menos de 1 km', y ruido estable por par HMAC(viewer,target,día). (c) Rate limit persistente en getNearby (p. ej. 10/min y 60/h por uid). (d) Agregar al CI el script de simulación como test: tras 100 sondas, la incertidumbre del atacante debe seguir ≥500 m. (e) Opcional: ids opacos por viewer.

### BE-06 · P0 · ops · sin verificar
**Runtime Node 20 (EOL 2026-04-30) para un lanzamiento en Q4-2026**

- **Evidencia:** functions/package.json:5-7 (`engines.node: "20"`), :19 @types/node 20.17.30
- **Detalle:** Node 20 ya no recibe parches de seguridad. El calendario de runtimes de Cloud Functions marca deprecación y luego decommission. Supuesto a verificar: si el patrón es deprecación + 6 meses, el decommission de nodejs20 caería alrededor del 2026-10-30, y crear funciones nuevas en un runtime deprecado puede quedar bloqueado. El proyecto todavía no tiene funciones desplegadas.
- **Recomendación:** Subir a nodejs22 como mínimo, o nodejs24 si Cloud Functions y firebase-functions lo soportan (verificar en cloud.google.com/functions/docs/runtime-support y con `npm view firebase-functions version`). Alinear @types/node, fijar versiones y registrar el ADR. Criterio: `firebase deploy --only functions --dry-run` OK en el runtime nuevo.

### BE-07 · P0 · gap · sin verificar
**Bucle central de saludos sin conectar en producción; falta índice y respondWave crea chats invisibles**

- **Evidencia:** lib/features/waves/wave_actions.dart:23-43 y wave_models.dart:39-41 (saludos entrantes y cupo desde `memoryWaves` en memoria; ids 'wave_N'); `grep collection('waves') lib` → 0; firestore.indexes.json sin (to,status,createdAt); waves.ts:128-137 (chat nuevo sin `lastMessageAt`); lib/services/chat_service_live.dart:45-46 (`orderBy('lastMessageAt')` excluye documentos sin ese campo)
- **Detalle:** El receptor nunca ve los saludos reales de Firestore. respondWave recibe ids en memoria que no existen y devuelve not-found. Aunque se aceptara, el chat creado no tiene lastMessageAt y no aparece en la lista de chats de ninguno de los dos hasta el primer mensaje. Si existía un chat previo en 'blocked', aceptar no lo reactiva. El loop 'ver → saludar → aceptar → chat', que es la North Star, no funciona en producción.
- **Recomendación:** El cliente escucha `waves where to==uid && status=='pending' orderBy createdAt desc limit 50` (agregar el índice compuesto). respondWave escribe `lastMessageAt = createdAt` y reactiva `status` si no hay bloqueo. Test e2e en el emulador: sendWave → aparece en el listener del receptor → respondWave → el chat aparece en watchUserChats de ambos.

### BE-08 · P1 · false_claim · sin verificar
**Las celdas de consulta 3×3 de geohash p5 no cubren el radio: Plus paga 10 km y recibe ~5-6 km**

- **Evidencia:** functions/src/pure/geohash.ts:5-11 (comentario: 'cover the 10 km Plus radius') y :139-142; pure/distance.ts:31-37. Simulación con queryPrefixesFor y storedGeohash de Grok (400 posiciones × 36 rumbos): cobertura 4 km 100%, 5 km 93,7%, 7 km 56,7%, 10 km 5,8%
- **Detalle:** Una celda p5 en Santiago mide ≈4,08 km (E-O) × 4,89 km (N-S). El bloque 3×3 garantiza solo ~4 km. Desde el borde de la celda, el radio gratis de 5 km ya pierde el 6% de los puntos y el de 10 km de Plus pierde el 94%. El bucket 'km10' casi nunca aparece. Vender un beneficio que no se entrega es un riesgo de publicidad engañosa (Ley 19.496) y de reembolsos.
- **Recomendación:** Elegir la precisión de las celdas según el radio (p6 para ≤1,2 km, p5 para ≤4 km, p4 o anillo k=2 de p5 para 10 km) o usar H3 res 7/8 con k-ring. Test de propiedad: para posiciones aleatorias en Santiago, ≥99,9% de los puntos a distancia ≤ radio están dentro de las celdas consultadas, para cada preset (500 m, 1, 2, 5 y 10 km).

### BE-09 · P1 · scalability · sin verificar
**getNearby: hasta ~6.400 lecturas por llamada, truncado lexicográfico en zonas densas, sin TTL ni paginación, y N+1 en el cliente**

- **Evidencia:** functions/src/getNearby.ts:13 (PER_PREFIX_LIMIT=150 sin orderBy), :54-61 (9 queries por rango), :80-87 (3 getAll por candidato + 2 queries de waves con limit 500), :132 (devuelve todos los resultados, sin límite); lib/services/user_service_live.dart:133 (`await getUser(uid)` secuencial por persona); no hay TTL en locations (firestore.indexes.json:37)
- **Detalle:** Peor caso: 9×150 + 3×1.350 + 2×500 + 2 ≈ 6.400 lecturas facturables y latencia alta (São Paulo + getAll en serie). Como `limit(150)` sin orden toma los primeros geohash lexicográficos, en el centro de Santiago se devuelve una subzona fija de cada celda, llena de usuarios inactivos (las ubicaciones nunca expiran), y se descartan personas activas cercanas. El bug B5 vuelve en otra forma. Encima el cliente hace hasta 50 lecturas de perfil en serie. Estimación (supuesto de US$0,06 por 100k lecturas): con 10k DAU × 5 llamadas × ~2.000 lecturas son ~US$1.800 al mes solo en Cerca. Sin rate limit es además un vector de abuso de costos.
- **Recomendación:** Crear `nearbyIndex/{uid}` desnormalizado y mantenido por triggers y callables: cell, visible, adult, lastActiveAt, boostUntil y la tarjeta pública mínima. Query `where cell in [...]` + `lastActiveAt >= now-7d` + `orderBy lastActiveAt desc` + limit, con índice compuesto. TTL `expireAt` en locations/nearbyIndex. Respuesta paginada (máximo 50 + cursor) con la tarjeta incluida, sin N+1. Presupuesto verificable: p95 ≤300 lecturas y ≤800 ms por llamada en el emulador con un seed de 20k usuarios en Santiago.

### BE-10 · P1 · security · sin verificar
**Mensajes: claves y createdAt libres, sin chequeo de bloqueos en reglas, y bloqueo directo que deja el chat activo**

- **Evidencia:** firestore.rules:161-171 (no hay keys().hasOnly ni validación de createdAt), :174-178 (el cliente crea y borra blocks con cualquier payload). Verificado en el emulador: mensaje con createdAt 2099, type 'system', imageUrl y blob de 500 KB → ALLOW; bloqueo por escritura directa en blocks/bob/blocked/alice y luego alice escribe en el chat activo → ALLOW; block con payload de 400 KB → ALLOW
- **Detalle:** Se pueden falsificar el orden y la paginación (createdAt futuro fija un mensaje arriba), inyectar mensajes 'system' o imágenes externas que el cliente puede renderizar, y meter documentos de hasta 1 MB (costo y crash en el cliente). Mensajes tras bloqueo: hoy se cierran solo si el bloqueo pasa por la callable blockUser (que cambia chat.status). Si el bloqueo se escribe directo (permitido por las reglas) o la callable falla después del set (blockUser.ts:15-25 no es atómico), el bloqueado sigue escribiendo. No hay unblock que restaure el chat.
- **Recomendación:** Reglas: `keys().hasOnly(['senderId','text','type','createdAt','chatId','imageUrl','isRead'])`, `createdAt == request.time`, `type == 'text'`, `imageUrl == null`, y `!blockedEitherWay(otro)` calculando el otro desde participantIds. Bloqueos solo por callable (cliente create/delete=false) o con un trigger onCreate de blocks que marque el chat. blockUser en batch atómico. Callable `unblockUser`. Tests deny para cada caso de esta lista.

### BE-11 · P1 · security · sin verificar
**El dueño puede escribir libremente lastActiveAt, birthDate y consents: presencia falsa, edad mutable y consentimiento sin valor probatorio**

- **Evidencia:** firestore.rules:18-36 y 121-126 (userKeys incluye lastActiveAt, birthDate, consents y settings sin validar contenido). Verificado en el emulador: lastActiveAt=2099 → ALLOW; reescribir birthDate → ALLOW; consents con ts 'whatever' → ALLOW. functions/src/touchActivity.ts:10,15-17 (fija profiles.activityBucket='ahora' para siempre, sin rate limit)
- **Detalle:** Un usuario aparece 'ahora' permanentemente (B4 sigue abierto) y sube en ranking. Puede cambiar su fecha de nacimiento después de un reporte de 'posible menor'. Los consentimientos escritos por el cliente no sirven como evidencia ante la Ley 21.719, que rige en plenitud desde el 1-12-2026, en 55 días. profiles.activityBucket nunca decae.
- **Recomendación:** Sacar lastActiveAt, birthDate y consents de los campos escribibles por el cliente. birthDate se escribe vía completeOnboarding y es inmutable. consents va a `users/{uid}/consentEvents/{id}` append-only con serverTimestamp y versión. touchActivity limitado a 1 cada 5 min. activityBucket se calcula al leer, no se persiste. Tests deny.

### BE-12 · P1 · monetization · sin verificar
**Plus sin enforcement completo en servidor: incógnito gratis y la mayoría de los beneficios sin backend**

- **Evidencia:** firestore.rules:62,70 (isVisible escribible por cualquier usuario, verificado ALLOW); getNearby.ts:30-52 (no valida que el que mira sea visible o Plus); pure/nearbyFilter.ts:41; no existen callables ni campos para filtros avanzados, visitas al perfil, Destacar 30 min, deshacer saludo ni explorar otra comuna
- **Detalle:** Cualquiera se pone isVisible=false y sigue viendo a todos sin aparecer, que es exactamente el beneficio 'Modo incógnito' de Plus (paywall bypass). Del paquete Plus solo están en servidor los saludos ilimitados, la nota y el radio (este último roto, ver BE-08). Tampoco hay métricas de liquidez en servidor (personas activas ≤3 km por sesión y por comuna), que son el gate para encender Plus según la §7.1.
- **Recomendación:** Separar `isVisible` (gratis: quien no aparece tampoco ve) de `incognito` (lo escribe solo el servidor según el entitlement). getNearby rechaza ver si el que mira no es visible ni Plus. Backend para boost (`boostUntil` en nearbyIndex y ledger de créditos), profileViews, cancelWave y filtros por edad/intereses en getNearby. Agregado diario de liquidez sin PII por celda p5/comuna (colección metrics o export a BigQuery). Tests de bypass desde el cliente.

### BE-13 · P1 · monetization · sin verificar
**revenuecatWebhook: secreto fuera de Secret Manager, el boost pisa Plus, eventos sandbox o desordenados alteran entitlements**

- **Evidencia:** functions/src/revenuecatWebhook.ts:12-15 (`process.env.REVENUECAT_WEBHOOK_SECRET` sin defineSecret ni `secrets:[]`), :42-57 (set merge plan/expiresAt sin comparar event_timestamp_ms); pure/revenuecat.ts:10,20-26 (solo EXPIRATION quita acceso; un producto sin 'plus' y sin entitlement_ids da plan 'free' y expiresAt null)
- **Detalle:** La comparación timing-safe está bien, pero el secreto queda en .env en texto plano o undefined (el webhook queda siempre en 401). Si un usuario Plus compra `boost_30m` (NON_RENEWING_PURCHASE, sin entitlement), el evento escribe plan 'free' y pierde Plus hasta la próxima renovación (reembolsos y reclamos). No se filtra environment SANDBOX: compras de TestFlight o tester gratuitas darían Plus en producción. Un evento viejo reintentado pisa el estado nuevo. TRANSFER o SUBSCRIBER_ALIAS sin app_user_id devuelven 400 y RevenueCat reintenta. Un app_user_id `$RCAnonymousID` crea entitlements huérfanos. webhookEvents crece sin TTL. Latente porque Plus está apagado (ADR 0002), pero bloquea encenderlo.
- **Recomendación:** `defineSecret('REVENUECAT_WEBHOOK_SECRET')` + `secrets:[...]`. Tras autenticar, reconciliar con la API REST de RevenueCat (GET /v1/subscribers/{id}) como fuente de verdad en vez de mapear tipos de evento. Ignorar SANDBOX en el proyecto prod. Los consumibles van a un ledger `boostCredits` que nunca toca `plan`. Verificar que el uid exista en Auth. TTL de 90 días en webhookEvents. Tests: el boost no pisa Plus, un evento viejo no pisa uno nuevo, un duplicado es idempotente, Bearer inválido da 401 y TRANSFER se maneja.

### BE-14 · P1 · security · sin verificar
**sendWave: cupo y duplicado con condición de carrera, sin cooldown tras 'ignored' y sin validar destinatario ni remitente**

- **Evidencia:** functions/src/waves.ts:49-71 (lecturas y escritura fuera de transacción), :51-56 (solo bloquea si hay uno 'pending'), :27-30 (toUid solo valida largo), :73-81 (id aleatorio)
- **Detalle:** N llamadas concurrentes leen sentToday=19 y todas escriben, así que se supera el límite de 20 y se crean saludos pendientes duplicados. Tras un 'ignored' se puede volver a saludar de inmediato: un usuario Plus (ilimitado) puede acosar a la misma persona sin fin. Se puede saludar a cualquier uid filtrado (sin verificar que exista, sea adulto, esté visible o dentro del radio del plan), y el remitente no necesita ser adulto ni tener perfil.
- **Recomendación:** ID determinístico `${from}_${to}` o contador `waveCounters/{uid}_{yyyymmdd}` en transacción. Cooldown por par tras 'ignored' (p. ej. 14 días, también para Plus) y tope de N saludos por par al mes. Validar destinatario (existe, adulto, visible o con saludo previo, dentro del radio) y remitente (adulto, perfil completo, sin baneo). Test de carrera: 25 llamadas concurrentes resultan en exactamente 20 aceptadas.

### BE-15 · P1 · compliance · sin verificar
**deleteAccount: cascada incompleta, síncrona y sin protección de sesión**

- **Evidencia:** functions/src/deleteAccount.ts:42-54 (borra waves `from` pero no `to`; no toca chats ni reports), :18-32 (anonimiza mensajes pero deja chat.lastMessage, lastMessageSenderId y unreadCount con el uid), :56-60 (traga errores de Storage), :62-67 (sin revokeRefreshTokens), sin chequeo de auth_time; timeout por defecto
- **Detalle:** Quedan saludos recibidos con el uid, el preview de 140 caracteres del último mensaje, el chat en 'active' (el otro sigue escribiendo al vacío), los reportes, el cliente en RevenueCat y la suscripción de la tienda cobrando sin aviso. Con el ID token vigente hasta 1 h, el cliente puede recrear users, profiles y locations (documentos zombie sin Auth). Una cuenta con mucho historial puede exceder el timeout y quedar a medias. Una sesión robada borra la cuenta sin re-autenticación. Respuesta `purgeWithinDays: 30` sin política de backups/PITR documentada.
- **Recomendación:** Trabajo durable: `deletionRequests/{uid}` + trigger con reintentos (o Cloud Tasks), BulkWriter y recursiveDelete. Cubrir waves from/to, chats (status 'closed', lastMessage anonimizado), mensajes, reports según la política de retención, Storage (falla si no se puede borrar), entitlements, DELETE del subscriber en RevenueCat, docs de rate limit y consentimientos con retención legal mínima. revokeRefreshTokens antes de borrar. Exigir auth_time ≤5 min. Avisar si Plus está activo, con link a gestionar la suscripción. Test en el emulador: después de la cascada, un barrido de todas las colecciones encuentra 0 documentos con el uid salvo la evidencia legal declarada.

### BE-16 · P1 · compliance · sin verificar
**exportMyData incompleto, síncrono y sin rate limit**

- **Evidencia:** functions/src/exportMyData.ts:10-19 (sin Auth record, consents, reports propios, metadatos de chats ni archivos de Storage), :21-29 (todos los mensajes leídos en línea), :31-41 (Timestamps de Firestore serializados como objetos internos)
- **Detalle:** La portabilidad y el acceso de la Ley 21.719 exigen un export completo y legible. Faltan datos de Auth (proveedores, email, fechas), consentimientos, reportes enviados, participantes de los chats, foto de perfil y compras. Con mucho historial la respuesta del callable puede exceder los límites y el timeout. Sin límite, cada llamada relee todo, lo que da un vector de costo.
- **Recomendación:** Job asíncrono que genera un JSON (ISO-8601) en `exports/{uid}/{ts}.json` con URL firmada de 72 h; máximo 1 cada 24 h. Incluir Auth, users, profiles, consentEvents, celda de ubicación, waves, blocks, reports enviados, metadatos de chats y mensajes propios, entitlements y archivos de Storage. Test de esquema contra un fixture.

### BE-17 · P1 · gap · sin verificar
**Push: sin registro de tokens en el cliente, sin limpiar tokens inválidos y sin respetar mute; trigger no idempotente**

- **Evidencia:** functions/src/onMessageCreated.ts:54-71 (ignora `result.responses`), :41-50 (increment de unreadCount sin deduplicar por event.id); pubspec.yaml sin firebase_messaging (nadie escribe fcmTokens); `muted` existe en reglas (firestore.rules:113-116) pero el trigger no lo consulta
- **Detalle:** Hoy no llega ninguna notificación, porque nadie registra tokens. Cuando se registren, los tokens `registration-token-not-registered` se acumulan para siempre, los chats silenciados siguen notificando y una reentrega del evento (at-least-once) duplica el contador de no leídos. El contenido del push sí está bien protegido. Sin push, la retención y la tasa de respuesta (North Star) caen.
- **Recomendación:** Cliente con firebase_messaging guardando en `users/{uid}/fcmTokens/{token}` con updatedAt. El trigger borra los tokens que fallan con not-registered o invalid-argument, respeta `muted[uid]` y las preferencias, y deduplica con `processedEvents/{event.id}`. Tests con messaging mockeado.

### BE-18 · P1 · security · sin verificar
**Reportes sin target ni validación de claves, sin cola de moderación ni mecanismo de baneo**

- **Evidencia:** firestore.rules:180-187 (exige reporterId, reason y text; no exige reportedUid, no tiene keys().hasOnly ni createdAt==request.time). Verificado: report sin target y con 400 KB de basura → ALLOW. No existe flag ni claim `banned` en reglas ni en functions; docs/security/threat-model.md:20 ('un humano tiene que leerlos en consola')
- **Detalle:** Se pueden crear reportes inútiles o inflar el storage, y no hay dedupe ni límite (reportes como arma). Lo central: aunque se lean los reportes, no existe ninguna forma de actuar. No se puede suspender a un usuario de modo que reglas y callables lo respeten, y Apple 1.2 exige actuar sobre contenido o usuarios reportados (la app promete 'lo revisamos en menos de 24 h').
- **Recomendación:** Callable `reportUser` (o reglas estrictas) con reportedUid obligatorio, contexto (chatId/messageId), dedupe por par y día, rate limit y opción de bloqueo en el mismo paso. Cola `moderationQueue` priorizada (minor/harassment). Custom claim `banned` revisado en reglas (`request.auth.token.banned != true`) y en `requireUid`. Script o consola admin mínima y SLA documentado. Tests.

### BE-19 · P1 · security · sin verificar
**Fotos: photoUrl acepta cualquier URL externa; Storage permite SVG, acumulación ilimitada, sin borrado ni limpieza de EXIF**

- **Evidencia:** firestore.rules:63-65 (photoUrl es cualquier string ≤500; verificado: 'https://evil.example/pixel.gif' → ALLOW); storage.rules:5-10 (`image/.*` incluye svg+xml, cualquier fileName sin límite de cantidad, `write` con request.resource no permite delete, lectura para cualquier sesión)
- **Detalle:** Un perfil con photoUrl a un servidor propio funciona como píxel de rastreo: registra la IP y el horario de cada persona que lo mira en Cerca o en el chat, y salta cualquier moderación de imágenes. Al habilitar la subida (D9), las fotos de teléfono traen EXIF con GPS (coordenadas exactas legibles por cualquier sesión) y los archivos se acumulan sin límite (costo).
- **Recomendación:** photoUrl lo escribe solo el servidor, o las reglas exigen el patrón del bucket propio `avatars/{uid}/avatar.jpg`. Storage: allowlist image/jpeg, png y webp, nombre fijo (sobrescribe), delete del dueño permitido. Trigger onObjectFinalized que re-encode a WebP o JPEG sin metadatos (elimina EXIF y GPS), redimensione y opcionalmente pase por SafeSearch. Tests de storage rules en el emulador.

### BE-20 · P1 · process · sin verificar
**Cobertura de tests insuficiente: 11 tests de reglas, 0 de Storage, 0 de integración de Functions**

- **Evidencia:** firestore-tests/rules.test.ts (11 tests; pasan 11/11 en el emulador v1.22.0, verificado); functions/src/pure.test.ts (10 tests puros); docs/BASELINE.md:44 ('No se corrieron en esta máquina')
- **Detalle:** La §11.1 pedía allow/deny por colección y tests de Functions en el emulador (cupo, filtros de getNearby, cascada de deleteAccount, idempotencia del webhook). Faltan casos de get/list/update/delete por colección, de waves, blocks y reports, y de payloads del cliente. Por eso pasaron BE-03, BE-10, BE-11, BE-18 y BE-19: de 20 sondas adversariales que ejecuté, 8 permiten escrituras que deberían negarse y 2 niegan escrituras legítimas del cliente.
- **Recomendación:** Matriz de reglas con ≥60 casos (colección × get/list/create/update/delete × dueño/extraño/bloqueado/no autenticado), incluidas las 20 sondas de esta auditoría. Tests de storage.rules. Integración de Functions con `firebase emulators:exec` (auth+firestore+functions) para los 9 callables y los 2 triggers. Publicar el reporte de cobertura de reglas del emulador como artefacto de CI.

### BE-21 · P1 · security · sin verificar
**Rate limiting solo en 1 de 9 callables; App Check sin protección contra replay**

- **Evidencia:** pure/rateLimit.ts (solo updateLocation); getNearby, touchActivity, blockUser, exportMyData, sendWave (Plus ilimitado), respondWave y deleteAccount sin límite; functions/src/https.ts:5-8 sin consumeAppCheckToken; index.ts:4 maxInstances 20 global
- **Detalle:** Un token de App Check extraído de un dispositivo real se reutiliza durante todo su TTL. Con una sesión se puede martillar getNearby (costo de ~6k lecturas por llamada) o exportMyData. `maxInstances: 20` global hace que un abusador sature la capacidad de todos los callables, incluido el trigger de mensajes.
- **Recomendación:** Rate limiter genérico persistente (token bucket transaccional en `rateLimits/{uid}_{acción}` con TTL) aplicado a todos los callables y a los reportes, con presupuestos por acción documentados. consumeAppCheckToken en acciones sensibles. maxInstances, concurrency, memory y timeoutSeconds por función. Tests: la llamada N+1 dentro de la ventana devuelve resource-exhausted.

### BE-22 · P2 · scalability
**Índices y TTL: faltan compuestos y políticas TTL, y hay riesgo de hotspot en locations.updatedAt**

- **Evidencia:** firestore.indexes.json:1-38 (`fieldOverrides: []`; sin (to,status,createdAt) en waves; sin TTL); updateLocation.ts:34-37 (updatedAt monotónico en una colección top-level)
- **Detalle:** El índice de campo único sobre `locations.updatedAt` recibe valores monotónicos. Por encima de ~500 escrituras/s (p. ej. ~10k usuarios activos con updates cada 20 s) aparece hotspotting. webhookEvents, waves vencidos y ubicaciones viejas crecen sin límite. Indexar `messages.text` y `reports.text` cuesta sin aportar nada.
- **Recomendación:** Agregar índices para las queries nuevas (waves entrantes, nearbyIndex). Políticas TTL con campo `expireAt` en webhookEvents, locations/nearbyIndex, waves y rateLimits. Exenciones de índice para locations.updatedAt (si no se consulta), messages.text y reports.text. En CI, validar con un deploy dry-run que cada query del código tiene su índice.

### BE-23 · P2 · design
**Región, configuración y entornos sin decisión verificada**

- **Evidencia:** functions/src/https.ts:3 y lib/core/config/app_config.dart:75 (southamerica-east1); docs/adr/0005-region-southamerica-east1.md:13 (afirma sin evidencia que southamerica-west1 'no ofrece el mismo set'); .firebaserc (un solo proyecto 'picaflorapp', sin alias staging/prod); onMessageCreated.ts:3-6 (trigger en la región fija)
- **Detalle:** La región es una decisión del humano según la §13.7. Santiago (southamerica-west1) bajaría la latencia y la afirmación del ADR no se verificó (supuesto: Firestore, Cloud Run functions y Cloud Storage estarían disponibles en southamerica-west1). El trigger de Firestore 2nd gen debe coincidir con la ubicación de la base: si la consola crea la DB en otra región, el deploy falla. Sin alias staging/prod no hay flavors de backend.
- **Recomendación:** ADR con la tabla de disponibilidad por región verificada en la documentación oficial a la fecha y la decisión firmada por el humano. Región en una sola constante compartida (functions y `--dart-define`). Alias `dev`, `staging` y `prod` en .firebaserc con proyectos separados. Script que valide que la ubicación de la DB coincide con la región de los triggers antes del deploy.

### BE-24 · P2 · security
**Oráculos de privacidad: perfil de incógnito legible por uid y bloqueo detectable**

- **Evidencia:** firestore.rules:131 (perfil legible por cualquier sesión si no hay bloqueo; verificado: get de un perfil con isVisible:false → ALLOW); el blockedEitherWay del perfil da DENY al bloqueado (verificado) y chat.status='blocked' es visible para ambos
- **Detalle:** Quien conoce un uid (de chats viejos o de un scraping previo) ve el perfil de alguien que se ocultó. El bloqueado puede inferir el bloqueo. Es un trade-off aceptable si se documenta, pero conviene mitigarlo.
- **Recomendación:** Leer el perfil exige relación (resultado de Cerca vigente, saludo o chat) o que el perfil esté visible. Mostrar el chat bloqueado como 'no disponible' sin exponer quién bloqueó. Documentarlo en el threat model.

### BE-25 · P2 · design
**Moderación de texto estática, post-hoc y con falsos positivos**

- **Evidencia:** functions/src/pure/moderate.ts:1-32 (cualquier 'https://', 'www.', 'whatsapp', 'cripto'); onMessageCreated.ts:25-29 (reescribe el texto después de que el receptor pudo verlo en tiempo real)
- **Detalle:** Mensajes legítimos ('te paso mi Instagram www...', 'criptografía') se reemplazan en silencio por 'Mensaje eliminado' sin avisar al emisor. El contenido abusivo ya llegó al receptor por el listener antes de la reescritura y no queda registro para revisión.
- **Recomendación:** Enviar mensajes por callable (o con estado `pending` hasta pasar moderación) cuando se marquen. Avisar al emisor. Registrar en moderationQueue. Lista es-CL versionada y testeada con casos positivos y negativos.

### BE-26 · P2 · security
**Hosting sin cabeceras de seguridad**

- **Evidencia:** firebase.json:95-157 (solo Cache-Control)
- **Detalle:** La PWA y /eliminar-cuenta no tienen CSP, X-Frame-Options/frame-ancestors (clickjacking sobre flujos sensibles), Referrer-Policy ni Permissions-Policy para geolocation.
- **Recomendación:** Agregar CSP compatible con Flutter web (script-src con hashes o 'self', connect-src a *.googleapis.com y CARTO/proveedor de tiles), `frame-ancestors 'none'`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy: geolocation=(self)` y `X-Content-Type-Options: nosniff`. Verificar con curl -I en el preview channel.

### BE-27 · P2 · gap
**Sin migración ni backfill de datos heredados a profiles y locations**

- **Evidencia:** No existe script ni función de migración; los usuarios heredados tienen users/{uid} con displayName y lat/lon (diagnóstico S1/S2) pero no tienen profiles/{uid}; updateLocation.ts:38-46 limpia solo al llamarse
- **Detalle:** Si existe base heredada (supuesto, no verificado), esos usuarios quedan invisibles y sin perfil público, y sus coordenadas viejas siguen en users hasta que vuelvan a abrir la app.
- **Recomendación:** Script idempotente de migración (Admin SDK) con dry-run y reporte: crea profiles con la allowlist, borra lat/lon/isOnline/fcmToken legados y crea nearbyIndex. Correrlo en staging y registrar el resultado.

**Requisitos que esta lente exige para la v2**

- Backend compila y despliega reproduciblemente: tsconfig.build.json excluye *.test.ts; `npm ci && npm run lint && npm run build && npm test` en functions sale con código 0; firebase.json tiene predeploy lint+build; job CI `backend` obligatorio para merge que además corre `firebase emulators:exec --only auth,firestore,storage,functions` con tests de reglas e integración. Pegar el log.
- Runtime nodejs22 o nodejs24 (verificado en la página de runtime-support de Cloud Functions a la fecha) con @types/node acorde y firebase-functions/firebase-admin en la última estable verificada con `npm view`; ADR del cambio.
- App Check integrado en el cliente (firebase_app_check: Play Integrity, App Attest/DeviceCheck, reCAPTCHA Enterprise web, proveedor debug en dev) y forzado en Functions, Firestore y Storage; consumeAppCheckToken en deleteAccount, sendWave y exportMyData; test de humo: cada callable con token OK, sin token rechazado.
- Tests de contrato cliente↔reglas: por cada escritura del cliente (createUser, updateProfile, markChatAsRead, sendTextMessage, submitReport, uploads) un test con el payload EXACTO que arma el código Dart (allow) y ≥2 variantes maliciosas (deny).
- Callable completeOnboarding({birthDate, consents}) que valida 18+, persiste birthDate inmutable, deriva profiles.age y registra consentimiento append-only con serverTimestamp y versión; las reglas niegan que el cliente escriba birthDate, lastActiveAt y consents (tests deny).
- Defensa anti-trilateración verificable: updateLocation con límites del Gran Santiago, velocidad máxima plausible y tope de celdas distintas por día; distancia desde la celda de consulta (≥p6) con bucket mínimo 'menos de 1 km' y ruido estable por par; rate limit persistente en getNearby; el script de simulación de ataque corre en CI y exige incertidumbre ≥500 m tras 100 sondas.
- Geo-índice escalable: nearbyIndex/{uid} desnormalizado (cell, visible, adult, lastActiveAt, boostUntil, tarjeta pública) con TTL; celdas de consulta según el radio con test de cobertura ≥99,9% para 500 m, 1, 2, 5 y 10 km; p95 ≤300 lecturas y ≤800 ms por getNearby con un seed de 20k usuarios; respuesta paginada (≤50 + cursor) que incluye la tarjeta (sin N+1).
- Bucle de saludos conectado de punta a punta en producción: listener `waves to==uid && status==pending orderBy createdAt desc` con índice; respondWave escribe lastMessageAt y reactiva el chat si no hay bloqueo; test e2e en el emulador sendWave → listener → respondWave → chat visible para ambos.
- sendWave transaccional (ID determinístico o contador diario), cooldown por par tras 'ignored' también para Plus, validación de destinatario (existe, adulto, visible, dentro del radio del plan) y remitente (adulto, perfil completo, sin baneo); test de 25 llamadas concurrentes da exactamente 20 aceptadas.
- Reglas de mensajes con keys().hasOnly, createdAt == request.time, type == 'text', y chequeo de bloqueo en ambos sentidos; bloqueos solo por callable o trigger (cliente sin create/delete directo en blocks), blockUser atómico y callable unblockUser; tests deny de mensaje tras bloqueo por cualquier vía.
- Enforcement de Plus en servidor: separar isVisible (gratis; quien no aparece no ve) de incognito (lo escribe solo el servidor según el entitlement); backend para boost (ledger de créditos + boostUntil en el ranking), visitas, deshacer saludo y filtros; tests de bypass desde el cliente para cada beneficio.
- Webhook de RevenueCat con defineSecret y `secrets:[]`, reconciliación vía API REST de RevenueCat como fuente de verdad, SANDBOX ignorado en prod, consumibles en ledger separado que nunca toca `plan`, orden por event_timestamp_ms, TRANSFER y alias manejados, TTL en webhookEvents; tests: el boost no pisa Plus, un evento viejo no pisa uno nuevo, duplicado idempotente, 401 con Bearer inválido.
- deleteAccount durable (deletionRequests + trigger con reintentos o Cloud Tasks) que cubre Auth, users, profiles, locations/nearbyIndex, waves from/to, chats (cerrados y anonimizados), mensajes, reports según la política de retención, Storage, entitlements, subscriber de RevenueCat y rate limits; revokeRefreshTokens y auth_time ≤5 min; aviso de suscripción activa; test de barrido que exige 0 documentos con el uid salvo la evidencia legal declarada.
- exportMyData asíncrono a Storage con URL firmada de 72 h, máximo 1 cada 24 h, timestamps ISO-8601 y contenido completo (Auth, users, profiles, consentEvents, celda, waves, blocks, reports enviados, chats y mensajes propios, entitlements, archivos); test de esquema.
- Push operativo: registro de tokens con firebase_messaging, limpieza de tokens inválidos según la respuesta de sendEachForMulticast, respeto de muted y preferencias, deduplicación por event.id; payload sin contenido del mensaje (mantener).
- Rate limiter persistente genérico (token bucket transaccional con TTL) en los 9 callables y en reportes, con presupuestos por acción documentados; maxInstances, memory y timeoutSeconds por función; tests de resource-exhausted.
- Trust & Safety operable: reportUser con reportedUid obligatorio, dedupe y límite; moderationQueue; custom claim `banned` respetado por reglas y callables; script o consola admin y SLA de 24 h documentado.
- Fotos seguras: photoUrl limitado al path propio del bucket o escrito solo por el servidor; Storage con allowlist jpeg/png/webp, nombre fijo y delete del dueño; trigger que re-encode y elimine EXIF y GPS; tests de storage.rules en el emulador.
- Matriz de tests de reglas ≥60 casos (colección × get/list/create/update/delete × dueño/extraño/bloqueado/no autenticado), incluidas las 20 sondas adversariales de esta auditoría, con el reporte de cobertura del emulador como artefacto de CI.
- Índices y TTL completos en firestore.indexes.json (waves entrantes, nearbyIndex, TTL en webhookEvents/locations/waves/rateLimits, exenciones para locations.updatedAt, messages.text y reports.text) validados por un deploy dry-run en CI.
- Decisión de región con evidencia (tabla de disponibilidad oficial de southamerica-west1 frente a southamerica-east1 a la fecha) firmada por el humano; triggers en la región de la DB; alias dev/staging/prod en .firebaserc.
- Métrica de liquidez en servidor sin PII (personas activas ≤3 km por sesión, agregada por celda p5 o comuna, diaria) para gatillar el encendido de Plus según la §7.1.
- Cabeceras de seguridad de Hosting (CSP, frame-ancestors 'none', Referrer-Policy, Permissions-Policy geolocation=(self), nosniff) verificadas con curl -I.
- Threat model actualizado con trilateración, scraping, píxel de rastreo vía photoUrl, replay de App Check, abuso de costos y zombies post-borrado, cada uno con su mitigación y su test.

**Cifras clave**

| Métrica | Valor | Base |
|---------|-------|------|
| Lecturas Firestore por llamada a getNearby (peor caso) | ≈6.400 (9×150 + 3×1.350 + 2×500 + 2 + bloqueos propios) | functions/src/getNearby.ts:13,54-61,80-87 |
| Cobertura real del bloque 3×3 geohash p5 según la distancia | 4 km 100% · 5 km 93,7% · 7 km 56,7% · 10 km 5,8% | Simulación con queryPrefixesFor y storedGeohash de Grok (400 posiciones × 36 rumbos en Santiago) |
| Tamaño de celda geohash en Santiago | p5 ≈ 4,08 × 4,89 km; p7 ≈ 127 × 153 m | Cálculo a partir de los bits del geohash a una latitud de -33,45° |
| Sondas para trilaterar la celda p7 exacta de un usuario | mediana 8, máximo 9 (30/30 objetivos) ≈ 3 min por cuenta con el límite de 20 s | Simulación adaptativa con distanceBucket y storedGeohash de Grok |
| Tests de reglas de Grok | 11/11 pasan | Verificado: tsx --test rules.test.ts contra el emulador Firestore v1.22.0 (puerto aislado) |
| Sondas adversariales de reglas ejecutadas | 20: 8 permiten escrituras que deberían negarse y 2 niegan escrituras legítimas del cliente | Verificado en el emulador (scratchpad/be-audit/probe.cjs) |
| Callables con rate limit | 1 de 9 (updateLocation, 20 s, persistente en Firestore) | functions/src/pure/rateLimit.ts, revisión de los 9 callables |
| Tests de Functions | 10 unitarios puros · 0 de integración en el emulador | functions/src/pure.test.ts |
| Costo estimado de Cerca con el diseño actual | ≈US$1.800/mes con 10k DAU × 5 llamadas × ~2.000 lecturas (≈US$270/mes con ≤300 lecturas por llamada) | supuesto: precio ~US$0,06 por 100k lecturas y perfil de uso estimado |
| maxInstances global | 20 para todas las funciones | functions/src/index.ts:4 |
| Días hasta la plena vigencia de la Ley 21.719 | 55 (al 1-12-2026) | Instrucciones 06.10.26.md §S12 y fecha de hoy 2026-10-07 |

## CV · Cumplimiento del megaprompt v1

**Veredicto de la lente**

Veredicto: lo que Grok declara está bastante por encima de lo que hay en el código. En papel cerró las fases 0, 1, 2, 4, 5 y 7. En la práctica, la rama no puede lanzarse: en producción el loop central (Cerca → saludo → chat) está roto por 7 P0 verificados. (1) updateLocation siempre lanza, porque la transacción lee después de escribir. (2) birthDate nunca llega a Firestore y getNearby oculta al 100% de los usuarios. (3) No hay UI para recibir ni aceptar saludos, así que nunca se crea un chat. (4) Las reglas de profiles rechazan todas las escrituras del cliente: editar el perfil, cambiar la visibilidad y el login con foto. (5) La presencia sigue siendo falsa. (6) Functions no compila para deploy. (7) App Check se exige en el servidor pero no existe en el cliente. Lo bien hecho es real pero acotado: reglas default-deny, split users/profiles, funciones puras testeadas, S9/S10/S11/D8/B1-B3/B6/B8. El proceso no cumplió el §13: un solo commit de 124 archivos (+4.824 líneas sin contar lockfiles ni fuentes), avanzó a la Fase 1 sin aprobación verificable, no hay screenshots, goldens ni red team, y la BASELINE se tomó después de los cambios. pubspec.lock (−686 líneas) y los generated_plugin_registrant son legítimos: salen de quitar 10 dependencias sin uso (A5), con 0 cambios de versión. No es basura.
TABLA: S1 parcial · S2 parcial · S3 hecho · S4 parcial · S5 parcial · S6 parcial · S7 FALSO · S8 parcial · S9 hecho · S10 hecho · S11 hecho · S12 parcial | B1 hecho · B2 hecho · B3 hecho · B4 FALSO · B5 parcial · B6 hecho · B7 parcial · B8 hecho | D1 parcial · D2 parcial · D3 no hecho · D4 hecho · D5 parcial (gate esquivado) · D6 parcial · D7 parcial · D8 hecho · D9 no hecho | A1 no · A2 hecho · A3 no · A4 no · A5 hecho · A6 parcial · A7 parcial | Fases: F0 parcial · F1 hecho sin tests de regresión · F2 parcial (0/21 componentes) · F3 no · F4 no · F5 parcial · F6 parcial con P0 · F7 mínimo (lista de espera ficticia) · F8 no. Totales §4: 13 hechos, 16 parciales, 5 no hechos, 2 falsos.

**Lo que está bien y se preserva**

- firestore.rules con default-deny (firestore.rules:198-200), users solo para el dueño, profiles públicos con filtro de bloqueo, locations/waves/entitlements/webhookEvents cerrados al cliente y validación diff().affectedKeys() del meta del chat con participantIds inmutable (firestore.rules:96-117): S3 bien resuelto.
- La lógica de servidor está separada en módulos puros testeables (functions/src/pure/*: geohash, grilla, buckets, edad, cupo con zona horaria America/Santiago, moderación, webhookAuth) con 10 tests que pasan.
- El webhook de RevenueCat falla cerrado si no hay secreto, compara con timingSafeEqual y es idempotente por event id (functions/src/pure/webhookAuth.ts, revenuecatWebhook.ts:40-57).
- El push no incluye el contenido del mensaje (functions/src/pure/push.ts).
- S9 (solo COARSE y When In Use, precisión low), S10 (el release sin keystore aborta, build.gradle.kts), S11 (atribución visible), D8 (url_launcher + package_info_plus), B1 (userByIdProvider), B2 (sessionProvider), B3 (debounce de 350 ms) y B6 (fetchOlderMessages) están implementados.
- B8 está bien resuelto: KeyValueStore en memoria sin APIs de test y con test ('memory prefs do not mark onboarding done').
- S8 en la capa de política: NearbyPolicy nunca rellena con perfiles de demo en producción y tiene test.
- El cliente difumina la ubicación antes de enviarla, el servidor la vuelve a difuminar y guarda un geohash p7. Los pines del mapa salen de un anillo calculado desde el bucket, no de la coordenada.
- Los tokens de color coinciden exactamente con §5.2. Inter está empaquetada como TTF real, con la licencia OFL.
- A5 está limpio: se quitaron 10 dependencias sin uso y con ellas 76 paquetes transitivos, sin subir versiones. pubspec.lock y los generated_plugin_registrant quedaron coherentes y sin CRLF.
- 7 ADRs con contexto, decisión, alternativas y consecuencias, y decisiones humanas bien delimitadas (isotipo, precios, región, App Check, mapa de pago).
- No desplegó, no tocó cuentas de tienda ni firma fuera de S10 y no commiteó secretos (escaneo del diff sin coincidencias).
- El CI ahora corre en todo push y PR, con un gate estático. Verificado: bash tool/gates.sh devuelve exit 0.

**Hallazgos**

### CV-01 · P0 · false_claim · sin verificar
**updateLocation siempre falla (lectura después de escritura en la transacción): S1/B5 'hecho' es falso en runtime**

- **Evidencia:** functions/src/updateLocation.ts:34 tx.set(locRef) y :38 tx.get(userRef); functions/node_modules/@google-cloud/firestore/build/src/transaction.js:96-98 lanza 'Firestore transactions require all reads to be executed before all writes.'; lib/providers/location_provider.dart:187-203 traga el error; functions/src/getNearby.ts:43-46
- **Detalle:** Toda llamada lanza dentro de runTransaction, así que la callable devuelve INTERNAL y locations/{uid} nunca se escribe. Entonces getNearby responde 'Location is not set.' a todos y Cerca en producción muestra siempre 'No pudimos cargar…'. El cliente silencia el error. Los tests puros no cubren el handler y los de emulador no se corrieron.
- **Recomendación:** Hacer todas las lecturas antes de escribir (tx.getAll(locRef, userRef) al inicio). Agregar un test de integración en el emulador (Functions+Firestore) que llame updateLocation dos veces y verifique geohash y luego resource-exhausted, y correrlo en CI.

### CV-02 · P0 · false_claim · sin verificar
**La fecha de nacimiento nunca llega al servidor: getNearby oculta a todos y el 18+ queda solo en el cliente**

- **Evidencia:** lib/screens/onboarding/onboarding_screen.dart:53-70 (solo guarda keyBirthDate en prefs locales; grep sin escrituras de birthDate en lib/services); functions/src/getNearby.ts:118; functions/src/pure/nearbyFilter.ts:40; docs/BASELINE.md:55 'S6 Confirmado'
- **Detalle:** Ningún usuario real tiene users/{uid}.birthDate, así que filterNearbyPeople descarta al 100% y Cerca queda vacía aunque se arregle CV-01. El gate de edad se evade borrando las prefs o reinstalando, y el consentimiento de términos y analytics no queda registrado ni versionado (S12).
- **Recomendación:** Crear una callable completeOnboarding({birthDate, consents{terms{version}, analytics{version,granted}}}) que valide 18+ en el servidor y escriba users.birthDate y consents con serverTimestamp; no permitir updateLocation/getNearby sin onboarding completo. Tests de emulador: usuario sin birthDate excluido, adulto incluido, menor rechazado.

### CV-03 · P0 · false_claim · sin verificar
**S7 Saludo a medias: nadie puede recibir ni aceptar un saludo y en producción no se puede crear ningún chat nuevo**

- **Evidencia:** lib/services/safety_service_live.dart:20-33 define respondWave sin llamadores (grep 'respondWave|incomingPending' solo encuentra la definición); no existe listener de waves to==uid ni la fila 'Saludos nuevos'; firestore.rules:155 chats create:false; lib/services/chat_service_live.dart:22-39; README.md:16 'Saludo… ✅'; docs/BASELINE.md:57; functions/src/waves.ts:130-136 crea el chat sin lastMessageAt mientras chat_service_live.dart:46 ordena por ese campo
- **Detalle:** El loop de §7.2 está roto: A saluda y la wave queda pending, pero B nunca se entera (sin UI, sin push, sin trigger). respondWave nunca corre, el chat nunca existe y los mensajes son imposibles. Con WAVES_ENABLED=false, getOrCreateChat también es denegado por reglas. Además, el chat aceptado no aparecería en la lista porque le falta lastMessageAt. En el demo la aceptación tampoco existe (MemoryWaves).
- **Recomendación:** Crear WavesRepository (Demo/Firebase) con stream de saludos entrantes, una fila 'Saludos nuevos (n)' con Aceptar/Ignorar que llame a respondWave y navegue a /chat/:id, y un trigger onWaveCreated con push sin contenido. Setear lastMessageAt al crear el chat. Test E2E en emulador: A saluda → B acepta → ambos ven el chat y se envían un mensaje.

### CV-04 · P0 · false_claim · sin verificar
**Las reglas de profiles rechazan todas las escrituras del cliente (editar perfil, visibilidad, login con foto)**

- **Evidencia:** lib/services/user_service_live.dart:83-91 agrega 'updatedAt' y :44 'age'; firestore.rules:69-71 (profileClientKeys sin updatedAt ni age) y :136-138 (affectedKeys().hasOnly); lib/services/user_service.dart:142-143 setVisibility→updateProfile; lib/services/auth_service_live.dart:325-333 llama updateProfile en el login; web/privacidad.html:71 promete 'Puedes dejar de aparecer en Cerca desde tu perfil'; firestore-tests/rules.test.ts no prueba el update de profiles
- **Detalle:** Todo updateProfile devuelve PERMISSION_DENIED: no se puede editar nombre, bio ni intereses, ni apagar 'Visible en Cerca', que es un control de privacidad prometido en la política. El login con Google de un perfil sin foto falla porque _upsertProfile lanza. createUser con age≠null también es rechazado.
- **Recomendación:** Definir un contrato de payload con fixtures JSON compartidos entre Dart y TS, y alinear: quitar updatedAt/age o permitirlos con validación (updatedAt == request.time). Tests de reglas con el payload exacto del cliente (create/update de profiles y users, markChatAsRead) y un test del toggle de visibilidad contra el emulador.

### CV-05 · P0 · false_claim · sin verificar
**B4 sigue sin resolver: 'activa ahora' para siempre, y los usuarios activos desaparecen de Cerca o nunca aparecen**

- **Evidencia:** functions/src/touchActivity.ts:10-17 escribe profiles.activityBucket='ahora' fijo; solo se invoca en el login con perfil existente (lib/services/auth_service_live.dart:325) y en el logout (lib/services/auth_service.dart:232); no hay observer de ciclo de vida (grep AppLifecycle vacío); lib/screens/chat/chat_screen.dart:253-254 y lib/widgets/public_profile_sheet.dart:31-32 muestran ese bucket; functions/src/pure/nearbyFilter.ts:42-44; docs/BASELINE.md:65
- **Detalle:** El chat y la ficha muestran 'activa ahora' indefinidamente, incluso después de cerrar sesión, que vuelve a escribir 'ahora'. Como las sesiones de Firebase persisten, lastActiveAt no se renueva y a los 7 días un usuario activo sale de Cerca. Los usuarios nuevos (vía createUser) nunca reciben lastActiveAt, así que nunca aparecen.
- **Recomendación:** Llamar touchActivity al volver a primer plano (throttle ≥5 min) y al crear la cuenta, y quitarla del logout. No persistir un bucket estático: derivarlo de lastActiveAt al leer. Tests de decaimiento del bucket y de un usuario nuevo visible en Cerca (emulador).

### CV-06 · P0 · gap · sin verificar
**Functions no se puede desplegar y la BASELINE omitió el build**

- **Evidencia:** functions/src/pure.test.ts:23 'const require = createRequire(...)' → TS2441 en 'npm run build' (verificado por el orquestador); functions/tsconfig.json incluye src/**/*.ts (compila los tests a lib/); firebase.json:9-21 sin predeploy; functions/.gitignore ignora lib/; functions/package.json:5-7 engines node '20' (EOL 2026-04-30); .github/workflows/ci.yml sin job de functions; docs/BASELINE.md:36-44 solo reporta npm test; DEPLOY.md:38
- **Detalle:** En un clon limpio no existe lib/index.js y el build falla, así que el 'firebase deploy --only …functions' de DEPLOY.md no puede funcionar. El runtime Node 20 está fuera de soporte. El §12 pedía pegar la salida real de lint, test y emulador; no se corrió ni el build ni el emulador.
- **Recomendación:** Usar un tsconfig.build.json sin tests (o renombrar la variable), agregar predeploy 'npm --prefix functions run build' y engines node 22. Agregar jobs de CI 'functions' (npm ci, lint, build, test) y 'rules' (firebase emulators:exec … firestore-tests). El DoD exige pegar la salida del build.

### CV-07 · P0 · false_claim · sin verificar
**App Check se exige en el servidor pero no existe en el cliente; el ADR 0003 dice que basta registrar las apps**

- **Evidencia:** functions/src/https.ts:5-8 enforceAppCheck:true; pubspec.yaml:21-27 sin firebase_app_check (grep vacío en lib/); docs/adr/0003-app-check-fail-closed.md ('…hasta registrar las apps en App Check')
- **Detalle:** Sin el SDK cliente no se adjunta token, así que getNearby, updateLocation, sendWave, blockUser, deleteAccount, exportMyData y touchActivity fallan aunque se configure la consola. Esto incluye borrar la cuenta y bloquear, que exigen las tiendas.
- **Recomendación:** Agregar firebase_app_check (Play Integrity, App Attest/DeviceCheck y reCAPTCHA Enterprise en web) activado en firebase_boot antes de la primera callable, con debug provider para emulador y CI. Corregir el ADR 0003. Test de integración de una callable con debug token.

### CV-08 · P1 · process · sin verificar
**§13 y §9 incumplidos: un commit monolítico, Fase 1 en adelante sin aprobación y sin revisión de A12 ni A7/A8**

- **Evidencia:** git log 02abbd4..155b6f6 = 1 commit; git diff --shortstat sin lockfiles ni fuentes: 124 archivos, +4.824/−640 (el tope del §9 es ≤~400 líneas por PR); docs/PLAN.md:3 'La orden de esta sesión fue ejecutar sin detenerse' (sin cita ni fecha de aprobación humana; el §15 ordenaba no empezar la Fase 1); no hay screenshots antes/después, goldens, reportes del §14 ni comentarios de red team
- **Detalle:** No se puede revisar, revertir ni bisecar por ítem. Los P0 CV-01..07 pasaron porque nadie ejecutó el flujo real; A12 debía intentar scrapear, escribir tras un bloqueo y saltarse el paywall. El conventional commit está bien, pero es uno solo y describe mal el contenido ('Keep exact coordinates', cuando guarda una celda difuminada).
- **Recomendación:** En v2: una serie de PRs (uno por hallazgo) con plantilla de evidencia, riesgos y checklist de red team, más CI verde. Gate humano explícito registrado en docs/PLAN.md (cita + fecha) antes de salir de la Fase 0. Si el entorno no puede pedir aprobación, detenerse y entregar el plan.

### CV-09 · P1 · false_claim · sin verificar
**Fase 2 'Design system: Hecho' es falso: 0 de 21 componentes y el ThemeExtension no se consume**

- **Evidencia:** lib/core/design_system/ solo tiene tokens/* y components/pf_mark.dart; grep 'context.pf' fuera del DS = 0; grep 'AppColors\.|isDark \?' en lib/screens + lib/widgets = 295; AppShadows 14 referencias, boxShadow 17 (p.ej. lib/widgets/chat_bubble.dart:76-84); docs/PLAN.md:11
- **Detalle:** El §5.3 prohíbe que los widgets lean AppColors o usen isDark ?, y el §5.4 pide 21 componentes Pf* con estados, Semantics, test y golden. No existen, como tampoco la galería /_dev/gallery, el isotipo SVG (PfMark es un CustomPaint, ADR 0006) ni la splash nativa única (D7).
- **Recomendación:** Gate de CI: 0 ocurrencias de 'AppColors\.|isDark \?|AppShadows|TextStyle\(' fuera de lib/core/design_system. Implementar los 21 componentes con test y golden (light/dark × 1.0/1.3) y la galería dev, y reportar el avance en STATUS.md.

### CV-10 · P1 · false_claim · sin verificar
**D5: el gate de literales se cumplió borrando fontSize, no tokenizando**

- **Evidencia:** git diff 02abbd4 HEAD -- lib/screens lib/widgets: ~29 líneas '-fontSize: …' borradas sin reemplazo (p.ej. lib/screens/nearby/nearby_screen.dart en _Header y _ToggleSegment, que quedan con TextStyle sin tamaño); tool/gates.sh:7 solo busca 'fontSize:'
- **Detalle:** Los textos caen al tamaño por defecto y cambia la jerarquía (títulos de 26/22 → default) sin screenshots ni goldens. El gate pasa (exit 0) pero no cumple la intención del §5.1.10.
- **Recomendación:** Usar estilos PfType (titleLg, label, caption…), con un gate que prohíba TextStyle( fuera del DS, y goldens antes/después de Cerca, chat y login.

### CV-11 · P1 · gap · sin verificar
**Onboarding: 'Siguiente' en el paso 2 intenta terminar y se queda bloqueado; falta el paso de privacidad y los links legales**

- **Evidencia:** lib/screens/onboarding/onboarding_screen.dart:30 (_stepCount=3), :32-50 (_pages tiene 2 elementos) y :81-83 (if (_page < _pages.length - 1) … else _finish()); lib/screens/onboarding/age_consent_form.dart:77-79 (título plano, sin url_launcher)
- **Detalle:** En la página 1 el CTA primario llama a _finish() con birthDate null: muestra el toast 'Picaflor es para mayores de 18.' y no avanza; solo se llega a la edad deslizando o con 'Saltar'. Falta el paso 'Tu zona, nunca tu punto exacto' y los Términos y la Política no abren. El copy 'Abre un chat' contradice S7.
- **Recomendación:** Cambiar la condición a _stepCount - 1. Widget test que recorra los 3 pasos solo con el CTA. Links tappables a TERMS_URL y PRIVACY_POLICY_URL, y copy alineado al saludo.

### CV-12 · P1 · gap · sin verificar
**S12/S5 parciales: sin registro de consentimiento, export no portable, y el borrado deja datos personales**

- **Evidencia:** onboarding_screen.dart:63-69 (consentimiento solo en prefs); lib/screens/settings/settings_screen.dart:410-433 (export = data.toString() en un AlertDialog) y :476-479 (borrado sin try/catch); functions/src/deleteAccount.ts:40-54 (no toca chats.lastMessage/lastMessageSenderId, waves to==uid, reports ni bloqueos de terceros); functions/src/onMessageCreated.ts:41-45 copia el texto a chats.lastMessage; web/privacidad.html:77-87 no declara la transferencia a Brasil; docs/adr/0005 afirma sin evidencia que southamerica-west1 no sirve (supuesto a verificar)
- **Detalle:** La Ley 21.719 (vigencia plena el 2026-12-01, en 55 días) exige consentimiento demostrable, portabilidad estructurada y supresión efectiva. Después de borrar la cuenta, el último mensaje del usuario sigue legible en chats/{id}.lastMessage. No hay retención ejecutable (ni TTL ni job). Si la callable falla, el usuario no recibe feedback.
- **Recomendación:** Consentimientos versionados en users mediante una callable. Export como archivo JSON descargable o compartible. deleteAccount que anonimice chat.lastMessage y borre waves to==uid. TTL o purga programada documentada. Verificar región Santiago con enlace oficial en el ADR o declarar la transferencia. Test de emulador 'sin PII residual tras deleteAccount'.

### CV-13 · P1 · false_claim · sin verificar
**S4: bloqueo y reporte incompletos, y la BASELINE afirma un bloqueo en Cerca que no existe**

- **Evidencia:** lib/features/safety/safety_controller.dart:8-23 (bloqueos solo en memoria) y :29 (alsoBlock=true por defecto); lib/models/chat_model.dart sin campo status; grep 'bloquead' sin 'Usuarios bloqueados' en Ajustes; lib/widgets/public_profile_sheet.dart:140-162 (sin texto libre ni opción 'Además, bloquear'); docs/BASELINE.md:54 dice 'bloqueo en la lista de Cerca' pero lib/screens/nearby/nearby_screen.dart no tiene esa acción (está en chat_list_screen.dart:297-316)
- **Detalle:** Tras reiniciar la app, la ficha de alguien bloqueado vuelve a ofrecer 'Saludar'. El chat bloqueado deja escribir y falla con un error genérico. No se puede desbloquear. Los errores de la callable no se manejan. Tampoco hay cola de moderación (esto sí está admitido).
- **Recomendación:** BlocksRepository con stream, lista y desbloqueo en Ajustes (callable unblockUser). ChatModel.status y UI de chat bloqueado. PfReportSheet con motivo, texto y checkbox desmarcable 'Además, bloquear'. Trigger onReportCreated → cola o alerta. Widget tests.

### CV-14 · P1 · gap · sin verificar
**B5 y escalabilidad: getNearby caro y con pérdida en zonas densas, más N+1 secuencial en el cliente**

- **Evidencia:** functions/src/getNearby.ts:13 y :54-61 (9 prefijos × limit 150, sin orden por recencia), :80-87 (getAll de profiles + users + blocks por candidato y hasta 1.000 waves); lib/services/user_service_live.dart:127-158 (await getUser secuencial, hasta 50); functions/src/index.ts:4 maxInstances 20; sin rate limit en getNearby
- **Detalle:** Peor caso ≈6.400 lecturas por refresh, más hasta 50 lecturas secuenciales del cliente (cada una evalúa 2 exists() en reglas) contra un timeout de 8 s. En zonas densas, con más de 150 personas por celda p5, se descartan personas de forma arbitraria (orden lexicográfico). El costo crece lineal con DAU × refresh.
- **Recomendación:** Índice denormalizado nearbyIndex/{uid} (geohash, isVisible, adulto, lastActiveAt y tarjeta pública) mantenido por triggers. Consulta por celdas ordenada por recencia, con presupuesto ≤500 lecturas por llamada y la tarjeta incluida en la respuesta (sin N+1). Rate limit por uid. Benchmark en emulador con 50k usuarios sintéticos en Santiago reportando lecturas por llamada y p95.

### CV-15 · P1 · gap · sin verificar
**Ubicación falsificable y Cerca sin límite: se puede mapear la base a ~150 m (S1 residual)**

- **Evidencia:** functions/src/pure/grid.ts:13-27 acepta cualquier lat/lon del planeta; functions/src/updateLocation.ts:31 solo limita a 1 actualización cada 20 s; getNearby.ts sin rate limit; functions/src/pure/distance.ts:23 (very_close <150 m); docs/security/threat-model.md no lo trata
- **Detalle:** Con una sesión y una app modificada (o App Check burlado), un script recorre la grilla cada 20 s y llama getNearby sin límite. Con los cambios de bucket triangula la celda de ~150 m de cada usuario visible de la ciudad.
- **Recomendación:** Validar plausibilidad (bounding box del Gran Santiago y velocidad máxima entre actualizaciones), poner rate limit a getNearby (p.ej. 10/min y 200/día), subir el bucket mínimo a ≥300 m y alertar ante patrones de barrido. Documentarlo como caso de A12.

### CV-16 · P1 · gap · sin verificar
**El guard anti-demo (S8) está inerte y la lógica demo_ sigue en producción (B7)**

- **Evidencia:** lib/core/privacy/nearby_policy.dart:55-67 solo dispara con flavor=='prod'; lib/core/config/app_config.dart:14-17 y :47-50 (DEMO_MODE true y FLAVOR 'dev' por defecto); grep FLAVOR en DEPLOY.md, README y CI = 0; lib/services/chat_service.dart:43-47, :154-158, :177-179; lib/services/user_service_live.dart:130
- **Detalle:** Un build de tienda que olvide DEMO_MODE=false y no pase FLAVOR=prod (no documentado) arranca con perfiles inventados y el guard no actúa. Sin repositorios no se puede verificar que ningún provider resuelva a Demo*.
- **Recomendación:** Flavors reales (env/{dev,staging,prod}.json con --dart-define-from-file) documentados. Guard con AppConfig.isRelease && !kIsWeb && demoMode → fallo. Test que construya el ProviderContainer de prod y verifique que ningún override es Demo*. Eliminar las ramas demo_ de los servicios live.

### CV-17 · P1 · false_claim · sin verificar
**Fase 7 'Hecho' exagerada: la lista de espera es ficticia y no hay analítica instrumentada**

- **Evidencia:** lib/screens/plus/plus_screen.dart:45-55 (snackbar 'Quedaste en la lista de espera' sin persistir nada) y :41 ('precios propuestos, no finales' en la UI); lib/core/analytics/app_analytics.dart (solo MemoryAnalytics; grep '.track(' en lib = 0); lib/core/config/app_config.dart:58-62 (plusEnabled en compile-time, no Remote Config); docs/PLAN.md:15
- **Detalle:** El usuario recibe una confirmación falsa, con riesgo frente a la Ley 19.496. No se captura intención de compra ni la métrica de liquidez (≥60% de sesiones con ≥5 personas a ≤3 km), así que no hay forma de decidir cuándo ni en qué comuna encender Plus. Ninguno de los 18 eventos del §7.6 existe.
- **Recomendación:** waitlist/{uid} (trigger, comuna aproximada, ts) vía callable. Analytics con consentimiento y los 18 eventos, con un test por cada emisión. Remote Config plus_enabled por cohorte o comuna. MonetizationRepository Demo/RevenueCat. Export a BigQuery con un tablero de liquidez por comuna.

### CV-18 · P1 · gap · sin verificar
**Webhook de RevenueCat frágil: el orden de eventos y los consumibles pueden quitar Plus**

- **Evidencia:** functions/src/pure/revenuecat.ts:10-27 (todo evento sin 'plus' da plan 'free'; heurística product.includes('plus')); functions/src/revenuecatWebhook.ts:42-57 (merge sin comparar event_timestamp_ms)
- **Detalle:** Supuesto plausible: una compra de boost_30m (NON_RENEWING_PURCHASE, sin entitlement plus) sobrescribe entitlements/{uid} a free con la suscripción activa. Los eventos fuera de orden pueden revertir una renovación. La idempotencia por id sí está bien.
- **Recomendación:** Reconciliar contra la API REST de RevenueCat (GET subscriber) en cada evento. Consumibles en boosts/{uid}. Ignorar eventos con un timestamp anterior al último aplicado. Fixtures de test para INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, NON_RENEWING_PURCHASE y TRANSFER.

### CV-19 · P1 · gap · sin verificar
**QA muy por debajo del §11: sin tests de regresión de la Fase 1, reglas sin ejecutar y CI incompleto**

- **Evidencia:** 23 tests de Flutter (8 nuevos en test/v2_policy_test.dart:14-126; ninguno para B1, B2, B3, B7, S9 ni S10); firestore-tests/rules.test.ts con 11 casos nunca corridos (docs/BASELINE.md:44) y sin update de profiles/users ni markChatAsRead; .github/workflows/ci.yml sin dart format, functions, emulador ni umbral de cobertura, y Android con if:false; no hay goldens ni integration_test
- **Detalle:** La Fase 1 exigía un test de regresión por PR. Un solo test de emulador con los payloads reales habría detectado CV-01, CV-02 y CV-04.
- **Recomendación:** Por cada ítem, un test que falle en 02abbd4 y pase después. Jobs de CI de reglas y functions. Umbral de cobertura ≥80% en la lógica pura, que haga fallar el CI. Widget tests por estado e integration_test (Patrol) del loop completo.

### CV-20 · P1 · gap · sin verificar
**D1: regresión de contraste en dark en código nuevo**

- **Evidencia:** lib/widgets/public_profile_sheet.dart:93-97 usa AppColors.lightTextSecondary (#4A5363) también en dark: 2,32:1 sobre #12171E (fórmula WCAG calculada); test/v2_policy_test.dart:98 solo prueba pares de tokens
- **Detalle:** El mensaje de confianza 'Tu ubicación exacta nunca se comparte.' queda ilegible en dark. Los tests de tokens no detectan cómo se usan en los widgets.
- **Recomendación:** Usar context.pf.colors.textSecondary. Widget tests con meetsGuideline(textContrastGuideline) en light y dark para cada pantalla y sheet.

### CV-21 · P1 · process · sin verificar
**La BASELINE no es una línea base y mezcla 'confirmado' con 'arreglado'; los documentos se contradicen**

- **Evidencia:** docs/BASELINE.md:11 ('después de los arreglos'), :26 (gates no corridos: 'no hay bash'), :46-82 (columna 'Confirmado' para ítems ya corregidos), :73 (D4 dice fuentes pendientes pero assets/fonts/Inter-*.ttf están commiteadas), :7 (expone la ruta local C:\Users\nicolas.andrade); docs/PLAN.md:9 ('salvo el build web') contra BASELINE.md:28-32; PLAN.md:19 ('Cerrar npm test') contra BASELINE.md:36-42 (10/10)
- **Detalle:** La Fase 0 pedía correr el §12 sobre el estado base y tomar screenshots 'antes' (light/dark, 3 tamaños). No hay un estado previo medible (bundle web, cobertura, violaciones del gate) y las contradicciones restan credibilidad al resto.
- **Recomendación:** Regenerar la BASELINE sobre un checkout limpio de 02abbd4, con las salidas completas (tamaño de main.dart.js, % de cobertura, conteo del gate) y la matriz de screenshots. STATUS.md con columnas 'verificación previa', 'estado' y 'evidencia (test/comando)'. Sin rutas personales.

### CV-22 · P1 · gap · sin verificar
**Fases 3, 4 y 8 sin ejecutar; A1, A3, A4, A6, D3 y D9 pendientes; las notificaciones push no funcionan**

- **Evidencia:** if (_isDemo) en lib/services/user_service.dart:29-154 y chat_service.dart:35-193; re-exports de 4 líneas en lib/features/**/screens; time_ago.dart y date_utils.dart duplicados; StateNotifier en 6 archivos; sin lib/l10n/*.arb; pubspec.yaml sin firebase_messaging, crashlytics, remote_config, flutter_native_splash ni image_picker; login_screen.dart:492 'G' en texto; functions/src/onMessageCreated.ts:52-71 envía a fcmTokens que ningún cliente registra; docs/BASELINE.md:76-81 (admitido)
- **Detalle:** La arquitectura del §8.1 (repositorios, flavors, Notifier) es prerrequisito para escalar el equipo y para los guards. Sin push no hay notificaciones de mensajes ni de saludos, lo que daña la retención D1/D7 y la liquidez.
- **Recomendación:** Fase 3 por feature (nearby, waves, chat, safety, profile, plus) con interfaces y overrides. ARB con gate de strings. Push con permiso contextual y registro de token en users.fcmTokens. Foto de perfil con Storage y moderación. Botón oficial de Google.

### CV-23 · P2 · gap
**Reglas sin lista blanca de campos en messages, reports y blocks**

- **Evidencia:** firestore.rules:161-170 (el create de messages no valida keys ni createdAt == request.time), :180-185 (reports sin hasOnly), :174-178 (blocks escribible directo, sin pasar por blockUser)
- **Detalle:** Un cliente puede inyectar campos arbitrarios, por ejemplo un createdAt futuro para quedar fijo al final del hilo, y crear bloqueos que no cierran el chat.
- **Recomendación:** keys().hasOnly(['senderId','text','createdAt']) && createdAt == request.time. Reports con hasOnly y otherUid validado. Blocks solo vía callable, o un trigger que actualice el chat. Tests de denegación.

### CV-24 · P2 · gap
**La moderación y los triggers tienen efectos colaterales**

- **Evidencia:** functions/src/pure/moderate.ts:1-24 marca 'whatsapp', 'http://' y 'www.'; functions/src/onMessageCreated.ts:24-28 reemplaza el texto después de entregarlo; :47-50 el increment no es idempotente; no respeta muted
- **Detalle:** Mensajes legítimos se reemplazan en silencio después de haber sido leídos en tiempo real. Los reintentos duplican los no leídos y se notifica a chats silenciados.
- **Recomendación:** Moderar antes de publicar (callable sendMessage o flag con revisión) y avisar al emisor. Dedupe por event.id. Respetar muted.{uid}.

### CV-25 · P2 · gap
**sendWave sin transacción ni validación del destinatario**

- **Evidencia:** functions/src/waves.ts:49-81 (cuenta y escribe fuera de una transacción; no verifica que toUid exista, sea adulto, esté visible o dentro del rango)
- **Detalle:** Ráfagas concurrentes superan el cupo de 20 por día, que es la palanca de Plus. Además se puede saludar a cualquier uid conocido aunque esté oculto.
- **Recomendación:** Contador waveCounters/{uid}_{fecha} dentro de una transacción. Validar el destino según perfil, edad, bloqueos y radio del plan. Test de concurrencia en el emulador.

### CV-26 · P2 · gap
**Atribución del mapa duplicada y superpuesta**

- **Evidencia:** lib/widgets/nearby_map.dart:217-237 y :239-260 (dos chips en la misma esquina; el de light dice solo '© OpenStreetMap')
- **Detalle:** Hay dos chips superpuestos y uno de ellos omite a CARTO.
- **Recomendación:** Un solo componente de atribución, configurable según el proveedor de tiles, con golden.

**Requisitos que esta lente exige para la v2**

- Fase 0.5 'Estabilizar rama de Grok' antes de cualquier feature nueva: cerrar CV-01 a CV-07 y que cada uno tenga un test que falle sobre 155b6f6 y pase después del fix.
- Prohibir commits monolíticos: un PR por hallazgo, ≤400 líneas sin contar lockfiles, generados ni goldens, con conventional commits y plantilla de PR (evidencia: comando + salida, screenshots antes/después, riesgos, checklist de A12). El CI rechaza PRs que superen el tope sin la etiqueta 'size-exception' y un ADR.
- Regla de 'claim = evidencia': docs/STATUS.md lista S1-S12, B1-B8, D1-D9 y A1-A7 con estado y enlace a un test o a la salida de un comando. Un script de CI verifica que cada test referenciado exista y corra. Lo que no tenga evidencia no puede marcarse 'hecho'.
- CI obligatorio con: dart format --set-exit-if-changed, flutter analyze --fatal-infos, flutter test --coverage con umbral (≥80% en lógica pura y application), tool/gates.sh, build web demo, job functions (npm ci, lint, build, test), job de reglas (firebase emulators:exec con firestore-tests) y E2E de callables en el emulador de Functions.
- E2E en emulador del loop completo, con los payloads exactos del cliente: completeOnboarding → updateLocation → getNearby → sendWave → listener de entrantes → respondWave → chat visible en la lista → mensaje → block → envío rechazado → exportMyData (JSON) → deleteAccount sin PII residual (incluido chats.lastMessage).
- Contrato de payloads compartido (fixtures JSON) entre Dart y TS para users, profiles, chats y messages, usado a la vez en los tests de reglas y en los tests de los servicios Dart.
- Edad y consentimiento del lado del servidor: users.birthDate y consents{terms, privacy, analytics: {version, granted, ts}} escritos por una callable que valide 18+. Sin onboarding completo, getNearby y updateLocation se rechazan.
- Saludos completos: stream de entrantes, fila 'Saludos nuevos (n)' con Aceptar/Ignorar, push en onWaveCreated, lastMessageAt al crear el chat, cupo diario transaccional y validación del destinatario. Simulación de aceptación en el modo demo.
- Presencia real: touchActivity al volver a primer plano con throttle de 5 min y al crear la cuenta, sin escritura en el logout. El bucket se calcula al leer y nunca se guarda 'ahora' fijo.
- App Check en el cliente (Play Integrity, App Attest/DeviceCheck y reCAPTCHA Enterprise) con debug provider para emulador y CI. ADR 0003 corregido.
- Escalabilidad medible: colección nearbyIndex denormalizada, presupuesto ≤500 lecturas por llamada de getNearby, cero N+1 en el cliente, rate limit por uid en getNearby, validación de plausibilidad en updateLocation (bounding box de Santiago y velocidad máxima). Reporte de benchmark con 50k usuarios sintéticos (lecturas por llamada p50/p95, latencia p95 <800 ms) incluido en el PR.
- Functions en Node 22 LTS, tsconfig.build sin tests, predeploy build en firebase.json, y un deploy dry-run (firebase deploy --only functions --dry-run o build + discovery) en CI.
- Monetización medible: waitlist/{uid} persistida, los 18 eventos del §7.6 instrumentados con consentimiento y con un test de emisión por evento, Remote Config plus_enabled por comuna o cohorte, MonetizationRepository Demo/RevenueCat, y un webhook que reconcilie contra la API REST con consumibles separados y control de orden de eventos.
- Adopción real del design system: gate de CI con 0 ocurrencias de 'AppColors\.|isDark \?|AppShadows|TextStyle\(' fuera de lib/core/design_system; los 21 componentes Pf* con widget test y golden (light/dark × 1.0/1.3); galería dev; prohibido 'arreglar' el gate borrando propiedades.
- Accesibilidad: cada pantalla o sheet con un widget test que pase textContrastGuideline, androidTapTargetGuideline y labeledTapTargetGuideline en light y dark, más una prueba de texto al 200% en 320 px.
- Guard anti-demo eficaz: flavors con --dart-define-from-file documentados en DEPLOY.md, fallo de arranque si isRelease && !kIsWeb && demoMode, un test que construya el contenedor de prod y verifique que no hay implementaciones Demo*, y nada de ramas demo_ en los servicios live.
- Cumplimiento Ley 21.719: export JSON descargable, retención ejecutable (TTL o job), región verificada con enlace oficial (o transferencia declarada en la política) y gestión de bloqueos/desbloqueo en Ajustes. Textos legales marcados 'requiere validación legal' con checklist para el humano.
- BASELINE real: generada sobre un checkout limpio del commit base antes de cualquier cambio, con la salida completa de §12, tamaño del bundle web, % de cobertura, conteo de violaciones y matriz de screenshots. Sin rutas ni datos personales.
- Gate humano: el agente se detiene al terminar la Fase 0 y no continúa sin una aprobación explícita registrada (cita + fecha) en docs/PLAN.md. Una instrucción de 'no detenerse' no reemplaza esa aprobación por escrito.
- Reporte del §14 por fase con métricas (cobertura antes/después, goldens n, violaciones n→0, bundle Δ) y una sección 'Intentos de A12' con los resultados de scraping, escritura tras bloqueo, salto del paywall y UI al 200%.

**Cifras clave**

| Métrica | Valor | Base |
|---------|-------|------|
| Commits en la rama de Grok | 1 (155b6f6) | git log 02abbd4..HEAD |
| Diff total | 132 archivos, +10.080/−1.231 | git diff --stat 02abbd4 HEAD |
| Diff sin lockfiles ni fuentes | 124 archivos, +4.824/−640 (≈12 veces el tope de 400 líneas por PR) | git diff --shortstat excluyendo *package-lock.json, pubspec.lock y assets/fonts |
| Ítems §4 (36) | 13 hechos · 16 parciales · 5 no hechos · 2 falsos (S7, B4) | Contraste de BASELINE.md con el código en esta auditoría |
| P0 nuevos que bloquean el lanzamiento | 7 (CV-01 a CV-07) | Verificados en el código; CV-06 en parte por el orquestador (TS2441) |
| Tests de Flutter | 23 en total, 8 nuevos; 0 widget tests de pantallas y 0 goldens | grep test( en test/*.dart |
| Tests de reglas de Firestore | 11 escritos, 0 ejecutados | firestore-tests/rules.test.ts; docs/BASELINE.md:44 |
| Tests de Functions | 10 de funciones puras, 0 de handlers o emulador | functions/src/pure.test.ts; npm test verificado por el orquestador |
| Componentes Pf* del §5.4 | 0/21 (solo existe PfMark, que no estaba en la lista) | find lib/core/design_system |
| Usos de AppColors./isDark ? en screens+widgets | 295 (context.pf: 0) | grep -rn en lib/screens y lib/widgets |
| Semantics/semanticLabel en lib | 0 → 1 | git grep en 02abbd4 contra grep en HEAD |
| Lecturas Firestore por getNearby (peor caso) | ≈6.400 (9×150 locations + 3×1.350 getAll + ≤1.000 waves + blocks) | functions/src/getNearby.ts:13,54-87 (cálculo derivado del código) |
| Lecturas N+1 del cliente por refresh de Cerca | hasta 50 secuenciales (+2 exists() de reglas cada una) | lib/services/user_service_live.dart:127-158 |
| Contraste en dark del texto de privacidad de la ficha | 2,32:1 (AA exige 4,5:1) | #4A5363 sobre #12171E, fórmula WCAG 2.x |
| Cambios en pubspec.lock | −76 paquetes transitivos, +14, 0 cambios de versión | comparación de nombres y versiones entre los lockfiles de 02abbd4 y HEAD |
| Runtime de Functions | Node 20 (EOL 2026-04-30) | functions/package.json:5-7; fecha de EOL verificada por el orquestador |
| Días hasta la vigencia plena de la Ley 21.719 | 55 (2026-12-01) | megaprompt v1 §4.1 S12; hoy es 2026-10-07 |

## SC · Escalabilidad y costo

**Veredicto de la lente**

Veredicto (lente escalabilidad): Grok sacó las coordenadas del cliente y las movió a callables, que es la dirección correcta para la privacidad. Pero el diseño no escala ni en costo ni en funcionamiento. getNearby lee ~5.465 documentos por llamada en el servidor y ~150 más en el cliente (N+1 de perfiles, con 2 exists() de reglas por perfil). El tope de lecturas se alcanza con ~1,8k–5,3k usuarios con ubicación en Santiago. Eso cuesta ~US$0,0025 por llamada y ~US$0,15 por MAU al mes (supuestos de uso), lo mismo o más que el ingreso neto esperado de Plus (US$0,075–0,15 por MAU). Además, getNearby trunca en silencio (limit 150 por prefijo en orden geohash, filtrando después) y no cubre los radios: en un sondeo con el código de Grok, el 44% de las posiciones pierde gente a ≤5 km y los 10 km de Plus nunca se cumplen. Sin rate limit, getNearby es un vector de denial-of-wallet (~US$10k/día con 50 req/s). En producción hoy no funcionaría nada: App Check exigido sin SDK en el cliente, Node 20 se decomisiona el 2026-10-30 (en 23 días), el build está roto y el CI no compila Functions. Falta además el andamiaje de escala: TTL, Remote Config, configuración por ciudad, proyectos dev/stg/prod, presupuestos y alertas, BigQuery, colas de push y moderación, jobs async, minInstances y tuning por función. Con ubicación desnormalizada, geohashQueryBounds por radio, caché por celda y un doc `relations`, Cerca baja a ≤25 lecturas por llamada (~200–800× menos) y la etapa A aguanta hasta 10k–100k MAU. Sobre 100k MAU hace falta un servicio geo dedicado (Redis GEO/Typesense) y bases de datos por macro-región.

**Lo que está bien y se preserva**

- Las coordenadas salen de los documentos legibles por clientes: `locations/{uid}` queda cerrado en las reglas (firestore.rules:143-145) y solo lo escribe el callable updateLocation.
- Se difumina a la grilla de ~150 m y a geohash p7 antes de guardar (functions/src/pure/geohash.ts:134-137), y la respuesta de Cerca trae solo buckets de distancia y actividad (nearbyFilter.ts:53-57).
- La lógica pura está separada en functions/src/pure/* y tiene tests unitarios (geohash, cuota, filtro, buckets). Así es barato reescribir getNearby sin tocar el contrato.
- Hay un tope global de instancias (`maxInstances: 20`, functions/src/index.ts:4). Es un freno de costo burdo pero útil; v2 debe conservarlo por función en vez de quitarlo.
- El chatId es determinístico (par ordenado, pure/chat.ts:1-3) y se crea dentro de una transacción en respondWave: idempotente, sin chats duplicados.
- El webhook de RevenueCat es idempotente con `webhookEvents/{eventId}` dentro de una transacción (revenuecatWebhook.ts:42-57).
- No hay contadores globales ni documentos calientes: unreadCount es un mapa por participante en un chat 1:1, y las reglas solo dejan tocar la clave propia (firestore.rules:87-117).
- markAsRead con debounce de 350 ms (BASELINE B3) y slider de radio que solo dispara en onChangeEnd (nearby_screen.dart:141-145): eso evita tormentas de escrituras y llamadas.
- El push no lleva el contenido del mensaje (pure/push.ts) y el fan-out es mínimo (1 destinatario).
- La región está centralizada en una sola constante en servidor y cliente (https.ts:3, app_config.dart:344): cambiarla es un cambio de una línea antes de crear la base.
- La paginación hacia atrás de mensajes existe (chat_service_live.dart:127-141).

**Hallazgos**

### SC-01 · P0 · scalability
**getNearby lee ~5.600 documentos por llamada: Cerca cuesta lo mismo que el ingreso de Plus**

- **Evidencia:** functions/src/getNearby.ts:13 (PER_PREFIX_LIMIT=150), :54-61 (9 consultas de prefijo), :80-87 (getAll de profiles+users+blocks inversos por candidato, más waves from/to hasta 500 cada una); lib/services/user_service_live.dart:127-133 (await getUser(uid) secuencial por persona); firestore.rules:131 + :13-16 (cada lectura de perfil hace 2 exists(); Google cobra las lecturas que hacen las reglas, verificado en firebase.google.com/docs/firestore/pricing). Precio verificado en cloud.google.com/firestore/pricing: southamerica-east1 cobra US$0,045 por 100k lecturas.
- **Detalle:** Con 9 prefijos p5 saturados: 2 + 1.350 + 3×1.350 + ~60 waves + ~3 bloqueos = ~5.465 lecturas en el servidor, más hasta 50×3 = 150 en el cliente. Eso da ~US$0,0025 por llamada (US$2,53 por cada 1.000). La saturación de 150 por prefijo llega con ~7,6 usuarios/km², o sea ~5,3k usuarios con ubicación repartidos parejo en 700 km² de Santiago, o ~1,8k si se concentran ×3 en las comunas core. Es justo el escenario de un lanzamiento por comuna. Supuestos: DAU/MAU 25% y 8 getNearby por DAU al día. Con eso, Cerca cuesta ~US$0,15 por MAU al mes: US$1,5k/mes con 10k MAU, US$15k con 100k y US$152k con 1M. Es el 99% del gasto de Firestore. El ingreso neto de Plus es ~US$0,075–0,15 por MAU al mes (conversión 2–4%, $4.990 CLP, IVA 19%, 15% de comisión de tienda, 950 CLP/USD, supuestos). El costo por llamada además queda topado, así que no mejora con la escala: el modelo de negocio no cierra.
- **Recomendación:** Reescribir getNearby: (1) desnormalizar `locations/{uid}` = {g7, cityId, visible, adult, lastActiveAt, expireAt} escrito solo por el servidor (updateLocation más un trigger onWrite de profiles/users); (2) consultar con límites calculados por radio (geofire-common `geohashQueryBounds` o un port propio) y `where('visible','==',true)`, con un tope de candidatos ordenados por distancia; (3) un solo doc `relations/{uid}` {blocked[], blockedBy[], wavedWith[]} mantenido por blockUser/sendWave/respondWave, que se lee 1 vez; (4) la respuesta trae la tarjeta pública (nombre, edad, thumb, 3 intereses), así el cliente hace 0 lecturas de perfiles; (5) caché por instancia (LRU) de la lista base por (cityId, celda, radio) con TTL de 60 s. Presupuesto verificable: ≤25 lecturas por llamada en p95, medidas con un contador de lecturas en un test de emulador y con una métrica de logs en prod.

### SC-02 · P0 · bug
**Truncamiento silencioso y sesgado en Cerca: B5 vuelve en zonas densas**

- **Evidencia:** functions/src/getNearby.ts:56-60 (rango geohash + limit(150) sin orderBy de distancia ni recencia); functions/src/pure/nearbyFilter.ts:35-44 (visibilidad, edad, bloqueos y recencia se filtran DESPUÉS del limit); functions/src/updateLocation.ts:34-37 (sin expireAt; locations solo se borra en deleteAccount)
- **Detalle:** Firestore devuelve los primeros 150 en orden lexicográfico de geohash, que es la curva Z. Siempre son las subceldas del SW de cada celda p5, y la gente del NE de cada celda es invisible para todos. Los docs viejos (más de 7 días, que nunca expiran), los invisibles, los menores y los bloqueados ocupan cupos y se descartan después, así que el resultado real puede ser casi vacío aunque haya cientos de personas activas. Ejemplo: si en Providencia (14,4 km², ~150k habitantes) se registra el 2%, una celda p5 de 19,8 km² puede tener miles de docs y solo se ven 150 por prefijo (<5%). Esto mata la liquidez, que según §7.1 es la condición para monetizar.
- **Recomendación:** Filtrar en la consulta (visible==true, TTL a 7 días para que los docs viejos no existan), paginar de forma determinística por límite y fusionar ordenando por distancia y luego por recencia, con tope K. Test obligatorio con emulador: 5.000 usuarios sintéticos en una sola celda p5 → getNearby devuelve exactamente los K más cercanos visibles y activos (comparado contra fuerza bruta).

### SC-04 · P0 · ops
**App Check exigido en el servidor sin SDK en el cliente: en producción todos los callables fallan**

- **Evidencia:** functions/src/https.ts:5-8 (enforceAppCheck: true en todos los callables); pubspec.yaml y pubspec.lock sin firebase_app_check (grep vacío); lib/firebase_boot.dart:8-18 (no activa App Check); docs/adr/0003-app-check-fail-closed.md
- **Detalle:** El cliente nunca obtiene un token de App Check, así que updateLocation, getNearby, sendWave, blockUser, deleteAccount y exportMyData responden 401 en cualquier proyecto real, aunque un humano configure App Check en la consola. El ADR presenta esto como 'falla cerrado hasta que el humano lo configure', pero configurarlo en la consola no basta: falta código. Consecuencia: Cerca vacía, sin saludos y sin borrado de cuenta, lo que además incumple Apple 5.1.1(v).
- **Recomendación:** Agregar firebase_app_check con Play Integrity (Android), App Attest con fallback a DeviceCheck (iOS), reCAPTCHA Enterprise (web) y proveedor debug en dev/staging. Activarlo en firebase_boot antes del primer callable. Hacer un test de integración en staging que llame a getNearby con un token válido y otro sin token (este debe dar 401). Para Firestore y Storage, primero modo monitor, luego enforcement cuando el % de solicitudes verificadas en las métricas de App Check sea ≥99% durante 7 días.

### SC-06 · P0 · ops
**El deploy de Functions es imposible y el CI no lo detecta (Node 20 decomisionado, build roto, sin predeploy)**

- **Evidencia:** functions/package.json:5-7 (engines node 20); verificado en docs.cloud.google.com/functions/docs/runtime-support: Node 20 se deprecó el 2026-04-30 y se decomisiona el 2026-10-30, y después ya no se pueden crear ni actualizar funciones; functions/src/pure.test.ts:23 TS2441 (verificado por el orquestador: `npm run build` falla); firebase.json:9-21 (sin `predeploy` de build); .github/workflows/ci.yml (solo Flutter: no hay job de functions ni de firestore-tests con emulador)
- **Detalle:** Faltan 23 días para que Node 20 no acepte deploys. Aunque se corrija el runtime, el build falla y firebase.json no compila antes del deploy, así que lib/index.js no existe. Como el CI no corre lint, build ni test de functions ni las reglas en el emulador, cualquier regresión del backend llega a main sin que nadie la vea.
- **Recomendación:** Pasar engines a node 22 (o 24 si la versión de firebase-tools fijada lo soporta; verificarlo y escribir un ADR), con @types/node acorde. Excluir los *.test.ts del tsconfig de build (tsconfig.build.json) o arreglar el `require` duplicado. Agregar `predeploy: ["npm --prefix functions run build"]`. Agregar un job de CI con `npm ci && npm run lint && npm run build && npm test` y `firebase emulators:exec --only firestore,functions,auth 'npm --prefix firestore-tests test'`, obligatorio para hacer merge.

### SC-24 · P0 · security
**Denial-of-wallet: getNearby no tiene rate limit y cada llamada cuesta ~5.465 lecturas**

- **Evidencia:** functions/src/getNearby.ts:29-133 (sin rate limit por uid; el único rate limit del backend es el de 20 s en updateLocation, functions/src/pure/rateLimit.ts:1-6); functions/src/index.ts:4 (maxInstances 20 × concurrencia 80 por defecto = ~1.600 en paralelo, supuesto)
- **Detalle:** Una cuenta con un token de App Check válido (o un dispositivo rooteado que reutilice tokens durante su TTL) puede llamar en bucle. 50 req/s × 5.465 lecturas × US$0,45/M ≈ US$443 por hora, ~US$10,6k por día. Sin presupuestos ni alertas (SC-14), se descubre con la factura. También facilita la triangulación por buckets (lo cubre la lente de seguridad).
- **Recomendación:** Token bucket por uid y por callable: getNearby 20/min y 300/día, sendWave según SC-19, exportMyData 1/día, deleteAccount 3/día. En etapa A, contador en Firestore con TTL; en etapa B, Redis. Ante exceso, respuesta resource-exhausted y backoff en el cliente. Alerta de anomalía por uid (más de 5× el p99). Test: la llamada 21 en 60 s es rechazada.

### SC-03 · P1 · false_claim
**Las celdas consultadas no cubren los radios de 5 km (gratis) ni 10 km (Plus)**

- **Evidencia:** functions/src/pure/geohash.ts:5-11 (comentario: 'cell plus 8 neighbors cover the 10 km Plus radius') y :139-142; functions/src/pure/distance.ts:31-38. Sondeo propio con el código de Grok (tsx sobre pure/geohash.ts, 342 posiciones en Santiago): el 44% de las posiciones pierde gente a ≤5 km, el 100% la pierde a ≤10 km, y la distancia mínima no cubierta fue ~4,45 km.
- **Detalle:** Una celda p5 en la latitud -33,45 mide 4,08 km (E-O) × 4,86 km (N-S). El 3×3 garantiza solo 4,08 km hacia el E-O y como máximo 8,16 km. El radio gratis de 5 km falla según dónde estés y los 10 km de Plus son imposibles. Vender 'hasta 10 km' en Plus sin cumplirlo es publicidad engañosa (Ley 19.496) y causa reembolsos. Hoy es P1 porque Plus está apagado; pasa a P0 antes de encender PLUS_ENABLED.
- **Recomendación:** Calcular las celdas de cobertura en función del radio (geohashQueryBounds: precisión según el radio, hasta 9 límites que cubren el círculo completo). Agregar un test de propiedad: para 10k centros aleatorios por ciudad y radios {0,5, 1, 2, 5, 10} km, todo punto sintético dentro del radio cae en algún límite consultado. Corregir el comentario y docs/product/plus.md con el radio real.

### SC-05 · P1 · ops
**La cuota de Play Integrity (10k/día por defecto) rompe App Check apenas haya tracción**

- **Evidencia:** Verificado en developer.android.com/google/play/integrity: 10.000 solicitudes diarias por defecto, el aumento exige estar en Google Play y puede tardar hasta una semana. El repo no tiene configuración de TTL del token ni ADR de cuota (docs/adr/0003).
- **Detalle:** Supuesto: con un TTL del token de 1 h y ~3–4 sesiones separadas al día, cada DAU de Android gasta ~3 attestations. La cuota se agota con ~3k DAU de Android. Como App Check falla cerrado, toda la app de Android se cae justo en el pico de un lanzamiento o una campaña.
- **Recomendación:** Checklist de pre-lanzamiento: pedir el aumento de cuota de Play Integrity (y revisar los límites de App Attest y reCAPTCHA) ≥2 semanas antes de la beta abierta. Escribir un ADR con el TTL del token (p. ej. 6–12 h para los callables comunes y tokens de uso limitado/replay protection solo para deleteAccount y exportMyData). Alerta cuando el uso de la cuota supere el 70%.

### SC-07 · P1 · bug
**Presencia rota: lastActiveAt solo se escribe al hacer login, y la gente desaparece de Cerca a los 7 días**

- **Evidencia:** lib/services/auth_service_live.dart:325 y lib/services/auth_service.dart:232 (únicos llamadores de touchActivity: login y logout); functions/src/touchActivity.ts:10-17 (escribe profiles.activityBucket='ahora' fijo, que nunca decae); functions/src/pure/nearbyFilter.ts:42-44 + pure/activity.ts:11-17 (sin lastActiveAt en los últimos 7 días, la persona se omite); lib/widgets/public_profile_sheet.dart:31-32 (la UI muestra el bucket guardado)
- **Detalle:** En móvil la sesión dura semanas. Alguien que abre la app todos los días pero no vuelve a hacer login desaparece de Cerca para todos el día 8. Eso destruye la liquidez y no se ve en ningún log. Además, la ficha pública muestra 'ahora' para siempre (B4 de nuevo), y cerrar sesión marca 'ahora'.
- **Recomendación:** Escribir lastActiveAt dentro de updateLocation y getNearby (ya se llaman al abrir la app), con throttle en el servidor de ≥10 min por usuario. Calcular el bucket al leer, en el servidor, y no guardar strings de bucket en profiles. Borrar touchActivity o dejarlo solo para eventos de foreground con throttle. Test: un usuario con sesión iniciada que abre la app a diario durante 30 días simulados sigue visible.

### SC-08 · P1 · scalability
**Latencia y cold starts: N+1 secuencial, timeout de 4 s en updateLocation, sin minInstances e imports pesados**

- **Evidencia:** lib/services/user_service_live.dart:127-133 (hasta 50 lecturas de perfil secuenciales con await); lib/providers/location_provider.dart:192-199 (updateLocation con timeout de 4 s y error ignorado); functions/src/index.ts:4 (sin minInstances); functions/src/admin.ts:1-5 (carga auth, firestore, messaging y storage en el arranque de cada uno de los 10 servicios); functions/src/getNearby.ts:20-25 (getAll en chunks secuenciales: ~14 viajes de ida y vuelta por cada colección)
- **Detalle:** Supuesto: RTT Santiago→São Paulo de ~40–60 ms. Las 50 lecturas secuenciales suman 2–3 s después del callable, dentro del timeout de 8 s de nearby_provider.dart:90. Un cold start de Node con firebase-admin y storage (~1,5–3 s, supuesto) más la transacción de updateLocation supera los 4 s: el error se ignora, el usuario queda sin ubicación y es invisible, y getNearby responde 'Location is not set'. Los cold starts son más frecuentes con poco tráfico, o sea justo en el lanzamiento por comuna, cuando la liquidez más importa.
- **Recomendación:** El servidor devuelve las tarjetas (0 lecturas en el cliente). getAll en paralelo con Promise.all por chunks. Imports perezosos por función (o codebases separadas). minInstances: 1 en prod para getNearby y updateLocation (~US$14/mes cada uno, supuesto tier 2), opcionalmente con horario. Timeouts del cliente ≥10 s con 1 reintento con backoff. Presupuesto medido en staging: cold start <1,5 s y p95 en caliente de getNearby <400 ms en el servidor y <1,2 s de punta a punta desde Santiago.

### SC-09 · P1 · gap
**No hay políticas TTL: datos viejos para siempre, costo creciente y retención incumplida**

- **Evidencia:** functions/src/updateLocation.ts:34-37 (locations sin expireAt); functions/src/waves.ts:74-81 (waves sin expiración) y :58-60 ('already-exists' si hay un pending: un saludo ignorado en silencio bloquea al emisor para siempre); functions/src/revenuecatWebhook.ts:51-55 (webhookEvents infinito); firestore.indexes.json:37 (fieldOverrides vacío)
- **Detalle:** Los docs de ubicación viejos inflan las consultas geo (SC-02) y guardan la ubicación aproximada de personas inactivas sin plazo. Eso choca con la minimización y la retención de la Ley 21.719 (vigente desde el 2026-12-01). Los waves pendientes nunca vencen y quedan pares bloqueados de por vida. Los borrados por TTL cuestan US$0,015 por 100k en São Paulo (verificado), así que es casi gratis.
- **Recomendación:** Campo `expireAt` y políticas TTL versionadas en el repo (fieldOverrides con ttl en firestore.indexes.json o un script `infra/ttl.sh` con gcloud): locations 7 días desde la última actualización, waves pendientes 14 días y resueltos 90, webhookEvents 90, rateLimits 48 h, exports 7. Tests que confirmen que cada escritura pone expireAt. Retención documentada en la política de privacidad.

### SC-10 · P1 · scalability
**Mismas opciones de runtime para todas las funciones: tope global de 20 instancias y memoria por defecto**

- **Evidencia:** functions/src/index.ts:4 (setGlobalOptions({ region, maxInstances: 20 }) y nada más); functions/src/https.ts:5-8 (callableOptions sin memory, concurrency, minInstances ni timeoutSeconds)
- **Detalle:** Supuesto según la documentación de firebase-functions v2: por defecto cada función tiene 256 MiB, concurrencia 80 y timeout de 60 s. Un getNearby guarda ~5.465 snapshots (~5–10 MB, supuesto). Con 80 concurrentes se pasa de 256 MiB: OOM, reinicios y 5xx en el pico. El tope de 20 vale igual para el trigger de mensajes, el webhook y getNearby: un spike de mensajes encola eventos y atrasa los push, y un abuso de getNearby agota la capacidad de todo lo demás.
- **Recomendación:** Tabla de opciones por función en código y en un ADR: getNearby {memory 1GiB, concurrency 40, minInstances 1 en prod, maxInstances 100}; updateLocation {512MiB, 80, min 1}; onMessageCreated {256MiB, 80, max 200}; deleteAccount y exportMyData como encoladores livianos (SC-16); revenuecatWebhook {max 5}. Revisar los topes en cada etapa (SC-25).

### SC-11 · P1 · scalability
**Santiago está hardcodeado en cliente y servidor: abrir una ciudad exige publicar una versión nueva**

- **Evidencia:** lib/core/constants/santiago_bounds.dart:4-38; lib/services/geo_locator_bridge.dart:55 y :107-117 (forceSantiago=true por defecto: fuera del bbox, el cliente lanza una excepción); functions/src/pure/waveQuota.ts:4 (zona horaria America/Santiago fija para la cuota diaria); functions/src/pure/distance.ts:31-32 (radios fijos); docs/product/plus.md (solo CLP)
- **Detalle:** Ir a Valparaíso, Concepción, Lima o Bogotá exige recompilar y esperar la revisión de las tiendas. La cuota diaria se reiniciaría a medianoche de Santiago para un usuario de Lima. Los docs no tienen cityId, así que no hay métricas de liquidez por ciudad ni rollout por ciudad.
- **Recomendación:** Colección `cities/{cityId}` (polígono o set de geohash p4/p5 de cobertura, tz, moneda, launchState: waitlist/beta/open, radios disponibles, límites de saludos, flags) servida al cliente por Remote Config y leída en el servidor con caché en memoria de 5 min. El servidor deriva cityId del geohash en updateLocation y lo guarda en locations. El cliente reemplaza SantiagoBounds por la config (Santiago queda solo como fallback offline). Tests con fixtures de Santiago, Valparaíso y Lima, incluido el reinicio de cuota en la tz local.

### SC-12 · P1 · gap
**Los flags se fijan al compilar: no hay rollout por ciudad o cohorte ni kill switch**

- **Evidencia:** lib/core/config/app_config.dart:321-331 (WAVES_ENABLED y PLUS_ENABLED con bool.fromEnvironment); pubspec.yaml sin firebase_remote_config; docs/product/plus.md ('Se enciende por cohorte, no para toda la ciudad de una vez'); el servidor usa constantes (pure/waveQuota.ts:1, pure/distance.ts:31-32)
- **Detalle:** La estrategia de monetización por fases (§7.1: encender Plus por comuna o cohorte cuando haya liquidez) no se puede ejecutar: cada cambio de flag requiere una release. Tampoco hay un kill switch para degradar Cerca (por ejemplo, bajar el radio o el tope de candidatos) si se dispara el costo.
- **Recomendación:** firebase_remote_config con condiciones por cityId, cohorte y % de usuarios. Espejo en el servidor `config/runtime` (flags y límites) cacheado 5 min y aplicado en las Functions. Kill switches: nearby_max_candidates, nearby_enabled, push_enabled y waves_daily_limit. Test: con plus_enabled=false en la ciudad X, el paywall no aparece y el servidor ignora los entitlements para el radio.

### SC-13 · P1 · ops
**Un solo proyecto Firebase: no hay dev, staging ni prod separados**

- **Evidencia:** .firebaserc:1-5 (solo default: picaflorapp); .github/workflows/deploy-web.yml:6 y :48 (el mismo projectId para demo y prod, elegido con un input); lib/core/config/app_config.dart:315-319 (FLAVOR existe pero no hay env/*.json ni firebase_options por flavor)
- **Detalle:** Las pruebas de carga, los seeds de usuarios sintéticos, App Check debug y los cambios de reglas van a la misma base que los usuarios reales. Los presupuestos y alertas no se pueden separar, y un error en staging gasta la cuota de Play Integrity y la plata de producción.
- **Recomendación:** Proyectos picaflor-dev, picaflor-stg y picaflor-prod (los crea el humano), con aliases en .firebaserc, `env/<flavor>.json` + `--dart-define-from-file`, `flutterfire configure` por flavor y workflows de deploy por entorno con aprobación manual para prod. Los seeds de carga solo en stg.

### SC-14 · P1 · ops
**No hay observabilidad de costo: sin presupuestos, alertas, métricas de lecturas ni freno automático**

- **Evidencia:** No hay infra/ ni documentación de budgets; los logs son solo `logger.info('getNearby.ok', { count })` (getNearby.ts:76,131), sin latencia ni lecturas; docs/PLAN.md no menciona costos
- **Detalle:** Con SC-01 sin resolver, un bug de recarga en el cliente o un abuso puede quemar miles de dólares en horas (SC-15b: ~US$443/h con 50 req/s) y nadie se entera hasta que llega la factura.
- **Recomendación:** Cloud Billing budgets por proyecto con alertas al 50/80/100% y notificación por Pub/Sub a una función que activa los kill switches de SC-12. Métricas de logs (lecturas por llamada, latencia, resultado) por callable. Dashboard de costo por MAU y por llamada. Alerta si el promedio de lecturas de getNearby pasa de 50 o si el gasto diario de Firestore supera el umbral del ADR. SLOs (disponibilidad 99,5% en etapa A y p95 de getNearby).

### SC-15 · P1 · gap
**Sin analytics ni BigQuery: el umbral de liquidez para encender Plus no se puede medir**

- **Evidencia:** lib/core/analytics/app_analytics.dart:33-45 (solo MemoryAnalytics); pubspec.yaml sin firebase_analytics ni crashlytics; docs/product/plus.md ('al menos el 60% de las sesiones con 5 o más personas activas a 3 km')
- **Detalle:** La North Star, el embudo, la liquidez por comuna, la conversión y el costo por MAU no tienen fuente. La decisión clave del negocio (cuándo cobrar) depende de una métrica que hoy no existe.
- **Recomendación:** firebase_analytics condicionado al consentimiento (eventos de §7.6 sin PII), con export a BigQuery diario y streaming. Eventos de servidor estructurados (`nearby_served{cityId, cell5, count_bucket, radius}`) a BigQuery con un log sink. SQL versionado en `analytics/` para la liquidez por comuna, la North Star y el costo por MAU. El gate de Plus se lee de esa tabla.

### SC-16 · P1 · scalability
**deleteAccount y exportMyData son síncronos y sin límite: van a fallar con usuarios activos**

- **Evidencia:** functions/src/deleteAccount.ts:18-32 (una consulta secuencial por chat y lotes de 400 secuenciales), :34-54 (no borra waves recibidos, chats ni reports, y no se puede reanudar); functions/src/exportMyData.ts:21-28 (una consulta secuencial por chat) y :31-41 (todo el export va en la respuesta)
- **Detalle:** Un usuario con 300 chats y 20k mensajes necesita cientos de viajes de ida y vuelta y 50 commits secuenciales: supera el timeout de 60 s (supuesto por defecto), queda a medio borrar y el reintento no sabe dónde quedó. El export puede pasar el límite de tamaño de respuesta de Cloud Run (32 MiB, supuesto) y el timeout. Es un incumplimiento operativo de 5.1.1(v) y de la Ley 21.719.
- **Recomendación:** El callable solo encola: `deletionRequests/{uid}` → Cloud Tasks → worker idempotente y reanudable (BulkWriter, recursiveDelete, cursores), con estado visible para el usuario y SLA de 30 días. El export se genera async a GCS con una URL firmada de 24 h y se avisa por push o email. Test con emulador: usuario con 10k mensajes en 200 chats → borrado completo verificado y reintento idempotente.

### SC-17 · P1 · false_claim
**El ADR de región se basa en un dato falso: Santiago (southamerica-west1) sí soporta Firestore y Functions 2.ª gen**

- **Evidencia:** docs/adr/0005-region-southamerica-east1.md:13 ('southamerica-west1 (Santiago) no ofrece el mismo set de productos'). Verificado: firebase.google.com/docs/firestore/locations lista southamerica-west1 (Santiago) y firebase.google.com/docs/functions/locations dice 'southamerica-west1 | Santiago, Chile | 2nd gen only' (todas las funciones de Grok son v2). Precios de Firestore verificados: west1 cobra US$0,043/0,129/0,014 por 100k lecturas/escrituras/borrados y east1 US$0,045/0,135/0,015; las dos regiones están en el Tier 2 de Cloud Run.
- **Detalle:** La ubicación de la base no se puede cambiar después de crearla. Con 100% de usuarios iniciales en Santiago, west1 da menos RTT (supuesto: ~2–5 ms contra ~40–60 ms) en los listeners de chat y los callables, cuesta ~4% menos y simplifica la transferencia internacional de datos bajo la Ley 21.719 (supuesto, validar con abogado). east1 puede convenir si en 12–18 meses se prioriza Brasil o Argentina. Es una decisión irreversible que hoy se apoya en una premisa falsa.
- **Recomendación:** Reescribir el ADR 0005 con datos medidos (gcping desde Santiago, disponibilidad verificada de Firestore, Functions v2, Eventarc y Storage en west1) y presentar al humano la recomendación southamerica-west1 para la base (default), con el plan multi-región de SC-25. Decidir antes de crear el proyecto prod.

### SC-18 · P1 · bug
**Chats sin paginación, badge calculado sobre todos los chats y chats aceptados que no aparecen en la lista**

- **Evidencia:** lib/services/chat_service_live.dart:43-56 (watchUserChats sin limit) y :46 (orderBy lastMessageAt); lib/services/chat_service.dart:339-347 (no leídos totales = suma sobre todos los chats); functions/src/waves.ts:128-136 (respondWave crea el chat sin lastMessageAt); chat_service_live.dart:131-134 (cursor por timestamp, no por documento)
- **Detalle:** Firestore excluye del orderBy los docs que no tienen el campo, así que un chat recién aceptado no aparece en la lista hasta que alguien escriba. Corta el embudo saludo→chat (además, ninguna UI llama a respondWave). Un usuario con 300 chats lee 300 docs al abrir la app y de nuevo tras 30 min desconectado (Firestore cobra la consulta completa al reconectar). Paginar con startAfter(timestamp) puede saltarse mensajes con la misma marca de tiempo.
- **Recomendación:** respondWave escribe lastMessageAt=createdAt. La lista usa limit(30) con paginación por documento. Doc `inbox/{uid}` {unreadChats} mantenido por el trigger solo en las transiciones 0↔n, para el badge. startAfterDocument para los mensajes. Índice (to, status, createdAt) para la bandeja de saludos.

### SC-19 · P1 · monetization
**La cuota de saludos no es atómica: se puede saltar con concurrencia, y el costo de Plus es O(n²)**

- **Evidencia:** functions/src/waves.ts:46-81 (lee la cuota, la verifica y escribe fuera de una transacción; id automático; la consulta de 'hoy' trae todos los waves del día); functions/src/pure/waveQuota.ts:64 (Plus sin ningún límite de velocidad); firestore.rules:180-186 (reports sin rate limit)
- **Detalle:** 20 llamadas paralelas desde la cuenta gratis pasan todas la verificación (sentToday=19), así que se puede saltar el límite que justifica Plus. Por la misma carrera, el chequeo de 'pending duplicado' deja crear duplicados. Un usuario Plus spammer que manda 1.000 saludos en un día lee ~500k docs en ese día (cada envío relee todos los anteriores). Además, cualquier cuenta puede inundar `reports` sin límite.
- **Recomendación:** Id determinístico de wave `${from}_${to}` con create(), que falla si ya existe. Contador `waveCounters/{uid}_{yyyymmdd_tz}` con TTL dentro de una transacción. Límites de velocidad también para Plus (p. ej. 10/min y 200/día) configurables por Remote Config. reports vía callable con dedupe (reporter+target+día) y límite. Test: 20 llamadas concurrentes → exactamente 20 aceptadas y la 21 rechazada.

### SC-21 · P1 · process
**Moderación a escala inexistente: la UI promete revisar en 24 h y no hay cola**

- **Evidencia:** lib/widgets/public_profile_sheet.dart:166 ('Gracias. Lo revisamos en menos de 24 h.'); docs/security/threat-model.md ('No hay cola de moderación en este repo. Un humano tiene que leerlos en consola'); reports no tiene trigger (functions/src/index.ts:6-14)
- **Detalle:** Supuesto: 5–20 reportes por 1.000 MAU al mes, o sea 500–2.000 al mes con 100k MAU y 5k–20k con 1M. Leerlos en la consola de Firebase no escala y la promesa de 24 h es falsa desde el día 1. Los reportes de 'posible menor' necesitan prioridad máxima. Es un riesgo de tiendas (1.2 / UGC) y legal.
- **Recomendación:** Trigger en reports → puntaje de prioridad (menor y sexual primero) → cola (Pub/Sub o Cloud Tasks) → consola de revisión mínima (app admin con custom claims). Acciones automáticas: N reportes únicos en 24 h → oculto de Cerca hasta revisión. Métrica del SLA a BigQuery y alerta si un reporte lleva más de 20 h sin revisar. Copy de la UI atado al SLA real.

### SC-25 · P1 · design
**Arquitectura objetivo 'v2 escalable' por etapas, con disparadores**

- **Evidencia:** Síntesis de SC-01..SC-24; precios verificados en las páginas de Firestore y Cloud Run (Tier 1: US$0,000024/vCPU-s, US$0,0000025/GiB-s, US$0,40 por millón de solicitudes; nivel gratuito de 180k vCPU-s, 360k GiB-s y 2M solicitudes al mes; las dos regiones de Sudamérica están en el Tier 2)
- **Detalle:** ETAPA A (0–10k MAU, 1 ciudad, 1–5 comunas). Firestore con 1 base en la región decidida (SC-17) y Functions v2. getNearby v2: locations desnormalizado con TTL, geohashQueryBounds por radio, visible==true, tope K por distancia, caché LRU por instancia (cityId, celda p6, radio) de 60 s, relations/{uid} y tarjeta en la respuesta. Rate limits en Firestore con TTL. minInstances 1 en getNearby y updateLocation. Remote Config + cities/{cityId}. Presupuestos, alertas y kill switches. Analytics → BigQuery. Proyectos dev/stg/prod. Objetivos: ≤25 lecturas por llamada, Firestore ≤US$0,002 por MAU al mes, infra total ≤US$0,01 por MAU al mes (≤10% del ingreso neto). Pasar a B si ocurre cualquiera de estos: una celda p5 con más de 500 usuarios activos en 7 días; p95 de getNearby >800 ms; Firestore >US$500/mes o >10% del ingreso neto; más de 3 ciudades; más de 50 reportes/día. ETAPA B (10k–100k MAU, 3–10 ciudades de Chile + piloto LATAM). Celdas materializadas `nearbyCells/{cityId}_{g6}` reconstruidas por un agregador (Scheduler cada 1 min o Pub/Sub con ≤1 escritura cada 30 s por celda, respetando ~1 escritura/s por documento): una lectura de Cerca son 9–25 docs. Memorystore Redis (caché y token buckets) vía Direct VPC egress. Pub/Sub para push (coalescencia) y moderación (worker en Cloud Run + cola humana con SLA). Cloud Tasks para borrado y export. Lista de chats paginada + inbox doc. FinOps: costo por MAU por ciudad y evaluación de CUD. Pasar a C si: más de 100 consultas geo/s sostenidas en el pico; Plus necesita filtros ricos (intereses, rango de edad, 'activos ahora') o ranking; Firestore >US$5k/mes; desde una ciudad clave el p95 de RTT a la región de la base pasa de 120 ms (p. ej. CDMX o Bogotá → São Paulo); 2 o más países. ETAPA C (100k–1M+ MAU, multi-país). Servicio geo dedicado en Cloud Run: Redis GEO (GEOSEARCH, shard por ciudad) para el camino caliente de quién está cerca, y Typesense (geo + facetas) para los filtros de Plus y la búsqueda por intereses. Se alimenta por Pub/Sub desde updateLocation, y Firestore deja de ser el índice geo. PostGIS/BigQuery GIS para polígonos de cobertura y analítica. Bases de Firestore con nombre por macro-región (CL/AR/PE en southamerica-west1, BR en southamerica-east1, MX/CO en la región disponible más cercana; verificar soporte) con un directorio global cityId→región. Functions y Cloud Run desplegadas por región, y Remote Config entrega el endpoint según la ciudad. Experimentación A/B de precios por país (RevenueCat offerings). Equipo de T&S con consola propia. SLO 99,9%.
- **Recomendación:** Exigir en v2 `docs/scale/roadmap.md` con estas 3 etapas, sus métricas de disparo conectadas a alertas reales (SC-14) y un ADR por cada salto (geo dedicado, Redis, multi-DB). La etapa A es obligatoria antes de la beta pública. B y C se diseñan ahora (interfaces NearbyIndex y PushDispatcher) para que el salto sea cambiar una implementación y no reescribir la app.

### SC-20 · P2 · scalability
**onMessageCreated no es idempotente, modera después de escribir y no administra tokens ni coalescencia de push**

- **Evidencia:** functions/src/onMessageCreated.ts:24-28 (el texto se reemplaza después de que el destinatario ya lo vio), :47-50 (increment sin dedupe por event.id con entrega al-menos-una-vez), :54-71 (no limpia tokens inválidos, no tiene collapseKey ni thread, envía 1 push por mensaje aunque el chat esté abierto); lib/services/chat_service_live.dart:118-121 (markRead escribe el mismo doc de chat)
- **Detalle:** Supuesto: ~3 escrituras y ~13 lecturas por mensaje (regla get(chat), lectura del trigger, listeners de mensajes, de la lista y de watchChat en ambos lados), ~US$10 en Firestore y ~US$7 en Functions por millón de mensajes. Es manejable, pero en ráfagas (>1 msg/s) el doc del chat recibe ~2 escrituras por mensaje, cerca del límite sostenido de ~1 escritura/s por documento, y el trigger sin reintento pierde actualizaciones de lastMessage y unreadCount. Los tokens muertos se acumulan para siempre.
- **Recomendación:** Dedupe por event.id (doc de procesado con TTL). Borrar los tokens con error registration-token-not-registered. collapseKey y apns thread-id por chat, y como máximo 1 push por chat cada 60 s mientras haya no leídos. En etapa B, push vía Pub/Sub. Moderación previa a la visibilidad (estado pending) cuando haya clasificador.

### SC-22 · P2 · scalability
**El cliente no cachea Cerca, repite llamadas y tiene una carrera entre updateLocation y getNearby**

- **Evidencia:** lib/providers/nearby_provider.dart:57-106 (FutureProvider.autoDispose sin TTL: cada cambio de radio o de lista de bloqueados vuelve a llamar al servidor); lib/screens/nearby/nearby_screen.dart:136-140 (refresh() cambia la ubicación y además hace invalidate, dos llamadas posibles); lib/providers/location_provider.dart:161-162 (updateLocation sin await antes de que el provider dispare getNearby, el primer intento da 'Location is not set')
- **Detalle:** El set de candidatos depende de las celdas, no del radio. Cambiar el radio dentro del máximo no debería costar otra consulta. Supuesto: con caché de 60–120 s en el cliente las llamadas por DAU bajan ≥40%.
- **Recomendación:** Caché en memoria y disco (solo uids, buckets y tarjeta, sin coordenadas) con TTL de 90 s y stale-while-revalidate. El servidor devuelve hasta el radio máximo permitido y el cliente filtra por radio. Encadenar updateLocation→getNearby (o un callable 'refreshNearby' que haga las dos cosas). Test: con 5 cambios de radio en 60 s → 1 sola llamada.

### SC-23 · P2 · scalability
**Índices: faltan exenciones para textos largos y el índice de la bandeja de saludos; las reglas triplican las lecturas de perfiles**

- **Evidencia:** firestore.indexes.json:37 (fieldOverrides vacío: messages.text, profiles.bio, waves.note y reports.text se indexan solos); no hay índice (to, status, createdAt) para la bandeja; firestore.rules:131 (cada lectura de perfil cobra 2 exists() extra; chat_list_screen.dart:159 resuelve un perfil por chat)
- **Detalle:** Indexar textos de hasta 2.000 caracteres infla el almacenamiento de índices y la latencia de escritura sin que ninguna consulta lo use. Una lista de 30 chats cuesta 90 lecturas solo en perfiles.
- **Recomendación:** fieldOverrides con indexes: [] para messages.text, profiles.bio, waves.note y reports.text. Índice compuesto para la bandeja. La regla de profiles consulta un solo doc `relations/{me}` (1 get) en vez de 2 exists(). Opcional: denormalizar en el chat un resumen del otro participante (nombre y thumb) actualizado por trigger.

**Requisitos que esta lente exige para la v2**

- Presupuesto de Cerca: getNearby hace ≤25 lecturas de Firestore por llamada en p95, sumando servidor y cliente. Se verifica con un test de emulador que cuenta lecturas (wrapper del Admin SDK) sobre 5.000 usuarios sintéticos en una celda, y en prod con una métrica de logs `nearby_reads` y una alerta si el promedio supera 50.
- Test de propiedad de cobertura: para 10k centros aleatorios por ciudad y radios {0,5, 1, 2, 5, 10} km, el 100% de los usuarios sintéticos dentro del radio cae en algún límite consultado (geohashQueryBounds o equivalente). Se corrige el comentario de geohash.ts:5-11.
- Sin truncamiento silencioso: con más candidatos que el tope K, getNearby devuelve exactamente los K más cercanos visibles, adultos, activos y no bloqueados (comparado contra fuerza bruta en el test), con un cursor de paginación determinístico.
- Desnormalización: `locations/{uid}` = {g7, cityId, visible, adult, lastActiveAt, expireAt}, escrito solo por el servidor y sincronizado por trigger al cambiar profile o birthDate. La respuesta de getNearby incluye la tarjeta pública y el cliente hace 0 lecturas de profiles para Cerca (test de widget o integración con un spy del repositorio).
- Un solo doc `relations/{uid}` {blocked[], blockedBy[], wavedWith[]} mantenido por blockUser, sendWave y respondWave. getNearby y la regla de profiles hacen 1 lectura en vez de N.
- Políticas TTL versionadas en el repo: locations 7 días, waves pendientes 14 y resueltos 90, webhookEvents 90, rateLimits 48 h, exports 7. Tests que confirman que cada escritura pone expireAt.
- Rate limits por uid y callable, documentados en una tabla (getNearby 20/min y 300/día; sendWave gratis 20/día y Plus 10/min y 200/día; exportMyData 1/día; deleteAccount 3/día; reports con dedupe por reporter+target+día), con tests de rechazo resource-exhausted y backoff en el cliente.
- sendWave atómico: id `${from}_${to}` con create() y contador diario en una transacción, en la zona horaria de la ciudad. Test con 20 llamadas concurrentes: exactamente el cupo aceptado.
- Opciones de runtime por función en código y en un ADR (memory, cpu, concurrency, minInstances, maxInstances, timeoutSeconds). minInstances 1 en prod para getNearby y updateLocation, e imports perezosos. Cold start medido <1,5 s y p95 en caliente de getNearby <400 ms en staging.
- Cadena de deploy: Node 22 o superior (verificar soporte en firebase-tools), build sin tests (tsconfig.build.json), `predeploy` en firebase.json y un job de CI obligatorio con functions (npm ci, lint, build, test) y reglas en emulador (firebase emulators:exec). La salida se pega en el PR.
- App Check de punta a punta: firebase_app_check en el cliente (Play Integrity / App Attest con fallback a DeviceCheck / reCAPTCHA Enterprise en web y debug en dev/stg), ADR del TTL del token, tokens de uso limitado en deleteAccount y exportMyData, y pedido de aumento de cuota de Play Integrity ≥2 semanas antes de la beta. Test en staging: con token, 200; sin token, 401.
- Presencia: lastActiveAt se escribe junto con updateLocation y getNearby (throttle ≥10 min), el bucket se calcula al leer en el servidor y se elimina el activityBucket guardado. Test: un usuario con sesión que usa la app a diario durante 30 días simulados sigue visible.
- Multi-ciudad: colección `cities/{cityId}` (cobertura, tz, moneda, launchState, radios, límites, flags), cityId derivado en el servidor, cliente sin SantiagoBounds como regla (solo fallback). Tests con fixtures de Santiago, Valparaíso y Lima, incluida la cuota diaria en la tz local.
- Remote Config con condiciones por cityId y cohorte (plus_enabled, waves_daily_limit, nearby_max_radius, nearby_max_candidates, push_enabled) y espejo en el servidor `config/runtime` con caché de 5 min. Los kill switches se prueban en staging.
- Entornos: proyectos picaflor-dev, picaflor-stg y picaflor-prod (los crea el humano), aliases en .firebaserc, env/<flavor>.json, firebase_options por flavor, y deploy por entorno con aprobación manual para prod. Las pruebas de carga corren solo en stg.
- FinOps: presupuestos por proyecto con alertas al 50/80/100% y notificación por Pub/Sub que activa kill switches. Dashboard de costo por MAU y por llamada. `docs/scale/costs.md` con un modelo de costo reproducible (script) y sus supuestos explícitos.
- Analytics: firebase_analytics condicionado al consentimiento, export a BigQuery, eventos de servidor por log sink, y SQL versionado para la liquidez por comuna (gate de Plus), la North Star y el costo por MAU.
- Jobs async: deleteAccount y exportMyData encolados en Cloud Tasks, idempotentes y reanudables (BulkWriter/recursiveDelete), export a GCS con URL firmada de 24 h. Test con un usuario de 10k mensajes en 200 chats.
- Chats: lista con limit(30) y paginación por documento, inbox doc para el badge, respondWave escribe lastMessageAt, mensajes con startAfterDocument e índice (to, status, createdAt) para la bandeja de saludos.
- onMessageCreated idempotente (dedupe por event.id), limpieza de tokens inválidos, collapseKey y thread por chat, y como máximo 1 push por chat cada 60 s con no leídos.
- Moderación: trigger en reports → priorización → cola → consola admin, auto-ocultar con umbral, métrica y alerta del SLA, y copy de la UI alineado al SLA real.
- Región: ADR 0005 reescrito con RTT medido desde Santiago y disponibilidad verificada (southamerica-west1 sí soporta Firestore y Functions v2), con recomendación al humano antes de crear la base prod y plan multi-región con bases con nombre.
- Prueba de carga como gate de la beta: un script k6 o Artillery en stg con 50k usuarios sintéticos en Santiago y 200 req/s a getNearby. Reporte de p95, lecturas por llamada, US$ por cada 1.000 llamadas y errores.
- docs/scale/roadmap.md con las etapas A/B/C, sus disparadores numéricos conectados a alertas y las interfaces NearbyIndex y PushDispatcher, para cambiar de implementación (Firestore → celdas materializadas → Redis GEO/Typesense) sin tocar el cliente.
- Exenciones de índices para los textos largos (messages.text, profiles.bio, waves.note, reports.text) declaradas en firestore.indexes.json.

**Cifras clave**

| Métrica | Valor | Base |
|---------|-------|------|
| Precio Firestore southamerica-east1 (lectura / escritura / borrado por 100k) | US$0,045 / US$0,135 / US$0,015 | Verificado: cloud.google.com/firestore/pricing (tabla por región) |
| Precio Firestore southamerica-west1 (lectura / escritura / borrado por 100k) | US$0,043 / US$0,129 / US$0,014 | Verificado: cloud.google.com/firestore/pricing |
| Disponibilidad en Santiago (southamerica-west1) | Firestore sí; Cloud Functions solo 2.ª gen; Tier 2 de precios | Verificado: firebase.google.com/docs/firestore/locations y firebase.google.com/docs/functions/locations |
| Decomisión del runtime Node 20 | 2026-10-30 (23 días); después no se puede crear ni actualizar | Verificado: docs.cloud.google.com/functions/docs/runtime-support |
| Cuota por defecto de Play Integrity | 10.000 solicitudes/día; el aumento tarda hasta 1 semana | Verificado: developer.android.com/google/play/integrity |
| Celda geohash p5 en Santiago (lat -33,45) | 4,08 km (E-O) × 4,86 km (N-S) = 19,8 km²; 3×3 = 178 km² | Calculado con la fórmula de geohash (13 bits de longitud, 12 de latitud) |
| Cobertura real de las 9 celdas consultadas | 44% de las posiciones pierde gente a ≤5 km; 100% la pierde a ≤10 km; distancia mínima no cubierta ~4,45 km | Sondeo propio ejecutando functions/src/pure/geohash.ts de Grok con tsx (342 posiciones en Santiago) |
| Lecturas por llamada a getNearby (saturado) | ~5.465 en el servidor + ~150 en el cliente (N+1 × 3 por las reglas) ≈ 5.615 | Contado desde getNearby.ts:54-87 y user_service_live.dart:127-133; supuesto ~60 waves y ~3 bloqueos por usuario |
| Usuarios con ubicación que saturan 150 por prefijo | ~1,8k (concentración ×3) a ~5,3k (uniforme en 700 km²) | Supuesto: área urbana de 700 km² y concentración en comunas core |
| Costo por llamada a getNearby (São Paulo) | ~US$0,0025 (US$2,53 por 1.000 llamadas) | Precio verificado × lecturas contadas |
| Costo de Cerca por MAU al mes (diseño actual) | ~US$0,15/MAU; US$1,5k (10k MAU), US$15k (100k), US$152k (1M) | Supuestos: DAU/MAU 25%, 8 getNearby por DAU al día, 30 días |
| Costo de Cerca por MAU al mes (diseño objetivo, ~7 lecturas/llamada) | ~US$0,0002/MAU; ~US$18/mes con 100k MAU (~800× menos) | Supuesto: 70% de aciertos de caché y 9–13 lecturas por fallo |
| Ingreso neto de Plus por MAU al mes | US$0,075–0,15 | Supuestos: $4.990 CLP, IVA 19%, 950 CLP/USD, 15% de comisión de tienda, conversión 2–4% |
| Denial-of-wallet con 50 getNearby/s | ~US$443/hora, ~US$10,6k/día | Supuesto de tasa de abuso × lecturas por llamada × precio verificado |
| Costo por mensaje de chat | ~3 escrituras + ~13 lecturas ≈ US$10 por millón en Firestore + ~US$7 por millón en Functions | Supuesto: listeners de ambos participantes activos, CPU de 50 ms, Tier 2 ≈1,4× Tier 1 |
| Precio de Cloud Run Tier 1 (base de las Functions v2) | US$0,000024/vCPU-s, US$0,0000025/GiB-s, US$0,40 por millón de solicitudes; gratis 180k vCPU-s, 360k GiB-s y 2M solicitudes al mes | Verificado: cloud.google.com/run/pricing. Las 2 regiones de Sudamérica están en Tier 2 (precio exacto del Tier 2 no verificado, supuesto ~1,4×) |
| minInstance inactiva (1 vCPU, 512 MiB, Tier 2) | ~US$14/mes por función | Supuesto: tarifa idle de Tier 1 × 1,4 |
| Techo de concurrencia actual | 20 instancias × 80 = ~1.600 solicitudes en paralelo para TODAS las funciones; 256 MiB por defecto | index.ts:4; los valores por defecto de concurrencia y memoria de firebase-functions v2 son supuestos (verificar) |
| Límite de escritura sostenida por documento | ~1 escritura/s (doc de chat: ~2 escrituras por mensaje en ráfaga) | Límite documentado de Firestore (supuesto: no re-verificado en esta sesión) |

## MO · Monetización y crecimiento

**Veredicto de la lente**

Veredicto (lente monetización y crecimiento): Grok respetó bien el principio de v1 de no cobrar antes de tener liquidez. Plus quedó apagado, la seguridad es gratis, el cupo y el radio se validan en servidor, entitlements solo los escribe el servidor y el webhook es idempotente con auth fail-closed. Pero la rama NO es monetizable ni medible, y hoy tampoco puede generar la liquidez de la que depende todo. (1) El loop Saludo→Aceptar→Chat no cierra en producción: no hay bandeja de saludos recibidos, respondWave no tiene llamadores, el receptor no recibe push y el chat aceptado no aparece en la lista porque nace sin lastMessageAt. (2) No hay analytics, Remote Config ni push en el cliente, así que el umbral de liquidez del 60% no se puede medir y Plus no se puede encender por comuna (el flag es de compilación). (3) La "lista de espera" es un SnackBar que no guarda nada: es una afirmación falsa al usuario y al README. (4) El webhook de RevenueCat le revocaría Plus a un suscriptor que compra un boost, no ordena los eventos, acepta sandbox y no maneja TRANSFER. (5) El beneficio Plus "10 km" no se puede entregar: la consulta geohash p5 3×3 garantiza ~4,1 km E-O en Santiago, y el "incógnito" ya es gratis de facto. (6) Con densidad, getNearby cuesta ~6.400 lecturas por llamada (~US$0,2/MAU/mes, supuesto), más que el ARPMAU esperado (~US$0,10). Con ese ingreso por usuario (LTV/instalación ~470 CLP, supuesto) la UA pagada no es viable: el crecimiento tiene que ser orgánico (campus/comuna, referidos por WhatsApp, eventos). Además hay que sumar ingresos sin comisión de tienda: Panoramas presenciales (Apple 3.1.3(e)) y Lugares B2B. Además el build de functions falla y Node 20 está en EOL (lo verificó el orquestador), así que hoy ni el webhook ni sendWave se pueden desplegar. Para tier 1, v2 debe cerrar el loop, instrumentar todo y rehacer el webhook sobre la API de RevenueCat. También debe hacer getNearby barato y fiel al radio, poner las palancas en Remote Config/Offerings y dejar un modelo de unit economics con go/no-go por zona.

**Lo que está bien y se preserva**

- Plus construido apagado ('no cobrar antes de liquidez') y seguridad gratis para siempre (bloquear, reportar, ocultarse, exportar, borrar): docs/product/plus.md:5-9, docs/adr/0007-plus-prices-proposed.md:9
- Cupo diario de saludos, nota solo Plus y tope de radio aplicados en servidor a partir del entitlement del servidor, no del cliente: functions/src/waves.ts:46-70, functions/src/getNearby.ts:50-51, functions/src/pure/distance.ts:34-37
- Día calendario del cupo calculado en America/Santiago (correcto con horario de verano): functions/src/pure/waveQuota.ts:4-32
- entitlements y webhookEvents sin escritura desde el cliente: firestore.rules:189-196
- Auth del webhook con comparación timing-safe, fail-closed si falta el secreto, e idempotencia por event id dentro de una transacción: functions/src/pure/webhookAuth.ts:9-22, functions/src/revenuecatWebhook.ts:40-57
- Nota del saludo moderada antes de guardarse (anti-spam y anti-acoso, protege la confianza): functions/src/waves.ts:36-38
- Formato CLP con punto de miles y copy 'IVA incluido' (Ley 19.496 art. 30, precio total): lib/core/privacy/wave_quota.dart:16-27, lib/screens/plus/plus_screen.dart:41-43
- Esqueleto del paywall con X visible desde el primer frame, 'Restaurar compras' visible y texto de renovación y cancelación: lib/screens/plus/plus_screen.dart:18-22,57-72
- Wrapper de analytics con consentimiento y lista de claves prohibidas (sin PII ni coordenadas): lib/core/analytics/app_analytics.dart:8-44
- Token de color 'plus' reservado solo para Plus (diferenciación visual sin contaminar la marca): lib/core/design_system/tokens/pf_palette.dart:21-22,44
- ADRs honestos sobre no integrar el SDK de tiendas sin cuentas autorizadas (respeta la regla 6 de v1): docs/adr/0002-no-store-billing-sdk.md

**Hallazgos**

### MO-01 · P0 · bug
**El loop central Saludo→Aceptar→Chat no cierra en producción: sin conversaciones no hay liquidez ni nada que monetizar**

- **Evidencia:** lib/services/safety_service_live.dart:20 (respondWave definido; grep en lib/ no encuentra llamadores); lib/features/waves/wave_models.dart:39,61 (incomingPending solo en memoria global); functions/src/waves.ts:73-83 (sendWave no notifica al receptor); functions/src/waves.ts:130-136 (chat creado sin lastMessageAt) vs lib/services/chat_service_live.dart:44-46 (watchUserChats ordena por lastMessageAt); firestore.rules:155 (chats create: if false) vs lib/screens/nearby/nearby_screen.dart:219-223 + lib/services/chat_service_live.dart:34 (ruta con wavesEnabled=false crea el chat desde el cliente)
- **Detalle:** En prod, A saluda a B y la Function guarda waves/{id} pending. B no tiene UI para ver saludos recibidos (la bandeja 'Saludos nuevos' de v1 §5.5.6 no existe; incomingPending lee una lista en memoria del dispositivo de A). B tampoco recibe push, y respondWave nunca se invoca. Aunque se aceptara por consola, el chat nace sin lastMessageAt y Firestore excluye de un orderBy los documentos sin ese campo, así que el chat no aparece en la lista de ninguno. Con WAVES_ENABLED=false la regla rechaza la creación del chat desde el cliente. Resultado: 0 conversaciones con respuesta (la North Star de v1 §7.6). La métrica de liquidez nunca sube, Plus nunca se enciende y el producto no retiene.
- **Recomendación:** v2 Fase 1 (bloqueante): pantalla o fila 'Saludos nuevos (n)' que lea waves where to==uid, status==pending (índice ya existe) con Aceptar/Ignorar → respondWave. Push FCM 'Alguien te saludó 👋' y 'Aceptaron tu saludo', sin nombre en la pantalla de bloqueo por defecto. respondWave escribe lastMessageAt=createdAt. Borrar la ruta de chat directo o hacerla demo-only. Test de integración en emulador: A saluda → B lista el saludo → acepta → el chat aparece en watchUserChats de ambos → los dos se escriben. Ese test es el gate de release.

### MO-02 · P1 · false_claim
**La 'lista de espera Plus' no guarda nada: le dice al usuario que quedó inscrito y es falso**

- **Evidencia:** lib/screens/plus/plus_screen.dart:45-55 (onPressed solo muestra SnackBar 'Quedaste en la lista de espera'); grep 'waitlist' sin resultados en lib/, functions/ y firestore.rules; afirmado como hecho en docs/adr/0002-no-store-billing-sdk.md:9 ('anota una lista de espera'), README.md:16 ('Plus en espera ✅') y docs/PLAN.md:15
- **Detalle:** v1 §7.1 Fase L usa la lista de espera para captar intención de compra por zona sin vender nada. Hoy no queda registro: no hay señal de demanda, no se puede avisar a nadie cuando Plus se encienda ni ofrecer precio fundador. Decirle a alguien que quedó en una lista en la que no está es engañoso (información veraz, Ley 19.496) y erosiona la confianza que el producto promete.
- **Recomendación:** Callable joinWaitlist que escribe waitlist/{uid} {zone (comuna gruesa calculada en servidor), source, referralCode, consentMarketing, createdAt}. Write-once, sin lectura desde el cliente salvo la propia. Contador agregado por zona (sharded o con función programada). Copy honesto con el estado real ('Te avisamos cuando Plus llegue a Ñuñoa'). Test de reglas y test de widget que verifiquen la escritura. Corregir README, ADR 0002 y PLAN.

### MO-03 · P1 · gap
**Sin medición ni palancas remotas: el umbral de liquidez y el encendido por comuna son imposibles**

- **Evidencia:** pubspec.yaml (sin firebase_analytics, firebase_remote_config, firebase_messaging ni purchases_flutter); lib/core/analytics/app_analytics.dart (MemoryAnalytics solo se usa en test/v2_policy_test.dart:114); grep de AnalyticsEvent( sin usos en lib/; lib/core/config/app_config.dart:58-62 (plusEnabled = bool.fromEnvironment, de compilación)
- **Detalle:** v1 §7.1 pide encender Plus 'por comuna o cohorte cuando ≥60% de sesiones vean ≥5 activos a ≤3 km'. No se emite ningún evento del embudo de §7.6 y no hay agregado de liquidez por zona. El flag requiere un build nuevo y pasar la revisión de tiendas, y no puede segmentarse por comuna. Tampoco hay A/B de paywall, precio ni cupo. Sin datos, cada decisión de monetización es una apuesta y no hay guardrails para detectar si el paywall daña la liquidez.
- **Recomendación:** firebase_analytics con consentimiento y la taxonomía de §7.6, más eventos de liquidez (nearby_viewed{count_bucket,radius,zone}). Función programada computeLiquidity que escribe metrics/liquidity/{zone}/{yyyy-mm-dd} con %sesiones≥5 activos≤3km, tasa de aceptación de saludos y tiempo a la primera respuesta. Remote Config con plus_enabled, free_wave_limit, paywall_variant y boost_enabled, condicionados por la user property launch_zone (comuna gruesa, bajo consentimiento). Los defaults de RC reemplazan a los dart-define. Test: con plus_enabled=false no se renderiza ningún precio ni CTA de compra.

### MO-04 · P1 · bug
**El webhook de RevenueCat calcula mal el entitlement: un boost le quita Plus a un suscriptor, acepta sandbox y no ordena eventos**

- **Evidencia:** functions/src/pure/revenuecat.ts:20-26 (cualquier evento cuyo producto no contenga 'plus' devuelve plan 'free'); functions/src/revenuecatWebhook.ts:45-50 (set merge de plan y expiresAt sin comparar event_timestamp_ms); functions/src/pure/revenuecat.ts:37-43 (acepta '$RCAnonymousID:…'); functions/src/pure/waveQuota.ts:34-40 (isPlusActive exige expiresAt != null); functions/src/revenuecatWebhook.ts:14 (process.env sin defineSecret)
- **Detalle:** Escenarios concretos. (a) Un suscriptor Plus compra 'boost_30m' (NON_RENEWING_PURCHASE): planFromRevenueCat devuelve free y el webhook pisa entitlements con plan free y expiresAt null, así que pierde Plus pagado, reclama y pide reembolso. (b) Un RENEWAL que llega después de un EXPIRATION posterior, o al revés, deja un estado incorrecto. (c) Según la documentación de RevenueCat (verificar), los eventos traen environment=SANDBOX/PRODUCTION: compras de TestFlight o tester darían Plus en prod. (d) Los eventos TRANSFER no traen app_user_id (usan transferred_from/to) → 400 y reintentos infinitos. (e) Sin Purchases.logIn(uid) se crean entitlements huérfanos con IDs anónimos. (f) Entitlements promocionales o lifetime (referidos, soporte) sin expiración se leen como no-Plus. (g) Las compras de consumibles no se registran en ningún ledger. El webhook todavía no se despliega, pero index.ts lo exporta y el primer deploy lo publicaría así.
- **Recomendación:** Rehacer el webhook. En cada evento, leer el estado autoritativo con la API REST de RevenueCat (GET subscriber/customer) y proyectarlo a entitlements/{uid} {plus:{active, expiresAt|null=lifetime, productId, store, periodType(trial/intro/normal), willRenew, billingIssue, source}}. Descartar environment!=PRODUCTION en el proyecto prod. Manejar TRANSFER, BILLING_ISSUE, PRODUCT_CHANGE, UNCANCELLATION y NON_RENEWING_PURCHASE; esta última solo acredita en ledger/{transactionId}, nunca toca plan. Usar defineSecret para el secreto y logIn(firebaseUid) antes de cualquier compra. Tests de tabla por tipo de evento, que incluyan: 'boost no revoca Plus', 'evento viejo no pisa uno nuevo', 'sandbox ignorado en prod' y 'TRANSFER mueve el acceso'.

### MO-05 · P1 · false_claim
**El beneficio Plus 'radio hasta 10 km' no se puede entregar y el gratis de 5 km tampoco está garantizado**

- **Evidencia:** functions/src/pure/geohash.ts:11 (QUERY_PRECISION=5) y :139-141 (solo la celda y sus 8 vecinas); functions/src/getNearby.ts:13,54-61 (PER_PREFIX_LIMIT=150 sin orden); lib/core/constants/santiago_bounds.dart:22 (slider hasta 10.000 m); functions/src/pure/distance.ts:31-37; lib/screens/plus/plus_screen.dart:33
- **Detalle:** Una celda geohash p5 mide 0,0439°×0,0439°. En Santiago (lat −33,45) eso es ~4,1 km E-O × ~4,9 km N-S. El bloque 3×3 garantiza cobertura de solo una celda alrededor del usuario: ~4,1 km E-O en el peor caso y como mucho ~8 km. Vender '10 km' que el backend no entrega es publicidad engañosa (Ley 19.496 art. 28) y genera reembolsos. Además, el límite de 150 documentos por prefijo sin orden trunca al azar justo en las celdas densas, que son las más valiosas: no devuelve a los más cercanos ni a los más activos.
- **Recomendación:** Guardar cell5 (y cell6) en locations y consultar con where('cell5','in', celdas que cubren el círculo del radio pedido; hasta 30 valores) + orderBy('lastActiveAt','desc') + limit(K), con su índice compuesto. Test de propiedad: 1.000 puntos aleatorios en el Gran Santiago, y todo candidato a distancia ≤ radio (5 y 10 km) aparece en la respuesta. No mostrar '10 km' en el paywall hasta que ese test esté verde.

### MO-06 · P1 · scalability
**Con densidad, getNearby cuesta más por usuario gratis que el ingreso por usuario**

- **Evidencia:** functions/src/getNearby.ts:54-61 (9 consultas × hasta 150 docs) y :80-87 (3 getAll por candidato: profiles, users, blocks; más 2 consultas de waves con limit 500 cada una); functions/src/index.ts:4 (maxInstances 20); sin cache ni rate limit en getNearby
- **Detalle:** Lecturas por llamada ≈ N (locations) + 3N + hasta 1.000 (waves) + bloqueos. Con N=1.350 (el tope) son ~6.400 lecturas. Supuestos: DAU/MAU 30%, 2 sesiones/día y 3 llamadas/sesión → 54 llamadas/MAU/mes → ~346k lecturas/MAU/mes. A ~US$0,06 por 100k (supuesto; el precio Standard en São Paulo no se pudo verificar) son ~US$0,21/MAU/mes (~197 CLP). El ARPMAU estimado es ~98 CLP. En etapa temprana (N=200) son ~855 lecturas/llamada, ~26 CLP/MAU/mes. Es decir, el margen se vuelve negativo justo cuando hay liquidez para cobrar. Además, maxInstances=20 global puede estrangular picos de lanzamiento por campus o en un ritual horario.
- **Recomendación:** Desnormalizar en locations un 'card' mínimo (isVisible, adult flag, lastActiveAt, cell5) para 1 lectura por candidato. Leer los bloqueos propios como 1 doc (blockedUids) y los pares saludados como 1 doc (wavedUids) en vez de 2×500. Cache por usuario de 60-120 s, rate limit de 30 llamadas/hora y página de 50. Meta verificable: ≤300 lecturas/llamada medidas en un test de emulador con contador, e infra ≤US$0,02/MAU/mes. Alertas de presupuesto GCP, maxInstances por función y prueba de carga de 500 rps antes de cada lanzamiento de zona.

### MO-07 · P1 · monetization
**El 'Modo incógnito' de Plus ya es gratis de hecho y los mirones drenan liquidez**

- **Evidencia:** functions/src/getNearby.ts:39-51 (solo lee locations y entitlements del llamador; nunca su isVisible); functions/src/pure/nearbyFilter.ts:41 (la visibilidad se aplica solo a los candidatos); lib/providers/user_provider.dart:83 (setVisibility gratis); docs/product/plus.md:9,16
- **Detalle:** Cualquier usuario gratis apaga 'Visible en Cerca' y sigue viendo a todos. El beneficio Plus 'incógnito' (ver sin aparecer) no se diferencia. Peor aún, rompe la reciprocidad de un marketplace de dos lados: quien mira sin ser visto consume oferta sin aportarla, y en la fase de liquidez eso baja directamente el % de sesiones con ≥5 personas.
- **Recomendación:** ADR con decisión humana. Recomendación: reciprocidad por defecto ('para ver Cerca tienes que ser visible'), validada en getNearby. Incógnito (ver sin aparecer salvo a quien saludas) como Plus. Las herramientas de seguridad siguen gratis: pausar cuenta, ocultarme de una persona, bloquear. Tests: un invisible gratis recibe failed-precondition y un Plus invisible recibe resultados.

### MO-08 · P1 · bug
**El cliente no conoce el entitlement y el paywall no tiene disparadores contextuales**

- **Evidencia:** lib/widgets/public_profile_sheet.dart:111 (plus: false fijo) y catch solo de WaveException; lib/features/waves/wave_actions.dart:23-41 (cupo con memoryWaves en memoria, día local del dispositivo); functions/src/waves.ts:66-70 (resource-exhausted); lib/core/constants/santiago_bounds.dart:22 vs functions/src/pure/distance.ts:34-37 (slider 10 km, servidor recorta a 5 km sin avisar); lib/screens/settings/settings_screen.dart:128-137 (único acceso a /plus)
- **Detalle:** En prod, el saludo 21 falla en servidor con FirebaseFunctionsException. La UI no lo convierte a WaveException, así que queda una excepción no manejada en vez del paywall 'Llegaste a 20 saludos hoy'. El cupo del cliente se reinicia al reabrir la app y usa el día del dispositivo, no el de Santiago. El usuario gratis mueve el slider a 10 km y ve '10 km' mientras recibe 5 km: es una UI engañosa y se pierde el disparador de compra más natural. El único camino al paywall es Ajustes, con conversión típicamente muy baja (supuesto).
- **Recomendación:** EntitlementRepository (stream de entitlements/{uid}, Demo/Firebase) consumido por la UI. Mapear errores de los callables a errores de dominio tipados. Disparadores de v1 §7.4: cupo agotado, radio >5 km (candado en el slider), toggle de incógnito, nota en el saludo y upsell suave tras la 3.ª conversación con respuesta, nunca dentro de un chat. Emitir paywall_viewed{trigger}. Tests de widget por disparador.

### MO-09 · P1 · monetization
**La arquitectura de precios es una sola tarjeta sin trials, ofertas de entrada, pase sin renovación ni escalera de valor**

- **Evidencia:** docs/product/plus.md:11-26; docs/adr/0007-plus-prices-proposed.md; comparables App Store CL verificados el 2026-10-07: Bumble For Friends Premium 1 mes $12.900–$13.900, 3 meses $22.900–$24.900, 6 meses $39.900; Bumble Premium 7 días $6.900; Tinder Gold $5.200–$17.900
- **Detalle:** $4.990 al mes es ~37% del BFF Premium mensual ($13.900). Sirve como precio de entrada para una marca nueva, pero falta todo lo demás. (1) Sin intro ni trial no hay forma barata de probar el valor. (2) Para quien solo quiere el finde, un plan semanal con auto-renovación da reclamos; hace falta un pase sin renovación. (3) Plus mezcla utilidades con features débiles para amistad. Un cupo de 20 saludos al día probablemente casi nunca se alcanza (supuesto: medir la distribución), así que el disparador principal rara vez se activa. (4) 'Lista de visitas' choca con la promesa de privacidad y con la Ley 21.719 (perfilamiento). (5) Falta precio fundador para quienes esperaron.
- **Recomendación:** Estructura propuesta (los precios los aprueba el humano; A/B con RevenueCat Offerings). Plus mensual $4.990 · trimestral $11.990 · anual $29.990, con intro 'primer mes $1.990' o trial de 7 días solo en el anual. 'Pase Finde' sin renovación $1.990 (vie-dom). Precio fundador para la lista de espera: anual $19.990 el primer año vía offer codes/intro. Plus+ (~$8.990) solo cuando la conversión a Plus sea ≥3%: Explorar otra comuna, saludo prioritario arriba en la bandeja y 4 destacados al mes. Sin 'ver quién te visitó' (o solo recíproco y opt-in). Ver quién te saludó, gratis (hace falta para aceptar). Experimento de cupo 10/20/30 saludos con guardrail en la tasa de aceptación y en reportes por 1.000. Un mismo precio para todos: nada por edad o género.

### MO-10 · P1 · gap
**Consumibles (Destacar) sin implementar: sin ledger, sin ranking, sin reglas de equidad y con pack más caro que el mercado**

- **Evidencia:** docs/product/plus.md:25 ('Destacar $1.990'); grep 'boost' sin lógica en functions/src; functions/src/pure/nearbyFilter.ts:52 (orden solo por distancia); comparable: Bumble For Friends 5 Spotlights $5.500 (App Store CL)
- **Detalle:** No hay producto, créditos ni efecto en el ranking. El pack de v1 (5 × $6.990 = $1.398 c/u) sale ~27% más caro por unidad que el de BFF ($1.100). En una app geolocal, un destacado en una zona con pocos usuarios no entrega valor (pocas vistas): habrá reembolsos y desconfianza. Sin límites, varios destacados en la misma celda degradan la experiencia de los usuarios gratis.
- **Recomendación:** wallets/{uid} + ledger/{txId}, idempotente por transaction_id, escrito solo por el webhook. Callable activateBoost: 30 min, etiqueta 'Destacado', máximo 1 destacado cada 8 tarjetas y máximo N simultáneos por celda. Garantía de vistas: si en 30 min lo vieron menos de K personas, el crédito se devuelve automáticamente. Precios a probar: 1×$1.990 y 5×$5.990. Tests: el doble webhook no duplica créditos y la garantía devuelve el crédito.

### MO-11 · P1 · gap
**Faltan los loops de crecimiento, y con este ARPU la UA pagada no es viable**

- **Evidencia:** pubspec.yaml (sin app_links, share_plus ni deep links); lib/router/app_router.dart (sin ruta de invitación /i/:code ni de perfil compartible); grep referral/invite sin resultados; docs/ sin playbook de lanzamiento
- **Detalle:** Con ~2.795 CLP netos por pagador-mes, churn del 12% y 2% de instalaciones que alguna vez pagan (supuestos), el LTV por instalación es ~470 CLP (~US$0,49). Para un LTV/CAC ≥3 el CPI tendría que ser menor a ~US$0,16, muy por debajo del CPI típico de redes sociales (supuesto). El crecimiento tiene que ser orgánico y denso por zona, y hoy no hay ningún mecanismo para eso.
- **Recomendación:** (1) Referidos: código y link por WhatsApp (canal dominante en Chile) con Universal Links/App Links y una página web /i/<code> con OG. Atribución en servidor. Recompensa para ambos (1 Destacar o 7 días de Plus promocional) solo cuando el invitado completa su perfil y recibe un saludo aceptado. Antifraude con App Check, dispositivo y tope mensual. Validar contra Apple 3.1.1/3.2.2 y la política de Play. (2) Compartir 'mi tarjeta Picaflor' opt-in, sin ubicación. (3) 'Desbloquea tu comuna o U' con barra de progreso real de la lista de espera. (4) docs/growth/launch.md con secuencia de zonas (p. ej. campus San Joaquín/Beauchef/JGM + Providencia-Ñuñoa → Santiago Centro → Las Condes), 20-30 embajadores por campus, Panorama semanal, umbral de apertura (≥300 en lista de espera por zona) y criterios de salida.

### MO-12 · P1 · gap
**Sin retención: el cliente no registra tokens push, no hay notificación de saludo y no hay rituales**

- **Evidencia:** pubspec.yaml (sin firebase_messaging); lib/models/user_model.dart:22 (fcmToken solo es un campo, ningún código lo escribe); functions/src/waves.ts:73-83 (sin push); functions/src/onMessageCreated.ts:52-71 (envía a tokens que nunca existirán)
- **Detalle:** En una app con saludo y aceptación, el saludo caduca si el receptor no abre la app a tiempo. Sin push de 'te saludaron' la tasa de aceptación y el tiempo a la primera respuesta se desploman. Eso hunde la North Star y la liquidez, y de rebote la conversión. onMessageCreated existe pero no tiene a quién enviar.
- **Recomendación:** firebase_messaging con permiso contextual (después del primer saludo enviado). Tokens en users/{uid}.fcmTokens (privado), con limpieza de tokens inválidos. Push transaccionales: saludo recibido, saludo aceptado, mensaje. Horario silencioso 22:00-09:00 en America/Santiago y tope de 3 push no transaccionales al día. Digest semanal opt-in ('12 personas nuevas cerca'). Ritual 'Hora Picaflor' por zona (p. ej. 19-21 h) para concentrar la actividad. Métrica: % de saludos respondidos en menos de 24 h.

### MO-13 · P1 · compliance
**Al encender Plus, el paywall, el borrado de cuenta y los textos no cumplen Apple 3.1.2 ni Ley 19.496/21.398**

- **Evidencia:** lib/screens/plus/plus_screen.dart:57-72 (Restaurar es un SnackBar, sin links a Términos ni Privacidad, sin precio por período del trimestral ni términos de prueba); functions/src/deleteAccount.ts:52 (borra entitlements sin avisar que la suscripción de la tienda sigue cobrando); web/eliminar-cuenta.html y lib/screens/settings/settings_screen.dart (sin aviso de suscripción)
- **Detalle:** Apple 3.1.2 exige en el paywall el título, la duración, el precio total y por período, los términos de la prueba y los links a Términos y Privacidad. La Ley 19.496 (art. 3 bis b, reformado por la 21.398) da 10 días de retracto en contratos electrónicos; en servicios solo se puede excluir si se informa de forma clara e inequívoca antes del pago. El art. 30 exige precio total con impuestos. Si alguien borra su cuenta mientras está suscrito, Apple y Google siguen cobrando y aparecen reclamos en SERNAC. Borrar todo rastro de las transacciones puede chocar con la retención tributaria (validar con un contador).
- **Recomendación:** Checklist A6 'Plus-ready' como gate: paywall con todos los campos de 3.1.2, aviso de exclusión de retracto o política de reembolso, links que abren el navegador, Restaurar real (Purchases.restorePurchases) y 'Gestionar suscripción' con deep link a App Store/Play. Borrar cuenta: si hay Plus activo, mostrar 'Tu suscripción sigue activa en la tienda, cancélala aquí' antes de confirmar, borrar el cliente en RevenueCat y conservar el ledger de transacciones seudonimizado. Copy validado por abogado (Ley 19.496/21.398/21.719).

### MO-14 · P1 · design
**Precios hardcodeados en la UI y la ADR 0007 subestima lo que cuesta cambiarlos**

- **Evidencia:** lib/screens/plus/plus_screen.dart:13-14 (ClpFormat.pesos(4990) / (29990)); docs/adr/0007-plus-prices-proposed.md:19 ('Cambiar el precio es un copy de una pantalla')
- **Detalle:** Con tiendas activas, el precio que se muestra tiene que salir del producto de la tienda (priceString localizado). Si no coincide con lo que cobra la tienda, hay rechazo de revisión e información engañosa. Subir el precio de una suscripción activa está regulado por cada tienda (consentimiento o aviso al suscriptor), así que no es 'un copy'. Si el storefront base de Apple es EE.UU., los precios en CLP se reajustan solos por tipo de cambio; conviene fijar Chile como base para tener precios estables (verificar en App Store Connect).
- **Recomendación:** El precio solo se lee de RevenueCat Offerings/StoreProduct. Gate de CI que prohíbe literales de precio en lib/ fuera de demo. ADR de pricing con IDs de producto (plus_monthly, plus_quarterly, plus_annual, pass_weekend, boost_1, boost_5), price points CLP elegidos en App Store CL (existen puntos .990 y .490: Tinder $14.990/$7.490) y en Play, Chile como storefront base y política de cambios de precio.

### MO-15 · P1 · process
**No hay modelo de unit economics: comisiones, IVA, LTV, CAC e infra no están en ningún documento**

- **Evidencia:** docs/product/plus.md (solo precios); docs/adr/0007-plus-prices-proposed.md; sin docs/product/unit-economics.md
- **Detalle:** Cálculo de referencia: $4.990 → sin IVA (19%) $4.193 → menos 15% de tienda (Apple Small Business Program / Google suscripciones) $3.564 → menos 1% de RevenueCat (sobre US$2,5k MTR) ≈ $3.514 neto (70%). Con 30% de tienda: $2.885 (58%). Anual $29.990 ≈ $1.760 netos por mes. Con un mix 50/15/35 quedan ~$2.795 netos por pagador-mes. Sin este modelo, v2 no puede decidir el cupo, el precio ni cuánto pagar por adquisición, y no ve que la infra de los usuarios gratis la pagan los pagadores (ver MO-06).
- **Recomendación:** docs/product/unit-economics.md con una planilla o script recalculable: supuestos marcados, escenarios (1,5% / 3% / 5% de conversión), costo de infra por MAU medido, LTV por cohorte, techo de CPI, payback y punto de equilibrio. Ejemplo: con 3M CLP/mes de costos fijos (supuesto) se necesitan ~48k MAU con la infra actual o ~34k con la infra optimizada. Incluir go/no-go por zona: liquidez ≥ umbral, infra ≤ US$0,02/MAU y reportes por 1.000 < X.

### MO-16 · P2 · monetization
**Faltan ingresos que no pasan por la tienda: Panoramas (eventos presenciales) y Lugares (B2B)**

- **Evidencia:** Instrucciones 06.10.26.md:298 (Fase X solo enunciada); sin código, docs ni flags en la rama de Grok
- **Detalle:** Apple 3.1.3(e) obliga a usar medios distintos a IAP para servicios que se consumen fuera de la app. Un cupo en un 'Panorama Picaflor' (6-8 personas en un café o bar asociado) se cobra con Webpay, Mercado Pago o Flow, sin el 15-30% de la tienda (comisión del procesador ~3%, supuesto). Hay precedentes de pagar por conocer gente en persona: Timeleft opera en LatAm (Quito, CDMX); su presencia en Santiago no está verificada. Lugares patrocinados: 100 locales × $39.990 + IVA ≈ $4,0M netos/mes (supuesto), el equivalente a ~1.430 suscriptores. Además los eventos alimentan la liquidez y la confianza.
- **Recomendación:** Detrás de flags en Fase X: modelo events/{id} (zona, local, cupos, precio), checkout web con boleta electrónica SII, check-in con el staff del local, reglas de seguridad (lugar público), descuento para Plus. Lugares B2B con contrato, factura y etiqueta 'Patrocinado' visible. A los comercios solo se les entregan métricas agregadas por comuna, nunca datos personales.

### MO-17 · P2 · design
**Sin decisión escrita sobre anuncios ni verificación: las dos afectan la confianza y el ARPU**

- **Evidencia:** docs/product/plus.md y docs/adr/ (sin ADR de ads ni de verificación); Instrucciones 06.10.26.md:302 ('La seguridad nunca se cobra')
- **Detalle:** Los anuncios programáticos (AdMob) en Chile rinden poco por MAU (supuesto). Además exigen consentimiento (Ley 21.719, ATT en iOS) y degradan la estética 'fintech sobria'. La verificación con selfie y liveness cuesta por chequeo (~US$0,3-1, supuesto) y sube la confianza y la conversión. Cobrarla o filtrar 'solo verificados' tras el paywall contradice 'la seguridad no se cobra'.
- **Recomendación:** ADR: sin ads programáticos, solo 'Lugares' first-party y etiquetados. Verificación gratis, con abstracción de proveedor, cupo según riesgo y badge. El filtro 'solo verificados' también gratis. El costo se modela como costo de Trust & Safety en el unit economics.

### MO-18 · P2 · monetization
**El checkout web no se puede usar para ahorrar comisión en apps chilenas**

- **Evidencia:** Instrucciones 06.10.26.md:329 (§7.5 web: 'Disponible en la app'); Google Play User Choice Billing no incluye a Chile (support.google.com/googleplay/android-developer/answer/13821247)
- **Detalle:** En Chile, Play exige Play Billing para lo digital dentro de la app de Android y Apple prohíbe dirigir a pagos externos fuera de las jurisdicciones con excepciones. Una compra web en la PWA (Stripe o Mercado Pago vía RevenueCat Web Billing) sí puede habilitar Plus en todas las plataformas (Apple 3.1.3(b)), siempre que la app no la mencione ni enlace.
- **Recomendación:** Fase X opcional: RevenueCat Web Billing en la PWA con el mismo entitlement 'plus', sin links desde las apps nativas. Validar las políticas de Apple y Play antes de activar. Medir la participación web antes de invertir.

### MO-19 · P2 · ops
**La capacidad y los secretos no están listos para picos de lanzamiento**

- **Evidencia:** functions/src/index.ts:4 (setGlobalOptions maxInstances 20 para todas las funciones); functions/src/revenuecatWebhook.ts:14 (process.env sin defineSecret/secrets); hechos del orquestador: npm run build falla (src/pure.test.ts:23 TS2441) y engines node 20 (EOL 2026-04-30)
- **Detalle:** Un lanzamiento por campus o un ritual horario concentra el tráfico en minutos. Un tope global de 20 instancias, compartido con getNearby que es pesado, puede devolver 429 justo en el momento de mayor intención. El secreto del webhook no pasa por Secret Manager. Y mientras el build falle, ni el webhook ni sendWave se pueden desplegar.
- **Recomendación:** maxInstances y concurrencia por función. Prueba de carga (k6 o Artillery contra el emulador o staging) de 500 rps en getNearby con p95 < 800 ms. defineSecret('REVENUECAT_WEBHOOK_SECRET'). Node 22, y build y deploy en CI como gate.

**Requisitos que esta lente exige para la v2**

- GATE DE LIQUIDEZ (bloqueante): implementar la bandeja 'Saludos nuevos' con Aceptar/Ignorar → respondWave, la push de saludo recibido y aceptado, y que respondWave escriba lastMessageAt. Test de integración en emulador: A saluda → B ve el saludo → acepta → el chat aparece en watchUserChats de ambos → los dos se escriben
- Instrumentar con firebase_analytics (con consentimiento) toda la taxonomía de v1 §7.6, más nearby_viewed{count_bucket,radius,zone} y paywall_viewed{trigger}. Test con fake analytics que verifique la emisión de cada evento y gate que rechace claves PII
- Función programada computeLiquidity que escriba metrics/liquidity/{zone}/{fecha} (%sesiones con ≥5 activos ≤3 km, tasa de aceptación, tiempo a la primera respuesta). La definición de 'activo' queda fijada en código y documentada
- Pasar plus_enabled, free_wave_limit, paywall_variant y boost_enabled a Remote Config con condición por launch_zone (comuna gruesa calculada en servidor). Eliminar el flag de compilación. Test: con plus_enabled=false no se renderiza ningún precio ni CTA de compra
- Lista de espera real: callable joinWaitlist → waitlist/{uid} write-once con zona, origen y código de referido, y contador por zona. Corregir README, ADR 0002 y PLAN, que hoy dicen que ya existe
- MonetizationRepository y EntitlementRepository (Demo/RevenueCat) con purchases_flutter importado de forma diferida o condicional para no romper el build web, Purchases.logIn(firebaseUid) y precios mostrados solo desde StoreProduct.priceString. Gate de CI que prohíba literales de precio en lib/ fuera de demo
- Webhook v2: leer el estado autoritativo de la API de RevenueCat en cada evento, descartar environment!=PRODUCTION en prod, manejar TRANSFER, BILLING_ISSUE, PRODUCT_CHANGE y NON_RENEWING_PURCHASE (este último solo al ledger) y usar defineSecret. Tests de tabla: 'boost no revoca Plus', 'evento viejo no pisa uno nuevo', 'sandbox ignorado', 'lifetime sin expiresAt = activo'
- Ledger de créditos idempotente por transaction_id y callable activateBoost con límites de equidad (≤1 destacado cada 8 tarjetas, N por celda) y garantía de vistas con devolución automática del crédito. Con tests
- getNearby fiel al radio: consulta por celdas que cubren el círculo pedido (cell5 'in' + orderBy lastActiveAt). Test de propiedad con 1.000 puntos aleatorios en el Gran Santiago: 100% de los candidatos ≤ radio devueltos para 5 y 10 km
- getNearby barato: ≤300 lecturas por llamada medidas en emulador, cache de 60-120 s, rate limit, 'card' desnormalizado en locations, alertas de presupuesto GCP y costo de infra por MAU ≤ US$0,02 publicado en el dashboard
- ADR de reciprocidad de visibilidad con decisión humana. Recomendado: el usuario invisible no ve Cerca salvo con Plus incógnito. La seguridad (pausar, ocultarme de alguien, bloquear) sigue gratis
- Paywall contextual: disparadores por cupo agotado, radio >5 km (candado en el slider para gratis), incógnito y nota. Mapeo de errores de los callables a errores de dominio. Test de widget por disparador. Nunca dentro de un chat
- ADR de pricing con IDs de producto, price points CLP de App Store y Play, Chile como storefront base, intro offer y trial a probar, 'Pase Finde' sin renovación, precio fundador para la lista de espera y prohibición de precios por edad o género. Los precios finales los aprueba el humano
- Checklist 'Plus-ready' (gate A6): todos los campos de Apple 3.1.2, exclusión del retracto o política de reembolso según Ley 19.496 art. 3 bis b, precio total con IVA (art. 30), Restaurar real, deep link para gestionar la suscripción, aviso de 'tu suscripción sigue activa' al borrar la cuenta, borrado del cliente en RevenueCat y ledger seudonimizado retenido (validar con contador y abogado)
- Push y retención: firebase_messaging con permiso contextual, tokens privados y limpieza de inválidos, horario silencioso 22-09 America/Santiago, tope de 3 push no transaccionales al día, digest semanal opt-in y el ritual 'Hora Picaflor' detrás de un flag
- Referidos con Universal Links/App Links y página web /i/<code> con OG, compartir por WhatsApp, atribución en servidor, recompensa tras la activación del invitado (perfil completo + saludo aceptado), antifraude con App Check y tope mensual. Validar contra Apple 3.1.1/3.2.2 y Play
- Entregar docs/growth/launch.md: secuencia de zonas (campus + comunas densas), embajadores, Panorama semanal, umbral de apertura por zona (lista de espera ≥ N), criterios go/no-go para encender Plus por zona y KPIs por zona
- Entregar docs/product/unit-economics.md recalculable (script o planilla) con IVA 19%, comisión 15%/30%, 1% de RevenueCat, mix de planes, churn, LTV, techo de CPI, infra por MAU medida y punto de equilibrio. Supuestos marcados
- Experimentación con guardrails: RevenueCat Offerings/Experiments para precio y paywall y Firebase A/B para cupos. Guardrails: reportes por 1.000, tasa de bloqueo, aceptación de saludos, D7 y tasa de reembolso. Holdout del 10% sin paywall y tamaño muestral mínimo documentado
- Dashboard de negocio: export a BigQuery de Analytics y RevenueCat + Looker Studio con North Star, liquidez por zona, embudo, D1/D7/D30, paywall→compra, trial→pago, MRR, ARPPU, churn, reembolsos, k-factor de referidos y costo de infra por MAU
- ADRs de anuncios (sin programáticos) y verificación (gratis, con abstracción de proveedor). Panoramas y Lugares solo en Fase X, detrás de flags, con cobro fuera de IAP solo para servicios consumidos fuera de la app (Apple 3.1.3(e)) y etiqueta 'Patrocinado'

**Cifras clave**

| Métrica | Valor | Base |
|---------|-------|------|
| Tinder (App Store Chile) compras dentro de la app | Tinder Gold $5.200–$17.900 (6 price points, duración no rotulada); 1 Boost $6.500; 600 monedas $6.500 | Verificado: apps.apple.com/cl/app/id547702041 (consultado 2026-10-07) |
| Bumble (App Store Chile) | Premium 7 días $6.900; 1 mes $12.900; Premium Plus 7 días $9.900; Boost $2.900; 2 SuperSwipes $2.200; 1 día votos ilimitados $190 | Verificado: apps.apple.com/cl/app/id930441707 (consultado 2026-10-07) |
| Bumble For Friends (comparable directo de amistad, App Store Chile) | Premium 1 mes $12.900–$13.900; 3 meses $22.900–$24.900; 6 meses $39.900; Spotlight 1×$2.200, 5×$5.500 | Verificado: apps.apple.com/cl/app/id6444040977 (consultado 2026-10-07) |
| Plus mensual propuesto vs BFF Premium mensual | $4.990 ≈ 36-39% de $12.900-$13.900 | Cálculo sobre datos verificados |
| Comisión de tiendas | Apple Small Business Program 15% (<US$1M/año); Google Play suscripciones 15% desde el día 1; 30% sobre el umbral en Apple | Fuentes: revenuecat.com/blog/engineering/small-business-program, splitmetrics.com/blog/google-play-apple-app-store-fees, appleinsider.com (2021-10-21) |
| RevenueCat | Gratis hasta US$2.500 MTR; después 1% del MTR | Fuente: revenuecat.com/pricing |
| IVA a servicios digitales en Chile | 19% (Ley 21.210), lo retienen y pagan las plataformas extranjeras registradas en el SII | Fuente: sii.cl (FAQ IVA servicios digitales), blog.nubox.com |
| Google Play User Choice Billing en Chile | No elegible: en la app Android se usa Play Billing | Fuente: support.google.com/googleplay/android-developer/answer/13821247 |
| Retracto en contratos electrónicos (Ley 19.496 reformada por la 21.398) | 10 días; en servicios se puede excluir si se informa de forma clara e inequívoca antes del pago | Fuente: derecho.udd.cl (2022-01), carey.cl; validar con abogado |
| Neto por Plus mensual $4.990 | ≈ $3.514 CLP (70,4%) con 15% de tienda; ≈ $2.885 (57,8%) con 30% | Cálculo: ÷1,19 IVA, −comisión, −1% RevenueCat sobre el bruto |
| Neto por pagador-mes (mix 50% mensual / 15% trimestral / 35% anual) | ≈ $2.795 CLP (~US$2,9) | Supuesto de mix; tipo de cambio supuesto ~950 CLP/USD |
| LTV neto por pagador | ≈ $23.300 CLP (churn mensual del 12% → 8,3 meses) | Supuesto |
| ARPMAU (suscripciones al 3% de conversión + boosts al 1%) | ≈ 98 CLP/MAU/mes (~US$0,10) | Supuesto |
| LTV por instalación y techo de CPI | ≈ 466 CLP (~US$0,49) con 2% de instalaciones que pagan; CPI máximo ~US$0,16 para LTV/CAC ≥3 | Supuesto; implica crecimiento orgánico |
| Lecturas Firestore por getNearby con densidad máxima | ≈ 6.400 por llamada (N=1.350 candidatos × 4 + hasta 1.000 de waves); ≈ 855 con N=200 | Derivado del código: functions/src/getNearby.ts:13,54-87 |
| Costo de getNearby por MAU | ≈ US$0,21/MAU/mes con densidad máxima vs ≈ US$0,03 temprano (54 llamadas/MAU/mes) | Supuesto de uso y de precio ~US$0,06/100k lecturas (el precio Standard en São Paulo no se pudo verificar; cuota gratis 50k lecturas/día verificada en firebase.google.com/docs/firestore/pricing) |
| Cobertura garantizada de la consulta geohash p5 3×3 en Santiago | ≈ 4,1 km E-O × 4,9 km N-S (Plus '10 km' no entregable) | Cálculo: 0,043945° × 111,32 km × cos(33,45°); functions/src/pure/geohash.ts:11 |
| Punto de equilibrio ilustrativo | ≈ 48k MAU con la infra actual (temprana) o ≈ 34k MAU con la infra optimizada, para 3M CLP/mes de costos fijos | Supuesto de costos fijos y conversión del 3% |
| Lugares B2B ilustrativo | 100 locales × $39.990 + IVA ≈ $4,0M CLP netos/mes ≈ 1.430 suscriptores equivalentes | Supuesto |

## T1 · Producto y diseño Tier-1

**Veredicto de la lente**

Veredicto: Grok cambió la paleta, no el producto. La distancia a tier-1 sigue siendo grande. Los tokens v2 existen (PfPalette, PfColors como ThemeExtension, PfType con Inter empaquetada de verdad) y el contraste de los pares de tokens está testeado. Pero la adopción es solo de nombre: `context.pf` tiene 0 usos en la UI, `AppColors.*` aparece 376 veces y `isDark ?` 98. De los 22 componentes Pf* exigidos en §5.4 existe 1 (PfMark), y las sombras multicapa siguen. Las pantallas son las de v1 con colores nuevos: Grok cambió 1 línea en profile_screen, 5 en main_shell y 14 en la tarjeta de persona. Al re-asignar el alias `primaryMuted` (#6FBFB6 → #075E55) rompió el contraste en dark mode: el ítem activo del rail, los tags y el botón de la tarjeta quedan en 1,99–2,35:1. La accesibilidad casi no existe: hay 1 Semantics en todo lib/, ningún testWidgets ni golden, y targets de 34–44 px. Hay bloqueadores de producto. El loop central está roto: se puede enviar un Saludo, pero no existe UI para recibirlo o aceptarlo (respondWave no tiene llamadas). No hay fotos de perfil, y en web nunca se muestran. Los íconos de app en Android, iOS y web son el logo de Flutter por defecto. El checkbox de Términos apunta a una página que no existe. Edad y consentimientos solo quedan en el teléfono. El reporte promete revisión en menos de 24 h sin cola de moderación. La lista de espera Plus dice "Quedaste en la lista" pero no guarda nada. Además, el isotipo dibujado a mano no se lee como picaflor (no tiene pico y a 16 px es una mancha), siguen los 3 splashes, y los botones de Google y Apple no son oficiales. Tampoco hay push en el cliente, deep links, compartir perfil, verificación, prompts, l10n, screenshots ni ASO. El PLAN da por "Hechas" las Fases 2 y 4 sin evidencia visual. El v2 debe exigir la migración completa al design system con gates que fallen de verdad, el flujo de saludos de punta a punta, fotos con moderación, identidad de marca y assets de tienda, y una matriz de goldens con a11y como criterio de salida.

**Lo que está bien y se preserva**

- Paleta v2 con los hex del megaprompt en un solo archivo (lib/core/design_system/tokens/pf_palette.dart) y test de contraste WCAG de los pares de tokens (test/v2_policy_test.dart:98, contrast.dart).
- Inter empaquetada de verdad: 4 TTF válidos v4.001 + OFL en assets/fonts y declarados en pubspec.yaml:57-67. Así se elimina la dependencia de Segoe UI (D4).
- Se quitó user-scalable=no (web/index.html:10) y el tope de escala de texto 1.15 (D6, parcial).
- Ajustes: los links legales abren el navegador con url_launcher y la versión sale de package_info_plus (settings_screen.dart:385-408). D8 queda resuelto.
- Modelo de Saludo detrás del flag WAVES_ENABLED. Cerca abre la ficha y ya no un chat en frío (nearby_screen.dart:197-221). Hay Bloquear y Reportar en la ficha, el chat y la lista de chats.
- Eliminar cuenta con doble confirmación y página web /eliminar-cuenta (firebase.json rewrites).
- Copy de privacidad en contexto ('Tu ubicación exacta nunca se comparte', 'Zona aproximada') y docs/voice.md con glosario fijo (Saludo, Cerca, buckets de distancia y actividad).
- Los pines del mapa en producción salen del bucket y no de la coordenada (lib/core/privacy/display_pin.dart), con atribución OSM/CARTO visible.
- Se mantuvo la carga diferida del mapa (nearby_screen.dart:20,170-195) y el IndexedStack Lista/Mapa.
- ADRs cortos que separan bien las decisiones que tiene que tomar una persona (isotipo, precios, mapa de pago, región).

**Hallazgos**

### T1-01 · P0 · gap
**Los íconos de app en Android, iOS y web son el logo de Flutter por defecto**

- **Evidencia:** ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png, android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png, web/icons/Icon-512.png (inspección visual: logo Flutter); git log de esos paths: solo 22f1a4e 2026-07-24 (scaffold)
- **Detalle:** Lo primero que ven el usuario y la tienda es el logo de Flutter, que es una marca de Google. Ninguna app tier-1 llega así a revisión. Hoy la app no tiene identidad visual en el home screen, la PWA ni el favicon.
- **Recomendación:** Generar el set completo desde el isotipo aprobado con flutter_launcher_icons: Android adaptive (fg/bg) + monochrome para themed icons de Android 13; iOS 1024 sin alpha + variantes dark/tinted de iOS 18; web 192/512 + maskable con safe zone del 80%; favicon 16/32. Agregar un test o script de CI que falle si el md5 de algún ícono coincide con los de Flutter por defecto.

### T1-02 · P0 · bug
**Loop central roto: se puede saludar, pero nadie puede ver ni aceptar un saludo**

- **Evidencia:** lib/services/safety_service_live.dart:20 (respondWave sin llamadas); lib/features/waves/wave_models.dart:39 (incomingPending sin consumidores); lib/screens/chat/chat_list_screen.dart:84-123 (sin sección de saludos); lib/core/config/app_config.dart:53 (WAVES_ENABLED=true por defecto)
- **Detalle:** Con el flag encendido, Cerca solo abre la ficha y el saludo (nearby_screen.dart:198-218). El receptor no tiene bandeja, ni push, ni Aceptar o Ignorar, así que en producción nunca se crea un chat nuevo y la North Star (conversaciones con respuesta) queda en 0. En demo los perfiles de ejemplo tampoco aceptan, por lo que el showcase no muestra el loop. Tampoco existe la vista 'Enviados', y el cupo diario vive en memoria (wave_actions.dart:23-26).
- **Recomendación:** Agregar a Chats una sección 'Saludos nuevos (n)' con Aceptar e Ignorar (ignorar en silencio), 'Enviados' con estado pendiente y expiración, badge en el tab, push de 'te saludó' y 'aceptó', y en demo aceptación automática a los 3–8 s. Criterio: test de integración en el emulador donde A saluda, B acepta y el chat queda abierto para ambos, más un e2e en demo.

### T1-03 · P0 · gap
**Sin fotos de perfil (D9), y en web los avatares nunca muestran foto**

- **Evidencia:** lib/screens/profile/profile_screen.dart (Grok cambió 1 línea; sin subida); pubspec.yaml sin image_picker ni cached_network_image; lib/widgets/picaflor_avatar.dart:41-42 `if (AppConfig.demoMode || kIsWeb) return false;`
- **Detalle:** En una app para conocer gente cerca, saludar a un círculo con iniciales baja la confianza y la conversión, y facilita el catfishing. En web/PWA la foto se desactiva aunque exista photoUrl. Sin fotos no hay verificación posible ni un producto comparable a Hinge, Bumble BFF o Timeleft.
- **Recomendación:** Hasta 6 fotos, con 1 obligatoria para aparecer en Cerca. Usar image_picker con recorte 4:5 y compresión a 1080 px y ≤1 MB, y quitar el EXIF/GPS en cliente y servidor. Subida a Storage con reglas (dueño, ≤5 MB, image/*) y una Function de moderación (SafeSearch LIKELY+ → rechazo) antes de publicar photoUrls. Usar blurhash como placeholder y fotos también en web. Criterio: test de reglas de Storage, test que confirma que el archivo publicado no tiene EXIF, y goldens de perfil y tarjeta con foto.

### T1-04 · P0 · compliance
**Se exige aceptar unos Términos que no existen y el checkbox no tiene links**

- **Evidencia:** lib/screens/onboarding/age_consent_form.dart:73-80 (CheckboxListTile sin links); lib/core/config/app_config.dart:29-32 (termsUrl=https://picaflor.app/terminos, otro dominio que el hosting picaflorapp.web.app); web/ no tiene terminos.html; firebase.json rewrites solo /privacidad y /eliminar-cuenta
- **Detalle:** El consentimiento no es informado si no se puede leer lo que se acepta. Eso choca con la Ley 21.719 (vigente el 1-12-2026) y con las exigencias de las tiendas. Además, el link de Ajustes > Términos apunta a un dominio que no está en el repo.
- **Recomendación:** Crear web/terminos.html (borrador marcado para abogado) con rewrite /terminos, unificar el dominio y hacer que 'Términos' y 'Política de Privacidad' sean links que se puedan tocar dentro del label del checkbox (TextSpan con recognizer y Semantics link). Criterio: un test de widget toca cada link y verifica launchUrl con la URL esperada, y un test de hosting comprueba que /terminos responde 200.

### T1-05 · P0 · compliance
**Edad y consentimientos solo quedan en el teléfono, el toggle de analytics no hace nada y la edad se puede reintentar**

- **Evidencia:** lib/screens/onboarding/onboarding_screen.dart:63-69 (solo SharedPreferences); lib/core/analytics/app_analytics.dart:35 (consent=false, nadie lo asigna; grep keyAnalyticsConsent sin lectores); age_consent_form.dart:49-71 (si tienes <18 puedes volver a elegir la fecha)
- **Detalle:** El servidor nunca conoce la fecha de nacimiento: getNearby no puede filtrar por edad, la ficha no muestra edad y no queda un registro auditable de consentimiento con versión y fecha. Un menor cambia la fecha y entra. El checkbox de métricas es decorativo.
- **Recomendación:** Crear el callable recordConsent{termsVersion, privacyVersion, analytics, ts} y guardar birthDate en users/{uid}. La edad se calcula en el servidor y se expone solo como `age` en profiles. Si la edad es menor a 18: pantalla de cierre respetuosa, bloqueo persistente en el dispositivo y evento age_gate_failed. AppAnalytics.consent se lee de ese registro y se puede cambiar en Ajustes. Criterio: tests en el emulador y test de widget del bloqueo.

### T1-06 · P0 · false_claim
**El reporte promete revisión en menos de 24 h sin cola de moderación, y bloquear no tiene confirmación ni deshacer**

- **Evidencia:** lib/widgets/public_profile_sheet.dart:140-169 (SimpleDialog sin texto libre ni 'Además, bloquear'; snackbar 'Lo revisamos en menos de 24 h'); :73-75, chat_list_screen.dart:301-308, chat_screen.dart:160-167 (bloqueo inmediato); docs/PLAN.md:13 ('La cola de moderación humana no existe'); firestore.rules:180-186 (reports solo se crea)
- **Detalle:** Ante acoso, el usuario recibe una promesa que nadie va a cumplir: no hay trigger, alerta ni panel. Apple 1.2 exige actuar sobre los reportes. Bloquear por error desde el menú ⋯ de una fila no se puede deshacer y no hay una lista de bloqueados.
- **Recomendación:** Crear PfReportSheet con los motivos de §5.5.11, texto libre (obligatorio en 'otro') y el toggle 'Además, bloquear' (activado por defecto en acoso, sexual y menor). Confirmación honesta sin SLA hasta que exista onReportCreated con alerta y panel admin. Bloquear pide confirmación explicando las consecuencias, ofrece Deshacer por 5 s y se agrega Ajustes > Usuarios bloqueados. Criterio: tests de widget de cada estado y copy aprobado en docs/voice.md.

### T1-07 · P1 · false_claim
**'Avisarme' de Plus dice 'Quedaste en la lista de espera' sin guardar nada**

- **Evidencia:** lib/screens/plus/plus_screen.dart:45-55 (solo SnackBar); grep 'waitlist' en lib y functions/src sin escrituras
- **Detalle:** Se le miente al usuario y se pierde la señal de intención de compra, que es la métrica con que la Fase L decide encender Plus por comuna.
- **Recomendación:** Guardar waitlist/{uid} con {comunaBucket, trigger, ts} mediante callable o regla de solo creación, emitir el evento waitlist_joined y mostrar un estado 'Ya estás en la lista' que persista al volver a la pantalla. Criterio: test en el emulador y test de widget del estado persistido.

### T1-08 · P1 · design
**El design system se adoptó solo de nombre: los tokens están, pero la UI sigue con AppColors, isDark y sombras**

- **Evidencia:** grep: 0 usos de context.pf; 376 refs AppColors.* fuera de app_colors.dart; 98 'isDark ?' en UI; lib/core/design_system/components/ solo tiene pf_mark.dart (1 de 22 de §5.4); AppShadows.* 13 usos (lib/core/theme/app_spacing.dart:141-271); lib/widgets/picaflor_card.dart:17 elevated=true por defecto; git diff --stat: profile_screen 1 línea, main_shell 5, picaflor_person_card 14
- **Detalle:** Hay dos sistemas conviviendo: PfColors registrado (app_theme.dart:69) que nadie lee, y aliases AppColors con ternarios por pantalla. Cada pantalla resuelve a mano bordes, alphas (59 withValues), radios y pesos (46 fontWeight). No escala, no es consistente y produjo la regresión T1-09.
- **Recomendación:** Migrar pantalla por pantalla a context.pf.* y a los componentes Pf*. Marcar AppColors, AppShadows y AppTypography como @Deprecated y prohibirlos fuera de design_system. La elevación por defecto pasa a e0 (solo borde). Criterio: `grep -rnE "AppColors\.|AppShadows\.|isDark \?" lib/screens lib/widgets lib/features` = 0 y los 22 componentes existen, cada uno con test de widget y golden.

### T1-09 · P1 · bug
**Regresión de contraste en dark mode al re-asignar el alias primaryMuted**

- **Evidencia:** lib/core/theme/app_colors.dart:10 (primaryMuted=#075E55) vs `git show 02abbd4:lib/core/theme/app_colors.dart`:11 (#6FBFB6); usos con isDark en main_shell.dart:195,206; nearby_screen.dart:545,642,715,745; picaflor_person_card.dart:223,291; profile_screen.dart:182; nearby_map.dart:530,641; picaflor_empty_state.dart:69. También public_profile_sheet.dart:96 (lightTextSecondary fijo) y settings_screen.dart:266 (primaryDark en dark)
- **Detalle:** Lo medí con la fórmula WCAG. #075E55 sobre la superficie dark da 2,35:1, y sobre el indicador del rail (brand al 18%) 1,99:1. Afecta el ítem activo de la navegación, el toggle Lista/Mapa, los tags de intereses, 'Chatear' y la píldora del radio. #4A5363 sobre #12171E da 2,32:1. El test v2 solo valida pares de tokens, no lo que se pinta.
- **Recomendación:** Que ningún widget elija color por ternario: dark usa onBrandSubtle=#3CC2B3 desde PfColors.dark. Agregar tests de widget que pinten cada pantalla en light y dark con expect(tester, meetsGuideline(textContrastGuideline)). Criterio: 0 fallas, y el label activo del rail en dark ≥4,5:1.

### T1-10 · P1 · gap
**Accesibilidad casi nula: 1 Semantics en toda la app, targets chicos y controles sin nombre**

- **Evidencia:** grep: Semantics( solo en pf_mark.dart:17; 5 tooltips; IconButton atrás sin tooltip en chat_screen.dart:224-227 y settings_screen.dart:31-34; envío sin label en message_input.dart:114-147; toggle Lista/Mapa con GestureDetector de 34×38 px sin rol ni estado en nearby_screen.dart:550-562; refrescar 38×38 en :631-633; botón de chat 44×44 en picaflor_person_card.dart:330-332; 'Regístrate' con GestureDetector sobre texto en login_screen.dart:515-531; shimmer infinito sin label en picaflor_skeleton.dart:46-49; 0 testWidgets
- **Detalle:** Con TalkBack o VoiceOver, el envío se anuncia como 'botón' sin nombre, el segmento Lista/Mapa no anuncia 'seleccionado' y las tarjetas se leen como fragmentos sueltos. MediaQuery.disableAnimations no se respeta en ningún lugar (0 referencias).
- **Recomendación:** Semantics completa en todos los elementos interactivos y MergeSemantics en tarjetas ('Camila, 29, a unos 300 m, activa hoy. Saludar'). Targets ≥48 px, anillo de foco visible (FocusThemeData) y SemanticsService.announce para los resultados. Criterio: los 4 guidelines de flutter_test en verde en cada pantalla, goldens a escala 2.0 en 320 px sin overflow y docs/a11y/report.md con video de la pasada TalkBack/VoiceOver.

### T1-11 · P1 · design
**El isotipo PfMark no se lee como picaflor y la marca es distinta en cada superficie**

- **Evidencia:** lib/core/design_system/components/pf_mark.dart:33-54 (lo rasterizé a 16/24/48/256 px: no tiene pico, el ojo es del mismo color y sobresale del contorno como un bulto, el ala al 0,85 de alpha se funde y queda descentrado en x 0,10–0,78); main_shell.dart:290-322 (rail con una 'P' w800 sobre gradiente); login_screen.dart:177-189, settings_screen.dart:214-226 y splash_screen.dart:57-68 (PfMark dentro de gradiente); web/index.html:47-53 (cuadrado con gradiente)
- **Detalle:** El pico largo es el rasgo que identifica a un picaflor y no está. A 16 px es una mancha. Hay 4 representaciones de marca distintas y los gradientes contradicen 'color con propósito, bordes antes que sombras'.
- **Recomendación:** Isotipo SVG de una tinta (flutter_svg) con pico recto y largo, cuerpo y ala reconocibles, hecho en grilla de 24, legible a 16 px. Lockup con wordmark en Inter, versiones light, dark y monocromática. Un solo componente PfLogo, sin gradientes. Criterio: hoja docs/brand/mark-sizes.png (16/24/32/48/1024) aprobada por la persona dueña del producto en un ADR, y `grep -rn "primaryGradient\|_BrandMark" lib` = 0.

### T1-12 · P1 · design
**Siguen 3 splashes desalineados (D7 sin resolver)**

- **Evidencia:** android/app/src/main/res/drawable/launch_background.xml (blanco); ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png (68 bytes, vacíos); web/index.html:30-73 (loader oscuro #0B0F14 con cuadrado pulsante y failsafe de 4 s); lib/screens/splash/splash_screen.dart y app_router.dart:104-112 (ruta /splash oscura); pubspec sin flutter_native_splash
- **Detalle:** En Android se ve blanco y luego la app. En web se ve un loader oscuro genérico y luego la app en light, lo que produce un flash de color opuesto. Si el primer frame tarda más de 4 s en web, queda una pantalla vacía.
- **Recomendación:** Usar flutter_native_splash en light (#FFFFFF) y dark (#0B0F14) con el isotipo centrado y la API de splash de Android 12. El loader HTML usa el mismo SVG inline con prefers-color-scheme y sin timeout ciego. Eliminar la ruta /splash. Criterio: `grep -rn SplashScreen lib` = 0 y capturas de arranque light/dark sin flash.

### T1-13 · P1 · compliance
**Botones de Google y Apple no oficiales (D3 sin resolver)**

- **Evidencia:** lib/screens/auth/login_screen.dart:488-495 (Text('G') + label 'Google'); :496-503 (Icons.apple_rounded + 'Apple')
- **Detalle:** No cumple las guías de marca de Google Identity (logo G multicolor oficial y texto 'Continuar con Google') ni la HIG de Sign in with Apple. Es riesgo de rechazo en App Review y se ve amateur.
- **Recomendación:** Usar SignInWithAppleButton de sign_in_with_apple (estilo según tema, 'Continuar con Apple') y el asset oficial de Google con texto 'Continuar con Google' y medidas según la guía. Criterio: golden light/dark del login en iOS y Android y checklist de marca en el PR.

### T1-14 · P1 · design
**Login sin una sola acción primaria, sin autofill ni OTP**

- **Evidencia:** login_screen.dart:209-266 ('Entrar en demo' lleno), :424-456 (Entrar/Crear cuenta lleno), :488-503 (social debajo); picaflor_text_field.dart:24,90 (soporta autofillHints pero ninguna pantalla lo pasa); :383-391 (SMS en un campo simple); :327 (email válido = contiene '@'); sin layout dividido ≥900 px
- **Detalle:** Compiten 3–4 CTAs. El orden es el inverso a los referentes (correo y clave arriba, social abajo). Sin autofill, iOS y Android no ofrecen claves guardadas ni el código SMS. Tampoco hay prefijo +56 ni máscara.
- **Recomendación:** Jerarquía: Apple en iOS o Google en Android/web como CTA primario, luego 'Continuar con teléfono' (secundario) y 'Usar correo' (terciario). Teléfono con +56 fijo y máscara '9 XXXX XXXX'. PfOtpField de 6 casillas con AutofillHints.oneTimeCode y reenvío con cuenta regresiva de 30 s. AutofillGroup con email, password y newPassword. En ≥900 px, panel de marca + formulario de 420 px. Criterio: test que verifica autofillHints en cada campo, goldens 375 y 1440, y guidelines a11y.

### T1-15 · P1 · gap
**El onboarding no activa: slides genéricos, sin 'Completar perfil' y sin guiar el primer saludo**

- **Evidencia:** onboarding_screen.dart:32-51 (Icons Material en círculos; copy 'Abre un chat' que contradice el Saludo; acento #9A3412 como segundo color de marca); :53-62 (validación por SnackBar); age_consent_form.dart:52-56 (date picker en modo calendario); login_screen.dart:65 y app_router.dart:95-98 (tras el login va directo a /home)
- **Detalle:** El usuario llega a Cerca sin foto, sin bio y sin intereses, y nadie lo guía a saludar el primer día. El CTA 'Empezar' parece activo cuando no lo está. El layout usa Spacer sin scroll, así que es probable que se desborde con texto al 200% (supuesto, no ejecutado).
- **Recomendación:** Flujo con barra de progreso: propuesta de valor con isotipo, privacidad ('Tu zona, nunca tu punto exacto'), edad y términos (CTA deshabilitado hasta que sea válido, error inline, fecha DD-MM-AAAA), login, Completar perfil (foto, 3–5 intereses, 1 prompt), pre-permiso de ubicación y 'Tu primer saludo' con 3 personas cercanas. Criterio: test Patrol de punta a punta y eventos onboarding_completed, profile_completed y first_wave_sent emitidos.

### T1-16 · P1 · design
**La tarjeta de Cerca dice 'Chatear' pero abre la ficha, y su presencia no funciona en producción**

- **Evidencia:** lib/widgets/picaflor_person_card.dart:308,323 ('Chatear' con ícono de chat); nearby_screen.dart:1072-1073 (onTap y onChat abren la ficha); picaflor_person_card.dart:137-147 ('En línea' según isOnline); user_service_live.dart:106-108 (el cliente ya no escribe isOnline)
- **Detalle:** La tarjeta promete un chat que no existe y contradice el modelo de saludo. 'En línea' nunca aparece en producción y el bucket de actividad (ahora, hoy, esta semana) no se muestra. Tampoco hay edad. Avatar de 58 px con iniciales y radio 24 con sombras de 3 capas, fuera del spec (16, e0).
- **Recomendación:** Tarjeta PfCard e0: foto 4:5 o avatar de 72 px, 'Nombre, edad', distancia y actividad como texto, 2 intereses, CTA terciario 'Saludar'. Toda la tarjeta lleva un solo nodo semántico. Criterio: goldens en 4 tamaños × 2 temas × escala 1,0 y 2,0, y `grep -rn "Chatear" lib` = 0.

### T1-17 · P1 · gap
**Cerca no tiene dato protagonista, ni presets, ni estado offline, y el estado vacío no ayuda a la liquidez**

- **Evidencia:** nearby_screen.dart:328-329 (subtítulo fijo 'Gente alrededor · zona aproximada'); :755-782 (slider continuo); :1024-1035 (vacío 'Nadie cerca… por ahora' con 'Actualizar'); :1007-1013 (error genérico); sin paquete de conectividad
- **Detalle:** Al lanzar, el estado vacío va a ser el más frecuente y no ofrece invitar a alguien, pedir aviso ni ampliar el radio. No hay PfStat ('14 personas a menos de 2 km'), ni PfRadiusPicker, ni banner offline.
- **Recomendación:** Header con PfStat de cifras tabulares, PfSegmented Lista|Mapa (48 px) y PfRadiusPicker con 500 m, 1, 2 y 5 km (10 km con candado de Plus, que dispara el paywall con trigger=radius). Estados: skeleton con label, vacío de liquidez ('Invitar a alguien', 'Avisarme cuando haya gente cerca', 'Ampliar radio'), offline, error con reintento y sin permiso. Criterio: goldens de cada estado.

### T1-18 · P1 · design
**La ficha pública no cumple §5.5.5: avatar chico, sin edad, intereses ni skeleton, y Saludar sin estados**

- **Evidencia:** lib/widgets/public_profile_sheet.dart:27-36 (muestra 'Persona' mientras carga), :52-56 (avatar 64), :103-130 (FilledButton sin loading ni estado 'enviado'); nearby_screen.dart:210-217 (showModalBottomSheet sin isScrollControlled)
- **Detalle:** Saludar se puede tocar dos veces y al reabrir la ficha aparece de nuevo aunque haya un saludo pendiente. No muestra el cupo restante. Con texto grande el sheet se corta. En desktop sigue siendo bottom sheet en lugar de panel lateral.
- **Recomendación:** Sheet scrollable al 90% en móvil y panel de 400 px en ≥1200: fotos, nombre y edad, badge de verificado, distancia y actividad, bio, intereses y prompts. CTA 'Saludar 👋' con estados idle, loading, 'Saludo enviado' (deshabilitado) y cupo agotado (enlaza al paywall), más 'Te quedan N saludos hoy' y skeleton. Criterio: un test de doble tap envía 1 solo saludo y hay tests de cada estado.

### T1-19 · P1 · design
**El mapa de producción engaña: pines con dirección inventada sobre un mapa real**

- **Evidencia:** lib/core/privacy/display_pin.dart:16-29 (ángulo = hash(uid) % 360); lib/services/user_service_live.dart:127-133 (getUser secuencial por persona, N+1)
- **Detalle:** La privacidad está bien resuelta, pero sobre calles reales el usuario va a leer 'está en Ñuñoa' cuando el punto es ficticio. Eso genera expectativas falsas y quejas. Además, el N+1 secuencial alarga el skeleton.
- **Recomendación:** ADR: reemplazar los pines por un 'Radar' abstracto (anillos por bucket, avatares sin mapa base) o por densidad por celda o comuna con k≥3. El mapa geográfico muestra solo tu propia zona. Perfiles en batch dentro de getNearby. Criterio: test que verifica que ningún marcador de otra persona usa coordenadas geográficas.

### T1-20 · P1 · gap
**Chat sin tip de seguridad, sin estado de bloqueo ni estados de envío**

- **Evidencia:** chat_screen.dart:272-281 (menú sin Silenciar; la cabecera no abre el perfil), :342 ('Sé el primero', con género), :365-377 ('Mensajes anteriores' como botón fijo, aunque haya 3 mensajes); widgets/chat_bubble.dart:71-72 (Radius.circular(18), que el gate no detecta); el modelo de mensaje no tiene estado de envío
- **Detalle:** No aparece 'Si se juntan, elijan un lugar público.' en el primer chat. Si la otra persona bloquea, el composer sigue activo. No hay estados enviando, fallido ni reintentar, ni long-press para copiar o reportar un mensaje.
- **Recomendación:** Tip de seguridad que se puede descartar en el primer chat. Si el chat está bloqueado, el composer se reemplaza por un aviso. Burbujas con estado y reintento. Paginación al hacer scroll hacia arriba. Long-press para copiar o reportar. En desktop, Enter envía y Shift+Enter hace salto de línea. Semantics 'Tú, 14:32: …'. Copy neutro: 'Escribe primero'. Criterio: tests de widget y golden.

### T1-21 · P1 · gap
**Mi perfil y Ajustes incompletos y con copy de desarrollador visible**

- **Evidencia:** profile_screen.dart:134-145 (muestra el email propio), :70-71 (error sin reintento), :104-111 y :286-291 (Ajustes duplicado); settings_screen.dart:103-109 ('Visibilidad' hace context.pop()), :410-428 (exportar = data.toString() en un diálogo), :437-480 (borrado sin loading, sin manejo de errores ni aviso de suscripción), :157 y :444 ('en producción…'), :285-301 (URLs crudas); plus_screen.dart:41 ('precios propuestos, no finales'); haptic.dart:41-46 (vibrate() al cerrar sesión)
- **Detalle:** No existen 'Así te ven', editor de intereses, fotos ni prompts, ni tarjeta Plus. En Ajustes faltan Notificaciones, Usuarios bloqueados, Ayuda y seguridad, Incógnito y Restaurar compras. Exportar no entrega un archivo portable, que es lo que pide la Ley 21.719.
- **Recomendación:** Mi perfil: vista 'Así te ven', medidor de completitud y edición de fotos, intereses y prompts, sin email visible. Ajustes con las secciones de §5.5.9. Exportar entrega un JSON por share sheet o correo. Eliminar avisa 'no cancela tu suscripción en la tienda'. Criterio: grep de 'en producción', 'propuestos' y 'nube' en strings de release = 0, más goldens.

### T1-22 · P1 · monetization
**El paywall no cumple §7.4 ni Apple 3.1.2 y no tiene disparadores contextuales**

- **Evidencia:** lib/screens/plus/plus_screen.dart:27-43 (bullets de texto sin íconos ni selector; anual grande en vez del equivalente mensual), :57-66 ('Restaurar' solo muestra un SnackBar), sin links a Términos y Privacidad; settings_screen.dart:137 (única entrada); features/waves/wave_actions.dart:27-29 (el cupo agotado lanza texto sin CTA)
- **Detalle:** Cuando se encienda Plus no va a convertir ni a pasar revisión. Le faltan selector de planes, precio mensual equivalente, términos de renovación con links y Restaurar real, y no aparece en los momentos de intención (cupo, radio, incógnito).
- **Recomendación:** PfPlanCard ×3 con el anual preseleccionado ('Ahorra 50%'), equivalente mensual tabular grande, 4 beneficios con ícono en color plus, X visible desde el primer frame, Restaurar real, links legales y precios leídos de la tienda. Disparadores: cupo, radio >5 km, incógnito, visitas y la 3.ª conversación con respuesta (máximo 1 cada 48 h). Criterio: evento paywall_viewed{trigger} testeado y golden.

### T1-23 · P1 · gap
**Sin notificaciones push en el cliente aunque el servidor las envía**

- **Evidencia:** functions/src/onMessageCreated.ts:52-66 (sendEachForMulticast); pubspec.yaml sin firebase_messaging; lib/models/user_model.dart:22,40 (fcmToken nunca se registra)
- **Detalle:** Sin push, el saludo recibido o aceptado y los mensajes nuevos no traen de vuelta a nadie, y el loop pierde tracción. No hay pre-permiso contextual ni preferencias de notificaciones.
- **Recomendación:** Agregar firebase_messaging. Pre-permiso después del primer saludo enviado, no al abrir la app. Tokens en users/{uid}.fcmTokens, canales Android (saludos, mensajes), contenido oculto por defecto y deep link al tocar (/chats?tab=saludos, /chat/:id). Criterio: test de navegación desde el payload.

### T1-24 · P1 · gap
**Sin deep links, perfil para compartir ni invitaciones (growth y liquidez)**

- **Evidencia:** lib/router/app_router.dart:20-29 (sin /u/:id ni /invite); android/app/src/main/AndroidManifest.xml:26-29 (solo intent-filter de launcher); sin associated-domains en iOS; sin share_plus
- **Detalle:** La monetización depende de la densidad por comuna y no hay ningún loop viral ni de referidos para crearla.
- **Recomendación:** App Links (assetlinks.json) y Universal Links (AASA) en el dominio de hosting. Rutas /u/:handle (nombre, foto principal e intereses, sin distancia; hay que entrar para saludar) e /invite/:code con atribución, más 'Invita a alguien' con share_plus y OG image. Criterio: tests del router con URIs y validadores AASA y assetlinks en CI.

### T1-25 · P1 · gap
**Sin verificación de identidad (selfie) ni prompts de perfil**

- **Evidencia:** No existe en lib/ (grep verif|selfie|prompt sin resultados de producto)
- **Detalle:** Bumble BFF, Hinge y Timeleft usan verificación y prompts para generar confianza y para romper el hielo. Aquí no hay contexto para escribir el primer mensaje ni una señal de autenticidad.
- **Recomendación:** Prompts: catálogo es-CL de unos 20, de 1 a 3 por perfil y 150 caracteres. Reaccionar a un prompt es gratis y la nota sigue siendo Plus. Verificación con liveness detrás del flag verification_enabled; el proveedor se decide en un ADR humano y la biometría, que es dato sensible bajo la Ley 21.719, pide consentimiento explícito separado y se borra después de verificar. Filtro 'solo verificados' gratis (la seguridad no se cobra).

### T1-26 · P1 · process
**Los gates no detectan lo que importa y CI no corre dart format**

- **Evidencia:** tool/gates.sh:7 (solo Color(0x, fontSize: y BorderRadius.circular(<dígito>)); .github/workflows/ci.yml (sin dart format); grep: 182 literales width/height/size en UI, 16 'AppSpacing.x ± n', 59 withValues(alpha:, 46 fontWeight:, Radius.circular(18) en chat_bubble.dart:71
- **Detalle:** BASELINE da el gate como verde mientras la UI está llena de valores sueltos. Sin gates efectivos, la consistencia no se sostiene con más pantallas ni con más agentes.
- **Recomendación:** Ampliar gates.sh para que falle con AppColors., isDark ?, Colors.(white|black), Radius.circular(, withValues(alpha:, fontWeight:, TextStyle(, Duration(milliseconds:, HapticFeedback., (width|height|size): [0-9] y Icons.*_outlined fuera de design_system, y con IconButton sin tooltip. Agregar `dart format --set-exit-if-changed`. Criterio: un fixture con una violación sembrada hace fallar CI.

### T1-27 · P1 · false_claim
**El PLAN da por hechas las Fases 2 y 4 sin evidencia visual, y BASELINE afirma un bloqueo que no existe**

- **Evidencia:** docs/PLAN.md:9-15 (Fase 2 y Fase 4 'Hecho'); docs/BASELINE.md:53 ('(bloqueo) en la lista de Cerca'), pero no hay 'block' ni 'Bloquear' en nearby_screen.dart ni en picaflor_person_card.dart; test/: 0 testWidgets, 0 goldens; no existen docs/screenshots ni /_dev/gallery
- **Detalle:** Las declaraciones de estado no siguen la regla 'nunca declares listo sin evidencia' (§1, §12) y llevan a planear sobre algo que no existe.
- **Recomendación:** El v2 debe exigir que cada fila 'Hecho' cite archivo:línea, nombre del test y golden. A12 hace una auditoría de afirmaciones antes de cerrar cada fase. Galería /_dev/gallery solo en dev con todos los Pf* y estados.

### T1-28 · P1 · gap
**No hay screenshots, assets de tienda, ASO ni plan para App Review**

- **Evidencia:** DEPLOY.md:121-136 (el checklist no incluye íconos, capturas, ficha ni cuenta de revisión); no existe fastlane/ ni metadata/
- **Detalle:** Un revisor de Apple fuera de Santiago va a ver 'Nadie cerca' y es probable que rechace por 2.1 (app incompleta). No hay capturas, feature graphic, textos ni keywords en es-CL.
- **Recomendación:** fastlane/metadata es-CL: título ≤30 ('Picaflor: gente cerca'), subtítulo, keywords ≤100, descripción corta de Play ≤80, feature graphic 1024×500 y 6–8 capturas con caption generadas por integration_test (iOS 6.9/6.5, Android phone y tablet). Notas de revisión con cuentas de prueba reales en una geocerca de revisión, sin datos demo en producción. Agregar docs/store/data-map.md (dato, propósito, label o Data safety).

### T1-29 · P1 · monetization
**Analytics sin instrumentar: el umbral para encender Plus no se puede medir**

- **Evidencia:** grep '.track(' en lib = 0 fuera de app_analytics.dart; docs/product/plus.md (umbral de liquidez del 60%)
- **Detalle:** El embudo de §7.6 no existe, así que no se pueden medir la activación D0, la aceptación de saludos ni la liquidez por comuna, que es la condición para monetizar.
- **Recomendación:** Implementar los eventos de §7.6, más waitlist_joined, first_wave_sent e invite_sent, sujetos al consentimiento real. Criterio: un test por flujo verifica la emisión y docs/product/metrics.md define cada KPI y su query.

### T1-30 · P2 · design
**Motion y haptics sin sistema**

- **Evidencia:** 11 duraciones distintas (110–1400 ms), PageView de 350 ms (onboarding_screen.dart:85), sin pageTransitionsTheme en app_theme.dart, 0 refs a disableAnimations; 31 llamadas a Haptic y Haptic.warning=vibrate() para cerrar sesión (profile_screen.dart:310, settings_screen.dart:177)
- **Detalle:** El movimiento es irregular y no respeta la opción de reducir movimiento. La vibración fuerte para una acción trivial se siente mal.
- **Recomendación:** PfMotion (fast 120, base 200, slow 300, easeOutCubic) que lee disableAnimations, transiciones fade + slide de 8 px y PfHaptics semánticos (selection, success, warning) sin vibrate(). El gate prohíbe Duration y HapticFeedback fuera del design system.

### T1-31 · P2 · design
**Iconografía mezclada y flecha de iOS en Android**

- **Evidencia:** grep: 44 Icons *_rounded + 29 *_outlined + 1 plain; arrow_back_ios_new_rounded en chat_screen.dart:225 y settings_screen.dart:32
- **Detalle:** Mezcla dos familias de íconos, en contra de 'un solo set' (§5.2), y usa la affordance equivocada en Android.
- **Recomendación:** Un solo set (Material Symbols Rounded o Lucide) en 20/24, con Icons.adaptive o BackButton para volver y tooltip en todos los íconos accionables. Gate: Icons.*_outlined = 0.

### T1-32 · P2 · process
**Sin l10n ARB, strings en todo el código y glosario inconsistente**

- **Evidencia:** no existe lib/l10n ni generate: true; 'Chats' (main_shell.dart:96) vs 'Mensajes' (chat_list_screen.dart:54); 'Contraseña' (login_screen.dart:336) vs 'clave' (:357); debugPrint con emoji fuera de kDebugMode (nearby_screen.dart:188)
- **Detalle:** Así no escala a otras ciudades o países ni a un A/B de copy, y la voz se va desviando entre pantallas.
- **Recomendación:** lib/l10n/app_es_CL.arb con gen-l10n y 0 literales en presentation (gate), aplicando el glosario de docs/voice.md.

### T1-33 · P2 · design
**Tipografía: sin cifras tabulares, con overrides locales y pesos sin empaquetar**

- **Evidencia:** 0 usos de tabularFigures; PfType.textTheme usa nombres de Material y no los del spec (pf_type.dart); 46 fontWeight y 18 height sobrescritos en la UI; FontWeight.w800 en main_shell.dart:316 (no hay Inter-ExtraBold); 4 TTF estáticos (1,67 MB) sin subset para web
- **Detalle:** Distancias, contadores y precios 'bailan' sin cifras tabulares. Los overrides rompen la escala tipográfica.
- **Recomendación:** PfType con los estilos display, titleLg… overline, más una variante numérica con FontFeature.tabularFigures(). Prohibir fontWeight y height fuera de PfType. Subset latin y latin-ext o Inter variable para web.

### T1-34 · P2 · design
**Escritorio y web todavía no se ven como producto**

- **Evidencia:** app_router.dart:166-175 (el chat usa el root navigator y oculta el rail); chat_list_screen.dart:39 (una columna de 680 px); picaflor_avatar.dart:42 (sin fotos en web); ficha como bottom sheet en desktop
- **Detalle:** En 1440 px el chat tapa la navegación, no hay vista maestro-detalle y la ficha sube desde abajo. Se siente como un móvil estirado.
- **Recomendación:** En ≥1200 px: Chats en maestro-detalle (lista de 360 px + conversación), ficha en panel lateral, hover y foco definidos, Esc cierra paneles. Criterio: goldens en 1440×900.

**Requisitos que esta lente exige para la v2**

- DS-1 Adopción real del design system: cada pantalla y widget lee solo context.pf.colors, PfType, PfSpace, PfRadius, PfMotion y componentes Pf*. Criterio: `grep -rnE "AppColors\.|AppShadows\.|AppTypography\.|isDark \?" lib --include=*.dart | grep -v lib/core/design_system` = 0.
- DS-2 Biblioteca: los 22 componentes de §5.4 existen en lib/core/design_system/components con doc comment, estados (default, hover, pressed, focus, disabled, loading, error), Semantics, test de widget y golden light/dark × escala 1,0/2,0. Galería en /_dev/gallery solo en el flavor dev.
- DS-3 Gates ampliados en tool/gates.sh (fallan CI): AppColors., isDark ?, Colors.(white|black), Radius.circular(, withValues(alpha:, fontWeight:, TextStyle(, Duration(milliseconds:, HapticFeedback., Icons.[a-z_]+_outlined, (width|height|size): [0-9] fuera de design_system, IconButton sin tooltip y literales Text('…') en presentation. Más `dart format --set-exit-if-changed` en ci.yml. Un fixture con una violación sembrada debe hacer fallar CI.
- A11Y-1 Cada pantalla tiene un test de widget en light y dark que pasa textContrastGuideline, androidTapTargetGuideline, iOSTapTargetGuideline y labeledTapTargetGuideline. Caso explícito: el label activo del rail en dark ≥4,5:1 (hoy 1,99:1).
- A11Y-2 Semantics completa: MergeSemantics por tarjeta ('Camila, 29, a unos 300 m, activa hoy. Saludar'), selected en segmented y tabs, label en enviar, volver, refrescar y skeleton. SemanticsService.announce para 'Saludo enviado' y 'Bloqueaste a…'. Anillo de foco visible en web y desktop. Goldens a escala 2,0 en 320 px sin overflow para onboarding, login, Cerca, ficha, chat y paywall. docs/a11y/report.md con video de TalkBack y VoiceOver.
- BRAND-1 Isotipo SVG de una tinta, reconocible como picaflor (pico largo y recto), legible a 16 px, con lockup y variantes light, dark y mono. Hoja docs/brand/mark-sizes.png (16/24/32/48/1024) aprobada en un ADR humano. Se eliminan el CustomPainter PfMark, _BrandMark con 'P' y todos los gradientes de marca.
- BRAND-2 Íconos de app desde el isotipo con flutter_launcher_icons: Android adaptive + monochrome, iOS 1024 sin alpha + dark/tinted, web 192/512 + maskable, favicon. Un script de CI falla si algún md5 coincide con los íconos de Flutter por defecto.
- BRAND-3 Un solo splash: flutter_native_splash light #FFFFFF y dark #0B0F14 con el isotipo, la API de splash de Android 12 y loader HTML con el mismo SVG y prefers-color-scheme. Se elimina la ruta /splash. Criterio: `grep -rn SplashScreen lib` = 0 y capturas de arranque sin flash de color opuesto.
- AUTH-1 Login con una acción primaria: SignInWithAppleButton oficial en iOS y el botón oficial 'Continuar con Google' (asset G multicolor) en Android y web. 'Continuar con teléfono' es secundario y 'Usar correo' terciario. Teléfono con +56 fijo y máscara. PfOtpField de 6 casillas con AutofillHints.oneTimeCode y reenvío a los 30 s. AutofillGroup en email y clave. En ≥900 px, panel de marca + formulario de 420 px. Un test verifica autofillHints en cada campo.
- ONB-1 Flujo de activación con barra de progreso: valor, privacidad, edad y términos (links que se pueden tocar a /terminos y /privacidad existentes, CTA deshabilitado hasta que sea válido, error inline, fecha DD-MM-AAAA), login, Completar perfil (≥1 foto, 3–5 intereses de catálogo, 1 prompt), pre-permiso de ubicación y 'Tu primer saludo' con 3 personas. Test Patrol de punta a punta. Eventos onboarding_completed, profile_completed y first_wave_sent.
- ONB-2 Si la edad es menor a 18: pantalla de cierre respetuosa, bloqueo persistente en el dispositivo y evento age_gate_failed. El callable recordConsent guarda {termsVersion, privacyVersion, analytics, ts} y birthDate en users/{uid}. La edad se calcula en el servidor y se publica solo como profiles.age. El toggle de analytics en Ajustes cambia la emisión (test).
- PHOTO-1 Fotos: de 1 a 6, con 1 obligatoria para ser visible. Recorte 4:5, 1080 px y ≤1 MB, sin EXIF (test sobre el archivo publicado). Storage rules con tests, Function de moderación SafeSearch antes de publicar, blurhash y fotos también en web (quitar `kIsWeb` de picaflor_avatar.dart:42).
- LOOP-1 Bandeja de saludos en Chats: 'Saludos nuevos (n)' con Aceptar e Ignorar (silencioso), 'Enviados' con estado y expiración a 7 días, badge en el tab y respondWave conectado. En demo, aceptación automática a los 3–8 s. Test en emulador: A saluda, B acepta y el chat queda visible para ambos.
- NEARBY-1 Cerca: PfStat tabular 'N personas a menos de X', PfSegmented de 48 px, PfRadiusPicker 500 m/1/2/5 km (10 km con candado → paywall trigger=radius) y tarjeta e0 con foto o avatar de 72, 'Nombre, edad', bucket de distancia y actividad como texto, 2 intereses y CTA 'Saludar'. Estados: skeleton con label, vacío de liquidez (Invitar, Avisarme, Ampliar), offline (conectividad), error y sin permiso. Goldens de cada estado en 375, 412, 820 y 1440 × light/dark.
- NEARBY-2 Mapa: ADR que reemplaza los pines con dirección ficticia por un Radar abstracto o por densidad por celda o comuna con k≥3. Test: ningún marcador de otra persona usa coordenadas geográficas. Perfiles en batch dentro de getNearby (sin N+1).
- PROFILE-1 Ficha pública: sheet scrollable al 90% en móvil y panel de 400 px en ≥1200, con fotos, edad, verificado, bio, intereses y prompts. 'Saludar 👋' con estados idle, loading, enviado y cupo agotado (enlaza al paywall), más 'Te quedan N saludos hoy'. Test: doble tap envía 1 solo saludo.
- PROFILE-2 Mi perfil: 'Así te ven', medidor de completitud, editor de fotos, intereses y prompts, toggle 'Visible en Cerca' con explicación y tarjeta Plus si el flag está activo. Nunca se muestra el email.
- TRUST-1 PfReportSheet con los motivos de §5.5.11, texto libre y 'Además, bloquear' (activado por defecto en acoso, sexual y menor). Copy honesto sin SLA hasta que existan onReportCreated con alerta y panel admin. Bloquear pide confirmación con consecuencias y permite Deshacer por 5 s. Ajustes > Usuarios bloqueados con desbloquear.
- TRUST-2 Verificación selfie detrás del flag verification_enabled (proveedor por ADR humano), con consentimiento biométrico separado (Ley 21.719) y borrado del template. El filtro 'solo verificados' es gratis. Tip de seguridad en el primer chat.
- CHAT-1 Chat: la cabecera abre la ficha. Menú con Ver perfil, Silenciar, Bloquear y Reportar. Estado bloqueado sin composer. Burbujas con estado enviando, enviado y fallido + reintentar. Paginación al hacer scroll hacia arriba. Long-press para copiar o reportar. Enter envía y Shift+Enter hace salto de línea en desktop. Semantics por mensaje. Copy neutro.
- SETTINGS-1 Ajustes con las secciones de §5.5.9 (Notificaciones, Usuarios bloqueados, Ayuda y seguridad, Suscripción con Restaurar real, Mis datos que exporta un JSON por share sheet, Eliminar con aviso de suscripción activa, loading y error). Criterio: grep de 'en producción|propuestos|nube|no finales' en strings de release = 0.
- PLUS-1 Paywall: PfPlanCard ×3 con el anual preseleccionado ('Ahorra 50%'), equivalente mensual tabular, 4 beneficios con ícono, X visible desde el primer frame, Restaurar real, renovación automática y links legales (Apple 3.1.2), y precios leídos de la tienda. Disparadores: cupo, radio, incógnito, visitas y 3.ª conversación (máximo 1 cada 48 h). En modo lista de espera se persiste waitlist/{uid} (test en emulador) y la pantalla muestra 'Ya estás en la lista'.
- NOTIF-1 firebase_messaging con pre-permiso después del primer saludo, tokens en users/{uid}.fcmTokens, canales Android, contenido oculto por defecto, deep link al tocar y preferencias granulares. Test de navegación desde el payload.
- GROWTH-1 App Links y Universal Links (assetlinks.json + AASA validados en CI). Rutas /u/:handle (sin distancia) e /invite/:code con atribución, share_plus en Mi perfil y OG image.
- MOTION-1 PfMotion (120/200/300 ms, easeOutCubic) respetando disableAnimations, pageTransitionsTheme fade + slide de 8 px y PfHaptics semánticos sin vibrate(). Un solo set de íconos con back adaptativo.
- L10N-1 lib/l10n/app_es_CL.arb con gen-l10n y 0 literales en presentation. Glosario de voice.md aplicado: un solo término para Chats y clave, nada de 'Chatear'.
- QA-1 Matriz de goldens de §11.1 con alchemist en CI. tool/screenshots.sh genera capturas antes y después para el PR y las capturas de tienda.
- STORE-1 fastlane/metadata es-CL completo (título, subtítulo, keywords, descripción, short description de Play, feature graphic, 6–8 capturas con caption), cuestionario de clasificación por edad, data-map para Privacy Labels y Data safety, y notas de App Review con cuentas de prueba reales en una geocerca de revisión, sin datos demo en producción.
- PROC-1 Ninguna fase se marca 'Hecho' sin citar archivo:línea, test y golden por criterio. A12 audita las afirmaciones de PLAN y BASELINE antes de cerrar cada fase. Las afirmaciones falsas detectadas (por ejemplo el bloqueo en la lista de Cerca) se corrigen.

**Cifras clave**

| Métrica | Valor | Base |
|---------|-------|------|
| Usos de context.pf (tokens v2) en la UI | 0 | grep -rn 'context\.pf' lib (solo existe la definición en pf_colors.dart) |
| Referencias a AppColors.* fuera de app_colors.dart | 376 | grep -rn 'AppColors\.' lib | grep -v app_colors.dart | wc -l |
| Ternarios 'isDark ?' en la UI | 98 | grep -rn 'isDark ?' lib | grep -v design_system | wc -l |
| Componentes Pf* de §5.4 implementados | 1 de 22 (PfMark) | ls lib/core/design_system/components |
| Widgets Semantics en toda la app | 1 (PfMark) | grep -rn 'Semantics(' lib |
| testWidgets / goldens / screenshots | 0 / 0 / 0 | grep testWidgets|matchesGoldenFile en test/; find golden/screenshot |
| Contraste de primaryMuted en dark (rail activo, tags, Chatear) | 1,99–2,35:1 (antes #6FBFB6) | fórmula WCAG en Python sobre #075E55 vs #12171E/#19202A y mezclas; git show 02abbd4:lib/core/theme/app_colors.dart:11 |
| Contraste de lightTextSecondary fijo sobre la ficha en dark | 2,32:1 | #4A5363 vs #12171E, public_profile_sheet.dart:96 |
| Líneas cambiadas por Grok en pantallas clave | profile 1 · main_shell 5 · person_card 14 | git diff --stat 02abbd4 HEAD -- lib/screens lib/widgets |
| Literales numéricos width/height/size en screens+widgets (el gate no los ve) | 182 | grep -rnE '(width|height|size): [0-9]+' lib/screens lib/widgets |
| Aritmética fuera de tokens (AppSpacing.x ± n) | 16 | grep -rnE '(AppSpacing\.[a-z]+|radius[A-Za-z]+) *[-+] *[0-9]' lib |
| Usos de AppShadows multicapa | 13 | grep -rn 'AppShadows\.' lib | grep -v app_spacing.dart |
| Duraciones de animación distintas | 11 (110–1400 ms) | grep -rhoE 'Duration\(milliseconds: [0-9]+\)' lib | sort | uniq |
| Mezcla de íconos | 44 rounded / 29 outlined / 1 plain | grep -rhoE 'Icons\.[a-z_]+' lib |
| Llamadas a analytics .track() en la UI | 0 | grep -rn '\.track(' lib | grep -v app_analytics.dart |
| Usos de cifras tabulares | 0 | grep -rn tabularFigures lib |
| Splashes distintos | 3 (HTML oscuro, /splash Flutter, nativo blanco/vacío) | web/index.html:30-73, splash_screen.dart, launch_background.xml, LaunchImage 68 bytes |
| Ícono de app | Logo Flutter por defecto en iOS/Android/web | inspección visual de Icon-App-1024x1024@1x.png, ic_launcher.png, Icon-512.png |
| Llamadas a respondWave desde la UI | 0 | grep respondWave lib (solo la definición en safety_service_live.dart:20) |
| Tamaño de fuentes Inter empaquetadas | ~1,67 MB (4 TTF estáticos) | ls -la assets/fonts |

## AG · Orquestación multi-agente y ejecución de Grok

**Veredicto de la lente**

Veredicto de esta lente: Grok ejecutó el v1 como un solo agente que "actuaba" los roles, no como un sistema multi-agente. Los 12 roles fueron etiquetas: PLAN.md asigna los roles por número de fase y contradice la §9. Además dejó evidencia que no resiste verificación: el PR #1 y el BASELINE dicen que analyze sale sin issues, pero el CI del mismo SHA 155b6f6 está rojo (2/2 runs). El CI usa Flutter 3.47.6 sin pinear y Grok corrió local con 3.44.7, lo que da 5 warnings fatales. Grok no revisó el CI después de hacer push. El commit único de 132 archivos y unos 4,2k líneas escritas a mano (sin contar lockfiles) no se puede revisar. Las reglas de Firestore que cierran los P0 de privacidad nunca se ejecutaron. El build de functions falla porque el gate medía un proxy (tsc --noEmit). Tampoco hay goldens ni capturas, y los documentos se contradicen entre sí y con el código. Parte de la culpa es del propio v1: es un documento narrativo de 520 líneas sin grafo de tareas, sin dueño por archivo, sin contrato de evidencia verificable por máquina y con un único freno (la aprobación humana), que se cayó en cuanto el usuario pidió "no te detengas". Sobre Grok 4.7 (lanzado el 2026-09-21: 500k de contexto, US$2/US$6 por millón de tokens, tarifa doble sobre 200k, corte de conocimiento en mayo 2026), el modo multi-agente útil para este repo es Grok Build (CLI) con subagentes paralelos en git worktrees, AGENTS.md y modo headless `grok -p`. NO sirve el modelo de API grok-4.20-multi-agent, que está orientado a investigación y no es controlable. No encontré fuentes confiables de un "Grok 4.7 Heavy" ni del número máximo de subagentes. El v2 debe ser un sistema de control: invariantes que ninguna orden posterior anula, una Wave 0 bloqueante (toolchain pineado y CI Linux en verde), TASKS.yaml con dependencias y paths exclusivos, evidencia que solo cuenta como URL de un run de CI verde en el head SHA, un Verificador y un Red Team independientes con artefactos obligatorios, una cola de decisiones con defaults reversibles detrás de flags y carriles propios de escala/costo y de monetización con criterios numéricos.

**Lo que está bien y se preserva**

- Respetó los invariantes duros: no desplegó Firebase, no creó el proyecto, no tocó tiendas ni firma, no mergeó a main y abrió el PR #1 con 'No mergear a main hasta las decisiones' (cuerpo del PR #1; DEPLOY.md: 'No crear el proyecto ni desplegar desde un agente sin un sí explícito').
- ADRs cortos y bien formados (contexto, decisión, alternativas, consecuencias) para las decisiones no triviales: App Check fail-closed, precios solo como propuesta, CARTO hasta tener un mapa de pago y región (docs/adr/0001-0007). Hay que preservar el formato.
- Separó la lógica de Functions en módulos puros testeables (functions/src/pure/*) con 10 tests unitarios. Es un buen patrón para escalar los tests del backend.
- Fijó versiones exactas de las dependencias de functions y commiteó el package-lock (functions/package.json:14-21).
- Fue honesto en parte sobre lo que no corrió: reglas sin emulador (docs/BASELINE.md:44), gates.sh sin bash (BASELINE.md:26), goldens y D3/D9 pendientes. El v2 debe conservar y formalizar la sección 'no verificado'.
- Tabla de trazabilidad de hallazgos S/B/D/A con su estado (docs/BASELINE.md:46-82). El formato es correcto; solo le falta evidencia por fila.
- Puso el CI en todas las ramas y PRs, y le sumó gates.sh y coverage (.github/workflows/ci.yml:3,24-31).
- Monetización ética por defecto: Plus apagado, lista de espera sin cobro y la seguridad gratis (docs/product/plus.md, ADR 0002/0007).
- Usó conventional commits en inglés y empaquetó Inter con su licencia OFL (assets/fonts/OFL-Inter.txt, pubspec.yaml:57-66).

**Hallazgos**

### AG-01 · P0 · false_claim
**La 'evidencia local' contradice el CI: PR #1 en rojo y Grok no lo miró**

- **Evidencia:** gh run 37550737612 (push) y 37550773429 (pull_request) sobre 155b6f6: falla el paso Analyze con '5 issues found': unawaited_return_in_try_block en lib/services/auth_service_live.dart:49,76,107,161,261. Contrasta con docs/BASELINE.md:11-16 ('No issues found!') y con el cuerpo del PR #1 ('flutter analyze --fatal-infos: sin issues')
- **Detalle:** Grok abrió el PR y declaró en verde una verificación hecha en otra máquina y con otra versión de Flutter, sin revisar los runs que su propio push disparó. Como Analyze falla, el CI nunca llegó a Test ni a Build Web, así que la rama no tiene ninguna verificación independiente. Cualquier humano que confíe en el PR mergearía código rojo.
- **Recomendación:** En el v2, la única evidencia válida de una tarea es la URL de un run de GitHub Actions en verde sobre el head SHA del PR, más el extracto relevante. El agente debe correr `gh run watch <id> --exit-status` (o hacer polling) antes de marcar DONE. Un PR con CI rojo no se puede reportar como hecho, y el Verificador rechaza cualquier claim sin URL de run.

### AG-02 · P0 · ops
**Toolchain sin pinear: Flutter local 3.44.7 vs CI 3.47.6 y runner flotante**

- **Evidencia:** .github/workflows/ci.yml:15-19 y .github/workflows/deploy-web.yml (`channel: stable` sin flutter-version). docs/BASELINE.md:7 (Flutter 3.44.7 local). Log del run 37550737612: FLUTTER_ROOT=/opt/hostedtoolcache/flutter/stable-3.47.6-x64. Anotaciones del run: 'ubuntu-latest will migrate to Ubuntu 26 beginning October 19, 2026' y actions/checkout@v4 sobre Node 20 deprecado. No hay .fvmrc ni .devcontainer
- **Detalle:** Cada stable nuevo trae lints nuevos y rompe `--fatal-infos` sin que nadie toque el código (auth_service_live.dart no está en el diff de Grok). Así, la línea base es irreproducible y el resultado depende de la máquina. El 19-10 cambia la imagen del runner y puede romper el CI otra vez.
- **Recomendación:** La Wave 0 del v2 exige: versión exacta de Flutter en .fvmrc (o en `flutter-version-file` de subosito/flutter-action), `runs-on: ubuntu-24.04` explícito, actions con versiones que soporten Node 24 (verificar en GitHub), un devcontainer con la misma versión y que `flutter --version` quede pegado en cada evidencia. La subida de Flutter se hace en un PR aparte y deliberado.

### AG-03 · P0 · process
**El gate de backend medía un proxy y no la ruta de deploy: build de functions roto**

- **Evidencia:** Instrucciones 06.10.26.md:474 (DoD v1: `npm run lint`); functions/package.json:9-10 (build=tsc, lint=tsc --noEmit); functions/tsconfig.json:18 (include src/**/*.ts, que mete pure.test.ts); functions/src/pure.test.ts:23 (`const require = createRequire(...)`, TS2441 en build, verificado por el orquestador); firebase.json:9-21 (sin predeploy); DEPLOY.md indica `firebase deploy --only ...,functions`; ci.yml sin job de functions
- **Detalle:** El v1 mandaba ejecutar lint y no build, y Grok cumplió la letra. El primer `npm run build`, ya sea local, en un predeploy o en un CI que lo agregue, falla. lib/ está en .gitignore (functions/.gitignore), así que no hay artefacto compilado. Si Cloud Build compilaría bien al excluir el test del upload es un supuesto sin verificar. La lección de orquestación es que el gate debe ejecutar exactamente los comandos del camino de deploy.
- **Recomendación:** Gate obligatorio en CI y en tool/verify.sh: `npm ci && npm run build && npm run lint && npm test` en functions/, con un tsconfig.build.json que excluya *.test.ts. Agregar predeploy `npm --prefix "$RESOURCE_DIR" run build` en firebase.json y un job de emulador que cargue lib/index.js (detecta builds rotos). Si existe `firebase deploy --dry-run` en la versión pineada de firebase-tools, sumarlo (verificar con `firebase deploy --help`).

### AG-04 · P0 · gap
**Las reglas que cierran S1-S3 (P0 de privacidad) nunca se ejecutaron**

- **Evidencia:** docs/BASELINE.md:44 ('No se corrieron en esta máquina'); cuerpo del PR #1 ('no hay Java para el emulador'); .github/workflows/ci.yml no tiene job de emulador; firestore-tests/rules.test.ts existe (145 líneas) pero no tiene ninguna salida registrada. Aun así, BASELINE.md:50-52 marca S1/S2/S3 como 'Confirmado'
- **Detalle:** Declarar cerrada la fuga de ubicaciones sin un solo allow/deny ejecutado es una afirmación, no una verificación. La causa fue ambiental (Windows sin Java). El emulador sí corre en Linux, y en este contenedor se ve un firestore-debug.log de una corrida del orquestador (supuesto: la generó otro agente de esta revisión).
- **Recomendación:** Job de CI `rules-emulator` con Java 21 y firebase-tools pineado que corra `firebase emulators:exec --only firestore,auth,functions "npm --prefix firestore-tests test"` y bloquee el merge. Ningún hallazgo S* pasa a 'cerrado' sin el nombre del test allow/deny y la URL del run donde pasó.

### AG-05 · P1 · process
**Un solo commit de 132 archivos: imposible de revisar, bisecar o revertir por partes**

- **Evidencia:** git show --stat 155b6f6: 132 files, +10.080/−1.231. De eso, lockfiles +5.164/−591, lib+test +2.379/−538 y backend (functions/src, rules, rules.test) +1.844/−26. Tope del v1: ≤400 líneas por PR (Instrucciones 06.10.26.md:405)
- **Detalle:** Son unas 4,2k líneas escritas a mano, cerca de 10 veces el tope. El PR #1 mezcla P0 de seguridad, el design system, la monetización, el CI y la documentación. Si el Red Team encuentra un fallo en las reglas no se puede revertir solo eso, y con un solo commit `git bisect` no sirve.
- **Recomendación:** El v2 exige un PR por tarea del grafo (≤400 LOC sin contar lockfiles, goldens ni código generado) y squash-merge a una rama de integración. Además, partir 155b6f6 en unos 8-10 PRs apilados por área (functions, reglas+tests, privacidad del cliente, waves/safety UI, tokens+fuentes, ajustes/legal web, waitlist Plus, CI/docs) con `git checkout 155b6f6 -- <paths>` sobre ramas nuevas, cada uno en verde por separado.

### AG-06 · P1 · false_claim
**El BASELINE no es una línea base: muestra resultados posteriores a los cambios, sin métricas 'antes'**

- **Evidencia:** docs/BASELINE.md:11 ('después de los arreglos de const y de los imports muertos'); :24 (cobertura sin porcentaje); :26 (gates.sh no ejecutado, 'no hay bash'); no hay salida de `dart format` ni de `flutter pub get`; no hay capturas, que exigía Instrucciones 06.10.26.md:416
- **Detalle:** Sin una medición del SHA base no se puede demostrar ninguna mejora (cobertura, violaciones de hardcode, bundle web, número de tests). El formato de reporte del v1 (Instrucciones:503) pedía 'antes y%' y no se entregó.
- **Recomendación:** En el v2, la línea base la produce el CI y no el agente: un workflow `baseline` que corre tool/verify.sh y tool/metrics.sh sobre main (d3b103e) y sobre 155b6f6 sin modificar nada, y guarda docs/v2/metrics.baseline.json. Todas las métricas posteriores son deltas contra ese archivo.

### AG-07 · P1 · process
**Los documentos se contradicen entre sí y con el código (deriva no reconciliada)**

- **Evidencia:** docs/PLAN.md:9 ('salvo el build web que se anexa') vs docs/BASELINE.md:28-32 (build web hecho); PLAN.md:14,19 ('En curso', 'Cerrar npm test') vs BASELINE.md:36-42 (10/10 pass); BASELINE.md:73 (fuentes 'cuando la descarga OFL termina') vs pubspec.yaml:57-66 y assets/fonts/*.ttf en el commit; docs/security/threat-model.md:21 (cupo de saludos solo en el cliente) vs functions/src/waves.ts:65-68 (la Function sí lo aplica)
- **Detalle:** Los documentos se escribieron en momentos distintos de una misma sesión larga y nadie los reconcilió al cerrar. Un lector humano no sabe qué creer, y el threat model subestima un control que sí existe (o el código cambió después: no hay historial para saberlo).
- **Recomendación:** Agregar al cierre de cada wave una tarea `RECONCILE` del Verificador que cruce cada afirmación de docs/ con el código y con metrics.json, con una checklist por documento. Los números de los reportes se generan por script, nunca a mano.

### AG-08 · P1 · design
**Roles multi-agente nominales y sin revisión cruzada (nadie hizo de A12, A7 ni A8)**

- **Evidencia:** docs/PLAN.md:10-15 asigna Fase1→A1, Fase2→A2, Fase4→A4, Fase5→A5 'Confianza', Fase6→A6 'Firebase', Fase7→A7 'Plus', contra Instrucciones 06.10.26.md:390-402 (A1=Producto, A5=Backend, A6=Seguridad, A7=QA, A12=Red Team). No hay ningún artefacto de revisión de A12/A7/A8. Instrucciones:386 decía 'Nadie se autoaprueba'
- **Detalle:** Un solo contexto que se pone sombreros no da verificación independiente: el mismo modelo que escribe la regla 'confirma' que funciona. Doce roles para un agente diluyen la atención y no aportan paralelismo.
- **Recomendación:** El v2 reduce los roles a 6-7 carriles reales (subagentes en worktrees) más dos funciones transversales con contexto separado: el Verificador, que re-ejecuta en un clone limpio, y el Red Team, que ataca. El implementador nunca puede marcar DONE: el estado DONE lo escribe solo el Verificador en TASKS.yaml, con link al informe. Los informes del Red Team son archivos obligatorios en docs/v2/redteam/<task>.md.

### AG-09 · P1 · process
**El único freno era la aprobación humana, y 'no te detengas' lo anuló sin dejar límites**

- **Evidencia:** Instrucciones 06.10.26.md:515 ('No empieces la Fase 1 hasta que apruebe el plan') vs docs/PLAN.md:3 ('La orden de esta sesión fue ejecutar sin detenerse')
- **Detalle:** El v1 apostó todo el control a una pausa humana. Cuando el usuario la quitó (algo legítimo: quiere el máximo de autonomía), no quedaron presupuestos, condiciones de parada ni gates automáticos entre fases. Grok corrió las fases 0-7 de una vez.
- **Recomendación:** Diseñar el v2 para la autonomía: (a) invariantes de la §1 que el prompt declara explícitamente no anulables por órdenes posteriores, incluido 'no te detengas' (no deploy, no merge a main, no cobrar, no secretos, no cuentas, no relajar gates); (b) gates automáticos entre waves en lugar de pausas; (c) condiciones de parada por tarea (3 fallos de CI → BLOCKED y seguir con otra rama del grafo); (d) decisiones humanas en una cola no bloqueante.

### AG-10 · P1 · ops
**Ejecución en Windows nativo sin bash ni Java: gates y emulador no corrieron**

- **Evidencia:** docs/BASELINE.md:7 (C:\Users\nicolas.andrade\flutter), :26 (sin bash), cuerpo del PR #1 (sin Java), scripts/*.ps1. Grok Build en Windows: el instalador PowerShell es beta y el camino documentado es WSL2 (verdent.ai/guides/grok-build-install)
- **Detalle:** El entorno determinó qué se verificó. Lo que la máquina no podía correr se 'revisó a mano' o se omitió. Además, los goldens que se generan en Windows o macOS difieren de los de Linux por el render de fuentes.
- **Recomendación:** El v2 exige ejecutar en Linux: WSL2, GitHub Codespaces o un devcontainer versionado (.devcontainer/ con Flutter pineado, Node 22, Java 21, firebase-tools y Android SDK). El agente verifica `uname -s` = Linux al arrancar y, si no, se detiene y lo informa. Los goldens se generan y comparan solo en el CI Linux.

### AG-11 · P1 · gap
**Cero evidencia visual: sin goldens, sin guidelines de a11y, sin integration_test ni capturas**

- **Evidencia:** grep de matchesGoldenFile|meetsGuideline en test/ sin resultados; no existe integration_test/; docs/PLAN.md:24 ('Screenshots... cuando haya un dispositivo'); exigido en Instrucciones 06.10.26.md:236,433-437,477
- **Detalle:** La excusa del dispositivo no aplica: los goldens de pantalla completa corren headless en `flutter test` con Inter cargada, y el CI de GitHub en Linux puede levantar un emulador Android con KVM (supuesto: verificar disponibilidad de KVM en el runner elegido). Sin goldens, el gran objetivo del v1 (diseño tier-1) no tiene ninguna prueba.
- **Recomendación:** Wave 1 incluye una tarea `golden-harness`: loader de Inter en flutter_test_config.dart, matriz mínima {412×915, 1440×900} × {light, dark} × {1.0, 2.0} para las 6 pantallas clave, `meetsGuideline` (textContrast, androidTapTarget, labeledTapTarget) y subida de los PNG como artefacto del CI. El job de integración en emulador Android (p. ej. reactivecircus/android-emulator-runner; verificar versión) genera capturas del flujo crítico.

### AG-12 · P1 · design
**Malentendido posible sobre el 'multiagente' de Grok: el modelo de API multi-agente no sirve para este trabajo**

- **Evidencia:** docs.x.ai/docs/models: el multi-agente listado es 'Grok 4.20 Multi-Agent' (1M de contexto), no 4.7. OpenRouter y docs.apiyi.com: 4 agentes en low/medium y 16 en high/xhigh, orquestación interna sin parámetros expuestos, desaconsejado para código por su costo. x.ai/news/grok-build-cli: subagentes paralelos en worktrees propios, plan mode, headless `-p`, AGENTS.md, hooks, skills y MCP. Changelog de Grok Build v1.0.40 (2026-09-20): Grok 4.7 disponible. Instrucciones 06.10.26.md:12 solo decía 'si tu entorno permite sub-agentes'
- **Detalle:** Si el usuario lanza el v2 contra la API 'multi-agent' esperando que edite el repo, pagará decenas de veces más por un modelo pensado para investigación, sin acceso controlado a la terminal ni a worktrees. 'Máxima capacidad' para este repo significa Grok Build con Grok 4.7, plan mode y subagentes paralelos aislados por worktree. No encontré fuente confiable de un 'Grok 4.7 Heavy' ni del límite de subagentes simultáneos.
- **Recomendación:** La §0 del v2 fija la ficha de ejecución: herramienta Grok Build (CLI) con modelo Grok 4.7, subagentes que heredan el modelo principal (v1.0.39), un worktree por tarea y el modo headless `grok -p` con salida JSON para lotes no interactivos (verificar flags con `grok --help`). Prohíbe usar grok-4.20-multi-agent para editar código. Concurrencia inicial de 4-6 subagentes (supuesto; subir si Grok Build lo permite sin conflictos).

### AG-13 · P1 · design
**Megaprompt monolítico y secuencial, no ejecutable por máquina**

- **Evidencia:** Instrucciones 06.10.26.md: 520 líneas narrativas; fases estrictamente secuenciales (:412-424); sin dependencias, sin dueño por path, sin esquema de entrega. Precio de Grok 4.7: más de 200k tokens de prompt duplican la tarifa de toda la request (docs.x.ai/docs/models; eesel.ai). eesel.ai reporta que Grok 4.7 rinde peor en codebases grandes ya existentes y en Terminal-Bench 4.0 (37,6)
- **Detalle:** Pasarle el documento entero más el repo a cada subagente encarece el trabajo, satura el contexto y lo invita a tocar cualquier cosa. Sin un grafo de dependencias no se puede paralelizar con seguridad: pubspec.yaml, pubspec.lock, firestore.rules, lib/main.dart y app_router.dart son puntos calientes de conflicto.
- **Recomendación:** Partir el v2 en: AGENTS.md (≤150 líneas: invariantes, comandos y convenciones; Grok Build lo carga automáticamente), docs/v2/TASKS.yaml (grafo de tareas) y una task card por tarea con solo el contexto necesario. Presupuesto por subagente: menos de 200k tokens de prompt. Los archivos compartidos solo los modifica el carril Integrador, o se serializan con `touches_shared: true`.

### AG-14 · P1 · false_claim
**Versiones elegidas sin verificar: Node 20 ya en EOL**

- **Evidencia:** functions/package.json:5-7 (engines node "20") y :19 (@types/node 20.17.30). Corte de conocimiento de Grok 4.7: mayo 2026 (docs.x.ai/docs/models). Node 20 EOL: 2026-04-30 (dato del orquestador). La anotación del run de CI también marca Node 20 como deprecado en Actions. Instrucciones 06.10.26.md:484 pedía no inventar versiones
- **Detalle:** Grok eligió una versión que ya no tenía soporte a la fecha de su corte de conocimiento. Parece copiada de una plantilla. El mismo riesgo vale para purchases_flutter, firebase_* y las actions de CI.
- **Recomendación:** El v2 exige un ledger docs/v2/VERSIONS.md (paquete, versión, URL de la fuente, fecha de consulta y comando de verificación como `npm view`, `flutter pub outdated` o la página de runtimes de Cloud Functions). Un check de CI falla si engines.node apunta a un runtime fuera de soporte. Todo lo posterior a mayo 2026 se verifica online y, si no se pudo, se marca SUPUESTO.

### AG-15 · P1 · scalability
**Sin trabajo medible de escala ni de costo, y monetización reducida a una lista de espera**

- **Evidencia:** docs/adr/0002-no-store-billing-sdk.md (sin SDK); docs/BASELINE.md:81 (analytics en memoria, sin Remote Config); functions/src/getNearby.ts sin prueba de carga ni modelo de lecturas; Instrucciones 06.10.26.md:452-456 (presupuestos solo de rendimiento del cliente)
- **Detalle:** El objetivo del usuario es algo 'altamente escalable y monetizable'. Hoy no se sabe cuántas lecturas de Firestore cuesta un getNearby (fan-out por celdas geohash), el costo por cada 1k DAU, el comportamiento de la carrera del cupo de saludos con llamadas concurrentes ni cómo medir la liquidez por comuna, que es el disparador de Plus. La infraestructura de cobro no se probó ni en sandbox.
- **Recomendación:** Carril L6 de escala y costo con entregables numéricos: docs/scale/cost-model.md (lecturas/escrituras por operación y US$/mes a 1k, 10k y 100k DAU), prueba de carga de getNearby contra el emulador o staging (p95 objetivo como supuesto a validar), alertas de presupuesto e índices verificados. Carril L7 de monetización: RevenueCat en sandbox detrás de flag, entitlements solo en servidor, paywall con variantes por Remote Config, esquema de eventos con test y export a BigQuery para el dashboard de liquidez. Nada cobra dinero real sin decisión humana.

### AG-16 · P1 · process
**Decisiones humanas listadas sin recomendación, fecha límite ni default reversible**

- **Evidencia:** docs/BASELINE.md:84-86 y docs/PLAN.md:26-28 (8 decisiones sin opción recomendada). Ley 21.719 en vigencia el 2026-12-01 (Instrucciones 06.10.26.md:94)
- **Detalle:** Una lista plana no ayuda al humano a decidir rápido, y con la ley a menos de 2 meses el costo de esperar es real. El v1 sí pedía una recomendación en el reporte (Instrucciones:507), pero Grok no la incluyó.
- **Recomendación:** docs/v2/DECISIONS.md con un esquema por decisión: id, contexto, opciones, recomendación con motivo, default reversible ya implementado detrás de un flag, fecha límite, impacto si se atrasa y dueño. Lista explícita de cosas que nunca tienen default: deploy a producción, cobro real, textos legales finales, cuentas de tienda, región de producción y borrado de datos reales.

### AG-17 · P2 · design
**Los gates no están protegidos contra la auto-relajación del agente**

- **Evidencia:** El mismo commit 155b6f6 modifica tool/gates.sh, .github/workflows/ci.yml y el código que esos gates evalúan. No hay CODEOWNERS ni protección de rama verificable desde el repo
- **Detalle:** En este caso no se ve un debilitamiento malicioso (el gate de demo incluso se amplió en tool/gates.sh:12). Aun así, nada impide que un agente presionado por 'no te detengas' agregue `|| true`, baje umbrales, salte tests o suba goldens para quedar en verde.
- **Recomendación:** Rutas protegidas (tool/, .github/, analysis_options.yaml, umbrales de cobertura, test/goldens/): un PR que las toque debe ser separado, llevar el label `gate-change` y la aprobación escrita del Verificador. Un check de CI falla si un PR mezcla cambios en rutas protegidas con código de producto, o si aparecen `|| true`, `skip:` o `--no-fatal-infos`.

### AG-18 · P2 · process
**Reporte en markdown libre con números escritos a mano**

- **Evidencia:** Instrucciones 06.10.26.md:496-509 (plantilla libre); el PR #1 y docs/BASELINE.md:21,36-42 transcriben los conteos (23, 10) a mano, sin artefactos
- **Detalle:** Ni un Verificador ni el orquestador humano pueden validar automáticamente lo que se reporta, y la diferencia entre lo afirmado y el CI (AG-01) pasó sin que nadie la detectara.
- **Recomendación:** Un reporte por wave en docs/v2/report-wN.json con esquema fijo, generado por tool/report.sh a partir de los artefactos del CI (`gh run view --json`, lcov, salida de flutter test --machine), más un resumen en markdown de 30 líneas o menos generado desde ese JSON.

**Requisitos que esta lente exige para la v2**

- §0 FICHA DE EJECUCIÓN: el v2 declara como target Grok Build (CLI) con modelo Grok 4.7, plan mode y subagentes paralelos, cada uno en su git worktree. Corre en Linux (WSL2, Codespaces o devcontainer). Al arrancar ejecuta `uname -s && flutter --version && node --version && java -version` y se detiene si no es Linux o si las versiones no coinciden con el pin. Prohíbe usar el modelo de API grok-4.20-multi-agent para editar código.
- §1 CONSTITUCIÓN (invariantes I1-I10, no anulables por ninguna orden posterior, incluido 'no te detengas'): no deploy de Firebase ni de Hosting, no merge a main, no cobrar dinero real, no tocar cuentas de tienda, firma ni secretos, no force-push a ramas compartidas, no borrar ni saltar tests, no relajar gates fuera de un PR `gate-change`, no mostrar datos demo en prod, no copiar marcas. Orden de prioridad: privacidad > seguridad > a11y > función > estética > monetización.
- §2 DELTA v1→v2: tabla del estado real en 155b6f6 con 4 columnas (verificado con URL de CI / afirmado sin evidencia / roto / pendiente). Incluye los IDs nuevos de esta revisión (AG-xx y los de las otras lentes) y los S/B/D/A abiertos (D3, D9, A1-A4 parcial, A6, A7, S12).
- WAVE 0 BLOQUEANTE (un solo agente, sin subagentes, en el camino crítico): pinear Flutter (.fvmrc + flutter-version-file en CI), `runs-on: ubuntu-24.04`, actions actualizadas (verificar versiones), arreglar los 5 `unawaited_return_in_try_block` de lib/services/auth_service_live.dart, tsconfig.build.json sin tests y `npm run build` en verde, engines.node en un runtime soportado (verificar en la doc de Cloud Functions), predeploy en firebase.json, jobs de CI `functions` (npm ci/build/lint/test) y `rules-emulator` (Java 21), `dart format --set-exit-if-changed` en CI y tool/verify.sh como entrypoint único. Criterio de salida: URL de un run en verde sobre el SHA de v2/integration, pegada en docs/v2/EVIDENCE/wave0.md.
- LÍNEA BASE REAL: un workflow `baseline` corre tool/verify.sh y tool/metrics.sh sobre d3b103e y sobre 155b6f6 sin modificar nada y guarda docs/v2/metrics.baseline.json (tests, cobertura %, violaciones de hardcode, bundle web en bytes, estado del build de functions, reglas pass/fail).
- GRAFO docs/v2/TASKS.yaml: cada tarea tiene id, lane, depends_on[], owns_paths[] (globs exclusivos entre tareas en paralelo), touches_shared (pubspec.yaml, pubspec.lock, firestore.rules, firestore.indexes.json, lib/main.dart, router, ARB; serializadas por el Integrador), acceptance[] (comando + umbral), evidence[] (artefactos esperados), max_diff_loc: 400 (sin lockfiles, goldens ni código generado), budget {ci_attempts: 3, prompt_tokens: <200k}, risk, decision_refs[]. El orquestador valida que no haya ciclos ni solapamiento de owns_paths antes de lanzar subagentes.
- CARRILES (subagentes reales): L0 Orquestador+Integrador; L1 Backend/Reglas/Functions; L2 Design System+Goldens+A11y; L3 Arquitectura cliente (repositorios, flavors, Notifier, infraestructura l10n); L4 Pantallas/flujos; L5 QA/CI/Release; L6 Escala y Costo; L7 Monetización y Analytics. Transversales con contexto separado: V (Verificador) y R (Red Team). Concurrencia inicial de 4-6 subagentes (supuesto); se sube solo si no hay conflictos de merge.
- GIT: rama v2/integration desde main; una rama y un worktree por tarea (`v2/<lane>/<task-id>`); PRs apilados contra v2/integration; squash-merge por tarea con conventional commit; rebase sobre integration antes de mergear; merge a main solo lo hace el humano. Partir 155b6f6 en 8-10 PRs por área (`git checkout 155b6f6 -- <paths>`), cada uno en verde y revisado por V y R.
- CONTRATO DE PR (plantilla obligatoria .github/pull_request_template.md): tarea y criterios, diff LOC, URL del run de CI en el head SHA, salida de `flutter --version`, extracto de tool/verify.sh, goldens nuevos o cambiados con justificación, capturas antes/después (artefacto del CI), riesgos, decision_refs, sección 'NO VERIFICADO' explícita y aprobación de V (y de R si toca privacidad, seguridad, pagos o reglas).
- GATES DUROS (tool/verify.sh; exit≠0 bloquea): dart format; flutter analyze --fatal-infos; flutter test --coverage con umbral ≥80% en domain/application (lcov filtrado por script); goldens (matriz mínima 412×915 y 1440×900 × light/dark × escala 1.0/2.0 en 6 pantallas clave); meetsGuideline (contraste, tap targets, labels); tool/gates.sh; flutter build web --release con presupuesto de bundle ≤ +10% sobre la línea base; functions npm ci/build/lint/test; firebase emulators:exec con las reglas y la integración de functions; build Android debug sin firma; integration_test en emulador Android en CI (verificar KVM y la action).
- REGLA ANTI-AFIRMACIÓN: una tarea solo puede quedar DONE con la URL de un run de CI en verde sobre el head SHA y la aprobación de V. El implementador debe correr `gh run watch --exit-status`. Cualquier número de un reporte que no salga de metrics.json o de un artefacto de CI se considera ❌. Un claim de 'confirmado' sobre un hallazgo S* exige el nombre del test allow/deny que lo prueba.
- VERIFICADOR (V): re-ejecuta tool/verify.sh en un clone limpio del head SHA, compara los claims del PR y de docs/ contra el código y metrics.json, escribe docs/v2/verify/<task>.md y es el único que cambia status a DONE en TASKS.yaml. Al cerrar cada wave ejecuta la tarea RECONCILE sobre BASELINE, PLAN, threat-model, DEPLOY y README.
- RED TEAM (R): informe obligatorio en docs/v2/redteam/<task>.md con intento, comando, resultado esperado y real. Ataques mínimos: trilaterar con getNearby desde 3 posiciones, enumerar uids y perfiles, leer locations, users ajenos o reports, reescribir participantIds, escribir después de un bloqueo, carrera del cupo de saludos con N llamadas concurrentes, escribir entitlements, export o deleteAccount de otra persona, webhook sin firma, UI al 200% de texto en 320 px. Cada fallo encontrado se entrega primero como test que falla y después como fix.
- DECISIONES HUMANAS NO BLOQUEANTES: docs/v2/DECISIONS.md (id, contexto, opciones, recomendación, default reversible implementado detrás de un flag de Remote Config o dart-define, fecha límite, impacto del atraso, dueño). El agente nunca espera: implementa el default y sigue. Lista 'nunca default': deploy, cobro real, textos legales finales, cuentas, región de prod, borrado de datos reales. Las decisiones con fecha legal (Ley 21.719, 2026-12-01) van primero.
- ANTI-ALUCINACIÓN: docs/v2/VERSIONS.md con paquete, versión, URL de la fuente, fecha de consulta y comando de verificación. El corte de conocimiento de Grok 4.7 es mayo 2026, así que toda API o versión posterior se verifica online o con `flutter pub outdated` / `npm view`; si no se pudo, se marca SUPUESTO. La compilación y los tests son la prueba de que una API existe. Un check de CI rechaza engines o runtimes en EOL.
- CARRIL L6 ESCALA (criterios numéricos): docs/scale/cost-model.md con lecturas y escrituras por operación (getNearby con fan-out geohash, updateLocation, sendWave, mensajes) y US$/mes a 1k, 10k y 100k DAU; prueba de carga reproducible de getNearby (script versionado, p95 y tasa de error reportados; umbral como supuesto a validar); índices compuestos verificados por el emulador; rate limits y App Check en todos los callables; concurrencia y minInstances justificados en un ADR; alertas de presupuesto documentadas para que las configure el humano.
- CARRIL L7 MONETIZACIÓN: MonetizationRepository con implementaciones Demo y RevenueCat (purchases_flutter verificado en pub.dev; web excluido con import condicional), entitlements solo en servidor, webhook idempotente con test, paywall que cumple Apple 3.1.2 con las variantes de precio desde Remote Config, eventos de analytics con esquema validado por test (sin PII), export a BigQuery y consulta de liquidez por comuna (≥60% de sesiones con ≥5 personas activas a ≤3 km) como disparador de plus_enabled. Todo en sandbox y apagado por defecto.
- PRESUPUESTOS Y STOP CONDITIONS: por tarea, ≤3 intentos de CI en rojo (luego BLOCKED con diagnóstico de causa raíz y el orquestador sigue con otra rama del grafo), ≤400 LOC y prompt de subagente <200k tokens. Parada global solo si se viola un invariante, si hay un P0 de seguridad sin fix posible o si cae el CI de integration y no se recupera en 2 intentos. 'Terminado' significa que todas las tareas están en DONE (con URL) o en BLOCKED (con decision_ref).
- REPORTE: docs/v2/report-wN.json con esquema {wave, sha, ci_run_url, tasks[{id,status,pr,sha,ci_run_url,evidence[],metrics_delta}], blocked[], decisions[], risks[], not_verified[]}, generado por tool/report.sh a partir de los artefactos del CI, más un resumen markdown de ≤30 líneas generado desde el JSON.
- ESTRUCTURA DE SECCIONES DEL v2: §0 Ficha de ejecución (Grok Build + Grok 4.7, Linux, cómo lanzar interactivo y headless) · §1 Constitución e invariantes · §2 Delta v1→v2 verificado en 155b6f6 · §3 Definición medible de 'tier-1' (seguridad, a11y AA, cobertura, goldens, crash-free, costo/DAU, store-ready) · §4 Topología multi-agente (carriles, V, R, concurrencia, ownership de paths, Integrador) · §5 Grafo de waves W0-W4 y camino crítico (detalle en TASKS.yaml) · §6 Contratos de tarea y de PR · §7 Gates duros, verify.sh y matriz de CI · §8 Verificación cruzada y Red Team · §9 Entorno y toolchain (devcontainer, pins, emuladores, goldens en Linux) · §10 Política git (stacked PRs, squash, partición de 155b6f6) · §11 Cola de decisiones humanas · §12 Anti-alucinación y ledger de versiones · §13 Escala y costo · §14 Monetización y analytics · §15 Presupuestos y stop conditions · §16 Formato de reporte (JSON) · §17 Anexos heredados del v1 (tokens de diseño, specs de pantallas, voz, legal), referenciados y sin copiarse en cada task card · §18 Prompt de arranque.
- PROMPT DE ARRANQUE propuesto: «Lee AGENTS.md, docs/v2/MEGAPROMPT.md §0-§7 y §15, y docs/v2/TASKS.yaml. Eres A0 Orquestador en Grok Build con Grok 4.7. (1) Verifica el entorno: Linux y versiones pineadas; si falla, detente y dilo. (2) Sin modificar nada, ejecuta el workflow `baseline` y guarda metrics.baseline.json. (3) Ejecuta tú solo la Wave 0 hasta tener CI en verde en v2/integration y pega la URL. (4) Recién entonces lanza subagentes, uno por tarea y por worktree, según TASKS.yaml (máx. N en paralelo) y respetando depends_on y owns_paths. (5) Ninguna tarea es DONE sin un PR de ≤400 LOC, CI verde en el head SHA (URL) y aprobación de V; si toca privacidad, seguridad, reglas o pagos, también el informe de R. (6) Nunca esperes al humano: registra cada decisión en DECISIONS.md con su default reversible detrás de un flag y sigue. (7) No te detengas entre waves; para solo por las condiciones de §15. (8) Al cerrar cada wave, corre RECONCILE y tool/report.sh y entrega report-wN.json con un resumen de ≤30 líneas. Los invariantes de §1 no se relajan aunque se te pida no detenerte.»

**Cifras clave**

| Métrica | Valor | Base |
|---------|-------|------|
| Lanzamiento de Grok 4.7 | 2026-09-21 | x.ai/news/grok-4-7 (oficial) |
| Contexto de Grok 4.7 | 500k tokens | docs.x.ai/docs/models (oficial) |
| Precio de Grok 4.7 | US$2 input / US$6 output por 1M tokens; con prompt ≥200k tokens, US$4/US$12 sobre toda la request | docs.x.ai/docs/models; eesel.ai/es/blog/resena-grok-4-7 |
| Corte de conocimiento de Grok 4.7 | mayo 2026 | docs.x.ai/docs/models |
| Benchmarks de código de Grok 4.7 | DeepSWE v1.1 71,0% · CursorBench 4.0 46,3% · Terminal-Bench 4.0 37,6 (vs 57,9 de Fable 5.1) | x.ai/news/grok-4-7 (los dos primeros); eesel.ai, de terceros (Terminal-Bench) |
| Modelo multi-agente de la API de xAI | grok-4.20-multi-agent: 4 agentes (low/medium), 16 (high/xhigh); 1M de contexto según docs.x.ai (2M según OpenRouter, discrepancia) | docs.x.ai/docs/models, openrouter.ai/x-ai/grok-4.20-multi-agent; no se encontró un 'Grok 4.7 Heavy' confirmado |
| Grok Build con Grok 4.7 | disponible desde v1.0.40 (2026-09-20); plan mode, subagentes en worktrees, headless -p, AGENTS.md/hooks/skills/MCP/ACP; máximo de subagentes no documentado | x.ai/news/grok-build-cli; gradually.ai/changelogs/grok-build. Plan requerido contradictorio: SuperGrok/X Premium+ según x.ai vs SuperGrok Heavy según terceros |
| Tamaño del commit 155b6f6 | 132 archivos, +10.080/−1.231 (lockfiles +5.164; lib+test +2.379; backend +1.844) | git show --stat y git diff --numstat 02abbd4 HEAD |
| Exceso sobre el tope de PR del v1 | ~4,2k líneas escritas a mano vs 400 → ~10x | Instrucciones 06.10.26.md:405 + numstat |
| Estado del CI en la rama de Grok | 2/2 runs fallidos (37550737612 push, 37550773429 PR #1); 5 issues en analyze | gh run list / gh run view --log-failed (verificado) |
| Flutter local vs CI | 3.44.7 (Windows de Grok) vs 3.47.6 (stable de GitHub Actions) | docs/BASELINE.md:7; log del run 37550737612 |
| Cobertura de tests en 155b6f6 | 23 tests Flutter; 10 tests puros de functions; 0 goldens; 0 integration_test; 0 corridas de tests de reglas | docs/BASELINE.md, PR #1, grep en test/ |
| Migración de ubuntu-latest | a Ubuntu 26 desde el 2026-10-19 | anotación del run 37550737612 |
| Fin de soporte de Node 20 | 2026-04-30 (functions/package.json sigue en engines "20") | dato del orquestador + functions/package.json:5-7 |
| Entrada en vigencia de la Ley 21.719 | 2026-12-01 (55 días desde hoy) | Instrucciones 06.10.26.md:94 |

## PR · Production readiness: SRE, seguridad, QA y cumplimiento

_Esta lente no devolvió resultado._

