part of '../app_database.dart';

extension _CatalogAttributesSchema on AppDatabase {
  Future<void> _crearTablasAtributosCategoria(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS unidades_medida(
      id TEXT PRIMARY KEY,
      codigo TEXT NOT NULL COLLATE NOCASE UNIQUE,
      nombre TEXT NOT NULL,
      simbolo TEXT NOT NULL,
      magnitud TEXT NOT NULL,
      factor_a_base REAL NOT NULL CHECK(factor_a_base > 0),
      decimales INTEGER NOT NULL DEFAULT 3 CHECK(decimales BETWEEN 0 AND 6),
      estado INTEGER NOT NULL DEFAULT 1
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS categoria_atributos(
      id TEXT PRIMARY KEY,
      categoria_id INTEGER NOT NULL,
      nombre TEXT NOT NULL COLLATE NOCASE,
      clave TEXT NOT NULL COLLATE NOCASE,
      ayuda TEXT,
      tipo_dato TEXT NOT NULL CHECK(tipo_dato IN (
        'texto_corto', 'numero', 'numero_unidad',
        'lista_unica', 'lista_multiple', 'si_no'
      )),
      nivel_captura TEXT NOT NULL DEFAULT 'familia' CHECK(nivel_captura IN (
        'familia', 'variante', 'decidir'
      )),
      requerido_activar INTEGER NOT NULL DEFAULT 0,
      visible_ficha INTEGER NOT NULL DEFAULT 1,
      filtrable INTEGER NOT NULL DEFAULT 0,
      puede_ser_eje INTEGER NOT NULL DEFAULT 0,
      activo_nuevos INTEGER NOT NULL DEFAULT 1,
      longitud_maxima INTEGER,
      ejemplo TEXT,
      minimo REAL,
      maximo REAL,
      decimales INTEGER NOT NULL DEFAULT 0 CHECK(decimales BETWEEN 0 AND 6),
      magnitud TEXT,
      maximo_selecciones INTEGER,
      etiqueta_verdadero TEXT,
      etiqueta_falso TEXT,
      orden INTEGER NOT NULL DEFAULT 0,
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT,
      FOREIGN KEY(categoria_id) REFERENCES categorias(id),
      UNIQUE(categoria_id, nombre),
      UNIQUE(categoria_id, clave),
      CHECK(minimo IS NULL OR maximo IS NULL OR minimo <= maximo),
      CHECK(tipo_dato = 'lista_multiple' OR maximo_selecciones IS NULL)
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS categoria_atributo_opciones(
      id TEXT PRIMARY KEY,
      categoria_atributo_id TEXT NOT NULL,
      etiqueta TEXT NOT NULL COLLATE NOCASE,
      codigo TEXT NOT NULL COLLATE NOCASE,
      orden INTEGER NOT NULL DEFAULT 0,
      estado INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY(categoria_atributo_id)
        REFERENCES categoria_atributos(id),
      UNIQUE(categoria_atributo_id, etiqueta),
      UNIQUE(categoria_atributo_id, codigo),
      UNIQUE(id, categoria_atributo_id)
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS categoria_atributo_unidades(
      id TEXT PRIMARY KEY,
      categoria_atributo_id TEXT NOT NULL,
      unidad_medida_id TEXT NOT NULL,
      es_predeterminada INTEGER NOT NULL DEFAULT 0,
      orden INTEGER NOT NULL DEFAULT 0,
      estado INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY(categoria_atributo_id)
        REFERENCES categoria_atributos(id),
      FOREIGN KEY(unidad_medida_id) REFERENCES unidades_medida(id),
      UNIQUE(categoria_atributo_id, unidad_medida_id),
      UNIQUE(id, categoria_atributo_id)
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS producto_variantes_catalogo(
      id TEXT PRIMARY KEY,
      producto_id TEXT NOT NULL,
      sku TEXT NOT NULL COLLATE NOCASE UNIQUE,
      codigo_proveedor TEXT NOT NULL DEFAULT '',
      nombre_corto TEXT NOT NULL,
      estado INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY(producto_id) REFERENCES productos(id) ON DELETE CASCADE
    )''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_variantes_codigo_proveedor '
      'ON producto_variantes_catalogo(codigo_proveedor)',
    );
    await db.execute('''CREATE TABLE IF NOT EXISTS producto_familia_ejes(
      producto_id TEXT NOT NULL,
      categoria_atributo_id TEXT NOT NULL,
      orden INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY(producto_id, categoria_atributo_id),
      FOREIGN KEY(producto_id) REFERENCES productos(id) ON DELETE CASCADE,
      FOREIGN KEY(categoria_atributo_id) REFERENCES categoria_atributos(id)
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS producto_atributos(
      id TEXT PRIMARY KEY,
      categoria_atributo_id TEXT NOT NULL,
      producto_id TEXT,
      variante_id TEXT,
      categoria_atributo_unidad_id TEXT,
      tipo_valor TEXT NOT NULL DEFAULT 'texto',
      valor_texto TEXT,
      valor_numero REAL,
      valor_numero_hasta REAL,
      valor_booleano INTEGER,
      valor_normalizado REAL,
      valor_normalizado_hasta REAL,
      actualizado_en TEXT NOT NULL,
      FOREIGN KEY(categoria_atributo_id)
        REFERENCES categoria_atributos(id),
      FOREIGN KEY(producto_id) REFERENCES productos(id) ON DELETE CASCADE,
      FOREIGN KEY(variante_id)
        REFERENCES producto_variantes_catalogo(id) ON DELETE CASCADE,
      FOREIGN KEY(categoria_atributo_unidad_id, categoria_atributo_id)
        REFERENCES categoria_atributo_unidades(id, categoria_atributo_id),
      CHECK(
        (producto_id IS NOT NULL AND variante_id IS NULL) OR
        (producto_id IS NULL AND variante_id IS NOT NULL)
      ),
      UNIQUE(id, categoria_atributo_id)
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS producto_atributo_opciones(
      producto_atributo_id TEXT NOT NULL,
      categoria_atributo_id TEXT NOT NULL,
      opcion_id TEXT NOT NULL,
      PRIMARY KEY(producto_atributo_id, opcion_id),
      FOREIGN KEY(producto_atributo_id, categoria_atributo_id)
        REFERENCES producto_atributos(id, categoria_atributo_id)
        ON DELETE CASCADE,
      FOREIGN KEY(opcion_id, categoria_atributo_id)
        REFERENCES categoria_atributo_opciones(id, categoria_atributo_id)
    )''');
    await db.execute('''CREATE UNIQUE INDEX IF NOT EXISTS
      uq_atributo_unidad_predeterminada
      ON categoria_atributo_unidades(categoria_atributo_id)
      WHERE es_predeterminada = 1 AND estado = 1''');
    await db.execute('''CREATE UNIQUE INDEX IF NOT EXISTS
      uq_producto_atributo_familia
      ON producto_atributos(producto_id, categoria_atributo_id)
      WHERE producto_id IS NOT NULL''');
    await db.execute('''CREATE UNIQUE INDEX IF NOT EXISTS
      uq_producto_atributo_variante
      ON producto_atributos(variante_id, categoria_atributo_id)
      WHERE variante_id IS NOT NULL''');
    await db.execute('''CREATE INDEX IF NOT EXISTS
      idx_categoria_atributos_categoria
      ON categoria_atributos(categoria_id, estado, orden)''');
    await db.execute('''CREATE INDEX IF NOT EXISTS
      idx_producto_atributos_normalizados
      ON producto_atributos(categoria_atributo_id, valor_normalizado)''');

    const units = [
      ('unit-mm', 'mm', 'Milímetro', 'mm', 'Longitud', 1.0, 3),
      ('unit-in', 'in', 'Pulgada', '″', 'Longitud', 25.4, 4),
      ('unit-cm', 'cm', 'Centímetro', 'cm', 'Longitud', 10.0, 3),
      ('unit-g', 'g', 'Gramo', 'g', 'Masa', 1.0, 3),
      ('unit-kg', 'kg', 'Kilogramo', 'kg', 'Masa', 1000.0, 3),
      ('unit-v', 'V', 'Voltio', 'V', 'Voltaje', 1.0, 2),
      ('unit-ah', 'Ah', 'Amperio-hora', 'Ah', 'Capacidad', 1.0, 2),
      ('unit-w', 'W', 'Vatio', 'W', 'Potencia', 1.0, 2),
    ];
    for (final unit in units) {
      await db.insert('unidades_medida', {
        'id': unit.$1,
        'codigo': unit.$2,
        'nombre': unit.$3,
        'simbolo': unit.$4,
        'magnitud': unit.$5,
        'factor_a_base': unit.$6,
        'decimales': unit.$7,
        'estado': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await _asegurarUnidadesTecnicas(db);
  }
}
