import 'package:equatable/equatable.dart';

/// Selección de filtros compartida por Catálogo y el selector de productos de
/// Nuevo pedido.
class CatalogoFiltros extends Equatable {
  const CatalogoFiltros({
    this.empresa,
    this.marca,
    this.categoria,
    this.subcategoria,
    this.subcategorias = const {},
    this.estado,
    this.precio,
    this.imagen,
    this.orden = 'Nombre A-Z',
  });

  final String? empresa;
  final String? marca;
  final String? categoria;

  /// Compatibilidad con filtros guardados y llamadas anteriores.
  final String? subcategoria;

  /// Selección múltiple usada por Catálogo y Nuevo pedido.
  final Set<String> subcategorias;

  final String? estado;
  final String? precio;
  final String? imagen;
  final String orden;

  Set<String> get subcategoriasActivas {
    final result = <String>{
      ...subcategorias
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    };
    final legacy = subcategoria?.trim() ?? '';
    if (legacy.isNotEmpty) result.add(legacy);
    return Set<String>.unmodifiable(result);
  }

  bool get tieneActivos =>
      empresa != null ||
      marca != null ||
      categoria != null ||
      subcategoriasActivas.isNotEmpty ||
      estado != null ||
      precio != null ||
      imagen != null;

  int get cantidadActivos =>
      [
        empresa,
        marca,
        categoria,
        estado,
        precio,
        imagen,
      ].whereType<String>().length +
      subcategoriasActivas.length;

  CatalogoFiltros copyWith({
    String? empresa,
    bool clearEmpresa = false,
    String? marca,
    bool clearMarca = false,
    String? categoria,
    bool clearCategoria = false,
    String? subcategoria,
    Set<String>? subcategorias,
    bool clearSubcategoria = false,
    String? estado,
    bool clearEstado = false,
    String? precio,
    bool clearPrecio = false,
    String? imagen,
    bool clearImagen = false,
    String? orden,
  }) {
    final nextLegacy = clearSubcategoria || subcategorias != null
        ? null
        : subcategoria ?? this.subcategoria;
    final nextMultiple = clearSubcategoria
        ? subcategorias == null
              ? const <String>{}
              : Set<String>.unmodifiable(subcategorias)
        : subcategoria != null
        ? const <String>{}
        : subcategorias == null
        ? this.subcategorias
        : Set<String>.unmodifiable(subcategorias);

    return CatalogoFiltros(
      empresa: clearEmpresa ? null : empresa ?? this.empresa,
      marca: clearMarca ? null : marca ?? this.marca,
      categoria: clearCategoria ? null : categoria ?? this.categoria,
      subcategoria: nextLegacy,
      subcategorias: nextMultiple,
      estado: clearEstado ? null : estado ?? this.estado,
      precio: clearPrecio ? null : precio ?? this.precio,
      imagen: clearImagen ? null : imagen ?? this.imagen,
      orden: orden ?? this.orden,
    );
  }

  @override
  List<Object?> get props => [
    empresa,
    marca,
    categoria,
    subcategoria,
    subcategorias,
    estado,
    precio,
    imagen,
    orden,
  ];
}
