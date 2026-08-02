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
      version: 22,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _crearTablasEstructuraCatalogo(db);
        await db.execute(
          '''CREATE TABLE atributos_def(id INTEGER PRIMARY KEY AUTOINCREMENT, categoria_id INTEGER NOT NULL, nombre TEXT NOT NULL, tipo TEXT NOT NULL, es_variante INTEGER NOT NULL DEFAULT 0, FOREIGN KEY(categoria_id) REFERENCES categorias(id))''',
        );
        await db.execute('''CREATE TABLE productos(
          id TEXT PRIMARY KEY, codigo TEXT NOT NULL UNIQUE, nombre TEXT NOT NULL,
          descripcion TEXT NOT NULL DEFAULT '', empresa TEXT NOT NULL, marca TEXT NOT NULL,
          categoria TEXT NOT NULL, subcategoria TEXT NOT NULL DEFAULT '', tipo_registro TEXT NOT NULL,
          atributos_json TEXT NOT NULL DEFAULT '{}', variantes_json TEXT NOT NULL DEFAULT '[]',
          presentaciones_json TEXT NOT NULL DEFAULT '[]',
          venta_logistica_json TEXT NOT NULL DEFAULT '{}',
          precios_configurados_json TEXT NOT NULL DEFAULT '{}',
          imagenes_configuradas_json TEXT NOT NULL DEFAULT '{}',
          precios_json TEXT NOT NULL DEFAULT '[]', unidad_venta TEXT NOT NULL,
          precio REAL, sin_precio INTEGER NOT NULL, activo INTEGER NOT NULL DEFAULT 1,
          imagen_path TEXT, imagenes_json TEXT NOT NULL DEFAULT '[]',
          creado_en TEXT NOT NULL
        )''');
        await _crearTablasAtributosCategoria(db);
        await _crearTablasPedidos(db);
        await _crearTablaColaSincronizacion(db);
        await _seed(db);
        await _migrarAtributosDef(db);
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
        if (oldVersion < 14) {
          await _migrarEstructuraCatalogo(db);
          await _crearTablaColaSincronizacion(db);
        }
        if (oldVersion < 15) {
          await db.execute(
            "ALTER TABLE productos ADD COLUMN variantes_json TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 16) {
          await db.execute(
            "ALTER TABLE productos ADD COLUMN venta_logistica_json TEXT NOT NULL DEFAULT '{}'",
          );
        }
        if (oldVersion < 17) {
          await db.execute(
            "ALTER TABLE productos ADD COLUMN precios_configurados_json TEXT NOT NULL DEFAULT '{}'",
          );
        }
        if (oldVersion < 18) {
          await db.execute(
            "ALTER TABLE productos ADD COLUMN imagenes_configuradas_json TEXT NOT NULL DEFAULT '{}'",
          );
        }
        if (oldVersion < 19) {
          await _crearTablasAtributosCategoria(db);
          await _migrarAtributosDef(db);
        }
        if (oldVersion < 20) {
          await _migrarCodigoProveedorVariantes(db);
        }
        if (oldVersion < 21) {
          await _migrarValoresTecnicos(db);
        }
        if (oldVersion < 22) {
          await _asegurarIdentidadPedidoItems(db);
        }
      },
    );
  }

  Future<void> _migrarValoresTecnicos(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(producto_atributos)');
    final names = columns.map((column) => column['name'] as String).toSet();

    Future<void> addColumn(String name, String sql) async {
      if (!names.contains(name)) await db.execute(sql);
    }

    await addColumn(
      'tipo_valor',
      "ALTER TABLE producto_atributos "
          "ADD COLUMN tipo_valor TEXT NOT NULL DEFAULT 'texto'",
    );
    await addColumn(
      'valor_numero_hasta',
      'ALTER TABLE producto_atributos '
          'ADD COLUMN valor_numero_hasta REAL',
    );
    await addColumn(
      'valor_normalizado_hasta',
      'ALTER TABLE producto_atributos '
          'ADD COLUMN valor_normalizado_hasta REAL',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_producto_atributos_rangos '
      'ON producto_atributos('
      'categoria_atributo_id, '
      'valor_normalizado, '
      'valor_normalizado_hasta'
      ')',
    );

    await _asegurarUnidadesTecnicas(db);
  }

  Future<void> _asegurarUnidadesTecnicas(Database db) async {
    const units = [
      ('unit-hz', 'Hz', 'Hercio', 'Hz', 'Frecuencia', 1.0, 2),
      ('unit-rpm', 'rpm', 'Revolución por minuto', 'rpm', 'Rotación', 1.0, 0),
      ('unit-bpm', 'bpm', 'Golpe por minuto', 'bpm', 'Impactos', 1.0, 0),
      ('unit-nm', 'Nm', 'Newton metro', 'Nm', 'Torque', 1.0, 2),
      ('unit-j', 'J', 'Julio', 'J', 'Energía', 1.0, 2),
      ('unit-bar', 'bar', 'Bar', 'bar', 'Presión', 100000.0, 4),
      (
        'unit-psi',
        'psi',
        'Libra por pulgada cuadrada',
        'psi',
        'Presión',
        6894.757293,
        4,
      ),
      ('unit-mpa', 'MPa', 'Megapascal', 'MPa', 'Presión', 1000000.0, 4),
      (
        'unit-ml-min',
        'ml/min',
        'Mililitro por minuto',
        'ml/min',
        'Caudal',
        1.0,
        3,
      ),
      ('unit-din-s', 'DIN-s', 'Segundo DIN', 'DIN-s', 'Viscosidad', 1.0, 2),
      ('unit-celsius', 'C', 'Grado Celsius', '°C', 'Temperatura', 1.0, 2),
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
  }

  Future<void> _migrarCodigoProveedorVariantes(Database db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(producto_variantes_catalogo)',
    );
    final hasColumn = columns.any(
      (column) => column['name'] == 'codigo_proveedor',
    );
    if (!hasColumn) {
      await db.execute(
        "ALTER TABLE producto_variantes_catalogo "
        "ADD COLUMN codigo_proveedor TEXT NOT NULL DEFAULT ''",
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_variantes_codigo_proveedor '
      'ON producto_variantes_catalogo(codigo_proveedor)',
    );
  }

  Future<void> _crearTablasEstructuraCatalogo(Database db) async {
    await db.execute('''CREATE TABLE empresas(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL COLLATE NOCASE UNIQUE,
      ruc TEXT NOT NULL DEFAULT '',
      telefono TEXT NOT NULL DEFAULT '',
      direccion TEXT NOT NULL DEFAULT '',
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT
    )''');
    await db.execute('''CREATE TABLE marcas(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      empresa_id INTEGER NOT NULL,
      nombre TEXT NOT NULL COLLATE NOCASE,
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT,
      FOREIGN KEY(empresa_id) REFERENCES empresas(id),
      UNIQUE(empresa_id, nombre)
    )''');
    await db.execute('''CREATE TABLE categorias(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      categoria_padre_id INTEGER,
      nombre TEXT NOT NULL COLLATE NOCASE,
      descripcion TEXT NOT NULL DEFAULT '',
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT,
      FOREIGN KEY(categoria_padre_id) REFERENCES categorias(id),
      UNIQUE(categoria_padre_id, nombre)
    )''');
    await db.execute('''CREATE UNIQUE INDEX idx_categoria_raiz_nombre
      ON categorias(nombre) WHERE categoria_padre_id IS NULL''');
    await db.execute('''CREATE TABLE marca_categorias(
      marca_id INTEGER NOT NULL,
      categoria_id INTEGER NOT NULL,
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT,
      PRIMARY KEY(marca_id, categoria_id),
      FOREIGN KEY(marca_id) REFERENCES marcas(id),
      FOREIGN KEY(categoria_id) REFERENCES categorias(id)
    )''');
    await db.execute(
      'CREATE INDEX idx_marcas_empresa ON marcas(empresa_id, estado)',
    );
    await db.execute(
      'CREATE INDEX idx_categorias_padre ON categorias(categoria_padre_id, estado)',
    );
  }

  Future<void> _crearTablaColaSincronizacion(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS sync_queue(
      id TEXT PRIMARY KEY,
      entidad TEXT NOT NULL,
      entidad_id TEXT NOT NULL,
      accion TEXT NOT NULL,
      payload_json TEXT NOT NULL,
      estado TEXT NOT NULL DEFAULT 'pendiente',
      intentos INTEGER NOT NULL DEFAULT 0,
      error TEXT,
      creado_en TEXT NOT NULL,
      actualizado_en TEXT NOT NULL
    )''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_estado ON sync_queue(estado, creado_en)',
    );
  }

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

  Future<void> _migrarAtributosDef(Database db) async {
    final legacyTable = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'atributos_def'",
    );
    if (legacyTable.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final rows = await db.rawQuery('''
      SELECT a.*, c.nombre AS categoria_nombre
      FROM atributos_def a
      INNER JOIN categorias c ON c.id = a.categoria_id
      ORDER BY a.id
    ''');
    for (final row in rows) {
      final id = 'legacy-atributo-${row['id']}';
      final exists = await db.query(
        'categoria_atributos',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (exists.isNotEmpty) continue;
      final name = row['nombre'] as String;
      final legacyType = (row['tipo'] as String).toLowerCase();
      final type = switch (legacyType) {
        'numero' => 'numero',
        'booleano' => 'si_no',
        _ => 'texto_corto',
      };
      await db.insert('categoria_atributos', {
        'id': id,
        'categoria_id': row['categoria_id'],
        'nombre': name,
        'clave': _claveAtributo(name),
        'tipo_dato': type,
        'nivel_captura': (row['es_variante'] as int? ?? 0) == 1
            ? 'variante'
            : 'familia',
        'requerido_activar': 0,
        'visible_ficha': 1,
        'filtrable': 1,
        'puede_ser_eje': (row['es_variante'] as int? ?? 0) == 1 ? 1 : 0,
        'activo_nuevos': 1,
        'orden': row['id'],
        'estado': 1,
        'actualizado_en': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  String _claveAtributo(String value) {
    var normalized = value.trim().toLowerCase();
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
      'ø': 'diametro',
    };
    replacements.forEach((source, target) {
      normalized = normalized.replaceAll(source, target);
    });
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<void> _migrarEstructuraCatalogo(Database db) async {
    final empresaColumns = await db.rawQuery('PRAGMA table_info(empresas)');
    final empresaNames = empresaColumns
        .map((row) => row['name'] as String)
        .toSet();
    Future<void> addEmpresa(String name, String sql) async {
      if (!empresaNames.contains(name)) await db.execute(sql);
    }

    await addEmpresa(
      'ruc',
      "ALTER TABLE empresas ADD COLUMN ruc TEXT NOT NULL DEFAULT ''",
    );
    await addEmpresa(
      'telefono',
      "ALTER TABLE empresas ADD COLUMN telefono TEXT NOT NULL DEFAULT ''",
    );
    await addEmpresa(
      'direccion',
      "ALTER TABLE empresas ADD COLUMN direccion TEXT NOT NULL DEFAULT ''",
    );
    await addEmpresa(
      'estado',
      'ALTER TABLE empresas ADD COLUMN estado INTEGER NOT NULL DEFAULT 1',
    );
    await addEmpresa(
      'actualizado_en',
      'ALTER TABLE empresas ADD COLUMN actualizado_en TEXT',
    );

    final now = DateTime.now().toIso8601String();
    final oldBrands = await db.query('marcas');
    final products = await db.query(
      'productos',
      columns: ['empresa', 'marca', 'categoria', 'subcategoria'],
    );
    final companies = await db.query('empresas');
    final companyByName = <String, int>{
      for (final row in companies)
        (row['nombre'] as String).trim().toLowerCase(): row['id'] as int,
    };
    final fallbackCompanyId = companies.isEmpty
        ? await db.insert('empresas', {
            'nombre': 'Otra',
            'estado': 1,
            'actualizado_en': now,
          })
        : companies.first['id'] as int;

    await db.execute('ALTER TABLE marcas RENAME TO marcas_legacy_v13');
    await db.execute('''CREATE TABLE marcas(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      empresa_id INTEGER NOT NULL,
      nombre TEXT NOT NULL COLLATE NOCASE,
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT,
      FOREIGN KEY(empresa_id) REFERENCES empresas(id),
      UNIQUE(empresa_id, nombre)
    )''');
    for (final row in oldBrands) {
      final brandName = row['nombre'] as String;
      final matchingProduct = products.cast<Map<String, Object?>>().firstWhere(
        (product) =>
            (product['marca'] as String).trim().toLowerCase() ==
            brandName.trim().toLowerCase(),
        orElse: () => const {},
      );
      final companyName = matchingProduct['empresa'] as String?;
      final companyId =
          companyByName[companyName?.trim().toLowerCase()] ?? fallbackCompanyId;
      await db.insert('marcas', {
        'id': row['id'],
        'empresa_id': companyId,
        'nombre': brandName,
        'estado': 1,
        'actualizado_en': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final product in products) {
      final companyName = product['empresa'] as String;
      var companyId = companyByName[companyName.trim().toLowerCase()];
      if (companyId == null) {
        companyId = await db.insert('empresas', {
          'nombre': companyName,
          'estado': 1,
          'actualizado_en': now,
        });
        companyByName[companyName.trim().toLowerCase()] = companyId;
      }
      await db.insert('marcas', {
        'empresa_id': companyId,
        'nombre': product['marca'] as String,
        'estado': 1,
        'actualizado_en': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await db.execute('DROP TABLE marcas_legacy_v13');

    final categoryColumns = await db.rawQuery('PRAGMA table_info(categorias)');
    final categoryNames = categoryColumns
        .map((row) => row['name'] as String)
        .toSet();
    Future<void> addCategory(String name, String sql) async {
      if (!categoryNames.contains(name)) await db.execute(sql);
    }

    await addCategory(
      'categoria_padre_id',
      'ALTER TABLE categorias ADD COLUMN categoria_padre_id INTEGER REFERENCES categorias(id)',
    );
    await addCategory(
      'descripcion',
      "ALTER TABLE categorias ADD COLUMN descripcion TEXT NOT NULL DEFAULT ''",
    );
    await addCategory(
      'estado',
      'ALTER TABLE categorias ADD COLUMN estado INTEGER NOT NULL DEFAULT 1',
    );
    await addCategory(
      'actualizado_en',
      'ALTER TABLE categorias ADD COLUMN actualizado_en TEXT',
    );

    final legacySubTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'subcategorias'",
    );
    if (legacySubTables.isNotEmpty) {
      final subcategories = await db.query('subcategorias');
      for (final subcategory in subcategories) {
        await db.insert('categorias', {
          'categoria_padre_id': subcategory['categoria_id'],
          'nombre': subcategory['nombre'],
          'descripcion': '',
          'estado': 1,
          'actualizado_en': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    await db.execute('''CREATE TABLE categorias_v14(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      categoria_padre_id INTEGER,
      nombre TEXT NOT NULL COLLATE NOCASE,
      descripcion TEXT NOT NULL DEFAULT '',
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT,
      FOREIGN KEY(categoria_padre_id) REFERENCES categorias_v14(id),
      UNIQUE(categoria_padre_id, nombre)
    )''');
    await db.execute('''
      INSERT INTO categorias_v14(
        id, categoria_padre_id, nombre, descripcion, estado, actualizado_en
      )
      SELECT id, categoria_padre_id, nombre, descripcion, estado, actualizado_en
      FROM categorias
    ''');
    await db.execute('''CREATE TABLE atributos_def_v14(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      categoria_id INTEGER NOT NULL,
      nombre TEXT NOT NULL,
      tipo TEXT NOT NULL,
      es_variante INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY(categoria_id) REFERENCES categorias_v14(id)
    )''');
    await db.execute('''
      INSERT INTO atributos_def_v14(
        id, categoria_id, nombre, tipo, es_variante
      )
      SELECT id, categoria_id, nombre, tipo, es_variante
      FROM atributos_def
    ''');
    await db.execute('DROP TABLE atributos_def');
    if (legacySubTables.isNotEmpty) {
      await db.execute('DROP TABLE subcategorias');
    }
    await db.execute('DROP TABLE categorias');
    await db.execute('ALTER TABLE categorias_v14 RENAME TO categorias');
    await db.execute('ALTER TABLE atributos_def_v14 RENAME TO atributos_def');
    await db.execute('''CREATE UNIQUE INDEX idx_categoria_raiz_nombre
      ON categorias(nombre) WHERE categoria_padre_id IS NULL''');

    await db.execute('''CREATE TABLE IF NOT EXISTS marca_categorias(
      marca_id INTEGER NOT NULL,
      categoria_id INTEGER NOT NULL,
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT,
      PRIMARY KEY(marca_id, categoria_id),
      FOREIGN KEY(marca_id) REFERENCES marcas(id),
      FOREIGN KEY(categoria_id) REFERENCES categorias(id)
    )''');
    final brandRows = await db.rawQuery('''
      SELECT m.id, m.nombre, e.nombre AS empresa
      FROM marcas m
      INNER JOIN empresas e ON e.id = m.empresa_id
    ''');
    final categoryRows = await db.query(
      'categorias',
      where: 'categoria_padre_id IS NULL',
    );
    for (final product in products) {
      final brand = brandRows.cast<Map<String, Object?>>().firstWhere(
        (row) =>
            (row['nombre'] as String).trim().toLowerCase() ==
                (product['marca'] as String).trim().toLowerCase() &&
            (row['empresa'] as String).trim().toLowerCase() ==
                (product['empresa'] as String).trim().toLowerCase(),
        orElse: () => const {},
      );
      final category = categoryRows.cast<Map<String, Object?>>().firstWhere(
        (row) =>
            (row['nombre'] as String).trim().toLowerCase() ==
            (product['categoria'] as String).trim().toLowerCase(),
        orElse: () => const {},
      );
      if (brand.isNotEmpty && category.isNotEmpty) {
        await db.insert('marca_categorias', {
          'marca_id': brand['id'],
          'categoria_id': category['id'],
          'estado': 1,
          'actualizado_en': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    for (final company in await db.query('empresas')) {
      await db.insert('marcas', {
        'empresa_id': company['id'],
        'nombre': 'Sin marca',
        'estado': 1,
        'actualizado_en': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_marcas_empresa ON marcas(empresa_id, estado)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categorias_padre ON categorias(categoria_padre_id, estado)',
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
    final empresaIds = <String, int>{};
    for (final nombre in [
      'DINA',
      'Garibaldi',
      'Rumi Import',
      'Dubau',
      'Otra',
    ]) {
      empresaIds[nombre] = await db.insert('empresas', {
        'nombre': nombre,
        'estado': 1,
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }
    const marcasEmpresas = {
      'DINA': 'DINA',
      'Garibaldi': 'Garibaldi',
      'Rumi': 'Rumi Import',
      'Dubau': 'Dubau',
      'Otra': 'Otra',
    };
    final marcaIds = <String, int>{};
    for (final entry in marcasEmpresas.entries) {
      marcaIds[entry.key] = await db.insert('marcas', {
        'empresa_id': empresaIds[entry.value],
        'nombre': entry.key,
        'estado': 1,
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }
    for (final empresa in empresaIds.entries) {
      await db.insert('marcas', {
        'empresa_id': empresa.value,
        'nombre': 'Sin marca',
        'estado': 1,
        'actualizado_en': DateTime.now().toIso8601String(),
      });
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
    final categoriaIds = <String, int>{};
    for (final entry in categorias.entries) {
      final categoriaId = await db.insert('categorias', {
        'nombre': entry.key,
        'estado': 1,
        'actualizado_en': DateTime.now().toIso8601String(),
      });
      categoriaIds[entry.key] = categoriaId;
      for (final subcategoria in entry.value) {
        await db.insert('categorias', {
          'categoria_padre_id': categoriaId,
          'nombre': subcategoria,
          'estado': 1,
          'actualizado_en': DateTime.now().toIso8601String(),
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
    const relacionesIniciales = {
      'DINA': ['Pernería'],
      'Rumi': ['Pernería'],
      'Garibaldi': ['Herramientas eléctricas', 'Herramientas manuales'],
      'Dubau': ['Limpieza'],
      'Otra': ['Purificadores'],
    };
    for (final entry in relacionesIniciales.entries) {
      for (final categoria in entry.value) {
        await db.insert('marca_categorias', {
          'marca_id': marcaIds[entry.key],
          'categoria_id': categoriaIds[categoria],
          'estado': 1,
          'actualizado_en': DateTime.now().toIso8601String(),
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
