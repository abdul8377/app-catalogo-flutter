part of '../../pages/dashboard_page.dart';

class _ClientesCard extends StatelessWidget {
  const _ClientesCard({
    required this.items,
    required this.onViewAll,
    this.onView,
  });

  final List<DashboardCliente> items;
  final VoidCallback onViewAll;
  final ValueChanged<String>? onView;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    return _Panel(
      child: Column(
        children: [
          _SectionTitle(
            title: 'Clientes del periodo',
            subtitle: 'Actividad comercial más reciente',
            action: onViewAll,
            actionLabel: 'Gestionar',
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const _EmptyLine(
              icon: Icons.people_outline,
              message: 'No hay clientes asociados al periodo.',
            )
          else
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFF3C4),
                  foregroundColor: _ink,
                  child: Text(
                    item.nombre.isEmpty ? '?' : item.nombre[0].toUpperCase(),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                  ),
                ),
                title: Text(
                  item.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${item.pedidos} pedidos • '
                  '${currency.format(item.subtotalConocido)}\n'
                  '${item.direccion.isEmpty ? 'Sin dirección registrada' : item.direccion}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: _muted, fontSize: 10),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  if (onView != null) {
                    onView!(item.id);
                  } else {
                    onViewAll();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
