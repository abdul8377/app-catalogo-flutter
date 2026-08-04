# Sincronización tablet ↔ PC

Estado documentado: 4 de agosto de 2026.

## Principios protegidos

- SQLite es la fuente operativa de la tablet y la aplicación sigue funcionando
  sin red.
- Nunca se envía el archivo completo `app_catalogo.db`.
- Cada cambio local y su evento outbox se confirman o revierten juntos.
- Un cambio remoto se aplica en una transacción y no genera un nuevo evento.
- La credencial del dispositivo vive en almacenamiento seguro, nunca en
  SQLite, logs ni mensajes de error.
- La IP es una caché reemplazable; la identidad estable es la vinculación del
  dispositivo con la PC.

## Organización

```text
features/sync/
  domain/
    entities/       configuración, QR, estado y resultado
    repositories/   contrato público del módulo
  data/
    datasources/    SQLite, HTTP, credenciales seguras y mDNS
    mappers/        registro explícito entidad ↔ tabla
    models/         DTO del contrato HTTP
    repositories/   coordinación push/pull/bootstrap
  presentation/
    bloc/            estado, reintento automático y acciones
    dialogs/         configuración, QR y dirección manual
```

No hay carpetas `services`, `models` o `usecases` vacías. Cada pieza existe
porque representa una frontera concreta y tiene consumidor.

## Esquema v23

- `sync_queue`: outbox con versión base, reintento, resultado y secuencia.
- `sync_configuration`: identidad pública y caché de dirección; no contiene el
  token.
- `sync_state`: cursor de pull, bootstrap y fechas de ejecución.
- `sync_entity_state`: versión remota por entidad.
- `sync_inbox`: idempotencia y auditoría de cambios recibidos.
- `sync_conflicts_local`: conserva ambos lados de un conflicto.
- `sync_file_queue`: base separada para archivos.
- `sync_runtime_context`: evita reencolar mientras se aplica información de la
  PC.

Las tablas locales con ID entero (`empresas`, `marcas`, `categorias`,
`marca_categorias` y `atributos_def`) reciben un `sync_id` UUID estable, sin
cambiar sus claves primarias ni las relaciones existentes.

## Flujo

1. La primera vinculación registra el dispositivo usando el QR, un servidor
   encontrado por mDNS o una dirección manual.
2. El token devuelto se guarda con `flutter_secure_storage`.
3. Una sincronización prepara snapshots de outbox, ejecuta `push`, aplica sus
   resultados y después ejecuta bootstrap/pull.
4. El cursor sólo avanza dentro de la misma transacción que aplica la página.
5. Al recuperar conectividad, el BLoC solicita una sincronización automática.
6. Si la IP cacheada falla, se buscan candidatos `_appcatalogo._tcp` y se
   valida la credencial del dispositivo antes de aceptar la nueva dirección.

## Contrato backend confirmado

La implementación usa el contrato del backend en el commit `c53b8f2`:

- `POST /api/v1/devices/register`
- `GET /api/v1/devices/{deviceId}/status`
- `POST /api/v1/sync/push`
- `GET /api/v1/sync/pull`
- `GET /api/v1/sync/bootstrap`

No se inventó un endpoint `ack`: el cursor local transaccional conserva la
autoridad de reintento. El backend tampoco expone todavía endpoints de subida
de archivos; por eso `sync_file_queue` queda preparada y visible, pero no se
marca un archivo como enviado sin confirmación real del servidor.

## Permisos de plataforma

Android declara Internet, cámara, estado de red y multicast Wi-Fi. iOS declara
cámara, red local y el servicio Bonjour `_appcatalogo._tcp`.

## Verificación mínima

```powershell
flutter test --no-pub test/core/database
flutter test --no-pub test/features/sync
flutter test --no-pub test/architecture/dependency_rules_test.dart
dart analyze
flutter build apk --debug --no-pub
```
