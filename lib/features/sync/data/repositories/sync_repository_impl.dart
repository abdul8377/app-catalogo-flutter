import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/sync_configuration.dart';
import '../../domain/entities/sync_pairing_payload.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/sync_repository.dart';
import '../contracts/sync_contract.dart';
import '../datasources/sync_discovery_datasource.dart';
import '../datasources/sync_local_datasource.dart';
import '../datasources/sync_remote_datasource.dart';
import '../datasources/sync_secure_credentials_datasource.dart';
import '../models/sync_discovery_models.dart';
import '../models/sync_push_models.dart';

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
    if (payload.pairingCode.trim().isEmpty) {
      throw const SyncException(
        code: 'PAIRING_CODE_REQUIRED',
        message: 'Escribe o escanea un codigo de vinculacion valido.',
      );
    }
    try {
      final located = await _locatePairingServer(payload);
      final registration = await _remote.registerDevice(
        serverUrl: located.$1,
        deviceName: deviceName.trim().isEmpty ? 'Tablet' : deviceName.trim(),
        pairingCode: payload.pairingCode,
      );
      _requireContract(registration.apiContractVersion);
      final now = DateTime.now().toUtc();
      final discovery = located.$2;
      final configuration = SyncConfiguration(
        serverId: discovery.serverId,
        serverName: discovery.serverName.isEmpty
            ? Uri.parse(located.$1).host
            : discovery.serverName,
        serviceType: SyncPairingPayload.normalizeServiceType(
          discovery.serviceType,
        ),
        serverUrlCache: located.$1,
        deviceId: registration.deviceId,
        deviceName: deviceName.trim().isEmpty ? 'Tablet' : deviceName.trim(),
        contractVersion: SyncContract.apiVersion,
        linkedAt: now,
      );
      await _credentials.saveDeviceToken(registration.token);
      try {
        await _local.saveConfiguration(configuration);
        final serverStatus = await _remote.readServerStatus(
          serverUrl: located.$1,
          deviceId: registration.deviceId,
          token: registration.token,
        );
        if (serverStatus.serverId != configuration.serverId) {
          throw const SyncException(
            code: 'SERVER_ID_MISMATCH',
            message: 'La direccion respondio con otra identidad de PC.',
          );
        }
        _requireContract(serverStatus.apiContractVersion);
        final localHasData = await _local.hasBusinessData();
        final serverHasData = serverStatus.records > 0;
        if (!serverHasData && localHasData) {
          await _local.setInitializationStatus('tablet');
          await _local.createInitialSnapshot();
        } else if (serverHasData && !localHasData) {
          await _local.setInitializationStatus('server');
        } else if (!serverHasData && !localHasData) {
          await _local.setInitializationStatus('ready');
        } else {
          await _local.setInitializationStatus('decision_required');
        }
      } catch (_) {
        await _credentials.clear();
        await _local.clearConfiguration();
        rethrow;
      }
      return configuration;
    } on SyncRemoteException catch (error) {
      throw _syncException(error);
    }
  }

  @override
  Future<List<SyncServerCandidate>> discoverServers() async {
    final raw = await _discovery.discover();
    final validated = <SyncServerCandidate>[];
    for (final candidate in raw) {
      try {
        final discovery = await _remote.discoverServer(
          serverUrl: candidate.url,
        );
        _requireContract(discovery.apiContractVersion);
        if (candidate.serverId.isNotEmpty &&
            candidate.serverId != discovery.serverId) {
          continue;
        }
        validated.add(
          SyncServerCandidate(
            url: candidate.url,
            serverId: discovery.serverId,
            name: discovery.serverName,
            serviceType: SyncPairingPayload.normalizeServiceType(
              discovery.serviceType,
            ),
            apiContractVersion: discovery.apiContractVersion,
          ),
        );
      } catch (_) {
        // Un anuncio sin identidad contractual no es una PC seleccionable.
      }
    }
    return validated;
  }

  @override
  Future<SyncRunResult> synchronize({bool forceBootstrap = false}) async {
    if (_syncing) {
      throw const SyncException(
        code: 'SYNC_IN_PROGRESS',
        message: 'Ya hay una sincronizacion en curso.',
      );
    }
    _syncing = true;
    var activeBatch = const <SyncEventModel>[];
    try {
      final configuration = await _local.readConfiguration();
      if (configuration == null) {
        throw const SyncException(
          code: 'NOT_LINKED',
          message: 'Vincula esta tablet con la PC primero.',
        );
      }
      final initialization = await _local.readInitializationStatus();
      if (initialization == 'decision_required') {
        throw const SyncException(
          code: 'INITIAL_SOURCE_REQUIRED',
          message:
              'La PC y la tablet contienen datos. Elige la fuente inicial antes de sincronizar.',
        );
      }
      final token = await _credentials.readDeviceToken();
      if (token == null || token.isEmpty) {
        throw const SyncException(
          code: 'MISSING_DEVICE_TOKEN',
          message:
              'La credencial segura no esta disponible. Vuelve a vincular la tablet.',
        );
      }
      await _local.markSyncAttempt(success: false);
      final serverUrl = await _resolveServerUrl(configuration, token);

      await _ackPending(configuration, token, serverUrl);
      await _processUploads(configuration, token, serverUrl);

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
          await _local.markBatchRetry(activeBatch, errorCode: 'PUSH_FAILED');
          activeBatch = const [];
          rethrow;
        }
      }

      var pulled = 0;
      final bootstrapCompleted = await _local.isBootstrapCompleted();
      if (forceBootstrap || !bootstrapCompleted) {
        await _local.beginBootstrap(resetCursor: forceBootstrap);
        var pageNumber = 0;
        int? snapshotCursor;
        while (true) {
          final page = await _remote.bootstrap(
            serverUrl: serverUrl,
            deviceId: configuration.deviceId,
            token: token,
            page: pageNumber,
            snapshotCursor: snapshotCursor,
          );
          snapshotCursor ??= page.snapshotCursor;
          if (snapshotCursor != page.snapshotCursor) {
            throw const SyncException(
              code: 'BOOTSTRAP_SNAPSHOT_CHANGED',
              message: 'La PC cambio el snapshot durante la reconstruccion.',
            );
          }
          await _local.applyBootstrapPage(
            page.records,
            snapshotCursor: page.snapshotCursor,
            isLastPage: !page.hasMore,
          );
          pulled += page.records.length;
          if (!page.hasMore) break;
          pageNumber = page.nextPage;
        }
        await _ackPending(configuration, token, serverUrl);
      }

      var cursor = await _local.readPullCursor();
      while (true) {
        final page = await _remote.pull(
          serverUrl: serverUrl,
          deviceId: configuration.deviceId,
          token: token,
          after: cursor,
        );
        await _local.applyPullPage(page.changes, nextCursor: page.nextCursor);
        pulled += page.changes.length;
        cursor = page.nextCursor;
        await _ackPending(configuration, token, serverUrl);
        if (!page.hasMore) break;
      }

      await _processDownloads(configuration, token, serverUrl);
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
    } on SyncRemoteException catch (error) {
      if (activeBatch.isNotEmpty) {
        await _local.markBatchRetry(activeBatch, errorCode: error.code);
      }
      throw _syncException(error);
    } on FormatException catch (error) {
      throw SyncException(
        code: 'INVALID_CONTRACT_JSON',
        message: error.message,
      );
    } catch (error) {
      throw SyncException(
        code: 'LOCAL_SYNC_APPLY_FAILED',
        message:
            'La tablet no pudo aplicar un registro recibido de la PC. '
            '$error',
      );
    } finally {
      _syncing = false;
    }
  }

  @override
  Future<void> chooseInitialSource(SyncInitialSource source) async {
    final current = await _local.readInitializationStatus();
    if (current != 'decision_required') {
      throw const SyncException(
        code: 'INITIAL_SOURCE_NOT_REQUIRED',
        message: 'La fuente inicial ya fue determinada.',
      );
    }
    switch (source) {
      case SyncInitialSource.tablet:
        await _local.setInitializationStatus('tablet');
        await _local.createInitialSnapshot();
      case SyncInitialSource.server:
        await _local.prepareServerInitialSource();
    }
  }

  @override
  Future<void> unlink() async {
    await _credentials.clear();
    await _local.clearConfiguration();
  }

  Future<(String, SyncDiscoveryModel)> _locatePairingServer(
    SyncPairingPayload payload,
  ) async {
    final urlHint = payload.currentUrlHint;
    if (urlHint != null && urlHint.isNotEmpty) {
      final discovery = await _remote.discoverServer(serverUrl: urlHint);
      _validateDiscovery(
        payload,
        discovery.serverId,
        discovery.apiContractVersion,
      );
      return (urlHint, discovery);
    }
    final candidates = await _discovery.discover(
      serviceType: payload.serviceType,
    );
    for (final candidate in candidates) {
      if (candidate.serverId.isNotEmpty &&
          candidate.serverId != payload.serverId) {
        continue;
      }
      try {
        final discovery = await _remote.discoverServer(
          serverUrl: candidate.url,
        );
        _validateDiscovery(
          payload,
          discovery.serverId,
          discovery.apiContractVersion,
        );
        return (candidate.url, discovery);
      } catch (_) {
        // Se continua hasta encontrar exactamente el serverId del QR.
      }
    }
    throw const SyncException(
      code: 'PC_UNAVAILABLE',
      message:
          'No se encontro la PC del QR en esta red. Revisa que ambos equipos usen el mismo Wi-Fi.',
    );
  }

  void _validateDiscovery(
    SyncPairingPayload payload,
    String serverId,
    String apiContractVersion,
  ) {
    if (payload.serverId.isNotEmpty && payload.serverId != serverId) {
      throw const SyncException(
        code: 'SERVER_ID_MISMATCH',
        message: 'La direccion pertenece a una PC distinta de la esperada.',
      );
    }
    final requestedContract = payload.apiContractVersion.isEmpty
        ? SyncContract.apiVersion
        : payload.apiContractVersion;
    if (requestedContract != SyncContract.apiVersion) {
      throw const SyncException(
        code: 'INCOMPATIBLE_API_CONTRACT',
        message: 'El QR pertenece a una version incompatible del servidor.',
      );
    }
    _requireContract(apiContractVersion);
  }

  Future<String> _resolveServerUrl(
    SyncConfiguration configuration,
    String token,
  ) async {
    final cached = configuration.serverUrlCache;
    if (cached.isNotEmpty &&
        await _isExpectedLinkedServer(cached, configuration, token)) {
      return cached;
    }

    final candidates = await _discovery.discover(
      serviceType: configuration.serviceType,
    );
    for (final candidate in candidates) {
      if (candidate.serverId.isNotEmpty &&
          candidate.serverId != configuration.serverId) {
        continue;
      }
      if (await _isExpectedLinkedServer(candidate.url, configuration, token)) {
        await _local.updateServerUrl(candidate.url);
        return candidate.url;
      }
    }
    throw const SyncException(
      code: 'PC_UNAVAILABLE',
      message:
          'No se encontro la PC vinculada en esta red. Revisa el Wi-Fi o actualiza la direccion.',
    );
  }

  Future<bool> _isExpectedLinkedServer(
    String url,
    SyncConfiguration configuration,
    String token,
  ) async {
    try {
      final discovery = await _remote.discoverServer(serverUrl: url);
      if (discovery.serverId != configuration.serverId ||
          discovery.apiContractVersion != SyncContract.apiVersion) {
        return false;
      }
      final device = await _remote.validateDevice(
        serverUrl: url,
        deviceId: configuration.deviceId,
        token: token,
      );
      return device.deviceId == configuration.deviceId &&
          device.apiContractVersion == SyncContract.apiVersion;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ackPending(
    SyncConfiguration configuration,
    String token,
    String serverUrl,
  ) async {
    final cursor = await _local.readPendingAckCursor();
    if (cursor == null) return;
    int acknowledged;
    try {
      acknowledged = await _remote.acknowledgePull(
        serverUrl: serverUrl,
        deviceId: configuration.deviceId,
        token: token,
        cursor: cursor,
      );
    } on SyncRemoteException catch (error) {
      if (error.code != 'PULL_ACK_NOT_DELIVERED') rethrow;
      // Compatibilidad con servidores 1.0 que no marcan el cursor del
      // bootstrap como entregado hasta el primer pull posterior al snapshot.
      final delivery = await _remote.pull(
        serverUrl: serverUrl,
        deviceId: configuration.deviceId,
        token: token,
        after: cursor,
        limit: 1,
      );
      await _local.applyPullPage(
        delivery.changes,
        nextCursor: delivery.nextCursor,
      );
      final deliveredCursor = await _local.readPendingAckCursor();
      if (deliveredCursor == null) return;
      acknowledged = await _remote.acknowledgePull(
        serverUrl: serverUrl,
        deviceId: configuration.deviceId,
        token: token,
        cursor: deliveredCursor,
      );
    }
    final expected = await _local.readPendingAckCursor();
    if (expected == null || acknowledged != expected) {
      throw const SyncException(
        code: 'INVALID_ACK_RESPONSE',
        message: 'La PC confirmo un cursor diferente al solicitado.',
      );
    }
    await _local.markAckConfirmed(acknowledged);
  }

  Future<void> _processUploads(
    SyncConfiguration configuration,
    String token,
    String serverUrl,
  ) async {
    await _local.refreshFileQueue();
    while (true) {
      final files = await _local.readPendingUploads();
      if (files.isEmpty) return;
      for (final item in files) {
        try {
          final file = File(item.localPath);
          if (!await file.exists()) {
            await _local.markFileRetry(item.id, 'LOCAL_FILE_NOT_FOUND');
            continue;
          }
          final bytes = await file.readAsBytes();
          final checksum = sha256.convert(bytes).toString();
          final contentType = _contentType(item.localPath);
          final fileName = path.basename(item.localPath);
          await _local.markFileUploading(
            item.id,
            checksum: checksum,
            sizeBytes: bytes.length,
            contentType: contentType,
            fileName: fileName,
          );
          final intent = await _remote.createFileIntent(
            serverUrl: serverUrl,
            deviceId: configuration.deviceId,
            token: token,
            fileName: fileName,
            contentType: contentType,
            sizeBytes: bytes.length,
            checksumSha256: checksum,
            ownerType: item.ownerType,
            ownerId: item.ownerId,
          );
          await _remote.uploadFileContent(
            serverUrl: serverUrl,
            deviceId: configuration.deviceId,
            token: token,
            intent: intent,
            localPath: item.localPath,
            contentType: contentType,
          );
          final ready = await _remote.completeFileUpload(
            serverUrl: serverUrl,
            deviceId: configuration.deviceId,
            token: token,
            intent: intent,
          );
          if (ready.storageKey.isEmpty || ready.status != 'READY') {
            throw const FormatException(
              'La PC no confirmo el archivo cargado.',
            );
          }
          await _local.markFileReady(
            item.id,
            backendFileId: ready.fileId,
            storageKey: ready.storageKey,
            downloadUrl: ready.downloadUrl,
          );
        } catch (error) {
          await _local.markFileRetry(
            item.id,
            error is SyncRemoteException ? error.code : 'FILE_UPLOAD_FAILED',
          );
          rethrow;
        }
      }
    }
  }

  Future<void> _processDownloads(
    SyncConfiguration configuration,
    String token,
    String serverUrl,
  ) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(path.join(documents.path, 'sync_files'));
    if (!await directory.exists()) await directory.create(recursive: true);
    while (true) {
      final files = await _local.readPendingDownloads();
      if (files.isEmpty) return;
      for (final item in files) {
        try {
          await _local.markFileDownloading(item.id);
          final storageKey = item.storageKey ?? '';
          final downloaded = await _remote.downloadFile(
            serverUrl: serverUrl,
            deviceId: configuration.deviceId,
            token: token,
            storageKey: storageKey,
          );
          final fileId = storageKey.split('/').elementAtOrNull(1) ?? item.id;
          final localPath = path.join(
            directory.path,
            '$fileId${_extension(downloaded.contentType)}',
          );
          await File(localPath).writeAsBytes(downloaded.bytes, flush: true);
          await _local.markFileDownloaded(item.id, localPath);
        } catch (error) {
          await _local.markFileRetry(
            item.id,
            error is SyncRemoteException ? error.code : 'FILE_DOWNLOAD_FAILED',
          );
          rethrow;
        }
      }
    }
  }

  String _contentType(String filePath) =>
      switch (path.extension(filePath).toLowerCase()) {
        '.png' => 'image/png',
        '.webp' => 'image/webp',
        '.pdf' => 'application/pdf',
        _ => 'image/jpeg',
      };

  String _extension(String contentType) =>
      switch (contentType.split(';').first.toLowerCase()) {
        'image/png' => '.png',
        'image/webp' => '.webp',
        'application/pdf' => '.pdf',
        _ => '.jpg',
      };

  void _requireContract(String value) {
    if (value != SyncContract.apiVersion) {
      throw const SyncException(
        code: 'INCOMPATIBLE_API_CONTRACT',
        message:
            'La version de sincronizacion de la PC no es compatible con esta app.',
      );
    }
  }

  SyncException _syncException(SyncRemoteException error) => SyncException(
    code: error.pcUnavailable ? 'PC_UNAVAILABLE' : error.code,
    message: error.message,
  );
}

class SyncException implements Exception {
  const SyncException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}
