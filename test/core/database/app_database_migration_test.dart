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

  test('crea desde cero el esquema SQLite 24 esperado', () async {
    final path = p.join(tempDirectory.path, 'catalogo_v24.db');
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
        'schema_version',
        'checksum',
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

  test('migra 23 a 24 conservando estado y corrigiendo PRODUCT', () async {
    final path = p.join(tempDirectory.path, 'catalogo_v23_historico.db');
    final legacy = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 23,
        onCreate: (database, _) async {
          await database.execute('''CREATE TABLE sync_queue(
            id TEXT PRIMARY KEY,
            entidad TEXT NOT NULL,
            entidad_id TEXT NOT NULL,
            accion TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            estado TEXT NOT NULL,
            intentos INTEGER NOT NULL DEFAULT 0,
            error TEXT,
            creado_en TEXT NOT NULL,
            actualizado_en TEXT NOT NULL,
            base_version INTEGER NOT NULL DEFAULT 0,
            payload_version INTEGER NOT NULL DEFAULT 1,
            next_retry_at TEXT,
            server_version INTEGER,
            server_sequence INTEGER,
            last_error_code TEXT
          )''');
          await database.execute('''CREATE TABLE sync_configuration(
            id INTEGER PRIMARY KEY,
            server_id TEXT NOT NULL,
            server_name TEXT NOT NULL,
            service_type TEXT NOT NULL,
            server_url_cache TEXT,
            device_id TEXT NOT NULL,
            device_name TEXT NOT NULL,
            contract_version INTEGER NOT NULL,
            linked_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )''');
          await database.execute('''CREATE TABLE sync_state(
            id INTEGER PRIMARY KEY,
            last_pull_cursor INTEGER NOT NULL DEFAULT 0,
            last_ack_cursor INTEGER NOT NULL DEFAULT 0,
            last_success_at TEXT,
            last_attempt_at TEXT,
            bootstrap_completed INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
          )''');
          await database.execute('''CREATE TABLE sync_conflicts_local(
            id TEXT PRIMARY KEY,
            event_id TEXT,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            local_base_version INTEGER NOT NULL,
            server_version INTEGER NOT NULL,
            local_payload_json TEXT NOT NULL,
            server_payload_json TEXT,
            status TEXT NOT NULL,
            message TEXT,
            created_at TEXT NOT NULL,
            resolved_at TEXT
          )''');
          await database.execute('''CREATE TABLE sync_file_queue(
            id TEXT PRIMARY KEY,
            owner_type TEXT NOT NULL,
            owner_id TEXT NOT NULL,
            local_path TEXT NOT NULL,
            checksum TEXT,
            size_bytes INTEGER,
            object_key TEXT,
            status TEXT NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0,
            next_retry_at TEXT,
            last_error TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )''');
          await database.execute('''CREATE TABLE sync_runtime_context(
            id INTEGER PRIMARY KEY,
            applying_remote INTEGER NOT NULL DEFAULT 0
          )''');
          await database.execute('''CREATE TABLE sync_entity_state(
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            server_version INTEGER NOT NULL DEFAULT 0,
            sync_status TEXT NOT NULL,
            last_error TEXT,
            last_synced_at TEXT,
            PRIMARY KEY(entity_type, entity_id)
          )''');
          await database.execute('''CREATE TABLE producto_variantes_catalogo(
            id TEXT PRIMARY KEY,
            producto_id TEXT NOT NULL,
            sku TEXT NOT NULL,
            codigo_proveedor TEXT NOT NULL DEFAULT '',
            nombre_corto TEXT NOT NULL,
            estado INTEGER NOT NULL DEFAULT 1
          )''');
          await database.execute('''CREATE TABLE producto_familia_ejes(
            producto_id TEXT NOT NULL,
            categoria_atributo_id TEXT NOT NULL,
            orden INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY(producto_id, categoria_atributo_id)
          )''');
          await database.execute('''CREATE TABLE producto_atributos(
            id TEXT PRIMARY KEY,
            producto_id TEXT,
            variante_id TEXT,
            categoria_atributo_id TEXT NOT NULL
          )''');
          await database.execute('''CREATE TABLE producto_atributo_opciones(
            producto_atributo_id TEXT NOT NULL,
            opcion_id TEXT NOT NULL,
            categoria_atributo_id TEXT NOT NULL,
            PRIMARY KEY(producto_atributo_id, opcion_id)
          )''');
          await database.insert('sync_runtime_context', {
            'id': 1,
            'applying_remote': 0,
          });
          await database.insert('sync_state', {
            'id': 1,
            'last_pull_cursor': 17,
            'last_ack_cursor': 12,
            'bootstrap_completed': 1,
            'updated_at': '2026-08-04T00:00:00.000Z',
          });
          await database.insert('producto_variantes_catalogo', {
            'id': 'variant-1',
            'producto_id': 'product-1',
            'sku': 'SKU-1',
            'nombre_corto': 'Variante',
          });
          await database.insert('sync_queue', {
            'id': 'child-event',
            'entidad': 'PRODUCT_VARIANT',
            'entidad_id': 'variant-1',
            'accion': 'UPSERT',
            'payload_json': '{}',
            'estado': 'pending',
            'creado_en': '2026-08-04T00:00:00.000Z',
            'actualizado_en': '2026-08-04T00:00:00.000Z',
          });
        },
      ),
    );
    await legacy.close();

    final appDatabase = AppDatabase.forTesting(factory: factory, path: path);
    addTearDown(appDatabase.close);
    final database = await appDatabase.database;

    final state = (await database.query('sync_state')).single;
    final events = await database.query('sync_queue');
    final conflictColumns = (await database.rawQuery(
      'PRAGMA table_info(sync_conflicts_local)',
    )).map((row) => row['name']);

    expect(state['last_pull_cursor'], 17);
    expect(state['last_ack_cursor'], 12);
    expect(state, contains('pending_ack_cursor'));
    expect(events, hasLength(1));
    expect(events.single['entidad'], 'PRODUCT');
    expect(events.single['entidad_id'], 'product-1');
    expect(conflictColumns, contains('backend_conflict_id'));
  });
}
