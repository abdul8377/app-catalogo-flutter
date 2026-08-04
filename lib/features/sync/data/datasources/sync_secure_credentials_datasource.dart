import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncSecureCredentialsDatasource {
  const SyncSecureCredentialsDatasource(this._storage);

  factory SyncSecureCredentialsDatasource.create() =>
      const SyncSecureCredentialsDatasource(FlutterSecureStorage());

  static const _deviceTokenKey = 'sync.device_token';

  final FlutterSecureStorage _storage;

  Future<void> saveDeviceToken(String token) =>
      _storage.write(key: _deviceTokenKey, value: token);

  Future<String?> readDeviceToken() => _storage.read(key: _deviceTokenKey);

  Future<void> clear() => _storage.delete(key: _deviceTokenKey);
}
