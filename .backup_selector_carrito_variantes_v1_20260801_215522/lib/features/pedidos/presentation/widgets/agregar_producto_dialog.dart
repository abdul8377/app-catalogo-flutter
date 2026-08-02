import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../catalogo/domain/entities/producto_detalle.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../../domain/entities/pedido.dart';

class AgregarProductoDialog extends StatefulWidget {
  const AgregarProductoDialog({required this.productoId, super.key});

  final String productoId;

  static Future<PedidoItem?> show(
    BuildContext context, {
    required String productoId,
  }) => showDialog<PedidoItem>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => RepositoryProvider<CatalogoRepository>.value(
      value: context.read<CatalogoRepository>(),
      child: AgregarProductoDialog(productoId: productoId),
    ),
  );

  @override
  State<AgregarProductoDialog> createState() => _AgregarProductoDialogState();
}

class _AgregarProductoDialogState extends State<AgregarProductoDialog> {
  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  late final Future<ProductoDetalle?> _detalle;
  final TextEditingController _cantidadCtrl = TextEditingController(text: '1');
  String? _varianteSeleccionada;
  String? _presentacionSeleccionada;
  int cantidad = 1;

  @override
  void initState() {
    super.initState();
    _detalle = context.read<CatalogoRepository>().obtenerDetalleProducto(
      widget.productoId,
    );
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = (constraints.maxWidth * 0.7).clamp(320.0, 720.0);
        return Container(
          width: maxWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: FutureBuilder<ProductoDetalle?>(
            future: _detalle,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final producto = snapshot.data;
              if (producto == null) {
                return const SizedBox(
                  height: 240,
                  child: Center(
                    child: Text('El producto ya no está disponible.'),
                  ),
                );
              }
              _inicializarSeleccion(producto);
              return _contenido(producto);
            },
          ),
        );
      },
    ),
  );

  Widget _contenido(ProductoDetalle producto) {
    final variantes = _variantes(producto);
    final varianteSeleccionada = variantes
        .where((item) => item.id == _varianteSeleccionada)
        .firstOrNull;
    final presentaciones = varianteSeleccionada?.presentaciones ?? [];
    final presentacionSeleccionada = presentaciones
        .where((item) => item.nombre == _presentacionSeleccionada)
        .firstOrNull;
    final precioAplicado = presentacionSeleccionada?.precio;
    final subtotal = precioAplicado == null ? null : precioAplicado * cantidad;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Agregar al pedido',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: darkColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
                splashRadius: 20,
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFF757575),
                  backgroundColor: const Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _tieneImagen(producto)
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _imagenProducto(producto),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildInfoRow('Código', producto.codigo),
                          _buildInfoRow('Marca', producto.marca),
                          _buildInfoRow('Empresa', producto.empresa),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (variantes.length > 1) ...[
                  Text(
                    'Variante',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: varianteSeleccionada?.id,
                    items: variantes
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(v.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        final nueva = variantes.firstWhere((v) => v.id == val);
                        _varianteSeleccionada = nueva.id;
                        _presentacionSeleccionada =
                            nueva.presentaciones.length == 1
                            ? nueva.presentaciones.first.nombre
                            : null;
                        cantidad = 1;
                        _cantidadCtrl.text = '1';
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Presentación',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (presentaciones.isEmpty)
                  Text(
                    'Este producto no tiene presentaciones disponibles.',
                    style: GoogleFonts.inter(color: const Color(0xFF757575)),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presentaciones.map((pres) {
                      final seleccionada =
                          _presentacionSeleccionada == pres.nombre;
                      return ChoiceChip(
                        label: Text(pres.nombre),
                        selected: seleccionada,
                        onSelected: (val) {
                          setState(() {
                            _presentacionSeleccionada = val
                                ? pres.nombre
                                : null;
                          });
                        },
                        selectedColor: primaryColor,
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: seleccionada ? Colors.black : darkColor,
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Cantidad de presentaciones',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      key: const Key('restar_cantidad'),
                      onPressed: cantidad > 1
                          ? () => _cambiarCantidad(-1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline, size: 28),
                      color: darkColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _cantidadCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                        onChanged: (val) {
                          final nuevaCantidad = int.tryParse(val);
                          setState(() {
                            cantidad = nuevaCantidad == null
                                ? 0
                                : nuevaCantidad.clamp(0, 999999);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: const Key('sumar_cantidad'),
                      onPressed: () => _cambiarCantidad(1),
                      icon: const Icon(Icons.add_circle_outline, size: 28),
                      color: darkColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (presentacionSeleccionada != null) ...[
                  Text(
                    'Equivalencia: $cantidad ${presentacionSeleccionada.nombre.toLowerCase()} = ${cantidad == 0 ? 0 : cantidad} ${presentacionSeleccionada.equivalencia}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Precio aplicado:',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          precioAplicado == null
                              ? 'Sin precio'
                              : 'S/ ${precioAplicado.toStringAsFixed(2)} por ${presentacionSeleccionada.nombre.toLowerCase()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: darkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Subtotal:',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          subtotal == null
                              ? 'Pendiente'
                              : 'S/ ${subtotal.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF757575),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('confirmar_agregar_producto'),
                  onPressed: presentacionSeleccionada != null && cantidad > 0
                      ? () => Navigator.of(context).pop(
                          PedidoItem(
                            productoId: producto.id,
                            codigo: producto.codigo,
                            nombre: producto.nombre,
                            presentacion: presentacionSeleccionada.nombre,
                            equivalencia: presentacionSeleccionada.equivalencia,
                            cantidad: cantidad,
                            precioUnitario: presentacionSeleccionada.precio,
                            opciones: presentaciones,
                            imagenPath:
                                producto.imagenPath ??
                                producto.imagenesPaths.firstOrNull,
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const FittedBox(child: Text('Agregar al pedido')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _inicializarSeleccion(ProductoDetalle producto) {
    if (_varianteSeleccionada != null) return;
    final variantes = _variantes(producto);
    if (variantes.isEmpty) return;
    final primera = variantes.first;
    _varianteSeleccionada = primera.id;
    if (primera.presentaciones.length == 1) {
      _presentacionSeleccionada = primera.presentaciones.first.nombre;
    } else {
      _presentacionSeleccionada = primera.presentaciones.firstOrNull?.nombre;
    }
  }

  List<_VariantePedidoUi> _variantes(ProductoDetalle producto) => [
    _VariantePedidoUi(
      id: producto.id,
      nombre: producto.nombre,
      presentaciones: producto.presentaciones
          .map(
            (presentacion) => PresentacionPedidoOpcion(
              nombre: presentacion.nombre,
              equivalencia: presentacion.unidad,
              precio: producto.precios
                  .where((precio) => precio.presentacion == presentacion.nombre)
                  .firstOrNull
                  ?.valor,
            ),
          )
          .toList(),
    ),
  ];

  bool _tieneImagen(ProductoDetalle producto) =>
      producto.imagenPath != null || producto.imagenesPaths.isNotEmpty;

  Widget _imagenProducto(ProductoDetalle producto) {
    final path = producto.imagenPath ?? producto.imagenesPaths.firstOrNull;
    if (path == null) {
      return const Icon(Icons.hide_image, size: 40, color: Color(0xFFBDBDBD));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.image, size: 40),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),
        ),
      ],
    ),
  );

  void _cambiarCantidad(int delta) {
    final next = (cantidad + delta).clamp(1, 999999);
    _cantidadCtrl.text = '$next';
    setState(() => cantidad = next);
  }
}

class _VariantePedidoUi {
  const _VariantePedidoUi({
    required this.id,
    required this.nombre,
    required this.presentaciones,
  });

  final String id;
  final String nombre;
  final List<PresentacionPedidoOpcion> presentaciones;
}
