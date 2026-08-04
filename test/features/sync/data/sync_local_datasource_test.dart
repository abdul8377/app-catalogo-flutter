import 'dart:convert';
import 'dart:io';

import 'package:app_catalogo/core/database/app_database.dart';
import 'package:app_catalogo/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:app_catalogo/features/sync/data/mappers/sync_entity_registry.dart';
import 'package:app_catalogo/features/sync/data/models/sync_bootstrap_models.dart';
import 'package:app_catalogo/features/sync/data/models/sync_pull_models.dart';
import 'package:app_catalogo/features/sync/data/models/sync_push_models.dart';
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
      await database.update(
        'sync_file_queue',
        {'status': 'ready', 'object_key': 'files/photo-1/content'},
        where: "owner_type = 'CLIENT' AND owner_id = 'cliente-local'",
      );

      final batch = await datasource.prepareOutboxBatch();
      expect(batch, hasLength(1));
      expect(batch.single.entityType, 'CLIENT');
      expect(batch.single.payload['nombre'], 'Cliente local');
      expect(batch.single.payload, isNot(contains('foto_ubicacion_path')));
      expect(
        batch.single.payload['locationPhotoStorageKey'],
        'files/photo-1/content',
      );

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
            sequence: 25,
            entityType: 'CLIENT',
            entityId: 'cliente-remoto',
            operation: 'UPSERT',
            version: 2,
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
      expect(await datasource.readAckCursor(), 0);
      expect(await datasource.readPendingAckCursor(), 25);
      expect((await database.query('sync_inbox')).single['status'], 'applied');

      await datasource.markAckConfirmed(25);
      expect(await datasource.readAckCursor(), 25);
      expect(await datasource.readPendingAckCursor(), isNull);
    },
  );

  test(
    'conserva el cambio local y registra conflicto ante versión remota',
    () async {
      await database.insert('clientes', _cliente('cliente-conflicto', 'Local'));

      await datasource.applyChangePage(
        [
          SyncChangeModel(
            sequence: 30,
            entityType: 'CLIENT',
            entityId: 'cliente-conflicto',
            operation: 'UPSERT',
            version: 4,
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
    'bootstrap solo termina al aplicar la ultima pagina y deja ACK',
    () async {
      await datasource.beginBootstrap(resetCursor: true);
      await datasource.applyBootstrapPage(
        const [
          SyncBootstrapRecordModel(
            entityType: 'CLIENT',
            entityId: 'bootstrap-client',
            version: 1,
            deleted: false,
            payload: {
              'name': 'Cliente bootstrap',
              'phone': '999999999',
              'createdAt': '2026-08-04T00:00:00Z',
            },
            updatedAt: '2026-08-04T00:00:00Z',
          ),
        ],
        snapshotCursor: 40,
        isLastPage: false,
      );

      expect(await datasource.isBootstrapCompleted(), isFalse);
      expect(await datasource.readPullCursor(), 0);
      expect(await datasource.readPendingAckCursor(), isNull);

      await datasource.applyBootstrapPage(
        const [],
        snapshotCursor: 40,
        isLastPage: true,
      );

      expect(await datasource.isBootstrapCompleted(), isTrue);
      expect(await datasource.readPullCursor(), 40);
      expect(await datasource.readPendingAckCursor(), 40);
      expect(
        await database.query(
          'clientes',
          where: 'id = ?',
          whereArgs: const ['bootstrap-client'],
        ),
        hasLength(1),
      );
    },
  );

  test('conserva conflictId del backend sin sustituirlo', () async {
    await database.insert('clientes', _cliente('conflict-backend', 'Local'));
    final batch = await datasource.prepareOutboxBatch();
    final event = batch.singleWhere(
      (item) => item.entityId == 'conflict-backend',
    );

    await datasource.markPushResults(
      [event],
      [
        SyncPushResultModel(
          eventId: event.eventId,
          status: 'CONFLICT',
          serverVersion: 4,
          conflictId: 'backend-conflict-42',
        ),
      ],
    );

    final conflict = (await database.query(
      'sync_conflicts_local',
      where: 'backend_conflict_id = ?',
      whereArgs: const ['backend-conflict-42'],
    )).single;
    expect(conflict['id'], 'backend-conflict-42');
  });

  test('una instalacion con solo demos se considera vacia', () async {
    expect(await datasource.hasBusinessData(), isFalse);

    await database.insert('clientes', _cliente('cliente-real', 'Cliente'));

    expect(await datasource.hasBusinessData(), isTrue);
  });

  test(
    'la fuente PC poda datos locales solo al terminar el snapshot',
    () async {
      await database.insert('clientes', _cliente('cliente-local', 'Local'));
      await datasource.prepareServerInitialSource();

      await datasource.applyBootstrapPage(
        const [
          SyncBootstrapRecordModel(
            entityType: 'CLIENT',
            entityId: 'cliente-servidor',
            version: 1,
            deleted: false,
            payload: {
              'name': 'Servidor',
              'phone': '999999999',
              'createdAt': '2026-08-04T00:00:00Z',
            },
            updatedAt: '2026-08-04T00:00:00Z',
          ),
        ],
        snapshotCursor: 50,
        isLastPage: false,
      );
      expect(
        await database.query(
          'clientes',
          where: 'id = ?',
          whereArgs: const ['cliente-local'],
        ),
        hasLength(1),
      );

      await datasource.applyBootstrapPage(
        const [],
        snapshotCursor: 50,
        isLastPage: true,
      );

      expect(
        await database.query(
          'clientes',
          where: 'id = ?',
          whereArgs: const ['cliente-local'],
        ),
        isEmpty,
      );
      expect(
        await database.query(
          'clientes',
          where: 'id = ?',
          whereArgs: const ['cliente-servidor'],
        ),
        hasLength(1),
      );
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
  serverUrlCache: 'http://192.168.1.10:8081',
  deviceId: 'tablet-1',
  deviceName: 'Tablet',
  contractVersion: '1.0',
  linkedAt: DateTime(2026, 8, 4),
);
