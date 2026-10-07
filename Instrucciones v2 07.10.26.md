# Instrucciones v2 · 07.10.26 — Sistema multi-agente Picaflor Tier-1

> **Reemplaza a:** `Instrucciones 06.10.26.md` (v1). La v1 queda como contexto histórico. Ante cualquier conflicto, manda este documento.
> **Para:** Grok 4.7 ejecutado en **Grok Build** (CLI agéntica con subagentes en git worktrees). Sirve también para cualquier agente de código con terminal, git y `gh`.
> **Archivos que forman el sistema:**
> - este documento (la constitución y las especificaciones);
> - [`AGENTS.md`](./AGENTS.md): resumen operativo que Grok Build carga automáticamente;
> - [`docs/v2/TASKS.yaml`](./docs/v2/TASKS.yaml): el grafo de tareas, con dueños de paths y criterios de aceptación;
> - [`docs/v2/AUDITORIA-07.10.26.md`](./docs/v2/AUDITORIA-07.10.26.md): los 203 hallazgos con evidencia `ruta:línea` y su veredicto de verificación;
> - [`.github/pull_request_template.md`](./.github/pull_request_template.md): el contrato de evidencia de cada PR.
>
> **Base auditada:** rama `grok/picaflor-v2-061026`, commit `155b6f6` (PR #1, draft). Hay que reverificar cada dato antes de actuar, porque los números de línea cambian.

---

## Índice

0. [Ficha de ejecución (cómo se lanza)](#0-ficha-de-ejecución)
1. [Constitución: invariantes no anulables](#1-constitución)
2. [Estado real verificado de la ejecución v1](#2-estado-real-verificado)
3. [Definición medible de "Tier-1"](#3-definición-medible-de-tier-1)
4. [Topología multi-agente](#4-topología-multi-agente)
5. [Protocolo git, PR y evidencia](#5-protocolo-git-pr-y-evidencia)
6. [Waves y camino crítico](#6-waves-y-camino-crítico)
7. [Especificaciones técnicas por dominio](#7-especificaciones-técnicas)
8. [QA/QC: gates, matrices y red team](#8-qaqc)
9. [Decisiones humanas (cola no bloqueante)](#9-decisiones-humanas)
10. [Reporte](#10-reporte)
11. [Prompt de arranque](#11-prompt-de-arranque)
12. [Anexo: hechos verificados al 07-10-2026](#12-anexo-hechos-verificados)

---

## 0. Ficha de ejecución

### 0.1 Herramienta y modelo
- **Herramienta:** Grok Build (CLI) con el modelo **Grok 4.7**, plan mode y **subagentes paralelos, cada uno en su git worktree**. Para lotes no interactivos se usa el modo headless (`grok -p … --output json`). Antes de usarlos, comprueba los flags con `grok --help`, porque solo se verificaron en fuentes públicas.
- **No uses** el modelo de API `grok-4.20-multi-agent` para editar código: su orquestación es interna y no se puede controlar.
- **Concurrencia inicial:** de 4 a 6 subagentes. Solo se sube si dos waves seguidas cierran sin conflictos de merge.
- **Presupuesto de contexto:** cada subagente arranca con un prompt de menos de 200k tokens (por encima de eso la tarifa de Grok 4.7 se duplica). Recibe solo `AGENTS.md`, su *task card* y los archivos que le pertenecen, nunca este documento completo.

### 0.2 Entorno obligatorio: Linux
La v1 se ejecutó en Windows nativo sin bash ni Java. Por eso los gates y el emulador no corrieron y el CI quedó rojo. **La v2 se ejecuta solo en Linux:**
- **Opción A (recomendada si tu PC es Windows):** WSL2 con Ubuntu 24.04.
  ```powershell
  wsl --install -d Ubuntu-24.04
  ```
  Dentro de Ubuntu: clona el repo **en el filesystem de Linux** (`~/src/Picaflorapp`, no en `/mnt/c`), instala Grok Build y ejecútalo desde ahí.
- **Opción B:** GitHub Codespaces o el devcontainer del repo (`.devcontainer/`, lo crea la tarea `T001`).

### 0.3 Preflight (el agente lo corre al arrancar y se detiene si algo falla)
```bash
uname -s                      # debe ser Linux
flutter --version             # debe coincidir con .fvmrc (pin de T001; hoy stable = 3.47.6)
node --version                # v22.x
java -version                 # 21
npx firebase --version        # versión fijada en package.json de tooling
gh auth status                # para leer el CI y crear PRs
git remote -v && git fetch --all --prune
```
Si `uname -s` no es `Linux` o alguna versión difiere del pin, el agente **se detiene**, informa la diferencia y no escribe código.

---

## 1. Constitución

### 1.1 Invariantes (I1–I14)
Las anula **ninguna** orden posterior, incluidas "no te detengas", "hazlo todo" o "sigue sin preguntar". Si una orden choca con un invariante, el agente lo dice, lo anota en `docs/v2/DECISIONS.md` y sigue con otra rama del grafo.

| # | Invariante |
|---|------------|
| I1 | No desplegar nada a Firebase ni a Hosting de **producción**. Solo se permite el proyecto `dev` y los preview channels, y únicamente cuando el humano lo creó y lo autorizó en `DECISIONS.md`. |
| I2 | No mergear a `main`. El merge a `main` lo hace solo el humano. Tampoco se cierran PRs ni issues ajenos. |
| I3 | No cobrar dinero real. Las compras solo corren en sandbox y detrás de un flag apagado. |
| I4 | No tocar cuentas de tiendas, firmas, keystores, secretos ni proyectos de Firebase o GCP. No se crean recursos en la nube. |
| I5 | Nunca hacer force-push a `v2/integration` ni a ramas ajenas. Las ramas propias de tarea sí se pueden rebasear. |
| I6 | No borrar, saltar (`skip`), relajar ni marcar como flaky un test o un gate, salvo en un PR `gate-change` aislado que el Verificador apruebe (§5.6). |
| I7 | Nunca mostrar datos demo en un build de producción. El guard de flavor y su test son intocables. |
| I8 | Nunca guardar ni exponer coordenadas exactas, email, teléfono, fecha de nacimiento ni tokens en documentos legibles por otros usuarios, en logs o en analytics. |
| I9 | No copiar marcas, logos, paletas exactas ni textos de Fintual, BCI ni de nadie. Se toman solo como referencia de calidad. |
| I10 | Ninguna tarea queda **DONE** sin la URL de un run de CI en verde sobre el **head SHA** y la aprobación escrita del Verificador (§5.4). |
| I11 | No inventar APIs, versiones ni datos. Todo lo posterior a mayo de 2026 (el corte de conocimiento de Grok 4.7) se verifica online o con `flutter pub outdated` / `npm view`. Si no se pudo verificar, se marca `SUPUESTO`. |
| I12 | Ningún PR supera **400 líneas** de diff, sin contar lockfiles, goldens ni código generado. Superarlo requiere el label `size-exception` y un ADR. |
| I13 | Los textos legales finales, los precios finales, la región de producción y el isotipo final nunca se toman por defecto: siempre los decide el humano (§9). |
| I14 | La seguridad nunca se cobra. Bloquear, reportar, ocultarse, exportar datos y borrar la cuenta son gratis para siempre. |

### 1.2 Orden de prioridad ante conflictos
**Privacidad > Seguridad > Cumplimiento legal > Accesibilidad > Funcionalidad > Costo/escala > Estética > Monetización.**

### 1.3 Condiciones de parada
- **Por tarea:** con 3 runs de CI rojos seguidos, la tarea pasa a `BLOCKED` con diagnóstico de causa raíz y el Orquestador sigue con otra rama del grafo. "Flaky" no cuenta como diagnóstico.
- **Globales:** se viola un invariante; aparece un P0 de seguridad sin fix posible; o `v2/integration` queda rojo y no se recupera en 2 intentos. Ante cualquiera de estas, el agente se detiene, reporta y espera.
- **"Terminado":** todas las tareas están `DONE` (con URL de CI) o `BLOCKED` con una decisión registrada, y el reporte final (§10) quedó generado por script.

---

## 2. Estado real verificado

> Lo verificó el orquestador de esta revisión el 07-10-2026 con Flutter 3.44.7 y 3.47.6, Node 22, el emulador de Firestore y los logs de GitHub Actions. Además corrieron 8 lentes de auditoría independientes (Flutter, backend, cumplimiento de v1, escala, monetización, tier-1, orquestación y production readiness) con verificación adversarial. El detalle completo está en `docs/v2/AUDITORIA-07.10.26.md`.

### 2.1 Qué hizo Grok en la v1 (y está bien: se preserva)
- **Privacidad (S1–S3):** las coordenadas pasaron a `locations/{uid}`, cerrada a clientes. `users/{uid}` es privado y existe `profiles/{uid}` como perfil público mínimo. Las reglas son default-deny, con `participantIds` y `status` inmutables y `diff().affectedKeys()` en la metadata del chat. Los tests de reglas pasan **11/11** en el emulador (verificado).
- **Cerca en producción** ya no se rellena con perfiles demo (S8), usa el callable `getNearby` y devuelve buckets sin coordenadas.
- **Correcciones confirmadas:**
  - B1–B3, B6 y B8.
  - S9: solo ubicación aproximada (`COARSE`) y uso *When In Use*.
  - S10: un release sin keystore falla.
  - S11: el mapa muestra la atribución.
  - D8: los links abren el navegador y la versión es dinámica.
  - A5: se quitaron las dependencias muertas.
- **Funciones puras** separadas y testeadas (10/10), webhook con `timingSafeEqual` e idempotencia por `event.id`, y push sin contenido del mensaje.
- **Inter** quedó empaquetada (4 TTF + OFL) y la paleta v2 tiene contrastes AA testeados en los pares de tokens.
- Se crearon 7 ADRs, `docs/voice.md`, `docs/product/plus.md`, `docs/security/threat-model.md` y `web/eliminar-cuenta.html`.

### 2.2 Qué está roto o es falso (bloquea el lanzamiento)

| ID | P0 verificado | Evidencia |
|----|---------------|-----------|
| **V-01** | El **CI del PR #1 está rojo** en sus 2 runs. Con Flutter 3.47.6 (el del CI) aparecen 5 warnings fatales `unawaited_return_in_try_block`. Grok validó con 3.44.7 en local y no revisó el CI. | `lib/services/auth_service_live.dart:49,76,107,161,261`; run `37550773429` |
| **V-02** | `dart format`: **36 de 92 archivos** sin formatear. | `dart format --output=none --set-exit-if-changed .` |
| **V-03** | **El build de Functions sale con error**: `tsc` termina en exit 2 por TS2441 en `src/pure.test.ts:23`, aunque igual emite los `.js`. Con un `predeploy` de build, el deploy aborta. Desde un clon limpio no hay `lib/`. El lint (`tsc --noEmit`) pasa y da falsa confianza, y no hay job de backend en el CI. | `npm run build` |
| **V-04** | **Node 20** como runtime: deprecado el 2026-04-30 y **decomisionado el 2026-10-30**. Después de esa fecha no se puede desplegar. | `functions/package.json:5-7` |
| **V-05** | **`updateLocation` siempre falla**: dentro de la transacción escribe y después lee, lo que Firestore prohíbe. Nadie llega a tener ubicación. | `functions/src/updateLocation.ts:34,38` |
| **V-06** | **`birthDate` nunca llega al servidor** (queda solo en SharedPreferences), y `getNearby` oculta a quien no la tiene. Resultado: **Cerca siempre vacía**. | `lib/screens/onboarding/onboarding_screen.dart:63-69`, `functions/src/pure/nearbyFilter.ts:40` |
| **V-07** | **App Check exigido en los 9 callables, pero el cliente no tiene `firebase_app_check`**, así que todos fallan en producción. | `functions/src/https.ts:7`; `pubspec.yaml` |
| **V-08** | **Las reglas de `profiles` rechazan los payloads reales del cliente** (`updatedAt`, `age`): no se puede editar el perfil ni la visibilidad. | `lib/services/user_service_live.dart:83-91` vs `firestore.rules:69-71` |
| **V-09** | **El loop central no cierra**: no hay UI para ver ni aceptar saludos (`respondWave` no tiene llamadores) y el chat aceptado nace sin `lastMessageAt`, así que no aparece en la lista. **Hoy no existe forma de iniciar una conversación en producción.** | `lib/services/safety_service_live.dart:20`; `functions/src/waves.ts:128-137` |
| **V-10** | **Borrar la cuenta recrea al usuario**: `signOut → setOnlineStatus → touchActivity` vuelve a escribir `users` y `profiles` con el token aún válido. | `lib/services/auth_service.dart:228-233` |
| **V-11** | **Trilateración**: la celda p7 (~127×153 m) de cualquier usuario se recupera en ≤9 sondas (simulado 30/30), porque `updateLocation` acepta cualquier coordenada y `getNearby` no tiene rate limit. | auditoría BE-05 |
| **V-12** | **Denial-of-wallet y costo**: `getNearby` hace hasta **~6.400 lecturas por llamada** y no tiene rate limit. Con densidad, Cerca cuesta **US$0,15–0,21 por MAU al mes**, más que el ingreso esperado de Plus (~US$0,10/MAU). | `functions/src/getNearby.ts:13,54-87` |
| **V-13** | **Radio vendido no entregado**: la consulta geohash p5 3×3 garantiza solo ~4,08 km E-O en Santiago. Cobertura real: 5 km = 93,7% y **10 km (Plus) = 5,8%**. | `functions/src/pure/geohash.ts:11,139-142` |
| **V-14** | **Los íconos de la app son el logo de Flutter** en Android, iOS y web (md5 idéntico a la plantilla). | `web/icons/Icon-512.png` |
| **V-15** | Se exige aceptar **Términos que no existen**: no hay `/terminos` y el dominio difiere del de la política de privacidad. Tampoco hay normas de comunidad ni estándares CSAE (seguridad infantil, exigidos por Google Play a las apps sociales). La URL de privacidad por defecto responde **404** porque el Hosting no está desplegado. | `lib/core/config/app_config.dart:29-31`; `curl https://picaflorapp.web.app/privacidad` |
| **V-16** | **Onboarding**: "Siguiente" en el paso 2 llama a `_finish()` y deja a la persona trabada. | `onboarding_screen.dart:83` (`_pages.length` = 2, `_stepCount` = 3) |

### 2.3 Lo que se declaró "Hecho" y no lo está

| Ítem v1 | Afirmación de Grok | Realidad |
|---------|--------------------|----------|
| S7 Saludos | Confirmado | **Falso**: no se pueden recibir ni aceptar saludos (V-09). |
| B4 Presencia | Resuelto | **Falso**: `profiles.activityBucket='ahora'` queda fijo para siempre y `touchActivity` solo corre al hacer login o logout. |
| Fase 2 Design System | Hecho | Hay **1 de 22** componentes. `context.pf` tiene **0** usos en la UI y `AppColors.*` **376**. El gate se pasó **borrando** 29 `fontSize:`. |
| Fase 7 Plus | Hecho | La "lista de espera" es un SnackBar que **no guarda nada**. Analytics, Remote Config y entitlements no existen en el cliente. |
| D6 Accesibilidad | Parcial | Hay 1 `Semantics` en toda la app, 0 widget tests, 0 goldens y targets de 34–44 px. |
| D1 Contraste | AA | Hay regresión en dark: `primaryMuted` da 1,99–2,35:1 y la ficha 2,32:1. |
| BASELINE | Línea base | Se generó **después** de los cambios, sin métricas del "antes", con gates sin correr y reglas sin ejecutar. |
| Proceso | §13 | Un solo commit de 132 archivos (unas 4,2k líneas escritas a mano, ~10× el tope). Los 12 roles fueron etiquetas, sin red team ni verificación cruzada. |

**Resumen de los 36 ítems de la v1:** 13 hechos · 16 parciales · 5 no hechos · 2 falsos. **Hallazgos nuevos:** 203 (46 P0, con duplicados entre lentes consolidados en V-01..V-16). De los 68 P0/P1 de código verificados adversarialmente: 54 confirmados, 14 parciales con corrección y **0 refutados**. El conteo exacto por lente está en el anexo de auditoría.

---

## 3. Definición medible de "Tier-1"

"Tier-1" **no** es una opinión: es cumplir este scorecard **completo**, medido por script (`tool/metrics.sh`) y verificado en CI.

| Dimensión | Métrica | Umbral Tier-1 |
|-----------|---------|---------------|
| **Funcional** | E2E en el emulador: onboarding → ubicación → Cerca → saludo → aceptar → chat → bloquear → reportar → exportar → borrar | 100% verde en CI |
| | P0 abiertos / bugs S1-S2 | 0 / 0 |
| **Calidad de código** | CI en el head SHA con el toolchain fijado | verde |
| | `dart format`, `analyze --fatal-infos`, gates AST | 0 issues |
| | Cobertura `domain` + `application` / global | ≥ 85% / ≥ 70% |
| | Pantallas con widget test por estado (loading/vacío/error/datos/offline) | 100% |
| **Diseño** | Usos de `AppColors.` / `isDark ?` / `AppShadows` / `TextStyle(` fuera del design system | 0 (ratchet) |
| | Componentes `Pf*` de §7.5 con test y golden | 22/22 |
| | Matriz de goldens (§8.3) | 100% aprobada |
| **Accesibilidad** | `textContrastGuideline`, `androidTapTargetGuideline`, `iOSTapTargetGuideline` y `labeledTapTargetGuideline` en light y dark | 100% de las pantallas |
| | Texto al 200% en 320 px sin overflow | 6 pantallas clave |
| | Pasada TalkBack y VoiceOver (video + checklist) | aprobada |
| **Privacidad y seguridad** | Matriz de reglas (colección × operación × actor), incluidas las 20 sondas de la auditoría | ≥ 80 casos, 100% verde |
| | Simulación de trilateración (3 cuentas coludidas, 100 sondas) | incertidumbre ≥ 500 m |
| | Callables con App Check + rate limit | 100% |
| | Checklist de la Ley 21.719 (§7.6) | completo (con firma legal pendiente) |
| **Escala y costo** | Lecturas por `getNearby` (p95, sin caché) | ≤ 60 |
| | Latencia de `getNearby` p95 (caliente / cold start) | < 400 ms / < 1,5 s |
| | Costo de Cerca por MAU al mes (modelo + medición) | ≤ US$0,02 |
| | Prueba de carga: 50k usuarios sintéticos, 200 req/s | p95 < 800 ms, errores < 0,5% |
| **Rendimiento cliente** | Primer frame en Android de gama media (perfil) | < 2,0 s |
| | Frames > 16 ms en el scroll de Cerca y del chat | < 1% |
| | JS inicial web gz (línea base 1.052.440 B) | ≤ +10% |
| **Confiabilidad** (beta) | Usuarios sin crash / tasa de error de callables | ≥ 99,5% / < 1% |
| **Tiendas** | Íconos, splash, capturas, metadata es-CL, Privacy Labels / Data safety, notas de revisión, borrado in-app + web | 100% |
| **Monetización** | Plus detrás de flag, entitlements solo en servidor, webhook testeado, paywall Apple 3.1.2, analytics + tablero de liquidez | 100% |

---

## 4. Topología multi-agente

### 4.1 Carriles (subagentes reales, uno por worktree)

| Carril | Rol | Paths propios (exclusivos) |
|--------|-----|----------------------------|
| **L0** | Orquestador + Integrador | `docs/v2/**`, y **los archivos compartidos** (serializados): `pubspec.yaml`, `pubspec.lock`, `firestore.rules`, `firestore.indexes.json`, `storage.rules`, `firebase.json`, `lib/main.dart`, `lib/app/router/**`, `lib/l10n/*.arb`, `.github/**` |
| **L1** | Backend, Reglas y Functions | `functions/**`, `firestore-tests/**`, `storage-tests/**`, `tool/emulator/**` |
| **L2** | Design System, Marca y A11y | `lib/core/design_system/**`, `assets/brand/**`, `test/goldens/**`, `test/design_system/**` |
| **L3** | Arquitectura cliente | `lib/app/**` (salvo el router), `lib/core/{config,prefs,analytics,errors,network}/**`, `lib/features/*/data/**`, `lib/features/*/domain/**`, `env/**` |
| **L4** | Pantallas y flujos | `lib/features/*/presentation/**`, `lib/features/*/application/**`, `test/features/**` |
| **L5** | QA, CI y Release | `tool/**`, `integration_test/**`, `.devcontainer/**`, `fastlane/**`, `docs/store/**` |
| **L6** | Escala y Costo | `functions/src/nearby/**`, `functions/src/platform/**`, `load/**`, `docs/scale/**` |
| **L7** | Monetización, Growth y Analytics | `lib/features/plus/**`, `lib/features/growth/**`, `functions/src/billing/**`, `functions/src/growth/**`, `analytics/**`, `docs/product/**`, `docs/growth/**` |
| **L8** | Trust & Safety y Legal | `functions/src/safety/**`, `docs/legal/**`, `docs/security/**`, `web/*.html` (legales) |

**Transversales, con contexto separado y sin escribir código de producto:**
- **V (Verificador):** re-ejecuta `tool/verify.sh` en un **clone limpio** del head SHA, contrasta cada afirmación del PR y de `docs/` contra el código y `metrics.json`, y escribe `docs/v2/verify/<task>.md`. **Es el único que cambia el `status` a `DONE` en `TASKS.yaml`.**
- **R (Red Team):** ataca cada PR que toque privacidad, seguridad, pagos, reglas o callables, y escribe `docs/v2/redteam/<task>.md` con intento, comando, resultado esperado y resultado real (lista mínima en §8.5).

### 4.2 Reglas de colaboración
1. Una tarea pertenece a un solo carril. Si necesita tocar un path de otro carril, abre una subtarea en ese carril (`depends_on`).
2. Los archivos compartidos los modifica **solo L0**, a pedido (`touches_shared: true` en la tarea). Así se evitan conflictos de `pubspec.lock` y de reglas.
3. **Contratos primero:** cuando hay cliente y backend involucrados, L1 publica el contrato (tipos TS + fixture JSON en `contracts/`) y L3/L4 lo consumen. Los tests de contrato fallan si alguno de los dos lados diverge (§8.2).
4. Ningún carril marca `DONE` (I10). El implementador deja la tarea en `REVIEW` con el link al PR.
5. El implementador nunca escribe el informe de verificación de su propia tarea.

---

## 5. Protocolo git, PR y evidencia

### 5.1 Ramas
- **`v2/integration`** se crea desde `155b6f6` (el trabajo de Grok es la base y esta auditoría cuenta como su revisión, ver D-01). Es la única rama larga de la v2 y nunca recibe force-push.
- **Una rama y un worktree por tarea:** `v2/<carril>/<task-id>-<slug>`, ej. `v2/l1/T101-update-location-tx`.
- **PR por tarea contra `v2/integration`** con squash-merge y un *conventional commit* (`fix(functions): …`). Antes de mergear se rebasea sobre `integration`.
- Al cerrar cada wave, L0 abre o actualiza un PR **draft** `v2/integration → main`. El merge a `main` lo hace el humano (I2).

### 5.2 Contrato de PR
Se usa la plantilla obligatoria `.github/pull_request_template.md`, que pide:
- tarea, hallazgos que cierra y criterios de aceptación;
- tamaño del diff;
- **URL del run de CI en el head SHA**;
- `flutter --version` y el extracto de `tool/verify.sh`;
- goldens nuevos o cambiados, con justificación;
- capturas antes y después (artefacto del CI);
- riesgos y referencias a decisiones;
- la sección **"NO VERIFICADO"**;
- las aprobaciones de V y, si aplica, de R.

### 5.3 Regla anti-afirmación
- La **única evidencia válida** de que algo funciona es un test o comando del CI, con su URL en verde sobre el head SHA. "Lo corrí en mi máquina" no cuenta.
- Después de cada push, el implementador corre `gh run watch <id> --exit-status`. Un PR en rojo no puede reportarse como hecho.
- Cualquier número de un reporte que no salga de `metrics.json` o de un artefacto del CI se considera ❌.
- Para marcar un hallazgo S* como cerrado hay que citar el **nombre del test allow/deny** que lo prueba.

### 5.4 Ciclo de vida de una tarea
`TODO → IN_PROGRESS (implementador) → REVIEW (PR verde) → [R si aplica] → VERIFIED por V → DONE (lo escribe V)`, con el desvío `→ BLOCKED (3 CI rojos o una decisión pendiente)`.

### 5.5 Línea base real (la produce el CI, no el agente)
El workflow `baseline` (tarea T004) corre `tool/verify.sh` y `tool/metrics.sh` **sin modificar nada** sobre `d3b103e` (main) y sobre `155b6f6`, y guarda `docs/v2/metrics.baseline.json`. Toda métrica posterior se expresa como delta contra ese archivo.

### 5.6 Rutas protegidas
`tool/`, `.github/`, `analysis_options.yaml`, los umbrales de cobertura y `test/goldens/` solo se cambian en PRs con el label `gate-change` y sin código de producto. Un check de CI falla si un PR mezcla ambos tipos de cambio o si introduce `|| true`, `skip:`, `--no-fatal-infos` o baja un umbral.

---

## 6. Waves y camino crítico

> El detalle de cada tarea (dueño, `depends_on`, `owns_paths`, criterios y evidencia) está en `docs/v2/TASKS.yaml`. Aquí va el mapa.

```
W0 Estabilizar (1 solo agente, secuencial) ──► W1 Loop central funcionando E2E ──► W2 Privacidad + escala backend ─┐
                                                       │                                                          ├─► W6 Release
                                                       └──────► W3 Design System + Pantallas Tier-1 ─────────────┤   readiness
                                                                         W4 Trust & Safety + Legal (fecha dura: 2026-12-01) ─┤
                                                                         W5 Monetización + Growth + Analytics ──────────────┘
```

| Wave | Objetivo | Criterio de salida (gate automático) | Paralelismo |
|------|----------|---------------------------------------|-------------|
| **W0** | CI verde y reproducible en Linux | `verify.sh` verde en `v2/integration`; `metrics.baseline.json` generado; gates v2 y plantilla de PR activos | **1 agente** (camino crítico) |
| **W1** | V-05 a V-10 y V-16: el loop central funciona en el emulador | El test E2E `integration_test/loop_e2e_test.dart` pasa contra los emuladores (auth + firestore + functions) en CI | L1, L3 y L4 en paralelo |
| **W2** | V-11, V-12 y V-13: privacidad real y costo controlado | Matriz de reglas ≥ 80 casos verde; simulación de trilateración ≥ 500 m; prueba de carga con p95 < 800 ms y ≤ 60 lecturas | L1, L6 y L8 |
| **W3** | Design system adoptado y pantallas Tier-1 | Ratchet en 0, 22/22 componentes, goldens y a11y al 100%, l10n en 0 literales | L2, L4 y L3 |
| **W4** | Ley 21.719, tiendas y Trust & Safety | Checklist legal completo **antes del 2026-11-15** (para la revisión del abogado), borrado y export durables, moderación operable | L8, L1 y L5 |
| **W5** | Monetización y crecimiento listos (flag apagado) | Webhook v2 testeado, paywall 3.1.2, analytics con consentimiento, tablero de liquidez, referidos y deep links | L7, L1 y L4 |
| **W6** | Release readiness | Scorecard Tier-1 (§3) completo; RECONCILE de V; campaña completa de R | L5, V y R |

W3 empieza apenas W0 cierra (no depende de W1, salvo en las pantallas del loop). W4 y W5 empiezan cuando sus dependencias específicas de W1 y W2 están en `DONE`.

### 6.1 Wave 0, paso a paso (la ejecuta el Orquestador solo, sin subagentes)
1. `T000`: crear `v2/integration` desde `155b6f6` e importar los archivos de la v2 desde `origin/claude/serene-davinci-2wiacu`:
   ```bash
   git checkout -b v2/integration origin/grok/picaflor-v2-061026
   git checkout origin/claude/serene-davinci-2wiacu -- "Instrucciones v2 07.10.26.md" AGENTS.md docs/v2 .github/pull_request_template.md
   ```
2. `T001`: fijar el toolchain.
   - Crear `.fvmrc` con la versión de Flutter verificada ese día (hoy stable = 3.47.6) y `flutter-version-file` en `subosito/flutter-action`.
   - `runs-on: ubuntu-24.04` explícito.
   - Actions en versiones compatibles con Node 24 (verificarlo en GitHub).
   - Crear `.devcontainer/` con Flutter fijado, Node 22, Java 21 y firebase-tools fijado.
3. `T002`: arreglar los 5 `unawaited_return_in_try_block` (V-01) y formatear (V-02) en **commits separados**: uno de formato puro y otro de fixes.
4. `T003`: backend deployable (V-03, V-04).
   - Crear `tsconfig.build.json` sin tests y subir el runtime a Node 22 (Node 24 solo si se verifica soporte en Cloud Functions y en firebase-functions).
   - Agregar `predeploy` (lint + build) en `firebase.json`.
   - Crear el job de CI `backend`: `npm ci`, `lint`, `build` y `test`.
   - Crear el job `emulators`: Java 21 y `firebase emulators:exec --only auth,firestore,functions,storage` con los tests de reglas.
5. `T004`: crear `tool/verify.sh`, `tool/metrics.sh` y el workflow `baseline`, y generar `docs/v2/metrics.baseline.json`.
6. `T005`: gates v2 (§8.1).
   - Basados en AST y con *ratchet*: el baseline de conteos solo puede bajar.
   - Con fixtures que deben fallar.
   - Checks de tamaño de PR y de rutas protegidas.
7. `T006`: crear `docs/v2/STATUS.md`, `docs/v2/DECISIONS.md` (copia de la §9) y `tool/report.sh`.
8. Con todo en verde, se lanzan los subagentes de W1, W2 (preparación) y W3.

---

## 7. Especificaciones técnicas

### 7.1 Modelo de datos objetivo (Firestore)

| Colección | Lectura | Escritura | Contenido clave | TTL |
|-----------|---------|-----------|-----------------|-----|
| `users/{uid}` | dueño | dueño, solo `settings` y `displayName` | email, teléfono, `birthDate` (inmutable, la escribe el servidor), `settings` | — |
| `users/{uid}/fcmTokens/{token}` | dueño | dueño | `platform`, `updatedAt` | 60 d sin uso |
| `users/{uid}/consentEvents/{id}` | dueño | **servidor** (append-only) | `type`, `version`, `granted`, `ts` | retención legal |
| `profiles/{uid}` | autenticado con relación vigente (resultado de Cerca, saludo o chat) o perfil visible y no bloqueado | dueño: `displayName`, `bio`, `interests`, `prompts`, `isVisible`; servidor: `age`, `photos[]`, `verified` | tarjeta pública | — |
| `locations/{uid}` | **nadie** | **servidor** (`updateLocation`) | `g7`, `cell6`, `cell5`, `cityId`, `updatedAt` | `expireAt` = +7 d |
| `nearbyIndex/{uid}` | **nadie** | **servidor** (trigger) | `cell6`, `cell5`, `cityId`, `visible`, `adult`, `lastActiveAt`, `boostUntil`, `card{name, age, photoThumb, interests[2], verified}` | `expireAt` = +7 d |
| `relations/{uid}` | **nadie** | **servidor** | `blocked[]`, `blockedBy[]`, `wavedWith[]` (topes y rotación documentados) | — |
| `waves/{from}_{to}` | emisor y receptor | **servidor** (`sendWave` / `respondWave` / `cancelWave`) | `status` (pending/accepted/ignored/expired/cancelled), `note?`, `createdAt`, `respondedAt` | pending 14 d, resueltos 90 d |
| `waveCounters/{uid}_{yyyymmdd}` | nadie | servidor (transacción) | `count` | 48 h |
| `chats/{id}` | participantes | servidor crea; cada participante solo su `unreadCount.<uid>`, `lastRead.<uid>` y `muted.<uid>` | `participantIds` y `status` inmutables para el cliente, `lastMessageAt` | — |
| `chats/{id}/messages/{m}` | participantes | participante si `status=='active'`, sin bloqueo en ningún sentido, `keys().hasOnly([...])`, `createdAt == request.time`, `type=='text'`, texto 1..2000 | — | — |
| `inbox/{uid}` | dueño | servidor | `unreadChats`, `pendingWaves` (para los badges) | — |
| `reports/{id}` | nadie | **servidor** (`reportUser`) | `reporter`, `target`, `context{chatId?, messageId?}`, `reason`, `text`, `priority` | según política |
| `moderationQueue/{id}` | admins (claim) | servidor | `status`, `assignee`, `slaDueAt` | — |
| `entitlements/{uid}` | dueño | **servidor** (webhook) | `plus{active, expiresAt, productId, store, periodType, willRenew, billingIssue}` | — |
| `wallets/{uid}` + `ledger/{txId}` | dueño (wallet) | servidor | créditos de Destacar, idempotente por `transaction_id` | ledger: retención contable |
| `waitlist/{uid}` | dueño | servidor (`joinWaitlist`) | `zone`, `source`, `referralCode`, `ts` | — |
| `deletionRequests/{uid}` · `exports/{uid}/{ts}` | dueño (estado) | servidor | estado del job | 30 d / 7 d |
| `cities/{cityId}` · `config/runtime` | cliente (solo lo público) vía Remote Config | admin | cobertura, tz, moneda, `launchState`, límites, flags y kill switches | — |
| `metrics/liquidity/{zone}/{date}` | nadie | job programado | agregados sin PII | 400 d |
| `rateLimits/{uid}_{action}` · `processedEvents/{id}` · `webhookEvents/{id}` | nadie | servidor | token bucket / dedupe | 48 h / 7 d / 90 d |

**Reglas:** se mantiene el catch-all en deny. `users`, `profiles` y `chats` usan listas blancas por campo con `affectedKeys().hasOnly`. `request.auth.token.banned != true` en toda escritura. Hay exenciones de índice para `messages.text`, `profiles.bio`, `waves.note` y `reports.text`. Los índices compuestos se validan con un deploy dry-run en el emulador.

### 7.2 Callables (todos con App Check, rate limit persistente y opciones de runtime por función)

| Callable | Rate limit (token bucket por uid) | Notas |
|----------|-----------------------------------|-------|
| `completeOnboarding` | 5/día | Valida 18+ en el servidor, escribe `birthDate` (inmutable), deriva `profiles.age` y agrega un `consentEvent`. Sin esto no se habilitan `updateLocation`, `getNearby` ni `sendWave`. |
| `updateLocation` | 1 cada 20 s, ≤ 20 celdas distintas al día | **Lecturas antes de escrituras.** Valida plausibilidad: ciudad habilitada y velocidad ≤ 150 km/h entre updates. Si falla, se rechaza y se congela 10 min. Escribe `lastActiveAt` con throttle de 10 min. |
| `getNearby` | 20/min, 300/día | §7.3. Devuelve tarjetas paginadas (≤ 50 + cursor). Exige que quien llama sea visible o tenga Plus incógnito (D-05). |
| `sendWave` / `respondWave` / `cancelWave` | gratis 20/día (contador transaccional en la tz de la ciudad); Plus 10/min y 200/día | ID `${from}_${to}` con `create()`. Cooldown de 14 días por par tras `ignored`, **también para Plus**. Valida que el destinatario exista, sea adulto, visible o con relación, y esté dentro del radio del plan. `respondWave` escribe `lastMessageAt` y reactiva el chat si no hay bloqueo. |
| `blockUser` / `unblockUser` | 30/día | Batch atómico: `relations` + `chat.status`. El cliente no escribe `blocks` directo. |
| `reportUser` | 10/día, dedupe por reporter+target+día | Prioriza los reportes de menor y sexual, y opcionalmente bloquea en el mismo paso. |
| `joinWaitlist` | 3/día | Write-once. |
| `activateBoost` | 3/día | Requiere crédito en el ledger. Garantiza vistas o devuelve el crédito. |
| `exportMyData` | 1/día | Async: el job escribe en Storage y entrega una URL firmada de 72 h. |
| `deleteAccount` | 3/día | Exige `auth_time` ≤ 5 min y solo encola `deletionRequests`; el worker es durable (§7.6). |

Opciones de runtime iniciales (a revisar con la prueba de carga):

| Función | Memoria | Concurrencia | Instancias (min-max) |
|---------|---------|--------------|----------------------|
| `getNearby` | 1 GiB | 40 | 1-100 en prod |
| `updateLocation` | 512 MiB | 80 | 1-100 |
| `onMessageCreated` | 256 MiB | 80 | máx 200 |
| `revenuecatWebhook` | — | — | máx 5 |

Se quita el `maxInstances: 20` global.

### 7.3 Cerca: algoritmo, privacidad y costo
1. **Cobertura fiel al radio.** Las celdas a consultar se calculan **según el radio**: p6 para ≤ 1,2 km, p5 para ≤ 5 km, y anillo k=2 de p5 o p4 para 10 km. Un **test de propiedad** recorre 10k centros aleatorios por ciudad con radios {0,5, 1, 2, 5, 10} km y exige que el **100%** de los puntos dentro del radio caigan en una celda consultada. Mientras ese test no esté verde, el paywall no muestra "10 km".
2. **Consulta.** `nearbyIndex where cell5 in [≤30] and visible==true and adult==true and lastActiveAt >= now-7d orderBy lastActiveAt desc limit K` con índice compuesto. Se itera de los anillos chicos a los grandes hasta juntar K = 50 candidatos. Se filtra el radio exacto y la `relations` del que llama (1 lectura) y se ordena por bucket de distancia y luego por recencia.
3. **Sin truncamiento silencioso:** el test con 5.000 usuarios sintéticos en una celda devuelve exactamente los K que da la fuerza bruta.
4. **Respuesta:** `{people: [{uid, distanceBucket, activityBucket, card}], cursor}`. **El cliente hace 0 lecturas extra** (adiós N+1).
5. **Anti-trilateración** (default D-06):
   - La distancia se calcula desde el **centro de la celda p6 del que mira**, no desde su p7.
   - El bucket mínimo es **"a menos de 500 m"**.
   - Se agrega ruido estable por par: `HMAC(secret, viewer|target|día)` desplaza el borde del bucket ±20%.
   - Más la plausibilidad de `updateLocation` y los rate limits.
   - Una simulación de ataque corre en CI (`tool/attack/trilaterate.ts`) con 3 cuentas coludidas y 100 sondas: la incertidumbre debe ser ≥ 500 m.
6. **Caché:** en el cliente, memoria + disco con TTL de 90 s y *stale-while-revalidate*, guardando solo uids, buckets y tarjetas. El servidor responde hasta el radio máximo del plan y el cliente filtra los presets, así que 5 cambios de radio en 60 s producen 1 sola llamada (test).
7. **Mapa:** no se pintan pines de otras personas sobre un mapa geográfico. Se usa un **Radar abstracto** (anillos por bucket, avatares, sin mapa base) y, opcionalmente, densidad por comuna con k ≥ 3. El mapa geográfico muestra solo **tu** zona, con un proveedor de licencia comercial y atribución (D-09).
8. **Presupuesto:** p95 ≤ 60 lecturas por llamada sin caché; costo de Cerca ≤ US$0,02/MAU/mes. Se mide con un wrapper contador del Admin SDK en el emulador y, en producción, con la métrica de logs `nearby_reads`. Hay alerta si el promedio supera 50.

### 7.4 Escalabilidad por etapas (`docs/scale/roadmap.md`, a cargo de L6)

| Etapa | MAU | Arquitectura | Disparador para pasar a la siguiente |
|-------|-----|--------------|---------------------------------------|
| **A** | 0 – 100k | Firestore + `nearbyIndex` + consultas por anillo + caché en el cliente + rate limits + minInstances 1 en los callables calientes. Una sola región (D-02). | p95 de lecturas de Cerca > 60, o p95 de latencia > 800 ms, o gasto diario de Firestore sobre el umbral del ADR durante 7 días |
| **B** | 100k – 1M | Celdas materializadas `cellCards/{cell6}` (trigger) o **Redis GEO** (Memorystore) detrás de la interfaz `NearbyIndex`. Pub/Sub para push y moderación. BigQuery streaming. | > 3 países, o latencia entre regiones > 300 ms, o costo de geo > X% del ingreso |
| **C** | 1M+ / multi-país | Servicio geo dedicado (Cloud Run + Redis/Typesense/PostGIS), **bases con nombre por macro-región** (residencia de datos por país), CDN para perfiles públicos. | — |

**Interfaces estables desde hoy** (para que cada salto sea cambiar una implementación sin reescribir la app): `NearbyIndex`, `PushDispatcher`, `ModerationQueue`, `EntitlementSource`, `RateLimiter`.

**FinOps:**
- Presupuestos de Cloud Billing por proyecto con alertas al 50, 80 y 100%, y una notificación por Pub/Sub que activa **kill switches** (`nearby_enabled`, `nearby_max_candidates`, `push_enabled`, `waves_daily_limit`).
- `docs/scale/cost-model.md` se genera con script (supuestos explícitos) a 1k, 10k y 100k DAU.

**Multi-ciudad:** `cities/{cityId}` con cobertura (set de geohash p4/p5), tz, moneda, `launchState` (waitlist/beta/open), radios, límites y flags. El servidor deriva `cityId` y `SantiagoBounds` deja de ser una regla.

### 7.5 Cliente: arquitectura, design system y UX Tier-1

**Arquitectura** (sigue la §8.1 de la v1):
- `features/<f>/{data,domain,application,presentation}` con interfaces de repositorio e implementaciones `Demo*` y `Firebase*` inyectadas por override.
- `Notifier`/`AsyncNotifier`, con estado **por sesión**: todo se invalida cuando cambia el uid.
- **Flavors reales** con `--dart-define-from-file=env/<flavor>.json`. `FLAVOR` es obligatorio en release, y si `kReleaseMode && demoMode` en móvil, la app crashea al arrancar.
- El demo web va en un site o canal de Hosting separado, con el banner "Demo".

**Integraciones obligatorias:**

| Integración | Detalle |
|-------------|---------|
| `firebase_app_check` | Play Integrity, App Attest con fallback a DeviceCheck, reCAPTCHA Enterprise en web y provider debug en dev/emulador. |
| `firebase_messaging` | Pre-permiso **después del primer saludo enviado**. |
| `firebase_remote_config` | Con espejo en el servidor. |
| `firebase_analytics` | Solo con consentimiento. |
| `firebase_crashlytics` | Sin PII. |
| `purchases_flutter` | Import condicional: en web no se compila. |
| Otros | `image_picker`, `share_plus`, `app_links`, `flutter_svg`, `flutter_native_splash`, `flutter_launcher_icons`. Verificar las versiones en pub.dev (I11). |

**Upgrades mayores pendientes** (cada uno en un PR propio y solo **después** de tener widget tests): `go_router` 14→18, `riverpod` 2→3, `google_sign_in` 6→7 (API incompatible) y `geolocator` 12→14.

**Design system (DS):**
- Se mantienen los tokens v2 que dejó Grok, porque sus contrastes están validados.
- **DS-1, adopción real:** los widgets consumen solo `context.pf.colors`, `PfType`, `PfSpace`, `PfRadius`, `PfMotion` y los componentes `Pf*`. `AppColors`, `AppShadows` y `AppTypography` pasan a `@Deprecated` y quedan prohibidos fuera de `design_system`. El ratchet parte de 376 / 98 / 13 y termina en **0**.
- **DS-2, los 22 componentes:**
  - Acciones: `PfButton`, `PfIconButton`
  - Formularios: `PfTextField`, `PfOtpField`, `PfSegmented`, `PfRadiusPicker`
  - Superficies: `PfSurface`/`PfCard`, `PfListTile`, `PfSheet`, `PfDialog`, `PfSectionHeader`
  - Identidad y datos: `PfAvatar` (foto + iniciales + semántica), `PfTag`, `PfBadge`, `PfStat` (tabular)
  - Feedback: `PfBanner`, `PfEmptyState`, `PfSkeleton`, `PfToast`
  - Producto: `PfPlanCard`, `PfReportSheet`, `PfLogo`

  Cada uno con doc comment, estados (default, hover, pressed, focus, disabled, loading, error), `Semantics`, widget test y golden. Hay una galería en `/_dev/gallery`, solo en el flavor dev.
- **No se "arregla" un gate borrando propiedades.** Cada `fontSize` eliminado se reemplaza por un estilo `PfType`.
- **Tipografía:** `PfType` con los nombres de la spec (display, titleLg, titleMd, titleSm, bodyLg, body, bodySm, label, caption, overline) y una variante numérica con `FontFeature.tabularFigures()`. Se prohíben `fontWeight` y `height` fuera de `PfType`. En web, Inter variable con subset latin y latin-ext.
- **Motion y haptics:** `PfMotion` (120/200/300 ms, `easeOutCubic`) respeta `disableAnimations`. `pageTransitionsTheme` usa fade + slide de 8 px. `PfHaptics` es semántico (selection, success, warning) y sin `vibrate()`. Un solo set de íconos (Material Symbols Rounded) y back adaptativo.

**Marca (BRAND-1..3):**
- El isotipo es un **SVG de una tinta**, reconocible como picaflor (pico largo y recto, cuerpo y ala), legible a 16 px y dibujado en una grilla de 24. Tiene lockup con wordmark en Inter y variantes light, dark y mono.
- La hoja `docs/brand/mark-sizes.png` (16/24/32/48/1024) la aprueba el humano (D-04). Hasta entonces se usa un placeholder geométrico marcado "provisorio".
- Se eliminan el `CustomPainter` `PfMark`, el `_BrandMark` con "P" y los gradientes de marca.
- **Íconos de app** con `flutter_launcher_icons`: Android adaptive + monochrome, iOS 1024 sin alfa + variantes dark/tinted, y web 192/512 + maskable. Un check de CI falla si algún md5 coincide con los de la plantilla de Flutter (V-14).
- **Una sola splash:** `flutter_native_splash` en light `#FFFFFF` y dark `#0B0F14`, con la API de splash de Android 12. El loader HTML usa el mismo SVG con `prefers-color-scheme`. Se elimina la ruta `/splash`.

**Pantallas (criterio = goldens + widget tests de cada estado):**

| Pantalla | Especificación Tier-1 |
|----------|------------------------|
| **Login** | Una acción primaria por plataforma:<br>• iOS: `SignInWithAppleButton` oficial.<br>• Android y web: botón oficial "Continuar con Google".<br>• Luego "Continuar con teléfono" (secundario, +56 fijo y máscara `9 XXXX XXXX`) y "Usar correo" (terciario).<br>• `PfOtpField` de 6 casillas con `AutofillHints.oneTimeCode` y reenvío a los 30 s.<br>• `AutofillGroup` en correo y clave.<br>• En ≥ 900 px, panel de marca + formulario de 420 px. |
| **Onboarding** | Barra de progreso a lo largo de: valor → privacidad → edad y términos (links tocables a `/terminos` y `/privacidad` existentes; CTA deshabilitado hasta que todo sea válido; error inline; fecha DD-MM-AAAA) → login → **Completar perfil** (≥ 1 foto, 3–5 intereses, 1 prompt) → pre-permiso de ubicación → **"Tu primer saludo"** con 3 personas cercanas.<br>Menores de 18: pantalla de cierre respetuosa y bloqueo persistente.<br>Test Patrol de punta a punta. |
| **Cerca** | `PfStat` "**14** personas a menos de 2 km", `PfSegmented` Lista/Radar (48 px), `PfRadiusPicker` 500 m / 1 / 2 / 5 km (10 km con candado de Plus, que dispara el paywall con trigger `radius`).<br>Tarjeta e0: foto 4:5 o avatar 72, "Nombre, edad", bucket y actividad como texto, 2 intereses, CTA terciario **"Saludar"**, un solo nodo semántico.<br>Estados: skeleton, **vacío de liquidez** ("Invita a alguien" / "Avísame cuando haya gente" / "Ampliar radio"), offline, error y sin permiso. |
| **Ficha pública** | Sheet scrollable al 90% en móvil y panel de 400 px en ≥ 1200 px: fotos, nombre y edad, verificado, distancia y actividad, bio, intereses y prompts.<br>"Saludar 👋" con estados idle, loading, enviado (deshabilitado) y cupo agotado (paywall), más "Te quedan N saludos hoy". Un doble tap envía 1 solo saludo (test).<br>Menú ⋯ con Bloquear y Reportar. |
| **Chats** | Sección **"Saludos nuevos (n)"** con Aceptar / Ignorar (ignorar es silencioso), "Enviados" con estado y expiración a 7 días, y badge en la pestaña.<br>Conversaciones con `limit(30)` y paginación por documento.<br>En ≥ 1200 px: maestro-detalle (lista de 360 px + conversación). |
| **Chat** | La cabecera abre la ficha. Menú: Ver perfil, Silenciar, Bloquear, Reportar.<br>Si el chat está bloqueado, el composer se reemplaza por un aviso. Burbujas con estado (enviando / enviado / fallido + reintentar).<br>Paginación con `startAfterDocument` sin ventana deslizante; `markRead` cuando cambia el id del último entrante; no leídos calculados respecto de `lastRead`.<br>Tip de seguridad en el primer chat. Long-press para copiar o reportar. En desktop, Enter envía y Shift+Enter hace salto de línea.<br>Autoscroll solo si la persona ya estaba al final; si no, aparece la píldora "Nuevos mensajes". |
| **Mi perfil** | "Así te ven", medidor de completitud, editor de 1–6 fotos (recorte 4:5, 1080 px, ≤ 1 MB, **sin EXIF**), intereses y prompts, y toggle "Visible en Cerca" con explicación. **Nunca se muestra el email.** |
| **Ajustes** | Cuenta · Privacidad (visibilidad, incógnito⁺, **Usuarios bloqueados**, consentimientos con retiro) · Notificaciones (granulares, horario silencioso) · Apariencia · Suscripción (Restaurar real y deep link para gestionar) · Ayuda y seguridad · Legal · **Mis datos** (export JSON por share sheet) · **Eliminar cuenta** (avisa si hay una suscripción activa).<br>`grep` de "en producción", "propuestos", "nube" o "no finales" en strings de release = 0. |
| **Paywall** | §7.7. |
| **Reportar** | `PfReportSheet` con motivos (spam / acoso / sexual no deseado / posible menor / perfil falso / otro + texto), "Además, bloquear" activado por defecto en acoso, sexual y menor, y confirmación honesta (sin prometer un SLA hasta que la cola exista).<br>Bloquear pide confirmación y ofrece Deshacer por 5 s. |

**Accesibilidad (A11Y-1..2):**
- Hay `MergeSemantics` por tarjeta ("Camila, 29, a unos 300 m, activa hoy. Saludar"), `selected` en segmented y tabs, labels en enviar, volver, refrescar y skeleton, y `SemanticsService.announce` para "Saludo enviado" y "Bloqueaste a…".
- El anillo de foco es visible en web y desktop. Los targets son ≥ 48 dp.
- Hay un reporte en `docs/a11y/report.md` con video de TalkBack y VoiceOver.

**l10n:** `lib/l10n/app_es_CL.arb` + `gen-l10n`, con **0 literales** en presentation (gate) y el glosario de `docs/voice.md`: "Chats" (no "Mensajes"), "clave" y nunca "Chatear".

### 7.6 Trust & Safety y Legal (fecha dura: Ley 21.719 vigente desde el **2026-12-01**)

**Checklist legal** (`docs/legal/checklist-21719.md`, a cargo de L8; borradores marcados "requiere validación legal"):
1. Registro de actividades de tratamiento (RAT): dato, finalidad, base de licitud, retención, destinatarios y transferencias.
2. Evaluación de impacto (EIPD) de la **geolocalización** y de la **biometría**, si se activa la verificación.
3. Consentimiento granular y versionado (`consentEvents` append-only), con retiro en Ajustes y evidencia demostrable.
4. Derechos ARCO + portabilidad + bloqueo: export JSON completo, rectificación, supresión y oposición, con plazos documentados.
5. **Transferencia internacional:** Firebase almacena fuera de Chile si la región no es `southamerica-west1` (D-02). Se declara en la política.
6. Protocolo de brechas: runbook, responsables, plazos de notificación (verificar en la ley) y plantilla de aviso.
7. Política de retención ejecutable (TTL y jobs de §7.1) que coincida con la política publicada.
8. Encargado o delegado de protección de datos (decisión humana).
9. En **un mismo dominio**, con rewrites en Hosting: Términos (`/terminos`, EULA con tolerancia cero), Privacidad v2 (`/privacidad`, con el contenido mínimo de la ley: responsable, finalidades, bases, categorías, plazos, encargados como Google/CARTO/RevenueCat, transferencias, derechos y canal), Normas de la comunidad (`/normas-comunidad`), **Estándares contra la explotación y el abuso sexual infantil** (`/seguridad-infantil`, con contacto designado, como exige Google Play) y Borrado (`/eliminar-cuenta`). Un job de CI verifica HTTP 200 de las 5 URLs en staging antes de cada release. Los textos finales los firma un abogado (I13).
10. Canal de derechos ARCOP + bloqueo con plazo de respuesta y registro de solicitudes. Persona designada para cumplimiento (D-12). Multas de hasta 20.000 UTM en infracciones gravísimas (fuente secundaria; validar con un abogado).

**Borrado durable:**
- `deleteAccount` solo encola `deletionRequests/{uid}`. El worker idempotente (trigger con reintentos o Cloud Tasks, `BulkWriter`, `recursiveDelete`) borra:
  - Auth, `users`, `profiles`, `locations` y `nearbyIndex`;
  - `relations` y `waves` (`from` y `to`);
  - chats: pasan a `closed`, con `lastMessage` anonimizado y mensajes propios anonimizados;
  - Storage (si falla, reintenta y alerta);
  - entitlements y el subscriber en RevenueCat;
  - `rateLimits` y `fcmTokens`.
- Se conserva solo la evidencia legal mínima declarada (consentimientos y ledger contable seudonimizado).
- `revokeRefreshTokens` y **revocación del token de Sign in with Apple** (REST de Apple, requisito de Apple al borrar la cuenta). El cliente hace `signOut` **solo local**.
- **Anti-zombie:** las reglas de Firestore **no** revisan la revocación de tokens, así que toda escritura exige `!exists(/databases/$(database)/documents/deletionRequests/$(request.auth.uid))`, y los callables rechazan si existe `deletionRequests/{uid}` o si `getUser(uid)` falla. Un test de barrido exige 0 documentos con el uid salvo los declarados, incluso si el cliente sigue escribiendo con el token viejo.
- Si hay una suscripción activa se avisa: "Tu suscripción sigue activa en la tienda: cancélala aquí".

**Export:** JSON con fechas ISO-8601 en Storage y URL firmada de 72 h, 1 vez cada 24 h. Incluye Auth, `users`, `profiles`, `consentEvents`, celda, waves, blocks, reportes enviados, metadatos de chats y mensajes propios, entitlements y archivos. Hay test de esquema.

**Moderación:**
- `reportUser` → puntaje de prioridad (menor y sexual primero) → `moderationQueue` → consola mínima con custom claim `moderator` y **acciones auditadas** (advertir, suspender con Auth disable, banear).
- **Preservación de evidencia:** al reportar, el servidor copia los últimos N mensajes del chat a `reports/{id}/evidence` con *legal hold*, de modo que el borrado de cuenta no los elimina.
- **SLA por severidad, medido:** posible menor y amenazas ≤ 2 h; resto ≤ 24 h. Cada reporte genera una alerta. El copy de "lo revisamos en…" se muestra solo si la medición existe.
- **Protocolo con autoridades y CSAM:** preservación, escalamiento y contacto designado, documentados en `docs/ops/runbooks/`.
- Con N reportes únicos en 24 h, la persona se **oculta de Cerca** hasta la revisión.
- El claim `banned` se respeta en reglas y callables.
- El SLA se mide en BigQuery y hay alerta a las 20 h.
- **Mensajes:** el texto marcado por el filtro (lista es-CL versionada con casos positivos y negativos) queda `pending` y no se entrega hasta la revisión. Se avisa al emisor y nunca se reescribe en silencio.

**Fotos:**
- `photoUrl` no lo escribe el cliente: se usa el path propio del bucket.
- Storage acepta solo `jpeg`, `png` y `webp`, con nombre fijo y delete del dueño.
- El trigger `onObjectFinalized` re-encodea **sin EXIF/GPS**, redimensiona y aplica SafeSearch antes de publicar.
- `blurhash` como placeholder y fotos también en web.

**Verificación selfie** (flag `verification_enabled`, apagado): abstracción de proveedor (D-10), consentimiento biométrico separado, borrado del template y filtro "solo verificados" **gratis**.

**Requisitos de tiendas:**

| Plataforma | Requisitos |
|------------|------------|
| Apple | 1.2 (UGC: filtro, reporte, bloqueo, contacto publicado y acción sobre reportes); 5.1.1(v) (borrado in-app); 4.8 (Sign in with Apple, con la capability en `Runner.entitlements`); 3.1.1 y 3.1.2 (IAP y suscripciones); `PrivacyInfo.xcprivacy` (verificar si aplica). |
| Google Play | UGC, Data safety, borrado de cuenta in-app **y vía web** (`/eliminar-cuenta` funcional, no solo informativo) y Play Billing (User Choice Billing no está disponible en Chile). |
| Ambas | `docs/store/data-map.md` (dato → propósito → Privacy Label / Data safety), cuestionario de edad, notas de revisión con **cuentas de prueba reales en una geocerca de revisión** (sin datos demo en producción) y `fastlane/metadata` en es-CL. |

**Auth por teléfono:** política de regiones SMS restringida a +56, cuotas y alerta de costo de OTP para frenar el *SMS pumping*. App Check también en Auth (si aplica a la versión verificada).

**Licencias:** `LicenseRegistry.addLicense` para Inter (OFL), visible en la página de licencias.

**Hosting:** cabeceras CSP compatibles con Flutter web, `frame-ancestors 'none'`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy: geolocation=(self)` y `X-Content-Type-Options: nosniff`. Se verifican con `curl -I` en el preview channel.

### 7.7 Monetización y crecimiento (Plus apagado hasta el gate de liquidez)

**Principios:**
- Primero liquidez: con el ARPU esperado, el crecimiento tiene que ser **orgánico**, porque el techo de CPI es ~US$0,16 para LTV/CAC ≥ 3.
- El loop central es gratis para siempre (I14).
- Las palancas se controlan **por zona** con Remote Config.
- Todo precio sale de la tienda (gate: no hay literales de precio en `lib/` fuera de demo).

**Mercado verificado** (App Store Chile, 07-10-2026):

| App | Precios |
|-----|---------|
| Bumble For Friends Premium | 1 mes $12.900–13.900 · 3 meses $22.900–24.900 · 6 meses $39.900 · Spotlight 1×$2.200, 5×$5.500 |
| Bumble Premium | 7 días $6.900 · 1 mes $12.900 |
| Tinder Gold | $5.200–17.900 |

La propuesta de la v1 ($4.990/mes) queda en ~37% de BFF.

**Arquitectura de precios** (hipótesis; **los precios finales los aprueba el humano**, D-07):

| Producto (ID) | Propuesta | Notas |
|---------------|-----------|-------|
| `plus_monthly` | A/B: **$4.990** vs **$6.990** | Experimento de RevenueCat con guardrails |
| `plus_quarterly` | $11.990 / $14.990 | — |
| `plus_annual` | $29.990 / $39.990 ("Ahorra ~50%") | Trial de 7 días **solo** en el anual |
| Precio fundador (lista de espera) | anual $19.990 el primer año | Offer code / intro offer |
| `pass_weekend` (sin renovación) | $1.990 vie-dom | Captura a quien no se suscribe |
| `boost_1` / `boost_5` | $1.990 / $5.990 | Ledger + garantía de vistas |
| `plus_plus` (más adelante) | ~$11.990 | Solo si la conversión a Plus es ≥ 3% |

**Qué incluye Plus** (validado en el servidor, con un test de bypass por cada beneficio):
- saludos ilimitados con límite de velocidad;
- radio de 10 km (solo cuando el test de cobertura esté verde);
- nota en el saludo;
- **incógnito** (`incognito` lo escribe el servidor según el entitlement; distinto de `isVisible`);
- "Visitas a tu perfil";
- filtros avanzados;
- 1 Destacar a la semana;
- deshacer saludo;
- "Explorar otra comuna" (Plus+).

**Reciprocidad (D-05):** quien no es visible no ve Cerca, salvo con Plus incógnito.

**Webhook v2:**
- `defineSecret` y, en cada evento, se reconcilia contra la **API REST de RevenueCat** como fuente de verdad.
- Se ignora `environment != PRODUCTION` en prod.
- Se manejan TRANSFER, BILLING_ISSUE, PRODUCT_CHANGE y UNCANCELLATION.
- `NON_RENEWING_PURCHASE` va **solo al ledger** y nunca toca `plus`. Hay orden por `event_timestamp_ms`.
- Tests de tabla: el boost no revoca Plus · un evento viejo no pisa uno nuevo · sandbox ignorado · lifetime sin `expiresAt` = activo · Bearer inválido = 401.

**Paywall (Apple 3.1.2 + Ley 19.496/21.398):**
- `PfPlanCard` ×3 con el anual preseleccionado y equivalente mensual tabular, 4 beneficios con ícono, **X visible desde el primer frame**, Restaurar real, renovación automática explicada, links legales y precios desde `StoreProduct`.
- Aviso de retracto o reembolso (verificar el art. 3 bis b con un abogado).
- **Disparadores:** cupo agotado, radio > 5 km, incógnito, visitas, nota y la 3.ª conversación con respuesta. Como máximo 1 vez cada 48 h y **nunca dentro de un chat**.
- **Holdout** del 10% sin paywall.

**Lista de espera real:** `joinWaitlist` con zona aproximada calculada en el servidor, origen y código de referido, más un contador por zona sharded. Copy honesto: "Te avisamos cuando Plus llegue a Ñuñoa".

**Growth:**
- **Referidos** por WhatsApp con App Links / Universal Links (`assetlinks.json` + AASA validados en CI), `/i/:code` con OG y atribución en el servidor.
- La recompensa (1 Destacar o 7 días de Plus) se entrega **cuando el invitado completa su perfil y recibe un saludo aceptado**. Antifraude: App Check, dispositivo y tope mensual. Validar contra Apple 3.1.1/3.2.2 y Play.
- `/u/:handle`: perfil compartible sin distancia; para saludar hay que entrar.
- **Retención:** push transaccionales (saludo recibido / aceptado / mensaje), horario silencioso 22:00–09:00 (America/Santiago), como máximo 3 push no transaccionales al día, digest semanal opt-in y el ritual **"Hora Picaflor"** por zona (flag).
- **Playbook de lanzamiento** (`docs/growth/launch.md`): *atomic networks* por zona.
  - Cada zona abre solo con lista de espera ≥ N (default 300).
  - Secuencia sugerida: 2 campus + Providencia / Ñuñoa / Santiago Centro (D-14), con embajadores y un Panorama semanal.
  - Go/no-go para encender Plus por zona: ≥ 60% de las sesiones con ≥ 5 activos a ≤ 3 km durante 14 días, aceptación de saludos ≥ 35%, reportes < 5 por cada 1.000 usuarios activos.
- **Fase X** (detrás de flags, solo diseño + modelo de datos hasta aprobación): **Panoramas** (eventos presenciales; pago fuera de IAP permitido por Apple 3.1.3(e), boleta SII) y **Lugares** B2B ("Patrocinado", métricas agregadas por comuna, nunca datos personales). Sin anuncios programáticos (ADR).

**Medición:**
- `firebase_analytics` con consentimiento, la taxonomía de la §7.6 de la v1 + `nearby_viewed{count_bucket, radius, zone}`, `waitlist_joined`, `first_wave_sent`, `invite_sent`, `paywall_viewed{trigger}`. Cada evento tiene su test de emisión y el gate rechaza claves con PII.
- Export a BigQuery y eventos de servidor por log sink.
- SQL versionado en `analytics/` para liquidez por zona, North Star, embudo, D1/D7/D30, paywall→compra, trial→pago, MRR, ARPPU, churn, reembolsos, k-factor y costo por MAU.
- Tablero en Looker Studio.

**Unit economics** (`docs/product/unit-economics.md` con script; los supuestos van marcados):
- Neto por Plus de $4.990: ≈ $3.514 CLP (70,4% del bruto, con IVA 19%, 15% de tienda y 1% de RevenueCat).
- ARPMAU ≈ US$0,10 (3% de conversión).
- Equilibrio ≈ 34k MAU con la infra optimizada y 3M CLP/mes de costos fijos (supuesto).
- **Condición necesaria:** Cerca ≤ US$0,02/MAU (§7.3). Con el diseño actual (US$0,15–0,21) cada usuario gratis destruye margen.

### 7.8 Operación, SRE y seguridad de la cadena

**Entornos:**
- Proyectos `picaflor-dev`, `picaflor-stg` y `picaflor-prod` (los crea el humano, I4), con aliases en `.firebaserc` y `firebase_options` por flavor.
- Deploy por entorno, con aprobación manual para prod.
- Las pruebas de carga corren solo en stg.

**CI/CD:**
- Toolchain fijado.
- Jobs: format, analyze, test + cobertura con umbral, gates, build web demo (presupuesto de bundle), backend, emuladores, E2E del loop, build Android (release sin firma con keystore efímero) y build iOS `--no-codesign` (runner macOS).
- Preview channels de Hosting en dev.
- **OIDC / Workload Identity** en vez del JSON de service account. Actions **fijadas por SHA** y `permissions: contents: read` por defecto.
- **CD por canales:** tag → staging → prod con una GitHub Environment que exija revisor; Play internal testing (fastlane `supply`) y TestFlight (fastlane `pilot`) automatizados con Play App Signing; `versionCode` derivado del CI.
- Dependabot semanal (pub, npm ×2 y actions), secret scanning con push protection + gitleaks en CI, CodeQL (TS), `npm audit --omit=dev --audit-level=high` como gate, SBOM CycloneDX por release y chequeo de licencias.
- `concurrency` por rama.

**Observabilidad:**
- Crashlytics y Performance Monitoring sin PII.
- Logs estructurados (`callable`, `latency_ms`, `reads`, `result`).
- **SLOs:** usuarios sin crash ≥ 99,5%; `getNearby` p95 < 800 ms; error de callables < 1%; push entregados ≥ 95%.
- Alertas (error de callables > 2% en 5 min, p95 de `getNearby` sobre el objetivo, reportes de posible menor sin triage > 2 h, budget al 50/90/100%) y *error budget*. Logs con `uidHash = HMAC(uid)`, nunca el uid en claro.
- **PITR activado + export diario** en la misma región, con un **simulacro de restauración** probado y registrado.
- `docs/ops/`: matriz de severidad, on-call (titular y respaldo) y runbooks (`getNearby` degradado, App Check, pico de costo, brecha de datos, abuso masivo, CSAM, solicitud de autoridad, restauración, revisión de tienda), más plantillas de comunicación a usuarios y a la Agencia de Protección de Datos. Simulacro trimestral.

**App Check:**
- Pedir el **aumento de cuota de Play Integrity** (10k/día por defecto; el aumento tarda hasta 1 semana) **≥ 2 semanas antes de la beta**.
- ADR con el TTL del token. `consumeAppCheckToken` (replay protection) en `deleteAccount`, `exportMyData` y `sendWave`.
- Alerta al 70% de la cuota.

---

## 8. QA/QC

### 8.1 Gates duros (`tool/verify.sh`; cualquier exit ≠ 0 bloquea)

| Área | Checks |
|------|--------|
| Flutter | `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos` (con el Flutter **fijado**) · `flutter test --coverage` + umbral por capa (script sobre lcov) |
| Gates AST | `tool/gates/` con `package:analyzer`, en vez de grep. Reglas:<br>• prohibidos fuera de `design_system`: `AppColors.`, `isDark ?`, `Colors.(white\|black)`, `Radius.circular(n)`, `withValues(alpha:`, `fontWeight:`, `TextStyle(`, `Duration(milliseconds:`, `HapticFeedback.`, `Icons.*_outlined`, `(width\|height\|size): <n>`;<br>• `IconButton` sin tooltip;<br>• `Text('literal')` fuera de l10n;<br>• logs con uid, email, lat, lon, token o phone;<br>• imports de `Demo*` desde presentation o desde los providers de prod;<br>• literales de precio;<br>• runtimes EOL en `engines`.<br>Cada regla tiene **fixtures que deben fallar**. |
| Ratchet | `tool/gates/baseline.json` con los conteos actuales, que solo pueden bajar. |
| Build web | `flutter build web --release` con el flavor dev y el presupuesto de bundle. |
| Backend | `functions`: `npm ci && npm run lint && npm run build && npm test`. |
| Emuladores | `firebase emulators:exec --only auth,firestore,functions,storage` con los tests de reglas, de Storage, de integración de callables y el **E2E del loop**. |
| Ataque | `tool/attack/trilaterate.ts`, con umbral. |
| PR | Checks de tamaño y de rutas protegidas. |

### 8.2 Tests de contrato
- Cada escritura a Firestore y cada payload de callable que produce el código Dart se exporta como **fixture JSON** en `contracts/`.
- `firestore-tests` y los tests de functions los usan como casos *allow*, junto con ≥ 2 variantes maliciosas *deny*.
- Si Dart y TS divergen, el CI queda rojo. Esto cierra la clase de bugs de V-08.

### 8.3 Matriz de goldens (alchemist o `matchesGoldenFile`, generada **solo** en el CI Linux)
- Tamaños: 375×667 · 412×915 · 820×1180 · 1440×900.
- Temas: light y dark.
- Escalas de texto: 1,0 y 1,3, más 2,0 en onboarding, login, Cerca, ficha, chat y paywall.
- Inter se carga en `flutter_test_config.dart`.
- Los PNG se suben como artefacto, y el diff antes/después va al PR.

### 8.4 Pirámide de tests
- **Unit:** puros y application, con cobertura ≥ 85%.
- **Widget:** cada `Pf*` y cada pantalla × estado.
- **Providers:** `ProviderContainer` + fakes, incluido el test "prod no resuelve `Demo*`".
- **Reglas:** ≥ 80 casos (colección × get/list/create/update/delete × dueño/extraño/bloqueado/baneado/no autenticado) + las 20 sondas de la auditoría.
- **Storage rules.**
- **Functions:** integración en el emulador para todos los callables (§7.2) y los triggers, con concurrencia (25 `sendWave` simultáneos dan exactamente el cupo).
- **Patrol:** onboarding → permisos (concedido / denegado / denegado permanente / servicio apagado / fuera de cobertura) → loop completo → paywall en sandbox → restaurar.
- **Carga:** k6 o Artillery en stg con 50k sintéticos y 200 req/s.

### 8.5 Red Team: ataques mínimos (R los ejecuta y documenta)
1. Trilaterar con `getNearby` desde 3 cuentas y 100 sondas.
2. Enumerar uids y armar un directorio de perfiles.
3. Leer `locations`, `users` ajenos, `reports` o `entitlements`.
4. Reescribir `participantIds` o `status`.
5. Escribir después de un bloqueo, por cualquier vía.
6. Carrera del cupo de saludos con N llamadas concurrentes.
7. Acoso: re-saludar después de un `ignored`, incluso con Plus.
8. Escribir `entitlements`, `birthDate`, `lastActiveAt` o `consents`.
9. Ejecutar `exportMyData` o `deleteAccount` de otra persona, o con una sesión robada (`auth_time`).
10. Webhook sin firma, con un evento viejo o desde sandbox.
11. Saltarse el paywall desde el cliente (incógnito, radio, nota).
12. Usar `photoUrl` como píxel de rastreo; subir un SVG o una foto con EXIF/GPS.
13. Denial-of-wallet con `getNearby` o `exportMyData`.
14. Replay de un token de App Check.
15. UI con texto al 200% en 320 px; TalkBack en el loop.
16. Instalar un build de release con `DEMO_MODE` por defecto.
17. Escribir en Firestore con el token viejo después de pedir el borrado de la cuenta (zombie).
18. *SMS pumping*: pedir OTP a números fuera de +56 o en ráfaga.
19. Borrar la cuenta para destruir la evidencia de un reporte (el *legal hold* debe sobrevivir).

---

## 9. Decisiones humanas

**Cola no bloqueante:** el agente implementa el **default reversible** detrás de un flag y sigue trabajando. La tarea `T006` copia esta tabla a `docs/v2/DECISIONS.md`, donde el humano responde con fecha.

| ID | Decisión | Recomendación (default implementado) | Fecha límite |
|----|----------|--------------------------------------|--------------|
| D-01 | Qué hacer con la rama y el PR #1 de Grok | Usar `155b6f6` como base de `v2/integration`, sin partirlo retroactivamente (esta auditoría cuenta como su revisión). El humano cierra el PR #1 cuando exista el PR de integración. | W0 |
| D-02 | Región de producción | **`southamerica-west1` (Santiago)**: Firestore y Functions 2.ª gen están disponibles, la latencia es menor y evita la transferencia internacional. Los defines dev/stg ya apuntan ahí. **Nunca default para crear prod.** | Antes de crear prod |
| D-03 | Entorno de ejecución del agente | WSL2 Ubuntu 24.04 en el PC del dueño, o Codespaces | W0 |
| D-04 | Isotipo final | Encargar a un diseñador. Default: placeholder geométrico SVG "provisorio" (no se envía a tiendas). | W3 |
| D-05 | Reciprocidad de visibilidad | Quien no es visible no ve Cerca. Incógnito = Plus. | W2 |
| D-06 | Bucket mínimo de distancia | "A menos de 500 m" + ruido estable por par | W2 |
| D-07 | Precios y experimento | A/B $4.990 vs $6.990 mensual; anual $29.990 / $39.990; fundador $19.990; Pase Finde $1.990; Destacar $1.990 / $5.990. **Nunca se cobra sin aprobación.** | Antes de encender Plus |
| D-08 | Umbral de liquidez | 60% / 5 activos / 3 km / 14 días + aceptación ≥ 35% + reportes < 5‰ | W5 |
| D-09 | Mapa | Radar abstracto. El mapa geográfico (solo tu zona) va con un proveedor de licencia comercial: el contrato lo firma el humano. | W3 |
| D-10 | Proveedor de verificación selfie | Flag apagado y abstracción lista | W4 |
| D-11 | Quién modera y con qué SLA | Copy sin SLA hasta que exista una persona asignada | W4 |
| D-12 | Textos legales y DPO | Borradores marcados. **Nunca default.** | **2026-11-15** |
| D-13 | Proyectos Firebase, App Check, cuentas de tienda, RevenueCat | **Nunca default** (I4) | W2 / W5 |
| D-14 | Zonas de lanzamiento | 2 campus + Providencia / Ñuñoa / Santiago Centro | W5 |
| D-15 | Runtime de Node | 22 LTS (24 solo si se verifica el soporte) | W0 |
| D-16 | Upgrades mayores (`go_router` 18, `riverpod` 3, `google_sign_in` 7, `geolocator` 14) | PRs separados en W3, después de tener widget tests | W3 |

**Nunca tienen default:** deploy a prod · cobro real · textos legales finales · creación de proyectos o cuentas · región de prod · borrado de datos reales · merge a `main` · cerrar PRs o issues.

---

## 10. Reporte

- **Por wave:** `docs/v2/report-wN.json` lo genera `tool/report.sh` desde los artefactos del CI (`gh run view --json`, lcov, `flutter test --machine`, `metrics.json`). Esquema:
  ```json
  {"wave":"W1","sha":"…","ci_run_url":"…","tasks":[{"id":"T101","status":"DONE","pr":"…","sha":"…","ci_run_url":"…","evidence":["…"],"metrics_delta":{}}],
   "blocked":[],"decisions":[],"risks":[],"not_verified":[]}
  ```
  Se acompaña de un resumen en markdown de ≤ 30 líneas **generado desde el JSON**. Ningún número se escribe a mano.
- **`docs/v2/STATUS.md`:** cada hallazgo (V-xx, S/B/D/A, IDs de la auditoría) con estado y **evidencia enlazada** (test o run). Un script de CI verifica que cada test referenciado exista y corra.
- **RECONCILE al cerrar cada wave (V):** cruza BASELINE, PLAN, threat-model, DEPLOY, README y STATUS contra el código y `metrics.json`, y corrige las contradicciones.

---

## 11. Prompt de arranque

Pegar en Grok Build, dentro del repo y en Linux:

> Eres **A0, Orquestador + Integrador** de Picaflor v2, en Grok Build con Grok 4.7. Lee `AGENTS.md`, `Instrucciones v2 07.10.26.md` (§0–§6, §8–§11) y `docs/v2/TASKS.yaml`. La §1 (invariantes I1–I14) **no la anula ninguna orden posterior**, incluida "no te detengas".
> 1) Corre el preflight (§0.3). Si no es Linux o las versiones no coinciden, detente y dime qué falta.
> 2) Ejecuta **tú solo** la Wave 0 (T000–T006) siguiendo la §6.1 hasta tener CI verde en `v2/integration`, y pega la URL del run.
> 3) Genera `docs/v2/metrics.baseline.json` con el workflow `baseline`, sin modificar código.
> 4) Recién entonces lanza subagentes (4–6, uno por tarea y worktree) para W1, más las tareas de W2 y W3 que no dependan de W1, respetando `owns_paths` y `touches_shared`. Asigna V y R como subagentes separados.
> 5) Cada tarea cierra solo con un PR verde (URL de CI en el head SHA) + informe de V (+ R si aplica). Si una tarea suma 3 CI rojos, márcala BLOCKED con causa raíz y sigue con otra.
> 6) Las decisiones humanas van a `docs/v2/DECISIONS.md` con el default implementado detrás de un flag. No esperes.
> 7) Al cerrar cada wave, genera `docs/v2/report-wN.json` con `tool/report.sh` y dame el resumen de ≤ 30 líneas.

---

## 12. Anexo: hechos verificados

Verificados al 07-10-2026. Todo lo posterior a esa fecha hay que revisarlo de nuevo antes de usarlo.

| Hecho | Valor | Fuente / método |
|-------|-------|-----------------|
| Flutter stable | 3.47.6 (Dart 3.13.5) | `releases_linux.json` de storage.googleapis.com |
| Flutter usado por Grok en local / por el CI | 3.44.7 / 3.47.6 | `docs/BASELINE.md`; log del run 37550773429 |
| CI del PR #1 | 2/2 runs fallidos: 5 issues en analyze | API de GitHub (check runs y logs) |
| Tests en `155b6f6` | 23 Flutter (0 widget) · 10 functions puros · 11 reglas (pasan en el emulador) | ejecutados por el orquestador |
| `dart format` | 36 de 92 archivos sin formato | ejecutado |
| Bundle web gz (demo) | `d3b103e`+v1: 981.256 B → `155b6f6`: 1.052.440 B (+7,3%) | build + gzip |
| Node 20 en Cloud Functions | deprecado 2026-04-30, decomisionado **2026-10-30** | docs.cloud.google.com/functions/docs/runtime-support (lente de escala) |
| `southamerica-west1` (Santiago) | Firestore ✅, Functions 2.ª gen ✅ (Tier 2 de precios) | firebase.google.com/docs/firestore/locations y docs de functions (lente de escala) |
| Precio de lectura de Firestore (por 100k) | east1 US$0,045 · west1 US$0,043 | cloud.google.com/firestore/pricing (lente de escala) |
| Cuota de Play Integrity | 10.000/día por defecto; el aumento tarda hasta 1 semana | developer.android.com/google/play/integrity |
| Grok 4.7 | lanzado el 2026-09-21; 500k de contexto; US$2 / US$6 por 1M (el doble con prompts ≥ 200k); corte de conocimiento mayo 2026 | docs.x.ai (lente de orquestación). **Verificar.** |
| Grok Build | CLI con subagentes en worktrees, `AGENTS.md`, headless `-p` | x.ai/news (lente de orquestación). **Verificar con `grok --help`.** |
| Comisiones | Apple Small Business 15% · Google Play suscripciones 15% · RevenueCat 1% sobre US$2.500 MTR | fuentes públicas (lente de monetización) |
| IVA a servicios digitales | 19% | SII |
| Google Play User Choice Billing en Chile | no elegible | support.google.com/googleplay/android-developer/answer/13821247 |
| Ley 21.719 | plena vigencia el **2026-12-01** (55 días) | v1 §S12. **Validar con un abogado.** |
| URL de privacidad por defecto (`picaflorapp.web.app/privacidad`) | HTTP 404 "Site Not Found" (Hosting sin desplegar) | `curl`, lente de production readiness |
| Retracto en contratos electrónicos | 10 días; se puede excluir en servicios si se informa antes del pago | Ley 19.496 / 21.398. **Validar con un abogado.** |

*Picaflor 🐦: primero que funcione y sea seguro, después que sea bello y al final que se pague solo. Las tres cosas, medidas.*
