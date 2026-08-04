part of '../../pages/dashboard_page.dart';

class _AtencionCard extends StatelessWidget {
  const _AtencionCard({
    required this.data,
    required this.onValorizacion,
    required this.onPreparacion,
    required this.onCarga,
    required this.onSync,
  });

  final DashboardData data;
  final VoidCallback onValorizacion;
  final VoidCallback onPreparacion;
  final VoidCallback onCarga;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final items = <_AlertItem>[
      if (data.pedidosPendientesValorizar > 0)
        _AlertItem(
          Icons.price_change_outlined,
          '${data.pedidosPendientesValorizar} pedidos requieren valorización',
          'Revisar',
          const Color(0xFFB54708),
          onValorizacion,
        ),
      if (data.pedidosPreparacionParcial > 0)
        _AlertItem(
          Icons.timelapse_rounded,
          '${data.pedidosPreparacionParcial} pedidos tienen preparación parcial',
          'Ver avance',
          const Color(0xFF175CD3),
          onPreparacion,
        ),
      if (data.pedidosListosCargar > 0)
        _AlertItem(
          Icons.local_shipping_outlined,
          '${data.pedidosListosCargar} pedidos están listos para cargar',
          'Preparar carga',
          const Color(0xFF087E8B),
          onCarga,
        ),
      if (!data.sincronizacion.sincronizado)
        _AlertItem(
          Icons.cloud_queue_outlined,
          '${data.sincronizacion.totalPendiente} cambios esperan sincronización',
          'Revisar',
          const Color(0xFFB54708),
          onSync,
        ),
    ];
    return _Panel(
      child: Column(
        children: [
          const _SectionTitle(
            title: 'Requieren atención',
            subtitle: 'Prioridades detectadas automáticamente',
          ),
          const SizedBox(height: 13),
          if (items.isEmpty)
            const _AllGood()
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Material(
                  color: item.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(13),
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: Row(
                        children: [
                          Icon(item.icon, color: item.color, size: 20),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              item.label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.action,
                            style: GoogleFonts.inter(
                              color: item.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 17),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertItem {
  const _AlertItem(this.icon, this.label, this.action, this.color, this.onTap);

  final IconData icon;
  final String label;
  final String action;
  final Color color;
  final VoidCallback onTap;
}

class _AllGood extends StatelessWidget {
  const _AllGood();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF3),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF067647)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Todo está al día en el periodo seleccionado.',
            style: GoogleFonts.inter(
              color: const Color(0xFF067647),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
