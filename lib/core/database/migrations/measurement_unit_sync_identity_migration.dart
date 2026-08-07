part of '../app_database.dart';

extension _MeasurementUnitSyncIdentityMigration on AppDatabase {
  Future<void> _migrarIdentidadSincronizacionUnidadesV27(
    Database db,
  ) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'unidades_medida'",
    );
    if (tables.isEmpty) return;

    final columns = await db.rawQuery(
      'PRAGMA table_info(unidades_medida)',
    );
    final hasSyncId = columns.any(
      (column) => column['name'] == 'sync_id',
    );
    if (!hasSyncId) {
      await db.execute(
        'ALTER TABLE unidades_medida ADD COLUMN sync_id TEXT',
      );
    }

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'uq_unidades_medida_sync_id '
      'ON unidades_medida(sync_id) '
      'WHERE sync_id IS NOT NULL',
    );
  }
}
