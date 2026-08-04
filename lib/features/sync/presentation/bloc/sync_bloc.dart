import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/entities/sync_pairing_payload.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/sync_repository.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc(
    this._repository, {
    Stream<List<ConnectivityResult>>? connectivityChanges,
  }) : _connectivityChanges =
           connectivityChanges ?? Connectivity().onConnectivityChanged,
       super(const SyncState.initial()) {
    on<SyncStarted>(_start);
    on<SyncRequested>(_synchronize);
    on<SyncQrPairingRequested>(_pairQr);
    on<SyncManualPairingRequested>(_pairManual);
    on<SyncCandidatePairingRequested>(_pairCandidate);
    on<SyncDiscoveryRequested>(_discover);
    on<SyncUnlinkRequested>(_unlink);
    on<SyncConnectivityRestored>(_connectivityRestored);
  }

  final SyncRepository _repository;
  final Stream<List<ConnectivityResult>> _connectivityChanges;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Future<void> _start(SyncStarted event, Emitter<SyncState> emit) async {
    final status = await _repository.getStatus();
    emit(state.copyWith(phase: SyncPhase.idle, status: status));
    _connectivitySubscription ??= _connectivityChanges.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        add(const SyncConnectivityRestored());
      }
    });
  }

  Future<void> _synchronize(
    SyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    if (!state.status.isLinked || state.phase == SyncPhase.synchronizing) {
      return;
    }
    emit(
      state.copyWith(
        phase: SyncPhase.synchronizing,
        clearError: true,
        clearMessage: true,
      ),
    );
    try {
      final result = await _repository.synchronize(
        forceBootstrap: event.forceBootstrap,
      );
      final status = await _repository.getStatus();
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          status: status,
          message:
              'Sincronización completa: ${result.pushed} enviados y '
              '${result.pulled} recibidos.',
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          status: await _repository.getStatus(),
          error: _message(error),
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _pairQr(
    SyncQrPairingRequested event,
    Emitter<SyncState> emit,
  ) async {
    try {
      await _pair(
        SyncPairingPayload.fromQr(event.rawQr),
        event.deviceName,
        emit,
      );
    } catch (error) {
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          error: _message(error),
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _pairManual(
    SyncManualPairingRequested event,
    Emitter<SyncState> emit,
  ) async {
    final payload = SyncPairingPayload.manual(event.address);
    if (payload.currentUrlHint.isEmpty) {
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          error: 'Escribe una dirección válida, por ejemplo 192.168.1.20:8080.',
        ),
      );
      return;
    }
    await _pair(payload, event.deviceName, emit);
  }

  Future<void> _pairCandidate(
    SyncCandidatePairingRequested event,
    Emitter<SyncState> emit,
  ) => _pair(
    SyncPairingPayload(
      serverId: event.serverId.isEmpty
          ? 'mdns:${event.address}'
          : event.serverId,
      pairingCode: 'mdns',
      currentUrlHint: event.address,
      serverName: event.serverName,
    ),
    event.deviceName,
    emit,
  );

  Future<void> _pair(
    SyncPairingPayload payload,
    String deviceName,
    Emitter<SyncState> emit,
  ) async {
    emit(
      state.copyWith(
        phase: SyncPhase.pairing,
        clearError: true,
        clearMessage: true,
      ),
    );
    try {
      await _repository.pair(payload: payload, deviceName: deviceName);
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          status: await _repository.getStatus(),
          message: 'Tablet vinculada correctamente.',
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          error: _message(error),
          clearMessage: true,
        ),
      );
    }
  }

  Future<void> _discover(
    SyncDiscoveryRequested event,
    Emitter<SyncState> emit,
  ) async {
    emit(
      state.copyWith(
        phase: SyncPhase.discovering,
        candidates: const [],
        clearError: true,
        clearMessage: true,
      ),
    );
    final candidates = await _repository.discoverServers();
    emit(
      state.copyWith(
        phase: SyncPhase.idle,
        candidates: candidates,
        message: candidates.isEmpty
            ? 'No se encontraron PCs compatibles en esta red.'
            : '${candidates.length} servidor(es) encontrado(s).',
      ),
    );
  }

  Future<void> _unlink(
    SyncUnlinkRequested event,
    Emitter<SyncState> emit,
  ) async {
    await _repository.unlink();
    emit(
      state.copyWith(
        phase: SyncPhase.idle,
        status: const SyncStatus.unlinked(),
        candidates: const [],
        message:
            'La tablet fue desvinculada. Los datos locales se conservaron.',
        clearError: true,
      ),
    );
  }

  Future<void> _connectivityRestored(
    SyncConnectivityRestored event,
    Emitter<SyncState> emit,
  ) async {
    if (state.status.isLinked && state.phase == SyncPhase.idle) {
      add(const SyncRequested());
    }
  }

  String _message(Object error) => switch (error) {
    SyncException() => error.message,
    FormatException() => error.message,
    _ => 'No se pudo completar la operación de sincronización.',
  };

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    return super.close();
  }
}
