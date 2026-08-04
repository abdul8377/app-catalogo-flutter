part of '../../pages/dashboard_page.dart';

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.sync,
    required this.updatedAt,
    required this.onRefresh,
    required this.onViewPending,
  });

  final DashboardSincronizacion sync;
  final DateTime updatedAt;
  final VoidCallback onRefresh;
  final VoidCallback onViewPending;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final status = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        (sync.sincronizado
                                ? const Color(0xFF067647)
                                : const Color(0xFFB54708))
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    sync.sincronizado
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_queue_outlined,
                    color: sync.sincronizado
                        ? const Color(0xFF067647)
                        : const Color(0xFFB54708),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sincronización offline',
                        style: GoogleFonts.inter(
                          color: _ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sync.sincronizado
                            ? 'La información local está al día.'
                            : 'Los cambios permanecen protegidos en la tablet '
                                  'hasta recuperar conexión.',
                        style: GoogleFonts.inter(
                          color: _muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('dashboard-sync-pending'),
                  onPressed: onViewPending,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _yellow),
                  ),
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: const Text('Ver pendientes'),
                ),
                FilledButton.icon(
                  onPressed: onRefresh,
                  style: FilledButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: _ink,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Actualizar estado'),
                ),
              ],
            );

            if (constraints.maxWidth >= 720) {
              return Row(
                children: [
                  Expanded(child: status),
                  const SizedBox(width: 16),
                  actions,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [status, const SizedBox(height: 14), actions],
            );
          },
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _SyncMetric(
              value: sync.pedidosPendientes,
              label: 'Pedidos',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF175CD3),
            ),
            _SyncMetric(
              value: sync.hojasPendientes,
              label: 'Hojas',
              icon: Icons.description_outlined,
              color: const Color(0xFF6941C6),
            ),
            _SyncMetric(
              value: sync.operacionesEnCola,
              label: 'Operaciones',
              icon: Icons.sync_alt_rounded,
              color: const Color(0xFFB54708),
            ),
            if (sync.errores > 0)
              _SyncMetric(
                value: sync.errores,
                label: 'Con error',
                icon: Icons.error_outline_rounded,
                color: const Color(0xFFB42318),
              ),
          ],
        ),
      ],
    ),
  );
}

class _SyncMetric extends StatelessWidget {
  const _SyncMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 145,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 8),
        Text(
          '$value',
          style: GoogleFonts.inter(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: _ink,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
