import '../../../catalogo/domain/entities/producto_detalle.dart';
import '../../../catalogo/domain/entities/producto_variante.dart';
import '../entities/pedido.dart';

enum TipoPrecioPedido { fijo, cantidad, cotizar, pendiente }

class ListaPrecioPedido {
  const ListaPrecioPedido({
    required this.id,
    required this.nombre,
    required this.moneda,
    required this.incluyeIgv,
  });

  final String id;
  final String nombre;
  final String moneda;
  final bool incluyeIgv;
}

class PrecioPedidoResuelto {
  const PrecioPedidoResuelto({
    required this.lista,
    required this.tipo,
    this.precioFijo,
    this.rangos = const [],
  });

  final ListaPrecioPedido lista;
  final TipoPrecioPedido tipo;
  final double? precioFijo;
  final List<PedidoPrecioRango> rangos;

  bool get permiteAgregar => tipo != TipoPrecioPedido.pendiente;

  double? precioPara(int cantidad) {
    switch (tipo) {
      case TipoPrecioPedido.fijo:
        return precioFijo;
      case TipoPrecioPedido.cantidad:
        for (final rango in rangos) {
          if (rango.aplica(cantidad)) return rango.precio;
        }
        return null;
      case TipoPrecioPedido.cotizar:
      case TipoPrecioPedido.pendiente:
        return null;
    }
  }

  String get configuracion => switch (tipo) {
    TipoPrecioPedido.fijo => 'precio_fijo',
    TipoPrecioPedido.cantidad => 'por_cantidad',
    TipoPrecioPedido.cotizar => 'por_cotizar',
    TipoPrecioPedido.pendiente => 'pendiente',
  };
}

class PresentacionPedidoResuelta {
  const PresentacionPedidoResuelta({
    required this.id,
    required this.nombre,
    required this.equivalencia,
    required this.unidadBase,
    required this.pedidoMinimo,
    required this.incremento,
    required this.predeterminada,
    required this.precios,
  });

  final String id;
  final String nombre;
  final double equivalencia;
  final String unidadBase;
  final int pedidoMinimo;
  final int incremento;
  final bool predeterminada;
  final Map<String, PrecioPedidoResuelto> precios;

  String get equivalenciaTexto => '${numeroPlano(equivalencia)} $unidadBase';

  PrecioPedidoResuelto? precioParaLista(String listaId) => precios[listaId];
}

class VariantePedidoResuelta {
  const VariantePedidoResuelta({
    required this.id,
    required this.sku,
    required this.codigoProveedor,
    required this.nombre,
    required this.atributos,
    required this.activa,
    required this.imagenPath,
    required this.presentaciones,
  });

  final String id;
  final String sku;
  final String codigoProveedor;
  final String nombre;
  final Map<String, String> atributos;
  final bool activa;
  final String? imagenPath;
  final List<PresentacionPedidoResuelta> presentaciones;

  String get etiqueta {
    final atributosTexto = atributos.values
        .where((value) => value.trim().isNotEmpty)
        .take(3)
        .join(' · ');
    return [
      nombre,
      if (sku.isNotEmpty) sku,
      if (atributosTexto.isNotEmpty) atributosTexto,
    ].join(' · ');
  }
}

class ProductoPedidoResuelto {
  const ProductoPedidoResuelto({
    required this.producto,
    required this.variantes,
    required this.listas,
    required this.ejes,
  });

  final ProductoDetalle producto;
  final List<VariantePedidoResuelta> variantes;
  final List<ListaPrecioPedido> listas;
  final List<String> ejes;

  List<VariantePedidoResuelta> get variantesActivas =>
      variantes.where((item) => item.activa).toList();

  ListaPrecioPedido get listaPredeterminada {
    for (final lista in listas) {
      if (lista.id.toLowerCase() == 'regular' ||
          lista.nombre.toLowerCase() == 'regular') {
        return lista;
      }
    }
    return listas.first;
  }
}

class ProductoPedidoResolver {
  const ProductoPedidoResolver._();

  static ProductoPedidoResuelto resolver(ProductoDetalle producto) {
    final venta = producto.ventaLogisticaContenido ?? const {};
    final configuracionPrecio = producto.preciosConfigurados ?? const {};
    final presentacionesRaw = _maps(venta['presentations']);
    final preciosRaw = _maps(configuracionPrecio['prices']);
    final listas = _listas(producto, configuracionPrecio);
    final variantesOrigen = producto.variantes.isEmpty
        ? [_varianteLegacy(producto)]
        : producto.variantes;

    final variantes = variantesOrigen.map((variante) {
      final presentaciones = presentacionesRaw.isEmpty
          ? _presentacionesLegacy(producto, variante, listas)
          : _presentacionesConfiguradas(
              producto,
              variante,
              presentacionesRaw,
              preciosRaw,
              listas,
            );
      return VariantePedidoResuelta(
        id: variante.id,
        sku: variante.sku.trim(),
        codigoProveedor: variante.codigoProveedor.trim(),
        nombre: variante.nombreCorto.trim().isEmpty
            ? (variante.sku.trim().isEmpty ? producto.nombre : variante.sku)
            : variante.nombreCorto.trim(),
        atributos: {
          for (final atributo in variante.atributos)
            if (atributo.texto.trim().isNotEmpty)
              atributo.nombre: atributo.texto,
        },
        activa: variante.activa,
        imagenPath: _textoOpcional(variante.imagenPath),
        presentaciones: presentaciones,
      );
    }).toList();

    return ProductoPedidoResuelto(
      producto: producto,
      variantes: variantes,
      listas: listas,
      ejes: _detectarEjes(variantes),
    );
  }

  static ProductoVariante _varianteLegacy(ProductoDetalle producto) =>
      ProductoVariante(
        id: producto.id,
        sku: producto.codigo,
        nombreCorto: producto.nombre,
        atributos: producto.atributos.entries
            .map(
              (entry) =>
                  AtributoProductoVariante.fromText(entry.key, entry.value),
            )
            .toList(),
        activa: producto.activo,
        imagenPath: producto.imagenPath ?? producto.imagenesPaths.firstOrNull,
      );

  static List<ListaPrecioPedido> _listas(
    ProductoDetalle producto,
    Map<String, dynamic> configuracion,
  ) {
    final configuradas = _maps(configuracion['lists'])
        .map(
          (item) => ListaPrecioPedido(
            id: item['id']?.toString() ?? '',
            nombre: item['name']?.toString() ?? 'Lista',
            moneda: item['currency_code']?.toString() ?? 'PEN',
            incluyeIgv: item['includes_igv'] as bool? ?? true,
          ),
        )
        .where((item) => item.id.trim().isNotEmpty)
        .toList();
    if (configuradas.isNotEmpty) return configuradas;

    final ids = producto.precios
        .map((item) => item.listaPrecioId.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    if (ids.isEmpty) {
      return const [
        ListaPrecioPedido(
          id: 'regular',
          nombre: 'Regular',
          moneda: 'PEN',
          incluyeIgv: true,
        ),
      ];
    }
    return ids
        .map(
          (id) => ListaPrecioPedido(
            id: id,
            nombre: _titulo(id),
            moneda: 'PEN',
            incluyeIgv: true,
          ),
        )
        .toList();
  }

  static List<PresentacionPedidoResuelta> _presentacionesLegacy(
    ProductoDetalle producto,
    ProductoVariante variante,
    List<ListaPrecioPedido> listas,
  ) => producto.presentaciones.asMap().entries.map((entry) {
    final presentacion = entry.value;
    final parsed = _equivalenciaLegacy(presentacion.unidad);
    final id =
        producto.precios
            .where(
              (price) =>
                  price.presentacion == presentacion.nombre &&
                  price.presentacionId.trim().isNotEmpty,
            )
            .map((price) => price.presentacionId)
            .firstOrNull ??
        'legacy-${entry.key}';
    return PresentacionPedidoResuelta(
      id: id,
      nombre: presentacion.nombre,
      equivalencia: parsed.$1,
      unidadBase: parsed.$2,
      pedidoMinimo: 1,
      incremento: 1,
      predeterminada: entry.key == 0,
      precios: _resolverPrecios(
        producto: producto,
        varianteId: variante.id,
        presentacionId: id,
        presentacionNombre: presentacion.nombre,
        listas: listas,
        preciosConfigurados: const [],
      ),
    );
  }).toList();

  static List<PresentacionPedidoResuelta> _presentacionesConfiguradas(
    ProductoDetalle producto,
    ProductoVariante variante,
    List<Map<String, dynamic>> presentaciones,
    List<Map<String, dynamic>> precios,
    List<ListaPrecioPedido> listas,
  ) {
    final result = <PresentacionPedidoResuelta>[];
    for (final item in presentaciones) {
      final assigned = _strings(item['assigned_variant_ids']);
      if (assigned.isNotEmpty && !assigned.contains(variante.id)) continue;
      final rule = _maps(item['variant_rules'])
          .where((item) => item['variant_id']?.toString() == variante.id)
          .firstOrNull;
      final id = item['id']?.toString() ?? '';
      final name = item['name']?.toString() ?? 'Presentación';
      result.add(
        PresentacionPedidoResuelta(
          id: id.isEmpty ? 'presentacion-${result.length}' : id,
          nombre: name,
          equivalencia:
              _numero(rule?['equivalent_to']) ??
              _numero(item['equivalent_to']) ??
              1,
          unidadBase: item['base_unit']?.toString() ?? 'UND',
          pedidoMinimo: _enteroPositivo(
            _numero(rule?['minimum_order']) ??
                _numero(item['minimum_order']) ??
                1,
          ),
          incremento: _enteroPositivo(
            _numero(rule?['purchase_increment']) ??
                _numero(item['purchase_increment']) ??
                1,
          ),
          predeterminada: _strings(
            item['default_variant_ids'],
          ).contains(variante.id),
          precios: _resolverPrecios(
            producto: producto,
            varianteId: variante.id,
            presentacionId: id,
            presentacionNombre: name,
            listas: listas,
            preciosConfigurados: precios,
          ),
        ),
      );
    }
    return result;
  }

  static Map<String, PrecioPedidoResuelto> _resolverPrecios({
    required ProductoDetalle producto,
    required String varianteId,
    required String presentacionId,
    required String presentacionNombre,
    required List<ListaPrecioPedido> listas,
    required List<Map<String, dynamic>> preciosConfigurados,
  }) {
    final result = <String, PrecioPedidoResuelto>{};
    for (final lista in listas) {
      final configured = preciosConfigurados
          .where(
            (price) =>
                price['list_id']?.toString() == lista.id &&
                price['variant_id']?.toString() == varianteId &&
                price['presentation_id']?.toString() == presentacionId,
          )
          .firstOrNull;
      if (configured != null) {
        final type = _tipoPrecio(configured['configuration']?.toString());
        result[lista.id] = PrecioPedidoResuelto(
          lista: lista,
          tipo: type,
          precioFijo: _numero(configured['fixed_price']),
          rangos: _maps(configured['ranges'])
              .map(
                (range) => PedidoPrecioRango(
                  desde: _numero(range['from']) ?? 1,
                  hasta: _numero(range['until']),
                  precio: _numero(range['price_per_presentation']) ?? 0,
                ),
              )
              .toList(),
        );
        continue;
      }

      final legacy = producto.precios
          .where(
            (price) =>
                (price.listaPrecioId.isEmpty ||
                    price.listaPrecioId == lista.id) &&
                (price.varianteId.isEmpty || price.varianteId == varianteId) &&
                ((price.presentacionId.isNotEmpty &&
                        price.presentacionId == presentacionId) ||
                    price.presentacion == presentacionNombre),
          )
          .firstOrNull;
      if (legacy != null) {
        final type = _tipoPrecio(legacy.configuracion);
        result[lista.id] = PrecioPedidoResuelto(
          lista: lista,
          tipo: type == TipoPrecioPedido.pendiente
              ? TipoPrecioPedido.fijo
              : type,
          precioFijo: legacy.valor,
          rangos: type == TipoPrecioPedido.cantidad
              ? [PedidoPrecioRango(desde: 1, precio: legacy.valor)]
              : const [],
        );
        continue;
      }

      // La ausencia de una fila de precio no invalida una combinación
      // vendible. El vendedor puede agregarla y valorizarla después en la
      // cotización. Solo una configuración explícita pendiente continúa
      // bloqueando la venta.
      result[lista.id] = PrecioPedidoResuelto(
        lista: lista,
        tipo: TipoPrecioPedido.cotizar,
      );
    }
    return result;
  }

  static List<String> _detectarEjes(List<VariantePedidoResuelta> variantes) {
    final names = <String>[];
    for (final variant in variantes) {
      for (final name in variant.atributos.keys) {
        if (!names.contains(name)) names.add(name);
      }
    }
    return names
        .where(
          (name) =>
              variantes
                  .map((item) => item.atributos[name])
                  .whereType<String>()
                  .toSet()
                  .length >
              1,
        )
        .take(2)
        .toList();
  }

  static TipoPrecioPedido _tipoPrecio(String? value) =>
      switch (value?.trim().toLowerCase()) {
        'fixed' || 'precio_fijo' => TipoPrecioPedido.fijo,
        'quantity' || 'por_cantidad' => TipoPrecioPedido.cantidad,
        'quote' || 'por_cotizar' => TipoPrecioPedido.cotizar,
        _ => TipoPrecioPedido.pendiente,
      };

  static (double, String) _equivalenciaLegacy(String value) {
    final match = RegExp(
      r'^([0-9]+(?:[.,][0-9]+)?)\s*(.*)$',
    ).firstMatch(value.trim());
    final quantity =
        double.tryParse(match?.group(1)?.replaceAll(',', '.') ?? '') ?? 1;
    final unit = (match?.group(2) ?? value).trim();
    return (quantity, unit.isEmpty ? 'UND' : unit);
  }

  static int _enteroPositivo(double value) => value.ceil().clamp(1, 999999);

  static List<Map<String, dynamic>> _maps(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : const [];

  static Set<String> _strings(Object? value) =>
      value is List ? value.map((item) => item.toString()).toSet() : <String>{};

  static double? _numero(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().replaceAll(',', '.') ?? '');

  static String? _textoOpcional(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }

  static String _titulo(String value) => value
      .split(RegExp(r'[_-]+'))
      .where((item) => item.isNotEmpty)
      .map((item) => '${item[0].toUpperCase()}${item.substring(1)}')
      .join(' ');
}

String numeroPlano(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value
          .toStringAsFixed(3)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
