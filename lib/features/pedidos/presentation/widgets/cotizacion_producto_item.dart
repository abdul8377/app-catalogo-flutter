import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/cotizacion_pedido.dart';
import '../../domain/entities/pedido_detalle.dart';
import '../formatters/money_input_formatter.dart';

class CotizacionProductoFormItem {
  CotizacionProductoFormItem({
    required this.producto,
    required this.precioCotizacion,
    this.descuento = 0,
    this.tipoDescuento = 'monto',
  });

  final PedidoDetalleProducto producto;
  double precioCotizacion;
  double descuento;
  String tipoDescuento;

  double get subtotalSinDescuento => precioCotizacion * producto.cantidad;

  double get descuentoAplicado {
    final value = tipoDescuento == 'porcentaje'
        ? subtotalSinDescuento * descuento / 100
        : descuento;
    return value.clamp(0, subtotalSinDescuento).toDouble();
  }

  double get subtotalCotizacion => subtotalSinDescuento - descuentoAplicado;

  double get precioFinal =>
      producto.cantidad <= 0 ? 0 : subtotalCotizacion / producto.cantidad;

  bool get valorizado => precioCotizacion > 0;

  CotizacionPedidoItemDraft toDraft() => CotizacionPedidoItemDraft(
    pedidoItemId: producto.id,
    productoId: producto.productoId,
    codigo: producto.codigo,
    nombre: producto.nombre,
    presentacion: producto.presentacion,
    cantidad: producto.cantidad,
    precioCotizacion: precioCotizacion,
    descuento: descuento,
    tipoDescuento: tipoDescuento,
    precioFinal: precioFinal,
    subtotal: subtotalCotizacion,
  );
}

class CotizacionProductoItem extends StatefulWidget {
  const CotizacionProductoItem({
    required this.item,
    required this.onChanged,
    super.key,
  });

  final CotizacionProductoFormItem item;
  final VoidCallback onChanged;

  @override
  State<CotizacionProductoItem> createState() => _CotizacionProductoItemState();
}

class _CotizacionProductoItemState extends State<CotizacionProductoItem> {
  late final TextEditingController _precioController;
  late final TextEditingController _descuentoController;

  @override
  void initState() {
    super.initState();
    _precioController = TextEditingController(
      text: widget.item.precioCotizacion > 0
          ? widget.item.precioCotizacion.toStringAsFixed(2)
          : '',
    );
    _descuentoController = TextEditingController(
      text: widget.item.descuento > 0
          ? widget.item.descuento.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _precioController.dispose();
    _descuentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prod = widget.item.producto;
    final tienePrecioBase = prod.tienePrecio;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.item.valorizado
              ? const Color(0xFFE0E0E0)
              : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProductImage(path: prod.imagenPath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod.nombre,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Código: ${prod.codigo}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF757575),
                      ),
                    ),
                    Text(
                      '${prod.cantidad} × ${prod.presentacion} · '
                      '${prod.equivalencia}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.item.valorizado)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Pendiente',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (tienePrecioBase)
            Text(
              'Precio sugerido: S/ ${prod.precioUnitario!.toStringAsFixed(2)} por ${prod.presentacion}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF757575),
              ),
            )
          else
            Text(
              'Este producto no tiene precio en catálogo. Ingresa el precio de cotización.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = [
                _priceField(),
                _discountField(),
                _discountTypeDropdown(),
              ];
              if (constraints.maxWidth < 520) {
                return Column(
                  children: [
                    fields[0],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: fields[1]),
                        const SizedBox(width: 8),
                        fields[2],
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 8),
                  Expanded(child: fields[1]),
                  const SizedBox(width: 8),
                  fields[2],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Precio unitario: S/ ${widget.item.precioCotizacion.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              if (widget.item.descuentoAplicado > 0)
                Text(
                  'Descuento total: -S/ ${widget.item.descuentoAplicado.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD84315),
                  ),
                ),
              Text(
                'Subtotal: S/ ${widget.item.subtotalCotizacion.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceField() => TextFormField(
    controller: _precioController,
    decoration: InputDecoration(
      labelText: 'Precio para cotización',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [MoneyInputFormatter()],
    onChanged: (value) {
      widget.item.precioCotizacion = parseMoney(value);
      setState(() {});
      widget.onChanged();
    },
  );

  Widget _discountField() => TextFormField(
    controller: _descuentoController,
    decoration: InputDecoration(
      labelText: 'Descuento sobre el subtotal',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [MoneyInputFormatter()],
    onChanged: (value) {
      widget.item.descuento = parseMoney(value);
      setState(() {});
      widget.onChanged();
    },
  );

  Widget _discountTypeDropdown() => DropdownButton<String>(
    value: widget.item.tipoDescuento,
    items: const [
      DropdownMenuItem(value: 'monto', child: Text('S/')),
      DropdownMenuItem(value: 'porcentaje', child: Text('%')),
    ],
    onChanged: (value) {
      if (value == null) return;
      setState(() => widget.item.tipoDescuento = value);
      widget.onChanged();
    },
    underline: const SizedBox(),
  );
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final imagePath = path;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 50,
        height: 50,
        color: const Color(0xFFF5F5F5),
        child: imagePath == null || imagePath.isEmpty
            ? const Icon(Icons.image, color: Color(0xFFBDBDBD))
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
      ),
    );
  }
}
