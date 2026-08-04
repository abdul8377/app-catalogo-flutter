part of '../../pages/dashboard_page.dart';

class _ActividadCard extends StatelessWidget {
  const _ActividadCard({required this.items});

  final List<DashboardActividad> items;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      children: [
        const _SectionTitle(
          title: 'Actividad reciente',
          subtitle: 'Trazabilidad guardada localmente',
        ),
        const SizedBox(height: 13),
        if (items.isEmpty)
          const _EmptyLine(
            icon: Icons.history_toggle_off_outlined,
            message: 'Todavía no hay actividad registrada.',
          )
        else
          ...items.map(
            (item) => IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      DateFormat('HH:mm').format(item.fecha),
                      style: GoogleFonts.inter(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.tipo == 'cotizacion'
                              ? const Color(0xFF12B76A)
                              : _yellow,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 1,
                          color: const Color(0xFFEAECF0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.evento,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.detalle.trim().isNotEmpty)
                            Text(
                              item.detalle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _FaltantesCard extends StatelessWidget {
  const _FaltantesCard({required this.data, required this.onView});

  final DashboardData data;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      children: [
        _SectionTitle(
          title: 'Pendientes de preparación',
          subtitle:
              '${data.presentacionesPendientes} presentaciones por preparar',
          action: onView,
          actionLabel: 'Ver consolidado',
        ),
        const SizedBox(height: 10),
        if (data.principalesFaltantes.isEmpty)
          const _AllGood()
        else ...[
          Row(
            children: [
              _SummaryBox(
                '${data.productosPendientesPreparacion}',
                'Productos',
                const Color(0xFFB54708),
              ),
              const SizedBox(width: 8),
              _SummaryBox(
                '${data.pedidosPreparacionParcial}',
                'Pedidos parciales',
                const Color(0xFF175CD3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...data.principalesFaltantes.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFFB54708),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${item.codigo} • ${item.pedidosAfectados} pedidos',
                          style: GoogleFonts.inter(color: _muted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEAD5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${item.cantidadPendiente} × ${item.presentacion}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB42318),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
