import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/producto_detalle.dart';
import '../../domain/entities/producto_variante.dart';
import '../../domain/repositories/catalogo_repository.dart';
import '../bloc/producto_detalle/producto_detalle_bloc.dart';

const _yellow = Color(0xFFFFC500);
const _ink = Color(0xFF1F1F1F);
const _muted = Color(0xFF667085);
const _border = Color(0xFFE1E5EA);
const _surface = Color(0xFFF7F8FA);

/// Diálogo de detalle del producto, expuesto como superficie pública del módulo.
class ProductoDetalleDialog extends StatelessWidget {
  const ProductoDetalleDialog({
    this.onEditar,
    this.onCambiarEstado,
    this.onAgregar,
    super.key,
  });

  final ValueChanged<ProductoDetalle>? onEditar;
  final ValueChanged<ProductoDetalle>? onCambiarEstado;
  final ValueChanged<ProductoDetalle>? onAgregar;

  static Future<void> show(
    BuildContext context, {
    required String productoId,
    ValueChanged<ProductoDetalle>? onEditar,
    ValueChanged<ProductoDetalle>? onCambiarEstado,
    ValueChanged<ProductoDetalle>? onAgregar,
  }) => showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .66),
    builder: (_) => BlocProvider(
      create: (_) =>
          ProductoDetalleBloc(context.read<CatalogoRepository>())
            ..add(ProductoDetalleSolicitado(productoId)),
      child: ProductoDetalleDialog(
        onEditar: onEditar,
        onCambiarEstado: onCambiarEstado,
        onAgregar: onAgregar,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SizedBox(
        width: math.min(1120, math.max(320, size.width - 24)),
        height: math.min(920, math.max(440, size.height - 20)),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: BlocBuilder<ProductoDetalleBloc, ProductoDetalleState>(
            builder: (context, state) {
              if (state.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: _yellow),
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
                onAgregar: onAgregar,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ContenidoDetalle extends StatelessWidget {
  const _ContenidoDetalle({
    required this.producto,
    this.onEditar,
    this.onCambiarEstado,
    this.onAgregar,
  });

  final ProductoDetalle producto;
  final ValueChanged<ProductoDetalle>? onEditar;
  final ValueChanged<ProductoDetalle>? onCambiarEstado;
  final ValueChanged<ProductoDetalle>? onAgregar;

  @override
  Widget build(BuildContext context) {
    final view = _ProductCommercialView.from(producto);
    return Column(
      children: [
        _header(context, view),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('producto_detalle_scroll'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _overview(view),
                if (producto.descripcion.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _section(
                    icon: Icons.notes_rounded,
                    title: 'Descripción',
                    child: Text(
                      producto.descripcion.trim(),
                      style: GoogleFonts.inter(
                        color: _ink,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                if (producto.atributos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _section(
                    icon: Icons.tune_rounded,
                    title: 'Características comunes',
                    subtitle:
                        'Datos de la familia que se aplican a todas las '
                        'variantes.',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: producto.atributos.entries
                          .where((entry) => entry.value.trim().isNotEmpty)
                          .map(
                            (entry) =>
                                _InfoChip(label: entry.key, value: entry.value),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _variantSection(view),
                if (view.logistics.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _logisticsSection(view),
                ],
                if (view.content.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _contentSection(view),
                ],
              ],
            ),
          ),
        ),
        _footer(context),
      ],
    );
  }

  Widget _header(BuildContext context, _ProductCommercialView view) =>
      Container(
        color: _ink,
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: _yellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: _ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ficha del producto',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${_typeLabel(producto.tipoRegistro)} · '
                    '${view.activeVariants.length} activas de '
                    '${view.variants.length}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB7BAC1),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
      );

  Widget _overview(_ProductCommercialView view) => LayoutBuilder(
    builder: (context, constraints) {
      final gallery = _ProductGallery(
        paths: producto.imagenesPaths.isNotEmpty
            ? producto.imagenesPaths
            : producto.imagenPath == null
            ? const []
            : [producto.imagenPath!],
      );
      final information = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _Pill(
                label: producto.activo ? 'Activo' : 'Inactivo',
                color: producto.activo
                    ? const Color(0xFF067647)
                    : const Color(0xFFB42318),
              ),
              _Pill(
                label: _typeLabel(producto.tipoRegistro),
                color: const Color(0xFF175CD3),
              ),
              _Pill(
                label: '${view.presentationsCount} combinaciones vendibles',
                color: const Color(0xFF6941C6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            producto.nombre,
            style: GoogleFonts.inter(
              color: _ink,
              fontSize: 25,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Código de familia: ${producto.codigo}',
            style: GoogleFonts.inter(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          _InfoRow('Empresa', producto.empresa),
          _InfoRow('Marca', producto.marca),
          _InfoRow(
            'Clasificación',
            producto.subcategoria.trim().isEmpty
                ? producto.categoria
                : '${producto.categoria} › ${producto.subcategoria}',
          ),
          _InfoRow('Registrado', _date(producto.creadoEn)),
        ],
      );

      if (constraints.maxWidth >= 760) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              key: const Key('producto_detalle_galeria'),
              width: 350,
              height: 371,
              child: gallery,
            ),
            const SizedBox(width: 22),
            Expanded(child: information),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: const Key('producto_detalle_galeria'),
            height: 364,
            child: gallery,
          ),
          const SizedBox(height: 18),
          information,
        ],
      );
    },
  );

  Widget _variantSection(_ProductCommercialView view) {
    switch (producto.tipoRegistro) {
      case 'matriz':
        return _section(
          icon: Icons.grid_view_rounded,
          title: 'Matriz de variantes',
          subtitle:
              'Las celdas representan combinaciones reales de los dos ejes. '
              'Debajo se detallan código, atributos, presentaciones y precios.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MatrixOverview(view: view),
              const SizedBox(height: 14),
              _VariantCards(variants: view.variants),
            ],
          ),
        );
      case 'variantes':
        return _section(
          icon: Icons.view_list_rounded,
          title: 'Lista de variantes',
          subtitle:
              'Cada bloque es un artículo distinto. Los precios se muestran '
              'por variante, presentación y lista.',
          child: _VariantCards(variants: view.variants),
        );
      default:
        return _section(
          icon: Icons.check_circle_outline_rounded,
          title: 'Artículo vendible',
          subtitle: 'Este producto tiene una única variante comercial.',
          child: _VariantCards(variants: view.variants),
        );
    }
  }

  Widget _logisticsSection(_ProductCommercialView view) => _section(
    icon: Icons.local_shipping_outlined,
    title: 'Empaques logísticos',
    subtitle:
        'Sirven para transporte y almacenamiento; no sustituyen las '
        'presentaciones que compra el cliente.',
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: view.logistics.map((item) {
        return Container(
          width: 285,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: GoogleFonts.inter(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_plain(item.total)} ${item.unit} en total',
                style: GoogleFonts.inter(color: _muted, fontSize: 11),
              ),
              if (item.supplierCode.isNotEmpty)
                Text(
                  'Código proveedor: ${item.supplierCode}',
                  style: GoogleFonts.inter(color: _muted, fontSize: 10),
                ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  item.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _ink,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    ),
  );

  Widget _contentSection(_ProductCommercialView view) => _section(
    icon: Icons.category_outlined,
    title: 'Contenido del producto',
    subtitle:
        'Componentes incluidos cuando la variante representa un juego, kit '
        'o set.',
    child: Column(
      children: view.content.map((item) {
        final owner = view.variants
            .where((variant) => variant.id == item.ownerVariantId)
            .firstOrNull;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFFFF4CC),
            foregroundColor: _ink,
            child: Icon(Icons.check_rounded),
          ),
          title: Text(
            item.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
          subtitle: owner == null ? null : Text(owner.name),
          trailing: Text(
            '${_plain(item.quantity)} ${item.unit}',
            style: GoogleFonts.inter(color: _ink, fontWeight: FontWeight.w900),
          ),
        );
      }).toList(),
    ),
  );

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
    String? subtitle,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4CC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _ink, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: _muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _footer(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: _border)),
    ),
    child: SafeArea(
      top: false,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 9,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (onCambiarEstado != null)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onCambiarEstado!(producto);
              },
              icon: Icon(
                producto.activo
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              label: Text(producto.activo ? 'Desactivar' : 'Activar'),
            ),
          if (onEditar != null)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onEditar!(producto);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _ink,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
          if (onAgregar != null)
            FilledButton.icon(
              key: const Key('agregar_desde_detalle'),
              onPressed: producto.activo
                  ? () {
                      Navigator.pop(context);
                      onAgregar!(producto);
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _ink,
              ),
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Seleccionar y agregar'),
            ),
        ],
      ),
    ),
  );
}

class _VariantCards extends StatelessWidget {
  const _VariantCards({required this.variants});

  final List<_VariantView> variants;

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) {
      return const _EmptyMessage(
        'No hay variantes registradas para este producto.',
      );
    }
    return Column(
      children: variants.map((variant) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _VariantCard(variant: variant),
        );
      }).toList(),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({required this.variant});

  final _VariantView variant;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: variant.active ? _surface : const Color(0xFFFAF2F2),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: variant.active ? _border : const Color(0xFFF1B5B5),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.name,
                    style: GoogleFonts.inter(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    variant.sku.isEmpty
                        ? 'Sin código interno'
                        : 'SKU: ${variant.sku}',
                    style: GoogleFonts.inter(color: _muted, fontSize: 11),
                  ),
                  if (variant.supplierCode.isNotEmpty)
                    Text(
                      'Código proveedor: ${variant.supplierCode}',
                      style: GoogleFonts.inter(color: _muted, fontSize: 11),
                    ),
                ],
              ),
            ),
            _Pill(
              label: variant.active ? 'Activa' : 'Inactiva',
              color: variant.active
                  ? const Color(0xFF067647)
                  : const Color(0xFFB42318),
            ),
          ],
        ),
        if (variant.attributes.isNotEmpty) ...[
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: variant.attributes.entries
                .map(
                  (entry) => _InfoChip(
                    label: entry.key,
                    value: entry.value,
                    compact: true,
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        if (variant.presentations.isEmpty)
          const _EmptyMessage(
            'Esta variante no tiene presentaciones de venta asignadas.',
          )
        else
          ...variant.presentations.map(
            (presentation) => _PresentationCard(presentation: presentation),
          ),
      ],
    ),
  );
}

class _PresentationCard extends StatelessWidget {
  const _PresentationCard({required this.presentation});

  final _PresentationView presentation;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${presentation.name} · ${presentation.equivalence}',
                style: GoogleFonts.inter(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (presentation.isDefault)
              const _Pill(label: 'Predeterminada', color: Color(0xFF8A6500)),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: presentation.prices
              .map((price) => _PricePill(price: price))
              .toList(),
        ),
        const SizedBox(height: 6),
        Text(
          'Pedido mínimo: ${_plain(presentation.minimum)} · '
          'Incremento: ${_plain(presentation.increment)}',
          style: GoogleFonts.inter(color: _muted, fontSize: 9),
        ),
      ],
    ),
  );
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.price});

  final _PriceView price;

  @override
  Widget build(BuildContext context) {
    final color = switch (price.type) {
      'fixed' => const Color(0xFF067647),
      'quantity' => const Color(0xFF175CD3),
      'quote' => const Color(0xFFB54708),
      _ => const Color(0xFFB42318),
    };
    final text = switch (price.type) {
      'fixed' => '${price.listName}: ${_money(price.currency, price.value)}',
      'quantity' =>
        '${price.listName}: ${price.rangeCount} '
            '${price.rangeCount == 1 ? 'rango' : 'rangos'}',
      'quote' => '${price.listName}: Por cotizar',
      _ => '${price.listName}: Pendiente',
    };
    return _Pill(label: text, color: color);
  }
}

class _MatrixOverview extends StatelessWidget {
  const _MatrixOverview({required this.view});

  final _ProductCommercialView view;

  @override
  Widget build(BuildContext context) {
    if (view.axes.length < 2) {
      return const _EmptyMessage(
        'No fue posible identificar dos ejes distintos. '
        'Las variantes se muestran como lista.',
      );
    }
    final rowAxis = view.axes[0];
    final columnAxis = view.axes[1];
    final rows = view.variants
        .map((item) => item.attributes[rowAxis])
        .whereType<String>()
        .toSet()
        .toList();
    final columns = view.variants
        .map((item) => item.attributes[columnAxis])
        .whereType<String>()
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _Pill(label: 'Filas: $rowAxis', color: const Color(0xFF175CD3)),
            _Pill(
              label: 'Columnas: $columnAxis',
              color: const Color(0xFF6941C6),
            ),
          ],
        ),
        const SizedBox(height: 11),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(175),
            border: TableBorder.all(color: _border),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF1F3F6)),
                children: [
                  _matrixHeader('$rowAxis / $columnAxis'),
                  ...columns.map(_matrixHeader),
                ],
              ),
              ...rows.map((rowValue) {
                return TableRow(
                  children: [
                    _matrixHeader(rowValue),
                    ...columns.map((columnValue) {
                      final variant = view.variants
                          .where(
                            (item) =>
                                item.attributes[rowAxis] == rowValue &&
                                item.attributes[columnAxis] == columnValue,
                          )
                          .firstOrNull;
                      if (variant == null) {
                        return const SizedBox(
                          height: 82,
                          child: Center(
                            child: Text(
                              'No existe',
                              style: TextStyle(color: _muted),
                            ),
                          ),
                        );
                      }
                      return Container(
                        constraints: const BoxConstraints(minHeight: 82),
                        padding: const EdgeInsets.all(8),
                        color: variant.active
                            ? Colors.white
                            : const Color(0xFFFAF2F2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              variant.sku.isEmpty ? variant.name : variant.sku,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: _ink,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              variant.active ? 'Activa' : 'Inactiva',
                              style: GoogleFonts.inter(
                                color: variant.active
                                    ? const Color(0xFF067647)
                                    : const Color(0xFFB42318),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _matrixHeader(String value) => Container(
    constraints: const BoxConstraints(minHeight: 50),
    padding: const EdgeInsets.all(9),
    alignment: Alignment.center,
    child: Text(
      value,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: _ink,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _ProductCommercialView {
  const _ProductCommercialView({
    required this.variants,
    required this.axes,
    required this.logistics,
    required this.content,
  });

  final List<_VariantView> variants;
  final List<String> axes;
  final List<_LogisticsView> logistics;
  final List<_ContentView> content;

  List<_VariantView> get activeVariants =>
      variants.where((item) => item.active).toList();

  int get presentationsCount =>
      variants.fold(0, (total, item) => total + item.presentations.length);

  factory _ProductCommercialView.from(ProductoDetalle product) {
    final sourceVariants = product.variantes.isEmpty
        ? [
            ProductoVariante(
              id: product.id,
              sku: product.codigo,
              nombreCorto: product.nombre,
              atributos: product.atributos.entries
                  .map(
                    (entry) => AtributoProductoVariante.fromText(
                      entry.key,
                      entry.value,
                    ),
                  )
                  .toList(),
              activa: product.activo,
              imagenPath:
                  product.imagenPath ?? product.imagenesPaths.firstOrNull,
            ),
          ]
        : product.variantes;

    final sales = product.ventaLogisticaContenido ?? const {};
    final pricing = product.preciosConfigurados ?? const {};
    final presentations = _maps(sales['presentations']);
    final lists = _priceLists(pricing, product);
    final prices = _maps(pricing['prices']);

    final variants = sourceVariants.map((variant) {
      final variantPresentations = presentations.isEmpty
          ? product.presentaciones.asMap().entries.map((entry) {
              return _PresentationView(
                id:
                    product.precios
                        .where(
                          (price) =>
                              price.presentacion == entry.value.nombre &&
                              price.presentacionId.isNotEmpty,
                        )
                        .map((price) => price.presentacionId)
                        .firstOrNull ??
                    'legacy-${entry.key}',
                name: entry.value.nombre,
                equivalence: entry.value.unidad,
                minimum: 1,
                increment: 1,
                isDefault: entry.key == 0,
                prices: _resolvePrices(
                  product,
                  variant.id,
                  'legacy-${entry.key}',
                  entry.value.nombre,
                  lists,
                  const [],
                ),
              );
            }).toList()
          : presentations
                .where((item) {
                  final assigned = _strings(item['assigned_variant_ids']);
                  return assigned.isEmpty || assigned.contains(variant.id);
                })
                .map((item) {
                  final rules = _maps(item['variant_rules']);
                  final rule = rules
                      .where(
                        (rule) => rule['variant_id']?.toString() == variant.id,
                      )
                      .firstOrNull;
                  final equivalent =
                      _number(rule?['equivalent_to']) ??
                      _number(item['equivalent_to']) ??
                      1;
                  final unit = item['base_unit']?.toString() ?? 'UND';
                  final id = item['id']?.toString() ?? '';
                  final name = item['name']?.toString() ?? 'Presentación';
                  return _PresentationView(
                    id: id,
                    name: name,
                    equivalence: '${_plain(equivalent)} $unit',
                    minimum:
                        _number(rule?['minimum_order']) ??
                        _number(item['minimum_order']) ??
                        1,
                    increment:
                        _number(rule?['purchase_increment']) ??
                        _number(item['purchase_increment']) ??
                        1,
                    isDefault: _strings(
                      item['default_variant_ids'],
                    ).contains(variant.id),
                    prices: _resolvePrices(
                      product,
                      variant.id,
                      id,
                      name,
                      lists,
                      prices,
                    ),
                  );
                })
                .toList();

      return _VariantView(
        id: variant.id,
        name: variant.nombreCorto.trim().isEmpty
            ? variant.sku
            : variant.nombreCorto,
        sku: variant.sku,
        supplierCode: variant.codigoProveedor,
        active: variant.activa,
        attributes: {
          for (final attribute in variant.atributos)
            if (attribute.texto.isNotEmpty) attribute.nombre: attribute.texto,
        },
        presentations: variantPresentations,
      );
    }).toList();

    final attributeNames = <String>[];
    for (final variant in variants) {
      for (final name in variant.attributes.keys) {
        if (!attributeNames.contains(name)) attributeNames.add(name);
      }
    }
    final axes = attributeNames
        .where(
          (name) =>
              variants
                  .map((item) => item.attributes[name])
                  .whereType<String>()
                  .toSet()
                  .length >
              1,
        )
        .take(2)
        .toList();

    return _ProductCommercialView(
      variants: variants,
      axes: axes,
      logistics: _maps(sales['logistics_packages'])
          .map(
            (item) => _LogisticsView(
              name: item['name']?.toString() ?? 'Empaque',
              total: _number(item['total_base_units']) ?? 1,
              unit: item['base_unit']?.toString() ?? 'UND',
              supplierCode: item['supplier_code']?.toString() ?? '',
              description: item['description']?.toString() ?? '',
            ),
          )
          .toList(),
      content: _maps(sales['content_items'])
          .map(
            (item) => _ContentView(
              ownerVariantId: item['owner_variant_id']?.toString() ?? '',
              name: item['component_name']?.toString() ?? 'Componente',
              quantity: _number(item['quantity']) ?? 1,
              unit: item['unit']?.toString() ?? 'PZA',
            ),
          )
          .toList(),
    );
  }

  static List<_PriceView> _resolvePrices(
    ProductoDetalle product,
    String variantId,
    String presentationId,
    String presentationName,
    List<_PriceListView> lists,
    List<Map<String, dynamic>> configured,
  ) {
    return lists.map((list) {
      final row = configured
          .where(
            (item) =>
                item['list_id']?.toString() == list.id &&
                item['variant_id']?.toString() == variantId &&
                item['presentation_id']?.toString() == presentationId,
          )
          .firstOrNull;
      if (row != null) {
        final type = row['configuration']?.toString() ?? 'unconfigured';
        return _PriceView(
          listName: list.name,
          currency: list.currency,
          type: type,
          value: _number(row['fixed_price']),
          rangeCount: _maps(row['ranges']).length,
        );
      }

      final legacy = product.precios
          .where(
            (price) =>
                (price.listaPrecioId.isEmpty ||
                    price.listaPrecioId == list.id) &&
                (price.varianteId.isEmpty || price.varianteId == variantId) &&
                ((price.presentacionId.isNotEmpty &&
                        price.presentacionId == presentationId) ||
                    price.presentacion == presentationName),
          )
          .firstOrNull;
      if (legacy != null) {
        return _PriceView(
          listName: list.name,
          currency: list.currency,
          type: legacy.configuracion == 'por_cantidad'
              ? 'quantity'
              : legacy.configuracion == 'por_cotizar'
              ? 'quote'
              : 'fixed',
          value: legacy.valor,
          rangeCount: legacy.configuracion == 'por_cantidad' ? 1 : 0,
        );
      }
      return _PriceView(
        listName: list.name,
        currency: list.currency,
        type: 'unconfigured',
      );
    }).toList();
  }

  static List<_PriceListView> _priceLists(
    Map<String, dynamic> pricing,
    ProductoDetalle product,
  ) {
    final configured = _maps(pricing['lists'])
        .map(
          (item) => _PriceListView(
            id: item['id']?.toString() ?? '',
            name: item['name']?.toString() ?? 'Lista',
            currency: item['currency_code']?.toString() ?? 'PEN',
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();
    if (configured.isNotEmpty) return configured;

    final ids = product.precios
        .map((item) => item.listaPrecioId)
        .where((item) => item.isNotEmpty)
        .toSet();
    if (ids.isEmpty) {
      return const [
        _PriceListView(id: 'regular', name: 'Regular', currency: 'PEN'),
      ];
    }
    return ids
        .map((id) => _PriceListView(id: id, name: id, currency: 'PEN'))
        .toList();
  }
}

class _VariantView {
  const _VariantView({
    required this.id,
    required this.name,
    required this.sku,
    required this.supplierCode,
    required this.active,
    required this.attributes,
    required this.presentations,
  });

  final String id;
  final String name;
  final String sku;
  final String supplierCode;
  final bool active;
  final Map<String, String> attributes;
  final List<_PresentationView> presentations;
}

class _PresentationView {
  const _PresentationView({
    required this.id,
    required this.name,
    required this.equivalence,
    required this.minimum,
    required this.increment,
    required this.isDefault,
    required this.prices,
  });

  final String id;
  final String name;
  final String equivalence;
  final double minimum;
  final double increment;
  final bool isDefault;
  final List<_PriceView> prices;
}

class _PriceView {
  const _PriceView({
    required this.listName,
    required this.currency,
    required this.type,
    this.value,
    this.rangeCount = 0,
  });

  final String listName;
  final String currency;
  final String type;
  final double? value;
  final int rangeCount;
}

class _PriceListView {
  const _PriceListView({
    required this.id,
    required this.name,
    required this.currency,
  });

  final String id;
  final String name;
  final String currency;
}

class _LogisticsView {
  const _LogisticsView({
    required this.name,
    required this.total,
    required this.unit,
    required this.supplierCode,
    required this.description,
  });

  final String name;
  final double total;
  final String unit;
  final String supplierCode;
  final String description;
}

class _ContentView {
  const _ContentView({
    required this.ownerVariantId,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  final String ownerVariantId;
  final String name;
  final double quantity;
  final String unit;
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({required this.paths});

  final List<String> paths;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  int index = 0;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: ColoredBox(
      color: _surface,
      child: widget.paths.isEmpty
          ? const Center(
              child: Icon(
                Icons.inventory_2_outlined,
                size: 72,
                color: Color(0xFFB7BDC6),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  itemCount: widget.paths.length,
                  onPageChanged: (value) => setState(() => index = value),
                  itemBuilder: (_, itemIndex) => Image.file(
                    File(widget.paths[itemIndex]),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      size: 58,
                      color: Color(0xFFB7BDC6),
                    ),
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
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${index + 1}/${widget.paths.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 8 : 10,
      vertical: compact ? 5 : 7,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _border),
    ),
    child: Text(
      '$label: $value',
      style: GoogleFonts.inter(
        color: _ink,
        fontSize: compact ? 9 : 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(message, style: GoogleFonts.inter(color: _muted, fontSize: 11)),
  );
}

class _ErrorDetalle extends StatelessWidget {
  const _ErrorDetalle({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Color(0xFFB42318),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: _yellow,
              foregroundColor: _ink,
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    ),
  );
}

List<Map<String, dynamic>> _maps(Object? source) {
  if (source is! List) return const [];
  return source
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Set<String> _strings(Object? source) =>
    source is List ? source.map((item) => item.toString()).toSet() : <String>{};

double? _number(Object? source) => source is num
    ? source.toDouble()
    : double.tryParse(source?.toString().replaceAll(',', '.') ?? '');

String _typeLabel(String value) => switch (value) {
  'variantes' => 'Lista de variantes',
  'matriz' => 'Matriz de variantes',
  _ => 'Producto único',
};

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _plain(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value
          .toStringAsFixed(3)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');

String _money(String currency, double? value) {
  if (value == null) return 'Pendiente';
  final symbol = switch (currency.toUpperCase()) {
    'USD' => 'US\$',
    'EUR' => '€',
    _ => 'S/',
  };
  return '$symbol ${value.toStringAsFixed(2)}';
}
