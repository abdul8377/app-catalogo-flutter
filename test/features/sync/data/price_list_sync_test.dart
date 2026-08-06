import 'dart:io';

import 'package:app_catalogo/core/database/app_database.dart';
import 'package:app_catalogo/features/sync/data/mappers/sync_entity_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late AppDatabase appDatabase;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'app_catalogo_price_list_test_',
    );
    appDatabase = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      path: p.join(tempDirectory.path, 'catalogo.db'),
    );
  });

  tearDown(() async {
    await appDatabase.close();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('crea la lista General en PEN y su infraestructura de cola', () async {
    final database = await appDatabase.database;

    final general = await database.query(
      'listas_precios',
      where: 'id = ?',
      whereArgs: ['price-list-general'],
      limit: 1,
    );
    final triggers = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'trigger' "
      "AND name LIKE 'trg_sync_listas_precios_%'",
    );

    expect(general, hasLength(1));
    expect(general.single['nombre'], 'General');
    expect(general.single['moneda'], 'PEN');
    expect(general.single['igv_porcentaje'], 18.0);
    expect(triggers, hasLength(3));
  });

  test('aplica y exporta PRICE_LIST sin perder moneda ni IGV', () async {
    final database = await appDatabase.database;
    const registry = SyncEntityRegistry();

    await registry.applyRemote(
      database,
      entityType: 'PRICE_LIST',
      entityId: 'price-list-dina-mayo-2026',
      operation: 'UPSERT',
      payload: const {
        'id': 'price-list-dina-mayo-2026',
        'name': 'DINA mayo 2026',
        'currency': 'PEN',
        'includesTax': true,
        'taxRate': 18,
        'active': true,
      },
    );

    final exported = await registry.exportEntity(
      database,
      entityType: 'PRICE_LIST',
      entityId: 'price-list-dina-mayo-2026',
      operation: 'UPSERT',
    );

    expect(exported['id'], 'price-list-dina-mayo-2026');
    expect(exported['nombre'], 'DINA mayo 2026');
    expect(exported['moneda'], 'PEN');
    expect(exported['incluye_igv'], 1);
    expect(exported['igv_porcentaje'], 18);
    expect(exported['estado'], 1);
  });

  test('un cambio local de lista de precios genera un evento outbox', () async {
    final database = await appDatabase.database;

    await database.insert('listas_precios', {
      'id': 'price-list-mayorista',
      'nombre': 'Mayorista',
      'moneda': 'PEN',
      'incluye_igv': 1,
      'igv_porcentaje': 18.0,
      'estado': 1,
    });

    final queued = await database.query(
      'sync_queue',
      where: 'entidad = ? AND entidad_id = ?',
      whereArgs: ['PRICE_LIST', 'price-list-mayorista'],
    );

    expect(queued, hasLength(1));
    expect(queued.single['accion'], 'UPSERT');
    expect(queued.single['estado'], 'pending');
  });
}
