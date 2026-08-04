import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../bloc/sync_state.dart';

class SyncSettingsDialog extends StatefulWidget {
  const SyncSettingsDialog({super.key});

  @override
  State<SyncSettingsDialog> createState() => _SyncSettingsDialogState();
}

class _SyncSettingsDialogState extends State<SyncSettingsDialog> {
  final _deviceController = TextEditingController(text: 'Tablet de ventas');
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _deviceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
      child: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, state) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 14),
              child: Row(
                children: [
                  const Icon(Icons.sync_rounded, color: Color(0xFFB54708)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Sincronización con la PC',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: state.status.isLinked
                    ? _linkedContent(context, state)
                    : _pairingContent(context, state),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _linkedContent(BuildContext context, SyncState state) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _StatusBanner(
        icon: Icons.verified_rounded,
        color: const Color(0xFF067647),
        title: 'Tablet vinculada',
        detail: state.status.serverName.isEmpty
            ? state.status.serverUrl
            : '${state.status.serverName}\n${state.status.serverUrl}',
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Metric(label: 'Pendientes', value: state.status.totalPending),
          _Metric(label: 'Conflictos', value: state.status.conflicts),
          _Metric(label: 'Archivos', value: state.status.pendingFiles),
        ],
      ),
      if (state.status.lastSuccessAt != null) ...[
        const SizedBox(height: 12),
        Text(
          'Última sincronización: ${_formatDate(state.status.lastSuccessAt!)}',
          style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
        ),
      ],
      _feedback(state),
      const SizedBox(height: 18),
      FilledButton.icon(
        key: const ValueKey('sync-settings-run'),
        onPressed: state.isBusy
            ? null
            : () => context.read<SyncBloc>().add(const SyncRequested()),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFC500),
          foregroundColor: const Color(0xFF1F1F1F),
          minimumSize: const Size.fromHeight(48),
        ),
        icon: state.phase == SyncPhase.synchronizing
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync_rounded),
        label: const Text('Sincronizar ahora'),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: state.isBusy
            ? null
            : () => context.read<SyncBloc>().add(
                const SyncRequested(forceBootstrap: true),
              ),
        icon: const Icon(Icons.cloud_download_outlined),
        label: const Text('Reconstruir datos desde la PC'),
      ),
      const SizedBox(height: 18),
      TextButton.icon(
        onPressed: state.isBusy ? null : () => _confirmUnlink(context),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFB42318)),
        icon: const Icon(Icons.link_off_rounded),
        label: const Text('Desvincular tablet'),
      ),
    ],
  );

  Widget _pairingContent(BuildContext context, SyncState state) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _StatusBanner(
        icon: Icons.tablet_android_rounded,
        color: Color(0xFF175CD3),
        title: 'Configura esta tablet una sola vez',
        detail:
            'La base local seguirá funcionando sin conexión. Cuando la PC esté disponible, se enviarán solamente los cambios pendientes.',
      ),
      const SizedBox(height: 18),
      TextField(
        controller: _deviceController,
        decoration: const InputDecoration(
          labelText: 'Nombre de esta tablet',
          prefixIcon: Icon(Icons.badge_outlined),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        key: const ValueKey('sync-scan-qr'),
        onPressed: state.isBusy ? null : () => _scanQr(context),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFC500),
          foregroundColor: const Color(0xFF1F1F1F),
          minimumSize: const Size.fromHeight(48),
        ),
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Escanear QR de la PC'),
      ),
      const SizedBox(height: 18),
      const Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('o usa la red local'),
          ),
          Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: state.isBusy
            ? null
            : () =>
                  context.read<SyncBloc>().add(const SyncDiscoveryRequested()),
        icon: state.phase == SyncPhase.discovering
            ? const SizedBox.square(
                dimension: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.wifi_find_rounded),
        label: const Text('Buscar PC automáticamente'),
      ),
      if (state.candidates.isNotEmpty) ...[
        const SizedBox(height: 10),
        ...state.candidates.map(
          (candidate) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.computer_rounded),
              title: Text(
                candidate.name.isEmpty ? 'PC encontrada' : candidate.name,
              ),
              subtitle: Text(candidate.url),
              trailing: TextButton(
                onPressed: state.isBusy
                    ? null
                    : () => context.read<SyncBloc>().add(
                        SyncCandidatePairingRequested(
                          address: candidate.url,
                          serverId: candidate.serverId,
                          serverName: candidate.name,
                          deviceName: _deviceController.text,
                        ),
                      ),
                child: const Text('Vincular'),
              ),
            ),
          ),
        ),
      ],
      const SizedBox(height: 12),
      TextField(
        controller: _addressController,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: 'Dirección temporal de la PC',
          hintText: '192.168.1.20:8080',
          prefixIcon: Icon(Icons.lan_outlined),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        key: const ValueKey('sync-pair-manual'),
        onPressed: state.isBusy
            ? null
            : () => context.read<SyncBloc>().add(
                SyncManualPairingRequested(
                  address: _addressController.text,
                  deviceName: _deviceController.text,
                ),
              ),
        child: state.phase == SyncPhase.pairing
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Vincular con esta dirección'),
      ),
      _feedback(state),
    ],
  );

  Widget _feedback(SyncState state) {
    final text = state.error ?? state.message;
    if (text == null) return const SizedBox.shrink();
    final isError = state.error != null;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? const Color(0xFFB42318) : const Color(0xFF067647),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _scanQr(BuildContext context) async {
    final raw = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _QrScannerDialog(),
    );
    if (!context.mounted || raw == null) return;
    context.read<SyncBloc>().add(
      SyncQrPairingRequested(rawQr: raw, deviceName: _deviceController.text),
    );
  }

  Future<void> _confirmUnlink(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desvincular tablet'),
        content: const Text(
          'Se eliminará solamente la credencial de conexión. Los datos y cambios locales se conservarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    context.read<SyncBloc>().add(const SyncUnlinkRequested());
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _QrScannerDialog extends StatefulWidget {
  const _QrScannerDialog();

  @override
  State<_QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<_QrScannerDialog> {
  final _controller = MobileScannerController();
  bool _completed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'Escanear QR de vinculación',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            trailing: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  if (_completed) return;
                  final raw = capture.barcodes
                      .map((barcode) => barcode.rawValue)
                      .whereType<String>()
                      .firstOrNull;
                  if (raw == null || raw.isEmpty) return;
                  _completed = true;
                  Navigator.pop(context, raw);
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(detail, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F4F7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$label: $value',
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
