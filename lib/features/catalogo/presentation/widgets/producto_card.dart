import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/producto_resumen.dart';

class ProductoCard extends StatelessWidget {
  const ProductoCard({
    required this.producto,
    required this.isGrid,
    required this.onVerDetalle,
    this.onEditar,
    this.onCambiarEstado,
    this.onAgregar,
    super.key,
  });

  final ProductoResumen producto;
  final bool isGrid;
  final VoidCallback onVerDetalle;
  final VoidCallback? onEditar;
  final VoidCallback? onCambiarEstado;
  final VoidCallback? onAgregar;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: Colors.white,
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFEAEAEA)),
    ),
    child: isGrid ? _grid(context) : _list(context),
  );

  Widget _grid(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _imagen(height: 145),
      Expanded(child: _contenido(context, compact: false)),
    ],
  );

  Widget _list(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 560) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_imagen(height: 150), _contenido(context, compact: true)],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 190, child: _imagen()),
            Expanded(child: _contenido(context, compact: true)),
          ],
        ),
      );
    },
  );

  Widget _imagen({double? height}) => SizedBox(
    width: double.infinity,
    height: height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: const Color(0xFFF3F3F3),
          child: producto.imagenPath == null
              ? const Icon(
                  Icons.inventory_2_outlined,
                  size: 52,
                  color: Color(0xFFBDBDBD),
                )
              : Image.file(
                  File(producto.imagenPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image_outlined, size: 52),
                ),
        ),
        Positioned(
          top: 9,
          left: 9,
          child: _badge(
            producto.activo ? 'Activo' : 'Inactivo',
            producto.activo ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            producto.activo ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
        ),
        if (producto.sinPrecio)
          Positioned(
            top: 9,
            right: 9,
            child: _badge(
              'Sin precio',
              const Color(0xFFFFF3E0),
              const Color(0xFFE65100),
            ),
          ),
      ],
    ),
  );

  Widget _contenido(BuildContext context, {required bool compact}) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Text(
          producto.nombre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '${producto.codigo}  •  ${producto.marca}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          producto.categoria,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF9E9E9E),
          ),
        ),
        if (producto.atributosClave.isNotEmpty) ...[
          const SizedBox(height: 9),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: producto.atributosClave
                .take(compact ? 2 : 3)
                .map(
                  (attr) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC500).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      attr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        if (!compact) const Spacer() else const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                producto.sinPrecio
                    ? 'Sin precio'
                    : 'S/ ${producto.precio!.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: producto.sinPrecio
                      ? Colors.redAccent
                      : const Color(0xFF1F1F1F),
                ),
              ),
            ),
            Text(
              producto.unidadVenta,
              style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: onAgregar == null
                  ? FilledButton(
                      key: Key('ver_producto_${producto.id}'),
                      onPressed: onVerDetalle,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC500),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Ver detalles'),
                    )
                  : OutlinedButton(
                      key: Key('ver_producto_${producto.id}'),
                      onPressed: onVerDetalle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1F1F1F),
                      ),
                      child: const Text('Ver detalles'),
                    ),
            ),
            if (onAgregar != null) ...[
              const SizedBox(width: 7),
              Expanded(
                child: FilledButton.icon(
                  key: Key('agregar_producto_${producto.id}'),
                  onPressed: onAgregar,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC500),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Agregar'),
                ),
              ),
            ],
            if (onEditar != null || onCambiarEstado != null) ...[
              const SizedBox(width: 7),
              PopupMenuButton<String>(
                tooltip: 'Más acciones',
                onSelected: (value) {
                  if (value == 'editar') {
                    onEditar?.call();
                  } else if (value == 'estado') {
                    onCambiarEstado?.call();
                  }
                },
                itemBuilder: (_) => [
                  if (onEditar != null)
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                  if (onCambiarEstado != null)
                    PopupMenuItem(
                      value: 'estado',
                      child: Row(
                        children: [
                          Icon(
                            producto.activo
                                ? Icons.block
                                : Icons.check_circle_outline,
                          ),
                          const SizedBox(width: 8),
                          Text(producto.activo ? 'Desactivar' : 'Activar'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ],
    ),
  );

  Widget _badge(String text, Color background, Color foreground) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      );
}
