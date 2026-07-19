import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/producto_detalle.dart';
import '../../domain/repositories/catalogo_repository.dart';
import '../bloc/producto_detalle_bloc.dart';

class ProductoDetalleDialog extends StatelessWidget {
  const ProductoDetalleDialog({
    required this.onEditar,
    required this.onCambiarEstado,
    super.key,
  });

  final ValueChanged<ProductoDetalle> onEditar;
  final ValueChanged<ProductoDetalle> onCambiarEstado;

  static Future<void> show(
    BuildContext context, {
    required String productoId,
    required ValueChanged<ProductoDetalle> onEditar,
    required ValueChanged<ProductoDetalle> onCambiarEstado,
  }) => showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .65),
    builder: (dialogContext) => BlocProvider(
      create: (_) =>
          ProductoDetalleBloc(context.read<CatalogoRepository>())
            ..add(ProductoDetalleSolicitado(productoId)),
      child: ProductoDetalleDialog(
        onEditar: onEditar,
        onCambiarEstado: onCambiarEstado,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 880, maxHeight: 760),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: BlocBuilder<ProductoDetalleBloc, ProductoDetalleState>(
          builder: (context, state) {
            if (state.loading) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.error != null || state.producto == null) {
              return _ErrorDetalle(
                message: state.error ?? 'No se encontró el producto.',
              );
            }
            return _ContenidoDetalle(
              producto: state.producto!,
              onEditar: onEditar,
              onCambiarEstado: onCambiarEstado,
            );
          },
        ),
      ),
    ),
  );
}

class _ContenidoDetalle extends StatelessWidget {
  const _ContenidoDetalle({
    required this.producto,
    required this.onEditar,
    required this.onCambiarEstado,
  });
  final ProductoDetalle producto;
  final ValueChanged<ProductoDetalle> onEditar;
  final ValueChanged<ProductoDetalle> onCambiarEstado;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 25,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC500),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                'Detalle del producto',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;
              final header = compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _imagen(),
                        const SizedBox(height: 18),
                        _informacion(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 260, child: _imagen()),
                        const SizedBox(width: 22),
                        Expanded(child: _informacion()),
                      ],
                    );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 26),
                  _titulo('Atributos técnicos'),
                  const SizedBox(height: 11),
                  producto.atributos.isEmpty
                      ? const _Vacio(
                          text: 'Este producto no tiene atributos registrados.',
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: producto.atributos.entries
                              .map(
                                (entry) => _DatoChip(
                                  label: entry.key,
                                  value: entry.value,
                                ),
                              )
                              .toList(),
                        ),
                  const SizedBox(height: 26),
                  _titulo('Presentaciones de venta'),
                  const SizedBox(height: 11),
                  producto.presentaciones.isEmpty
                      ? const _Vacio(text: 'No hay presentaciones registradas.')
                      : Wrap(
                          spacing: 9,
                          runSpacing: 9,
                          children: producto.presentaciones
                              .map(
                                (item) => Chip(
                                  avatar: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 17,
                                  ),
                                  label: Text(
                                    '${item.nombre} · ${item.unidad}',
                                  ),
                                  backgroundColor: const Color(
                                    0xFFFFC500,
                                  ).withValues(alpha: .10),
                                  side: const BorderSide(
                                    color: Color(0xFFFFD84D),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                  const SizedBox(height: 26),
                  _titulo('Precios'),
                  const SizedBox(height: 11),
                  producto.precios.isEmpty
                      ? const _Vacio(text: 'Producto registrado sin precio.')
                      : Column(
                          children: producto.precios
                              .map(
                                (precio) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          precio.presentacion,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'S/ ${precio.valor.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ],
              );
            },
          ),
        ),
      ),
      const Divider(height: 1),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final editarButton = FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onEditar(producto);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC500),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              );
              final estadoButton = FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onCambiarEstado(producto);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: producto.activo
                      ? const Color(0xFFC62828)
                      : const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  producto.activo ? Icons.block : Icons.check_circle_outline,
                ),
                label: Text(producto.activo ? 'Desactivar' : 'Activar'),
              );
              final cerrarButton = OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cerrar'),
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    editarButton,
                    const SizedBox(height: 10),
                    estadoButton,
                    const SizedBox(height: 10),
                    cerrarButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: editarButton),
                  const SizedBox(width: 10),
                  Expanded(child: estadoButton),
                  const SizedBox(width: 10),
                  Expanded(child: cerrarButton),
                ],
              );
            },
          ),
        ),
      ),
    ],
  );

  Widget _imagen() => _GaleriaDetalleProducto(
    paths: producto.imagenesPaths.isNotEmpty
        ? producto.imagenesPaths
        : producto.imagenPath == null
        ? const []
        : [producto.imagenPath!],
  );

  Widget _informacion() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          _estado(producto.activo ? 'Activo' : 'Inactivo', producto.activo),
          const SizedBox(width: 7),
          _estado(_tipo(producto.tipoRegistro), null),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        producto.nombre,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
      if (producto.descripcion.isNotEmpty) ...[
        const SizedBox(height: 9),
        Text(
          producto.descripcion,
          style: const TextStyle(color: Color(0xFF616161), height: 1.4),
        ),
      ],
      const SizedBox(height: 16),
      _fila('Código', producto.codigo),
      _fila('Empresa', producto.empresa),
      _fila('Marca', producto.marca),
      _fila('Categoría', producto.categoria),
      _fila(
        'Subcategoría',
        producto.subcategoria.isEmpty
            ? 'Sin subcategoría'
            : producto.subcategoria,
      ),
      _fila('Registrado', _fecha(producto.creadoEn)),
    ],
  );

  Widget _fila(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(label, style: const TextStyle(color: Color(0xFF8A8A8A))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _titulo(String value) => Text(
    value,
    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
  );
  Widget _estado(String value, bool? activo) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: activo == null
          ? const Color(0xFFE3F2FD)
          : activo
          ? const Color(0xFFE8F5E9)
          : const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      value,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: activo == null
            ? const Color(0xFF1565C0)
            : activo
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC62828),
      ),
    ),
  );
  String _tipo(String value) => switch (value) {
    'variantes' => 'Con variantes',
    'matriz' => 'Matriz',
    _ => 'Producto único',
  };
  String _fecha(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _DatoChip extends StatelessWidget {
  const _DatoChip({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(text, style: const TextStyle(color: Color(0xFF757575))),
  );
}

class _GaleriaDetalleProducto extends StatefulWidget {
  const _GaleriaDetalleProducto({required this.paths});
  final List<String> paths;

  @override
  State<_GaleriaDetalleProducto> createState() =>
      _GaleriaDetalleProductoState();
}

class _GaleriaDetalleProductoState extends State<_GaleriaDetalleProducto> {
  int pagina = 0;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
      aspectRatio: 4 / 3,
      child: ColoredBox(
        color: const Color(0xFFF1F1F1),
        child: widget.paths.isEmpty
            ? const Icon(
                Icons.inventory_2_outlined,
                size: 70,
                color: Color(0xFFBDBDBD),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: widget.paths.length,
                    onPageChanged: (value) => setState(() => pagina = value),
                    itemBuilder: (_, index) => Image.file(
                      File(widget.paths[index]),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined, size: 60),
                    ),
                  ),
                  if (widget.paths.length > 1)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .72),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${pagina + 1}/${widget.paths.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    ),
  );
}

class _ErrorDetalle extends StatelessWidget {
  const _ErrorDetalle({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
