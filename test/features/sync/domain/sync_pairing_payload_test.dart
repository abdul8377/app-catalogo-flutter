import 'package:app_catalogo/features/sync/domain/entities/sync_pairing_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta el QR contractual y normaliza la dirección', () {
    final payload = SyncPairingPayload.fromQr('''{
      "serverId":"pc-principal",
      "serverName":"PC almacén",
      "serviceType":"_appcatalogo._tcp.local",
      "pairingCode":"482915",
      "apiContractVersion":1,
      "currentUrlHint":"192.168.1.15:8080/"
    }''');

    expect(payload.serverId, 'pc-principal');
    expect(payload.currentUrlHint, 'http://192.168.1.15:8080');
    expect(payload.pairingCode, '482915');
  });

  test('rechaza QR incompleto y direcciones no válidas', () {
    expect(
      () => SyncPairingPayload.fromQr('{"serverId":"pc"}'),
      throwsFormatException,
    );
    expect(SyncPairingPayload.normalizeServerUrl('texto sin host'), isEmpty);
  });
}
