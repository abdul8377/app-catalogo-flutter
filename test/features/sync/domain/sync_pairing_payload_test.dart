import 'package:app_catalogo/features/sync/domain/entities/sync_pairing_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta el QR oficial aunque no incluya una IP', () {
    final payload = SyncPairingPayload.fromQr('''{
      "serverId":"pc-principal",
      "serverName":"PC almacen",
      "serviceType":"_appcatalogo._tcp.local.",
      "pairingCode":"48291500",
      "apiContractVersion":"1.0"
    }''');

    expect(payload.serverId, 'pc-principal');
    expect(payload.currentUrlHint, isNull);
    expect(payload.pairingCode, '48291500');
    expect(payload.apiContractVersion, '1.0');
    expect(payload.serviceType, '_appcatalogo._tcp');
  });

  test('normaliza una pista de direccion opcional', () {
    final payload = SyncPairingPayload.fromQr('''{
      "serverId":"pc-principal",
      "serverName":"PC almacen",
      "serviceType":"_appcatalogo._tcp",
      "pairingCode":"48291500",
      "apiContractVersion":"1.0",
      "currentUrlHint":"192.168.1.15:8081/"
    }''');

    expect(payload.currentUrlHint, 'http://192.168.1.15:8081');
  });

  test('rechaza QR incompleto y direcciones no validas', () {
    expect(
      () => SyncPairingPayload.fromQr('{"serverId":"pc"}'),
      throwsFormatException,
    );
    expect(SyncPairingPayload.normalizeServerUrl('texto sin host'), isEmpty);
  });
}
