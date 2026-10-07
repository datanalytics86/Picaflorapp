# ADR 0004 — Tiles CARTO hasta elegir un mapa de pago

## Contexto

El mapa usa teselas públicas de CARTO sobre datos de OpenStreetMap. El plan gratuito no cubre un uso comercial sostenido, y la atribución es obligatoria.

## Decisión

Se queda el URL de CARTO, con el chip "© OpenStreetMap © CARTO". Un `--dart-define` de URL de teselas lo reemplaza sin cambiar código. Los pines de producción no usan la coordenada real: se dibujan en el anillo del bucket.

## Alternativas

Elegir MapTiler o Stadia ahora. Se descartó: implica una API key y un contrato que esta sesión no puede firmar.

## Consecuencias

Antes de abrir la app a desconocidos hace falta un proveedor con licencia comercial. El demo puede seguir con CARTO y la atribución visible.
