import 'dart:convert';
import 'dart:io';

import 'package:app_catalogo/core/database/app_database.dart';
import 'package:app_catalogo/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:app_catalogo/features/sync/data/mappers/sync_entity_registry.dart';
import 'package:app_catalogo/features/sync/data/models/sync_api_models.dart';
import 'package:app_catalogo/features/sync/domain/entities/sync_configuration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late AppDatabase appDatabase;
  late Database database;
  late SyncLocalDatasource datasource;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'app_catalogo_sync_local_test_',
    );
    appDatabase = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      path: p.join(tempDirectory.path, 'catalogo.db'),
    );
    database = await appDatabase.database;
    datasource = SyncLocalDatasource(appDatabase, const SyncEntityRegistry());
  });

  tearDown(() async {
    await appDatabase.close();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'materializa el snapshot al preparar el lote y acepta idempotencia',
    () async {
      final client = _cliente('cliente-local', 'Cliente local')
        ..['foto_ubicacion_path'] = r'D:\fotos\ubicacion.jpg';
      await database.insert('clientes', client);

      final batch = await datasource.prepareOutboxBatch();
      expect(batch, hasLength(1));
      expect(batch.single.entityType, 'CLIENT');
      expect(batch.single.payload['nombre'], 'Cliente local');
      expect(batch.single.payload, isNot(contains('foto_ubicacion_path')));

      await datasource.markPushResults(batch, [
        SyncPushResultModel(
          eventId: batch.single.eventId,
          status: 'ALREADY_PROCESSED',
          serverVersion: 3,
          serverSequence: 10,
        ),
      ]);

      final event = (await database.query(
        'sync_queue',
        where: 'id = ?',
        whereArgs: [batch.single.eventId],
      )).single;
      expect(event['estado'], 'synced');
      expect(await datasource.prepareOutboxBatch(), isEmpty);
    },
  );

  test(
    'aplica una página remota sin eco y avanza el cursor atómicamente',
    () async {
      await datasource.applyChangePage(
        [
          SyncChangeModel(
            serverSequence: 25,
            entityType: 'CLIENT',
            entityId: 'cliente-remoto',
            operation: 'UPSERT',
            serverVersion: 2,
            changedAt: '2026-08-04T12:00:00.000Z',
            payload: const {
              'name': 'Cliente remoto',
              'phone': '999999999',
              'createdAt': '2026-08-04T00:00:00.000Z',
            },
          ),
        ],
        nextCursor: 25,
        bootstrap: false,
      );

      final remote = await database.query(
        'clientes',
        where: 'id = ?',
        whereArgs: const ['cliente-remoto'],
      );
      expect(remote.single['nombre'], 'Cliente remoto');
      expect(await database.query('sync_queue'), isEmpty);
      expect(await datasource.readPullCursor(), 25);
      expect((await database.query('sync_inbox')).single['status'], 'applied');
    },
  );

  test(
    'conserva el cambio local y registra conflicto ante versión remota',
    () async {
      await database.insert('clientes', _cliente('cliente-conflicto', 'Local'));

      await datasource.applyChangePage(
        [
          SyncChangeModel(
            serverSequence: 30,
            entityType: 'CLIENT',
            entityId: 'cliente-conflicto',
            operation: 'UPSERT',
            serverVersion: 4,
            changedAt: '2026-08-04T12:30:00.000Z',
            payload: _cliente('cliente-conflicto', 'Remoto'),
          ),
        ],
        nextCursor: 30,
        bootstrap: false,
      );

      final local = (await database.query(
        'clientes',
        where: 'id = ?',
        whereArgs: const ['cliente-conflicto'],
      )).single;
      expect(local['nombre'], 'Local');
      expect(
        await database.query(
          'sync_conflicts_local',
          where: "status = 'pending'",
        ),
        hasLength(1),
      );
      final conflict = (await database.query('sync_conflicts_local')).single;
      final localPayload = jsonDecode(conflict['local_payload_json'] as String);
      expect(localPayload['nombre'], 'Local');
    },
  );

  test(
    'cambiar de PC invalida cursor y versiones, no los datos locales',
    () async {
      await database.insert(
        'clientes',
        _cliente('cliente-conservado', 'Local'),
      );
      await datasource.saveConfiguration(_configuration('servidor-a'));
      await datasource.applyChangePage(
        const [],
        nextCursor: 88,
        bootstrap: true,
      );

      await datasource.saveConfiguration(_configuration('servidor-b'));

      expect(await datasource.readPullCursor(), 0);
      expect(await datasource.isBootstrapCompleted(), isFalse);
      expect(
        await database.query(
          'clientes',
          where: 'id = ?',
          whereArgs: const ['cliente-conservado'],
        ),
        hasLength(1),
      );
    },
  );
}

Map<String, Object?> _cliente(String id, String name) => {
  'id': id,
  'nombre': name,
  'telefono': '999999999',
  'creado_en': '2026-08-04T00:00:00.000Z',
};

SyncConfiguration _configuration(String serverId) => SyncConfiguration(
  serverId: serverId,
  serverName: 'PC',
  serviceType: '_appcatalogo._tcp',
  serverUrlCache: 'http://192.168.1.10:8080',
  deviceId: 'tablet-1',
  deviceName: 'Tablet',
  contractVersion: 1,
  linkedAt: DateTime(2026, 8, 4),
);
