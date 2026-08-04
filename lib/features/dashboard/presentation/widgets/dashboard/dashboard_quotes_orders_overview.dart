part of '../../pages/dashboard_page.dart';

class _CotizacionesCard extends StatelessWidget {
  const _CotizacionesCard({
    required this.items,
    required this.generadas,
    required this.borradores,
    required this.onView,
  });

  final List<DashboardCotizacion> items;
  final int generadas;
  final int borradores;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    return _Panel(
      child: Column(
        children: [
          _SectionTitle(
            title: 'Cotizaciones',
            subtitle: 'Versiones guardadas en el periodo',
            action: onView,
            actionLabel: 'Ver pedidos',
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _StatusPill(
                  label: '$generadas generadas',
                  color: const Color(0xFF067647),
                ),
                _StatusPill(
                  label: '$borradores borradores',
                  color: const Color(0xFFB54708),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const _EmptyLine(
              icon: Icons.request_quote_outlined,
              message: 'No se guardaron cotizaciones en este periodo.',
            )
          else
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.esBorrador
                        ? const Color(0xFFFFFAEB)
                        : const Color(0xFFECFDF3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.tienePdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.description_outlined,
                    size: 19,
                    color: item.esBorrador
                        ? const Color(0xFFB54708)
                        : const Color(0xFF067647),
                  ),
                ),
                title: Text(
                  item.codigo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${item.cliente} • ${item.pedidoCodigo}\n'
                  '${DateFormat('dd/MM HH:mm').format(item.fecha)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: _muted, fontSize: 10),
                ),
                trailing: Text(
                  currency.format(item.total),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: onView,
              ),
            ),
        ],
      ),
    );
  }
}

class _PedidosRecientesCard extends StatelessWidget {
  const _PedidosRecientesCard({required this.items, required this.onView});

  final List<DashboardPedidoReciente> items;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    return _Panel(
      child: Column(
        children: [
          _SectionTitle(
            title: 'Pedidos recientes',
            subtitle: 'Últimos movimientos del periodo seleccionado',
            action: onView,
            actionLabel: 'Ver todos',
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const _EmptyLine(
              icon: Icons.receipt_long_outlined,
              message: 'No existen pedidos para mostrar.',
            )
          else
            ...items.map(
              (item) => InkWell(
                onTap: onView,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _estadoColor(
                            item.estado,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: _estadoColor(item.estado),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.codigo} • ${item.cliente}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.productos} productos • '
                              '${DateFormat('dd/MM HH:mm').format(item.fecha)}',
                              style: GoogleFonts.inter(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!item.sincronizado)
                        const Tooltip(
                          message: 'Pendiente de sincronización',
                          child: Icon(
                            Icons.cloud_queue_outlined,
                            size: 17,
                            color: Color(0xFFB54708),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.tienePrecioCompleto
                                ? currency.format(item.total)
                                : 'Precio pendiente',
                            style: GoogleFonts.inter(
                              color: item.tienePrecioCompleto
                                  ? _ink
                                  : const Color(0xFFB54708),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _StatusPill(
                            label: item.estado,
                            color: _estadoColor(item.estado),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
