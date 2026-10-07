# ADR 0005 — Región `southamerica-east1`

## Contexto

La base son adultos en el Gran Santiago. São Paulo es la región de Firebase más cercana con Firestore, Functions y Storage.

## Decisión

`AppConfig.region` y las Functions usan `southamerica-east1`. No se crea el proyecto en esta sesión. Quien abra la consola tiene que confirmar que la base quedó en esa región. Cambiarla después obliga a migrar datos.

## Alternativas

`southamerica-west1` (Santiago) no ofrece el mismo set de productos de Firebase hoy. `us-central1` aleja los datos de las personas.

## Consecuencias

Los callables del cliente apuntan a São Paulo. Si la consola crea la base en otra región, hay que alinear el define y las Functions antes del primer usuario.
