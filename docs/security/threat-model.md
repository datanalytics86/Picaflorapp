# Modelo de amenazas (borrador)

Actores: una persona con cuenta, alguien sin cuenta, y quien opere la consola de Firebase. El dato que más duele es la coordenada exacta.

## Qué no puede hacer el cliente

- Leer o escribir `locations/{uid}`. Ahí vive el geohash de precisión 7. Solo el Admin SDK.
- Leer el email, el teléfono, la fecha de nacimiento o los tokens FCM de otra persona. Eso está en `users/{uid}`, solo el dueño.
- Crear un chat o reescribir `participantIds`. El chat nace en `respondWave`.
- Leer reportes. Puede crear el propio, con `reporterId` igual a su uid.
- Escribir `entitlements` o eventos de webhook.

## Qué sí ve otra persona con sesión

El perfil público: nombre, bio, intereses, foto, visibilidad. Cerca devuelve uid, bucket de distancia y bucket de actividad. El mapa dibuja el pin en un anillo, no en el punto real.

## Abuso

- Bloqueo: callable `blockUser`. Marca el chat `blocked` si existe. Un chat bloqueado no acepta mensajes.
- Reporte: el cliente crea `reports/{id}` con un motivo cerrado. No hay cola de moderación en este repo. Un humano tiene que leerlos en consola.
- Cupo de saludos: el cliente lo aplica en demo. La Function tiene que volver a aplicarlo. Si solo corre el cliente, se puede saltar.
- App Check obligatorio. Sin él, los callables rechazan. Ver ADR 0003.
- Borrado: `deleteAccount` con `confirm: ELIMINAR`. La página pública `/eliminar-cuenta` explica el plazo de 30 días. El texto legal sigue en borrador.

## Qué queda abierto

Foto pública legible por cualquier sesión (hace falta para el producto, y también permite acopio). Sin rate limit verificado en cliente. Sin prueba de reglas en emulador en esta máquina. La lista de Cerca en producción depende de que la Function filtre bloqueos; el cliente también filtra los uid que ya bloqueó en esta sesión.
