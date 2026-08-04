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

  test('crea desde cero el esquema SQLite 22 esperado', () async {
    final path = p.join(tempDirectory.path, 'catalogo_v22.db');
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
}
