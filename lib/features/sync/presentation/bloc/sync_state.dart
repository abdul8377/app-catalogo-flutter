import 'package:equatable/equatable.dart';

import '../../domain/entities/sync_configuration.dart';
import '../../domain/entities/sync_status.dart';

enum SyncPhase { loading, idle, pairing, discovering, synchronizing }

class SyncState extends Equatable {
  const SyncState({
    required this.phase,
    required this.status,
    this.candidates = const [],
    this.error,
    this.message,
  });

  const SyncState.initial()
    : phase = SyncPhase.loading,
      status = const SyncStatus.unlinked(),
      candidates = const [],
      error = null,
      message = null;

  final SyncPhase phase;
  final SyncStatus status;
  final List<SyncServerCandidate> candidates;
  final String? error;
  final String? message;

  bool get isBusy => phase != SyncPhase.idle;

  SyncState copyWith({
    SyncPhase? phase,
    SyncStatus? status,
    List<SyncServerCandidate>? candidates,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) => SyncState(
    phase: phase ?? this.phase,
    status: status ?? this.status,
    candidates: candidates ?? this.candidates,
    error: clearError ? null : error ?? this.error,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [phase, status, candidates, error, message];
}
