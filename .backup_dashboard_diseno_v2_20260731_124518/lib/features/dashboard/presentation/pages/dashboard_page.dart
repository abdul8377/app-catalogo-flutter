import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

const _yellow = Color(0xFFFFC500);
const _ink = Color(0xFF1F1F1F);
const _muted = Color(0xFF667085);
const _background = Color(0xFFF5F6F8);

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    this.onNavigate,
    this.onOpenPedidos,
    this.onOpenHoja,
    this.onOpenCliente,
    super.key,
  });

  final ValueChanged<int>? onNavigate;
  final void Function(int tab, String hojaCodigo)? onOpenPedidos;
  final ValueChanged<String>? onOpenHoja;
  final ValueChanged<String>? onOpenCliente;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        DashboardBloc(context.read<DashboardRepository>())
          ..add(const DashboardStarted()),
    child: _DashboardView(
      onNavigate: onNavigate,
      onOpenPedidos: onOpenPedidos,
      onOpenHoja: onOpenHoja,
      onOpenCliente: onOpenCliente,
    ),
  );
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    this.onNavigate,
    this.onOpenPedidos,
    this.onOpenHoja,
    this.onOpenCliente,
  });

  final ValueChanged<int>? onNavigate;
  final void Function(int tab, String hojaCodigo)? onOpenPedidos;
  final ValueChanged<String>? onOpenHoja;
  final ValueChanged<String>? onOpenCliente;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardBloc, DashboardState>(
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.message != current.message,
      listener: (context, state) {
        final initialLoadFailed =
            state.error != null && state.data == const DashboardData.empty();
        if (initialLoadFailed) return;

        final text = state.error ?? state.message;
        if (text == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(text),
              backgroundColor: state.error == null
                  ? const Color(0xFF16794B)
                  : const Color(0xFFB42318),
            ),
          );
      },
      builder: (context, state) => Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              _DashboardHeader(
                state: state,
                onRefresh: () => context.read<DashboardBloc>().add(
                  const DashboardRefreshed(),
                ),
                onPeriodo: (periodo) =>
                    _seleccionarPeriodo(context, state, periodo),
              ),
              if (state.actualizando)
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: _yellow,
                  backgroundColor: Color(0xFFFFE899),
                ),
              Expanded(
                child: state.loading
                    ? const _DashboardSkeleton()
                    : state.error != null &&
                          state.data == const DashboardData.empty()
                    ? _ErrorState(
                        message: state.error!,
                        onRetry: () => context.read<DashboardBloc>().add(
                          const DashboardStarted(),
                        ),
                      )
                    : RefreshIndicator(
                        color: _ink,
                        backgroundColor: _yellow,
                        onRefresh: () async {
                          context.read<DashboardBloc>().add(
                            const DashboardRefreshed(),
                          );
                          await context.read<DashboardBloc>().stream.firstWhere(
                            (value) => !value.actualizando,
                          );
                        },
                        child: _DashboardBody(
                          state: state,
                          onNavigate: onNavigate,
                          onOpenPedidos: onOpenPedidos,
                          onOpenHoja: onOpenHoja,
                          onOpenCliente: onOpenCliente,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarPeriodo(
    BuildContext context,
    DashboardState state,
    DashboardPeriodoTipo periodo,
  ) async {
    if (periodo != DashboardPeriodoTipo.personalizado) {
      context.read<DashboardBloc>().add(
        DashboardPeriodoCambiado(DashboardFiltro(periodo: periodo)),
      );
      return;
    }
    final now = DateTime.now();
    final initialStart =
        state.filtro.fechaInicio ?? now.subtract(const Duration(days: 6));
    final initialEnd = state.filtro.fechaFin ?? now;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialStart.isAfter(now) ? now : initialStart,
        end: initialEnd.isAfter(now) ? now : initialEnd,
      ),
      helpText: 'Selecciona el periodo del Dashboard',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _yellow,
            onPrimary: Colors.black,
            surface: Colors.white,
            onSurface: _ink,
          ),
        ),
        child: child!,
      ),
    );
    if (!context.mounted || range == null) return;
    context.read<DashboardBloc>().add(
      DashboardPeriodoCambiado(
        DashboardFiltro(
          periodo: periodo,
          fechaInicio: range.start,
          fechaFin: range.end,
        ),
      ),
    );
  }
}

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

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    this.onNavigate,
    this.onOpenPedidos,
    this.onOpenHoja,
    this.onOpenCliente,
  });

  final DashboardState state;
  final ValueChanged<int>? onNavigate;
  final void Function(int tab, String hojaCodigo)? onOpenPedidos;
  final ValueChanged<String>? onOpenHoja;
  final ValueChanged<String>? onOpenCliente;

  DashboardData get data => state.data;

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('dashboard-body-list'),
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            children: [
              _KpiGrid(data: data, onTap: _onKpi),
              const SizedBox(height: 16),
              _ResponsivePair(
                left: _HojaActivaCard(
                  hoja: data.hojaActiva,
                  onViewSheet: _verHoja,
                  onViewOrders: () => _abrirPedidos(0),
                  onManageSheets: () => onNavigate?.call(5),
                ),
                right: _PedidosEstadoCard(
                  total: data.totalPedidos,
                  estados: data.pedidosPorEstado,
                  onViewOrders: () => _abrirPedidos(0),
                ),
              ),
              const SizedBox(height: 16),
              _ResponsivePair(
                left: _ProgresoOperativoCard(data: data),
                right: _AtencionCard(
                  data: data,
                  onValorizacion: () => _abrirPedidos(0),
                  onPreparacion: () => _abrirPedidos(2),
                  onCarga: () => _abrirPedidos(2),
                  onSync: () => onNavigate?.call(4),
                ),
              ),
              const SizedBox(height: 16),
              _ResponsivePair(
                left: _ProductosTopCard(
                  items: data.productosTop,
                  onView: () => _abrirPedidos(1),
                ),
                right: _CotizacionesCard(
                  items: data.cotizaciones,
                  generadas: data.cotizacionesGeneradas,
                  borradores: data.cotizacionesBorradores,
                  onView: () => _abrirPedidos(0),
                ),
              ),
              const SizedBox(height: 16),
              _PedidosRecientesCard(
                items: data.pedidosRecientes,
                onView: () => _abrirPedidos(0),
              ),
              const SizedBox(height: 16),
              _ResponsivePair(
                left: _ClientesCard(
                  items: data.clientes,
                  onViewAll: () => onNavigate?.call(2),
                  onView: onOpenCliente,
                ),
                right: _ActividadCard(items: data.actividad),
              ),
              const SizedBox(height: 16),
              _ResponsivePair(
                left: _FaltantesCard(
                  data: data,
                  onView: () => _abrirPedidos(1),
                ),
                right: _CargaEntregaCard(
                  data: data,
                  procesando: state.procesando,
                  onRegister: (pedido) => _registrarCarga(context, pedido),
                  onView: () => _abrirPedidos(2),
                ),
              ),
              const SizedBox(height: 16),
              _SyncCard(
                sync: data.sincronizacion,
                updatedAt: state.ultimaActualizacion,
                onRefresh: () => context.read<DashboardBloc>().add(
                  const DashboardRefreshed(),
                ),
                onViewPending: () => onNavigate?.call(4),
              ),
              const SizedBox(height: 10),
              Text(
                'Última actualización local: '
                '${DateFormat('dd/MM/yyyy HH:mm').format(state.ultimaActualizacion)}',
                style: GoogleFonts.inter(color: _muted, fontSize: 11),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ],
  );

  void _onKpi(_KpiType type) {
    switch (type) {
      case _KpiType.pedidos:
      case _KpiType.subtotal:
      case _KpiType.sinValorizar:
        _abrirPedidos(0);
      case _KpiType.clientes:
        onNavigate?.call(2);
      case _KpiType.preparacion:
      case _KpiType.cargados:
        _abrirPedidos(2);
    }
  }

  void _abrirPedidos(int tab) {
    final codigo = data.hojaActiva?.codigo;
    if (codigo != null && onOpenPedidos != null) {
      onOpenPedidos!(tab, codigo);
    } else {
      onNavigate?.call(4);
    }
  }

  void _verHoja() {
    final codigo = data.hojaActiva?.codigo;
    if (codigo != null && onOpenHoja != null) {
      onOpenHoja!(codigo);
    } else {
      onNavigate?.call(5);
    }
  }

  Future<void> _registrarCarga(
    BuildContext context,
    DashboardPedidoListo pedido,
  ) async {
    final result = await showDialog<_CargaInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RegistrarCargaDialog(pedido: pedido),
    );
    if (!context.mounted || result == null) return;
    context.read<DashboardBloc>().add(
      DashboardPedidoCargado(
        pedidoId: pedido.id,
        paquetes: result.paquetes,
        observacion: result.observacion,
      ),
    );
  }
}

enum _KpiType {
  pedidos,
  subtotal,
  clientes,
  sinValorizar,
  preparacion,
  cargados,
}

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
        'Preparación física',
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

class _PedidosEstadoCard extends StatelessWidget {
  const _PedidosEstadoCard({
    required this.total,
    required this.estados,
    required this.onViewOrders,
  });

  final int total;
  final Map<String, int> estados;
  final VoidCallback onViewOrders;

  @override
  Widget build(BuildContext context) {
    const colors = {
      'Pendiente': Color(0xFFFDB022),
      'En proceso': Color(0xFF2E90FA),
      'Listo para entregar': Color(0xFF06AED4),
      'Entregado': Color(0xFF12B76A),
      'Cancelado': Color(0xFFF04438),
    };
    final maxValue = estados.values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    return _Panel(
      child: Column(
        children: [
          _SectionTitle(
            title: 'Pedidos por estado',
            subtitle: '$total pedidos en el periodo',
            action: onViewOrders,
            actionLabel: 'Ver pedidos',
          ),
          const SizedBox(height: 14),
          ...estados.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[entry.key],
                        ),
                      ),
                      const SizedBox(width: 7),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: maxValue == 0 ? 0 : entry.value / maxValue,
                      minHeight: 7,
                      color: colors[entry.key],
                      backgroundColor: const Color(0xFFF0F1F3),
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
}

class _ProgresoOperativoCard extends StatelessWidget {
  const _ProgresoOperativoCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final total = data.totalPedidos;
    return _Panel(
      child: Column(
        children: [
          const _SectionTitle(
            title: 'Progreso operativo',
            subtitle: 'Avance real de valorización, preparación y entrega',
          ),
          const SizedBox(height: 15),
          _ProgressRow(
            label: 'Valorización',
            detail:
                '${(total - data.pedidosPendientesValorizar).clamp(0, total)} de $total',
            progress: total == 0
                ? 0
                : (total - data.pedidosPendientesValorizar) / total,
            color: const Color(0xFF2E90FA),
          ),
          _ProgressRow(
            label: 'Preparación física',
            detail:
                '${data.unidadesPreparadas} de ${data.unidadesRequeridas} UND',
            progress: data.progresoPreparacion,
            color: const Color(0xFFF79009),
          ),
          _ProgressRow(
            label: 'Listos para carga',
            detail: '${data.pedidosListosCargar} de $total',
            progress: total == 0 ? 0 : data.pedidosListosCargar / total,
            color: const Color(0xFF06AED4),
          ),
          _ProgressRow(
            label: 'Cargados',
            detail: '${data.pedidosCargados} de $total',
            progress: total == 0 ? 0 : data.pedidosCargados / total,
            color: const Color(0xFF667085),
          ),
          _ProgressRow(
            label: 'Entregados',
            detail: '${data.pedidosEntregados} de $total',
            progress: total == 0 ? 0 : data.pedidosEntregados / total,
            color: const Color(0xFF12B76A),
            bottomPadding: 0,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.detail,
    required this.progress,
    required this.color,
    this.bottomPadding = 13,
  });

  final String label;
  final String detail;
  final double progress;
  final Color color;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: bottomPadding),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$detail • ${(progress.clamp(0, 1) * 100).round()}%',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 7,
            color: color,
            backgroundColor: const Color(0xFFF0F1F3),
          ),
        ),
      ],
    ),
  );
}

class _AtencionCard extends StatelessWidget {
  const _AtencionCard({
    required this.data,
    required this.onValorizacion,
    required this.onPreparacion,
    required this.onCarga,
    required this.onSync,
  });

  final DashboardData data;
  final VoidCallback onValorizacion;
  final VoidCallback onPreparacion;
  final VoidCallback onCarga;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final items = <_AlertItem>[
      if (data.pedidosPendientesValorizar > 0)
        _AlertItem(
          Icons.price_change_outlined,
          '${data.pedidosPendientesValorizar} pedidos requieren valorización',
          'Revisar',
          const Color(0xFFB54708),
          onValorizacion,
        ),
      if (data.pedidosPreparacionParcial > 0)
        _AlertItem(
          Icons.timelapse_rounded,
          '${data.pedidosPreparacionParcial} pedidos tienen preparación parcial',
          'Ver avance',
          const Color(0xFF175CD3),
          onPreparacion,
        ),
      if (data.pedidosListosCargar > 0)
        _AlertItem(
          Icons.local_shipping_outlined,
          '${data.pedidosListosCargar} pedidos están listos para cargar',
          'Preparar carga',
          const Color(0xFF087E8B),
          onCarga,
        ),
      if (!data.sincronizacion.sincronizado)
        _AlertItem(
          Icons.cloud_queue_outlined,
          '${data.sincronizacion.totalPendiente} cambios esperan sincronización',
          'Revisar',
          const Color(0xFFB54708),
          onSync,
        ),
    ];
    return _Panel(
      child: Column(
        children: [
          const _SectionTitle(
            title: 'Requieren atención',
            subtitle: 'Prioridades detectadas automáticamente',
          ),
          const SizedBox(height: 13),
          if (items.isEmpty)
            const _AllGood()
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Material(
                  color: item.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(13),
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: Row(
                        children: [
                          Icon(item.icon, color: item.color, size: 20),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              item.label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.action,
                            style: GoogleFonts.inter(
                              color: item.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 17),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertItem {
  const _AlertItem(this.icon, this.label, this.action, this.color, this.onTap);

  final IconData icon;
  final String label;
  final String action;
  final Color color;
  final VoidCallback onTap;
}

class _AllGood extends StatelessWidget {
  const _AllGood();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF3),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF067647)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Todo está al día en el periodo seleccionado.',
            style: GoogleFonts.inter(
              color: const Color(0xFF067647),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

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
          subtitle: 'Cantidades convertidas a la unidad base',
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: entry.key == 0
                          ? const Color(0xFFFFF3C4)
                          : const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.codigo} • ${item.marca} • '
                          '${item.pedidos} pedidos',
                          style: GoogleFonts.inter(color: _muted, fontSize: 10),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: item.progreso,
                            minHeight: 6,
                            color: item.cantidadPendiente == 0
                                ? const Color(0xFF12B76A)
                                : _yellow,
                            backgroundColor: const Color(0xFFF0F1F3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.cantidadRequerida} ${item.unidadBase} '
                          'requeridas • ${item.cantidadPendiente} pendientes',
                          style: GoogleFonts.inter(color: _muted, fontSize: 10),
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
          subtitle: '${data.unidadesPendientes} unidades base por preparar',
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
                'Parciales',
                const Color(0xFF175CD3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...data.principalesFaltantes.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF79009),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${item.codigo} • ${item.pedidosAfectados} pedidos',
                          style: GoogleFonts.inter(color: _muted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.cantidadPendiente} ${item.unidadBase}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB42318),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.sync,
    required this.updatedAt,
    required this.onRefresh,
    required this.onViewPending,
  });

  final DashboardSincronizacion sync;
  final DateTime updatedAt;
  final VoidCallback onRefresh;
  final VoidCallback onViewPending;

  @override
  Widget build(BuildContext context) => _Panel(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sync.sincronizado
                  ? 'La información local está al día'
                  : 'Cambios protegidos en la tablet',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sync.sincronizado
                  ? 'No hay operaciones pendientes de sincronización.'
                  : 'La aplicación continúa funcionando offline. Los cambios '
                        'permanecen en cola hasta que el servicio remoto esté disponible.',
              style: GoogleFonts.inter(color: _muted, fontSize: 11),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: [
                _StatusPill(
                  label: '${sync.pedidosPendientes} pedidos',
                  color: const Color(0xFF175CD3),
                ),
                _StatusPill(
                  label: '${sync.hojasPendientes} hojas',
                  color: const Color(0xFF6941C6),
                ),
                _StatusPill(
                  label: '${sync.operacionesEnCola} en cola',
                  color: const Color(0xFFB54708),
                ),
                if (sync.errores > 0)
                  _StatusPill(
                    label: '${sync.errores} errores',
                    color: const Color(0xFFB42318),
                  ),
              ],
            ),
          ],
        );
        final actions = Wrap(
          spacing: 8,
          runSpacing: 7,
          children: [
            OutlinedButton.icon(
              onPressed: onViewPending,
              style: OutlinedButton.styleFrom(foregroundColor: _ink),
              icon: const Icon(Icons.list_alt_rounded, size: 18),
              label: const Text('Ver pendientes'),
            ),
            FilledButton.icon(
              onPressed: onRefresh,
              style: FilledButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _ink,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Actualizar estado'),
            ),
          ],
        );
        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      (sync.sincronizado
                              ? const Color(0xFF067647)
                              : const Color(0xFFB54708))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  sync.sincronizado
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_queue_outlined,
                  color: sync.sincronizado
                      ? const Color(0xFF067647)
                      : const Color(0xFFB54708),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(child: content),
              const SizedBox(width: 14),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Sincronización offline'),
            const SizedBox(height: 10),
            content,
            const SizedBox(height: 12),
            actions,
          ],
        );
      },
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF98A2B3), size: 32),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: _muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _RegistrarCargaDialog extends StatefulWidget {
  const _RegistrarCargaDialog({required this.pedido});

  final DashboardPedidoListo pedido;

  @override
  State<_RegistrarCargaDialog> createState() => _RegistrarCargaDialogState();
}

class _RegistrarCargaDialogState extends State<_RegistrarCargaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _paquetes = TextEditingController(text: '1');
  final _observacion = TextEditingController();

  @override
  void dispose() {
    _paquetes.dispose();
    _observacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    titlePadding: EdgeInsets.zero,
    contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
    actionsPadding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    title: Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _yellow,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.local_shipping_outlined, color: _ink),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrar carga',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.pedido.codigo,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB7BAC1),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    content: SizedBox(
      width: 430,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pedido.cliente,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              widget.pedido.direccion.isEmpty
                  ? 'Sin dirección registrada'
                  : widget.pedido.direccion,
              style: GoogleFonts.inter(color: _muted, fontSize: 11),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paquetes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad de paquetes *',
                helperText: 'Debe representar la carga física del pedido.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final cantidad = int.tryParse(value?.trim() ?? '');
                if (cantidad == null || cantidad <= 0) {
                  return 'Ingresa una cantidad mayor que cero.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _observacion,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observación',
                hintText: 'Ej. Carga revisada y sellada',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            _CargaInput(
              int.parse(_paquetes.text.trim()),
              _observacion.text.trim(),
            ),
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: _ink,
        ),
        icon: const Icon(Icons.check_rounded),
        label: const Text('Confirmar carga'),
      ),
    ],
  );
}

class _CargaInput {
  const _CargaInput(this.paquetes, this.observacion);

  final int paquetes;
  final String observacion;
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 230,
          mainAxisExtent: 126,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, _) => const _SkeletonBox(height: 126),
      ),
      const SizedBox(height: 16),
      const _SkeletonBox(height: 280),
      const SizedBox(height: 16),
      const _SkeletonBox(height: 240),
    ],
  );
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEAECF0)),
    ),
    padding: const EdgeInsets.all(18),
    child: Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: 130,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFFEAECF0),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight > 40
            ? constraints.maxHeight - 40
            : 0.0;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEECEB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.dashboard_customize_outlined,
                        size: 30,
                        color: Color(0xFFB42318),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pudimos preparar el Dashboard',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8DD),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: _yellow, width: 4),
                        ),
                      ),
                      child: Text(
                        'La información comercial sigue disponible en Pedidos, '
                        'Hojas de pedido y Clientes.',
                        style: GoogleFonts.inter(
                          color: _ink,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: _yellow,
                        foregroundColor: _ink,
                        minimumSize: const Size(170, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        'Reintentar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _estadoColor(String estado) {
  final value = estado.trim().toLowerCase();
  if (value == 'cancelado') return const Color(0xFFB42318);
  if (value == 'entregado') return const Color(0xFF067647);
  if (value.contains('listo')) return const Color(0xFF087E8B);
  if (value.contains('proceso')) return const Color(0xFF175CD3);
  return const Color(0xFFB54708);
}
