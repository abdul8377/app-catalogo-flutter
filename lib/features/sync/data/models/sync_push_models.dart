class SyncEventModel {
  const SyncEventModel({
    required this.eventId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.baseVersion,
    required this.payloadVersion,
    required this.schemaVersion,
    required this.occurredAt,
    required this.payload,
    this.checksum,
  });

  final String eventId;
  final String entityType;
  final String entityId;
  final String operation;
  final int baseVersion;
  final int payloadVersion;
  final String schemaVersion;
  final String? checksum;
  final String occurredAt;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'eventId': eventId,
    'entityType': entityType,
    'entityId': entityId,
    'operation': operation,
    'baseVersion': baseVersion,
    'payloadVersion': payloadVersion,
    'schemaVersion': schemaVersion,
    'checksum': checksum,
    'occurredAt': occurredAt,
    'payload': payload,
  };
}

class SyncPushRequestModel {
  const SyncPushRequestModel({
    required this.deviceId,
    required this.apiContractVersion,
    required this.events,
  });

  final String deviceId;
  final String apiContractVersion;
  final List<SyncEventModel> events;

  Map<String, Object?> toJson() => {
    'deviceId': deviceId,
    'apiContractVersion': apiContractVersion,
    'events': events.map((event) => event.toJson()).toList(),
  };
}

class SyncPushResultModel {
  const SyncPushResultModel({
    required this.eventId,
    required this.status,
    this.serverVersion,
    this.serverSequence,
    this.conflictId,
    this.message,
  });

  factory SyncPushResultModel.fromJson(Map<String, Object?> json) =>
      SyncPushResultModel(
        eventId: json['eventId'] as String? ?? '',
        status: (json['status'] as String? ?? 'REJECTED').toUpperCase(),
        serverVersion: (json['serverVersion'] as num?)?.toInt(),
        serverSequence: (json['serverSequence'] as num?)?.toInt(),
        conflictId: json['conflictId'] as String?,
        message: json['message'] as String?,
      );

  final String eventId;
  final String status;
  final int? serverVersion;
  final int? serverSequence;
  final String? conflictId;
  final String? message;
}
