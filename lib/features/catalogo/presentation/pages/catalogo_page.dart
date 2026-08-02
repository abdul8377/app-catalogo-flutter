import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../bloc/catalogo_bloc.dart';
import '../bloc/catalogo_event.dart';
import '../bloc/catalogo_state.dart';
import '../widgets/filtros_catalogo.dart';
import '../widgets/producto_card.dart';
import '../widgets/producto_detalle_dialog.dart';
import 'producto_form_page.dart';

class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<CatalogoBloc, CatalogoState>(
    listenWhen: (previous, current) =>
        previous.error != current.error && current.error != null,
    listener: (context, state) => AppNotice.error(context, state.error!),
    builder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catálogo de productos',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            Text(
              '${state.productosFiltrados.length} de ${state.productos.length} productos',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (state.actualizando)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFFC500),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Recargar catálogo',
              onPressed: () =>
                  context.read<CatalogoBloc>().add(const CatalogoRecargado()),
              icon: const Icon(Icons.refresh),
            ),
          IconButton(
            tooltip: state.vistaGrilla ? 'Ver como lista' : 'Ver como grilla',
            onPressed: () => context.read<CatalogoBloc>().add(
              CatalogoVistaCambiada(!state.vistaGrilla),
            ),
            icon: Icon(
              state.vistaGrilla ? Icons.view_list : Icons.grid_view,
              color: const Color(0xFFFFC500),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          FiltrosCatalogo(
            state: state,
            onBusquedaCambiada: (value) => context.read<CatalogoBloc>().add(
              CatalogoBusquedaCambiada(value),
            ),
            onFiltroRapido: (value) => context.read<CatalogoBloc>().add(
              CatalogoFiltroRapidoCambiado(value),
            ),
            onFiltrosAplicados: (value) => context.read<CatalogoBloc>().add(
              CatalogoFiltrosAplicados(value),
            ),
            onFiltrosLimpiados: () => context.read<CatalogoBloc>().add(
              const CatalogoFiltrosLimpiados(),
            ),
          ),
          Expanded(child: _contenido(context, state)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _registrarProducto(context),
        backgroundColor: const Color(0xFFFFC500),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
    ),
  );

  Widget _contenido(BuildContext context, CatalogoState state) {
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.productosFiltrados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 64, color: Color(0xFFBDBDBD)),
              const SizedBox(height: 14),
              Text(
                'No se encontraron productos',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Prueba con otra búsqueda o limpia los filtros.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (!state.vistaGrilla) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: state.productosFiltrados.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) => ProductoCard(
          producto: state.productosFiltrados[index],
          isGrid: false,
          onVerDetalle: () =>
              _verDetalle(context, state.productosFiltrados[index].id),
          onEditar: () =>
              _editarProducto(context, state.productosFiltrados[index].id),
          onCambiarEstado: () => _confirmarEstado(
            context,
            state.productosFiltrados[index].id,
            state.productosFiltrados[index].activo,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: constraints.maxWidth < 500 ? 500 : 360,
          mainAxisExtent: constraints.maxWidth < 500 ? 550 : 520,
          crossAxisSpacing: 13,
          mainAxisSpacing: 13,
        ),
        itemCount: state.productosFiltrados.length,
        itemBuilder: (_, index) => ProductoCard(
          producto: state.productosFiltrados[index],
          isGrid: true,
          onVerDetalle: () =>
              _verDetalle(context, state.productosFiltrados[index].id),
          onEditar: () =>
              _editarProducto(context, state.productosFiltrados[index].id),
          onCambiarEstado: () => _confirmarEstado(
            context,
            state.productosFiltrados[index].id,
            state.productosFiltrados[index].activo,
          ),
        ),
      ),
    );
  }

  Future<void> _registrarProducto(BuildContext context) async {
    final guardado = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ProductoFormPage()));
    if (guardado == true && context.mounted) {
      context.read<CatalogoBloc>().add(const CatalogoRecargado());
      AppNotice.success(context, 'Producto registrado correctamente.');
    }
  }

  Future<void> _verDetalle(BuildContext context, String id) =>
      ProductoDetalleDialog.show(
        context,
        productoId: id,
        onEditar: (producto) => _editarProducto(context, producto.id),
        onCambiarEstado: (producto) =>
            _confirmarEstado(context, producto.id, producto.activo),
      );

  Future<void> _editarProducto(BuildContext context, String id) async {
    final actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductoFormPage(productoId: id)),
    );
    if (actualizado == true && context.mounted) {
      context.read<CatalogoBloc>().add(const CatalogoRecargado());
      AppNotice.success(context, 'Producto actualizado correctamente.');
    }
  }

  Future<void> _confirmarEstado(
    BuildContext context,
    String id,
    bool activo,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activo ? 'Desactivar producto' : 'Activar producto'),
        content: Text(
          activo
              ? 'El producto dejará de estar disponible, pero conservará toda su información.'
              : 'El producto volverá a estar disponible en el catálogo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: activo
                  ? const Color(0xFFC62828)
                  : const Color(0xFF2E7D32),
            ),
            child: Text(activo ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      context.read<CatalogoBloc>().add(
        CatalogoEstadoProductoCambiado(id, activo: !activo),
      );
    }
  }
}
