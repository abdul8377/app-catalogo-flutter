import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/cotizacion_pedido.dart';
import '../../domain/entities/pedido_detalle.dart';
import 'cotizacion_producto_item.dart';

class CotizacionPreview extends StatelessWidget {
  const CotizacionPreview({
    required this.pedido,
    required this.productos,
    required this.subtotalProductos,
    required this.descuentosProductos,
    required this.descuentoGeneral,
    required this.total,
    required this.observaciones,
    this.codigoCotizacion,
    super.key,
  });

  final PedidoDetalle pedido;
  final List<CotizacionProductoFormItem> productos;
  final double subtotalProductos;
  final double descuentosProductos;
  final double descuentoGeneral;
  final double total;
  final String observaciones;
  final String? codigoCotizacion;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC500),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      codigoCotizacion == null
                          ? 'COTIZACIÓN DEL PEDIDO'
                          : 'COTIZACIÓN N.º $codigoCotizacion',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      codigoCotizacion == null
                          ? 'El número se asignará al guardar'
                          : 'Pedido ${pedido.codigo}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatFecha(DateTime.now()),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _Info(label: 'Cliente', value: pedido.clienteNombre),
              if (pedido.clienteRuc.isNotEmpty)
                _Info(label: 'RUC', value: pedido.clienteRuc),
              if (pedido.clienteDni.isNotEmpty)
                _Info(label: 'DNI', value: pedido.clienteDni),
              _Info(label: 'Dirección', value: pedido.direccion),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Productos',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _ProductosTable(productos: productos),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Column(
                  children: [
                    _totalRow('Subtotal de productos', subtotalProductos),
                    _totalRow(
                      'Descuento',
                      -(descuentosProductos + descuentoGeneral),
                      discount: true,
                    ),
                    _totalRow(
                      'Total sin IGV',
                      CotizacionIgv.totalSinIgv(total),
                    ),
                    _totalRow('IGV', CotizacionIgv.igvIncluido(total)),
                    const Divider(height: 22),
                    _totalRow(
                      'Total de cotización — incluye IGV',
                      total,
                      total: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (observaciones.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8DB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Observación para el cliente: ${observaciones.trim()}',
                style: GoogleFonts.inter(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _totalRow(
    String label,
    double value, {
    bool discount = false,
    bool total = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: total ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${value < 0 ? '-' : ''}S/ ${value.abs().toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: total ? 18 : 14,
            color: discount ? const Color(0xFFD84315) : null,
          ),
        ),
      ],
    ),
  );

  String _formatFecha(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _ProductosTable extends StatelessWidget {
  const _ProductosTable({required this.productos});

  final List<CotizacionProductoFormItem> productos;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 720,
          child: Column(
            children: [
              Container(
                color: const Color(0xFFFFC500),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const _TableRow(
                  producto: 'Producto',
                  cantidad: 'Cantidad',
                  precio: 'P. unitario',
                  subtotal: 'Subtotal',
                  header: true,
                ),
              ),
              ...productos.asMap().entries.map((entry) {
                final item = entry.value;
                return Container(
                  color: entry.key.isEven
                      ? Colors.white
                      : const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _TableRow(
                    producto: item.producto.nombre,
                    cantidad:
                        '${item.producto.cantidad} ${item.producto.presentacion}',
                    precio: 'S/ ${item.precioCotizacion.toStringAsFixed(2)}',
                    subtotal:
                        'S/ ${item.subtotalCotizacion.toStringAsFixed(2)}',
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.producto,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
    this.header = false,
  });

  final String producto;
  final String cantidad;
  final String precio;
  final String subtotal;
  final bool header;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _cell(producto, flex: 4),
      _cell(cantidad, flex: 2),
      _cell(precio, flex: 2),
      _cell(subtotal, flex: 2, alignRight: true),
    ],
  );

  Widget _cell(String value, {required int flex, bool alignRight = false}) =>
      Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: header ? FontWeight.w800 : FontWeight.w500,
              color: const Color(0xFF1F1F1F),
            ),
          ),
        ),
      );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: RichText(
      text: TextSpan(
        style: GoogleFonts.inter(color: const Color(0xFF1F1F1F), fontSize: 13),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}
