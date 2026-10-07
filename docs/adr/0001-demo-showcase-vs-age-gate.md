# ADR 0001 — El demo abre Inicio; la edad corre cuando hay onboarding

## Contexto

El showcase web tiene que abrir `/home` sin fricción. La tienda exige un control de 18+ y términos no pre-marcados antes de usar la app real.

## Decisión

`main.dart` en `DEMO_MODE` marca el onboarding como hecho para que el demo llegue a Inicio. Si el onboarding corre (producción, o demo si se borra esa preferencia), la tercera página pide fecha de nacimiento y aceptación de términos. Saltar solo avanza a esa página. No llama a terminar.

## Alternativas

Pedir la edad también en el demo. Se descartó porque rompe el showcase que ya está publicado como demo.

## Consecuencias

Un build con `DEMO_MODE=true` no demuestra el gate. El gate se prueba en `test/v2_policy_test.dart` (`AgeGate`) y hay que recorrerlo a mano con `DEMO_MODE=false`.
