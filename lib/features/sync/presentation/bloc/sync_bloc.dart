import 'dart:async';
import 'dart:math' as math;

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
    on<SyncInitialSourceSelected>(_selectInitialSource);
    on<SyncDiscoveryRequested>(_discover);
    on<SyncUnlinkRequested>(_unlink);
    on<SyncConnectivityRestored>(_connectivityRestored);
  }

  final SyncRepository _repository;
  final Stream<List<ConnectivityResult>> _connectivityChanges;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _automaticRetry;
  int _automaticFailures = 0;

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
    if (!state.status.isLinked ||
        state.status.requiresInitialSource ||
        state.phase == SyncPhase.synchronizing) {
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
      _automaticFailures = 0;
      _automaticRetry?.cancel();
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          status: status,
          message:
              'Sincronizacion completa: ${result.pushed} enviados y '
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
      if (event.automatic &&
          error is SyncException &&
          error.code == 'PC_UNAVAILABLE') {
        _scheduleAutomaticRetry();
      }
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
    final payload = SyncPairingPayload.manual(
      address: event.address,
      pairingCode: event.pairingCode,
    );
    if (payload.currentUrlHint?.isEmpty ?? true) {
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          error: 'Escribe una direccion valida, por ejemplo 192.168.1.20:8081.',
        ),
      );
      return;
    }
    if (payload.pairingCode.isEmpty) {
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          error: 'Escribe el codigo de vinculacion mostrado por la PC.',
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
      serverId: event.serverId,
      pairingCode: event.pairingCode,
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
      final status = await _repository.getStatus();
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          status: status,
          message: status.requiresInitialSource
              ? 'Tablet vinculada. Elige ahora la fuente inicial de datos.'
              : 'Tablet vinculada correctamente.',
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

  Future<void> _selectInitialSource(
    SyncInitialSourceSelected event,
    Emitter<SyncState> emit,
  ) async {
    emit(
      state.copyWith(
        phase: SyncPhase.synchronizing,
        clearError: true,
        clearMessage: true,
      ),
    );
    try {
      final source = event.source == 'tablet'
          ? SyncInitialSource.tablet
          : SyncInitialSource.server;
      await _repository.chooseInitialSource(source);
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          status: await _repository.getStatus(),
          message: source == SyncInitialSource.tablet
              ? 'La tablet quedo elegida como fuente inicial.'
              : 'La PC quedo elegida como fuente inicial.',
        ),
      );
      add(SyncRequested(forceBootstrap: source == SyncInitialSource.server));
    } catch (error) {
      emit(
        state.copyWith(
          phase: SyncPhase.idle,
          status: await _repository.getStatus(),
          error: _message(error),
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
    try {
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
    } catch (error) {
      emit(state.copyWith(phase: SyncPhase.idle, error: _message(error)));
    }
  }

  Future<void> _unlink(
    SyncUnlinkRequested event,
    Emitter<SyncState> emit,
  ) async {
    _automaticRetry?.cancel();
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
    if (state.status.isLinked &&
        !state.status.requiresInitialSource &&
        state.phase == SyncPhase.idle) {
      add(const SyncRequested(automatic: true));
    }
  }

  void _scheduleAutomaticRetry() {
    if (_automaticRetry?.isActive == true) return;
    _automaticFailures++;
    final seconds = math.min(300, 5 * math.pow(2, _automaticFailures - 1));
    _automaticRetry = Timer(Duration(seconds: seconds.toInt()), () {
      if (!isClosed && state.status.isLinked && state.phase == SyncPhase.idle) {
        add(const SyncRequested(automatic: true));
      }
    });
  }

  String _message(Object error) => switch (error) {
    SyncException() => error.message,
    FormatException() => error.message,
    _ => 'No se pudo completar la operacion de sincronizacion.',
  };

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    _automaticRetry?.cancel();
    return super.close();
  }
}
