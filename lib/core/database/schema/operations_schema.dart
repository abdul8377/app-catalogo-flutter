part of '../app_database.dart';

extension _OperationsSchema on AppDatabase {
  Future<void> _crearTablasPreparacion(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS preparacion_productos(
      id TEXT PRIMARY KEY,
      pedido_item_id TEXT NOT NULL,
      pedido_id TEXT NOT NULL,
      producto_id TEXT NOT NULL,
      cantidad INTEGER NOT NULL,
      cantidad_base INTEGER NOT NULL DEFAULT 0,
      observacion TEXT NOT NULL DEFAULT '',
      creado_en TEXT NOT NULL,
      FOREIGN KEY(pedido_item_id) REFERENCES pedido_items(id) ON DELETE CASCADE,
      FOREIGN KEY(pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
    )''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_preparacion_item ON preparacion_productos(pedido_item_id, creado_en)',
    );
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS preparacion_disponible_movimientos(
      id TEXT PRIMARY KEY,
      producto_key TEXT NOT NULL,
      producto_id TEXT NOT NULL,
      presentacion TEXT NOT NULL,
      equivalencia TEXT NOT NULL DEFAULT '',
      factor_unidad_base INTEGER NOT NULL DEFAULT 1,
      cantidad_delta INTEGER NOT NULL,
      cantidad_base_delta INTEGER NOT NULL,
      observacion TEXT NOT NULL DEFAULT '',
      creado_en TEXT NOT NULL
    )''',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_preparacion_disponible_producto ON preparacion_disponible_movimientos(producto_key, presentacion)',
    );
    await db.execute('''CREATE TABLE IF NOT EXISTS pedido_cargas(
      id TEXT PRIMARY KEY,
      pedido_id TEXT NOT NULL UNIQUE,
      paquetes INTEGER NOT NULL DEFAULT 0,
      observacion TEXT NOT NULL DEFAULT '',
      creado_en TEXT NOT NULL,
      FOREIGN KEY(pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
    )''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedido_cargas_pedido ON pedido_cargas(pedido_id, creado_en)',
    );
  }

  Future<void> _crearTablaHistorialPedidos(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS pedido_historial(
      id TEXT PRIMARY KEY,
      pedido_id TEXT NOT NULL,
      evento TEXT NOT NULL,
      observacion TEXT NOT NULL DEFAULT '',
      responsable TEXT,
      creado_en TEXT NOT NULL,
      FOREIGN KEY(pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
    )''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedido_historial_pedido ON pedido_historial(pedido_id, creado_en)',
    );
  }

  Future<void> _crearTablaHistorialHojas(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS hoja_historial(
      id TEXT PRIMARY KEY,
      hoja_id TEXT NOT NULL,
      evento TEXT NOT NULL,
      observacion TEXT NOT NULL DEFAULT '',
      responsable TEXT,
      creado_en TEXT NOT NULL,
      FOREIGN KEY(hoja_id) REFERENCES hojas_pedido(id) ON DELETE CASCADE
    )''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_hoja_historial_hoja ON hoja_historial(hoja_id, creado_en)',
    );
  }
}
