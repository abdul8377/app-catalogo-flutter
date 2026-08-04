import 'dart:convert';

import 'package:equatable/equatable.dart';

class SyncPairingPayload extends Equatable {
  const SyncPairingPayload({
    required this.serverId,
    required this.pairingCode,
    required this.currentUrlHint,
    this.serverName = '',
    this.serviceType = '_appcatalogo._tcp',
    this.apiContractVersion = 1,
  });

  factory SyncPairingPayload.fromQr(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException(
        'El QR no contiene una configuración válida.',
      );
    }
    final json = Map<String, Object?>.from(decoded);
    final serverId = (json['serverId'] as String? ?? '').trim();
    final pairingCode = (json['pairingCode'] as String? ?? '').trim();
    final url = normalizeServerUrl(json['currentUrlHint'] as String? ?? '');
    if (serverId.isEmpty || pairingCode.isEmpty || url.isEmpty) {
      throw const FormatException('El QR de vinculación está incompleto.');
    }
    return SyncPairingPayload(
      serverId: serverId,
      pairingCode: pairingCode,
      currentUrlHint: url,
      serverName: (json['serverName'] as String? ?? '').trim(),
      serviceType: (json['serviceType'] as String? ?? '_appcatalogo._tcp')
          .trim(),
      apiContractVersion: (json['apiContractVersion'] as num? ?? 1).toInt(),
    );
  }

  factory SyncPairingPayload.manual(String address) => SyncPairingPayload(
    serverId: 'manual:${normalizeServerUrl(address)}',
    pairingCode: 'manual',
    currentUrlHint: normalizeServerUrl(address),
  );

  final String serverId;
  final String pairingCode;
  final String currentUrlHint;
  final String serverName;
  final String serviceType;
  final int apiContractVersion;

  static String normalizeServerUrl(String value) {
    var normalized = value.trim();
    if (normalized.isEmpty || RegExp(r'\s').hasMatch(normalized)) return '';
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty || uri.hasFragment || uri.hasQuery) {
      return '';
    }
    final path = uri.path == '/'
        ? ''
        : uri.path.replaceFirst(RegExp(r'/$'), '');
    return uri.replace(path: path).toString().replaceFirst(RegExp(r'/$'), '');
  }

  @override
  List<Object?> get props => [
    serverId,
    pairingCode,
    currentUrlHint,
    serverName,
    serviceType,
    apiContractVersion,
  ];
}
