import 'package:equatable/equatable.dart';

import '../../domain/entities/producto_resumen.dart';

class CatalogoFiltros extends Equatable {
  const CatalogoFiltros({
    this.empresa,
    this.marca,
    this.categoria,
    this.subcategoria,
    this.estado,
    this.precio,
    this.imagen,
    this.orden = 'Nombre A-Z',
  });
  final String? empresa, marca, categoria, subcategoria, estado, precio, imagen;
  final String orden;
  bool get tieneActivos =>
      empresa != null ||
      marca != null ||
      categoria != null ||
      subcategoria != null ||
      estado != null ||
      precio != null ||
      imagen != null;
  int get cantidadActivos => [
    empresa,
    marca,
    categoria,
    subcategoria,
    estado,
    precio,
    imagen,
  ].whereType<String>().length;

  CatalogoFiltros copyWith({
    String? empresa,
    bool clearEmpresa = false,
    String? marca,
    bool clearMarca = false,
    String? categoria,
    bool clearCategoria = false,
    String? subcategoria,
    bool clearSubcategoria = false,
    String? estado,
    bool clearEstado = false,
    String? precio,
    bool clearPrecio = false,
    String? imagen,
    bool clearImagen = false,
    String? orden,
  }) => CatalogoFiltros(
    empresa: clearEmpresa ? null : empresa ?? this.empresa,
    marca: clearMarca ? null : marca ?? this.marca,
    categoria: clearCategoria ? null : categoria ?? this.categoria,
    subcategoria: clearSubcategoria ? null : subcategoria ?? this.subcategoria,
    estado: clearEstado ? null : estado ?? this.estado,
    precio: clearPrecio ? null : precio ?? this.precio,
    imagen: clearImagen ? null : imagen ?? this.imagen,
    orden: orden ?? this.orden,
  );

  @override
  List<Object?> get props => [
    empresa,
    marca,
    categoria,
    subcategoria,
    estado,
    precio,
    imagen,
    orden,
  ];
}

class CatalogoState extends Equatable {
  const CatalogoState({
    required this.loading,
    required this.actualizando,
    required this.busqueda,
    required this.filtrosRapidos,
    required this.filtros,
    required this.vistaGrilla,
    required this.productos,
    required this.productosFiltrados,
    this.error,
  });

  factory CatalogoState.initial() => const CatalogoState(
    loading: true,
    actualizando: false,
    busqueda: '',
    filtrosRapidos: {'Todos'},
    filtros: CatalogoFiltros(),
    vistaGrilla: true,
    productos: [],
    productosFiltrados: [],
  );

  final bool loading, actualizando, vistaGrilla;
  final String busqueda;
  final Set<String> filtrosRapidos;
  final CatalogoFiltros filtros;
  final List<ProductoResumen> productos, productosFiltrados;
  final String? error;

  List<String> get empresas => _unicos(productos.map((p) => p.empresa));
  List<String> get marcas => _unicos(productos.map((p) => p.marca));
  List<String> get categorias => _unicos(productos.map((p) => p.categoria));
  List<String> get subcategorias => _unicos(
    productos.map((p) => p.subcategoria).where((value) => value.isNotEmpty),
  );
  static List<String> _unicos(Iterable<String> values) =>
      (values.toSet().toList()..sort());

  CatalogoState copyWith({
    bool? loading,
    bool? actualizando,
    String? busqueda,
    Set<String>? filtrosRapidos,
    CatalogoFiltros? filtros,
    bool? vistaGrilla,
    List<ProductoResumen>? productos,
    List<ProductoResumen>? productosFiltrados,
    String? error,
    bool limpiarError = false,
  }) => CatalogoState(
    loading: loading ?? this.loading,
    actualizando: actualizando ?? this.actualizando,
    busqueda: busqueda ?? this.busqueda,
    filtrosRapidos: filtrosRapidos ?? this.filtrosRapidos,
    filtros: filtros ?? this.filtros,
    vistaGrilla: vistaGrilla ?? this.vistaGrilla,
    productos: productos ?? this.productos,
    productosFiltrados: productosFiltrados ?? this.productosFiltrados,
    error: limpiarError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [
    loading,
    actualizando,
    busqueda,
    filtrosRapidos,
    filtros,
    vistaGrilla,
    productos,
    productosFiltrados,
    error,
  ];
}
