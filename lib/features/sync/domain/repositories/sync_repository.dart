import '../entities/sync_configuration.dart';
import '../entities/sync_pairing_payload.dart';
import '../entities/sync_status.dart';

abstract interface class SyncRepository {
  Future<SyncStatus> getStatus();

  Future<SyncConfiguration> pair({
    required SyncPairingPayload payload,
    required String deviceName,
  });

  Future<List<SyncServerCandidate>> discoverServers();

  Future<SyncRunResult> synchronize({bool forceBootstrap = false});

  Future<void> unlink();
}
