import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/producto_consolidado.dart';
import '../bloc/productos_consolidados/productos_consolidados_bloc.dart';
import '../bloc/productos_consolidados/productos_consolidados_event.dart';
import '../bloc/productos_consolidados/productos_consolidados_state.dart';
import '../dialogs/consolidado_filtros_dialog.dart';
import '../dialogs/producto_distribucion_dialog.dart';
import '../dialogs/registrar_preparacion_producto_dialog.dart';
import '../widgets/consolidado_producto_card.dart';
import '../widgets/consolidado_resumen.dart';
import '../widgets/estados_vacios.dart';

class ProductosConsolidadosSection extends StatelessWidget {
  const ProductosConsolidadosSection({this.initialHojaCodigo, super.key});

  final String? initialHojaCodigo;

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ProductosConsolidadosBloc, ProductosConsolidadosState>(
    listenWhen: (previous, current) =>
        previous.error != current.error || previous.message != current.message,
    listener: (context, state) {
      final text = state.error ?? state.message;
      if (text == null) return;
      if (state.error != null) {
        AppNotice.error(context, text);
      } else {
        AppNotice.success(context, text);
      }
    },
    builder: (context, state) {
      if (state.loading) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFC500)),
        );
      }
      final productos = state.productosFiltrados;
      return Column(
        children: [
          ConsolidadoResumen(productos: productos),
          _Toolbar(state: state),
          if (state.hojaCodigo != null)
            _HojaActivaBanner(codigo: state.hojaCodigo!),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFFFC500),
              onRefresh: () async {
                context.read<ProductosConsolidadosBloc>().add(
                  const ProductosConsolidadosRecargados(),
                );
                await Future<void>.delayed(const Duration(milliseconds: 250));
              },
              child: productos.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 70),
                        EstadoVacioPedidos(
                          icon: Icons.inventory_2_outlined,
                          title: 'Sin productos para consolidar',
                          message:
                              'Los productos de los pedidos de la hoja '
                              'seleccionada aparecerán aquí conservando sus '
                              'presentaciones comerciales.',
                        ),
                      ],
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 1050) {
                          return ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: productos.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) =>
                                _card(context, productos[index], state.saving),
                          );
                        }
                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: (productos.length / 2).ceil(),
                          itemBuilder: (_, rowIndex) {
                            final first = rowIndex * 2;
                            final second = first + 1;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _card(
                                      context,
                                      productos[first],
                                      state.saving,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: second < productos.length
                                        ? _card(
                                            context,
                                            productos[second],
                                            state.saving,
                                          )
                                        : const SizedBox(),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      );
    },
  );

  Widget _card(
    BuildContext context,
    ProductoConsolidado producto,
    bool saving,
  ) => ConsolidadoProductoCard(
    producto: producto,
    onVerDistribucion: () async {
      final registrar = await ProductoDistribucionDialog.show(
        context,
        producto: producto,
      );
      if (registrar == true && context.mounted) {
        await _registrar(context, producto);
      }
    },
    onRegistrarPreparacion: saving ? null : () => _registrar(context, producto),
  );

  Future<void> _registrar(
    BuildContext context,
    ProductoConsolidado producto,
  ) async {
    final draft = await RegistrarPreparacionProductoDialog.show(
      context,
      producto: producto,
    );
    if (draft != null && context.mounted) {
      context.read<ProductosConsolidadosBloc>().add(
        ProductosConsolidadosPreparacionRegistrada(draft),
      );
    }
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.state});

  final ProductosConsolidadosState state;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
    child: Column(
      children: [
        TextField(
          onChanged: (value) => context.read<ProductosConsolidadosBloc>().add(
            ProductosConsolidadosBusquedaCambiada(value),
          ),
          decoration: InputDecoration(
            hintText: 'Buscar por producto, código, marca o variante',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _mostrarFiltros(context),
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(
                  state.filtrosActivos == 0
                      ? 'Filtros'
                      : 'Filtros (${state.filtrosActivos})',
                ),
                style: _buttonStyle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _mostrarOrden(context),
                icon: const Icon(Icons.sort, size: 18),
                label: const Text('Ordenar'),
                style: _buttonStyle,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  static final _buttonStyle = OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF1F1F1F),
    side: const BorderSide(color: Color(0xFFE0E0E0)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(vertical: 12),
  );

  Future<void> _mostrarFiltros(BuildContext context) async {
    final result = await ConsolidadoFiltrosDialog.show(context, state: state);
    if (result == null || !context.mounted) return;
    context.read<ProductosConsolidadosBloc>().add(
      ProductosConsolidadosFiltrosAplicados(
        hojaCodigo: result.hoja,
        empresa: result.empresa,
        marca: result.marca,
        categoria: result.categoria,
        subcategoria: result.subcategoria,
        estadoPreparacion: result.preparacion,
        estadoPedido: result.estadoPedido,
        soloSinPrecio: result.sinPrecio,
      ),
    );
  }

  Future<void> _mostrarOrden(BuildContext context) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Ordenar productos'),
        children: _ordenes
            .map(
              (item) => ListTile(
                selected: item == state.orden,
                selectedColor: const Color(0xFF1F1F1F),
                leading: Icon(
                  item == state.orden
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: item == state.orden
                      ? const Color(0xFFFFC500)
                      : Colors.grey,
                ),
                title: Text(item),
                onTap: () => Navigator.pop(context, item),
              ),
            )
            .toList(),
      ),
    );
    if (value != null && context.mounted) {
      context.read<ProductosConsolidadosBloc>().add(
        ProductosConsolidadosOrdenCambiado(value),
      );
    }
  }

  static const _ordenes = [
    'Pendientes primero',
    'Empresa',
    'Marca',
    'Categoría',
    'Nombre del producto',
    'Mayor cantidad requerida',
    'Más pedidos asociados',
  ];
}

class _HojaActivaBanner extends StatelessWidget {
  const _HojaActivaBanner({required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: const Color(0xFFFFF8DB),
    child: Row(
      children: [
        const Icon(Icons.description_outlined, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Mostrando hoja activa $codigo',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
