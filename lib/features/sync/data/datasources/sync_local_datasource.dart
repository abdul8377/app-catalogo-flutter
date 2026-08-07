import 'dart:convert';
import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/sync_configuration.dart';
import '../../domain/entities/sync_status.dart';
import '../contracts/sync_contract.dart';
import '../mappers/sync_entity_registry.dart';
import '../models/sync_bootstrap_models.dart';
import '../models/sync_file_models.dart';
import '../models/sync_pull_models.dart';
import '../models/sync_push_models.dart';

class SyncLocalDatasource {
  const SyncLocalDatasource(this._appDatabase, this._registry);

  final AppDatabase _appDatabase;
  final SyncEntityRegistry _registry;

  Future<Database> get _database => _appDatabase.database;

  Future<SyncConfiguration?> readConfiguration() async {
    final database = await _database;
    final rows = await database.query(
      'sync_configuration',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return SyncConfiguration(
      serverId: row['server_id'] as String,
      serverName: row['server_name'] as String? ?? '',
      serviceType: row['service_type'] as String? ?? '_appcatalogo._tcp',
      serverUrlCache: row['server_url_cache'] as String? ?? '',
      deviceId: row['device_id'] as String,
      deviceName: row['device_name'] as String,
      contractVersion:
          row['contract_version']?.toString() ?? SyncContract.apiVersion,
      linkedAt: DateTime.parse(row['linked_at'] as String),
    );
  }

  Future<void> saveConfiguration(SyncConfiguration configuration) async {
    final database = await _database;
    final now = DateTime.now().toUtc().toIso8601String();
    await database.transaction((transaction) async {
      final previous = await transaction.query(
        'sync_configuration',
        columns: const ['server_id'],
        where: 'id = 1',
        limit: 1,
      );
      final changedServer =
          previous.isEmpty ||
          previous.single['server_id'] != configuration.serverId;
      await transaction.insert('sync_configuration', {
        'id': 1,
        'server_id': configuration.serverId,
        'server_name': configuration.serverName,
        'service_type': configuration.serviceType,
        'server_url_cache': configuration.serverUrlCache,
        'device_id': configuration.deviceId,
        'device_name': configuration.deviceName,
        'contract_version': configuration.contractVersion,
        'payload_version': SyncContract.payloadVersion,
        'schema_version': SyncContract.schemaVersion,
        'linked_at': configuration.linkedAt.toUtc().toIso8601String(),
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      if (changedServer) {
        await transaction.delete('sync_inbox');
        await transaction.delete('sync_entity_state');
        await transaction.delete('sync_conflicts_local');
        await transaction.update('sync_state', {
          'last_pull_cursor': 0,
          'last_ack_cursor': 0,
          'pending_ack_cursor': null,
          'bootstrap_snapshot_cursor': null,
          'bootstrap_completed': 0,
          'initialization_status': 'pending',
          'initial_snapshot_created': 0,
          'api_contract_version': SyncContract.apiVersion,
          'last_success_at': null,
          'updated_at': now,
        }, where: 'id = 1');
      }
    });
  }

  Future<void> updateServerUrl(String url) async {
    final database = await _database;
    await database.update('sync_configuration', {
      'server_url_cache': url,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = 1');
  }

  Future<void> clearConfiguration() async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.delete('sync_configuration', where: 'id = 1');
      await transaction.update('sync_state', {
        'last_pull_cursor': 0,
        'last_ack_cursor': 0,
        'pending_ack_cursor': null,
        'bootstrap_snapshot_cursor': null,
        'bootstrap_completed': 0,
        'initialization_status': 'pending',
        'initial_snapshot_created': 0,
        'last_success_at': null,
        'last_attempt_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, where: 'id = 1');
    });
  }

  Future<SyncStatus> readStatus() async {
    final database = await _database;
    await database.update('sync_queue', {
      'estado': 'retry',
    }, where: "estado = 'sending'");
    await database.update('sync_file_queue', {
      'status': 'retry',
      'next_retry_at': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: "status IN ('uploading', 'downloading')");
    final configuration = await readConfiguration();
    if (configuration == null) return const SyncStatus.unlinked();
    final counts = (await database.rawQuery('''
      SELECT
        SUM(CASE WHEN estado = 'pending' THEN 1 ELSE 0 END) pending,
        SUM(CASE WHEN estado = 'retry' THEN 1 ELSE 0 END) retry,
        SUM(CASE WHEN estado = 'conflict' THEN 1 ELSE 0 END) conflicts
      FROM sync_queue
    ''')).single;
    final localConflicts = Sqflite.firstIntValue(
      await database.rawQuery(
        "SELECT COUNT(*) FROM sync_conflicts_local WHERE status = 'pending'",
      ),
    );
    final pendingFiles = Sqflite.firstIntValue(
      await database.rawQuery(
        "SELECT COUNT(*) FROM sync_file_queue "
        "WHERE status IN ('pending', 'retry', 'uploading', "
        "'download_pending', 'downloading', 'failed')",
      ),
    );
    final state = (await database.query(
      'sync_state',
      where: 'id = 1',
      limit: 1,
    )).single;
    return SyncStatus(
      isLinked: true,
      pendingEvents: (counts['pending'] as num? ?? 0).toInt(),
      retryEvents: (counts['retry'] as num? ?? 0).toInt(),
      conflicts: math.max(
        (counts['conflicts'] as num? ?? 0).toInt(),
        localConflicts ?? 0,
      ),
      pendingFiles: pendingFiles ?? 0,
      serverName: configuration.serverName,
      serverUrl: configuration.serverUrlCache,
      lastSuccessAt: DateTime.tryParse(
        state['last_success_at'] as String? ?? '',
      ),
      initializationStatus:
          state['initialization_status'] as String? ?? 'pending',
      hasPendingAck: state['pending_ack_cursor'] != null,
    );
  }

  Future<int> readPullCursor() async {
    final database = await _database;
    return Sqflite.firstIntValue(
          await database.rawQuery(
            'SELECT last_pull_cursor FROM sync_state WHERE id = 1',
          ),
        ) ??
        0;
  }

  Future<int> readAckCursor() async {
    final database = await _database;
    return Sqflite.firstIntValue(
          await database.rawQuery(
            'SELECT last_ack_cursor FROM sync_state WHERE id = 1',
          ),
        ) ??
        0;
  }

  Future<int?> readPendingAckCursor() async {
    final database = await _database;
    final row = (await database.query(
      'sync_state',
      columns: const ['pending_ack_cursor'],
      where: 'id = 1',
      limit: 1,
    )).single;
    return (row['pending_ack_cursor'] as num?)?.toInt();
  }

  Future<void> markAckConfirmed(int cursor) async {
    final database = await _database;
    await database.update(
      'sync_state',
      {
        'last_ack_cursor': cursor,
        'pending_ack_cursor': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = 1 AND last_pull_cursor >= ?',
      whereArgs: [cursor],
    );
  }

  Future<bool> isBootstrapCompleted() async {
    final database = await _database;
    return (Sqflite.firstIntValue(
              await database.rawQuery(
                'SELECT bootstrap_completed FROM sync_state WHERE id = 1',
              ),
            ) ??
            0) ==
        1;
  }

  Future<void> beginBootstrap({required bool resetCursor}) async {
    final database = await _database;
    await database.update('sync_state', {
      'bootstrap_completed': 0,
      'bootstrap_snapshot_cursor': null,
      if (resetCursor) ...{
        'last_pull_cursor': 0,
        'last_ack_cursor': 0,
        'pending_ack_cursor': null,
      },
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = 1');
  }

  Future<List<SyncEventModel>> prepareOutboxBatch({
    int limit = SyncContract.pushBatchSize,
  }) async {
    final database = await _database;
    return database.transaction((transaction) async {
      final now = DateTime.now().toUtc().toIso8601String();
      final rows = await transaction.rawQuery(
        '''
        SELECT q.*
        FROM sync_queue q
        WHERE q.estado IN ('pending', 'retry')
          AND (q.next_retry_at IS NULL OR q.next_retry_at <= ?)
          AND NOT EXISTS (
            SELECT 1 FROM sync_file_queue f
            WHERE f.owner_type = q.entidad
              AND f.owner_id = q.entidad_id
              AND UPPER(f.direction) = 'UPLOAD'
              AND f.status NOT IN ('ready', 'downloaded')
          )
        ORDER BY q.creado_en ASC
        LIMIT ?
      ''',
        [now, limit],
      );
      final events = <SyncEventModel>[];
      for (final row in rows) {
        final eventId = row['id'] as String;
        final entityType = row['entidad'] as String;
        final entityId = row['entidad_id'] as String;
        var operation = (row['accion'] as String).toUpperCase();
        var payload = await _registry.exportEntity(
          transaction,
          entityType: entityType,
          entityId: entityId,
          operation: operation,
        );
        if (operation != 'DELETE' && payload.isEmpty) {
          operation = 'DELETE';
          payload = const {};
        }
        await transaction.update(
          'sync_queue',
          {
            'accion': operation,
            'payload_json': jsonEncode(payload),
            'estado': 'sending',
            'actualizado_en': now,
            'error': null,
            'last_error_code': null,
          },
          where: 'id = ?',
          whereArgs: [eventId],
        );
        events.add(
          SyncEventModel(
            eventId: eventId,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            baseVersion: (row['base_version'] as num? ?? 0).toInt(),
            payloadVersion:
                (row['payload_version'] as num? ?? SyncContract.payloadVersion)
                    .toInt(),
            schemaVersion:
                row['schema_version']?.toString() ?? SyncContract.schemaVersion,
            checksum: row['checksum'] as String?,
            occurredAt: row['creado_en'] as String,
            payload: payload,
          ),
        );
      }
      return events;
    });
  }

  Future<void> markPushResults(
    List<SyncEventModel> events,
    List<SyncPushResultModel> results,
  ) async {
    final database = await _database;
    final byId = {for (final result in results) result.eventId: result};
    await database.transaction((transaction) async {
      for (final event in events) {
        final result = byId[event.eventId];
        if (result == null) {
          await _markRetry(transaction, event.eventId, 'MISSING_RESULT');
          continue;
        }
        switch (result.status) {
          case 'ACCEPTED':
          case 'ALREADY_PROCESSED':
            await transaction.update(
              'sync_queue',
              {
                'estado': 'synced',
                'server_version': result.serverVersion,
                'server_sequence': result.serverSequence,
                'error': null,
                'last_error_code': null,
                'actualizado_en': DateTime.now().toUtc().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [event.eventId],
            );
            await transaction.insert('sync_entity_state', {
              'entity_type': event.entityType,
              'entity_id': event.entityId,
              'server_version': result.serverVersion ?? event.baseVersion,
              'sync_status': 'synced',
              'last_synced_at': DateTime.now().toUtc().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
            await _markLegacySynced(transaction, event);
          case 'CONFLICT':
            await transaction.update(
              'sync_queue',
              {
                'estado': 'conflict',
                'server_version': result.serverVersion,
                'server_sequence': result.serverSequence,
                'error': result.message,
                'last_error_code': 'CONFLICT',
              },
              where: 'id = ?',
              whereArgs: [event.eventId],
            );
            final conflictId = result.conflictId;
            await transaction.insert('sync_conflicts_local', {
              'id': conflictId?.isNotEmpty == true
                  ? conflictId
                  : 'event:${event.eventId}',
              'backend_conflict_id': conflictId,
              'event_id': event.eventId,
              'entity_type': event.entityType,
              'entity_id': event.entityId,
              'local_base_version': event.baseVersion,
              'server_version': result.serverVersion ?? 0,
              'local_payload_json': jsonEncode(event.payload),
              'status': 'pending',
              'message': result.message,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          default:
            await transaction.update(
              'sync_queue',
              {
                'estado': 'failed',
                'error': result.message ?? 'Cambio rechazado por el servidor.',
                'last_error_code': 'REJECTED',
                'actualizado_en': DateTime.now().toUtc().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [event.eventId],
            );
        }
      }
    });
  }

  Future<void> markBatchRetry(
    List<SyncEventModel> events, {
    required String errorCode,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      for (final event in events) {
        await _markRetry(transaction, event.eventId, errorCode);
      }
    });
  }

  Future<void> applyPullPage(
    List<SyncChangeModel> changes, {
    required int nextCursor,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await _setApplyingRemote(transaction, true);
      for (final change in changes) {
        await _applyRemoteRecord(
          transaction,
          sequence: change.sequence,
          entityType: change.entityType,
          entityId: change.entityId,
          operation: change.operation,
          version: change.version,
          originDeviceId: change.originDeviceId,
          payload: change.payload,
          changedAt: change.changedAt,
        );
      }
      final ack = await _readStateValue(transaction, 'last_ack_cursor');
      await transaction.update('sync_state', {
        'last_pull_cursor': nextCursor,
        'pending_ack_cursor': nextCursor > ack ? nextCursor : null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, where: 'id = 1');
      await _setApplyingRemote(transaction, false);
    });
  }

  Future<void> applyBootstrapPage(
    List<SyncBootstrapRecordModel> records, {
    required int snapshotCursor,
    required bool isLastPage,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await _setApplyingRemote(transaction, true);
      for (final record in records) {
        await _applyRemoteRecord(
          transaction,
          entityType: record.entityType,
          entityId: record.entityId,
          operation: record.deleted ? 'DELETE' : 'UPSERT',
          version: record.version,
          payload: record.payload,
          changedAt: record.updatedAt,
        );
      }
      final initialization = (await transaction.query(
        'sync_state',
        columns: const ['initialization_status'],
        where: 'id = 1',
        limit: 1,
      )).single['initialization_status'];
      if (isLastPage && initialization == 'server') {
        await transaction.execute('PRAGMA defer_foreign_keys = ON');
        await _registry.pruneMissingRemoteEntities(transaction);
      }
      final currentSnapshot = await _readNullableStateValue(
        transaction,
        'bootstrap_snapshot_cursor',
      );
      if (currentSnapshot != null && currentSnapshot != snapshotCursor) {
        throw StateError('El snapshot de bootstrap cambio entre paginas.');
      }
      await transaction.update('sync_state', {
        'bootstrap_snapshot_cursor': snapshotCursor,
        if (isLastPage) ...{
          'bootstrap_completed': 1,
          'last_pull_cursor': snapshotCursor,
          'pending_ack_cursor': snapshotCursor,
          'initialization_status': 'ready',
        },
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, where: 'id = 1');
      await _setApplyingRemote(transaction, false);
    });
  }

  Future<void> applyChangePage(
    List<SyncChangeModel> changes, {
    required int nextCursor,
    required bool bootstrap,
  }) => applyPullPage(changes, nextCursor: nextCursor);

  Future<void> _applyRemoteRecord(
    Transaction transaction, {
    int? sequence,
    required String entityType,
    required String entityId,
    required String operation,
    required int version,
    String? originDeviceId,
    required Map<String, Object?> payload,
    required String changedAt,
  }) async {
    if (sequence != null && sequence > 0) {
      final applied = await transaction.query(
        'sync_inbox',
        columns: const ['status'],
        where: 'server_sequence = ?',
        whereArgs: [sequence],
        limit: 1,
      );
      if (applied.isNotEmpty && applied.single['status'] == 'applied') return;
      await transaction.insert('sync_inbox', {
        'server_sequence': sequence,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'server_version': version,
        'origin_device_id': originDeviceId,
        'payload_json': jsonEncode(payload),
        'changed_at': changedAt,
        'status': 'pending',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final localEvents = await transaction.query(
      'sync_queue',
      where:
          'entidad = ? AND entidad_id = ? '
          "AND estado IN ('pending', 'retry', 'sending')",
      whereArgs: [entityType, entityId],
      orderBy: 'creado_en DESC',
      limit: 1,
    );
    if (localEvents.isNotEmpty) {
      final localEvent = localEvents.single;
      final localPayload = await _registry.exportEntity(
        transaction,
        entityType: entityType,
        entityId: entityId,
        operation: (localEvent['accion'] as String).toUpperCase(),
      );
      final localConflictId = sequence == null
          ? 'bootstrap:$entityType:$entityId:$version'
          : 'pull:$sequence';
      await transaction.insert('sync_conflicts_local', {
        'id': localConflictId,
        'event_id': localEvent['id'],
        'entity_type': entityType,
        'entity_id': entityId,
        'local_base_version': (localEvent['base_version'] as num? ?? 0).toInt(),
        'server_version': version,
        'local_payload_json': jsonEncode(localPayload),
        'server_payload_json': jsonEncode(payload),
        'status': 'pending',
        'message': 'Existe un cambio local pendiente para esta entidad.',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      if (sequence != null && sequence > 0) {
        await transaction.update(
          'sync_inbox',
          {'status': 'conflict'},
          where: 'server_sequence = ?',
          whereArgs: [sequence],
        );
      }
      return;
    }

    try {
      await _registry.applyRemote(
        transaction,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
      );
    } catch (error) {
      throw StateError(
        'Error aplicando $entityType/$entityId '
        '($operation, version $version): $error',
      );
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await transaction.insert('sync_entity_state', {
      'entity_type': entityType,
      'entity_id': entityId,
      'server_version': version,
      'sync_status': 'synced',
      'last_synced_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await transaction.update(
      'sync_conflicts_local',
      {'status': 'resolved', 'resolved_at': now},
      where: "entity_type = ? AND entity_id = ? AND status = 'pending'",
      whereArgs: [entityType, entityId],
    );
    await transaction.update(
      'sync_queue',
      {'estado': 'resolved', 'server_version': version, 'actualizado_en': now},
      where: "entidad = ? AND entidad_id = ? AND estado = 'conflict'",
      whereArgs: [entityType, entityId],
    );
    await _scheduleRemoteFiles(transaction, entityType, entityId, payload);
    if (sequence != null && sequence > 0) {
      await transaction.update(
        'sync_inbox',
        {'status': 'applied', 'applied_at': now},
        where: 'server_sequence = ?',
        whereArgs: [sequence],
      );
    }
  }

  Future<void> setInitializationStatus(String status) async {
    final database = await _database;
    await database.update('sync_state', {
      'initialization_status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = 1');
  }

  Future<String> readInitializationStatus() async {
    final database = await _database;
    final rows = await database.query(
      'sync_state',
      columns: const ['initialization_status'],
      where: 'id = 1',
      limit: 1,
    );
    return rows.single['initialization_status'] as String? ?? 'pending';
  }

  Future<bool> hasBusinessData() async {
    final database = await _database;
    final pendingEvents =
        Sqflite.firstIntValue(
          await database.rawQuery(
            "SELECT COUNT(*) FROM sync_queue "
            "WHERE estado IN ('pending', 'retry', 'sending', 'conflict')",
          ),
        ) ??
        0;
    if (pendingEvents > 0) return true;
    final userProducts =
        Sqflite.firstIntValue(
          await database.rawQuery(
            "SELECT COUNT(*) FROM productos WHERE id NOT LIKE 'demo-%'",
          ),
        ) ??
        0;
    if (userProducts > 0) return true;
    for (final table in const [
      'clientes',
      'pedidos',
      'cotizaciones',
      'preparacion_productos',
      'pedido_cargas',
    ]) {
      final count =
          Sqflite.firstIntValue(
            await database.rawQuery('SELECT COUNT(*) FROM $table'),
          ) ??
          0;
      if (count > 0) return true;
    }
    return false;
  }

  Future<void> prepareServerInitialSource() async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.delete(
        'sync_queue',
        where:
            "estado IN ('pending', 'retry', 'sending', 'conflict', 'failed')",
      );
      await transaction.delete('sync_conflicts_local');
      await transaction.update('sync_state', {
        'initialization_status': 'server',
        'bootstrap_completed': 0,
        'bootstrap_snapshot_cursor': null,
        'last_pull_cursor': 0,
        'last_ack_cursor': 0,
        'pending_ack_cursor': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, where: 'id = 1');
    });
  }

  Future<void> createInitialSnapshot() async {
    final database = await _database;
    await database.transaction((transaction) async {
      final state = (await transaction.query(
        'sync_state',
        columns: const ['initialization_status', 'initial_snapshot_created'],
        where: 'id = 1',
        limit: 1,
      )).single;
      if (state['initialization_status'] != 'tablet') {
        throw StateError(
          'La instantanea inicial solo puede crearla la tablet elegida.',
        );
      }
      if ((state['initial_snapshot_created'] as num? ?? 0).toInt() == 1) {
        return;
      }
      final now = DateTime.now().toUtc().toIso8601String();
      for (final entityType in SyncEntityRegistry.initialSnapshotOrder) {
        final ids = await _registry.listEntityIdentities(
          transaction,
          entityType,
        );
        for (final entityId in ids) {
          await transaction.delete(
            'sync_queue',
            where:
                'entidad = ? AND entidad_id = ? '
                "AND estado IN ('pending', 'retry')",
            whereArgs: [entityType, entityId],
          );
          await transaction.insert('sync_queue', {
            'id': const Uuid().v4(),
            'entidad': entityType,
            'entidad_id': entityId,
            'accion': 'UPSERT',
            'payload_json': '{}',
            'estado': 'pending',
            'intentos': 0,
            'creado_en': now,
            'actualizado_en': now,
            'base_version': 0,
            'payload_version': SyncContract.payloadVersion,
            'schema_version': SyncContract.schemaVersion,
          });
        }
      }
      await transaction.update('sync_state', {
        'initial_snapshot_created': 1,
        'bootstrap_completed': 1,
        'initialization_status': 'ready',
        'updated_at': now,
      }, where: 'id = 1');
    });
  }

  Future<void> refreshFileQueue() async {
    final database = await _database;
    await database.transaction((transaction) async {
      final products = await transaction.query(
        'productos',
        columns: const [
          'id',
          'imagen_path',
          'imagenes_json',
          'imagenes_configuradas_json',
          'variantes_json',
        ],
      );
      for (final product in products) {
        final paths = <String>{};
        _collectLocalPaths(product['imagen_path'], paths);
        _collectLocalPaths(_decodeJson(product['imagenes_json']), paths);
        _collectLocalPaths(
          _decodeJson(product['imagenes_configuradas_json']),
          paths,
        );
        _collectLocalPaths(_decodeJson(product['variantes_json']), paths);
        for (final path in paths) {
          await _queueLocalFile(
            transaction,
            ownerType: 'PRODUCT',
            ownerId: product['id'].toString(),
            path: path,
          );
        }
      }
      for (final spec in const [
        ('clientes', 'CLIENT', 'foto_ubicacion_path'),
        ('cotizaciones', 'QUOTE', 'pdf_path'),
      ]) {
        final rows = await transaction.query(spec.$1, columns: ['id', spec.$3]);
        for (final row in rows) {
          final path = row[spec.$3]?.toString() ?? '';
          if (path.trim().isEmpty) continue;
          await _queueLocalFile(
            transaction,
            ownerType: spec.$2,
            ownerId: row['id'].toString(),
            path: path,
          );
        }
      }
    });
  }

  Future<List<SyncFileQueueItem>> readPendingUploads({int limit = 20}) async {
    final database = await _database;
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await database.query(
      'sync_file_queue',
      where:
          "UPPER(direction) = 'UPLOAD' "
          "AND status IN ('pending', 'retry') "
          'AND (next_retry_at IS NULL OR next_retry_at <= ?)',
      whereArgs: [now],
      orderBy: 'created_at',
      limit: limit,
    );
    return rows.map(_fileItem).toList();
  }

  Future<List<SyncFileQueueItem>> readPendingDownloads({int limit = 20}) async {
    final database = await _database;
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await database.query(
      'sync_file_queue',
      where:
          "UPPER(direction) = 'DOWNLOAD' "
          "AND status IN ('download_pending', 'retry') "
          'AND (next_retry_at IS NULL OR next_retry_at <= ?)',
      whereArgs: [now],
      orderBy: 'created_at',
      limit: limit,
    );
    return rows.map(_fileItem).toList();
  }

  Future<void> markFileUploading(
    String id, {
    required String checksum,
    required int sizeBytes,
    required String contentType,
    required String fileName,
  }) async {
    final database = await _database;
    await database.update(
      'sync_file_queue',
      {
        'status': 'uploading',
        'checksum': checksum,
        'size_bytes': sizeBytes,
        'content_type': contentType,
        'file_name': fileName,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFileReady(
    String id, {
    required String backendFileId,
    required String storageKey,
    required String downloadUrl,
  }) async {
    final database = await _database;
    await database.update(
      'sync_file_queue',
      {
        'status': 'ready',
        'backend_file_id': backendFileId,
        'object_key': storageKey,
        'download_url': downloadUrl,
        'next_retry_at': null,
        'last_error': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFileDownloading(String id) async {
    final database = await _database;
    await database.update(
      'sync_file_queue',
      {
        'status': 'downloading',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFileDownloaded(String id, String localPath) async {
    final database = await _database;
    await database.transaction((transaction) async {
      final rows = await transaction.query(
        'sync_file_queue',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final row = rows.single;
      await _setApplyingRemote(transaction, true);
      final ownerType = row['owner_type'] as String;
      final ownerId = row['owner_id'] as String;
      switch (ownerType) {
        case 'PRODUCT':
          final products = await transaction.query(
            'productos',
            columns: const ['imagen_path', 'imagenes_json'],
            where: 'id = ?',
            whereArgs: [ownerId],
            limit: 1,
          );
          if (products.isNotEmpty) {
            final paths = _decodeJson(products.single['imagenes_json']);
            final images = paths is List
                ? paths.map((value) => value.toString()).toList()
                : <String>[];
            if (!images.contains(localPath)) images.add(localPath);
            await transaction.update(
              'productos',
              {
                if ((products.single['imagen_path']?.toString() ?? '').isEmpty)
                  'imagen_path': localPath,
                'imagenes_json': jsonEncode(images),
              },
              where: 'id = ?',
              whereArgs: [ownerId],
            );
          }
        case 'CLIENT':
          await transaction.update(
            'clientes',
            {'foto_ubicacion_path': localPath},
            where: 'id = ?',
            whereArgs: [ownerId],
          );
        case 'QUOTE':
          await transaction.update(
            'cotizaciones',
            {'pdf_path': localPath},
            where: 'id = ?',
            whereArgs: [ownerId],
          );
      }
      await transaction.update(
        'sync_file_queue',
        {
          'local_path': localPath,
          'status': 'downloaded',
          'next_retry_at': null,
          'last_error': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await _setApplyingRemote(transaction, false);
    });
  }

  Future<void> markFileRetry(String id, String errorCode) async {
    final database = await _database;
    final rows = await database.query(
      'sync_file_queue',
      columns: const ['attempts'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final attempts = (rows.single['attempts'] as num? ?? 0).toInt() + 1;
    final seconds = math.min(300, 5 * math.pow(2, attempts - 1).toInt());
    await database.update(
      'sync_file_queue',
      {
        'status': 'retry',
        'attempts': attempts,
        'next_retry_at': DateTime.now()
            .toUtc()
            .add(Duration(seconds: seconds))
            .toIso8601String(),
        'last_error': errorCode,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSyncAttempt({required bool success}) async {
    final database = await _database;
    final now = DateTime.now().toUtc().toIso8601String();
    await database.update('sync_state', {
      'last_attempt_at': now,
      if (success) 'last_success_at': now,
      'updated_at': now,
    }, where: 'id = 1');
  }

  Future<void> _queueLocalFile(
    Transaction transaction, {
    required String ownerType,
    required String ownerId,
    required String path,
  }) async {
    final existing = await transaction.query(
      'sync_file_queue',
      columns: const ['id'],
      where:
          "owner_type = ? AND owner_id = ? AND local_path = ? "
          "AND UPPER(direction) = 'UPLOAD'",
      whereArgs: [ownerType, ownerId, path],
      limit: 1,
    );
    if (existing.isNotEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    await transaction.insert('sync_file_queue', {
      'id': const Uuid().v4(),
      'owner_type': ownerType,
      'owner_id': ownerId,
      'local_path': path,
      'direction': 'UPLOAD',
      'status': 'pending',
      'attempts': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _scheduleRemoteFiles(
    Transaction transaction,
    String ownerType,
    String ownerId,
    Map<String, Object?> payload,
  ) async {
    final storageKeys = <String>{};
    _collectStorageKeys(payload, storageKeys);
    final now = DateTime.now().toUtc().toIso8601String();
    for (final storageKey in storageKeys) {
      await transaction.insert('sync_file_queue', {
        'id': 'download:$ownerType:$ownerId:$storageKey',
        'owner_type': ownerType,
        'owner_id': ownerId,
        'local_path': '',
        'object_key': storageKey,
        'direction': 'DOWNLOAD',
        'status': 'download_pending',
        'attempts': 0,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  SyncFileQueueItem _fileItem(Map<String, Object?> row) => SyncFileQueueItem(
    id: row['id'] as String,
    ownerType: row['owner_type'] as String,
    ownerId: row['owner_id'] as String,
    localPath: row['local_path'] as String,
    direction: row['direction'] as String? ?? 'UPLOAD',
    storageKey: row['object_key'] as String?,
    contentType: row['content_type'] as String?,
  );

  Future<void> _markRetry(
    DatabaseExecutor database,
    String eventId,
    String errorCode,
  ) async {
    final rows = await database.query(
      'sync_queue',
      columns: const ['intentos'],
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final attempts = (rows.single['intentos'] as num? ?? 0).toInt() + 1;
    final seconds = math.min(300, 5 * math.pow(2, attempts - 1).toInt());
    await database.update(
      'sync_queue',
      {
        'estado': 'retry',
        'intentos': attempts,
        'next_retry_at': DateTime.now()
            .toUtc()
            .add(Duration(seconds: seconds))
            .toIso8601String(),
        'last_error_code': errorCode,
        'actualizado_en': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  Future<void> _markLegacySynced(
    DatabaseExecutor database,
    SyncEventModel event,
  ) async {
    final table = switch (event.entityType) {
      'ORDER' => 'pedidos',
      'ORDER_SHEET' => 'hojas_pedido',
      _ => null,
    };
    if (table == null) return;
    final columns = await database.rawQuery('PRAGMA table_info($table)');
    if (!columns.any((column) => column['name'] == 'sincronizado')) return;
    await database.update(
      table,
      const {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [event.entityId],
    );
  }

  Future<int> _readStateValue(DatabaseExecutor database, String column) async {
    return Sqflite.firstIntValue(
          await database.rawQuery('SELECT $column FROM sync_state WHERE id=1'),
        ) ??
        0;
  }

  Future<int?> _readNullableStateValue(
    DatabaseExecutor database,
    String column,
  ) async {
    final row = (await database.rawQuery(
      'SELECT $column FROM sync_state WHERE id=1',
    )).single;
    return (row[column] as num?)?.toInt();
  }

  Future<void> _setApplyingRemote(DatabaseExecutor database, bool value) =>
      database.update('sync_runtime_context', {
        'applying_remote': value ? 1 : 0,
      }, where: 'id = 1');

  Object? _decodeJson(Object? value) {
    if (value is! String || value.trim().isEmpty) return value;
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  void _collectLocalPaths(Object? value, Set<String> paths) {
    if (value is String) {
      if (value.trim().isNotEmpty && !value.startsWith('files/')) {
        paths.add(value);
      }
      return;
    }
    if (value is List) {
      for (final item in value) {
        _collectLocalPaths(item, paths);
      }
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase();
        if (key.contains('path') || key.contains('image')) {
          _collectLocalPaths(entry.value, paths);
        }
      }
    }
  }

  void _collectStorageKeys(Object? value, Set<String> storageKeys) {
    if (value is List) {
      for (final item in value) {
        _collectStorageKeys(item, storageKeys);
      }
      return;
    }
    if (value is! Map) return;
    for (final entry in value.entries) {
      if (entry.key.toString().toLowerCase() == 'storagekey') {
        final storageKey = entry.value?.toString() ?? '';
        if (storageKey.startsWith('files/')) storageKeys.add(storageKey);
      } else {
        _collectStorageKeys(entry.value, storageKeys);
      }
    }
  }
}
