class SyncDiscoveryModel {
  const SyncDiscoveryModel({
    required this.serverId,
    required this.serverName,
    required this.serviceType,
    required this.port,
    required this.apiContractVersion,
    required this.pairingAvailable,
  });

  factory SyncDiscoveryModel.fromJson(Map<String, Object?> json) =>
      SyncDiscoveryModel(
        serverId: json['serverId'] as String? ?? '',
        serverName: json['serverName'] as String? ?? '',
        serviceType: json['serviceType'] as String? ?? '',
        port: (json['port'] as num? ?? 0).toInt(),
        apiContractVersion: json['apiContractVersion'] as String? ?? '',
        pairingAvailable: json['pairingAvailable'] as bool? ?? false,
      );

  final String serverId;
  final String serverName;
  final String serviceType;
  final int port;
  final String apiContractVersion;
  final bool pairingAvailable;
}

class SyncServerStatusModel {
  const SyncServerStatusModel({
    required this.serverId,
    required this.apiContractVersion,
    required this.records,
  });

  factory SyncServerStatusModel.fromJson(Map<String, Object?> json) =>
      SyncServerStatusModel(
        serverId: json['serverId'] as String? ?? '',
        apiContractVersion: json['apiContractVersion'] as String? ?? '',
        records: (json['records'] as num? ?? 0).toInt(),
      );

  final String serverId;
  final String apiContractVersion;
  final int records;
}
