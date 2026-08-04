import 'dart:async';

import 'package:app_catalogo/features/sync/domain/entities/sync_configuration.dart';
import 'package:app_catalogo/features/sync/domain/entities/sync_pairing_payload.dart';
import 'package:app_catalogo/features/sync/domain/entities/sync_status.dart';
import 'package:app_catalogo/features/sync/domain/repositories/sync_repository.dart';
import 'package:app_catalogo/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:app_catalogo/features/sync/presentation/bloc/sync_event.dart';
import 'package:app_catalogo/features/sync/presentation/bloc/sync_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vincula manualmente y conserva un estado operativo', () async {
    final repository = _SyncRepositoryFake();
    final bloc = SyncBloc(
      repository,
      connectivityChanges: const Stream.empty(),
    );
    addTearDown(bloc.close);

    bloc.add(const SyncStarted());
    await bloc.stream.firstWhere((state) => state.phase == SyncPhase.idle);
    bloc.add(
      const SyncManualPairingRequested(
        address: '192.168.1.10:8081',
        pairingCode: '12345678',
        deviceName: 'Tablet 1',
      ),
    );
    final linked = await bloc.stream.firstWhere(
      (state) => state.phase == SyncPhase.idle && state.status.isLinked,
    );

    expect(linked.error, isNull);
    expect(linked.message, 'Tablet vinculada correctamente.');
    expect(repository.lastPayload?.currentUrlHint, 'http://192.168.1.10:8081');
  });

  test('sincroniza automáticamente al recuperar conectividad', () async {
    final connectivity = StreamController<List<ConnectivityResult>>();
    final repository = _SyncRepositoryFake(true);
    final bloc = SyncBloc(repository, connectivityChanges: connectivity.stream);
    addTearDown(() async {
      await bloc.close();
      await connectivity.close();
    });

    bloc.add(const SyncStarted());
    await bloc.stream.firstWhere((state) => state.phase == SyncPhase.idle);
    connectivity.add(const [ConnectivityResult.wifi]);
    await bloc.stream.firstWhere(
      (state) =>
          state.phase == SyncPhase.idle &&
          state.message?.startsWith('Sincronizacion completa') == true,
    );

    expect(repository.syncCalls, 1);
  });
}

class _SyncRepositoryFake implements SyncRepository {
  _SyncRepositoryFake([this._linked = false]);

  bool _linked;
  int syncCalls = 0;
  SyncPairingPayload? lastPayload;

  @override
  Future<List<SyncServerCandidate>> discoverServers() async => const [];

  @override
  Future<SyncStatus> getStatus() async => _linked
      ? const SyncStatus(
          isLinked: true,
          pendingEvents: 1,
          retryEvents: 0,
          conflicts: 0,
          pendingFiles: 0,
          serverName: 'PC principal',
          serverUrl: 'http://192.168.1.10:8081',
        )
      : const SyncStatus.unlinked();

  @override
  Future<SyncConfiguration> pair({
    required SyncPairingPayload payload,
    required String deviceName,
  }) async {
    _linked = true;
    lastPayload = payload;
    return SyncConfiguration(
      serverId: payload.serverId,
      serverName: 'PC principal',
      serviceType: payload.serviceType,
      serverUrlCache: payload.currentUrlHint ?? '',
      deviceId: 'device-1',
      deviceName: deviceName,
      contractVersion: '1.0',
      linkedAt: DateTime(2026, 8, 4),
    );
  }

  @override
  Future<SyncRunResult> synchronize({bool forceBootstrap = false}) async {
    syncCalls++;
    return const SyncRunResult(pushed: 1, pulled: 2, conflicts: 0, pending: 0);
  }

  @override
  Future<void> chooseInitialSource(SyncInitialSource source) async {}

  @override
  Future<void> unlink() async => _linked = false;
}
