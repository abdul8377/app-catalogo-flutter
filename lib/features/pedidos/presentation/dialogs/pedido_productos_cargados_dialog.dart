import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/pedido_preparacion.dart';
import '../../domain/entities/producto_consolidado.dart';

class PedidoProductosCargadosDialog extends StatelessWidget {
  const PedidoProductosCargadosDialog({required this.pedido, super.key});

  final PedidoPreparacion pedido;

  static Future<void> show(
    BuildContext context, {
    required PedidoPreparacion pedido,
  }) => showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => PedidoProductosCargadosDialog(pedido: pedido),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: LayoutBuilder(
      builder: (context, constraints) => Container(
        width: constraints.maxWidth > 860 ? 860 : constraints.maxWidth,
        height: constraints.maxHeight > 800 ? 800 : constraints.maxHeight,
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
        child: Column(
          children: [
            _header(context),
            _summary(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                itemCount: pedido.productos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) =>
                    _ProductLoadedCard(producto: pedido.productos[index]),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC500),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 13,
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Productos cargados',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              Text(
                '${pedido.codigo} • ${pedido.cliente}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            foregroundColor: Colors.grey,
            backgroundColor: const Color(0xFFF5F5F5),
          ),
        ),
      ],
    ),
  );

  Widget _summary() => Padding(
    padding: const EdgeInsets.all(24),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          _summaryValue(
            Icons.check_circle,
            '${pedido.completos} productos completados',
          ),
          _summaryValue(
            Icons.shopping_bag_outlined,
            pedido.paquetes == 1 ? '1 paquete' : '${pedido.paquetes} paquetes',
          ),
          ...pedido.resumenPresentaciones.map(
            (value) => _summaryValue(Icons.layers_outlined, value),
          ),
        ],
      ),
    ),
  );

  Widget _summaryValue(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
      const SizedBox(width: 5),
      Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _ProductLoadedCard extends StatelessWidget {
  const _ProductLoadedCard({required this.producto});

  final ProductoPreparacion producto;

  @override
  Widget build(BuildContext context) {
    final path = producto.imagenPath;
    final file = path == null ? null : File(path);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final image = Container(
            width: 72,
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: file != null && file.existsSync()
                ? Image.file(file, fit: BoxFit.cover)
                : const Icon(
                    Icons.image_outlined,
                    size: 34,
                    color: Color(0xFFBDBDBD),
                  ),
          );
          final details = _details();
          if (constraints.maxWidth < 540) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image,
                    const SizedBox(width: 12),
                    Expanded(child: _identity()),
                  ],
                ),
                const SizedBox(height: 14),
                details,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              image,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_identity(), const SizedBox(height: 12), details],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _identity() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        producto.nombre,
        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      if (producto.variante.isNotEmpty && producto.variante != 'Producto único')
        Text(
          producto.variante,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      const SizedBox(height: 3),
      Text(
        'Código: ${producto.codigo}'
        '${producto.marca.isEmpty ? '' : ' • ${producto.marca}'}',
        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF757575)),
      ),
    ],
  );

  Widget _details() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          _quantity('Presentación cargada', producto.presentacion),
          _quantity('Solicitado', producto.solicitadoTexto),
          _quantity('Preparado', producto.preparadoTexto),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 6,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 5),
                Text(
                  'Completado: ${producto.preparadoTexto}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Equivalencia: ${producto.cantidadPreparadaBase} '
            '${unidadBaseTexto(producto.cantidadPreparadaBase, producto.unidadBase)}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _quantity(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
      Text(
        value,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ],
  );
}
