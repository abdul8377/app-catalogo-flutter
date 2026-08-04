import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_catalogo/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:app_catalogo/features/sync/data/models/sync_push_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _ContractAdapter adapter;
  late SyncRemoteDatasource datasource;

  setUp(() {
    adapter = _ContractAdapter();
    datasource = SyncRemoteDatasource(Dio()..httpClientAdapter = adapter);
  });

  test('usa rutas y cuerpos reales de registro, push, pull y ACK', () async {
    final registration = await datasource.registerDevice(
      serverUrl: 'http://192.168.1.20:8081',
      deviceName: 'Tablet de ventas',
      pairingCode: '12345678',
    );
    final registrationRequest = adapter.requestFor('/devices/register');
    expect(registration.deviceId, 'tablet-1');
    expect(registrationRequest.data, {
      'name': 'Tablet de ventas',
      'platform': 'ANDROID',
      'pairingCode': '12345678',
      'appVersion': '1.0.0',
      'apiContractVersion': '1.0',
    });
    expect(registrationRequest.headers, isNot(contains('X-Pairing-Code')));

    final discovery = await datasource.discoverServer(
      serverUrl: 'http://192.168.1.20:8081',
    );
    expect(discovery.serverId, 'server-1');
    expect(discovery.port, 8081);

    final results = await datasource.push(
      serverUrl: 'http://192.168.1.20:8081',
      deviceId: 'tablet-1',
      token: 'token',
      events: const [
        SyncEventModel(
          eventId: 'event-1',
          entityType: 'PRODUCT',
          entityId: 'product-1',
          operation: 'UPSERT',
          baseVersion: 3,
          payloadVersion: 1,
          schemaVersion: '1.0',
          occurredAt: '2026-08-04T18:00:00Z',
          payload: {'productId': 'product-1'},
        ),
      ],
    );
    final pushRequest = adapter.requestFor('/sync/push');
    expect((pushRequest.data as Map)['apiContractVersion'], '1.0');
    expect(
      ((pushRequest.data as Map)['events'] as List).single,
      containsPair('payloadVersion', 1),
    );
    expect(results.single.conflictId, 'conflict-backend-1');

    final pull = await datasource.pull(
      serverUrl: 'http://192.168.1.20:8081',
      deviceId: 'tablet-1',
      token: 'token',
      after: 150,
    );
    expect(pull.changes.single.sequence, 151);
    expect(pull.changes.single.version, 4);
    expect(adapter.requestFor('/sync/pull').queryParameters['limit'], 300);

    final acknowledged = await datasource.acknowledgePull(
      serverUrl: 'http://192.168.1.20:8081',
      deviceId: 'tablet-1',
      token: 'token',
      cursor: 151,
    );
    expect(acknowledged, 151);
    expect(adapter.requestFor('/sync/pull/ack').data, {'cursor': 151});
  });

  test(
    'bootstrap conserva snapshot y archivos siguen intent/upload/complete',
    () async {
      final bootstrap = await datasource.bootstrap(
        serverUrl: 'http://192.168.1.20:8081',
        deviceId: 'tablet-1',
        token: 'token',
        page: 0,
      );
      expect(bootstrap.records.single.entityType, 'PRODUCT');
      expect(bootstrap.snapshotCursor, 150);
      expect(
        adapter.requestFor('/sync/bootstrap').queryParameters['limit'],
        300,
      );

      final intent = await datasource.createFileIntent(
        serverUrl: 'http://192.168.1.20:8081',
        deviceId: 'tablet-1',
        token: 'token',
        fileName: 'foto.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 4,
        checksumSha256:
            '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a',
        ownerType: 'PRODUCT',
        ownerId: 'product-1',
      );
      final intentRequest = adapter.requestFor('/files/intents');
      expect(intentRequest.data, containsPair('fileType', 'PRODUCT_IMAGE'));
      expect(intentRequest.data, containsPair('visibility', 'PUBLIC'));

      final temp = await File(
        '${Directory.systemTemp.path}/sync-contract-upload.jpg',
      ).writeAsBytes(const [1, 2, 3, 4]);
      addTearDown(() async {
        if (await temp.exists()) await temp.delete();
      });
      await datasource.uploadFileContent(
        serverUrl: 'http://192.168.1.20:8081',
        deviceId: 'tablet-1',
        token: 'token',
        intent: intent,
        localPath: temp.path,
        contentType: 'image/jpeg',
      );
      final ready = await datasource.completeFileUpload(
        serverUrl: 'http://192.168.1.20:8081',
        deviceId: 'tablet-1',
        token: 'token',
        intent: intent,
      );
      expect(ready.storageKey, 'files/file-1/content');
      expect(adapter.requestFor('/files/intents/file-1/content').method, 'PUT');
      expect(
        adapter.requestFor('/files/intents/file-1/complete').method,
        'POST',
      );
    },
  );
}

class _ContractAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  RequestOptions requestFor(String suffix) =>
      requests.lastWhere((request) => request.path.endsWith(suffix));

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final fixture = switch (options.path) {
      String path when path.endsWith('/devices/register') =>
        'registration_response.json',
      String path when path.endsWith('/discovery') => 'discovery_response.json',
      String path when path.endsWith('/sync/push') => 'push_response.json',
      String path when path.endsWith('/sync/pull/ack') =>
        'pull_ack_response.json',
      String path when path.endsWith('/sync/pull') => 'pull_response.json',
      String path when path.endsWith('/sync/bootstrap') =>
        'bootstrap_response.json',
      String path when path.endsWith('/files/intents') =>
        'file_intent_response.json',
      String path when path.endsWith('/files/intents/file-1/content') =>
        'stored_file_response.json',
      String path when path.endsWith('/files/intents/file-1/complete') =>
        'stored_file_response.json',
      _ => throw StateError('Ruta no simulada: ${options.path}'),
    };
    final raw = await File(
      'test/features/sync/fixtures/$fixture',
    ).readAsString();
    return ResponseBody.fromString(
      raw,
      options.path.endsWith('/devices/register') ? 201 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
