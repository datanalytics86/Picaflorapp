# ADR 0002 — Plus no enlaza el SDK de las tiendas

## Contexto

No hay cuenta de Play ni de App Store autorizada. `purchases_flutter` también complica el build web del CI.

## Decisión

`PLUS_ENABLED` sale en falso. La pantalla `/plus` anota una lista de espera y muestra los precios como propuesta. Restaurar compras explica que vivirá en la app de la tienda. El webhook de RevenueCat existe en Functions y no se despliega desde aquí.

## Alternativas

Integrar RevenueCat ya. Se descartó: sin cuenta de tienda no hay producto que cobrar, y la regla de trabajo prohíbe tocar esas cuentas.

## Consecuencias

Nadie puede pagar desde esta rama. Encender Plus es un PR aparte, con el flag y el SDK, cuando existan las cuentas.
