import 'dart:convert';
import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/sync_configuration.dart';
import '../../domain/entities/sync_status.dart';
import '../mappers/sync_entity_registry.dart';
import '../models/sync_api_models.dart';

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
      contractVersion: (row['contract_version'] as num? ?? 1).toInt(),
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
          'bootstrap_completed': 0,
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
        'bootstrap_completed': 0,
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
        "SELECT COUNT(*) FROM sync_file_queue WHERE status IN ('pending', 'retry')",
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
      if (resetCursor) 'last_pull_cursor': 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = 1');
  }

  Future<List<SyncEventModel>> prepareOutboxBatch({int limit = 100}) async {
    final database = await _database;
    return database.transaction((transaction) async {
      final now = DateTime.now().toUtc().toIso8601String();
      final rows = await transaction.query(
        'sync_queue',
        where:
            "estado IN ('pending', 'retry') AND "
            '(next_retry_at IS NULL OR next_retry_at <= ?)',
        whereArgs: [now],
        orderBy: 'creado_en ASC',
        limit: limit,
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
          await _markRetry(transaction, event.eventId, 'missing_result');
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
                'last_error_code': 'conflict',
              },
              where: 'id = ?',
              whereArgs: [event.eventId],
            );
            await transaction.insert('sync_conflicts_local', {
              'id': const Uuid().v4(),
              'event_id': event.eventId,
              'entity_type': event.entityType,
              'entity_id': event.entityId,
              'local_base_version': event.baseVersion,
              'server_version': result.serverVersion ?? 0,
              'local_payload_json': jsonEncode(event.payload),
              'status': 'pending',
              'message': result.message,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            });
          default:
            await transaction.update(
              'sync_queue',
              {
                'estado': 'failed',
                'error': result.message ?? 'Cambio rechazado por el servidor.',
                'last_error_code': 'rejected',
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

  Future<void> applyChangePage(
    List<SyncChangeModel> changes, {
    required int nextCursor,
    required bool bootstrap,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.update('sync_runtime_context', const {
        'applying_remote': 1,
      }, where: 'id = 1');
      for (final change in changes) {
        if (change.serverSequence > 0) {
          final applied = await transaction.query(
            'sync_inbox',
            columns: const ['status'],
            where: 'server_sequence = ?',
            whereArgs: [change.serverSequence],
            limit: 1,
          );
          if (applied.isNotEmpty && applied.single['status'] == 'applied') {
            continue;
          }
          await transaction.insert('sync_inbox', {
            'server_sequence': change.serverSequence,
            'entity_type': change.entityType,
            'entity_id': change.entityId,
            'operation': change.operation,
            'server_version': change.serverVersion,
            'origin_device_id': change.originDeviceId,
            'payload_json': jsonEncode(change.payload),
            'changed_at': change.changedAt,
            'status': 'pending',
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        final localEvents = await transaction.query(
          'sync_queue',
          where:
              'entidad = ? AND entidad_id = ? '
              "AND estado IN ('pending', 'retry', 'sending')",
          whereArgs: [change.entityType, change.entityId],
          orderBy: 'creado_en DESC',
          limit: 1,
        );
        final hasLocalChanges = localEvents.isNotEmpty;
        if (hasLocalChanges) {
          final localEvent = localEvents.single;
          final localPayload = await _registry.exportEntity(
            transaction,
            entityType: change.entityType,
            entityId: change.entityId,
            operation: (localEvent['accion'] as String).toUpperCase(),
          );
          await transaction.insert('sync_conflicts_local', {
            'id': const Uuid().v4(),
            'entity_type': change.entityType,
            'entity_id': change.entityId,
            'local_base_version': 0,
            'server_version': change.serverVersion,
            'local_payload_json': jsonEncode(localPayload),
            'server_payload_json': jsonEncode(change.payload),
            'status': 'pending',
            'message': 'Existe un cambio local pendiente para esta entidad.',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
          if (change.serverSequence > 0) {
            await transaction.update(
              'sync_inbox',
              {'status': 'conflict'},
              where: 'server_sequence = ?',
              whereArgs: [change.serverSequence],
            );
          }
          continue;
        }

        await _registry.applyRemote(
          transaction,
          entityType: change.entityType,
          entityId: change.entityId,
          operation: change.operation,
          payload: change.payload,
        );
        await transaction.insert('sync_entity_state', {
          'entity_type': change.entityType,
          'entity_id': change.entityId,
          'server_version': change.serverVersion,
          'sync_status': 'synced',
          'last_synced_at': DateTime.now().toUtc().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        if (change.serverSequence > 0) {
          await transaction.update(
            'sync_inbox',
            {
              'status': 'applied',
              'applied_at': DateTime.now().toUtc().toIso8601String(),
            },
            where: 'server_sequence = ?',
            whereArgs: [change.serverSequence],
          );
        }
      }
      await transaction.update('sync_state', {
        'last_pull_cursor': nextCursor,
        if (bootstrap) 'bootstrap_completed': 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, where: 'id = 1');
      await transaction.update('sync_runtime_context', const {
        'applying_remote': 0,
      }, where: 'id = 1');
    });
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

  Future<void> _markRetry(
    DatabaseExecutor database,
    String eventId,
    String errorCode,
  ) async {
    final row = (await database.query(
      'sync_queue',
      columns: const ['intentos'],
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 1,
    )).single;
    final attempts = (row['intentos'] as num? ?? 0).toInt() + 1;
    final seconds = math.min(300, 5 * math.pow(2, attempts - 1).toInt());
    await database.update(
      'sync_queue',
      {
        'estado': 'retry',
        'intentos': attempts,
        'error': 'No se pudo contactar al servidor.',
        'last_error_code': errorCode,
        'next_retry_at': DateTime.now()
            .toUtc()
            .add(Duration(seconds: seconds))
            .toIso8601String(),
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
    if (event.operation == 'DELETE') return;
    final table = switch (event.entityType) {
      'ORDER' => 'pedidos',
      'ORDER_SHEET' => 'hojas_pedido',
      _ => null,
    };
    if (table == null) return;
    await database.update('sync_runtime_context', const {
      'applying_remote': 1,
    }, where: 'id = 1');
    await database.update(
      table,
      const {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [event.entityId],
    );
    await database.update('sync_runtime_context', const {
      'applying_remote': 0,
    }, where: 'id = 1');
  }
}
