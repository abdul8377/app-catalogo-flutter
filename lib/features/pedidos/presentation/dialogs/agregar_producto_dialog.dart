import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../catalogo/domain/entities/producto_detalle.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../../domain/entities/pedido.dart';
import '../../domain/services/producto_pedido_resolver.dart';

const _yellow = Color(0xFFFFC500);
const _ink = Color(0xFF1F1F1F);
const _muted = Color(0xFF667085);
const _border = Color(0xFFE1E5EA);
const _surface = Color(0xFFF7F8FA);

/// Diálogo de selección y configuración de un producto para el pedido.
class AgregarProductoDialog extends StatefulWidget {
  const AgregarProductoDialog({required this.productoId, super.key});

  final String productoId;

  static Future<PedidoItem?> show(
    BuildContext context, {
    required String productoId,
  }) => showDialog<PedidoItem>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .66),
    builder: (_) => RepositoryProvider<CatalogoRepository>.value(
      value: context.read<CatalogoRepository>(),
      child: AgregarProductoDialog(productoId: productoId),
    ),
  );

  @override
  State<AgregarProductoDialog> createState() => _AgregarProductoDialogState();
}

class _AgregarProductoDialogState extends State<AgregarProductoDialog> {
  late final Future<ProductoDetalle?> _detalle;
  final TextEditingController _cantidadController = TextEditingController(
    text: '1',
  );
  final Map<String, String> _axisValues = {};

  String? _variantId;
  String? _presentationId;
  String? _priceListId;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _detalle = context.read<CatalogoRepository>().obtenerDetalleProducto(
      widget.productoId,
    );
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SizedBox(
        width: math.min(980, math.max(320, size.width - 24)),
        height: math.min(900, math.max(440, size.height - 20)),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: FutureBuilder<ProductoDetalle?>(
            future: _detalle,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: _yellow),
                );
              }
              final product = snapshot.data;
              if (product == null) {
                return const Center(
                  child: Text('El producto ya no está disponible.'),
                );
              }
              final resolved = ProductoPedidoResolver.resolver(product);
              _initialize(resolved);
              return _content(resolved);
            },
          ),
        ),
      ),
    );
  }

  void _initialize(ProductoPedidoResuelto resolved) {
    if (resolved.listas.isNotEmpty && _priceListId == null) {
      _priceListId = resolved.listaPredeterminada.id;
    }
    final variants = resolved.variantesActivas;
    if (variants.isEmpty) return;
    final current = variants.where((item) => item.id == _variantId).firstOrNull;
    final variant = current ?? variants.first;
    _variantId = variant.id;
    for (final axis in resolved.ejes) {
      final value = variant.atributos[axis];
      if (value != null) _axisValues[axis] = value;
    }
    final currentPresentation = variant.presentaciones
        .where((item) => item.id == _presentationId)
        .firstOrNull;
    final presentation =
        currentPresentation ??
        variant.presentaciones
            .where((item) => item.predeterminada)
            .firstOrNull ??
        variant.presentaciones.firstOrNull;
    _presentationId = presentation?.id;
    if (presentation != null && !_validQuantity(presentation, _quantity)) {
      _setQuantity(presentation.pedidoMinimo, rebuild: false);
    }
  }

  Widget _content(ProductoPedidoResuelto resolved) {
    final product = resolved.producto;
    final variants = resolved.variantesActivas;
    final variant = variants.where((item) => item.id == _variantId).firstOrNull;
    final presentation = variant?.presentaciones
        .where((item) => item.id == _presentationId)
        .firstOrNull;
    final price = presentation?.precioParaLista(_priceListId ?? '');
    final unitPrice = price?.precioPara(_quantity);
    final quantityValid =
        presentation != null && _validQuantity(presentation, _quantity);
    final canAdd =
        variant != null &&
        presentation != null &&
        quantityValid &&
        (price?.permiteAgregar ?? false) &&
        (price?.tipo != TipoPrecioPedido.cantidad || unitPrice != null);

    return Column(
      children: [
        _header(product),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('agregar_producto_scroll'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _productSummary(product, variant),
                const SizedBox(height: 18),
                if (variants.isEmpty)
                  const _Notice(
                    message:
                        'Este producto no tiene variantes activas disponibles.',
                    danger: true,
                  )
                else ...[
                  _sectionTitle(
                    product.tipoRegistro == 'matriz'
                        ? '1. Selecciona la combinación'
                        : variants.length > 1
                        ? '1. Selecciona la variante'
                        : 'Artículo seleccionado',
                    product.tipoRegistro == 'matriz'
                        ? 'Elige un valor por cada eje. Solo se permiten '
                              'combinaciones existentes y activas.'
                        : 'El pedido conservará el SKU y los atributos de la '
                              'variante exacta.',
                  ),
                  const SizedBox(height: 10),
                  if (product.tipoRegistro == 'matriz' &&
                      resolved.ejes.length >= 2)
                    _matrixSelectors(resolved)
                  else if (variants.length > 1)
                    _variantSelector(variants),
                  if (variant != null) ...[
                    const SizedBox(height: 10),
                    _variantSummary(variant),
                  ],
                  const SizedBox(height: 18),
                  _sectionTitle(
                    product.tipoRegistro == 'unico'
                        ? '1. Selecciona la presentación'
                        : '2. Selecciona la presentación',
                    'La cantidad se expresa en presentaciones vendibles, no '
                    'en unidades base.',
                  ),
                  const SizedBox(height: 10),
                  if (variant == null || variant.presentaciones.isEmpty)
                    const _Notice(
                      message:
                          'La variante seleccionada no tiene presentaciones '
                          'de venta asignadas.',
                      danger: true,
                    )
                  else
                    ...variant.presentaciones.map(
                      (item) => _presentationOption(
                        item,
                        selected: item.id == _presentationId,
                      ),
                    ),
                  const SizedBox(height: 18),
                  _sectionTitle(
                    product.tipoRegistro == 'unico'
                        ? '2. Lista de precios'
                        : '3. Lista de precios',
                    'El precio se resuelve para la variante y presentación '
                    'seleccionadas.',
                  ),
                  const SizedBox(height: 10),
                  _priceListSelector(resolved.listas),
                  const SizedBox(height: 18),
                  _sectionTitle(
                    product.tipoRegistro == 'unico'
                        ? '3. Cantidad'
                        : '4. Cantidad',
                    presentation == null
                        ? 'Selecciona primero una presentación.'
                        : 'Pedido mínimo: ${presentation.pedidoMinimo} · '
                              'incrementos de ${presentation.incremento}.',
                  ),
                  const SizedBox(height: 10),
                  _quantitySelector(presentation),
                  if (presentation != null) ...[
                    const SizedBox(height: 12),
                    _summary(
                      presentation: presentation,
                      price: price,
                      unitPrice: unitPrice,
                      quantityValid: quantityValid,
                    ),
                    if (price?.tipo == TipoPrecioPedido.cotizar &&
                        unitPrice == null) ...[
                      const SizedBox(height: 10),
                      const _Notice(
                        message:
                            'Esta combinación se agregará sin precio y '
                            'quedará marcada como Por cotizar.',
                      ),
                    ] else if (price?.tipo == TipoPrecioPedido.pendiente) ...[
                      const SizedBox(height: 10),
                      const _Notice(
                        message:
                            'Esta combinación está pendiente de configuración '
                            'comercial. Completa su precio o márcala como '
                            'Por cotizar antes de venderla.',
                        danger: true,
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ),
        _footer(
          resolved: resolved,
          variant: variant,
          presentation: presentation,
          price: price,
          unitPrice: unitPrice,
          canAdd: canAdd,
        ),
      ],
    );
  }

  Widget _header(ProductoDetalle product) => Container(
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
          child: const Icon(Icons.add_shopping_cart_rounded, color: _ink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agregar al pedido',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                product.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _productSummary(
    ProductoDetalle product,
    VariantePedidoResuelta? variant,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final image = Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: _image(product, variant),
      );
      final info = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.nombre,
            style: GoogleFonts.inter(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${product.marca} · ${product.categoria}'
            '${product.subcategoria.isEmpty ? '' : ' › ${product.subcategoria}'}',
            style: GoogleFonts.inter(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            'Código de familia: ${product.codigo}',
            style: GoogleFonts.inter(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (variant != null && variant.sku.isNotEmpty)
            Text(
              'SKU seleccionado: ${variant.sku}',
              style: GoogleFonts.inter(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      );
      if (constraints.maxWidth >= 560) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            image,
            const SizedBox(width: 16),
            Expanded(child: info),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [image, const SizedBox(height: 12), info],
      );
    },
  );

  Widget _matrixSelectors(ProductoPedidoResuelto resolved) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectors = resolved.ejes.map((axis) {
          final values = resolved.variantesActivas
              .map((item) => item.atributos[axis])
              .whereType<String>()
              .toSet()
              .toList();
          return DropdownButtonFormField<String>(
            key: ValueKey('pedido_eje_$axis'),
            initialValue: values.contains(_axisValues[axis])
                ? _axisValues[axis]
                : null,
            isExpanded: true,
            decoration: _inputDecoration(label: axis),
            items: values
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) _selectAxis(resolved, axis, value);
            },
          );
        }).toList();
        if (constraints.maxWidth >= 620) {
          return Row(
            children: [
              for (var i = 0; i < selectors.length; i++) ...[
                Expanded(child: selectors[i]),
                if (i < selectors.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < selectors.length; i++) ...[
              selectors[i],
              if (i < selectors.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _variantSelector(List<VariantePedidoResuelta> variants) =>
      DropdownButtonFormField<String>(
        key: const Key('pedido_variante_selector'),
        initialValue: _variantId,
        isExpanded: true,
        decoration: _inputDecoration(label: 'Variante'),
        items: variants
            .map(
              (item) => DropdownMenuItem(
                value: item.id,
                child: Text(
                  item.etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          final selected = variants.firstWhere((item) => item.id == value);
          setState(() => _selectVariant(selected, rebuild: false));
        },
      );

  Widget _variantSummary(VariantePedidoResuelta variant) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          variant.nombre,
          style: GoogleFonts.inter(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (variant.sku.isNotEmpty)
          Text(
            'SKU: ${variant.sku}',
            style: GoogleFonts.inter(color: _muted, fontSize: 10),
          ),
        if (variant.codigoProveedor.isNotEmpty)
          Text(
            'Código proveedor: ${variant.codigoProveedor}',
            style: GoogleFonts.inter(color: _muted, fontSize: 10),
          ),
        if (variant.atributos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: variant.atributos.entries
                .map(
                  (entry) => Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: _border),
                    label: Text(
                      '${entry.key}: ${entry.value}',
                      style: GoogleFonts.inter(
                        color: _ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );

  Widget _presentationOption(
    PresentacionPedidoResuelta item, {
    required bool selected,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: selected ? const Color(0xFFFFF8DD) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        key: ValueKey('pedido_presentacion_${item.id}'),
        onTap: () {
          setState(() {
            _presentationId = item.id;
            _setQuantity(item.pedidoMinimo, rebuild: false);
          });
        },
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? _yellow : _border,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? const Color(0xFFB88600) : _muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombre,
                      style: GoogleFonts.inter(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '1 ${item.nombre.toLowerCase()} = '
                      '${item.equivalenciaTexto}',
                      style: GoogleFonts.inter(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (item.predeterminada)
                const _Pill(label: 'Predeterminada', color: Color(0xFF8A6500)),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _priceListSelector(List<ListaPrecioPedido> lists) {
    if (lists.isEmpty) {
      return const _Notice(
        message: 'No hay listas de precios configuradas.',
        danger: true,
      );
    }
    return DropdownButtonFormField<String>(
      key: const Key('pedido_lista_precio'),
      initialValue: _priceListId,
      isExpanded: true,
      decoration: _inputDecoration(label: 'Lista de precios'),
      items: lists
          .map(
            (list) => DropdownMenuItem(
              value: list.id,
              child: Text(
                '${list.nombre} · ${list.moneda}'
                '${list.incluyeIgv ? ' · Incluye IGV' : ' · Sin IGV'}',
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _priceListId = value);
      },
    );
  }

  Widget _quantitySelector(PresentacionPedidoResuelta? presentation) {
    final step = presentation?.incremento ?? 1;
    return Row(
      children: [
        IconButton.filledTonal(
          key: const Key('restar_cantidad'),
          onPressed:
              presentation == null || _quantity <= presentation.pedidoMinimo
              ? null
              : () => _setQuantity(
                  math.max(presentation.pedidoMinimo, _quantity - step),
                ),
          icon: const Icon(Icons.remove_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            key: const Key('cantidad_presentaciones'),
            controller: _cantidadController,
            enabled: presentation != null,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            decoration: _inputDecoration(
              label: presentation == null
                  ? 'Cantidad'
                  : 'Cantidad de ${presentation.nombre.toLowerCase()}',
            ),
            onChanged: (value) {
              setState(() => _quantity = int.tryParse(value) ?? 0);
            },
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          key: const Key('sumar_cantidad'),
          onPressed: presentation == null
              ? null
              : () => _setQuantity(_quantity + step),
          style: IconButton.styleFrom(
            backgroundColor: _yellow,
            foregroundColor: _ink,
          ),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }

  Widget _summary({
    required PresentacionPedidoResuelta presentation,
    required PrecioPedidoResuelto? price,
    required double? unitPrice,
    required bool quantityValid,
  }) {
    final totalBase = presentation.equivalencia * _quantity;
    final subtotal = unitPrice == null ? null : unitPrice * _quantity;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: quantityValid
            ? const Color(0xFFF8F9FB)
            : const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: quantityValid ? _border : const Color(0xFFF1B5B5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!quantityValid)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'La cantidad no cumple el pedido mínimo o el incremento.',
                style: GoogleFonts.inter(
                  color: const Color(0xFFB42318),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          _summaryLine(
            'Equivalencia total',
            '$_quantity ${presentation.nombre.toLowerCase()} = '
                '${numeroPlano(totalBase)} ${presentation.unidadBase}',
          ),
          _summaryLine('Precio aplicado', _priceText(price, unitPrice)),
          _summaryLine(
            'Subtotal',
            subtotal == null
                ? price?.tipo == TipoPrecioPedido.cotizar
                      ? 'Por cotizar'
                      : 'No disponible'
                : _money(price?.lista.moneda ?? 'PEN', subtotal),
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _footer({
    required ProductoPedidoResuelto resolved,
    required VariantePedidoResuelta? variant,
    required PresentacionPedidoResuelta? presentation,
    required PrecioPedidoResuelto? price,
    required double? unitPrice,
    required bool canAdd,
  }) => Container(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: _border)),
    ),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              key: const Key('confirmar_agregar_producto'),
              onPressed: canAdd
                  ? () => Navigator.pop(
                      context,
                      _buildItem(
                        resolved,
                        variant!,
                        presentation!,
                        price!,
                        unitPrice,
                      ),
                    )
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _ink,
                minimumSize: const Size(0, 48),
              ),
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text(
                'Agregar al carrito',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  PedidoItem _buildItem(
    ProductoPedidoResuelto resolved,
    VariantePedidoResuelta variant,
    PresentacionPedidoResuelta presentation,
    PrecioPedidoResuelto price,
    double? unitPrice,
  ) {
    final options = variant.presentaciones.map((item) {
      final itemPrice = item.precioParaLista(price.lista.id);
      return PresentacionPedidoOpcion(
        id: item.id,
        nombre: item.nombre,
        equivalencia: item.equivalenciaTexto,
        equivalenteA: item.equivalencia,
        unidadBase: item.unidadBase,
        pedidoMinimo: item.pedidoMinimo,
        incremento: item.incremento,
        listaPrecioId: price.lista.id,
        listaPrecioNombre: price.lista.nombre,
        configuracionPrecio: itemPrice?.configuracion ?? 'pendiente',
        precio: itemPrice?.precioFijo,
        rangos: itemPrice?.rangos ?? const [],
      );
    }).toList();

    return PedidoItem(
      productoId: resolved.producto.id,
      codigo: resolved.producto.codigo,
      nombre: resolved.producto.nombre,
      varianteId: variant.id,
      varianteSku: variant.sku,
      varianteNombre: variant.nombre,
      atributosVariante: variant.atributos,
      presentacionId: presentation.id,
      presentacion: presentation.nombre,
      equivalencia: presentation.equivalenciaTexto,
      cantidad: _quantity,
      precioUnitario: unitPrice,
      precioListaId: price.lista.id,
      precioListaNombre: price.lista.nombre,
      precioConfiguracion: price.configuracion,
      opciones: options,
      imagenPath:
          variant.imagenPath ??
          resolved.producto.imagenPath ??
          resolved.producto.imagenesPaths.firstOrNull,
    );
  }

  void _selectAxis(ProductoPedidoResuelto resolved, String axis, String value) {
    setState(() {
      _axisValues[axis] = value;
      var candidates = resolved.variantesActivas.where((variant) {
        for (final entry in _axisValues.entries) {
          if (variant.atributos[entry.key] != entry.value) return false;
        }
        return true;
      }).toList();
      if (candidates.isEmpty) {
        candidates = resolved.variantesActivas
            .where((variant) => variant.atributos[axis] == value)
            .toList();
      }
      if (candidates.isEmpty) return;
      final variant = candidates.first;
      for (final matrixAxis in resolved.ejes) {
        final axisValue = variant.atributos[matrixAxis];
        if (axisValue != null) _axisValues[matrixAxis] = axisValue;
      }
      _selectVariant(variant, rebuild: false);
    });
  }

  void _selectVariant(VariantePedidoResuelta variant, {bool rebuild = true}) {
    _variantId = variant.id;
    final presentation =
        variant.presentaciones
            .where((item) => item.predeterminada)
            .firstOrNull ??
        variant.presentaciones.firstOrNull;
    _presentationId = presentation?.id;
    _setQuantity(presentation?.pedidoMinimo ?? 1, rebuild: false);
    if (rebuild) setState(() {});
  }

  void _setQuantity(int value, {bool rebuild = true}) {
    _quantity = value.clamp(0, 999999);
    _cantidadController.text = '$_quantity';
    if (rebuild) setState(() {});
  }

  bool _validQuantity(PresentacionPedidoResuelta presentation, int value) {
    if (value < presentation.pedidoMinimo) return false;
    final step = presentation.incremento <= 0 ? 1 : presentation.incremento;
    return (value - presentation.pedidoMinimo) % step == 0;
  }

  Widget _image(ProductoDetalle product, VariantePedidoResuelta? variant) {
    final path =
        variant?.imagenPath ??
        product.imagenPath ??
        product.imagenesPaths.firstOrNull;
    if (path == null) {
      return const Icon(
        Icons.inventory_2_outlined,
        size: 48,
        color: Color(0xFFB7BDC6),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.broken_image_outlined,
        size: 44,
        color: Color(0xFFB7BDC6),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.inter(
          color: _ink,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        subtitle,
        style: GoogleFonts.inter(color: _muted, fontSize: 10, height: 1.35),
      ),
    ],
  );

  Widget _summaryLine(String label, String value, {bool emphasized = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(color: _muted, fontSize: 11),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                  color: _ink,
                  fontSize: emphasized ? 14 : 11,
                  fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  InputDecoration _inputDecoration({required String label}) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _yellow, width: 1.8),
    ),
  );

  String _priceText(PrecioPedidoResuelto? price, double? value) {
    if (price == null) return 'Sin configurar';
    return switch (price.tipo) {
      TipoPrecioPedido.fijo =>
        '${_money(price.lista.moneda, value)} por presentación',
      TipoPrecioPedido.cantidad =>
        value == null
            ? 'Sin rango para esta cantidad'
            : '${_money(price.lista.moneda, value)} según cantidad',
      TipoPrecioPedido.cotizar => 'Por cotizar',
      TipoPrecioPedido.pendiente => 'Pendiente de configurar',
    };
  }
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
      style: GoogleFonts.inter(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.danger = false});

  final String message;
  final bool danger;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: danger ? const Color(0xFFFFF1F0) : const Color(0xFFFFF8DD),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: danger ? const Color(0xFFF1B5B5) : _yellow),
    ),
    child: Text(
      message,
      style: GoogleFonts.inter(
        color: danger ? const Color(0xFFB42318) : _ink,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String _money(String currency, double? value) {
  if (value == null) return 'Pendiente';
  final symbol = switch (currency.toUpperCase()) {
    'USD' => 'US\$',
    'EUR' => '€',
    _ => 'S/',
  };
  return '$symbol ${value.toStringAsFixed(2)}';
}
