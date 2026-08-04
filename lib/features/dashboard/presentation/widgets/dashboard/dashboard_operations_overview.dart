part of '../../pages/dashboard_page.dart';

class _ProgresoOperativoCard extends StatelessWidget {
  const _ProgresoOperativoCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final total = data.totalPedidos;
    final valorizados = (total - data.pedidosPendientesValorizar).clamp(
      0,
      total,
    );
    final valorizacion = total == 0 ? 0.0 : valorizados / total;
    final preparacion = data.progresoPreparacion;

    return _Panel(
      child: Column(
        children: [
          const _SectionTitle(
            title: 'Progreso operativo',
            subtitle: 'Lectura rápida del avance comercial y físico',
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 18,
            children: [
              _RadialMetric(
                label: 'Valorizados',
                detail: '$valorizados de $total pedidos',
                progress: valorizacion,
                color: const Color(0xFF2E90FA),
                icon: Icons.price_check_rounded,
              ),
              _RadialMetric(
                label: 'Preparación',
                detail:
                    '${data.presentacionesPreparadas} de '
                    '${data.presentacionesRequeridas} presentaciones',
                progress: preparacion,
                color: const Color(0xFFF79009),
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
          const Divider(height: 30),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _StageMetric(
                value: data.pedidosListosCargar,
                label: 'Listos para carga',
                icon: Icons.inventory_outlined,
                color: const Color(0xFF087E8B),
              ),
              _StageMetric(
                value: data.pedidosCargados,
                label: 'Cargados',
                icon: Icons.local_shipping_outlined,
                color: const Color(0xFF175CD3),
              ),
              _StageMetric(
                value: data.pedidosEntregados,
                label: 'Entregados',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF067647),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadialMetric extends StatelessWidget {
  const _RadialMetric({
    required this.label,
    required this.detail,
    required this.progress,
    required this.color,
    required this.icon,
  });

  final String label;
  final String detail;
  final double progress;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: 170,
      child: Column(
        children: [
          SizedBox.square(
            dimension: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: 104,
                  child: CircularProgressIndicator(
                    value: normalized,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: const Color(0xFFF0F1F3),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 3),
                    Text(
                      '${(normalized * 100).round()}%',
                      style: GoogleFonts.inter(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: _muted, fontSize: 10, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _StageMetric extends StatelessWidget {
  const _StageMetric({
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
    width: 142,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.18)),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: _ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
