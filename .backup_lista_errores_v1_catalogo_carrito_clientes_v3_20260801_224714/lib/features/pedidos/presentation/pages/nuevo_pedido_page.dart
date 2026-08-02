import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../../../catalogo/presentation/bloc/catalogo_state.dart';
import '../../../catalogo/presentation/widgets/filtros_catalogo.dart';
import '../../../catalogo/presentation/widgets/producto_card.dart';
import '../../../catalogo/presentation/widgets/producto_detalle_dialog.dart';
import '../../domain/entities/pedido.dart';
import '../../domain/repositories/pedidos_repository.dart';
import '../bloc/pedidos_bloc.dart';
import '../bloc/pedidos_event.dart';
import '../bloc/pedidos_state.dart';
import '../widgets/agregar_producto_dialog.dart';
import '../widgets/confirmar_pedido_dialog.dart';

class NuevoPedidoPage extends StatelessWidget {
  const NuevoPedidoPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PedidosBloc(
      context.read<CatalogoRepository>(),
      context.read<PedidosRepository>(),
    )..add(const PedidosStarted()),
    child: const _NuevoPedidoView(),
  );
}

class _NuevoPedidoView extends StatefulWidget {
  const _NuevoPedidoView();

  @override
  State<_NuevoPedidoView> createState() => _NuevoPedidoViewState();
}

class _NuevoPedidoViewState extends State<_NuevoPedidoView> {
  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  @override
  Widget build(BuildContext context) => BlocBuilder<PedidosBloc, PedidosState>(
    builder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuevo pedido',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              state.hojaActiva == null
                  ? 'Sin hoja activa'
                  : 'Hoja activa: ${state.hojaActiva!.codigo}',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: darkColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: state.vistaGrilla ? 'Ver como lista' : 'Ver como grilla',
            onPressed: () => context.read<PedidosBloc>().add(
              PedidosVistaCambiada(!state.vistaGrilla),
            ),
            icon: Icon(
              state.vistaGrilla ? Icons.view_list : Icons.grid_view,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (state.hojaActiva == null) const _SinHojaBanner(),
                FiltrosCatalogo(
                  state: _catalogoState(state),
                  modoPedido: true,
                  onBusquedaCambiada: (value) => context
                      .read<PedidosBloc>()
                      .add(PedidosBusquedaCambiada(value)),
                  onFiltroRapido: (value) => context.read<PedidosBloc>().add(
                    PedidosFiltroRapidoCatalogoCambiado(value),
                  ),
                  onFiltrosAplicados: (value) => context
                      .read<PedidosBloc>()
                      .add(PedidosFiltrosCatalogoAplicados(value)),
                  onFiltrosLimpiados: () => context.read<PedidosBloc>().add(
                    const PedidosFiltrosLimpiados(),
                  ),
                ),
                Expanded(child: _productos(state)),
              ],
            ),
      bottomNavigationBar: state.loading
          ? null
          : _CarritoBar(
              state: state,
              onVerCarrito: state.carrito.isEmpty
                  ? null
                  : () => _revisarCarrito(context),
            ),
    ),
  );

  CatalogoState _catalogoState(PedidosState state) => CatalogoState(
    loading: state.loading,
    actualizando: state.guardando,
    busqueda: state.busqueda,
    filtrosRapidos: state.filtrosRapidos,
    filtros: state.catalogoFiltros,
    vistaGrilla: state.vistaGrilla,
    productos: state.productos,
    productosFiltrados: state.productosFiltrados,
    error: state.error,
  );

  Widget _productos(PedidosState state) {
    final productos = state.productosFiltrados;
    if (productos.isEmpty) {
      return Center(
        child: Text(
          'No hay productos disponibles',
          style: GoogleFonts.inter(color: const Color(0xFF757575)),
        ),
      );
    }
    if (!state.vistaGrilla) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: productos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => ProductoCard(
          producto: productos[index],
          isGrid: false,
          onVerDetalle: () => _verDetalle(context, productos[index].id),
          onAgregar: () => _agregar(context, productos[index].id),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: constraints.maxWidth < 500 ? 500 : 360,
          mainAxisExtent: constraints.maxWidth < 500 ? 560 : 580,
          crossAxisSpacing: 13,
          mainAxisSpacing: 13,
        ),
        itemCount: productos.length,
        itemBuilder: (context, index) => ProductoCard(
          producto: productos[index],
          isGrid: true,
          onVerDetalle: () => _verDetalle(context, productos[index].id),
          onAgregar: () => _agregar(context, productos[index].id),
        ),
      ),
    );
  }

  Future<void> _agregar(BuildContext context, String id) async {
    final item = await AgregarProductoDialog.show(context, productoId: id);
    if (item == null || !context.mounted) return;
    context.read<PedidosBloc>().add(PedidoProductoAgregado(item));
    AppNotice.success(
      context,
      'Producto agregado al pedido',
      actionLabel: 'Ver carrito',
      onAction: () => _revisarCarrito(context),
    );
  }

  Future<void> _verDetalle(BuildContext context, String id) async {
    await ProductoDetalleDialog.show(
      context,
      productoId: id,
      onAgregar: (_) => _agregar(context, id),
    );
  }

  Future<void> _revisarCarrito(BuildContext context) async {
    final confirmado = await ConfirmarPedidoDialog.show(context);
    if (!confirmado || !context.mounted) return;
    final resultado = context.read<PedidosBloc>().state.resultado;
    if (resultado != null) await _mostrarResultado(context, resultado);
  }

  Future<void> _mostrarResultado(
    BuildContext context,
    PedidoRegistrado resultado,
  ) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const CircleAvatar(
        radius: 28,
        backgroundColor: Color(0xFFE8F5E9),
        child: Icon(Icons.check, color: Color(0xFF2E7D32), size: 34),
      ),
      title: const Text('Pedido registrado correctamente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Código: ${resultado.codigo}'),
          Text('Cliente: ${resultado.cliente}'),
          Text('Estado: ${resultado.estado}'),
          Text('Hoja: ${resultado.hojaCodigo}'),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          onPressed: () {
            context.read<PedidosBloc>().add(const PedidoNuevoSolicitado());
            Navigator.pop(dialogContext);
          },
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Nuevo pedido'),
        ),
      ],
    ),
  );
}

class _CarritoBar extends StatelessWidget {
  const _CarritoBar({required this.state, required this.onVerCarrito});

  final PedidosState state;
  final VoidCallback? onVerCarrito;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE1E5EA))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC500),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.black,
                  size: 24,
                ),
                if (state.cantidadPresentaciones > 0)
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFB42318),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${state.cantidadPresentaciones}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.carrito.isEmpty
                      ? 'Carrito vacío'
                      : '${state.lineasCarrito} '
                            '${state.lineasCarrito == 1 ? 'producto' : 'productos'}'
                            ' · ${state.cantidadPresentaciones} '
                            '${state.cantidadPresentaciones == 1 ? 'presentación' : 'presentaciones'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.totalParcial
                      ? 'Total pendiente · ${state.lineasSinPrecio} '
                            '${state.lineasSinPrecio == 1 ? 'línea por cotizar' : 'líneas por cotizar'}'
                      : 'Total: S/ ${state.subtotalConocido.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: state.totalParcial
                        ? const Color(0xFFB54708)
                        : const Color(0xFF1F1F1F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            key: const Key('revisar_carrito'),
            onPressed: onVerCarrito,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: const Text('Revisar'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFC500),
              foregroundColor: Colors.black,
              disabledBackgroundColor: const Color(0xFFE0E0E0),
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SinHojaBanner extends StatelessWidget {
  const _SinHojaBanner();

  @override
  Widget build(BuildContext context) => MaterialBanner(
    leading: const Icon(Icons.warning_amber, color: Color(0xFFE65100)),
    content: const Text('No existe una hoja de pedido activa.'),
    actions: [
      TextButton(
        onPressed: () =>
            context.read<PedidosBloc>().add(const PedidoHojaActivaCreada()),
        child: const Text('Crear hoja'),
      ),
    ],
  );
}
