import 'package:equatable/equatable.dart';

import '../../../../catalogo/domain/entities/producto_resumen.dart';
import '../../../../catalogo/domain/value_objects/catalogo_filtros.dart';
import '../../../domain/entities/pedido.dart';

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
    this.subcategoria,
    this.subcategoriasSeleccionadas = const {},
    this.estado,
    this.imagen,
    this.pedidoIdEditando,
    this.pedidoCodigoEditando,
    this.pedidoEstadoOriginal,
    this.pedidoHojaEditando,
    this.filtrosRapidos = const {'Todos'},
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
  final String? subcategoria;
  final Set<String> subcategoriasSeleccionadas;
  final String? estado;
  final String? imagen;
  final String? pedidoIdEditando;
  final String? pedidoCodigoEditando;
  final String? pedidoEstadoOriginal;
  final String? pedidoHojaEditando;
  final Set<String> filtrosRapidos;
  final List<PedidoItem> carrito;
  final List<ClientePedido> clientes;
  final HojaPedidoActiva? hojaActiva;
  final ClientePedido? cliente;
  final PedidoRegistrado? resultado;
  final String? error;

  Set<String> get subcategoriasActivas {
    final result = <String>{
      ...subcategoriasSeleccionadas
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    };
    final legacy = subcategoria?.trim() ?? '';
    if (legacy.isNotEmpty) result.add(legacy);
    return Set<String>.unmodifiable(result);
  }

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
          producto.subcategoria.toLowerCase().contains(query) ||
          producto.atributosClave.any(
            (atributo) => atributo.toLowerCase().contains(query),
          );
      final coincidePrecio =
          filtroPrecio == 'Todos' ||
          (filtroPrecio == 'Con precio' && !producto.sinPrecio) ||
          (filtroPrecio == 'Sin precio' && producto.sinPrecio);
      final quick = filtrosRapidos;
      return producto.activo &&
          coincideTexto &&
          coincidePrecio &&
          (!quick.contains('Inactivos')) &&
          (!quick.contains('Con precio') || !producto.sinPrecio) &&
          (!quick.contains('Sin precio') || producto.sinPrecio) &&
          (!quick.contains('Con imagen') || producto.imagenPath != null) &&
          (!quick.contains('Sin imagen') || producto.imagenPath == null) &&
          (!quick.contains('Con variantes') ||
              producto.tipoRegistro != 'unico') &&
          (!quick.contains('Sin variantes') ||
              producto.tipoRegistro == 'unico') &&
          (empresa == null || producto.empresa == empresa) &&
          (marca == null || producto.marca == marca) &&
          (categoria == null || producto.categoria == categoria) &&
          (subcategoriasActivas.isEmpty ||
              subcategoriasActivas.contains(producto.subcategoria)) &&
          (estado == null || estado == 'Activo') &&
          (imagen == null ||
              (imagen == 'Con imagen'
                  ? producto.imagenPath != null
                  : producto.imagenPath == null));
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
  List<String> get subcategorias => ({
    for (final item in productos)
      if (item.subcategoria.isNotEmpty) item.subcategoria,
  }.toList()..sort());
  int get filtrosAvanzadosActivos =>
      [empresa, marca, categoria, estado, imagen].whereType<String>().length +
      subcategoriasActivas.length;

  CatalogoFiltros get catalogoFiltros => CatalogoFiltros(
    empresa: empresa,
    marca: marca,
    categoria: categoria,
    subcategorias: subcategoriasActivas,
    estado: estado,
    precio: filtroPrecio == 'Todos' ? null : filtroPrecio,
    imagen: imagen,
    orden: orden,
  );

  bool get modoEdicion =>
      pedidoIdEditando != null && pedidoIdEditando!.trim().isNotEmpty;
  int get lineasLegadas => carrito
      .where(
        (item) =>
            item.pedidoItemId.isNotEmpty &&
            item.varianteId.isEmpty &&
            item.presentacionId.isEmpty,
      )
      .length;

  int get lineasCarrito => carrito.length;
  int get cantidadPresentaciones =>
      carrito.fold(0, (total, item) => total + item.cantidad);
  int get cantidadProductos => cantidadPresentaciones;
  double get subtotalConocido =>
      carrito.fold(0, (total, item) => total + (item.subtotal ?? 0));
  int get lineasSinPrecio =>
      carrito.where((item) => item.precioUnitario == null).length;
  int get productosSinPrecio => lineasSinPrecio;
  bool get totalParcial => lineasSinPrecio > 0;

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
    String? subcategoria,
    Set<String>? subcategoriasSeleccionadas,
    String? estado,
    String? imagen,
    String? pedidoIdEditando,
    String? pedidoCodigoEditando,
    String? pedidoEstadoOriginal,
    String? pedidoHojaEditando,
    Set<String>? filtrosRapidos,
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
    subcategoria: limpiarFiltros || subcategoriasSeleccionadas != null
        ? null
        : subcategoria ?? this.subcategoria,
    subcategoriasSeleccionadas: limpiarFiltros
        ? const {}
        : subcategoria != null
        ? const {}
        : subcategoriasSeleccionadas ?? this.subcategoriasSeleccionadas,
    estado: limpiarFiltros ? null : estado ?? this.estado,
    imagen: limpiarFiltros ? null : imagen ?? this.imagen,
    pedidoIdEditando: pedidoIdEditando ?? this.pedidoIdEditando,
    pedidoCodigoEditando: pedidoCodigoEditando ?? this.pedidoCodigoEditando,
    pedidoEstadoOriginal: pedidoEstadoOriginal ?? this.pedidoEstadoOriginal,
    pedidoHojaEditando: pedidoHojaEditando ?? this.pedidoHojaEditando,
    filtrosRapidos: filtrosRapidos ?? this.filtrosRapidos,
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
    subcategoria,
    subcategoriasSeleccionadas,
    estado,
    imagen,
    pedidoIdEditando,
    pedidoCodigoEditando,
    pedidoEstadoOriginal,
    pedidoHojaEditando,
    filtrosRapidos,
    carrito,
    clientes,
    hojaActiva,
    cliente,
    resultado,
    error,
  ];
}
