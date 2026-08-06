part of '../app_database.dart';

extension _PriceListMigration on AppDatabase {
  Future<void> _migrarListasPreciosV26(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS listas_precios(
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL COLLATE NOCASE UNIQUE,
        moneda TEXT NOT NULL DEFAULT 'PEN' CHECK(moneda = 'PEN'),
        incluye_igv INTEGER NOT NULL DEFAULT 1 CHECK(incluye_igv IN (0, 1)),
        igv_porcentaje REAL NOT NULL DEFAULT 18,
        estado INTEGER NOT NULL DEFAULT 1 CHECK(estado IN (0, 1)),
        actualizado_en TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_listas_precios_estado '
      'ON listas_precios(estado, nombre)',
    );
    await db.insert('listas_precios', {
      'id': 'price-list-general',
      'nombre': 'General',
      'moneda': 'PEN',
      'incluye_igv': 1,
      'igv_porcentaje': 18.0,
      'estado': 1,
      'actualizado_en': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await _crearTriggersListasPrecios(db);
  }

  Future<void> _crearTriggersListasPrecios(Database db) async {
    for (final suffix in const ['insert', 'update', 'delete']) {
      await db.execute(
        'DROP TRIGGER IF EXISTS trg_sync_listas_precios_$suffix',
      );
    }
    await db.execute(
      _priceListTriggerSql(
        trigger: 'trg_sync_listas_precios_insert',
        timing: 'AFTER INSERT',
        identity: 'NEW.id',
        operation: 'UPSERT',
      ),
    );
    await db.execute(
      _priceListTriggerSql(
        trigger: 'trg_sync_listas_precios_update',
        timing: 'AFTER UPDATE',
        identity: 'NEW.id',
        operation: 'UPSERT',
      ),
    );
    await db.execute(
      _priceListTriggerSql(
        trigger: 'trg_sync_listas_precios_delete',
        timing: 'BEFORE DELETE',
        identity: 'OLD.id',
        operation: 'DELETE',
      ),
    );
  }

  String _priceListTriggerSql({
    required String trigger,
    required String timing,
    required String identity,
    required String operation,
  }) =>
      '''
    CREATE TRIGGER $trigger
    $timing ON listas_precios
    WHEN (SELECT applying_remote FROM sync_runtime_context WHERE id = 1) = 0
      AND ($identity) IS NOT NULL
      AND TRIM(CAST(($identity) AS TEXT)) <> ''
    BEGIN
      DELETE FROM sync_queue
      WHERE entidad = 'PRICE_LIST'
        AND entidad_id = CAST(($identity) AS TEXT)
        AND estado IN ('pending', 'retry');
      INSERT INTO sync_queue(
        id, entidad, entidad_id, accion, payload_json, estado,
        intentos, error, creado_en, actualizado_en,
        base_version, payload_version, next_retry_at,
        server_version, server_sequence, last_error_code
      ) VALUES (
        ${_priceListUuidSql()}, 'PRICE_LIST', CAST(($identity) AS TEXT),
        '$operation', '{}', 'pending', 0, NULL,
        strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
        strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
        COALESCE((
          SELECT server_version FROM sync_entity_state
          WHERE entity_type = 'PRICE_LIST'
            AND entity_id = CAST(($identity) AS TEXT)
        ), 0),
        1, NULL, NULL, NULL, NULL
      );
    END
  ''';

  String _priceListUuidSql() => '''
    lower(hex(randomblob(4))) || '-' ||
    lower(hex(randomblob(2))) || '-' ||
    '4' || substr(lower(hex(randomblob(2))), 2) || '-' ||
    substr('89ab', abs(random()) % 4 + 1, 1) ||
    substr(lower(hex(randomblob(2))), 2) || '-' ||
    lower(hex(randomblob(6)))
  ''';
}
