import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/producto_consolidado.dart';

class ConsolidadoProductoCard extends StatelessWidget {
  const ConsolidadoProductoCard({
    required this.producto,
    required this.onVerDistribucion,
    required this.onRegistrarPreparacion,
    super.key,
  });

  final ProductoConsolidado producto;
  final VoidCallback onVerDistribucion;
  final VoidCallback? onRegistrarPreparacion;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEEEEEE)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .045),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImagenProducto(path: producto.imagenPath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Código: ${producto.codigo}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  if (producto.variante != 'Producto único')
                    Text(
                      producto.variante,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF616161),
                      ),
                    ),
                  if (_clasificacion.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _clasificacion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (producto.pendientePrecio)
              const Tooltip(
                message: 'Hay pedidos pendientes de precio',
                child: Icon(
                  Icons.price_change_outlined,
                  size: 20,
                  color: Color(0xFFF57C00),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: producto.progreso.clamp(0, 1),
            minHeight: 8,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: AlwaysStoppedAnimation(
              producto.completo
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF1976D2),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${(producto.progreso.clamp(0, 1) * 100).round()}% completado',
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        _PresentacionesResumen(
          label: 'Total requerido',
          valores: producto.presentaciones
              .map((item) => item.solicitadaTexto)
              .toList(),
        ),
        const SizedBox(height: 7),
        _PresentacionesResumen(
          label: 'Equivalencia total',
          valores: [producto.equivalenciaTotalTexto],
          secundaria: true,
        ),
        const SizedBox(height: 7),
        _PresentacionesResumen(
          label: 'Preparado',
          valores: producto.presentaciones
              .where((item) => item.preparada > 0)
              .map((item) => item.preparadaTexto)
              .toList(),
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(height: 7),
        _PresentacionesResumen(
          label: 'Pendiente',
          valores: producto.presentaciones
              .where((item) => item.pendiente > 0)
              .map((item) => item.pendienteTexto)
              .toList(),
          color: const Color(0xFFF57C00),
        ),
        const SizedBox(height: 10),
        Text(
          '${producto.cantidadPedidos} pedidos • ${producto.cantidadClientes} clientes',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            final ver = OutlinedButton.icon(
              onPressed: onVerDistribucion,
              icon: const Icon(Icons.list_alt_outlined, size: 17),
              label: const Text('Ver distribución'),
              style: _outlinedStyle,
            );
            final registrar = ElevatedButton.icon(
              onPressed: producto.pendiente > 0 ? onRegistrarPreparacion : null,
              icon: const Icon(Icons.check, size: 17),
              label: Text(
                producto.completo
                    ? 'Preparación completa'
                    : 'Registrar preparación',
              ),
              style: _primaryStyle,
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [ver, const SizedBox(height: 8), registrar],
              );
            }
            return Row(
              children: [
                Expanded(child: ver),
                const SizedBox(width: 8),
                Expanded(child: registrar),
              ],
            );
          },
        ),
      ],
    ),
  );

  String get _clasificacion => [
    producto.categoria,
    producto.subcategoria,
    producto.empresa ?? producto.marca,
  ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' • ');

  static final _outlinedStyle = OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF1F1F1F),
    side: const BorderSide(color: Color(0xFFE0E0E0)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static final _primaryStyle = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFFC500),
    foregroundColor: Colors.black,
    disabledBackgroundColor: const Color(0xFFE0E0E0),
    disabledForegroundColor: const Color(0xFF757575),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 0,
  );
}

class _PresentacionesResumen extends StatelessWidget {
  const _PresentacionesResumen({
    required this.label,
    required this.valores,
    this.color = const Color(0xFF1F1F1F),
    this.secundaria = false,
  });

  final String label;
  final List<String> valores;
  final Color color;
  final bool secundaria;

  @override
  Widget build(BuildContext context) {
    final items = valores.isEmpty ? const ['0'] : valores;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF757575),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: items
                .map(
                  (value) => Text(
                    secundaria ? value : '• $value',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: secundaria
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: secundaria ? const Color(0xFF757575) : color,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ImagenProducto extends StatelessWidget {
  const _ImagenProducto({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final file = path == null || path!.trim().isEmpty ? null : File(path!);
    return Container(
      width: 58,
      height: 58,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: file != null && file.existsSync()
          ? Image.file(file, fit: BoxFit.cover)
          : const Icon(Icons.image_outlined, color: Color(0xFFBDBDBD)),
    );
  }
}
