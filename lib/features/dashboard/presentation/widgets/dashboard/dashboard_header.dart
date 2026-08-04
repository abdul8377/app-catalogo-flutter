part of '../../pages/dashboard_page.dart';

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.state,
    required this.onRefresh,
    required this.onPeriodo,
  });

  final DashboardState state;
  final VoidCallback onRefresh;
  final ValueChanged<DashboardPeriodoTipo> onPeriodo;

  @override
  Widget build(BuildContext context) {
    final sync = state.data.sincronizacion;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final subtitle = state.filtro.periodo == DashboardPeriodoTipo.personalizado
        ? '${dateFormat.format(state.filtro.fechaInicio!)} – '
              '${dateFormat.format(state.filtro.fechaFin!)}'
        : 'Información operativa de ${state.filtro.etiqueta.toLowerCase()}';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _ink,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _yellow,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.space_dashboard_rounded, color: _ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard operativo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB7BAC1),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _SyncBadge(sync: sync, compact: constraints.maxWidth < 620),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Actualizar Dashboard',
                  onPressed: state.actualizando ? null : onRefresh,
                  icon: state.actualizando
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _yellow,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: DashboardPeriodoTipo.values.map((periodo) {
                final selected = state.filtro.periodo == periodo;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: ValueKey('dashboard-periodo-${periodo.name}'),
                    selected: selected,
                    onSelected: state.actualizando
                        ? null
                        : (_) => onPeriodo(periodo),
                    showCheckmark: false,
                    label: Text(_periodoLabel(periodo)),
                    labelStyle: GoogleFonts.inter(
                      color: selected ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedColor: _yellow,
                    backgroundColor: const Color(0xFF343434),
                    side: BorderSide(
                      color: selected ? _yellow : const Color(0xFF505050),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _periodoLabel(DashboardPeriodoTipo periodo) {
    switch (periodo) {
      case DashboardPeriodoTipo.hojaActiva:
        return 'Hoja activa';
      case DashboardPeriodoTipo.hoy:
        return 'Hoy';
      case DashboardPeriodoTipo.semana:
        return 'Esta semana';
      case DashboardPeriodoTipo.mes:
        return 'Este mes';
      case DashboardPeriodoTipo.personalizado:
        return 'Personalizado';
    }
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.sync, required this.compact});

  final DashboardSincronizacion sync;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ok = sync.sincronizado;
    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 38 : 132),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFF164B35) : const Color(0xFF5B4610),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.cloud_done_outlined : Icons.cloud_queue_outlined,
            size: 15,
            color: ok ? const Color(0xFF75E0A7) : _yellow,
          ),
          if (!compact) ...[
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                ok ? 'Al día' : '${sync.totalPendiente} pendientes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: ok ? const Color(0xFF75E0A7) : _yellow,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
