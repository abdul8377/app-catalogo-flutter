import 'package:equatable/equatable.dart';

class SyncStatus extends Equatable {
  const SyncStatus({
    required this.isLinked,
    required this.pendingEvents,
    required this.retryEvents,
    required this.conflicts,
    required this.pendingFiles,
    this.serverName = '',
    this.serverUrl = '',
    this.lastSuccessAt,
  });

  const SyncStatus.unlinked()
    : isLinked = false,
      pendingEvents = 0,
      retryEvents = 0,
      conflicts = 0,
      pendingFiles = 0,
      serverName = '',
      serverUrl = '',
      lastSuccessAt = null;

  final bool isLinked;
  final int pendingEvents;
  final int retryEvents;
  final int conflicts;
  final int pendingFiles;
  final String serverName;
  final String serverUrl;
  final DateTime? lastSuccessAt;

  int get totalPending => pendingEvents + retryEvents + pendingFiles;

  @override
  List<Object?> get props => [
    isLinked,
    pendingEvents,
    retryEvents,
    conflicts,
    pendingFiles,
    serverName,
    serverUrl,
    lastSuccessAt,
  ];
}

class SyncRunResult extends Equatable {
  const SyncRunResult({
    required this.pushed,
    required this.pulled,
    required this.conflicts,
    required this.pending,
  });

  final int pushed;
  final int pulled;
  final int conflicts;
  final int pending;

  @override
  List<Object?> get props => [pushed, pulled, conflicts, pending];
}
