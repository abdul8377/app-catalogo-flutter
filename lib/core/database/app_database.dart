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
      version: 5,
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
      activa INTEGER NOT NULL DEFAULT 0, creado_en TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS pedidos(
      id TEXT PRIMARY KEY, codigo TEXT NOT NULL UNIQUE, hoja_id TEXT NOT NULL,
      cliente_id TEXT NOT NULL, vendedor TEXT NOT NULL, estado TEXT NOT NULL,
      subtotal_conocido REAL NOT NULL DEFAULT 0, total_parcial INTEGER NOT NULL DEFAULT 0,
      creado_en TEXT NOT NULL,
      FOREIGN KEY(hoja_id) REFERENCES hojas_pedido(id),
      FOREIGN KEY(cliente_id) REFERENCES clientes(id)
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS pedido_items(
      id TEXT PRIMARY KEY, pedido_id TEXT NOT NULL, producto_id TEXT NOT NULL,
      codigo TEXT NOT NULL, nombre TEXT NOT NULL, presentacion TEXT NOT NULL,
      equivalencia TEXT NOT NULL, cantidad INTEGER NOT NULL,
      precio_unitario REAL, subtotal REAL,
      FOREIGN KEY(pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
      FOREIGN KEY(producto_id) REFERENCES productos(id)
    )''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_clientes_busqueda ON clientes(nombre, telefono, dni, ruc)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedidos_hoja ON pedidos(hoja_id, creado_en)',
    );
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
