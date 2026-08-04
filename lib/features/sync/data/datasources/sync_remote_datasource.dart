import 'dart:io';

import 'package:dio/dio.dart';

import '../contracts/sync_contract.dart';
import '../models/device_registration_models.dart';
import '../models/sync_bootstrap_models.dart';
import '../models/sync_discovery_models.dart';
import '../models/sync_file_models.dart';
import '../models/sync_pull_models.dart';
import '../models/sync_push_models.dart';

class SyncRemoteDatasource {
  SyncRemoteDatasource([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<DeviceRegistrationResponseModel> registerDevice({
    required String serverUrl,
    required String deviceName,
    required String pairingCode,
  }) => _guard(() async {
    final request = DeviceRegistrationRequestModel(
      name: deviceName,
      pairingCode: pairingCode,
    );
    final response = await _dio.post<Object?>(
      '${_base(serverUrl)}/devices/register',
      data: request.toJson(apiContractVersion: SyncContract.apiVersion),
    );
    final registration = DeviceRegistrationResponseModel.fromJson(
      _json(response.data),
    );
    if (registration.deviceId.isEmpty || registration.token.isEmpty) {
      throw const FormatException(
        'El servidor devolvio una vinculacion incompleta.',
      );
    }
    return registration;
  });

  Future<SyncDiscoveryModel> discoverServer({required String serverUrl}) =>
      _guard(() async {
        final response = await _dio.get<Object?>(
          '${_base(serverUrl)}/discovery',
        );
        return SyncDiscoveryModel.fromJson(_json(response.data));
      });

  Future<DeviceStatusModel> validateDevice({
    required String serverUrl,
    required String deviceId,
    required String token,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      '${_base(serverUrl)}/devices/$deviceId/status',
      options: _auth(deviceId, token),
    );
    return DeviceStatusModel.fromJson(_json(response.data));
  });

  Future<SyncServerStatusModel> readServerStatus({
    required String serverUrl,
    required String deviceId,
    required String token,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      '${_base(serverUrl)}/sync/status',
      options: _auth(deviceId, token),
    );
    return SyncServerStatusModel.fromJson(_json(response.data));
  });

  Future<List<SyncPushResultModel>> push({
    required String serverUrl,
    required String deviceId,
    required String token,
    required List<SyncEventModel> events,
  }) => _guard(() async {
    final request = SyncPushRequestModel(
      deviceId: deviceId,
      apiContractVersion: SyncContract.apiVersion,
      events: events,
    );
    final response = await _dio.post<Object?>(
      '${_base(serverUrl)}/sync/push',
      data: request.toJson(),
      options: _auth(deviceId, token),
    );
    final rawResults = _json(response.data)['results'] as List? ?? const [];
    return rawResults
        .whereType<Map>()
        .map(
          (result) =>
              SyncPushResultModel.fromJson(Map<String, Object?>.from(result)),
        )
        .toList();
  });

  Future<SyncPullPageModel> pull({
    required String serverUrl,
    required String deviceId,
    required String token,
    required int after,
    int limit = SyncContract.pullPageSize,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      '${_base(serverUrl)}/sync/pull',
      queryParameters: {'after': after, 'limit': limit},
      options: _auth(deviceId, token),
    );
    return SyncPullPageModel.fromJson(_json(response.data));
  });

  Future<int> acknowledgePull({
    required String serverUrl,
    required String deviceId,
    required String token,
    required int cursor,
  }) => _guard(() async {
    final response = await _dio.post<Object?>(
      '${_base(serverUrl)}/sync/pull/ack',
      data: {'cursor': cursor},
      options: _auth(deviceId, token),
    );
    return SyncPullAckModel.fromJson(_json(response.data)).acknowledgedCursor;
  });

  Future<SyncBootstrapPageModel> bootstrap({
    required String serverUrl,
    required String deviceId,
    required String token,
    required int page,
    int? snapshotCursor,
    int limit = SyncContract.bootstrapPageSize,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      '${_base(serverUrl)}/sync/bootstrap',
      queryParameters: {
        'page': page,
        'limit': limit,
        'snapshotCursor': ?snapshotCursor,
      },
      options: _auth(deviceId, token),
    );
    return SyncBootstrapPageModel.fromJson(_json(response.data));
  });

  Future<SyncFileIntentModel> createFileIntent({
    required String serverUrl,
    required String deviceId,
    required String token,
    required String fileName,
    required String contentType,
    required int sizeBytes,
    required String checksumSha256,
    required String ownerType,
    required String ownerId,
  }) => _guard(() async {
    final response = await _dio.post<Object?>(
      '${_base(serverUrl)}/files/intents',
      data: {
        'fileName': fileName,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'checksumSha256': checksumSha256,
        'visibility': ownerType == 'PRODUCT' ? 'PUBLIC' : 'PRIVATE',
        'ownerType': ownerType,
        'ownerId': ownerId,
      },
      options: _auth(deviceId, token),
    );
    return SyncFileIntentModel.fromJson(_json(response.data));
  });

  Future<SyncStoredFileModel> uploadFileContent({
    required String serverUrl,
    required String deviceId,
    required String token,
    required SyncFileIntentModel intent,
    required String localPath,
    required String contentType,
  }) => _guard(() async {
    final response = await _dio.put<Object?>(
      _absolute(serverUrl, intent.uploadUrl),
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(
          localPath,
          filename: File(localPath).uri.pathSegments.last,
          contentType: DioMediaType.parse(contentType),
        ),
      }),
      options: _auth(deviceId, token),
    );
    return SyncStoredFileModel.fromJson(_json(response.data));
  });

  Future<SyncStoredFileModel> completeFileUpload({
    required String serverUrl,
    required String deviceId,
    required String token,
    required SyncFileIntentModel intent,
  }) => _guard(() async {
    final response = await _dio.post<Object?>(
      _absolute(serverUrl, intent.completeUrl),
      options: _auth(deviceId, token),
    );
    return SyncStoredFileModel.fromJson(_json(response.data));
  });

  Future<SyncDownloadedFileModel> downloadFile({
    required String serverUrl,
    required String deviceId,
    required String token,
    required String storageKey,
  }) => _guard(() async {
    final parts = storageKey.split('/');
    if (parts.length < 2 || parts[1].isEmpty) {
      throw const FormatException('La referencia del archivo no es valida.');
    }
    final response = await _dio.get<List<int>>(
      '${_base(serverUrl)}/files/${parts[1]}',
      options: _auth(
        deviceId,
        token,
      ).copyWith(responseType: ResponseType.bytes),
    );
    return SyncDownloadedFileModel(
      bytes: response.data ?? const [],
      contentType:
          response.headers.value(Headers.contentTypeHeader) ??
          'application/octet-stream',
    );
  });

  Options _auth(String deviceId, String token) =>
      Options(headers: {'X-Device-Id': deviceId, 'X-Device-Token': token});

  String _base(String serverUrl) =>
      '${serverUrl.replaceFirst(RegExp(r'/$'), '')}/api/v1';

  String _absolute(String serverUrl, String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${serverUrl.replaceFirst(RegExp(r'/$'), '')}/${path.replaceFirst(RegExp(r'^/'), '')}';
  }

  Map<String, Object?> _json(Object? value) {
    if (value is Map) return Map<String, Object?>.from(value);
    throw const FormatException('El servidor devolvio una respuesta invalida.');
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw SyncRemoteException.fromDio(error);
    }
  }
}

class SyncRemoteException implements Exception {
  const SyncRemoteException({
    required this.code,
    required this.message,
    this.statusCode,
    this.pcUnavailable = false,
  });

  factory SyncRemoteException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final json = body is Map ? Map<String, Object?>.from(body) : const {};
    final functionalCode = json['code'] as String?;
    final backendMessage = json['message'] as String?;
    final unavailable =
        status == null &&
        {
          DioExceptionType.connectionError,
          DioExceptionType.connectionTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.sendTimeout,
        }.contains(error.type);
    final code =
        functionalCode ??
        switch (status) {
          400 => 'INVALID_JSON',
          401 => 'INVALID_DEVICE_TOKEN',
          403 => 'ACCESS_DENIED',
          409 => 'CONFLICT',
          422 => 'BUSINESS_RULE',
          _ when status != null && status >= 500 => 'SERVER_ERROR',
          _ when unavailable =>
            error.type == DioExceptionType.connectionTimeout
                ? 'TIMEOUT'
                : 'PC_UNAVAILABLE',
          _ => 'NETWORK_ERROR',
        };
    return SyncRemoteException(
      code: code,
      statusCode: status,
      pcUnavailable: unavailable,
      message: _friendlyMessage(code, backendMessage, status),
    );
  }

  final String code;
  final String message;
  final int? statusCode;
  final bool pcUnavailable;

  static String _friendlyMessage(
    String code,
    String? backendMessage,
    int? status,
  ) => switch (code) {
    'INCOMPATIBLE_API_CONTRACT' =>
      'La version de la app no es compatible con la PC. Actualiza ambos productos.',
    'INVALID_PAIRING_CODE' =>
      'El codigo de vinculacion no es valido. Genera uno nuevo en la PC.',
    'PAIRING_CODE_EXPIRED' =>
      'El codigo de vinculacion vencio. Genera uno nuevo en la PC.',
    'PAIRING_CODE_ALREADY_USED' =>
      'Ese codigo ya fue utilizado. Genera uno nuevo en la PC.',
    'PRODUCT_VARIANTS_REQUIRED' =>
      'El producto debe contener al menos una variante valida.',
    'INVALID_DEVICE_TOKEN' =>
      'La vinculacion fue revocada o ya no es valida. Vuelve a vincular la tablet.',
    'ACCESS_DENIED' => 'La PC rechazo el acceso de esta tablet.',
    'INVALID_JSON' => 'La PC recibio datos con un formato no valido.',
    'CONFLICT' => 'La PC detecto un conflicto de sincronizacion.',
    'TIMEOUT' => 'La PC tardo demasiado en responder.',
    'PC_UNAVAILABLE' =>
      'No se encontro la PC vinculada. Los cambios siguen guardados en la tablet.',
    'SERVER_ERROR' => 'La PC tuvo un error temporal. Intenta nuevamente.',
    _ =>
      backendMessage?.trim().isNotEmpty == true
          ? backendMessage!
          : status == 422
          ? 'La PC rechazo una regla de negocio o de contrato.'
          : 'No se pudo completar la comunicacion con la PC.',
  };

  @override
  String toString() => '$code: $message';
}
