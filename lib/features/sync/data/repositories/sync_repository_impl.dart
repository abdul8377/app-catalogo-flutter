import 'package:dio/dio.dart';

import '../../domain/entities/sync_configuration.dart';
import '../../domain/entities/sync_pairing_payload.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_discovery_datasource.dart';
import '../datasources/sync_local_datasource.dart';
import '../datasources/sync_remote_datasource.dart';
import '../datasources/sync_secure_credentials_datasource.dart';
import '../models/sync_api_models.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(
    this._local,
    this._remote,
    this._credentials,
    this._discovery,
  );

  final SyncLocalDatasource _local;
  final SyncRemoteDatasource _remote;
  final SyncSecureCredentialsDatasource _credentials;
  final SyncDiscoveryDatasource _discovery;
  bool _syncing = false;

  @override
  Future<SyncStatus> getStatus() => _local.readStatus();

  @override
  Future<SyncConfiguration> pair({
    required SyncPairingPayload payload,
    required String deviceName,
  }) async {
    if (payload.currentUrlHint.isEmpty) {
      throw const SyncException('La dirección del servidor no es válida.');
    }
    try {
      final registration = await _remote.registerDevice(
        serverUrl: payload.currentUrlHint,
        deviceName: deviceName.trim().isEmpty ? 'Tablet' : deviceName.trim(),
        pairingCode: payload.pairingCode,
      );
      final now = DateTime.now().toUtc();
      final configuration = SyncConfiguration(
        serverId: payload.serverId,
        serverName: payload.serverName.isEmpty
            ? Uri.parse(payload.currentUrlHint).host
            : payload.serverName,
        serviceType: payload.serviceType,
        serverUrlCache: payload.currentUrlHint,
        deviceId: registration.deviceId,
        deviceName: deviceName.trim().isEmpty ? 'Tablet' : deviceName.trim(),
        contractVersion: payload.apiContractVersion,
        linkedAt: now,
      );
      await _credentials.saveDeviceToken(registration.token);
      try {
        await _local.saveConfiguration(configuration);
      } catch (_) {
        await _credentials.clear();
        rethrow;
      }
      return configuration;
    } on DioException catch (error) {
      throw SyncException(_networkMessage(error));
    }
  }

  @override
  Future<List<SyncServerCandidate>> discoverServers() => _discovery.discover();

  @override
  Future<SyncRunResult> synchronize({bool forceBootstrap = false}) async {
    if (_syncing) {
      throw const SyncException('Ya hay una sincronización en curso.');
    }
    _syncing = true;
    var activeBatch = const <SyncEventModel>[];
    try {
      final configuration = await _local.readConfiguration();
      if (configuration == null) {
        throw const SyncException('Vincula esta tablet con la PC primero.');
      }
      final token = await _credentials.readDeviceToken();
      if (token == null || token.isEmpty) {
        throw const SyncException(
          'La credencial segura no está disponible. Vuelve a vincular la tablet.',
        );
      }
      await _local.markSyncAttempt(success: false);
      final serverUrl = await _resolveServerUrl(configuration, token);

      var pushed = 0;
      while (true) {
        activeBatch = await _local.prepareOutboxBatch();
        if (activeBatch.isEmpty) break;
        try {
          final results = await _remote.push(
            serverUrl: serverUrl,
            deviceId: configuration.deviceId,
            token: token,
            events: activeBatch,
          );
          await _local.markPushResults(activeBatch, results);
          pushed += results
              .where(
                (result) =>
                    result.status == 'ACCEPTED' ||
                    result.status == 'ALREADY_PROCESSED',
              )
              .length;
          activeBatch = const [];
        } catch (_) {
          await _local.markBatchRetry(activeBatch, errorCode: 'push_failed');
          activeBatch = const [];
          rethrow;
        }
      }

      var pulled = 0;
      final bootstrapCompleted = await _local.isBootstrapCompleted();
      if (forceBootstrap || !bootstrapCompleted) {
        await _local.beginBootstrap(resetCursor: forceBootstrap);
        var pageNumber = 0;
        while (true) {
          final page = await _remote.bootstrap(
            serverUrl: serverUrl,
            deviceId: configuration.deviceId,
            token: token,
            page: pageNumber,
          );
          await _local.applyChangePage(
            page.changes,
            nextCursor: page.nextCursor,
            bootstrap: !page.hasMore,
          );
          pulled += page.changes.length;
          if (!page.hasMore) break;
          pageNumber++;
        }
      }

      var cursor = await _local.readPullCursor();
      while (true) {
        final page = await _remote.pull(
          serverUrl: serverUrl,
          deviceId: configuration.deviceId,
          token: token,
          after: cursor,
        );
        await _local.applyChangePage(
          page.changes,
          nextCursor: page.nextCursor,
          bootstrap: false,
        );
        pulled += page.changes.length;
        cursor = page.nextCursor;
        if (!page.hasMore) break;
      }

      await _local.markSyncAttempt(success: true);
      final status = await _local.readStatus();
      return SyncRunResult(
        pushed: pushed,
        pulled: pulled,
        conflicts: status.conflicts,
        pending: status.totalPending,
      );
    } on SyncException {
      rethrow;
    } on DioException catch (error) {
      if (activeBatch.isNotEmpty) {
        await _local.markBatchRetry(activeBatch, errorCode: 'network_error');
      }
      throw SyncException(_networkMessage(error));
    } on Object {
      if (activeBatch.isNotEmpty) {
        await _local.markBatchRetry(activeBatch, errorCode: 'unexpected_error');
      }
      throw const SyncException(
        'No se pudo aplicar un cambio recibido. Los datos locales no fueron modificados.',
      );
    } finally {
      _syncing = false;
    }
  }

  @override
  Future<void> unlink() async {
    await _credentials.clear();
    await _local.clearConfiguration();
  }

  Future<String> _resolveServerUrl(
    SyncConfiguration configuration,
    String token,
  ) async {
    final cached = configuration.serverUrlCache;
    if (cached.isNotEmpty) {
      try {
        await _remote.validateDevice(
          serverUrl: cached,
          deviceId: configuration.deviceId,
          token: token,
        );
        return cached;
      } catch (_) {
        // La IP puede haber cambiado; se continúa con mDNS.
      }
    }

    final candidates = await _discovery.discover(
      serviceType: configuration.serviceType,
    );
    for (final candidate in candidates) {
      if (candidate.serverId.isNotEmpty &&
          candidate.serverId != configuration.serverId) {
        continue;
      }
      try {
        await _remote.validateDevice(
          serverUrl: candidate.url,
          deviceId: configuration.deviceId,
          token: token,
        );
        await _local.updateServerUrl(candidate.url);
        return candidate.url;
      } catch (_) {
        // Una respuesta no autenticada nunca se acepta como la PC vinculada.
      }
    }
    throw const SyncException(
      'No se encontró la PC vinculada en esta red. Revisa el Wi-Fi o actualiza la dirección.',
    );
  }

  String _networkMessage(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'La vinculación fue rechazada por la PC. Vuelve a emparejar la tablet.';
    }
    if (status != null && status >= 400 && status < 500) {
      return 'La PC rechazó la solicitud de sincronización (código $status).';
    }
    return 'No se pudo conectar con la PC. Los cambios siguen guardados en la tablet.';
  }
}

class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => message;
}
