part of '../app_database.dart';

extension _OrderColumnsMigrations on AppDatabase {
  Future<void> _asegurarColumnasPedidos(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(pedidos)');
    if (info.isEmpty) return;
    final columns = info.map((row) => row['name'] as String).toSet();
    if (!columns.contains('sincronizado')) {
      await db.execute(
        'ALTER TABLE pedidos ADD COLUMN sincronizado INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('sync_error')) {
      await db.execute('ALTER TABLE pedidos ADD COLUMN sync_error TEXT');
    }
  }

  Future<void> _asegurarIdentidadPedidoItems(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(pedido_items)');
    if (info.isEmpty) return;
    final columns = info.map((row) => row['name'] as String).toSet();

    Future<void> addColumn(String name, String sql) async {
      if (!columns.contains(name)) await db.execute(sql);
    }

    await addColumn(
      'activo',
      'ALTER TABLE pedido_items ADD COLUMN activo INTEGER NOT NULL DEFAULT 1',
    );
    await addColumn(
      'variante_id',
      "ALTER TABLE pedido_items ADD COLUMN variante_id TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'variante_sku',
      "ALTER TABLE pedido_items ADD COLUMN variante_sku TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'variante_nombre',
      "ALTER TABLE pedido_items ADD COLUMN variante_nombre TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'atributos_variante_json',
      "ALTER TABLE pedido_items ADD COLUMN atributos_variante_json TEXT NOT NULL DEFAULT '{}'",
    );
    await addColumn(
      'presentacion_id',
      "ALTER TABLE pedido_items ADD COLUMN presentacion_id TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'precio_lista_id',
      "ALTER TABLE pedido_items ADD COLUMN precio_lista_id TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'precio_lista_nombre',
      "ALTER TABLE pedido_items ADD COLUMN precio_lista_nombre TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'precio_configuracion',
      "ALTER TABLE pedido_items ADD COLUMN precio_configuracion TEXT NOT NULL DEFAULT 'precio_fijo'",
    );
    await addColumn(
      'imagen_path',
      'ALTER TABLE pedido_items ADD COLUMN imagen_path TEXT',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedido_items_activos '
      'ON pedido_items(pedido_id, activo)',
    );
  }
}
