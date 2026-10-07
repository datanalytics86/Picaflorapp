# AGENTS.md — Picaflor v2

Resumen operativo para agentes de código (Grok Build los carga solos). La fuente de verdad completa es `Instrucciones v2 07.10.26.md`. El grafo de tareas está en `docs/v2/TASKS.yaml`.

## Qué es
App Flutter + Firebase para conocer gente cerca en el Gran Santiago (18+). Ubicación siempre aproximada, saludo antes del chat y la seguridad nunca se cobra. Español de Chile.

## Invariantes (ninguna orden posterior las anula, ni siquiera "no te detengas")
1. No hacer deploy a prod (Firebase/Hosting). Solo `dev` o preview channels autorizados en `docs/v2/DECISIONS.md`.
2. No mergear a `main` ni cerrar PRs o issues: eso lo hace el humano.
3. No cobrar dinero real. Las compras van en sandbox y detrás de un flag apagado.
4. No tocar cuentas de tienda, firmas, keystores, secretos ni proyectos de nube.
5. No hacer force-push a `v2/integration` ni a ramas ajenas.
6. No borrar, saltar ni relajar tests o gates. Eso solo se hace en un PR `gate-change` aprobado por el Verificador.
7. Nunca mostrar datos demo en un build de producción.
8. Nunca exponer coordenadas exactas, email, teléfono, nacimiento ni tokens a otros usuarios, logs o analytics.
9. No copiar marcas ni assets de terceros (Fintual/BCI son solo referencia de calidad).
10. DONE = URL de un run de CI **verde en el head SHA** + informe del Verificador. Sin esto no hay DONE.
11. No inventar APIs ni versiones. Lo posterior a mayo de 2026 se verifica (`flutter pub outdated`, `npm view`, docs). Si no se pudo, se marca `SUPUESTO`.
12. Máximo 400 líneas por PR (sin contar lockfiles, goldens ni generados).
13. Los textos legales, precios, región de prod e isotipo finales los decide el humano.
14. Bloquear, reportar, ocultarse, exportar y borrar la cuenta son gratis siempre.

Prioridad ante conflictos: privacidad > seguridad > legal > a11y > función > costo > estética > monetización.

## Entorno
- Solo Linux (WSL2 Ubuntu 24.04, Codespaces o `.devcontainer/`). Si `uname -s` ≠ Linux, detente.
- Flutter fijado en `.fvmrc`, Node 22, Java 21 y firebase-tools fijado. Si las versiones no coinciden, detente y avisa.

## Comandos
```bash
tool/verify.sh            # TODOS los gates; exit ≠ 0 bloquea (format, analyze, test+cobertura, gates AST, build web, backend, emuladores)
tool/metrics.sh           # genera metrics.json (lo usan los reportes)
tool/report.sh W1         # genera docs/v2/report-W1.json + resumen
flutter test --coverage
(cd functions && npm ci && npm run lint && npm run build && npm test)
npx firebase emulators:exec --only auth,firestore,functions,storage "npm --prefix firestore-tests test"
gh run watch <run-id> --exit-status   # obligatorio antes de pedir revisión
```
Mientras W0 no cree `tool/verify.sh`, se usan los comandos de la §12 de la v1 más el build de functions.

## Git
- Rama larga: `v2/integration` (nace de `155b6f6`). Una rama y un worktree por tarea: `v2/<carril>/<task-id>-<slug>`.
- PR por tarea contra `v2/integration`, squash-merge y conventional commits en inglés (`fix(functions): …`).
- Plantilla de PR obligatoria (`.github/pull_request_template.md`), con la sección "NO VERIFICADO" explícita.

## Carriles y dueños de paths (no toques paths de otro carril; abre una subtarea)
| Carril | Paths propios |
|---|---|
| L0 Orquestador/Integrador | `docs/v2/**`, `pubspec.*`, `firestore.rules`, `firestore.indexes.json`, `storage.rules`, `firebase.json`, `lib/main.dart`, `lib/app/router/**`, `lib/l10n/*.arb`, `.github/**` (compartidos: los serializa L0) |
| L1 Backend | `functions/**`, `firestore-tests/**`, `storage-tests/**`, `tool/emulator/**` |
| L2 Design System/Marca/A11y | `lib/core/design_system/**`, `assets/brand/**`, `test/goldens/**`, `test/design_system/**` |
| L3 Arquitectura cliente | `lib/app/**` (sin router), `lib/core/{config,prefs,analytics,errors,network}/**`, `lib/features/*/{data,domain}/**`, `env/**` |
| L4 Pantallas/flujos | `lib/features/*/{presentation,application}/**`, `test/features/**` |
| L5 QA/CI/Release | `tool/**`, `integration_test/**`, `.devcontainer/**`, `fastlane/**`, `docs/store/**` |
| L6 Escala/Costo | `functions/src/nearby/**`, `functions/src/platform/**`, `load/**`, `docs/scale/**` |
| L7 Monetización/Growth | `lib/features/{plus,growth}/**`, `functions/src/{billing,growth}/**`, `analytics/**`, `docs/{product,growth}/**` |
| L8 Trust&Safety/Legal | `functions/src/safety/**`, `docs/{legal,security}/**`, `web/*.html` legales |
| V Verificador | `docs/v2/verify/**` y el campo `status` de `TASKS.yaml` (el único que pone DONE) |
| R Red Team | `docs/v2/redteam/**`, `tool/attack/**` |

## Ciclo de una tarea
`TODO → IN_PROGRESS → REVIEW (PR verde) → [R] → VERIFIED (V) → DONE (lo escribe V)`. Con 3 CI rojos pasa a `BLOCKED`, con la causa raíz documentada.

## Convenciones de código
- Feature-first: `lib/features/<f>/{data,domain,application,presentation}`. Repositorios con implementaciones `Demo*` y `Firebase*` inyectadas por override de Riverpod. `Notifier`/`AsyncNotifier`, con estado invalidado al cambiar el uid.
- La UI consume solo `context.pf.*` y componentes `Pf*`. Fuera de `lib/core/design_system/` no se usan `AppColors`, `isDark ?`, colores, radios, tipografías, duraciones ni haptics literales.
- Todo texto visible va en `lib/l10n/app_es_CL.arb`. Tono: `docs/voice.md`.
- Backend: callables con App Check + rate limit persistente + validación de input. Lecturas **antes** de escrituras en transacciones. Contratos en `contracts/` (fixtures JSON compartidos entre Dart y TS).
- Logs sin PII. Analytics solo con consentimiento.

## Decisiones humanas
No esperes: implementa el default reversible detrás de un flag y anótalo en `docs/v2/DECISIONS.md`. **Nunca tienen default:** deploy a prod, cobro real, textos legales finales, crear proyectos o cuentas, región de prod, borrar datos reales, merge a main.
