# Sincronizacion tablet <-> PC

Estado documentado: 4 de agosto de 2026. Contrato HTTP: `1.0`.

## Principios protegidos

- SQLite sigue siendo la fuente operativa de la tablet y la aplicacion funciona
  sin red.
- Nunca se envia el archivo completo `app_catalogo.db`.
- Cada cambio local y su evento outbox se confirman o revierten juntos.
- Un cambio remoto se aplica en una transaccion y no genera eco en el outbox.
- La credencial del dispositivo se guarda con `flutter_secure_storage`.
- La IP es solo una cache. La identidad permanente es `serverId` mas la
  credencial vinculada.
- Un `PRODUCT` siempre se transporta como agregado completo; sus variantes,
  ejes y atributos no son entidades de transporte independientes.

## Organizacion

```text
features/sync/
  domain/
    entities/       configuracion, QR, estado y resultado
    repositories/   contrato publico del modulo
  data/
    contracts/      unica fuente de versiones y limites
    datasources/    SQLite, HTTP, credenciales seguras y mDNS
    mappers/        registro generico y mapper exclusivo de PRODUCT
    models/         DTO separados por registro, push, pull, bootstrap y archivos
    repositories/   coordinacion del ciclo completo
  presentation/
    bloc/            estado, exclusion mutua y backoff automatico
    dialogs/         QR, descubrimiento, direccion manual y fuente inicial
```

No se mantienen carpetas vacias ni una capa `usecases` sin consumidores.

## Esquema SQLite v24

La migracion v23 permanece intacta. v24 evoluciona la misma base
`app_catalogo.db` y conserva los datos existentes.

- `sync_queue`: outbox con `payload_version`, `schema_version`, checksum
  opcional, version base, reintento y resultado del servidor.
- `sync_configuration`: identidad publica, cache de direccion y versiones del
  contrato; nunca almacena el token.
- `sync_state`: separa `last_pull_cursor`, `last_ack_cursor` y
  `pending_ack_cursor`; tambien conserva snapshot, bootstrap e inicializacion.
- `sync_entity_state`: version remota por entidad.
- `sync_inbox`: idempotencia y auditoria de cambios recibidos.
- `sync_conflicts_local`: conserva el `backend_conflict_id` sin reemplazarlo.
- `sync_file_queue`: upload/download, intent, storage key, reintento y estado.
- `sync_runtime_context`: evita generar outbox al aplicar informacion remota.

Las tablas locales con ID entero reciben un `sync_id` UUID estable sin cambiar
sus claves primarias. Los triggers de las tablas secundarias de producto
coalescen un unico evento `PRODUCT` cuyo `entityId` es el ID de la familia.

## Vinculacion y descubrimiento

El QR oficial no necesita contener una IP. Incluye `serverId`, nombre, codigo,
tipo de servicio y `apiContractVersion`. La tablet localiza la PC por mDNS y
verifica su endpoint de descubrimiento antes de registrar el dispositivo.

La vinculacion manual solicita direccion temporal, codigo de vinculacion y
nombre de la tablet. La direccion por defecto usa el puerto `8081`. Una URL
descubierta o cacheada solo se acepta despues de validar:

1. `serverId` esperado.
2. contrato `1.0`.
3. token y `deviceId` de la tablet ya vinculada.

El tipo mDNS `_appcatalogo._tcp`, con o sin `.local` y punto final, se normaliza
al nombre base.

## Push, pull, ACK y bootstrap

1. Antes de iniciar trabajo nuevo se reintenta cualquier ACK pendiente.
2. Los archivos locales se cargan mediante intent -> content -> complete.
3. Solo despues de obtener `storageKey` se publica la entidad que lo referencia.
4. Push envia como maximo 100 eventos con contrato y versiones de payload.
5. Cada pagina pull se aplica en una transaccion SQLite y actualiza
   `last_pull_cursor`.
6. Inmediatamente se envia `POST /api/v1/sync/pull/ack`. Solo al confirmarse se
   actualiza `last_ack_cursor` y puede solicitarse la pagina siguiente.
7. Si el ACK falla, los datos aplicados no se revierten: queda
   `pending_ack_cursor` y la siguiente ejecucion reintenta primero ese ACK.

Bootstrap usa su modelo propio. La pagina 0 fija `snapshotCursor`, las paginas
siguientes deben conservarlo y `bootstrap_completed` solo se marca despues de
aplicar la ultima pagina. El cursor del snapshot queda pendiente de ACK.

Existe compatibilidad puntual con servidores 1.0 que respondan
`PULL_ACK_NOT_DELIVERED` despues del bootstrap: se realiza el primer pull desde
el snapshot para registrar la entrega y luego se confirma, sin saltar paginas.

## Fuente inicial

Al vincular se comparan datos utiles en PC y tablet:

- PC vacia y tablet con datos: la tablet crea una instantanea ordenada y la
  envia.
- PC con datos y tablet vacia: se ejecuta bootstrap desde la PC.
- Ambas vacias: vinculacion normal.
- Ambas con datos: la configuracion exige una eleccion explicita.

La instantanea local solo se genera cuando la tablet fue elegida como fuente.
Si se elige la PC, los eventos locales sin enviar se descartan y, al terminar
correctamente todo el snapshot, se podan registros que no existan en el
servidor. No se elimina informacion antes de completar el bootstrap.

## PRODUCT y archivos

`ProductSyncMapper` exporta y aplica `productos`,
`producto_variantes_catalogo`, `producto_familia_ejes`,
`producto_atributos` y `producto_atributo_opciones`. Los JSON locales se
decodifican a mapas/listas reales. La aplicacion ocurre dentro de la misma
transaccion que la pagina pull; cualquier error de variante, precio o relacion
revierte el agregado completo.

Los tipos se convierten explicitamente `simple/lista/matriz` <-
`SINGLE/LIST/MATRIX`; el estado usa `activo` <- `ACTIVE/INACTIVE/DELETED`.

Los archivos remotos se descargan por `storageKey`, se guardan en el directorio
de documentos de la app y se proyecta su ruta local con `applying_remote = 1`.

## Verificacion

```powershell
flutter test --no-pub test/core/database
flutter test --no-pub test/features/sync
flutter test --no-pub test/architecture/dependency_rules_test.dart
dart analyze
flutter build apk --debug --no-pub
```

Los fixtures de `test/features/sync/fixtures` reproducen los JSON del backend
para registro, descubrimiento, push, conflictos, pull, ACK, bootstrap, producto
y archivos.
