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

  bool get _esComercial => onAgregar != null;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0F0F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .04),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: isGrid ? _grid() : _list(),
  );

  Widget _grid() => LayoutBuilder(
    builder: (context, constraints) {
      final compacto = constraints.maxHeight < 450;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagen(height: compacto ? 170 : 212),
          Expanded(
            child: _contenidoAdministrativo(
              expandido: true,
              compacto: compacto,
            ),
          ),
        ],
      );
    },
  );

  Widget _list() => LayoutBuilder(
    builder: (context, constraints) {
      final contenido = _contenidoAdministrativo(
        expandido: false,
        compacto: true,
      );
      if (constraints.maxWidth < 600) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_imagen(height: 206), contenido],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 264, child: _imagen(height: 264)),
            Expanded(child: contenido),
          ],
        ),
      );
    },
  );

  Widget _imagen({required double height}) => SizedBox(
    key: Key('producto_imagen_${producto.id}'),
    width: double.infinity,
    height: height,
    child: Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: const Color(0xFFF8F9FA),
                child: _imagenProducto(),
              ),
            ),
          ),
        ),
        Positioned(top: 20, right: 20, child: _badgeEstado()),
      ],
    ),
  );

  Widget _imagenProducto() {
    final path = producto.imagenPath ?? producto.imagenesPaths.firstOrNull;
    if (path == null) {
      return const Icon(
        Icons.inventory_2_outlined,
        size: 58,
        color: Color(0xFFBDBDBD),
      );
    }
    return Image.file(
      File(path),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.broken_image_outlined,
        size: 56,
        color: Color(0xFFBDBDBD),
      ),
    );
  }

  Widget _contenidoAdministrativo({
    required bool expandido,
    required bool compacto,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: expandido ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Text(
          producto.tipoRegistro == 'unico'
              ? 'SKU: ${producto.codigo.toUpperCase()}'
              : _tipoNombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: const Color(0xFF8A8A8A),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        _titulo(),
        const SizedBox(height: 4),
        _clasificacion(),
        const SizedBox(height: 10),
        _etiquetasAdministrativas(compacto),
        if (expandido) const Spacer() else const SizedBox(height: 14),
        _precio(fontSize: 14),
        const SizedBox(height: 10),
        _esComercial ? _accionesComerciales() : _accionesAdministrativas(),
      ],
    ),
  );

  Widget _titulo() => Text(
    producto.nombre,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: GoogleFonts.inter(
      fontSize: 16,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1A1A1A),
    ),
  );

  Widget _clasificacion() {
    final categoria = producto.subcategoria.trim().isEmpty
        ? producto.categoria
        : '${producto.categoria} › ${producto.subcategoria}';
    return Text(
      '${producto.marca} · $categoria',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(color: const Color(0xFF8A8A8A), fontSize: 12),
    );
  }

  Widget _etiquetasAdministrativas(bool compacto) {
    final presentations = _presentaciones
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final limit = compacto ? 2 : 3;
    final hidden = presentations.length - limit;

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _chipTipo(),
        ...presentations
            .take(limit)
            .map((presentacion) => _chipPresentacion(presentacion)),
        if (hidden > 0) _chipMasPresentaciones(hidden),
      ],
    );
  }

  Widget _chipMasPresentaciones(int cantidad) => Container(
    key: Key('producto_presentaciones_restantes_${producto.id}'),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F4F7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFD0D5DD)),
    ),
    child: Text(
      '+$cantidad más',
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF475467),
      ),
    ),
  );

  Widget _chipTipo() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: _tipoColor.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _tipoColor.withValues(alpha: .3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_tipoIcono, size: 13, color: _tipoColor),
        const SizedBox(width: 4),
        Text(
          _tipoNombre,
          style: GoogleFonts.inter(
            color: _tipoColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _chipPresentacion(String texto) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFC500).withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFFC500).withValues(alpha: .55)),
    ),
    child: Text(
      texto,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      ),
    ),
  );

  Widget _precio({required double fontSize}) => Text(
    _precioTexto,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: _precioColor,
      letterSpacing: .1,
    ),
  );

  Widget _accionesAdministrativas() => Row(
    children: [
      Expanded(
        child: _botonSecundario(
          key: Key('ver_producto_${producto.id}'),
          texto: 'Ver',
          onPressed: onVerDetalle,
        ),
      ),
      if (onEditar != null) ...[
        const SizedBox(width: 7),
        Expanded(
          child: _botonSecundario(
            key: Key('editar_producto_${producto.id}'),
            texto: 'Editar',
            onPressed: onEditar,
          ),
        ),
      ],
      if (onCambiarEstado != null) ...[
        const SizedBox(width: 7),
        Expanded(
          child: OutlinedButton(
            key: Key('estado_producto_${producto.id}'),
            onPressed: onCambiarEstado,
            style: OutlinedButton.styleFrom(
              foregroundColor: producto.activo
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF2E7D32),
              backgroundColor: producto.activo
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFE8F5E9),
              side: BorderSide(
                color: producto.activo
                    ? const Color(0xFFEF9A9A)
                    : const Color(0xFFA5D6A7),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(producto.activo ? 'Desactivar' : 'Activar'),
            ),
          ),
        ),
      ],
    ],
  );

  Widget _accionesComerciales() => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          key: Key('ver_producto_${producto.id}'),
          onPressed: onVerDetalle,
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Ver')),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1F1F1F),
            side: const BorderSide(color: Color(0xFFDADADA)),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
            minimumSize: const Size(0, 38),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: ElevatedButton.icon(
          key: Key('agregar_producto_${producto.id}'),
          onPressed: onAgregar,
          icon: const Icon(Icons.add_shopping_cart, size: 16),
          label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Agregar')),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: const Color(0xFFFFC500),
            shadowColor: const Color(0xFFFFC500),
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
            minimumSize: const Size(0, 38),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _botonSecundario({
    required Key key,
    required String texto,
    required VoidCallback? onPressed,
  }) => OutlinedButton(
    key: key,
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1F1F1F),
      side: const BorderSide(color: Color(0xFFDADADA)),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
    ),
    child: FittedBox(fit: BoxFit.scaleDown, child: Text(texto)),
  );

  Widget _badgeEstado() {
    final background = producto.activo
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFCE4EC);
    final foreground = producto.activo
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: producto.activo
              ? const Color(0xFFA5D6A7)
              : const Color(0xFFF48FB1),
        ),
      ),
      child: Text(
        producto.activo ? 'Activo' : 'Inactivo',
        style: GoogleFonts.inter(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<String> get _presentaciones => producto.presentaciones.isEmpty
      ? [producto.unidadVenta]
      : producto.presentaciones;

  String get _precioTexto {
    if (producto.sinPrecio || producto.precio == null) return 'Por cotizar';
    final precio = producto.precio!.toStringAsFixed(2);
    final prefijo = producto.tipoRegistro == 'unico' ? '' : 'Desde ';
    return '${prefijo}S/ $precio por ${producto.unidadVenta.toLowerCase()}';
  }

  Color get _precioColor {
    if (producto.sinPrecio || producto.precio == null) {
      return const Color(0xFFC62828);
    }
    return const Color(0xFF2E7D32);
  }

  String get _tipoNombre => switch (producto.tipoRegistro) {
    'variantes' => 'Con variantes',
    'matriz' => 'Matriz de medidas',
    _ => 'Único',
  };

  Color get _tipoColor => switch (producto.tipoRegistro) {
    'variantes' => const Color(0xFF0288D1),
    'matriz' => const Color(0xFF5C6BC0),
    _ => const Color(0xFF00897B),
  };

  IconData get _tipoIcono => switch (producto.tipoRegistro) {
    'variantes' => Icons.list_alt_outlined,
    'matriz' => Icons.grid_view_outlined,
    _ => Icons.check_circle_outline,
  };
}
