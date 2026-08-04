import 'dart:io';

import 'package:app_catalogo/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late DatabaseFactory factory;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    factory = databaseFactoryFfi;
    tempDirectory = await Directory.systemTemp.createTemp(
      'app_catalogo_database_test_',
    );
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('crea desde cero el esquema SQLite 23 esperado', () async {
    final path = p.join(tempDirectory.path, 'catalogo_v23.db');
    final appDatabase = AppDatabase.forTesting(factory: factory, path: path);
    addTearDown(appDatabase.close);

    final database = await appDatabase.database;
    final version =
        (await database.rawQuery('PRAGMA user_version')).single.values.first
            as int;
    final tableRows = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tables = tableRows.map((row) => row['name']).toSet();

    expect(version, AppDatabase.version);
    expect(
      tables,
      containsAll(<String>{
        'productos',
        'pedidos',
        'pedido_items',
        'clientes',
        'hojas_pedido',
        'cotizaciones',
        'preparacion_productos',
        'sync_queue',
        'sync_configuration',
        'sync_state',
        'sync_entity_state',
        'sync_inbox',
        'sync_conflicts_local',
        'sync_file_queue',
      }),
    );

    final syncQueueColumns = (await database.rawQuery(
      'PRAGMA table_info(sync_queue)',
    )).map((row) => row['name']);
    expect(
      syncQueueColumns,
      containsAll(<String>{
        'base_version',
        'payload_version',
        'next_retry_at',
        'server_version',
        'server_sequence',
        'last_error_code',
      }),
    );

    final pedidoItemColumns = await database.rawQuery(
      'PRAGMA table_info(pedido_items)',
    );
    expect(
      pedidoItemColumns.map((row) => row['name']),
      containsAll(<String>{
        'activo',
        'variante_id',
        'presentacion_id',
        'precio_lista_id',
        'precio_configuracion',
      }),
    );
  });

  test('migra 21 a 22 conservando registros e identidad de items', () async {
    final path = p.join(tempDirectory.path, 'catalogo_v21.db');
    final legacy = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 21,
        onCreate: (database, _) async {
          await database.execute('''
            CREATE TABLE pedido_items(
              id TEXT PRIMARY KEY,
              pedido_id TEXT NOT NULL,
              producto_id TEXT NOT NULL
            )
          ''');
          await database.insert('pedido_items', {
            'id': 'item-historico',
            'pedido_id': 'pedido-historico',
            'producto_id': 'producto-historico',
          });
        },
      ),
    );
    await legacy.close();

    final appDatabase = AppDatabase.forTesting(factory: factory, path: path);
    addTearDown(appDatabase.close);
    final database = await appDatabase.database;

    final version =
        (await database.rawQuery('PRAGMA user_version')).single.values.first
            as int;
    final columns = (await database.rawQuery(
      'PRAGMA table_info(pedido_items)',
    )).map((row) => row['name']).toSet();
    final historic = await database.query(
      'pedido_items',
      where: 'id = ?',
      whereArgs: const ['item-historico'],
    );
    final indexes = await database.rawQuery('PRAGMA index_list(pedido_items)');

    expect(version, AppDatabase.version);
    expect(
      columns,
      containsAll(<String>{
        'activo',
        'variante_id',
        'variante_sku',
        'variante_nombre',
        'atributos_variante_json',
        'presentacion_id',
        'precio_lista_id',
        'precio_lista_nombre',
        'precio_configuracion',
        'imagen_path',
      }),
    );
    expect(historic, hasLength(1));
    expect(historic.single['producto_id'], 'producto-historico');
    expect(
      indexes.map((row) => row['name']),
      contains('idx_pedido_items_activos'),
    );
  });

  test('migra 22 a 23 conservando cola e identidades locales', () async {
    final path = p.join(tempDirectory.path, 'catalogo_v22.db');
    final legacy = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 22,
        onCreate: (database, _) async {
          await database.execute('''CREATE TABLE empresas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            ruc TEXT NOT NULL DEFAULT '',
            telefono TEXT NOT NULL DEFAULT '',
            direccion TEXT NOT NULL DEFAULT '',
            estado INTEGER NOT NULL DEFAULT 1,
            actualizado_en TEXT
          )''');
          await database.execute('''CREATE TABLE sync_queue(
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
          await database.insert('empresas', {'nombre': 'Empresa histórica'});
          await database.insert('sync_queue', {
            'id': 'evento-historico',
            'entidad': 'COMPANY',
            'entidad_id': 'empresa-historica',
            'accion': 'upsert',
            'payload_json': '{"nombre":"Empresa histórica"}',
            'estado': 'pendiente',
            'creado_en': '2026-01-01T00:00:00.000Z',
            'actualizado_en': '2026-01-01T00:00:00.000Z',
          });
        },
      ),
    );
    await legacy.close();

    final appDatabase = AppDatabase.forTesting(factory: factory, path: path);
    addTearDown(appDatabase.close);
    final database = await appDatabase.database;

    final company = (await database.query('empresas')).single;
    final historicEvent = (await database.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: const ['evento-historico'],
    )).single;
    final configurationColumns = (await database.rawQuery(
      'PRAGMA table_info(sync_configuration)',
    )).map((row) => row['name']);

    expect(company['nombre'], 'Empresa histórica');
    expect(company['sync_id'], isNotEmpty);
    expect(historicEvent['estado'], 'pending');
    expect(historicEvent['accion'], 'UPSERT');
    expect(historicEvent['base_version'], 0);
    expect(configurationColumns, isNot(contains('device_token')));
    expect(configurationColumns, isNot(contains('token')));
  });
}
