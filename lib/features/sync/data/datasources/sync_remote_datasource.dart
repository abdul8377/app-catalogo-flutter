import 'package:dio/dio.dart';

import '../models/sync_api_models.dart';

class SyncRegistrationResponse {
  const SyncRegistrationResponse({required this.deviceId, required this.token});

  final String deviceId;
  final String token;
}

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

  Future<SyncRegistrationResponse> registerDevice({
    required String serverUrl,
    required String deviceName,
    required String pairingCode,
  }) async {
    final response = await _dio.post<Object?>(
      '${_base(serverUrl)}/devices/register',
      data: {'name': deviceName, 'platform': 'ANDROID'},
      options: Options(headers: {'X-Pairing-Code': pairingCode}),
    );
    final json = _json(response.data);
    final deviceId = json['deviceId'] as String? ?? '';
    final token = json['token'] as String? ?? '';
    if (deviceId.isEmpty || token.isEmpty) {
      throw const FormatException(
        'El servidor devolvió una vinculación incompleta.',
      );
    }
    return SyncRegistrationResponse(deviceId: deviceId, token: token);
  }

  Future<void> validateDevice({
    required String serverUrl,
    required String deviceId,
    required String token,
  }) async {
    await _dio.get<Object?>(
      '${_base(serverUrl)}/devices/$deviceId/status',
      options: _auth(deviceId, token),
    );
  }

  Future<List<SyncPushResultModel>> push({
    required String serverUrl,
    required String deviceId,
    required String token,
    required List<SyncEventModel> events,
  }) async {
    final response = await _dio.post<Object?>(
      '${_base(serverUrl)}/sync/push',
      data: {
        'deviceId': deviceId,
        'events': events.map((event) => event.toJson()).toList(),
      },
      options: _auth(deviceId, token),
    );
    final json = _json(response.data);
    final rawResults = json['results'] as List? ?? const [];
    return rawResults
        .whereType<Map>()
        .map(
          (result) =>
              SyncPushResultModel.fromJson(Map<String, Object?>.from(result)),
        )
        .toList();
  }

  Future<SyncChangePageModel> pull({
    required String serverUrl,
    required String deviceId,
    required String token,
    required int after,
    int limit = 200,
  }) async {
    final response = await _dio.get<Object?>(
      '${_base(serverUrl)}/sync/pull',
      queryParameters: {'after': after, 'limit': limit},
      options: _auth(deviceId, token),
    );
    return SyncChangePageModel.fromJson(_json(response.data));
  }

  Future<SyncChangePageModel> bootstrap({
    required String serverUrl,
    required String deviceId,
    required String token,
    required int page,
    int limit = 200,
  }) async {
    final response = await _dio.get<Object?>(
      '${_base(serverUrl)}/sync/bootstrap',
      queryParameters: {'page': page, 'limit': limit},
      options: _auth(deviceId, token),
    );
    return SyncChangePageModel.fromJson(_json(response.data));
  }

  Options _auth(String deviceId, String token) =>
      Options(headers: {'X-Device-Id': deviceId, 'X-Device-Token': token});

  String _base(String serverUrl) =>
      '${serverUrl.replaceFirst(RegExp(r'/$'), '')}/api/v1';

  Map<String, Object?> _json(Object? value) {
    if (value is Map) return Map<String, Object?>.from(value);
    throw const FormatException('El servidor devolvió una respuesta inválida.');
  }
}
