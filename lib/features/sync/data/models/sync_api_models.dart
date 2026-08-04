class SyncEventModel {
  const SyncEventModel({
    required this.eventId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.baseVersion,
    required this.occurredAt,
    required this.payload,
  });

  final String eventId;
  final String entityType;
  final String entityId;
  final String operation;
  final int baseVersion;
  final String occurredAt;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'eventId': eventId,
    'entityType': entityType,
    'entityId': entityId,
    'operation': operation,
    'baseVersion': baseVersion,
    'occurredAt': occurredAt,
    'payload': payload,
  };
}

class SyncPushResultModel {
  const SyncPushResultModel({
    required this.eventId,
    required this.status,
    this.serverVersion,
    this.serverSequence,
    this.message,
  });

  factory SyncPushResultModel.fromJson(Map<String, Object?> json) =>
      SyncPushResultModel(
        eventId: json['eventId'] as String? ?? '',
        status: (json['status'] as String? ?? 'REJECTED').toUpperCase(),
        serverVersion: (json['serverVersion'] as num?)?.toInt(),
        serverSequence: (json['serverSequence'] as num?)?.toInt(),
        message: json['message'] as String?,
      );

  final String eventId;
  final String status;
  final int? serverVersion;
  final int? serverSequence;
  final String? message;
}

class SyncChangeModel {
  const SyncChangeModel({
    required this.serverSequence,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.serverVersion,
    required this.changedAt,
    required this.payload,
    this.originDeviceId,
  });

  factory SyncChangeModel.fromJson(Map<String, Object?> json) {
    final rawPayload = json['payload'];
    return SyncChangeModel(
      serverSequence: (json['serverSequence'] as num? ?? 0).toInt(),
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      operation: (json['operation'] as String? ?? 'UPSERT').toUpperCase(),
      serverVersion: (json['serverVersion'] as num? ?? 0).toInt(),
      changedAt:
          json['changedAt'] as String? ??
          DateTime.now().toUtc().toIso8601String(),
      originDeviceId: json['originDeviceId'] as String?,
      payload: rawPayload is Map
          ? Map<String, Object?>.from(rawPayload)
          : const {},
    );
  }

  final int serverSequence;
  final String entityType;
  final String entityId;
  final String operation;
  final int serverVersion;
  final String changedAt;
  final String? originDeviceId;
  final Map<String, Object?> payload;
}

class SyncChangePageModel {
  const SyncChangePageModel({
    required this.changes,
    required this.nextCursor,
    required this.hasMore,
  });

  factory SyncChangePageModel.fromJson(Map<String, Object?> json) {
    final rawChanges = (json['changes'] ?? json['items']) as List? ?? const [];
    return SyncChangePageModel(
      changes: rawChanges
          .whereType<Map>()
          .map(
            (value) =>
                SyncChangeModel.fromJson(Map<String, Object?>.from(value)),
          )
          .toList(),
      nextCursor: (json['nextCursor'] as num? ?? 0).toInt(),
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  final List<SyncChangeModel> changes;
  final int nextCursor;
  final bool hasMore;
}
