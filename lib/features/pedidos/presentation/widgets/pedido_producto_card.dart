import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../catalogo/domain/entities/producto_resumen.dart';

class VarianteVendible {
  const VarianteVendible({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.empresa,
    required this.marca,
    required this.atributosClave,
    required this.tienePrecio,
    required this.tieneImagen,
    this.presentacionPrincipal,
    this.precio,
    this.tieneMultiplesPresentaciones = false,
    this.urlImagen,
    this.imagenPath,
  });

  factory VarianteVendible.fromProductoResumen(ProductoResumen producto) =>
      VarianteVendible(
        id: producto.id,
        nombre: producto.nombre,
        codigo: producto.codigo,
        empresa: producto.empresa,
        marca: producto.marca,
        atributosClave: producto.atributosClave,
        presentacionPrincipal: producto.unidadVenta,
        precio: producto.precio,
        tienePrecio: !producto.sinPrecio && producto.precio != null,
        tieneMultiplesPresentaciones: producto.tipoRegistro != 'unico',
        imagenPath: producto.imagenPath,
        tieneImagen:
            producto.imagenPath != null || producto.imagenesPaths.isNotEmpty,
      );

  final String id;
  final String nombre;
  final String codigo;
  final String empresa;
  final String marca;
  final List<String> atributosClave;
  final String? presentacionPrincipal;
  final double? precio;
  final bool tienePrecio;
  final bool tieneMultiplesPresentaciones;
  final String? urlImagen;
  final String? imagenPath;
  final bool tieneImagen;
}

class ProductoVendibleCard extends StatelessWidget {
  const ProductoVendibleCard({
    required this.producto,
    this.onVerDetalle,
    this.onAgregar,
    super.key,
  });

  factory ProductoVendibleCard.fromResumen({
    required ProductoResumen producto,
    VoidCallback? onVerDetalle,
    VoidCallback? onAgregar,
  }) => ProductoVendibleCard(
    producto: VarianteVendible.fromProductoResumen(producto),
    onVerDetalle: onVerDetalle,
    onAgregar: onAgregar,
  );

  final VarianteVendible producto;
  final VoidCallback? onVerDetalle;
  final VoidCallback? onAgregar;

  @override
  Widget build(BuildContext context) {
    final darkColor = const Color(0xFF1F1F1F);
    final primaryColor = const Color(0xFFFFC500);

    String precioTexto;
    if (!producto.tienePrecio) {
      precioTexto = 'Sin precio';
    } else if (producto.tieneMultiplesPresentaciones) {
      precioTexto = 'Desde S/ ${producto.precio!.toStringAsFixed(2)}';
    } else {
      precioTexto = 'S/ ${producto.precio!.toStringAsFixed(2)}';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: producto.tieneImagen
                      ? const Color(0xFFF7F7F7)
                      : const Color(0xFFEEEEEE),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: _imagenProducto(),
              ),
              if (!producto.tienePrecio)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildBadge(
                    'Sin precio',
                    const Color(0xFFFFF3E0),
                    const Color(0xFFE65100),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: darkColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.tag, size: 14, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Código: ${producto.codigo}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${producto.empresa} • ${producto.marca}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (producto.atributosClave.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: producto.atributosClave.take(3).map((attr) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            attr,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (producto.tieneMultiplesPresentaciones)
                              Text(
                                'Desde',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                            Text(
                              precioTexto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: producto.tienePrecio
                                    ? darkColor
                                    : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (producto.tienePrecio &&
                          producto.presentacionPrincipal != null)
                        Flexible(
                          child: Text(
                            producto.presentacionPrincipal!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onVerDetalle,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: darkColor,
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          child: const Text('Ver detalles'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          key: Key('agregar_${producto.id}'),
                          onPressed: onAgregar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          child: const Text('Agregar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagenProducto() {
    if (!producto.tieneImagen) {
      return Center(
        child: Icon(Icons.hide_image, size: 48, color: Colors.grey.shade400),
      );
    }
    if (producto.imagenPath != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.file(
          File(producto.imagenPath!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.image, size: 48, color: Color(0xFFBDBDBD)),
          ),
        ),
      );
    }
    if (producto.urlImagen != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.network(
          producto.urlImagen!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.image, size: 48, color: Color(0xFFBDBDBD)),
          ),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.image, size: 48, color: Color(0xFFBDBDBD)),
    );
  }

  Widget _buildBadge(String texto, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
