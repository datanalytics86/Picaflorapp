# ADR 0003 — App Check falla cerrado

## Contexto

Los callables de Cerca, saludos, bloqueo, borrado y export son el único camino a las coordenadas. Sin App Check, un script con una sesión puede llamarlos.

## Decisión

Los callables usan `enforceAppCheck: true` en `southamerica-east1`. Si el humano aún no configuró App Check, la app de producción muestra vacío o error. Nunca rellena con personas de demo.

## Alternativas

Dejar App Check en modo monitor. Se descartó: el hallazgo S1 es P0 y un modo laxo deja la puerta abierta.

## Consecuencias

Un proyecto Firebase nuevo no tendrá Cerca funcional hasta registrar las apps en App Check. Eso es intencional.
