part of '../app_database.dart';

extension _SyncInfrastructureSchema on AppDatabase {
  Future<void> _crearTablasInfraestructuraSincronizacion(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS sync_configuration(
      id INTEGER PRIMARY KEY CHECK(id = 1),
      server_id TEXT NOT NULL,
      server_name TEXT NOT NULL DEFAULT '',
      service_type TEXT NOT NULL DEFAULT '_appcatalogo._tcp',
      server_url_cache TEXT,
      device_id TEXT NOT NULL,
      device_name TEXT NOT NULL,
      contract_version INTEGER NOT NULL DEFAULT 1,
      linked_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS sync_state(
      id INTEGER PRIMARY KEY CHECK(id = 1),
      last_pull_cursor INTEGER NOT NULL DEFAULT 0,
      last_ack_cursor INTEGER NOT NULL DEFAULT 0,
      last_success_at TEXT,
      last_attempt_at TEXT,
      bootstrap_completed INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS sync_entity_state(
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      server_version INTEGER NOT NULL DEFAULT 0,
      sync_status TEXT NOT NULL DEFAULT 'pending',
      last_error TEXT,
      last_synced_at TEXT,
      PRIMARY KEY(entity_type, entity_id)
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS sync_inbox(
      server_sequence INTEGER PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      server_version INTEGER NOT NULL,
      origin_device_id TEXT,
      payload_json TEXT NOT NULL,
      changed_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      last_error TEXT,
      applied_at TEXT
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS sync_conflicts_local(
      id TEXT PRIMARY KEY,
      event_id TEXT,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      local_base_version INTEGER NOT NULL,
      server_version INTEGER NOT NULL,
      local_payload_json TEXT NOT NULL,
      server_payload_json TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      message TEXT,
      created_at TEXT NOT NULL,
      resolved_at TEXT
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS sync_file_queue(
      id TEXT PRIMARY KEY,
      owner_type TEXT NOT NULL,
      owner_id TEXT NOT NULL,
      local_path TEXT NOT NULL,
      checksum TEXT,
      size_bytes INTEGER,
      object_key TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      attempts INTEGER NOT NULL DEFAULT 0,
      next_retry_at TEXT,
      last_error TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS sync_runtime_context(
      id INTEGER PRIMARY KEY CHECK(id = 1),
      applying_remote INTEGER NOT NULL DEFAULT 0
    )''');
    await db.insert('sync_runtime_context', const {
      'id': 1,
      'applying_remote': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('sync_state', {
      'id': 1,
      'last_pull_cursor': 0,
      'last_ack_cursor': 0,
      'bootstrap_completed': 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_retry '
      'ON sync_queue(estado, next_retry_at, creado_en)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_entity '
      'ON sync_queue(entidad, entidad_id, estado)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_inbox_status '
      'ON sync_inbox(status, server_sequence)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_conflicts_status '
      'ON sync_conflicts_local(status, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_file_queue_status '
      'ON sync_file_queue(status, next_retry_at, created_at)',
    );
  }

  Future<void> _crearTriggersColaSincronizacion(Database db) async {
    await _crearTriggerIdentidad(
      db,
      table: 'empresas',
      rowWhere: 'id = NEW.id',
    );
    await _crearTriggerIdentidad(db, table: 'marcas', rowWhere: 'id = NEW.id');
    await _crearTriggerIdentidad(
      db,
      table: 'categorias',
      rowWhere: 'id = NEW.id',
    );
    await _crearTriggerIdentidad(
      db,
      table: 'marca_categorias',
      rowWhere: 'marca_id = NEW.marca_id AND categoria_id = NEW.categoria_id',
    );
    await _crearTriggerIdentidad(
      db,
      table: 'atributos_def',
      rowWhere: 'id = NEW.id',
    );

    for (final spec in _syncTriggerSpecs) {
      if (!await _syncTableExists(db, spec.table)) continue;
      await _crearTriggersEntidad(db, spec);
    }
    await _crearTriggersArchivosSincronizacion(db);
  }

  Future<void> _crearTriggersArchivosSincronizacion(Database db) async {
    for (final spec in const [
      ('productos', 'PRODUCT', 'imagen_path'),
      ('clientes', 'CLIENT', 'foto_ubicacion_path'),
      ('cotizaciones', 'QUOTE', 'pdf_path'),
    ]) {
      if (!await _syncTableExists(db, spec.$1)) continue;
      final base = 'trg_sync_file_${spec.$1}_${spec.$3}';
      await db.execute('DROP TRIGGER IF EXISTS ${base}_insert');
      await db.execute('DROP TRIGGER IF EXISTS ${base}_update');
      await db.execute('DROP TRIGGER IF EXISTS ${base}_delete');
      final eventId = "'${spec.$2}:' || NEW.id || ':${spec.$3}'";
      final values =
          '''
        $eventId, '${spec.$2}', CAST(NEW.id AS TEXT), NEW.${spec.$3},
        'pending', 0,
        strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
        strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
      ''';
      final upsert = '''
        ON CONFLICT(id) DO UPDATE SET
          local_path = excluded.local_path,
          status = 'pending',
          attempts = 0,
          next_retry_at = NULL,
          last_error = NULL,
          updated_at = excluded.updated_at
      ''';
      await db.execute('''
        CREATE TRIGGER ${base}_insert
        AFTER INSERT ON ${spec.$1}
        WHEN (SELECT applying_remote FROM sync_runtime_context WHERE id = 1) = 0
          AND NEW.${spec.$3} IS NOT NULL
          AND TRIM(NEW.${spec.$3}) <> ''
        BEGIN
          INSERT INTO sync_file_queue(
            id, owner_type, owner_id, local_path, status, attempts,
            created_at, updated_at
          ) VALUES ($values) $upsert;
        END
      ''');
      await db.execute('''
        CREATE TRIGGER ${base}_update
        AFTER UPDATE OF ${spec.$3} ON ${spec.$1}
        WHEN (SELECT applying_remote FROM sync_runtime_context WHERE id = 1) = 0
          AND NEW.${spec.$3} IS NOT NULL
          AND TRIM(NEW.${spec.$3}) <> ''
          AND COALESCE(OLD.${spec.$3}, '') <> NEW.${spec.$3}
        BEGIN
          INSERT INTO sync_file_queue(
            id, owner_type, owner_id, local_path, status, attempts,
            created_at, updated_at
          ) VALUES ($values) $upsert;
        END
      ''');
      await db.execute('''
        CREATE TRIGGER ${base}_delete
        AFTER DELETE ON ${spec.$1}
        BEGIN
          DELETE FROM sync_file_queue
          WHERE owner_type = '${spec.$2}' AND owner_id = CAST(OLD.id AS TEXT);
        END
      ''');
    }
  }

  Future<void> _crearTriggerIdentidad(
    Database db, {
    required String table,
    required String rowWhere,
  }) async {
    if (!await _syncTableExists(db, table)) return;
    await db.execute('DROP TRIGGER IF EXISTS trg_${table}_assign_sync_id');
    await db.execute('''
      CREATE TRIGGER trg_${table}_assign_sync_id
      AFTER INSERT ON $table
      WHEN NEW.sync_id IS NULL OR TRIM(NEW.sync_id) = ''
      BEGIN
        UPDATE $table SET sync_id = ${_syncUuidSql()} WHERE $rowWhere;
      END
    ''');
  }

  Future<void> _crearTriggersEntidad(Database db, _SyncTriggerSpec spec) async {
    final safe = spec.table.replaceAll(RegExp('[^a-zA-Z0-9_]'), '_');
    for (final suffix in const ['insert', 'update', 'delete']) {
      await db.execute('DROP TRIGGER IF EXISTS trg_sync_${safe}_$suffix');
    }
    await db.execute(
      _syncTriggerSql(
        trigger: 'trg_sync_${safe}_insert',
        timing: 'AFTER INSERT',
        table: spec.table,
        entityType: spec.entityType,
        identity: spec.newIdentity,
        operation: 'UPSERT',
      ),
    );
    await db.execute(
      _syncTriggerSql(
        trigger: 'trg_sync_${safe}_update',
        timing: 'AFTER UPDATE',
        table: spec.table,
        entityType: spec.entityType,
        identity: spec.newIdentity,
        operation: 'UPSERT',
      ),
    );
    await db.execute(
      _syncTriggerSql(
        trigger: 'trg_sync_${safe}_delete',
        timing: 'BEFORE DELETE',
        table: spec.table,
        entityType: spec.entityType,
        identity: spec.oldIdentity,
        operation: 'DELETE',
      ),
    );
  }

  String _syncTriggerSql({
    required String trigger,
    required String timing,
    required String table,
    required String entityType,
    required String identity,
    required String operation,
  }) =>
      '''
    CREATE TRIGGER $trigger
    $timing ON $table
    WHEN (SELECT applying_remote FROM sync_runtime_context WHERE id = 1) = 0
      AND ($identity) IS NOT NULL
      AND TRIM(CAST(($identity) AS TEXT)) <> ''
    BEGIN
      DELETE FROM sync_queue
      WHERE entidad = '$entityType'
        AND entidad_id = CAST(($identity) AS TEXT)
        AND estado IN ('pending', 'retry');
      INSERT INTO sync_queue(
        id, entidad, entidad_id, accion, payload_json, estado,
        intentos, error, creado_en, actualizado_en,
        base_version, payload_version, next_retry_at,
        server_version, server_sequence, last_error_code
      ) VALUES (
        ${_syncUuidSql()}, '$entityType', CAST(($identity) AS TEXT),
        '$operation', '{}', 'pending', 0, NULL,
        strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
        strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
        COALESCE((
          SELECT server_version FROM sync_entity_state
          WHERE entity_type = '$entityType'
            AND entity_id = CAST(($identity) AS TEXT)
        ), 0),
        1, NULL, NULL, NULL, NULL
      );
    END
  ''';

  Future<bool> _syncTableExists(Database db, String table) async =>
      (await db.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
        [table],
      )).isNotEmpty;

  String _syncUuidSql() => '''
    lower(hex(randomblob(4))) || '-' ||
    lower(hex(randomblob(2))) || '-' ||
    '4' || substr(lower(hex(randomblob(2))), 2) || '-' ||
    substr('89ab', abs(random()) % 4 + 1, 1) ||
    substr(lower(hex(randomblob(2))), 2) || '-' ||
    lower(hex(randomblob(6)))
  ''';
}

class _SyncTriggerSpec {
  const _SyncTriggerSpec(
    this.table,
    this.entityType,
    this.newIdentity,
    this.oldIdentity,
  );

  final String table;
  final String entityType;
  final String newIdentity;
  final String oldIdentity;
}

const _syncTriggerSpecs = <_SyncTriggerSpec>[
  _SyncTriggerSpec('empresas', 'COMPANY', 'NEW.sync_id', 'OLD.sync_id'),
  _SyncTriggerSpec('marcas', 'BRAND', 'NEW.sync_id', 'OLD.sync_id'),
  _SyncTriggerSpec('categorias', 'CATEGORY', 'NEW.sync_id', 'OLD.sync_id'),
  _SyncTriggerSpec(
    'marca_categorias',
    'BRAND_CATEGORY',
    'NEW.sync_id',
    'OLD.sync_id',
  ),
  _SyncTriggerSpec('unidades_medida', 'MEASUREMENT_UNIT', 'NEW.id', 'OLD.id'),
  _SyncTriggerSpec(
    'categoria_atributos',
    'CATEGORY_ATTRIBUTE',
    'NEW.id',
    'OLD.id',
  ),
  _SyncTriggerSpec(
    'categoria_atributo_opciones',
    'CATEGORY_ATTRIBUTE_OPTION',
    'NEW.id',
    'OLD.id',
  ),
  _SyncTriggerSpec(
    'categoria_atributo_unidades',
    'CATEGORY_ATTRIBUTE_UNIT',
    'NEW.id',
    'OLD.id',
  ),
  _SyncTriggerSpec(
    'atributos_def',
    'LEGACY_ATTRIBUTE_DEFINITION',
    'NEW.sync_id',
    'OLD.sync_id',
  ),
  _SyncTriggerSpec('productos', 'PRODUCT', 'NEW.id', 'OLD.id'),
  _SyncTriggerSpec(
    'producto_variantes_catalogo',
    'PRODUCT_VARIANT',
    'NEW.id',
    'OLD.id',
  ),
  _SyncTriggerSpec(
    'producto_familia_ejes',
    'PRODUCT_FAMILY_AXIS',
    "NEW.producto_id || '|' || NEW.categoria_atributo_id",
    "OLD.producto_id || '|' || OLD.categoria_atributo_id",
  ),
  _SyncTriggerSpec(
    'producto_atributos',
    'PRODUCT_ATTRIBUTE',
    'NEW.id',
    'OLD.id',
  ),
  _SyncTriggerSpec(
    'producto_atributo_opciones',
    'PRODUCT_ATTRIBUTE_OPTION',
    "NEW.producto_atributo_id || '|' || NEW.opcion_id",
    "OLD.producto_atributo_id || '|' || OLD.opcion_id",
  ),
  _SyncTriggerSpec('clientes', 'CLIENT', 'NEW.id', 'OLD.id'),
  _SyncTriggerSpec('hojas_pedido', 'ORDER_SHEET', 'NEW.id', 'OLD.id'),
  _SyncTriggerSpec('pedidos', 'ORDER', 'NEW.id', 'OLD.id'),
  _SyncTriggerSpec('pedido_items', 'ORDER_ITEM', 'NEW.id', 'OLD.id'),
  _SyncTriggerSpec('cotizaciones', 'QUOTE', 'NEW.id', 'OLD.id'),
  _SyncTriggerSpec('cotizacion_items', 'QUOTE_ITEM', 'NEW.id', 'OLD.id'),
  _SyncTriggerSpec('preparacion_productos', 'PREPARATION', 'NEW.id', 'OLD.id'),
  _SyncTriggerSpec(
    'preparacion_disponible_movimientos',
    'PREPARATION_STOCK_MOVEMENT',
    'NEW.id',
    'OLD.id',
  ),
  _SyncTriggerSpec('pedido_cargas', 'ORDER_LOAD', 'NEW.id', 'OLD.id'),
  _SyncTriggerSpec('pedido_historial', 'ORDER_HISTORY', 'NEW.id', 'OLD.id'),
  _SyncTriggerSpec('hoja_historial', 'ORDER_SHEET_HISTORY', 'NEW.id', 'OLD.id'),
];
