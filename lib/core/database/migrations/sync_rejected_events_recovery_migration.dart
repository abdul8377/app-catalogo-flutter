part of '../app_database.dart';

extension _SyncRejectedEventsRecoveryMigration on AppDatabase {
  Future<void> _migrarSincronizacionV25(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'sync_queue'",
    );
    if (tables.isEmpty) return;

    // La primera versión del backend rechazó PRODUCT porque el contrato no
    // aceptaba las proyecciones técnicas enviadas por SQLite. Esos eventos no
    // modificaron MySQL, por lo que es seguro reintentarlos una vez después de
    // actualizar ambos componentes.
    await db.update(
      'sync_queue',
      {
        'estado': 'retry',
        'next_retry_at': null,
        'error': null,
        'last_error_code': null,
        'actualizado_en': DateTime.now().toUtc().toIso8601String(),
      },
      where:
          "estado = 'failed' AND (last_error_code = 'REJECTED' "
          "OR error LIKE '%campos%' OR error LIKE '%PRODUCT%')",
    );
  }
}
