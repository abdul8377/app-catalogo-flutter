import 'package:equatable/equatable.dart';

import '../../../domain/entities/catalogo_form_data.dart';
import '../../../domain/entities/producto_variante.dart';
import '../../models/producto_form/imagenes_draft.dart';
import '../../models/producto_form/precios_draft.dart';
import '../../models/producto_form/venta_logistica_draft.dart';

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
    required this.matrizCombinacionesTotales,
    required this.matrizCombinacionesExcluidas,
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

  static const pasosFlujo = <int>[0, 1, 3, 4, 5, 6];

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
    matrizCombinacionesTotales: 0,
    matrizCombinacionesExcluidas: 0,
    presentaciones: [],
    precios: [],
    imagenesPaths: [],
    productoId: null,
    activo: false,
    creadoEn: null,
  );

  final bool loading, saving, guardado;
  final int paso;
  final CatalogoFormData? datos;
  final String codigo, nombre, descripcion, tipoRegistro;
  final String? empresa, marca, categoria, subcategoria, error;
  final List<String> imagenesPaths;
  final String? productoId;
  final bool activo;
  final DateTime? creadoEn;
  final Map<String, String> atributos;
  final List<ProductoVariante> variantes;
  final bool edicionVariantePendiente;
  final int matrizCombinacionesTotales;
  final int matrizCombinacionesExcluidas;
  final List<PresentacionProducto> presentaciones;
  final List<PrecioProducto> precios;
  final Step4SalesDraft? ventaLogisticaContenido;
  final PricingStep5Draft? preciosConfigurados;
  final Step6ImagesDraft? imagenesConfiguradas;

  String? get imagenPath => imagenesPaths.isEmpty ? null : imagenesPaths.first;
  bool get editando => productoId != null;

  bool get preciosListosParaActivar {
    final draft = preciosConfigurados;
    if (draft == null) return precios.isNotEmpty;
    if (draft.lists.isEmpty) return false;
    return draft.lists.every((list) => draft.canActivate(list.id));
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
    final selectedSubcategory = subcategoria;
    if (selectedSubcategory != null) {
      final values = formData.atributos[selectedSubcategory];
      if (values != null && values.isNotEmpty) return values;
    }
    final selectedCategory = categoria;
    return selectedCategory == null
        ? const []
        : formData.atributos[selectedCategory] ?? const [];
  }

  List<AtributoDef> get atributosFamilia =>
      atributosDisponibles.where((attribute) => !attribute.esVariante).toList();

  List<AtributoDef> get atributosDeVariante =>
      atributosDisponibles.where((attribute) => attribute.esVariante).toList();

  List<AtributoDef> get atributosPermitidosComoEje =>
      atributosDisponibles.where((attribute) => attribute.puedeSerEje).toList();

  bool get atributosFamiliaCompletos => atributosFamilia
      .where((attribute) => attribute.requerido)
      .every(
        (attribute) => (atributos[attribute.nombre] ?? '').trim().isNotEmpty,
      );

  bool get subcategoriaRequerida => subcategorias.isNotEmpty;

  bool get clasificacionCompleta =>
      empresa != null &&
      marca != null &&
      categoria != null &&
      (!subcategoriaRequerida || subcategoria != null);

  bool get variantesCompletas => variantes.every(
    (variant) =>
        variant.sku.trim().isNotEmpty && variant.nombreCorto.trim().isNotEmpty,
  );

  bool get variantesConCodigoUnico {
    final codes = variantes
        .map((variant) => variant.sku.trim().toUpperCase())
        .where((code) => code.isNotEmpty)
        .toList();
    return codes.toSet().length == codes.length;
  }

  bool get variantesValidas =>
      variantes.isNotEmpty &&
      variantes.any((variant) => variant.activa) &&
      variantesCompletas &&
      variantesConCodigoUnico &&
      (tipoRegistro != 'unico' || variantes.length == 1) &&
      !edicionVariantePendiente;

  bool get estructuraProductoCompleta =>
      nombre.trim().isNotEmpty && atributosFamiliaCompletos && variantesValidas;

  bool get presentacionesCompletas =>
      ventaLogisticaContenido?.presentations.isNotEmpty ??
      presentaciones.isNotEmpty;

  bool get tieneVariantesConDatosIngresados => variantes.any(
    (variant) =>
        variant.codigoProveedor.trim().isNotEmpty ||
        variant.nombreCorto.trim().isNotEmpty ||
        variant.atributos.isNotEmpty,
  );

  bool get tieneConfiguracionDependiente =>
      atributos.isNotEmpty ||
      tieneVariantesConDatosIngresados ||
      presentaciones.isNotEmpty ||
      ventaLogisticaContenido != null ||
      precios.isNotEmpty ||
      preciosConfigurados != null ||
      imagenesPaths.isNotEmpty ||
      imagenesConfiguradas != null;

  bool get pasoValido => switch (paso) {
    0 => clasificacionCompleta,
    1 || 2 => estructuraProductoCompleta,
    3 => presentacionesCompletas,
    _ => true,
  };

  String get mensajePasoInvalido => switch (paso) {
    0 => 'Completa la empresa, marca, categoría y subcategoría requeridas.',
    1 when nombre.trim().isEmpty =>
      tipoRegistro == 'unico'
          ? 'Ingresa el nombre comercial.'
          : 'Ingresa el nombre de la familia.',
    1 when !atributosFamiliaCompletos =>
      'Completa las características comunes obligatorias.',
    1 when edicionVariantePendiente =>
      'Guarda o cancela los cambios de la variante antes de continuar.',
    1 when variantes.isEmpty =>
      tipoRegistro == 'matriz'
          ? 'Incluye al menos una combinación real de la matriz.'
          : tipoRegistro == 'unico'
          ? 'Completa los datos del producto único.'
          : 'Agrega al menos una variante para continuar.',
    1 when !variantes.any((variant) => variant.activa) =>
      'Activa al menos una variante para continuar.',
    1 when !variantesCompletas =>
      'Completa el código interno y el nombre de todas las variantes.',
    1 when !variantesConCodigoUnico =>
      'Corrige los códigos internos duplicados antes de continuar.',
    1 when tipoRegistro == 'unico' && variantes.length != 1 =>
      'Un producto único debe tener exactamente una variante.',
    2 => 'Completa la estructura del producto antes de continuar.',
    3 => 'Agrega una presentación vendible para cada variante.',
    _ => 'Revisa los datos requeridos antes de continuar.',
  };

  int get ultimoIndiceAccesible {
    if (!clasificacionCompleta) return 0;
    if (!estructuraProductoCompleta) return 1;
    if (!presentacionesCompletas) return 2;
    return pasosFlujo.length - 1;
  }

  bool pasoEsAccesible(int target) {
    final index = pasosFlujo.indexOf(target);
    return index >= 0 && index <= ultimoIndiceAccesible;
  }

  bool get formularioValido =>
      clasificacionCompleta &&
      estructuraProductoCompleta &&
      presentacionesCompletas;

  int get primerPasoInvalido {
    if (!clasificacionCompleta) return 0;
    if (!estructuraProductoCompleta) return 1;
    if (!presentacionesCompletas) return 3;
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
    int? matrizCombinacionesTotales,
    int? matrizCombinacionesExcluidas,
    List<PresentacionProducto>? presentaciones,
    List<PrecioProducto>? precios,
    Step4SalesDraft? ventaLogisticaContenido,
    bool limpiarVentaLogisticaContenido = false,
    PricingStep5Draft? preciosConfigurados,
    bool limpiarPreciosConfigurados = false,
    Step6ImagesDraft? imagenesConfiguradas,
    bool limpiarImagenesConfiguradas = false,
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
    matrizCombinacionesTotales:
        matrizCombinacionesTotales ?? this.matrizCombinacionesTotales,
    matrizCombinacionesExcluidas:
        matrizCombinacionesExcluidas ?? this.matrizCombinacionesExcluidas,
    presentaciones: presentaciones ?? this.presentaciones,
    precios: precios ?? this.precios,
    ventaLogisticaContenido: limpiarVentaLogisticaContenido
        ? null
        : ventaLogisticaContenido ?? this.ventaLogisticaContenido,
    preciosConfigurados: limpiarPreciosConfigurados
        ? null
        : preciosConfigurados ?? this.preciosConfigurados,
    imagenesConfiguradas: limpiarImagenesConfiguradas
        ? null
        : imagenesConfiguradas ?? this.imagenesConfiguradas,
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
    matrizCombinacionesTotales,
    matrizCombinacionesExcluidas,
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
