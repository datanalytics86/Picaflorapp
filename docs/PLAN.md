# Plan Picaflor v2

El megaprompt pedía frenar antes de la Fase 1. La orden de esta sesión fue ejecutar sin detenerse. Estas son las tajadas que quedan, cada una del tamaño de un PR, sobre `grok/picaflor-v2-061026`. No se mergea a `main` ni se despliega Firebase desde aquí.

## Hecho en esta rama

| Fase | Responsable | Criterio | Estado |
|------|-------------|----------|--------|
| 0 Línea base | A0 | `docs/BASELINE.md` con analyze y tests reales, CI en todas las ramas | Hecho, salvo el build web que se anexa al terminar |
| 1 P0 | A1 | S8, B1–B3, B7, B8, S9, S10 | Hecho en cliente y reglas |
| 2 Design system | A2 | Tokens, contraste AA, gate de literales | Hecho. Goldens no |
| 4 Ficha, saludo, ajustes, Plus | A4 | Estados vacíos honestos en producción | Hecho en los flujos nuevos |
| 5 Confianza | A5 | Bloqueo, reporte, edad, borrado, export | Hecho. La cola de moderación humana no existe |
| 6 Firebase | A6 | Reglas, callables, tests puros sin emulador | En curso en `functions/` |
| 7 Plus | A7 | Flag apagado, lista de espera, sin SDK de tienda | Hecho |

## Siguiente, en este orden

1. **A6** — Cerrar `npm test` en `functions/` y no desplegar.
2. **A3** — Sacar los `if (_isDemo)` que sigan en servicios hacia dos implementaciones. No migrar Riverpod 3 en el mismo PR.
3. **A11** — `lib/l10n/app_es_CL.arb` y cero strings en widgets nuevos. `docs/voice.md` ya fija el tono.
4. **A4** — Foto de perfil (Storage ya tiene reglas) e intereses editables.
5. **A8** — Semantics en ficha, chat, ajustes y onboarding. Widget tests de esos flujos.
6. **A0** — Screenshots antes/después cuando haya un dispositivo o un browser de verificación.

## Fuera de alcance hasta que una persona lo diga

Crear el proyecto Firebase, App Check, keystore, cuentas de tienda, compras reales, mapa de pago, texto legal definitivo, isotipo definitivo.
