import 'package:equatable/equatable.dart';

import '../../../catalogo/domain/entities/producto_resumen.dart';
import '../../domain/entities/pedido.dart';

class PedidosState extends Equatable {
  const PedidosState({
    required this.loading,
    required this.guardando,
    required this.productos,
    required this.busqueda,
    required this.filtroPrecio,
    required this.orden,
    required this.vistaGrilla,
    required this.carrito,
    required this.clientes,
    required this.hojaActiva,
    this.cliente,
    this.resultado,
    this.error,
    this.empresa,
    this.marca,
    this.categoria,
  });

  factory PedidosState.initial() => const PedidosState(
    loading: true,
    guardando: false,
    productos: [],
    busqueda: '',
    filtroPrecio: 'Todos',
    orden: 'Nombre A-Z',
    vistaGrilla: true,
    carrito: [],
    clientes: [],
    hojaActiva: null,
  );

  final bool loading;
  final bool guardando;
  final List<ProductoResumen> productos;
  final String busqueda;
  final String filtroPrecio;
  final String orden;
  final bool vistaGrilla;
  final String? empresa;
  final String? marca;
  final String? categoria;
  final List<PedidoItem> carrito;
  final List<ClientePedido> clientes;
  final HojaPedidoActiva? hojaActiva;
  final ClientePedido? cliente;
  final PedidoRegistrado? resultado;
  final String? error;

  List<ProductoResumen> get productosFiltrados {
    final query = busqueda.trim().toLowerCase();
    final result = productos.where((producto) {
      final coincideTexto =
          query.isEmpty ||
          producto.nombre.toLowerCase().contains(query) ||
          producto.codigo.toLowerCase().contains(query) ||
          producto.marca.toLowerCase().contains(query) ||
          producto.empresa.toLowerCase().contains(query) ||
          producto.categoria.toLowerCase().contains(query) ||
          producto.atributosClave.any(
            (atributo) => atributo.toLowerCase().contains(query),
          );
      final coincidePrecio =
          filtroPrecio == 'Todos' ||
          (filtroPrecio == 'Con precio' && !producto.sinPrecio) ||
          (filtroPrecio == 'Sin precio' && producto.sinPrecio);
      return producto.activo &&
          coincideTexto &&
          coincidePrecio &&
          (empresa == null || producto.empresa == empresa) &&
          (marca == null || producto.marca == marca) &&
          (categoria == null || producto.categoria == categoria);
    }).toList();
    switch (orden) {
      case 'Nombre Z-A':
        result.sort((a, b) => b.nombre.compareTo(a.nombre));
      case 'Precio menor a mayor':
        result.sort(
          (a, b) => (a.precio ?? double.infinity).compareTo(
            b.precio ?? double.infinity,
          ),
        );
      case 'Precio mayor a menor':
        result.sort((a, b) => (b.precio ?? -1).compareTo(a.precio ?? -1));
      default:
        result.sort((a, b) => a.nombre.compareTo(b.nombre));
    }
    return result;
  }

  List<String> get empresas =>
      ({for (final item in productos) item.empresa}.toList()..sort());
  List<String> get marcas =>
      ({for (final item in productos) item.marca}.toList()..sort());
  List<String> get categorias =>
      ({for (final item in productos) item.categoria}.toList()..sort());
  int get filtrosAvanzadosActivos =>
      [empresa, marca, categoria].whereType<String>().length;

  int get cantidadProductos =>
      carrito.fold(0, (total, item) => total + item.cantidad);
  double get subtotalConocido =>
      carrito.fold(0, (total, item) => total + (item.subtotal ?? 0));
  int get productosSinPrecio =>
      carrito.where((item) => item.precioUnitario == null).length;
  bool get totalParcial => productosSinPrecio > 0;

  PedidosState copyWith({
    bool? loading,
    bool? guardando,
    List<ProductoResumen>? productos,
    String? busqueda,
    String? filtroPrecio,
    String? orden,
    bool? vistaGrilla,
    String? empresa,
    String? marca,
    String? categoria,
    bool limpiarFiltros = false,
    List<PedidoItem>? carrito,
    List<ClientePedido>? clientes,
    HojaPedidoActiva? hojaActiva,
    bool limpiarHoja = false,
    ClientePedido? cliente,
    bool limpiarCliente = false,
    PedidoRegistrado? resultado,
    bool limpiarResultado = false,
    String? error,
    bool limpiarError = false,
  }) => PedidosState(
    loading: loading ?? this.loading,
    guardando: guardando ?? this.guardando,
    productos: productos ?? this.productos,
    busqueda: busqueda ?? this.busqueda,
    filtroPrecio: filtroPrecio ?? this.filtroPrecio,
    orden: orden ?? this.orden,
    vistaGrilla: vistaGrilla ?? this.vistaGrilla,
    empresa: limpiarFiltros ? null : empresa ?? this.empresa,
    marca: limpiarFiltros ? null : marca ?? this.marca,
    categoria: limpiarFiltros ? null : categoria ?? this.categoria,
    carrito: carrito ?? this.carrito,
    clientes: clientes ?? this.clientes,
    hojaActiva: limpiarHoja ? null : hojaActiva ?? this.hojaActiva,
    cliente: limpiarCliente ? null : cliente ?? this.cliente,
    resultado: limpiarResultado ? null : resultado ?? this.resultado,
    error: limpiarError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [
    loading,
    guardando,
    productos,
    busqueda,
    filtroPrecio,
    orden,
    vistaGrilla,
    empresa,
    marca,
    categoria,
    carrito,
    clientes,
    hojaActiva,
    cliente,
    resultado,
    error,
  ];
}
