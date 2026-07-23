import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<void> open() async => database;

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'app_catalogo.db');
    return openDatabase(
      path,
      version: 13,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute(
          '''CREATE TABLE empresas(id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL UNIQUE)''',
        );
        await db.execute(
          '''CREATE TABLE marcas(id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL UNIQUE)''',
        );
        await db.execute(
          '''CREATE TABLE categorias(id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL UNIQUE)''',
        );
        await db.execute(
          '''CREATE TABLE subcategorias(id INTEGER PRIMARY KEY AUTOINCREMENT, categoria_id INTEGER NOT NULL, nombre TEXT NOT NULL, FOREIGN KEY(categoria_id) REFERENCES categorias(id))''',
        );
        await db.execute(
          '''CREATE TABLE atributos_def(id INTEGER PRIMARY KEY AUTOINCREMENT, categoria_id INTEGER NOT NULL, nombre TEXT NOT NULL, tipo TEXT NOT NULL, es_variante INTEGER NOT NULL DEFAULT 0, FOREIGN KEY(categoria_id) REFERENCES categorias(id))''',
        );
        await db.execute('''CREATE TABLE productos(
          id TEXT PRIMARY KEY, codigo TEXT NOT NULL UNIQUE, nombre TEXT NOT NULL,
          descripcion TEXT NOT NULL DEFAULT '', empresa TEXT NOT NULL, marca TEXT NOT NULL,
          categoria TEXT NOT NULL, subcategoria TEXT NOT NULL DEFAULT '', tipo_registro TEXT NOT NULL,
          atributos_json TEXT NOT NULL DEFAULT '{}', presentaciones_json TEXT NOT NULL DEFAULT '[]',
          precios_json TEXT NOT NULL DEFAULT '[]', unidad_venta TEXT NOT NULL,
          precio REAL, sin_precio INTEGER NOT NULL, activo INTEGER NOT NULL DEFAULT 1,
          imagen_path TEXT, imagenes_json TEXT NOT NULL DEFAULT '[]',
          creado_en TEXT NOT NULL
        )''');
        await _crearTablasPedidos(db);
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE productos ADD COLUMN imagen_path TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE productos ADD COLUMN imagenes_json TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 4) {
          await _crearTablasPedidos(db);
          await _asegurarHojaInicial(db);
        }
        if (oldVersion < 5) {
          await _asegurarColumnasClientes(db);
        }
        if (oldVersion < 6) {
          await _crearTablasCotizaciones(db);
        }
        if (oldVersion < 7) {
          await _crearTablasPreparacion(db);
        }
        if (oldVersion < 8) {
          await _crearTablaHistorialPedidos(db);
        }
        if (oldVersion < 9) {
          await _asegurarColumnasHojas(db);
          await _crearTablaHistorialHojas(db);
        }
        if (oldVersion < 10) {
          await _asegurarUnidadesBasePedidos(db);
        }
        if (oldVersion < 11) {
          await _asegurarVersionesCotizaciones(db);
        }
        if (oldVersion < 12) {
          await _crearTablasPreparacion(db);
        }
        if (oldVersion < 13) {
          await _asegurarColumnasPedidos(db);
        }
      },
    );
  }

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
      FOREIGN KEY(pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
      FOREIGN KEY(producto_id) REFERENCES productos(id)
    )''');
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

  Future<void> _asegurarColumnasHojas(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(hojas_pedido)');
    final columns = info.map((row) => row['name'] as String).toSet();
    Future<void> addColumn(String name, String definition) async {
      if (!columns.contains(name)) await db.execute(definition);
    }

    await addColumn(
      'vendedor',
      "ALTER TABLE hojas_pedido ADD COLUMN vendedor TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'fecha_cierre',
      'ALTER TABLE hojas_pedido ADD COLUMN fecha_cierre TEXT',
    );
    await addColumn(
      'referencia',
      "ALTER TABLE hojas_pedido ADD COLUMN referencia TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'observacion',
      "ALTER TABLE hojas_pedido ADD COLUMN observacion TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'sincronizado',
      'ALTER TABLE hojas_pedido ADD COLUMN sincronizado INTEGER NOT NULL DEFAULT 0',
    );
    await addColumn(
      'usuario_cierre',
      'ALTER TABLE hojas_pedido ADD COLUMN usuario_cierre TEXT',
    );
    await db.execute('''
      UPDATE hojas_pedido
      SET vendedor = COALESCE(
        NULLIF(vendedor, ''),
        (SELECT p.vendedor FROM pedidos p WHERE p.hoja_id = hojas_pedido.id LIMIT 1),
        'Alfonzo Esteban'
      )
    ''');
  }

  Future<void> _asegurarUnidadesBasePedidos(Database db) async {
    final itemInfo = await db.rawQuery('PRAGMA table_info(pedido_items)');
    final itemColumns = itemInfo.map((row) => row['name'] as String).toSet();
    if (!itemColumns.contains('factor_unidad_base')) {
      await db.execute(
        'ALTER TABLE pedido_items ADD COLUMN factor_unidad_base INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (!itemColumns.contains('unidad_base')) {
      await db.execute(
        "ALTER TABLE pedido_items ADD COLUMN unidad_base TEXT NOT NULL DEFAULT 'UND'",
      );
    }

    final preparacionInfo = await db.rawQuery(
      'PRAGMA table_info(preparacion_productos)',
    );
    final preparacionColumns = preparacionInfo
        .map((row) => row['name'] as String)
        .toSet();
    final columnaBaseNueva = !preparacionColumns.contains('cantidad_base');
    if (columnaBaseNueva) {
      await db.execute(
        'ALTER TABLE preparacion_productos ADD COLUMN cantidad_base INTEGER NOT NULL DEFAULT 0',
      );
    }

    final items = await db.query(
      'pedido_items',
      columns: ['id', 'presentacion', 'equivalencia'],
    );
    for (final item in items) {
      final presentacion = item['presentacion'] as String? ?? '';
      final equivalencia = item['equivalencia'] as String? ?? '';
      await db.update(
        'pedido_items',
        {
          'factor_unidad_base': _factorUnidadBase(presentacion, equivalencia),
          'unidad_base': _unidadBase(presentacion, equivalencia),
        },
        where: 'id = ?',
        whereArgs: [item['id']],
      );
    }
    if (columnaBaseNueva) {
      await db.execute('''
        UPDATE preparacion_productos
        SET cantidad_base = cantidad * COALESCE(
          (SELECT factor_unidad_base
           FROM pedido_items
           WHERE pedido_items.id = preparacion_productos.pedido_item_id),
          1
        )
      ''');
    }
  }

  int _factorUnidadBase(String presentacion, String equivalencia) {
    final texto = '$equivalencia $presentacion'.toLowerCase();
    final coincidencias = RegExp(r'(\d+)').allMatches(equivalencia).toList();
    final numero = coincidencias.isEmpty ? null : coincidencias.last.group(1);
    final parsed = int.tryParse(numero ?? '');
    if (parsed != null && parsed > 0) return parsed;
    if (texto.contains('millar')) return 1000;
    if (texto.contains('ciento')) return 100;
    if (texto.contains('docena')) return 12;
    if (texto.contains('par')) return 2;
    return 1;
  }

  String _unidadBase(String presentacion, String equivalencia) {
    final texto = '$equivalencia $presentacion'.toUpperCase();
    if (texto.contains('KG')) return 'KG';
    if (texto.contains('LT') || texto.contains('LITRO')) return 'LT';
    if (texto.contains('MT') || texto.contains('METRO')) return 'MT';
    return 'UND';
  }

  Future<void> _asegurarColumnasClientes(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(clientes)');
    final columns = info.map((row) => row['name'] as String).toSet();
    Future<void> addColumn(String name, String definition) async {
      if (!columns.contains(name)) await db.execute(definition);
    }

    await addColumn(
      'tipo',
      "ALTER TABLE clientes ADD COLUMN tipo TEXT NOT NULL DEFAULT 'Persona'",
    );
    await addColumn(
      'foto_ubicacion_path',
      'ALTER TABLE clientes ADD COLUMN foto_ubicacion_path TEXT',
    );
    await addColumn(
      'activo',
      'ALTER TABLE clientes ADD COLUMN activo INTEGER NOT NULL DEFAULT 1',
    );
    await addColumn(
      'actualizado_en',
      'ALTER TABLE clientes ADD COLUMN actualizado_en TEXT',
    );
    await db.execute(
      "UPDATE clientes SET tipo = 'Empresa' WHERE ruc != '' AND tipo = 'Persona'",
    );
  }

  Future<void> _asegurarHojaInicial(Database db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM hojas_pedido WHERE activa = 1 AND estado = 'Abierta'",
          ),
        ) ??
        0;
    if (count == 0) {
      final year = DateTime.now().year;
      await db.insert('hojas_pedido', {
        'id': 'hoja-inicial-$year',
        'codigo': 'HP-$year-001',
        'estado': 'Abierta',
        'activa': 1,
        'vendedor': 'Alfonzo Esteban',
        'sincronizado': 0,
        'creado_en': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _seed(Database db) async {
    for (final nombre in [
      'DINA',
      'Garibaldi',
      'Rumi Import',
      'Dubau',
      'Otra',
    ]) {
      await db.insert('empresas', {'nombre': nombre});
    }
    for (final nombre in ['DINA', 'Garibaldi', 'Rumi', 'Dubau', 'Otra']) {
      await db.insert('marcas', {'nombre': nombre});
    }
    const categorias = {
      'Pernería': ['Pernos métricos', 'Pernos pulgada'],
      'Herramientas eléctricas': ['Rotomartillos', 'Amoladoras'],
      'Herramientas manuales': ['Llaves', 'Martillos'],
      'Purificadores': ['Ultrafiltración', 'Ósmosis inversa'],
      'Limpieza': ['Accesorios de limpieza'],
    };
    const atributos = {
      'Pernería': [
        ('Rosca', 'texto', 0),
        ('Clase', 'texto', 0),
        ('Acabado', 'texto', 0),
        ('Norma', 'texto', 0),
        ('Diámetro', 'texto', 1),
        ('Largo', 'texto', 1),
      ],
      'Herramientas eléctricas': [
        ('Voltaje', 'texto', 0),
        ('Potencia', 'texto', 0),
        ('RPM', 'numero', 0),
      ],
      'Herramientas manuales': [
        ('Medida', 'texto', 0),
        ('Material', 'texto', 0),
        ('Peso', 'numero', 0),
        ('Tipo de mango', 'texto', 0),
      ],
      'Purificadores': [
        ('Tecnología', 'texto', 0),
        ('Número de etapas', 'numero', 0),
        ('Alto (cm)', 'numero', 0),
        ('Ancho (cm)', 'numero', 0),
        ('Garantía', 'texto', 0),
        ('Requiere electricidad', 'booleano', 0),
      ],
    };
    for (final entry in categorias.entries) {
      final categoriaId = await db.insert('categorias', {'nombre': entry.key});
      for (final subcategoria in entry.value) {
        await db.insert('subcategorias', {
          'categoria_id': categoriaId,
          'nombre': subcategoria,
        });
      }
      for (final atributo in atributos[entry.key] ?? const []) {
        await db.insert('atributos_def', {
          'categoria_id': categoriaId,
          'nombre': atributo.$1,
          'tipo': atributo.$2,
          'es_variante': atributo.$3,
        });
      }
    }
    final ahora = DateTime.now().toIso8601String();
    const productosDemo = [
      (
        'demo-1',
        'ABZ-001',
        'Abrazadera liviana 1 oreja',
        'DINA',
        'DINA',
        'Pernería',
        'UND',
        1.95,
      ),
      (
        'demo-2',
        'PER-002',
        'Perno hexagonal grado 2 UNC',
        'Rumi Import',
        'Rumi',
        'Pernería',
        'Ciento',
        18.50,
      ),
      (
        'demo-3',
        'TAL-020',
        'Taladro impacto 20V',
        'Garibaldi',
        'Garibaldi',
        'Herramientas eléctricas',
        'UND',
        null,
      ),
      (
        'demo-4',
        'ESC-011',
        'Escobilla lavandera',
        'Dubau',
        'Dubau',
        'Limpieza',
        'Docena',
        12.00,
      ),
    ];
    for (final producto in productosDemo) {
      await db.insert('productos', {
        'id': producto.$1,
        'codigo': producto.$2,
        'nombre': producto.$3,
        'empresa': producto.$4,
        'marca': producto.$5,
        'categoria': producto.$6,
        'tipo_registro': 'unico',
        'unidad_venta': producto.$7,
        'precio': producto.$8,
        'sin_precio': producto.$8 == null ? 1 : 0,
        'activo': 1,
        'creado_en': ahora,
      });
    }
    await _asegurarHojaInicial(db);
  }
}
