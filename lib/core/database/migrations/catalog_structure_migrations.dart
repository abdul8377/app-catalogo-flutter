part of '../app_database.dart';

extension _CatalogStructureMigrations on AppDatabase {
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
}
