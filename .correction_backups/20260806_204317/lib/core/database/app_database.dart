import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

part 'migrations/catalog_attributes_migration.dart';
part 'migrations/catalog_structure_migrations.dart';
part 'migrations/order_columns_migrations.dart';
part 'migrations/order_support_migrations.dart';
part 'migrations/price_list_migration.dart';
part 'migrations/quote_migrations.dart';
part 'migrations/sync_infrastructure_migration.dart';
part 'migrations/sync_reliability_migration.dart';
part 'migrations/sync_rejected_events_recovery_migration.dart';
part 'migrations/technical_values_migrations.dart';
part 'schema/catalog_attributes_schema.dart';
part 'schema/catalog_structure_schema.dart';
part 'schema/operations_schema.dart';
part 'schema/orders_schema.dart';
part 'schema/quotes_schema.dart';
part 'schema/sync_infrastructure_schema.dart';

class AppDatabase {
  AppDatabase._() : _factory = null, _pathResolver = _defaultPath;

  /// Constructor aislado para pruebas de creación y migración SQLite.
  // ignore: prefer_initializing_formals
  AppDatabase.forTesting({
    required DatabaseFactory factory,
    required String path,
  }) : _factory = factory,
       _pathResolver = (() async => path);

  static final AppDatabase instance = AppDatabase._();
  static const version = 26;

  final DatabaseFactory? _factory;
  final Future<String> Function() _pathResolver;
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<void> open() async => database;

  Future<void> close() async {
    final current = _database;
    _database = null;
    await current?.close();
  }

  static Future<String> _defaultPath() async =>
      join(await getDatabasesPath(), 'app_catalogo.db');

  Future<Database> _open() async {
    final path = await _pathResolver();
    return (_factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
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
          await _migrarAtributosDef(db);
          await _migrarSincronizacionV23(db);
          await _migrarSincronizacionV24(db);
          await _migrarSincronizacionV25(db);
          await _migrarListasPreciosV26(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE productos ADD COLUMN imagen_path TEXT',
            );
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
          if (oldVersion < 23) {
            await _migrarSincronizacionV23(db);
          }
          if (oldVersion < 24) {
            await _migrarSincronizacionV24(db);
          }
          if (oldVersion < 25) {
            await _migrarSincronizacionV25(db);
          }
          if (oldVersion < 26) {
            await _migrarListasPreciosV26(db);
          }
        },
      ),
    );
  }
}
