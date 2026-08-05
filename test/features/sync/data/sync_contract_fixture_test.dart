import 'dart:convert';
import 'dart:io';

import 'package:app_catalogo/features/sync/data/contracts/sync_contract.dart';
import 'package:app_catalogo/features/sync/data/models/device_registration_models.dart';
import 'package:app_catalogo/features/sync/data/models/sync_bootstrap_models.dart';
import 'package:app_catalogo/features/sync/data/models/sync_discovery_models.dart';
import 'package:app_catalogo/features/sync/data/models/sync_file_models.dart';
import 'package:app_catalogo/features/sync/data/models/sync_pull_models.dart';
import 'package:app_catalogo/features/sync/data/models/sync_push_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registro usa exactamente el contrato 1.0 del backend', () async {
    final fixture = await _fixture('registration_request.json');
    final request = const DeviceRegistrationRequestModel(
      name: 'Tablet de ventas',
      pairingCode: '12345678',
    );

    expect(
      request.toJson(apiContractVersion: SyncContract.apiVersion),
      fixture,
    );
    final response = DeviceRegistrationResponseModel.fromJson(
      await _fixture('registration_response.json'),
    );
    expect(response.deviceId, 'tablet-1');
    expect(response.apiContractVersion, '1.0');
  });

  test('descubrimiento conserva identidad, puerto y version String', () async {
    final discovery = SyncDiscoveryModel.fromJson(
      await _fixture('discovery_response.json'),
    );

    expect(discovery.serverId, 'server-1');
    expect(discovery.port, 8081);
    expect(discovery.apiContractVersion, isA<String>());
    expect(discovery.apiContractVersion, SyncContract.apiVersion);
  });

  test('push incluye versiones de API, payload y esquema', () async {
    final fixture = await _fixture('push_request.json');
    final request = SyncPushRequestModel(
      deviceId: 'tablet-1',
      apiContractVersion: SyncContract.apiVersion,
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

    expect(request.toJson(), fixture);
    final response = await _fixture('push_response.json');
    final result = SyncPushResultModel.fromJson(
      Map<String, Object?>.from((response['results'] as List).single as Map),
    );
    expect(result.status, 'CONFLICT');
    expect(result.conflictId, 'conflict-backend-1');
  });

  test('pull lee sequence/version y ACK conserva el cursor', () async {
    final page = SyncPullPageModel.fromJson(
      await _fixture('pull_response.json'),
    );
    final ack = SyncPullAckModel.fromJson(
      await _fixture('pull_ack_response.json'),
    );

    expect(page.changes.single.sequence, 151);
    expect(page.changes.single.version, 4);
    expect(ack.acknowledgedCursor, page.nextCursor);
  });

  test('bootstrap usa records y snapshotCursor propios', () async {
    final page = SyncBootstrapPageModel.fromJson(
      await _fixture('bootstrap_response.json'),
    );

    expect(page.page, 0);
    expect(page.nextPage, 1);
    expect(page.snapshotCursor, 150);
    expect(page.records.single.entityType, 'PRODUCT');
  });

  test('PRODUCT conserva catálogo y configuración completa de SQLite', () async {
    final product = await _fixture('product_aggregate.json');
    final intent = SyncFileIntentModel.fromJson(
      await _fixture('file_intent_response.json'),
    );
    final stored = SyncStoredFileModel.fromJson(
      await _fixture('stored_file_response.json'),
    );

    expect(product['attributes'], isA<Map>());
    expect(product['variants'], isA<List>());
    expect(product['presentations'], isA<List>());
    expect(product['prices'], isA<List>());
    expect(product['images'], isA<List>());
    expect(product['familyAxes'], isA<List>());
    expect(product['attributeValues'], isA<List>());
    expect(product['attributeOptions'], isA<List>());
    expect(product['salesConfiguration'], isA<Map>());
    expect(product['pricingConfiguration'], isA<Map>());
    expect(product['imageConfiguration'], isA<Map>());
    expect(intent.completeUrl, '/api/v1/files/intents/file-1/complete');
    expect(stored.storageKey, 'files/file-1/content');
    expect(stored.status, 'READY');
  });

  test('conflicto conserva el ID asignado por el backend', () async {
    final conflict = await _fixture('conflict_response.json');
    expect(conflict['conflictId'], 'conflict-backend-1');
    expect(conflict['status'], 'PENDING');
  });
}

Future<Map<String, Object?>> _fixture(String name) async {
  final raw = await File('test/features/sync/fixtures/$name').readAsString();
  return Map<String, Object?>.from(jsonDecode(raw) as Map);
}
