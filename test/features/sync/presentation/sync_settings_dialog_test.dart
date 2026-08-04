import 'package:app_catalogo/features/sync/domain/entities/sync_configuration.dart';
import 'package:app_catalogo/features/sync/domain/entities/sync_pairing_payload.dart';
import 'package:app_catalogo/features/sync/domain/entities/sync_status.dart';
import 'package:app_catalogo/features/sync/domain/repositories/sync_repository.dart';
import 'package:app_catalogo/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:app_catalogo/features/sync/presentation/bloc/sync_event.dart';
import 'package:app_catalogo/features/sync/presentation/dialogs/sync_settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('configura dirección manual sin desbordar en tablet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DialogSyncRepositoryFake();
    final bloc = SyncBloc(repository, connectivityChanges: const Stream.empty())
      ..add(const SyncStarted());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: Scaffold(body: SyncSettingsDialog())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escanear QR de la PC'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Dirección temporal de la PC'),
      '192.168.1.50:8080',
    );
    await tester.tap(find.byKey(const ValueKey('sync-pair-manual')));
    await tester.pumpAndSettle();

    expect(find.text('Tablet vinculada'), findsOneWidget);
    expect(repository.address, 'http://192.168.1.50:8080');
    expect(tester.takeException(), isNull);
  });
}

class _DialogSyncRepositoryFake implements SyncRepository {
  bool linked = false;
  String? address;

  @override
  Future<List<SyncServerCandidate>> discoverServers() async => const [];

  @override
  Future<SyncStatus> getStatus() async => linked
      ? SyncStatus(
          isLinked: true,
          pendingEvents: 0,
          retryEvents: 0,
          conflicts: 0,
          pendingFiles: 0,
          serverName: 'PC principal',
          serverUrl: address ?? '',
        )
      : const SyncStatus.unlinked();

  @override
  Future<SyncConfiguration> pair({
    required SyncPairingPayload payload,
    required String deviceName,
  }) async {
    linked = true;
    address = payload.currentUrlHint;
    return SyncConfiguration(
      serverId: payload.serverId,
      serverName: 'PC principal',
      serviceType: payload.serviceType,
      serverUrlCache: payload.currentUrlHint,
      deviceId: 'tablet-1',
      deviceName: deviceName,
      contractVersion: 1,
      linkedAt: DateTime(2026, 8, 4),
    );
  }

  @override
  Future<SyncRunResult> synchronize({bool forceBootstrap = false}) async =>
      const SyncRunResult(pushed: 0, pulled: 0, conflicts: 0, pending: 0);

  @override
  Future<void> unlink() async => linked = false;
}
