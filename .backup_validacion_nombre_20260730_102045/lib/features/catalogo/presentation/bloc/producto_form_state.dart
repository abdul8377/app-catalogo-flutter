import 'package:equatable/equatable.dart';

import '../../domain/entities/catalogo_form_data.dart';
import '../../domain/entities/producto_variante.dart';
import '../widgets/paso4_venta_logistica_contenido.dart';
import '../widgets/paso5_precios_corregido.dart';
import '../widgets/paso6_imagenes_corregido.dart';

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
    required this.variantes,
    required this.edicionVariantePendiente,
    required this.presentaciones,
    required this.precios,
    required this.imagenesPaths,
    required this.productoId,
    required this.activo,
    required this.creadoEn,
    this.ventaLogisticaContenido,
    this.preciosConfigurados,
    this.imagenesConfiguradas,
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
    variantes: [],
    edicionVariantePendiente: false,
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
  final List<ProductoVariante> variantes;
  final bool edicionVariantePendiente;
  final List<PresentacionProducto> presentaciones;
  final List<PrecioProducto> precios;
  final Step4SalesDraft? ventaLogisticaContenido;
  final PricingStep5Draft? preciosConfigurados;
  final Step6ImagesDraft? imagenesConfiguradas;
  bool get preciosListosParaActivar {
    final draft = preciosConfigurados;
    if (draft == null) return precios.isNotEmpty;
    if (draft.lists.isEmpty) return false;
    return draft.canActivate(draft.lists.first.id);
  }

  bool get imagenesListasParaActivar =>
      imagenesConfiguradas?.canActivate ?? imagenesPaths.isNotEmpty;

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

  List<AtributoDef> get atributosDisponibles {
    final formData = datos;
    if (formData == null) return const [];

    final subcategory = subcategoria;
    if (subcategory != null) {
      final values = formData.atributos[subcategory];
      if (values != null && values.isNotEmpty) return values;
    }

    final category = categoria;
    return category == null
        ? const []
        : formData.atributos[category] ?? const [];
  }

  bool get subcategoriaRequerida => subcategorias.isNotEmpty;
  bool get variantesCompletas => variantes.every(
    (variante) =>
        variante.sku.trim().isNotEmpty &&
        variante.nombreCorto.trim().isNotEmpty,
  );
  bool get variantesConSkuUnico {
    final skus = variantes
        .map((variante) => variante.sku.trim().toUpperCase())
        .where((sku) => sku.isNotEmpty)
        .toList();
    return skus.toSet().length == skus.length;
  }

  bool get variantesValidas =>
      variantes.isNotEmpty &&
      variantes.any((variante) => variante.activa) &&
      variantesCompletas &&
      variantesConSkuUnico &&
      (tipoRegistro != 'unico' || variantes.length == 1) &&
      !edicionVariantePendiente;

  bool get pasoValido => switch (paso) {
    0 =>
      empresa != null &&
          marca != null &&
          categoria != null &&
          (!subcategoriaRequerida || subcategoria != null),
    1 => nombre.trim().isNotEmpty && variantesValidas,
    2 => variantesValidas,
    3 => presentaciones.isNotEmpty,
    _ => true,
  };

  String get mensajePasoInvalido => switch (paso) {
    0 => 'Completa la empresa, marca, categoría y subcategoría requeridas.',
    1 when nombre.trim().isEmpty =>
      tipoRegistro == 'unico'
          ? 'Ingresa el nombre comercial del producto.'
          : 'Ingresa el nombre general del producto.',
    1 when edicionVariantePendiente =>
      'Guarda o cancela los cambios de la variante antes de continuar.',
    1 when variantes.isEmpty =>
      tipoRegistro == 'unico'
          ? 'Completa los datos del producto único.'
          : 'Agrega al menos una variante para continuar.',
    1 when !variantes.any((variante) => variante.activa) =>
      'Activa al menos una variante para continuar.',
    1 when !variantesCompletas =>
      'Completa el código interno y el nombre de todas las variantes.',
    1 when !variantesConSkuUnico =>
      'Corrige los códigos internos duplicados antes de continuar.',
    1 when tipoRegistro == 'unico' && variantes.length != 1 =>
      'Un producto único debe tener exactamente una variante.',
    2 when edicionVariantePendiente =>
      'Guarda o cancela los cambios de la variante antes de continuar.',
    2 when variantes.isEmpty => 'Agrega al menos una variante para continuar.',
    2 when !variantes.any((variante) => variante.activa) =>
      'Activa al menos una variante para continuar.',
    2 when !variantesCompletas =>
      'Completa el código interno y el nombre de todas las variantes.',
    2 when !variantesConSkuUnico =>
      'Corrige los códigos internos duplicados antes de continuar.',
    2 when tipoRegistro == 'unico' && variantes.length != 1 =>
      'Un producto único debe tener exactamente una variante.',
    3 => 'Agrega al menos una presentación para continuar.',
    _ => 'Revisa los datos requeridos antes de continuar.',
  };

  bool get formularioValido =>
      empresa != null &&
      marca != null &&
      categoria != null &&
      (!subcategoriaRequerida || subcategoria != null) &&
      nombre.trim().isNotEmpty &&
      variantesValidas &&
      presentaciones.isNotEmpty;

  int get primerPasoInvalido {
    if (empresa == null ||
        marca == null ||
        categoria == null ||
        (subcategoriaRequerida && subcategoria == null)) {
      return 0;
    }
    if (nombre.trim().isEmpty || !variantesValidas) return 1;
    if (presentaciones.isEmpty) return 3;
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
    List<ProductoVariante>? variantes,
    bool? edicionVariantePendiente,
    List<PresentacionProducto>? presentaciones,
    List<PrecioProducto>? precios,
    Step4SalesDraft? ventaLogisticaContenido,
    PricingStep5Draft? preciosConfigurados,
    Step6ImagesDraft? imagenesConfiguradas,
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
    variantes: variantes ?? this.variantes,
    edicionVariantePendiente:
        edicionVariantePendiente ?? this.edicionVariantePendiente,
    presentaciones: presentaciones ?? this.presentaciones,
    precios: precios ?? this.precios,
    ventaLogisticaContenido:
        ventaLogisticaContenido ?? this.ventaLogisticaContenido,
    preciosConfigurados: preciosConfigurados ?? this.preciosConfigurados,
    imagenesConfiguradas: imagenesConfiguradas ?? this.imagenesConfiguradas,
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
    variantes,
    edicionVariantePendiente,
    presentaciones,
    precios,
    ventaLogisticaContenido,
    preciosConfigurados,
    imagenesConfiguradas,
    error,
    imagenesPaths,
    productoId,
    activo,
    creadoEn,
  ];
}
