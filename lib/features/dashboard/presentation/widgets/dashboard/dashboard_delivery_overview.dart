part of '../../pages/dashboard_page.dart';

class _CargaEntregaCard extends StatelessWidget {
  const _CargaEntregaCard({
    required this.data,
    required this.procesando,
    required this.onRegister,
    required this.onView,
  });

  final DashboardData data;
  final bool procesando;
  final ValueChanged<DashboardPedidoListo> onRegister;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      children: [
        _SectionTitle(
          title: 'Carga y entrega',
          subtitle: 'Pedidos preparados físicamente',
          action: onView,
          actionLabel: 'Operación',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _StatusPill(
              label: '${data.pedidosListosCargar} por cargar',
              color: const Color(0xFF087E8B),
            ),
            _StatusPill(
              label: '${data.pedidosCargados} cargados',
              color: const Color(0xFF175CD3),
            ),
            _StatusPill(
              label: '${data.pedidosEntregados} entregados',
              color: const Color(0xFF067647),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (data.pedidosListos.isEmpty)
          const _EmptyLine(
            icon: Icons.local_shipping_outlined,
            message: 'No hay pedidos pendientes de carga.',
          )
        else
          ...data.pedidosListos.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_outlined,
                      color: Color(0xFF175CD3),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.codigo} • ${item.cliente}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${item.productos} productos • '
                          '${item.direccion.isEmpty ? 'Sin dirección' : item.direccion}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: _muted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  FilledButton(
                    key: ValueKey('dashboard-load-${item.id}'),
                    onPressed: procesando ? null : () => onRegister(item),
                    style: FilledButton.styleFrom(
                      backgroundColor: _yellow,
                      foregroundColor: _ink,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Cargar'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
