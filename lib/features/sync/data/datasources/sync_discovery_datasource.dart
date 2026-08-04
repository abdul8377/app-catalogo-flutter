import 'dart:async';
import 'dart:convert';

import 'package:nsd/nsd.dart';

import '../../domain/entities/sync_configuration.dart';

class SyncDiscoveryDatasource {
  const SyncDiscoveryDatasource();

  Future<List<SyncServerCandidate>> discover({
    String serviceType = '_appcatalogo._tcp',
    Duration timeout = const Duration(seconds: 4),
  }) async {
    Discovery? discovery;
    final candidates = <String, SyncServerCandidate>{};
    try {
      discovery = await startDiscovery(
        serviceType.replaceFirst(RegExp(r'\.local$'), ''),
        ipLookupType: IpLookupType.v4,
      );
      discovery.addServiceListener((service, status) {
        if (status != ServiceStatus.found || service.port == null) return;
        final host = _host(service);
        if (host.isEmpty) return;
        final url = 'http://$host:${service.port}';
        candidates[url] = SyncServerCandidate(
          url: url,
          serverId: _txt(service, 'serverId'),
          name: service.name ?? '',
        );
      });
      await Future<void>.delayed(timeout);
    } catch (_) {
      return const [];
    } finally {
      if (discovery != null) {
        try {
          await stopDiscovery(discovery);
        } catch (_) {
          // El descubrimiento ya puede haber sido cerrado por la plataforma.
        }
      }
    }
    return candidates.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  String _host(Service service) {
    final addresses = service.addresses;
    if (addresses != null && addresses.isNotEmpty) {
      return addresses.first.address;
    }
    return (service.host ?? '').replaceFirst(RegExp(r'\.$'), '');
  }

  String _txt(Service service, String key) {
    final bytes = service.txt?[key];
    if (bytes == null) return '';
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return '';
    }
  }
}
