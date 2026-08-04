part of '../app_database.dart';

extension _QuoteMigrations on AppDatabase {
  Future<void> _asegurarVersionesCotizaciones(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(cotizaciones)');
    if (info.isEmpty) return;
    final columns = info.map((row) => row['name'] as String).toSet();
    if (!columns.contains('codigo_base')) {
      await db.execute(
        "ALTER TABLE cotizaciones ADD COLUMN codigo_base TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!columns.contains('version')) {
      await db.execute(
        'ALTER TABLE cotizaciones ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (!columns.contains('descuento_global_porcentaje')) {
      await db.execute(
        'ALTER TABLE cotizaciones ADD COLUMN descuento_global_porcentaje REAL NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('descuento_global_monto')) {
      await db.execute(
        'ALTER TABLE cotizaciones ADD COLUMN descuento_global_monto REAL NOT NULL DEFAULT 0',
      );
    }

    final rows = await db.query(
      'cotizaciones',
      orderBy: 'pedido_id ASC, creado_en ASC',
    );
    final bases = <String, String>{};
    final versiones = <String, int>{};
    for (final row in rows) {
      final pedidoId = row['pedido_id'] as String;
      final base = bases.putIfAbsent(
        pedidoId,
        () => (row['codigo_base'] as String? ?? '').trim().isNotEmpty
            ? row['codigo_base'] as String
            : row['codigo'] as String,
      );
      final version = (versiones[pedidoId] ?? 0) + 1;
      versiones[pedidoId] = version;
      final tipo = row['tipo_descuento_global'] as String? ?? 'monto';
      final descuento = (row['descuento_global'] as num? ?? 0).toDouble();
      await db.update(
        'cotizaciones',
        {
          'codigo_base': base,
          'version': version,
          'descuento_global_porcentaje': tipo == 'porcentaje' ? descuento : 0,
          'descuento_global_monto': tipo == 'porcentaje' ? 0 : descuento,
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }
}
