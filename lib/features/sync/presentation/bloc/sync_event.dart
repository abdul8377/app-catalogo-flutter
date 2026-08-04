import 'package:equatable/equatable.dart';

sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class SyncStarted extends SyncEvent {
  const SyncStarted();
}

class SyncRequested extends SyncEvent {
  const SyncRequested({this.forceBootstrap = false});

  final bool forceBootstrap;

  @override
  List<Object?> get props => [forceBootstrap];
}

class SyncQrPairingRequested extends SyncEvent {
  const SyncQrPairingRequested({required this.rawQr, required this.deviceName});

  final String rawQr;
  final String deviceName;

  @override
  List<Object?> get props => [rawQr, deviceName];
}

class SyncManualPairingRequested extends SyncEvent {
  const SyncManualPairingRequested({
    required this.address,
    required this.deviceName,
  });

  final String address;
  final String deviceName;

  @override
  List<Object?> get props => [address, deviceName];
}

class SyncDiscoveryRequested extends SyncEvent {
  const SyncDiscoveryRequested();
}

class SyncCandidatePairingRequested extends SyncEvent {
  const SyncCandidatePairingRequested({
    required this.address,
    required this.serverId,
    required this.serverName,
    required this.deviceName,
  });

  final String address;
  final String serverId;
  final String serverName;
  final String deviceName;

  @override
  List<Object?> get props => [address, serverId, serverName, deviceName];
}

class SyncUnlinkRequested extends SyncEvent {
  const SyncUnlinkRequested();
}

class SyncConnectivityRestored extends SyncEvent {
  const SyncConnectivityRestored();
}
