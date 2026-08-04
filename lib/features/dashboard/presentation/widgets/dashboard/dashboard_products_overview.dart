part of '../../pages/dashboard_page.dart';

class _ProductosTopCard extends StatelessWidget {
  const _ProductosTopCard({required this.items, required this.onView});

  final List<DashboardProductoTop> items;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      children: [
        _SectionTitle(
          title: 'Productos más solicitados',
          subtitle: 'Agrupados por la presentación realmente pedida',
          action: onView,
          actionLabel: 'Consolidado',
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const _EmptyLine(
            icon: Icons.inventory_2_outlined,
            message: 'No hay productos en este periodo.',
          )
        else
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: entry.key == 0
                          ? const Color(0xFFFFF3C4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: GoogleFonts.inter(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.codigo} • ${item.marca} • '
                          '${item.pedidos} pedidos',
                          style: GoogleFonts.inter(color: _muted, fontSize: 10),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _QuantityTag(
                              label:
                                  '${item.cantidadRequerida} × '
                                  '${item.presentacion}',
                              color: const Color(0xFF175CD3),
                            ),
                            _QuantityTag(
                              label: '${item.cantidadPreparada} preparadas',
                              color: const Color(0xFF067647),
                            ),
                            if (item.cantidadPendiente > 0)
                              _QuantityTag(
                                label: '${item.cantidadPendiente} pendientes',
                                color: const Color(0xFFB54708),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    ),
  );
}

class _QuantityTag extends StatelessWidget {
  const _QuantityTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
