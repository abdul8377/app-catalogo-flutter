class SyncBootstrapRecordModel {
  const SyncBootstrapRecordModel({
    required this.entityType,
    required this.entityId,
    required this.version,
    required this.deleted,
    required this.payload,
    required this.updatedAt,
  });

  factory SyncBootstrapRecordModel.fromJson(Map<String, Object?> json) {
    final rawPayload = json['payload'];
    return SyncBootstrapRecordModel(
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      version: (json['version'] as num? ?? 0).toInt(),
      deleted: json['deleted'] as bool? ?? false,
      payload: rawPayload is Map
          ? Map<String, Object?>.from(rawPayload)
          : const {},
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  final String entityType;
  final String entityId;
  final int version;
  final bool deleted;
  final Map<String, Object?> payload;
  final String updatedAt;
}

class SyncBootstrapPageModel {
  const SyncBootstrapPageModel({
    required this.page,
    required this.nextPage,
    required this.hasMore,
    required this.snapshotCursor,
    required this.records,
  });

  factory SyncBootstrapPageModel.fromJson(Map<String, Object?> json) {
    final rawRecords = json['records'] as List? ?? const [];
    return SyncBootstrapPageModel(
      page: (json['page'] as num? ?? 0).toInt(),
      nextPage: (json['nextPage'] as num? ?? 0).toInt(),
      hasMore: json['hasMore'] as bool? ?? false,
      snapshotCursor: (json['snapshotCursor'] as num? ?? 0).toInt(),
      records: rawRecords
          .whereType<Map>()
          .map(
            (value) => SyncBootstrapRecordModel.fromJson(
              Map<String, Object?>.from(value),
            ),
          )
          .toList(),
    );
  }

  final int page;
  final int nextPage;
  final bool hasMore;
  final int snapshotCursor;
  final List<SyncBootstrapRecordModel> records;
}
