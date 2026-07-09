class SyncQueueService {
  Future<void> enqueue({
    required String entity,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    // Guardara eventos pendientes en SQLite para sincronizarlos despues.
  }
}
