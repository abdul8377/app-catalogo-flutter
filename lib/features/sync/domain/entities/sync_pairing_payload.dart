import 'dart:convert';

import 'package:equatable/equatable.dart';

class SyncPairingPayload extends Equatable {
  const SyncPairingPayload({
    required this.serverId,
    required this.pairingCode,
    this.currentUrlHint,
    this.serverName = '',
    this.serviceType = '_appcatalogo._tcp',
    this.apiContractVersion = '',
  });

  factory SyncPairingPayload.fromQr(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException(
        'El QR no contiene una configuracion valida.',
      );
    }
    final json = Map<String, Object?>.from(decoded);
    final serverId = (json['serverId'] as String? ?? '').trim();
    final pairingCode = (json['pairingCode'] as String? ?? '').trim();
    final rawUrl = json['currentUrlHint'] as String?;
    final url = rawUrl == null ? null : normalizeServerUrl(rawUrl);
    final apiContractVersion = (json['apiContractVersion'] as String? ?? '')
        .trim();
    if (serverId.isEmpty ||
        pairingCode.isEmpty ||
        url == '' ||
        apiContractVersion.isEmpty) {
      throw const FormatException('El QR de vinculacion esta incompleto.');
    }
    return SyncPairingPayload(
      serverId: serverId,
      pairingCode: pairingCode,
      currentUrlHint: url,
      serverName: (json['serverName'] as String? ?? '').trim(),
      serviceType: normalizeServiceType(
        json['serviceType'] as String? ?? '_appcatalogo._tcp',
      ),
      apiContractVersion: apiContractVersion,
    );
  }

  factory SyncPairingPayload.manual({
    required String address,
    required String pairingCode,
  }) => SyncPairingPayload(
    serverId: '',
    pairingCode: pairingCode.trim(),
    currentUrlHint: normalizeServerUrl(address),
  );

  final String serverId;
  final String pairingCode;
  final String? currentUrlHint;
  final String serverName;
  final String serviceType;
  final String apiContractVersion;

  static String normalizeServiceType(String value) => value.trim().replaceFirst(
    RegExp(r'\.local\.?$', caseSensitive: false),
    '',
  );

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
