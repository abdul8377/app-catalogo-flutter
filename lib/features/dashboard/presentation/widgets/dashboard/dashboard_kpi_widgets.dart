part of '../../pages/dashboard_page.dart';

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data, required this.onTap});

  final DashboardData data;
  final ValueChanged<_KpiType> onTap;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final items = [
      _Kpi(
        _KpiType.pedidos,
        '${data.totalPedidos}',
        'Pedidos',
        Icons.receipt_long_outlined,
        const Color(0xFF175CD3),
      ),
      _Kpi(
        _KpiType.subtotal,
        currency.format(data.subtotalConocido),
        'Total conocido',
        Icons.payments_outlined,
        const Color(0xFF067647),
      ),
      _Kpi(
        _KpiType.clientes,
        '${data.totalClientes}',
        'Clientes atendidos',
        Icons.groups_2_outlined,
        const Color(0xFF6941C6),
      ),
      _Kpi(
        _KpiType.sinValorizar,
        '${data.pedidosPendientesValorizar}',
        'Sin valorizar',
        Icons.price_change_outlined,
        const Color(0xFFB54708),
      ),
      _Kpi(
        _KpiType.preparacion,
        '${(data.progresoPreparacion * 100).round()}%',
        'Preparación de presentaciones',
        Icons.inventory_2_outlined,
        const Color(0xFF026AA2),
      ),
      _Kpi(
        _KpiType.cargados,
        '${data.pedidosCargados}',
        'Pedidos cargados',
        Icons.local_shipping_outlined,
        const Color(0xFF344054),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 230,
          mainAxisExtent: 126,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, index) {
          final item = items[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              key: ValueKey('dashboard-kpi-${item.type.name}'),
              onTap: () => onTap(item.type),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 19, color: item.color),
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.value,
                        style: GoogleFonts.inter(
                          color: _ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Kpi {
  const _Kpi(this.type, this.value, this.label, this.icon, this.color);

  final _KpiType type;
  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 900) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          ),
        );
      }
      return Column(children: [left, const SizedBox(height: 16), right]);
    },
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: const Color(0x14101828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEAECF0)),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 4,
        height: 22,
        decoration: BoxDecoration(
          color: _yellow,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: GoogleFonts.inter(color: _muted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: action,
          style: TextButton.styleFrom(foregroundColor: _ink),
          child: Text(
            actionLabel ?? 'Ver más',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
    ],
  );
}
