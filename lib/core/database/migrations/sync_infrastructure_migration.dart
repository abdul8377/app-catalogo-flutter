part of '../app_database.dart';

extension _SyncInfrastructureMigration on AppDatabase {
  Future<void> _migrarSincronizacionV23(Database db) async {
    await _crearTablaColaSincronizacion(db);
    await _asegurarColumnasColaSincronizacion(db);
    await _crearTablasInfraestructuraSincronizacion(db);
    await _asegurarIdentidadesSincronizacion(db);
    await _migrarEventosLegacySincronizacion(db);
    await _normalizarEstadosColaSincronizacion(db);
    await _crearTriggersColaSincronizacion(db);
  }

  Future<void> _asegurarColumnasColaSincronizacion(Database db) async {
    await _agregarColumnaSiFalta(
      db,
      'sync_queue',
      'base_version',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _agregarColumnaSiFalta(
      db,
      'sync_queue',
      'payload_version',
      'INTEGER NOT NULL DEFAULT 1',
    );
    await _agregarColumnaSiFalta(db, 'sync_queue', 'next_retry_at', 'TEXT');
    await _agregarColumnaSiFalta(db, 'sync_queue', 'server_version', 'INTEGER');
    await _agregarColumnaSiFalta(
      db,
      'sync_queue',
      'server_sequence',
      'INTEGER',
    );
    await _agregarColumnaSiFalta(db, 'sync_queue', 'last_error_code', 'TEXT');
  }

  Future<void> _asegurarIdentidadesSincronizacion(Database db) async {
    for (final table in const [
      'empresas',
      'marcas',
      'categorias',
      'marca_categorias',
      'atributos_def',
    ]) {
      if (!await _tablaExiste(db, table)) continue;
      await _agregarColumnaSiFalta(db, table, 'sync_id', 'TEXT');
      await db.execute('''
        UPDATE $table
        SET sync_id = ${_uuidSql()}
        WHERE sync_id IS NULL OR TRIM(sync_id) = ''
      ''');
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS uq_${table}_sync_id '
        'ON $table(sync_id)',
      );
    }
  }

  Future<void> _normalizarEstadosColaSincronizacion(Database db) async {
    await db.execute('''
      UPDATE sync_queue
      SET estado = CASE LOWER(estado)
        WHEN 'pendiente' THEN 'pending'
        WHEN 'error' THEN 'retry'
        WHEN 'enviando' THEN 'retry'
        WHEN 'sincronizado' THEN 'synced'
        ELSE LOWER(estado)
      END
    ''');
    await db.execute(
      "UPDATE sync_queue SET accion = UPPER(accion) "
      "WHERE UPPER(accion) IN ('UPSERT', 'DELETE')",
    );
  }

  Future<void> _migrarEventosLegacySincronizacion(Database db) async {
    const simpleEntities = {
      'empresa': ('COMPANY', 'empresas'),
      'marca': ('BRAND', 'marcas'),
      'categoria': ('CATEGORY', 'categorias'),
      'atributo_def': ('LEGACY_ATTRIBUTE_DEFINITION', 'atributos_def'),
    };
    for (final entry in simpleEntities.entries) {
      final table = entry.value.$2;
      if (!await _tablaExiste(db, table)) continue;
      await db.execute('''
        UPDATE sync_queue
        SET entidad = '${entry.value.$1}',
            entidad_id = COALESCE(
              (SELECT sync_id FROM $table WHERE id = CAST(entidad_id AS INTEGER)),
              entidad_id
            )
        WHERE LOWER(entidad) = '${entry.key}'
      ''');
    }
    await db.execute('''
      UPDATE sync_queue
      SET entidad = 'CATEGORY_ATTRIBUTE'
      WHERE LOWER(entidad) = 'categoria_atributo'
    ''');
    await db.execute('''
      UPDATE sync_queue
      SET accion = CASE
        WHEN LOWER(accion) IN ('eliminar', 'borrar', 'delete') THEN 'DELETE'
        ELSE 'UPSERT'
      END
    ''');

    final legacyRelationEvents =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM sync_queue "
            "WHERE LOWER(entidad) = 'marca_categoria'",
          ),
        ) ??
        0;
    await db.delete('sync_queue', where: "LOWER(entidad) = 'marca_categoria'");
    if (legacyRelationEvents > 0 &&
        await _tablaExiste(db, 'marca_categorias')) {
      final now = DateTime.now().toUtc().toIso8601String();
      final relations = await db.query(
        'marca_categorias',
        columns: const ['sync_id'],
      );
      for (final relation in relations) {
        final syncId = relation['sync_id'] as String?;
        if (syncId == null || syncId.isEmpty) continue;
        await db.insert('sync_queue', {
          'id': _legacyEventId(syncId),
          'entidad': 'BRAND_CATEGORY',
          'entidad_id': syncId,
          'accion': 'UPSERT',
          'payload_json': '{}',
          'estado': 'pending',
          'intentos': 0,
          'creado_en': now,
          'actualizado_en': now,
          'base_version': 0,
          'payload_version': 1,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  String _legacyEventId(String syncId) => 'migration-v23-$syncId';

  Future<void> _agregarColumnaSiFalta(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((row) => row['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<bool> _tablaExiste(DatabaseExecutor db, String table) async {
    final rows = await db.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      [table],
    );
    return rows.isNotEmpty;
  }

  String _uuidSql() => '''
    lower(hex(randomblob(4))) || '-' ||
    lower(hex(randomblob(2))) || '-' ||
    '4' || substr(lower(hex(randomblob(2))), 2) || '-' ||
    substr('89ab', abs(random()) % 4 + 1, 1) ||
    substr(lower(hex(randomblob(2))), 2) || '-' ||
    lower(hex(randomblob(6)))
  ''';
}
