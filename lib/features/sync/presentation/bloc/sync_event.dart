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
  const SyncRequested({this.forceBootstrap = false, this.automatic = false});

  final bool forceBootstrap;
  final bool automatic;

  @override
  List<Object?> get props => [forceBootstrap, automatic];
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
    required this.pairingCode,
    required this.deviceName,
  });

  final String address;
  final String pairingCode;
  final String deviceName;

  @override
  List<Object?> get props => [address, pairingCode, deviceName];
}

class SyncDiscoveryRequested extends SyncEvent {
  const SyncDiscoveryRequested();
}

class SyncCandidatePairingRequested extends SyncEvent {
  const SyncCandidatePairingRequested({
    required this.address,
    required this.serverId,
    required this.serverName,
    required this.pairingCode,
    required this.deviceName,
  });

  final String address;
  final String serverId;
  final String serverName;
  final String pairingCode;
  final String deviceName;

  @override
  List<Object?> get props => [
    address,
    serverId,
    serverName,
    pairingCode,
    deviceName,
  ];
}

class SyncInitialSourceSelected extends SyncEvent {
  const SyncInitialSourceSelected(this.source);

  final String source;

  @override
  List<Object?> get props => [source];
}

class SyncUnlinkRequested extends SyncEvent {
  const SyncUnlinkRequested();
}

class SyncConnectivityRestored extends SyncEvent {
  const SyncConnectivityRestored();
}
