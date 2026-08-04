import 'package:equatable/equatable.dart';

class SyncConfiguration extends Equatable {
  const SyncConfiguration({
    required this.serverId,
    required this.serverName,
    required this.serviceType,
    required this.serverUrlCache,
    required this.deviceId,
    required this.deviceName,
    required this.contractVersion,
    required this.linkedAt,
  });

  final String serverId;
  final String serverName;
  final String serviceType;
  final String serverUrlCache;
  final String deviceId;
  final String deviceName;
  final int contractVersion;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [
    serverId,
    serverName,
    serviceType,
    serverUrlCache,
    deviceId,
    deviceName,
    contractVersion,
    linkedAt,
  ];
}

class SyncServerCandidate extends Equatable {
  const SyncServerCandidate({
    required this.url,
    this.serverId = '',
    this.name = '',
  });

  final String url;
  final String serverId;
  final String name;

  @override
  List<Object?> get props => [url, serverId, name];
}
