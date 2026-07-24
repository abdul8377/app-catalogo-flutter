import 'package:equatable/equatable.dart';

import '../../domain/entities/catalogo_form_data.dart';

class ProductoFormState extends Equatable {
  const ProductoFormState({
    required this.loading,
    required this.saving,
    required this.guardado,
    required this.paso,
    required this.datos,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.empresa,
    required this.marca,
    required this.categoria,
    required this.subcategoria,
    required this.tipoRegistro,
    required this.atributos,
    required this.presentaciones,
    required this.precios,
    required this.imagenesPaths,
    required this.productoId,
    required this.activo,
    required this.creadoEn,
    this.error,
  });
  factory ProductoFormState.initial() => const ProductoFormState(
    loading: true,
    saving: false,
    guardado: false,
    paso: 0,
    datos: null,
    codigo: '',
    nombre: '',
    descripcion: '',
    empresa: null,
    marca: null,
    categoria: null,
    subcategoria: null,
    tipoRegistro: 'unico',
    atributos: {},
    presentaciones: [],
    precios: [],
    imagenesPaths: [],
    productoId: null,
    activo: true,
    creadoEn: null,
  );
  final bool loading, saving, guardado;
  final int paso;
  final CatalogoFormData? datos;
  final String codigo, nombre, descripcion, tipoRegistro;
  final String? empresa, marca, categoria, subcategoria, error;
  final List<String> imagenesPaths;
  String? get imagenPath => imagenesPaths.isEmpty ? null : imagenesPaths.first;
  final String? productoId;
  final bool activo;
  final DateTime? creadoEn;
  bool get editando => productoId != null;
  final Map<String, String> atributos;
  final List<PresentacionProducto> presentaciones;
  final List<PrecioProducto> precios;
  List<String> get subcategorias => categoria == null
      ? const []
      : datos?.subcategorias[categoria] ?? const [];
  List<String> get marcasDisponibles {
    final values = datos?.marcasDe(empresa) ?? const [];
    return datos?.marcasPorEmpresa.isEmpty ?? true
        ? datos?.marcas ?? const []
        : values;
  }

  List<String> get categoriasDisponibles {
    final values = datos?.categoriasDe(empresa, marca) ?? const [];
    return datos?.categoriasPorMarca.isEmpty ?? true
        ? datos?.categorias ?? const []
        : values;
  }

  List<AtributoDef> get atributosDisponibles =>
      categoria == null ? const [] : datos?.atributos[categoria] ?? const [];
  bool get pasoValido => switch (paso) {
    0 =>
      empresa != null &&
          marca != null &&
          categoria != null &&
          subcategoria != null,
    1 => codigo.trim().isNotEmpty && nombre.trim().isNotEmpty,
    4 => presentaciones.isNotEmpty,
    _ => true,
  };
  bool get formularioValido =>
      empresa != null &&
      marca != null &&
      categoria != null &&
      subcategoria != null &&
      codigo.trim().isNotEmpty &&
      nombre.trim().isNotEmpty &&
      presentaciones.isNotEmpty;

  int get primerPasoInvalido {
    if (empresa == null ||
        marca == null ||
        categoria == null ||
        subcategoria == null ||
        codigo.trim().isEmpty ||
        nombre.trim().isEmpty) {
      return 0;
    }
    if (presentaciones.isEmpty) return editando ? 3 : 4;
    return paso;
  }

  ProductoFormState copyWith({
    bool? loading,
    bool? saving,
    bool? guardado,
    int? paso,
    CatalogoFormData? datos,
    String? codigo,
    String? nombre,
    String? descripcion,
    String? empresa,
    String? marca,
    bool limpiarMarca = false,
    String? categoria,
    bool limpiarCategoria = false,
    String? subcategoria,
    bool limpiarSubcategoria = false,
    String? tipoRegistro,
    Map<String, String>? atributos,
    List<PresentacionProducto>? presentaciones,
    List<PrecioProducto>? precios,
    String? error,
    bool limpiarError = false,
    List<String>? imagenesPaths,
    String? productoId,
    bool? activo,
    DateTime? creadoEn,
  }) => ProductoFormState(
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    guardado: guardado ?? this.guardado,
    paso: paso ?? this.paso,
    datos: datos ?? this.datos,
    codigo: codigo ?? this.codigo,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion ?? this.descripcion,
    empresa: empresa ?? this.empresa,
    marca: limpiarMarca ? null : marca ?? this.marca,
    categoria: limpiarCategoria ? null : categoria ?? this.categoria,
    subcategoria: limpiarSubcategoria
        ? null
        : subcategoria ?? this.subcategoria,
    tipoRegistro: tipoRegistro ?? this.tipoRegistro,
    atributos: atributos ?? this.atributos,
    presentaciones: presentaciones ?? this.presentaciones,
    precios: precios ?? this.precios,
    error: limpiarError ? null : error ?? this.error,
    imagenesPaths: imagenesPaths ?? this.imagenesPaths,
    productoId: productoId ?? this.productoId,
    activo: activo ?? this.activo,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  @override
  List<Object?> get props => [
    loading,
    saving,
    guardado,
    paso,
    datos,
    codigo,
    nombre,
    descripcion,
    empresa,
    marca,
    categoria,
    subcategoria,
    tipoRegistro,
    atributos,
    presentaciones,
    precios,
    error,
    imagenesPaths,
    productoId,
    activo,
    creadoEn,
  ];
}
