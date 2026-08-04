import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_destination.dart';
import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/entities/hoja_pedido.dart';
import '../../domain/repositories/hojas_pedido_repository.dart';
import '../bloc/hojas_pedido_bloc.dart';
import '../bloc/hojas_pedido_event.dart';
import '../bloc/hojas_pedido_state.dart';
import '../dialogs/completar_hoja_dialog.dart';
import '../dialogs/crear_hoja_dialog.dart';
import '../dialogs/hoja_pedido_detalle_dialog.dart';
import '../sections/hoja_activa_section.dart';
import '../sections/hojas_historial_section.dart';
import '../widgets/hojas_pedido_empty_state.dart';
import '../widgets/hojas_pedido_header.dart';
import '../widgets/hojas_pedido_loading_skeleton.dart';

class HojasPedidoPage extends StatelessWidget {
  const HojasPedidoPage({
    this.onNavigate,
    this.onOpenPedidos,
    this.initialHojaCodigo,
    this.sellerName = 'Alfonzo Esteban',
    super.key,
  });

  final ValueChanged<AppDestination>? onNavigate;
  final void Function(int tab, String hojaCodigo)? onOpenPedidos;
  final String? initialHojaCodigo;
  final String sellerName;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        HojasPedidoBloc(context.read<HojasPedidoRepository>())
          ..add(const HojasPedidoStarted()),
    child: _HojasPedidoPageView(
      onNavigate: onNavigate,
      onOpenPedidos: onOpenPedidos,
      initialHojaCodigo: initialHojaCodigo,
      sellerName: sellerName,
    ),
  );
}

class _HojasPedidoPageView extends StatefulWidget {
  const _HojasPedidoPageView({
    required this.onNavigate,
    required this.onOpenPedidos,
    required this.sellerName,
    this.initialHojaCodigo,
  });

  final ValueChanged<AppDestination>? onNavigate;
  final void Function(int tab, String hojaCodigo)? onOpenPedidos;
  final String? initialHojaCodigo;
  final String sellerName;

  @override
  State<_HojasPedidoPageView> createState() => _HojasPedidoPageViewState();
}

class _HojasPedidoPageViewState extends State<_HojasPedidoPageView> {
  bool _detalleInicialAbierto = false;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<HojasPedidoBloc, HojasPedidoState>(
        listenWhen: (previous, current) =>
            previous.error != current.error ||
            previous.message != current.message,
        listener: (context, state) {
          if (state.error != null) {
            AppNotice.error(context, state.error!);
          }
          if (state.message == 'Hoja creada correctamente.') {
            AppNotice.success(context, 'Hoja creada correctamente.');
          }
          if (state.message == 'Hoja completada correctamente.') {
            _mostrarResultadoCierre(context);
          }
        },
        builder: (context, state) {
          if (!_detalleInicialAbierto &&
              !state.loading &&
              widget.initialHojaCodigo != null) {
            final coincidencias = state.hojas.where(
              (hoja) => hoja.codigo == widget.initialHojaCodigo,
            );
            if (coincidencias.isNotEmpty) {
              _detalleInicialAbierto = true;
              final hoja = coincidencias.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) _verDetalle(context, hoja);
              });
            }
          }
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            appBar: HojasPedidoHeader(
              totalHojas: state.hojas.length,
              currentTab: state.currentTab,
              actualizando: state.actualizando,
              tieneHojaActiva: state.hojaActiva != null,
              onRefresh: () => context.read<HojasPedidoBloc>().add(
                const HojasPedidoRecargadas(),
              ),
              onTabChanged: (value) => context.read<HojasPedidoBloc>().add(
                HojasPedidoTabCambiado(value),
              ),
              onCrearHoja: () => _crearHoja(context, state),
            ),
            body: state.loading
                ? const HojasPedidoLoadingSkeleton()
                : IndexedStack(
                    index: state.currentTab,
                    children: [
                      _hojaActiva(context, state),
                      HojasHistorialSection(
                        hojas: state.historial,
                        busqueda: state.busqueda,
                        filtro: state.filtro,
                        orden: state.orden,
                        onBusquedaChanged: (value) => context
                            .read<HojasPedidoBloc>()
                            .add(HojasPedidoBusquedaCambiada(value)),
                        onFiltroChanged: (value) => context
                            .read<HojasPedidoBloc>()
                            .add(HojasPedidoFiltroCambiado(value)),
                        onOrdenChanged: (value) => context
                            .read<HojasPedidoBloc>()
                            .add(HojasPedidoOrdenCambiado(value)),
                        onLimpiarFiltros: () {
                          context.read<HojasPedidoBloc>()
                            ..add(const HojasPedidoBusquedaCambiada(''))
                            ..add(const HojasPedidoFiltroCambiado('Todas'));
                        },
                        onCrearHoja: () => _crearHoja(context, state),
                        onVerHoja: (hoja) => _verDetalle(context, hoja),
                        onVerPedidos: (hoja) =>
                            _abrirPedidos(context, 0, hoja.codigo),
                        onVerConsolidado: (hoja) =>
                            _abrirPedidos(context, 1, hoja.codigo),
                      ),
                    ],
                  ),
          );
        },
      );

  Widget _hojaActiva(BuildContext context, HojasPedidoState state) {
    final hoja = state.hojaActiva;
    if (hoja == null) {
      return HojasPedidoEmptyState(
        title: 'No existe una hoja de pedido activa',
        message: 'Crea una hoja para comenzar a registrar nuevos pedidos.',
        actionLabel: 'Crear hoja',
        onAction: () => _crearHoja(context, state),
      );
    }
    return HojaActivaSection(
      hoja: hoja,
      onVerDetalle: () => _verDetalle(context, hoja),
      onVerPedidos: () => _abrirPedidos(context, 0, hoja.codigo),
      onVerConsolidado: () => _abrirPedidos(context, 1, hoja.codigo),
      onPreparacionCarga: () => _abrirPedidos(context, 2, hoja.codigo),
      onCompletar: () => _completarHoja(context, hoja),
    );
  }

  Future<void> _crearHoja(BuildContext context, HojasPedidoState state) async {
    if (state.hojaActiva != null || state.saving) return;
    final year = DateTime.now().year;
    final count = state.hojas
        .where((hoja) => hoja.fechaApertura.year == year)
        .length;
    final result = await CrearHojaDialog.show(
      context,
      codigoSugerido: 'HP-$year-${(count + 1).toString().padLeft(3, '0')}',
      vendedorInicial: widget.sellerName,
    );
    if (!context.mounted || result == null) return;
    context.read<HojasPedidoBloc>().add(
      HojasPedidoCreada(
        vendedor: result.vendedor,
        referencia: result.referencia,
        observacion: result.observacion,
      ),
    );
  }

  Future<void> _completarHoja(BuildContext context, HojaPedido hoja) async {
    final observacion = await CompletarHojaDialog.show(context, hoja);
    if (!context.mounted || observacion == null) return;
    context.read<HojasPedidoBloc>().add(
      HojasPedidoCompletada(
        hojaId: hoja.id,
        usuario: hoja.vendedor,
        observacion: observacion,
      ),
    );
  }

  Future<void> _verDetalle(BuildContext context, HojaPedido hoja) =>
      HojaPedidoDetalleDialog.show(
        context,
        hoja: hoja,
        onVerPedidos: () => _abrirPedidos(context, 0, hoja.codigo),
        onGestionOperativa: () => _abrirPedidos(context, 2, hoja.codigo),
        onCompletar: (value) => _completarHoja(context, value),
      );

  void _abrirPedidos(BuildContext context, int tab, String hojaCodigo) {
    if (widget.onOpenPedidos != null) {
      widget.onOpenPedidos!(tab, hojaCodigo);
      return;
    }
    if (widget.onNavigate != null) {
      widget.onNavigate!(AppDestination.pedidos);
      return;
    }
    AppNotice.info(context, 'Abre el módulo Pedidos para continuar.');
  }

  Future<void> _mostrarResultadoCierre(BuildContext context) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 42),
        title: const Text('Hoja completada correctamente'),
        content: const Text(
          'La hoja pasó al historial y dejó de formar parte del flujo operativo activo.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'cerrar'),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'historial'),
            child: const Text('Ver historial'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'crear'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFC500),
              foregroundColor: Colors.black,
            ),
            child: const Text('Crear nueva hoja'),
          ),
        ],
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'historial') {
      context.read<HojasPedidoBloc>().add(const HojasPedidoTabCambiado(1));
    } else if (action == 'crear') {
      await _crearHoja(context, context.read<HojasPedidoBloc>().state);
    }
  }
}
