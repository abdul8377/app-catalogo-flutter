part of '../app_database.dart';

extension _OrdersSchema on AppDatabase {
  Future<void> _crearTablasPedidos(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS clientes(
      id TEXT PRIMARY KEY, nombre TEXT NOT NULL, telefono TEXT NOT NULL,
      dni TEXT NOT NULL DEFAULT '', ruc TEXT NOT NULL DEFAULT '',
      tipo TEXT NOT NULL DEFAULT 'Persona',
      tipo_entrega TEXT NOT NULL DEFAULT 'entrega', direccion TEXT NOT NULL DEFAULT '',
      referencia TEXT NOT NULL DEFAULT '', observaciones TEXT NOT NULL DEFAULT '',
      foto_ubicacion_path TEXT,
      activo INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT,
      creado_en TEXT NOT NULL
    )''');
    await _asegurarColumnasClientes(db);
    await db.execute('''CREATE TABLE IF NOT EXISTS hojas_pedido(
      id TEXT PRIMARY KEY, codigo TEXT NOT NULL UNIQUE, estado TEXT NOT NULL,
      activa INTEGER NOT NULL DEFAULT 0,
      vendedor TEXT NOT NULL DEFAULT '',
      fecha_cierre TEXT,
      referencia TEXT NOT NULL DEFAULT '',
      observacion TEXT NOT NULL DEFAULT '',
      sincronizado INTEGER NOT NULL DEFAULT 0,
      usuario_cierre TEXT,
      creado_en TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS pedidos(
      id TEXT PRIMARY KEY, codigo TEXT NOT NULL UNIQUE, hoja_id TEXT NOT NULL,
      cliente_id TEXT NOT NULL, vendedor TEXT NOT NULL, estado TEXT NOT NULL,
      subtotal_conocido REAL NOT NULL DEFAULT 0, total_parcial INTEGER NOT NULL DEFAULT 0,
      sincronizado INTEGER NOT NULL DEFAULT 0,
      sync_error TEXT,
      creado_en TEXT NOT NULL,
      FOREIGN KEY(hoja_id) REFERENCES hojas_pedido(id),
      FOREIGN KEY(cliente_id) REFERENCES clientes(id)
    )''');
    await _asegurarColumnasHojas(db);
    await _asegurarColumnasPedidos(db);
    await db.execute('''CREATE TABLE IF NOT EXISTS pedido_items(
      id TEXT PRIMARY KEY, pedido_id TEXT NOT NULL, producto_id TEXT NOT NULL,
      codigo TEXT NOT NULL, nombre TEXT NOT NULL, presentacion TEXT NOT NULL,
      equivalencia TEXT NOT NULL, cantidad INTEGER NOT NULL,
      factor_unidad_base INTEGER NOT NULL DEFAULT 1,
      unidad_base TEXT NOT NULL DEFAULT 'UND',
      precio_unitario REAL, subtotal REAL,
      activo INTEGER NOT NULL DEFAULT 1,
      variante_id TEXT NOT NULL DEFAULT '',
      variante_sku TEXT NOT NULL DEFAULT '',
      variante_nombre TEXT NOT NULL DEFAULT '',
      atributos_variante_json TEXT NOT NULL DEFAULT '{}',
      presentacion_id TEXT NOT NULL DEFAULT '',
      precio_lista_id TEXT NOT NULL DEFAULT '',
      precio_lista_nombre TEXT NOT NULL DEFAULT '',
      precio_configuracion TEXT NOT NULL DEFAULT 'precio_fijo',
      imagen_path TEXT,
      FOREIGN KEY(pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
      FOREIGN KEY(producto_id) REFERENCES productos(id)
    )''');
    await _asegurarIdentidadPedidoItems(db);
    await _crearTablasCotizaciones(db);
    await _crearTablasPreparacion(db);
    await _asegurarUnidadesBasePedidos(db);
    await _crearTablaHistorialPedidos(db);
    await _crearTablaHistorialHojas(db);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_clientes_busqueda ON clientes(nombre, telefono, dni, ruc)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedidos_hoja ON pedidos(hoja_id, creado_en)',
    );
  }
}
