part of '../app_database.dart';

extension _SyncV24Migration on AppDatabase {
  Future<void> _migrarSincronizacionV24(Database db) async {
    await _agregarColumnaSiFalta(
      db,
      'sync_queue',
      'schema_version',
      "TEXT NOT NULL DEFAULT '1.0'",
    );
    await _agregarColumnaSiFalta(db, 'sync_queue', 'checksum', 'TEXT');
    await _agregarColumnaSiFalta(
      db,
      'sync_configuration',
      'payload_version',
      'INTEGER NOT NULL DEFAULT 1',
    );
    await _agregarColumnaSiFalta(
      db,
      'sync_configuration',
      'schema_version',
      "TEXT NOT NULL DEFAULT '1.0'",
    );
    await _agregarColumnaSiFalta(
      db,
      'sync_state',
      'pending_ack_cursor',
      'INTEGER',
    );
    await _agregarColumnaSiFalta(
      db,
      'sync_state',
      'bootstrap_snapshot_cursor',
      'INTEGER',
    );
    await _agregarColumnaSiFalta(
      db,
      'sync_state',
      'initialization_status',
      "TEXT NOT NULL DEFAULT 'pending'",
    );
    await _agregarColumnaSiFalta(
      db,
      'sync_state',
      'initial_snapshot_created',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _agregarColumnaSiFalta(
      db,
      'sync_state',
      'api_contract_version',
      "TEXT NOT NULL DEFAULT '1.0'",
    );
    await _agregarColumnaSiFalta(
      db,
      'sync_conflicts_local',
      'backend_conflict_id',
      'TEXT',
    );
    await _agregarColumnaSiFalta(
      db,
      'sync_file_queue',
      'direction',
      "TEXT NOT NULL DEFAULT 'UPLOAD'",
    );
    await _agregarColumnaSiFalta(db, 'sync_file_queue', 'file_name', 'TEXT');
    await _agregarColumnaSiFalta(db, 'sync_file_queue', 'content_type', 'TEXT');
    await _agregarColumnaSiFalta(db, 'sync_file_queue', 'visibility', 'TEXT');
    await _agregarColumnaSiFalta(
      db,
      'sync_file_queue',
      'backend_file_id',
      'TEXT',
    );
    await _agregarColumnaSiFalta(db, 'sync_file_queue', 'download_url', 'TEXT');
    await db.execute("UPDATE sync_configuration SET contract_version = '1.0'");
    await db.execute(
      "UPDATE sync_queue SET schema_version = '1.0' "
      "WHERE schema_version IS NULL OR TRIM(schema_version) = ''",
    );
    await _coalescerEventosProductoV24(db);
    await _crearTriggersProductoAgregadoV24(db);
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'uq_sync_conflicts_backend_id '
      'ON sync_conflicts_local(backend_conflict_id) '
      'WHERE backend_conflict_id IS NOT NULL',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_state_pending_ack '
      'ON sync_state(pending_ack_cursor)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_file_direction_status '
      'ON sync_file_queue(direction, status, next_retry_at, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_file_owner_path '
      'ON sync_file_queue(owner_type, owner_id, local_path)',
    );
  }

  Future<void> _coalescerEventosProductoV24(Database db) async {
    final productIds = <String>{};
    if (await _tablaExiste(db, 'producto_variantes_catalogo')) {
      productIds.addAll(
        (await db.rawQuery('''
        SELECT DISTINCT v.producto_id id
        FROM sync_queue q
        JOIN producto_variantes_catalogo v ON v.id = q.entidad_id
        WHERE q.entidad = 'PRODUCT_VARIANT'
          AND q.estado IN ('pending', 'retry', 'sending')
      ''')).map((row) => row['id']?.toString() ?? ''),
      );
    }
    productIds.addAll(
      (await db.rawQuery('''
        SELECT DISTINCT substr(q.entidad_id, 1, instr(q.entidad_id, '|') - 1) id
        FROM sync_queue q
        WHERE q.entidad = 'PRODUCT_FAMILY_AXIS'
          AND instr(q.entidad_id, '|') > 1
          AND q.estado IN ('pending', 'retry', 'sending')
      ''')).map((row) => row['id']?.toString() ?? ''),
    );
    if (await _tablaExiste(db, 'producto_atributos') &&
        await _tablaExiste(db, 'producto_variantes_catalogo')) {
      productIds.addAll(
        (await db.rawQuery('''
        SELECT DISTINCT COALESCE(a.producto_id, v.producto_id) id
        FROM sync_queue q
        JOIN producto_atributos a ON a.id = q.entidad_id
        LEFT JOIN producto_variantes_catalogo v ON v.id = a.variante_id
        WHERE q.entidad = 'PRODUCT_ATTRIBUTE'
          AND q.estado IN ('pending', 'retry', 'sending')
      ''')).map((row) => row['id']?.toString() ?? ''),
      );
    }
    productIds.removeWhere((id) => id.isEmpty);
    await db.delete(
      'sync_queue',
      where:
          "entidad IN ('PRODUCT_VARIANT', 'PRODUCT_FAMILY_AXIS', "
          "'PRODUCT_ATTRIBUTE', 'PRODUCT_ATTRIBUTE_OPTION') "
          "AND estado IN ('pending', 'retry', 'sending')",
    );
    final now = DateTime.now().toUtc().toIso8601String();
    var sequence = 0;
    for (final productId in productIds) {
      await db.delete(
        'sync_queue',
        where:
            "entidad = 'PRODUCT' AND entidad_id = ? "
            "AND estado IN ('pending', 'retry')",
        whereArgs: [productId],
      );
      await db.insert('sync_queue', {
        'id': 'migration-v24-product-${sequence++}-$productId',
        'entidad': 'PRODUCT',
        'entidad_id': productId,
        'accion': 'UPSERT',
        'payload_json': '{}',
        'estado': 'pending',
        'intentos': 0,
        'creado_en': now,
        'actualizado_en': now,
        'base_version': 0,
        'payload_version': 1,
        'schema_version': '1.0',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _crearTriggersProductoAgregadoV24(Database db) async {
    const tables = [
      'producto_variantes_catalogo',
      'producto_familia_ejes',
      'producto_atributos',
      'producto_atributo_opciones',
    ];
    for (final table in tables) {
      if (!await _tablaExiste(db, table)) continue;
      for (final suffix in const ['insert', 'update', 'delete']) {
        await db.execute('DROP TRIGGER IF EXISTS trg_sync_${table}_$suffix');
      }
    }
    if (await _tablaExiste(db, 'producto_variantes_catalogo')) {
      await _crearTriggersHijoProducto(
        db,
        table: 'producto_variantes_catalogo',
        newProductId: 'NEW.producto_id',
        oldProductId: 'OLD.producto_id',
      );
    }
    if (await _tablaExiste(db, 'producto_familia_ejes')) {
      await _crearTriggersHijoProducto(
        db,
        table: 'producto_familia_ejes',
        newProductId: 'NEW.producto_id',
        oldProductId: 'OLD.producto_id',
      );
    }
    if (await _tablaExiste(db, 'producto_atributos') &&
        await _tablaExiste(db, 'producto_variantes_catalogo')) {
      await _crearTriggersHijoProducto(
        db,
        table: 'producto_atributos',
        newProductId:
            'COALESCE(NEW.producto_id, (SELECT producto_id FROM '
            'producto_variantes_catalogo WHERE id = NEW.variante_id))',
        oldProductId:
            'COALESCE(OLD.producto_id, (SELECT producto_id FROM '
            'producto_variantes_catalogo WHERE id = OLD.variante_id))',
      );
    }
    if (await _tablaExiste(db, 'producto_atributo_opciones') &&
        await _tablaExiste(db, 'producto_atributos') &&
        await _tablaExiste(db, 'producto_variantes_catalogo')) {
      await _crearTriggersHijoProducto(
        db,
        table: 'producto_atributo_opciones',
        newProductId:
            '(SELECT COALESCE(a.producto_id, v.producto_id) '
            'FROM producto_atributos a LEFT JOIN producto_variantes_catalogo v '
            'ON v.id = a.variante_id WHERE a.id = NEW.producto_atributo_id)',
        oldProductId:
            '(SELECT COALESCE(a.producto_id, v.producto_id) '
            'FROM producto_atributos a LEFT JOIN producto_variantes_catalogo v '
            'ON v.id = a.variante_id WHERE a.id = OLD.producto_atributo_id)',
      );
    }
  }

  Future<void> _crearTriggersHijoProducto(
    Database db, {
    required String table,
    required String newProductId,
    required String oldProductId,
  }) async {
    await db.execute(
      _syncTriggerSql(
        trigger: 'trg_sync_${table}_insert',
        timing: 'AFTER INSERT',
        table: table,
        entityType: 'PRODUCT',
        identity: newProductId,
        operation: 'UPSERT',
      ),
    );
    await db.execute(
      _syncTriggerSql(
        trigger: 'trg_sync_${table}_update',
        timing: 'AFTER UPDATE',
        table: table,
        entityType: 'PRODUCT',
        identity: newProductId,
        operation: 'UPSERT',
      ),
    );
    await db.execute(
      _syncTriggerSql(
        trigger: 'trg_sync_${table}_delete',
        timing: 'BEFORE DELETE',
        table: table,
        entityType: 'PRODUCT',
        identity: oldProductId,
        operation: 'UPSERT',
      ),
    );
  }
}
