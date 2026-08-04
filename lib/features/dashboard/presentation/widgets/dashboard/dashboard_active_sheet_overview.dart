part of '../../pages/dashboard_page.dart';

class _HojaActivaCard extends StatelessWidget {
  const _HojaActivaCard({
    required this.hoja,
    required this.onViewSheet,
    required this.onViewOrders,
    required this.onManageSheets,
  });

  final DashboardHojaActiva? hoja;
  final VoidCallback onViewSheet;
  final VoidCallback onViewOrders;
  final VoidCallback onManageSheets;

  @override
  Widget build(BuildContext context) {
    if (hoja == null) {
      return _Panel(
        child: Column(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 44,
              color: Color(0xFF98A2B3),
            ),
            const SizedBox(height: 10),
            Text(
              'No existe una hoja de pedido activa',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Crea una hoja para registrar pedidos y medir la operación.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onManageSheets,
              style: FilledButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _ink,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Gestionar hojas'),
            ),
          ],
        ),
      );
    }
    final currency = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final duration = DateTime.now().difference(hoja!.fecha).inDays;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Hoja activa',
            subtitle: 'Responsable: ${hoja!.vendedor}',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  hoja!.codigo,
                  style: GoogleFonts.inter(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(label: hoja!.estado, color: const Color(0xFF067647)),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Iniciada ${DateFormat('dd/MM/yyyy, HH:mm').format(hoja!.fecha)}'
            ' • ${duration == 0 ? 'hoy' : '$duration días activa'}',
            style: GoogleFonts.inter(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniMetric('${hoja!.pedidos}', 'Pedidos'),
              _MiniMetric('${hoja!.clientes}', 'Clientes'),
              _MiniMetric('${hoja!.productos}', 'Productos'),
            ],
          ),
          const Divider(height: 26),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total conocido',
                      style: GoogleFonts.inter(color: _muted, fontSize: 11),
                    ),
                    Text(
                      currency.format(hoja!.subtotal),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (hoja!.pendientesPrecio > 0)
                _StatusPill(
                  label: '${hoja!.pendientesPrecio} sin valorizar',
                  color: const Color(0xFFB54708),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onViewSheet,
                  style: FilledButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: _ink,
                  ),
                  child: const Text('Ver hoja'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewOrders,
                  style: OutlinedButton.styleFrom(foregroundColor: _ink),
                  child: const Text('Ver pedidos'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          Text(label, style: GoogleFonts.inter(color: _muted, fontSize: 10)),
        ],
      ),
    ),
  );
}
