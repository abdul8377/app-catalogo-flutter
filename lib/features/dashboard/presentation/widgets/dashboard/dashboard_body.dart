part of '../../pages/dashboard_page.dart';

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    this.onNavigate,
    this.onOpenPedidos,
    this.onOpenHoja,
    this.onOpenCliente,
  });

  final DashboardState state;
  final ValueChanged<AppDestination>? onNavigate;
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
                  onManageSheets: () =>
                      onNavigate?.call(AppDestination.hojasPedido),
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
                  onSync: () => _showSyncPending(context),
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
                  onViewAll: () => onNavigate?.call(AppDestination.clientes),
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
                onViewPending: () => _showSyncPending(context),
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
        onNavigate?.call(AppDestination.clientes);
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
      onNavigate?.call(AppDestination.pedidos);
    }
  }

  void _verHoja() {
    final codigo = data.hojaActiva?.codigo;
    if (codigo != null && onOpenHoja != null) {
      onOpenHoja!(codigo);
    } else {
      onNavigate?.call(AppDestination.hojasPedido);
    }
  }

  Future<void> _showSyncPending(BuildContext context) => showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    builder: (_) => _SyncPendingDialog(sync: data.sincronizacion),
  );

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
