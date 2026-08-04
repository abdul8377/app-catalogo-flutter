part of '../../pages/dashboard_page.dart';

class _PedidosEstadoCard extends StatelessWidget {
  const _PedidosEstadoCard({
    required this.total,
    required this.estados,
    required this.onViewOrders,
  });

  final int total;
  final Map<String, int> estados;
  final VoidCallback onViewOrders;

  static const _colors = {
    'Pendiente': Color(0xFFFDB022),
    'En proceso': Color(0xFF2E90FA),
    'Listo para entregar': Color(0xFF06AED4),
    'Entregado': Color(0xFF12B76A),
    'Cancelado': Color(0xFFF04438),
  };

  @override
  Widget build(BuildContext context) {
    final slices = estados.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => _DonutSlice(
            value: entry.value,
            color: _colors[entry.key] ?? _muted,
          ),
        )
        .toList();

    final chart = SizedBox.square(
      dimension: 168,
      child: CustomPaint(
        painter: _DonutPainter(slices),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: GoogleFonts.inter(
                  color: _ink,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                total == 1 ? 'pedido' : 'pedidos',
                style: GoogleFonts.inter(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );

    final legend = Column(
      children: estados.entries.map((entry) {
        final percentage = total == 0 ? 0 : (entry.value / total * 100).round();
        final color = _colors[entry.key] ?? _muted;
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${entry.value}',
                style: GoogleFonts.inter(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 7),
              SizedBox(
                width: 34,
                child: Text(
                  '$percentage%',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(color: _muted, fontSize: 10),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    return _Panel(
      child: Column(
        children: [
          _SectionTitle(
            title: 'Pedidos por estado',
            subtitle: 'Distribución del periodo seleccionado',
            action: onViewOrders,
            actionLabel: 'Ver pedidos',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 520) {
                return Row(
                  children: [
                    chart,
                    const SizedBox(width: 22),
                    Expanded(child: legend),
                  ],
                );
              }
              return Column(
                children: [chart, const SizedBox(height: 18), legend],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DonutSlice {
  const _DonutSlice({required this.value, required this.color});

  final int value;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.slices);

  final List<_DonutSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.12;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final background = Paint()
      ..color = const Color(0xFFF0F1F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, background);

    final total = slices.fold<int>(0, (sum, item) => sum + item.value);
    if (total <= 0) return;

    var start = -math.pi / 2;
    const gap = 0.035;
    for (final slice in slices) {
      final sweep = math.pi * 2 * slice.value / total;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      final drawableSweep = (sweep - gap).clamp(0.0, math.pi * 2);
      canvas.drawArc(arcRect, start, drawableSweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
