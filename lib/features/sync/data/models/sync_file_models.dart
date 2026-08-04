class SyncFileQueueItem {
  const SyncFileQueueItem({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.localPath,
    required this.direction,
    this.storageKey,
    this.contentType,
  });

  final String id;
  final String ownerType;
  final String ownerId;
  final String localPath;
  final String direction;
  final String? storageKey;
  final String? contentType;
}

class SyncFileIntentModel {
  const SyncFileIntentModel({
    required this.fileId,
    required this.uploadUrl,
    required this.completeUrl,
    required this.status,
  });

  factory SyncFileIntentModel.fromJson(Map<String, Object?> json) =>
      SyncFileIntentModel(
        fileId: json['fileId'] as String? ?? '',
        uploadUrl: json['uploadUrl'] as String? ?? '',
        completeUrl: json['completeUrl'] as String? ?? '',
        status: json['status'] as String? ?? '',
      );

  final String fileId;
  final String uploadUrl;
  final String completeUrl;
  final String status;
}

class SyncStoredFileModel {
  const SyncStoredFileModel({
    required this.fileId,
    required this.storageKey,
    required this.downloadUrl,
    required this.contentType,
    required this.sizeBytes,
    required this.checksumSha256,
    required this.visibility,
    required this.status,
  });

  factory SyncStoredFileModel.fromJson(Map<String, Object?> json) =>
      SyncStoredFileModel(
        fileId: json['fileId'] as String? ?? '',
        storageKey: json['storageKey'] as String? ?? '',
        downloadUrl: json['downloadUrl'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        sizeBytes: (json['sizeBytes'] as num? ?? 0).toInt(),
        checksumSha256: json['checksumSha256'] as String? ?? '',
        visibility: json['visibility'] as String? ?? '',
        status: json['status'] as String? ?? '',
      );

  final String fileId;
  final String storageKey;
  final String downloadUrl;
  final String contentType;
  final int sizeBytes;
  final String checksumSha256;
  final String visibility;
  final String status;
}

class SyncDownloadedFileModel {
  const SyncDownloadedFileModel({
    required this.bytes,
    required this.contentType,
  });

  final List<int> bytes;
  final String contentType;
}
