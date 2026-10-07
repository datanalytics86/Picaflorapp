# ADR 0006 — Isotipo provisorio

## Contexto

La app usaba `Icons.pets_rounded` para un picaflor. El isotipo final no está aprobado.

## Decisión

`PfMark` dibuja un colibrí simple con `CustomPaint`. No es un SVG final ni se parece a marcas de terceros. Splash, login y ajustes lo usan. El shell todavía muestra una P de wordmark en la barra.

## Alternativas

Encargar el isotipo en esta sesión. Se descartó: la decisión de marca queda en la persona dueña del producto.

## Consecuencias

Hay que reemplazar `PfMark` cuando exista el archivo final. Hasta entonces no se manda a tiendas como identidad cerrada.
