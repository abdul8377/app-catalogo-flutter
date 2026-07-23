import 'package:equatable/equatable.dart';

import '../../domain/entities/producto_consolidado.dart';

class ProductosConsolidadosState extends Equatable {
  const ProductosConsolidadosState({
    required this.loading,
    required this.saving,
    required this.productos,
    required this.busqueda,
    required this.orden,
    required this.soloSinPrecio,
    this.hojaCodigo,
    this.empresa,
    this.marca,
    this.categoria,
    this.subcategoria,
    this.estadoPreparacion,
    this.estadoPedido,
    this.error,
    this.message,
  });

  factory ProductosConsolidadosState.initial({String? hojaCodigo}) =>
      ProductosConsolidadosState(
        loading: true,
        saving: false,
        productos: const [],
        busqueda: '',
        orden: 'Pendientes primero',
        soloSinPrecio: false,
        hojaCodigo: hojaCodigo,
      );

  final bool loading;
  final bool saving;
  final List<ProductoConsolidado> productos;
  final String busqueda;
  final String orden;
  final String? hojaCodigo;
  final String? empresa;
  final String? marca;
  final String? categoria;
  final String? subcategoria;
  final String? estadoPreparacion;
  final String? estadoPedido;
  final bool soloSinPrecio;
  final String? error;
  final String? message;

  List<ProductoConsolidado> get productosFiltrados {
    final query = busqueda.trim().toLowerCase();
    final result = <ProductoConsolidado>[];
    for (final producto in productos) {
      final distribucion = producto.distribucion.where((item) {
        if (hojaCodigo != null && item.hojaCodigo != hojaCodigo) return false;
        if (estadoPedido != null &&
            !_estadoNormalizado(
              item.estadoPedido,
            ).contains(_estadoNormalizado(estadoPedido!))) {
          return false;
        }
        return true;
      }).toList();
      if (distribucion.isEmpty) continue;
      final consolidado = producto.conDistribucion(distribucion);
      final coincideTexto =
          query.isEmpty ||
          consolidado.nombre.toLowerCase().contains(query) ||
          consolidado.codigo.toLowerCase().contains(query) ||
          (consolidado.marca ?? '').toLowerCase().contains(query) ||
          consolidado.variante.toLowerCase().contains(query);
      final coincidePreparacion = switch (estadoPreparacion) {
        'pendiente' => consolidado.totalPreparado == 0,
        'parcial' => consolidado.parcial,
        'completo' => consolidado.completo,
        _ => true,
      };
      if (coincideTexto &&
          coincidePreparacion &&
          (empresa == null || consolidado.empresa == empresa) &&
          (marca == null || consolidado.marca == marca) &&
          (categoria == null || consolidado.categoria == categoria) &&
          (subcategoria == null || consolidado.subcategoria == subcategoria) &&
          (!soloSinPrecio || consolidado.pendientePrecio)) {
        result.add(consolidado);
      }
    }

    switch (orden) {
      case 'Empresa':
        result.sort((a, b) => (a.empresa ?? '').compareTo(b.empresa ?? ''));
      case 'Marca':
        result.sort((a, b) => (a.marca ?? '').compareTo(b.marca ?? ''));
      case 'Categoría':
        result.sort((a, b) => (a.categoria ?? '').compareTo(b.categoria ?? ''));
      case 'Nombre del producto':
        result.sort((a, b) => a.nombre.compareTo(b.nombre));
      case 'Mayor cantidad requerida':
        result.sort((a, b) => b.totalRequerido.compareTo(a.totalRequerido));
      case 'Más pedidos asociados':
        result.sort((a, b) => b.cantidadPedidos.compareTo(a.cantidadPedidos));
      default:
        result.sort((a, b) {
          final pendiente = b.pendiente.compareTo(a.pendiente);
          return pendiente == 0 ? a.nombre.compareTo(b.nombre) : pendiente;
        });
    }
    return result;
  }

  String _estadoNormalizado(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll('ó', 'o');

  List<String> get hojasDisponibles => ({
    for (final producto in productos)
      for (final item in producto.distribucion)
        if (item.hojaCodigo.isNotEmpty) item.hojaCodigo,
  }.toList()..sort());

  List<String> get empresas => ({
    for (final p in productos)
      if ((p.empresa ?? '').isNotEmpty) p.empresa!,
  }.toList()..sort());
  List<String> get marcas => ({
    for (final p in productos)
      if ((p.marca ?? '').isNotEmpty) p.marca!,
  }.toList()..sort());
  List<String> get categorias => ({
    for (final p in productos)
      if ((p.categoria ?? '').isNotEmpty) p.categoria!,
  }.toList()..sort());
  List<String> get subcategorias => ({
    for (final p in productos)
      if ((p.subcategoria ?? '').isNotEmpty) p.subcategoria!,
  }.toList()..sort());

  int get filtrosActivos =>
      [
        empresa,
        marca,
        categoria,
        subcategoria,
        estadoPreparacion,
        estadoPedido,
      ].whereType<String>().length +
      (soloSinPrecio ? 1 : 0);

  ProductosConsolidadosState copyWith({
    bool? loading,
    bool? saving,
    List<ProductoConsolidado>? productos,
    String? busqueda,
    String? orden,
    String? hojaCodigo,
    String? empresa,
    String? marca,
    String? categoria,
    String? subcategoria,
    String? estadoPreparacion,
    String? estadoPedido,
    bool? soloSinPrecio,
    bool limpiarFiltros = false,
    bool limpiarHoja = false,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) => ProductosConsolidadosState(
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    productos: productos ?? this.productos,
    busqueda: busqueda ?? this.busqueda,
    orden: orden ?? this.orden,
    hojaCodigo: limpiarHoja ? null : hojaCodigo ?? this.hojaCodigo,
    empresa: limpiarFiltros ? null : empresa ?? this.empresa,
    marca: limpiarFiltros ? null : marca ?? this.marca,
    categoria: limpiarFiltros ? null : categoria ?? this.categoria,
    subcategoria: limpiarFiltros ? null : subcategoria ?? this.subcategoria,
    estadoPreparacion: limpiarFiltros
        ? null
        : estadoPreparacion ?? this.estadoPreparacion,
    estadoPedido: limpiarFiltros ? null : estadoPedido ?? this.estadoPedido,
    soloSinPrecio: limpiarFiltros ? false : soloSinPrecio ?? this.soloSinPrecio,
    error: clearError ? null : error ?? this.error,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    loading,
    saving,
    productos,
    busqueda,
    orden,
    hojaCodigo,
    empresa,
    marca,
    categoria,
    subcategoria,
    estadoPreparacion,
    estadoPedido,
    soloSinPrecio,
    error,
    message,
  ];
}
