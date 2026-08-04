class SyncChangeModel {
  const SyncChangeModel({
    required this.sequence,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.version,
    required this.changedAt,
    required this.payload,
    this.originDeviceId,
  });

  factory SyncChangeModel.fromJson(Map<String, Object?> json) {
    final rawPayload = json['payload'];
    return SyncChangeModel(
      sequence: (json['sequence'] as num? ?? 0).toInt(),
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      operation: (json['operation'] as String? ?? 'UPSERT').toUpperCase(),
      version: (json['version'] as num? ?? 0).toInt(),
      changedAt: json['changedAt'] as String? ?? '',
      originDeviceId: json['originDeviceId'] as String?,
      payload: rawPayload is Map
          ? Map<String, Object?>.from(rawPayload)
          : const {},
    );
  }

  final int sequence;
  final String entityType;
  final String entityId;
  final String operation;
  final int version;
  final String changedAt;
  final String? originDeviceId;
  final Map<String, Object?> payload;
}

class SyncPullPageModel {
  const SyncPullPageModel({
    required this.changes,
    required this.nextCursor,
    required this.hasMore,
  });

  factory SyncPullPageModel.fromJson(Map<String, Object?> json) {
    final rawChanges = json['changes'] as List? ?? const [];
    return SyncPullPageModel(
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

class SyncPullAckModel {
  const SyncPullAckModel({
    required this.acknowledgedCursor,
    required this.acknowledgedAt,
  });

  factory SyncPullAckModel.fromJson(Map<String, Object?> json) =>
      SyncPullAckModel(
        acknowledgedCursor: (json['acknowledgedCursor'] as num? ?? 0).toInt(),
        acknowledgedAt: json['acknowledgedAt'] as String? ?? '',
      );

  final int acknowledgedCursor;
  final String acknowledgedAt;
}
