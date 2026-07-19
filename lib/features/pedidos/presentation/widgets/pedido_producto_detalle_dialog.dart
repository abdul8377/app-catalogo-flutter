import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../catalogo/domain/entities/producto_detalle.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';

class PedidoProductoDetalleDialog extends StatelessWidget {
  const PedidoProductoDetalleDialog({required this.productoId, super.key});

  final String productoId;

  static Future<bool> show(
    BuildContext context, {
    required String productoId,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => RepositoryProvider<CatalogoRepository>.value(
          value: context.read<CatalogoRepository>(),
          child: PedidoProductoDetalleDialog(productoId: productoId),
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = (constraints.maxWidth * 0.75).clamp(320.0, 920.0);
        final maxHeight = constraints.maxHeight * 0.85;
        return Container(
          width: maxWidth,
          height: maxHeight,
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
            future: context.read<CatalogoRepository>().obtenerDetalleProducto(
              productoId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final producto = snapshot.data;
              if (producto == null) {
                return const Center(child: Text('Producto no disponible.'));
              }
              return _DetalleContent(producto: producto);
            },
          ),
        );
      },
    ),
  );
}

class _DetalleContent extends StatelessWidget {
  const _DetalleContent({required this.producto});

  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  final ProductoDetalle producto;

  @override
  Widget build(BuildContext context) => Column(
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
                'Detalle del producto',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: darkColor,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(false),
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
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final imagen = Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: _tieneImagen
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _imagenProducto(60, 16),
                  );
                  final datos = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: darkColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Código', producto.codigo),
                      _buildInfoRow('Marca', producto.marca),
                      _buildInfoRow('Empresa', producto.empresa),
                      if (producto.tipoRegistro != 'unico') ...[
                        const SizedBox(height: 8),
                        Text(
                          '${producto.presentaciones.length} variantes disponibles',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ],
                  );
                  if (constraints.maxWidth < 560) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [imagen, const SizedBox(height: 20), datos],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      imagen,
                      const SizedBox(width: 20),
                      Expanded(child: datos),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              if (producto.descripcion.isNotEmpty) ...[
                Text(
                  'Descripción',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  producto.descripcion,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF616161),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (producto.atributos.isNotEmpty) ...[
                Text(
                  'Características técnicas',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: producto.atributos.entries.map((attr) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            attr.key,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            attr.value,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: darkColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              if (producto.tipoRegistro != 'unico' &&
                  producto.presentaciones.length > 1) ...[
                Text(
                  'Variantes disponibles',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Código')),
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Precio desde')),
                      ],
                      rows: producto.presentaciones.map((presentacion) {
                        final precio = _precioDe(presentacion.nombre);
                        return DataRow(
                          cells: [
                            DataCell(Text(producto.codigo)),
                            DataCell(Text(presentacion.nombre)),
                            DataCell(
                              Text(
                                precio == null
                                    ? 'Sin precio'
                                    : 'S/ ${precio.toStringAsFixed(2)}',
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (producto.presentaciones.isNotEmpty) ...[
                Text(
                  'Presentaciones y precios (${producto.nombre})',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 12),
                ...producto.presentaciones.map((pres) {
                  final precio = _precioDe(pres.nombre);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${pres.nombre} (${pres.unidad})',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            precio == null
                                ? 'Sin precio'
                                : 'S/ ${precio.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Text(
                  'Modo de precio: ${producto.tipoRegistro}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF757575),
                  ),
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
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF757575),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cerrar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const FittedBox(child: Text('Agregar al pedido')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
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

  bool get _tieneImagen =>
      producto.imagenPath != null || producto.imagenesPaths.isNotEmpty;

  Widget _imagenProducto(double iconSize, double radius) {
    final path = producto.imagenPath ?? producto.imagenesPaths.firstOrNull;
    if (path == null) {
      return Center(
        child: Icon(
          Icons.hide_image,
          size: iconSize,
          color: const Color(0xFFBDBDBD),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Icon(Icons.image, size: iconSize, color: const Color(0xFFBDBDBD)),
      ),
    );
  }

  double? _precioDe(String presentacion) => producto.precios
      .where((precio) => precio.presentacion == presentacion)
      .firstOrNull
      ?.valor;

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
}
