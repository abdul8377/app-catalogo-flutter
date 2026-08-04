part of '../../pages/dashboard_page.dart';

class _SyncPendingDialog extends StatelessWidget {
  const _SyncPendingDialog({required this.sync});

  final DashboardSincronizacion sync;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
              color: _ink,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _yellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_queue_outlined, color: _ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pendientes de sincronización',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${sync.totalPendiente} cambios protegidos localmente',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFB7BAC1),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusPill(
                    label: '${sync.pedidosPendientes} pedidos',
                    color: const Color(0xFF175CD3),
                  ),
                  _StatusPill(
                    label: '${sync.hojasPendientes} hojas',
                    color: const Color(0xFF6941C6),
                  ),
                  _StatusPill(
                    label: '${sync.operacionesEnCola} operaciones',
                    color: const Color(0xFFB54708),
                  ),
                  if (sync.errores > 0)
                    _StatusPill(
                      label: '${sync.errores} errores',
                      color: const Color(0xFFB42318),
                    ),
                ],
              ),
            ),
            Flexible(
              child: sync.pendientes.isEmpty
                  ? const _EmptyLine(
                      icon: Icons.cloud_done_outlined,
                      message: 'No hay detalles pendientes para mostrar.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                      itemCount: sync.pendientes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _SyncPendingTile(item: sync.pendientes[index]),
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'La app puede continuar trabajando sin conexión.',
                      style: GoogleFonts.inter(color: _muted, fontSize: 11),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _yellow,
                      foregroundColor: _ink,
                    ),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SyncPendingTile extends StatelessWidget {
  const _SyncPendingTile({required this.item});

  final DashboardSyncPendiente item;

  @override
  Widget build(BuildContext context) {
    final color = item.estado.toLowerCase() == 'error'
        ? const Color(0xFFB42318)
        : const Color(0xFFB54708);
    final icon = switch (item.tipo) {
      'pedido' => Icons.receipt_long_outlined,
      'hoja' => Icons.description_outlined,
      _ => Icons.sync_alt_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titulo,
                  style: GoogleFonts.inter(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.detalle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _muted,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
                if (item.error.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.error,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB42318),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd/MM HH:mm').format(item.fecha),
            style: GoogleFonts.inter(color: _muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF98A2B3), size: 32),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: _muted, fontSize: 11),
        ),
      ],
    ),
  );
}
