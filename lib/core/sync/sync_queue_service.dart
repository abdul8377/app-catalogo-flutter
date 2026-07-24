import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

class SyncQueueService {
  SyncQueueService([AppDatabase? database])
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> enqueue({
    required String entity,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now().toIso8601String();
    final entityId = payload['id']?.toString() ?? '';
    await (await _database.database).insert('sync_queue', {
      'id': const Uuid().v4(),
      'entidad': entity,
      'entidad_id': entityId,
      'accion': action,
      'payload_json': jsonEncode(payload),
      'estado': 'pendiente',
      'intentos': 0,
      'creado_en': now,
      'actualizado_en': now,
    });
  }
}
