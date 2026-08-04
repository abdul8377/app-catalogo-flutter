part of '../app_database.dart';

extension _QuotesSchema on AppDatabase {
  Future<void> _crearTablasCotizaciones(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS cotizaciones(
      id TEXT PRIMARY KEY,
      pedido_id TEXT NOT NULL,
      codigo TEXT NOT NULL UNIQUE,
      codigo_base TEXT NOT NULL DEFAULT '',
      version INTEGER NOT NULL DEFAULT 1,
      subtotal REAL NOT NULL,
      descuento_global REAL NOT NULL DEFAULT 0,
      tipo_descuento_global TEXT NOT NULL DEFAULT 'monto',
      descuento_global_porcentaje REAL NOT NULL DEFAULT 0,
      descuento_global_monto REAL NOT NULL DEFAULT 0,
      total REAL NOT NULL,
      vigencia_dias INTEGER NOT NULL DEFAULT 7,
      condiciones TEXT NOT NULL DEFAULT '',
      observaciones TEXT NOT NULL DEFAULT '',
      estado TEXT NOT NULL DEFAULT 'Generada',
      pdf_path TEXT,
      creado_en TEXT NOT NULL,
      actualizado_en TEXT NOT NULL,
      FOREIGN KEY(pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS cotizacion_items(
      id TEXT PRIMARY KEY,
      cotizacion_id TEXT NOT NULL,
      pedido_item_id TEXT NOT NULL,
      producto_id TEXT NOT NULL,
      codigo TEXT NOT NULL,
      nombre TEXT NOT NULL,
      presentacion TEXT NOT NULL,
      cantidad INTEGER NOT NULL,
      precio_cotizacion REAL NOT NULL,
      descuento REAL NOT NULL DEFAULT 0,
      tipo_descuento TEXT NOT NULL DEFAULT 'monto',
      precio_final REAL NOT NULL,
      subtotal REAL NOT NULL,
      FOREIGN KEY(cotizacion_id) REFERENCES cotizaciones(id) ON DELETE CASCADE,
      FOREIGN KEY(pedido_item_id) REFERENCES pedido_items(id) ON DELETE CASCADE
    )''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cotizaciones_pedido ON cotizaciones(pedido_id, creado_en)',
    );
    await _asegurarVersionesCotizaciones(db);
  }
}
