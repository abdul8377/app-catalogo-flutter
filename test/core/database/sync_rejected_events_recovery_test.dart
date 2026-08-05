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
      'sync_rejected_recovery_',
    );
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('v25 reencola un PRODUCT rechazado por el contrato anterior', () async {
    final path = p.join(tempDirectory.path, 'catalogo_v24.db');
    final legacy = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 24,
        onCreate: (database, _) async {
          await database.execute('''
            CREATE TABLE sync_queue(
              id TEXT PRIMARY KEY,
              entidad TEXT NOT NULL,
              entidad_id TEXT NOT NULL,
              estado TEXT NOT NULL,
              next_retry_at TEXT,
              error TEXT,
              last_error_code TEXT,
              actualizado_en TEXT
            )
          ''');
          await database.insert('sync_queue', {
            'id': 'event-product-1',
            'entidad': 'PRODUCT',
            'entidad_id': 'product-1',
            'estado': 'failed',
            'error': 'PRODUCT contiene campos no soportados',
            'last_error_code': 'REJECTED',
            'actualizado_en': '2026-08-04T20:00:00Z',
          });
        },
      ),
    );
    await legacy.close();

    final appDatabase = AppDatabase.forTesting(factory: factory, path: path);
    addTearDown(appDatabase.close);
    final database = await appDatabase.database;
    final row = (await database.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: ['event-product-1'],
    )).single;

    expect(row['estado'], 'retry');
    expect(row['last_error_code'], isNull);
    expect(row['error'], isNull);
    expect(
      (await database.rawQuery('PRAGMA user_version')).single.values.first,
      AppDatabase.version,
    );
  });
}
