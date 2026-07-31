from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()

PATHS = {
    'form_data': ROOT / 'lib/features/catalogo/domain/entities/catalogo_form_data.dart',
    'datasource': ROOT / 'lib/features/catalogo/data/datasources/catalogo_local_datasource.dart',
    'state': ROOT / 'lib/features/catalogo/presentation/bloc/producto_form_state.dart',
    'event': ROOT / 'lib/features/catalogo/presentation/bloc/producto_form_event.dart',
    'bloc': ROOT / 'lib/features/catalogo/presentation/bloc/producto_form_bloc.dart',
    'page': ROOT / 'lib/features/catalogo/presentation/pages/producto_form_page.dart',
    'matrix': ROOT / 'lib/features/catalogo/presentation/widgets/producto_matriz_step.dart',
    'variants': ROOT / 'lib/features/catalogo/presentation/widgets/producto_variantes_step.dart',
    'sales': ROOT / 'lib/features/catalogo/presentation/widgets/producto_venta_logistica_step.dart',
    'review': ROOT / 'lib/features/catalogo/presentation/widgets/producto_revision_step.dart',
    'legacy_test': ROOT / 'test/producto_form_page_test.dart',
}
FAMILY_WIDGET = ROOT / 'lib/features/catalogo/presentation/widgets/producto_atributos_familia.dart'
TEST_PATH = ROOT / 'test/flujo_producto_coherencia_test.dart'


def fail(message: str) -> None:
    raise SystemExit(f'\nERROR: {message}\nNo se escribió ningún archivo.')


def read(path: Path) -> str:
    if not path.exists():
        fail(f'No se encontró {path}')
    return path.read_text(encoding='utf-8')


def replace_once(content: str, old: str, new: str, label: str) -> str:
    count = content.count(old)
    if count != 1:
        fail(f'No se pudo aplicar “{label}”. Se esperaba 1 coincidencia y se encontraron {count}.')
    return content.replace(old, new, 1)


def regex_once(content: str, pattern: str, replacement: str, label: str, flags: int = re.DOTALL) -> str:
    try:
        updated, count = re.subn(pattern, replacement, content, count=1, flags=flags)
    except re.error as error:
        fail(f'El patrón de “{label}” es inválido: {error}')
    if count != 1:
        fail(f'No se pudo aplicar “{label}”. Se esperaba 1 bloque compatible y se encontraron {count}.')
    return updated


def _matching_brace(content: str, opening_index: int) -> int:
    depth = 0
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    index = opening_index
    while index < len(content):
        char = content[index]
        nxt = content[index + 1] if index + 1 < len(content) else ''
        if line_comment:
            if char == '\n':
                line_comment = False
            index += 1
            continue
        if block_comment:
            if char == '*' and nxt == '/':
                block_comment = False
                index += 2
                continue
            index += 1
            continue
        if quote is not None:
            if escaped:
                escaped = False
            elif char == '\\':
                escaped = True
            elif char == quote:
                quote = None
            index += 1
            continue
        if char == '/' and nxt == '/':
            line_comment = True
            index += 2
            continue
        if char == '/' and nxt == '*':
            block_comment = True
            index += 2
            continue
        if char in {'\'', '"'}:
            quote = char
            index += 1
            continue
        if char == '{':
            depth += 1
        elif char == '}':
            depth -= 1
            if depth == 0:
                return index
        index += 1
    return -1


def replace_dart_block(content: str, marker: str, replacement: str, label: str) -> str:
    start = content.find(marker)
    if start < 0:
        fail(f'No se encontró el inicio de “{label}”.')
    brace = content.find('{', start + len(marker))
    if brace < 0:
        fail(f'No se encontró la llave de apertura de “{label}”.')
    end = _matching_brace(content, brace)
    if end < 0:
        fail(f'No se pudo determinar el final de “{label}”.')
    return content[:start] + replacement + content[end + 1:]


contents = {name: read(path) for name, path in PATHS.items()}

if 'codigoProveedor' not in contents['variants']:
    fail('La fase 2 de códigos no está aplicada.')
if 'ValorTecnicoParser' not in contents['variants']:
    fail('La fase 3A de valores técnicos no está aplicada en la lista de variantes.')
if FAMILY_WIDGET.exists() or TEST_PATH.exists():
    fail('La fase 4A ya parece estar aplicada.')

# ---------------------------------------------------------------------------
# Entidad de definición de atributos: conserva nivel y capacidad de eje.
# ---------------------------------------------------------------------------
form_data = contents['form_data']
form_data = replace_once(
    form_data,
    "    this.magnitud,\n  });",
    "    this.magnitud,\n    this.nivelCaptura = 'familia',\n    this.puedeSerEje = false,\n    this.ayuda = '',\n    this.ejemplo = '',\n  });",
    'parámetros de metadatos del atributo',
)
form_data = replace_once(
    form_data,
    "  final String? magnitud;\n  @override",
    "  final String? magnitud;\n  final String nivelCaptura;\n  final bool puedeSerEje;\n  final String ayuda;\n  final String ejemplo;\n  @override",
    'campos de metadatos del atributo',
)
form_data = replace_once(
    form_data,
    "    magnitud,\n  ];",
    "    magnitud,\n    nivelCaptura,\n    puedeSerEje,\n    ayuda,\n    ejemplo,\n  ];",
    'props de metadatos del atributo',
)
contents['form_data'] = form_data

datasource = contents['datasource']
datasource = replace_once(
    datasource,
    "          magnitud: row['magnitud'] as String?,\n",
    "          magnitud: row['magnitud'] as String?,\n          nivelCaptura: capture,\n          puedeSerEje: row['puede_ser_eje'] == 1,\n          ayuda: row['ayuda'] as String? ?? '',\n          ejemplo: row['ejemplo'] as String? ?? '',\n",
    'cargar nivel, ejes y ayudas del atributo',
)
contents['datasource'] = datasource

# ---------------------------------------------------------------------------
# Estado coherente de seis pasos.
# ---------------------------------------------------------------------------
state_content = r'''import 'package:equatable/equatable.dart';

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

  List<AtributoDef> get atributosFamilia => atributosDisponibles
      .where((attribute) => !attribute.esVariante)
      .toList();

  List<AtributoDef> get atributosDeVariante => atributosDisponibles
      .where((attribute) => attribute.esVariante)
      .toList();

  List<AtributoDef> get atributosPermitidosComoEje => atributosDisponibles
      .where((attribute) => attribute.puedeSerEje)
      .toList();

  bool get atributosFamiliaCompletos => atributosFamilia
      .where((attribute) => attribute.requerido)
      .every((attribute) => (atributos[attribute.nombre] ?? '').trim().isNotEmpty);

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
      nombre.trim().isNotEmpty &&
      atributosFamiliaCompletos &&
      variantesValidas;

  bool get presentacionesCompletas =>
      ventaLogisticaContenido?.presentations.isNotEmpty ??
      presentaciones.isNotEmpty;

  bool get tieneConfiguracionDependiente =>
      atributos.isNotEmpty ||
      variantes.isNotEmpty ||
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
      clasificacionCompleta && estructuraProductoCompleta && presentacionesCompletas;

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
'''
contents['state'] = state_content

# ---------------------------------------------------------------------------
# Evento de resumen de matriz.
# ---------------------------------------------------------------------------
event = contents['event']
event = replace_once(
    event,
    "class ProductoFormVarianteEliminada extends ProductoFormEvent {",
    "class ProductoFormMatrizResumenCambiado extends ProductoFormEvent {\n  const ProductoFormMatrizResumenCambiado({\n    required this.total,\n    required this.excluidas,\n  });\n\n  final int total;\n  final int excluidas;\n\n  @override\n  List<Object?> get props => [total, excluidas];\n}\n\nclass ProductoFormVarianteEliminada extends ProductoFormEvent {",
    'evento de resumen de matriz',
)
contents['event'] = event

# ---------------------------------------------------------------------------
# BLoC: navegación bloqueada y reinicio de dependencias.
# ---------------------------------------------------------------------------
bloc = contents['bloc']
bloc = replace_once(
    bloc,
    "    on<ProductoFormPasoSeleccionado>((event, emit) {\n      if (event.paso >= 0 && event.paso <= 6) {\n        emit(state.copyWith(paso: event.paso, limpiarError: true));\n      }\n    });",
    "    on<ProductoFormPasoSeleccionado>((event, emit) {\n      if (state.pasoEsAccesible(event.paso)) {\n        emit(state.copyWith(paso: event.paso, limpiarError: true));\n        return;\n      }\n      emit(\n        state.copyWith(\n          error: 'Completa los pasos anteriores antes de continuar.',\n        ),\n      );\n    });",
    'bloquear saltos inválidos',
)
bloc = replace_once(
    bloc,
    "    on<ProductoFormTipoCambiado>((event, emit) {\n      if (event.tipo == state.tipoRegistro) return;\n      emit(\n        state.copyWith(\n          tipoRegistro: event.tipo,\n          variantes: const [],\n          edicionVariantePendiente: false,\n          limpiarError: true,\n        ),\n      );\n    });",
    "    on<ProductoFormTipoCambiado>((event, emit) {\n      if (event.tipo == state.tipoRegistro) return;\n      emit(\n        state.copyWith(\n          tipoRegistro: event.tipo,\n          variantes: const [],\n          edicionVariantePendiente: false,\n          matrizCombinacionesTotales: 0,\n          matrizCombinacionesExcluidas: 0,\n          presentaciones: const [],\n          precios: const [],\n          imagenesPaths: const [],\n          limpiarVentaLogisticaContenido: true,\n          limpiarPreciosConfigurados: true,\n          limpiarImagenesConfiguradas: true,\n          activo: false,\n          limpiarError: true,\n        ),\n      );\n    });",
    'reiniciar dependencias al cambiar tipo',
)
bloc = replace_once(
    bloc,
    "    on<ProductoFormVariantesReemplazadas>((event, emit) {",
    "    on<ProductoFormMatrizResumenCambiado>((event, emit) {\n      emit(\n        state.copyWith(\n          matrizCombinacionesTotales: event.total,\n          matrizCombinacionesExcluidas: event.excluidas,\n        ),\n      );\n    });\n    on<ProductoFormVariantesReemplazadas>((event, emit) {",
    'registrar resumen de matriz',
)

# Las referencias comerciales solo se conservan cuando permanecen los mismos ids.
bloc = regex_once(
    bloc,
    r"    on<ProductoFormVarianteGuardada>\(\(event, emit\) \{.*?\n    \}\);\n    on<ProductoFormMatrizResumenCambiado>",
    r'''    on<ProductoFormVarianteGuardada>((event, emit) {
      final variantes = [...state.variantes];
      final index = variantes.indexWhere(
        (variante) => variante.id == event.variante.id,
      );
      final cambiaEstructura = index < 0;
      if (cambiaEstructura) {
        variantes.add(event.variante);
      } else {
        variantes[index] = event.variante;
      }
      emit(
        state.copyWith(
          variantes: variantes,
          edicionVariantePendiente: false,
          presentaciones: cambiaEstructura ? const [] : null,
          precios: cambiaEstructura ? const [] : null,
          imagenesPaths: cambiaEstructura ? const [] : null,
          limpiarVentaLogisticaContenido: cambiaEstructura,
          limpiarPreciosConfigurados: cambiaEstructura,
          limpiarImagenesConfiguradas: cambiaEstructura,
          activo: cambiaEstructura ? false : null,
          limpiarError: true,
        ),
      );
    });
    on<ProductoFormMatrizResumenCambiado>''',
    'invalidar dependencias al agregar variante',
)
bloc = regex_once(
    bloc,
    r"    on<ProductoFormVariantesReemplazadas>\(\(event, emit\) \{.*?\n    \}\);\n    on<ProductoFormVarianteEliminada>",
    r'''    on<ProductoFormVariantesReemplazadas>((event, emit) {
      final currentIds = state.variantes.map((item) => item.id).toSet();
      final nextIds = event.variantes.map((item) => item.id).toSet();
      final cambiaEstructura =
          currentIds.length != nextIds.length ||
          !currentIds.containsAll(nextIds);
      emit(
        state.copyWith(
          variantes: event.variantes,
          edicionVariantePendiente: false,
          presentaciones: cambiaEstructura ? const [] : null,
          precios: cambiaEstructura ? const [] : null,
          imagenesPaths: cambiaEstructura ? const [] : null,
          limpiarVentaLogisticaContenido: cambiaEstructura,
          limpiarPreciosConfigurados: cambiaEstructura,
          limpiarImagenesConfiguradas: cambiaEstructura,
          activo: cambiaEstructura ? false : null,
          limpiarError: true,
        ),
      );
    });
    on<ProductoFormVarianteEliminada>''',
    'invalidar dependencias al cambiar combinaciones',
)
bloc = regex_once(
    bloc,
    r"    on<ProductoFormVarianteEliminada>\(\(event, emit\) \{.*?\n    \}\);\n    on<ProductoFormEdicionVarianteCambiada>",
    r'''    on<ProductoFormVarianteEliminada>((event, emit) {
      final variantes = state.variantes
          .where((variante) => variante.id != event.id)
          .toList();
      emit(
        state.copyWith(
          variantes: variantes,
          edicionVariantePendiente: false,
          presentaciones: const [],
          precios: const [],
          imagenesPaths: const [],
          limpiarVentaLogisticaContenido: true,
          limpiarPreciosConfigurados: true,
          limpiarImagenesConfiguradas: true,
          activo: false,
          limpiarError: true,
        ),
      );
    });
    on<ProductoFormEdicionVarianteCambiada>''',
    'invalidar dependencias al eliminar variante',
)
bloc = replace_once(
    bloc,
    "      final listaPrincipal = event.draft.lists.firstOrNull;\n      final tienePendientes =\n          listaPrincipal == null || !event.draft.canActivate(listaPrincipal.id);",
    "      final tienePendientes =\n          event.draft.lists.isEmpty ||\n          event.draft.lists.any(\n            (list) => !event.draft.canActivate(list.id),\n          );",
    'validar todas las listas de precios',
)
new_classification = r'''  void _clasificacion(
    ProductoFormClasificacionCambiada event,
    Emitter<ProductoFormState> emit,
  ) {
    final cambioEmpresa =
        event.empresa != null && event.empresa != state.empresa;
    final cambioMarca = event.marca != null && event.marca != state.marca;
    final cambioCategoria =
        event.categoria != null && event.categoria != state.categoria;
    final cambioSubcategoria =
        event.subcategoria != null && event.subcategoria != state.subcategoria;
    final cambioEstructural =
        cambioEmpresa || cambioMarca || cambioCategoria || cambioSubcategoria;

    emit(
      state.copyWith(
        empresa: event.empresa,
        marca: event.marca,
        limpiarMarca: cambioEmpresa && event.marca == null,
        categoria: event.categoria,
        limpiarCategoria:
            (cambioEmpresa || cambioMarca) && event.categoria == null,
        subcategoria: event.subcategoria,
        limpiarSubcategoria:
            (cambioEmpresa || cambioMarca || cambioCategoria) &&
            event.subcategoria == null,
        atributos: cambioEstructural ? const {} : null,
        variantes: cambioEstructural ? const [] : null,
        edicionVariantePendiente: cambioEstructural ? false : null,
        matrizCombinacionesTotales: cambioEstructural ? 0 : null,
        matrizCombinacionesExcluidas: cambioEstructural ? 0 : null,
        presentaciones: cambioEstructural ? const [] : null,
        precios: cambioEstructural ? const [] : null,
        imagenesPaths: cambioEstructural ? const [] : null,
        limpiarVentaLogisticaContenido: cambioEstructural,
        limpiarPreciosConfigurados: cambioEstructural,
        limpiarImagenesConfiguradas: cambioEstructural,
        activo: cambioEstructural ? false : null,
        limpiarError: true,
      ),
    );
  }'''
bloc = replace_dart_block(bloc, '  void _clasificacion(', new_classification, 'método de clasificación')
contents['bloc'] = bloc

# ---------------------------------------------------------------------------
# Editor de características comunes.
# ---------------------------------------------------------------------------
family_widget_content = r'''import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/catalogo_form_data.dart';
import '../../domain/services/valor_tecnico_parser.dart';
import '../bloc/producto_form_bloc.dart';
import '../bloc/producto_form_event.dart';
import '../bloc/producto_form_state.dart';

class ProductoAtributosFamilia extends StatelessWidget {
  const ProductoAtributosFamilia({required this.state, super.key});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) {
    final definitions = state.atributosFamilia;
    if (definitions.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const Key('atributos_comunes_familia'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5DDE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Color(0xFF20242B)),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Características comunes',
                      style: TextStyle(
                        color: Color(0xFF20242B),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Se completan una vez y se aplican a todas las variantes.',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 700
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: definitions
                    .map(
                      (definition) => SizedBox(
                        width: width,
                        child: _FamilyAttributeField(
                          key: ValueKey(
                            'familia-${definition.id}-${definition.nombre}',
                          ),
                          definition: definition,
                          initialValue:
                              state.atributos[definition.nombre] ?? '',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FamilyAttributeField extends StatefulWidget {
  const _FamilyAttributeField({
    required this.definition,
    required this.initialValue,
    super.key,
  });

  final AtributoDef definition;
  final String initialValue;

  @override
  State<_FamilyAttributeField> createState() =>
      _FamilyAttributeFieldState();
}

class _FamilyAttributeFieldState extends State<_FamilyAttributeField> {
  late final TextEditingController _controller;
  String _unit = '';
  Set<String> _selectedValues = {};

  AtributoDef get definition => widget.definition;

  @override
  void initState() {
    super.initState();
    final separated = ValorTecnicoParser.separarValorUnidad(widget.initialValue);
    _controller = TextEditingController(text: separated.valor);
    _selectedValues = _parseSelections(widget.initialValue);
    _unit = separated.unidad.isNotEmpty
        ? separated.unidad
        : definition.unidadPredeterminada ??
              (definition.unidades.isEmpty ? '' : definition.unidades.first);
  }

  @override
  void didUpdateWidget(covariant _FamilyAttributeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _selectedValues = _parseSelections(widget.initialValue);
    }
  }

  Set<String> _parseSelections(String raw) => raw
      .split(RegExp(r'[;|·]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit([String? directValue]) {
    final value = directValue ?? _controller.text.trim();
    final stored = definition.tipo == 'numero_unidad' && value.isNotEmpty
        ? '$value $_unit'.trim()
        : value;
    context.read<ProductoFormBloc>().add(
      ProductoFormAtributoCambiado(definition.nombre, stored),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = '${definition.nombre}${definition.requerido ? ' *' : ''}';
    final helper = definition.ayuda.trim().isNotEmpty
        ? definition.ayuda.trim()
        : null;

    if (definition.tipo == 'lista_unica' || definition.tipo == 'si_no') {
      final options = definition.tipo == 'si_no'
          ? const ['Sí', 'No']
          : definition.opciones;
      final current = options.contains(widget.initialValue)
          ? widget.initialValue
          : null;
      return DropdownButtonFormField<String>(
        key: ValueKey('atributo_familia_${definition.nombre}'),
        initialValue: current,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map((option) => DropdownMenuItem(value: option, child: Text(option)))
            .toList(),
        onChanged: (value) => _emit(value ?? ''),
      );
    }

    if (definition.tipo == 'lista_multiple') {
      return FormField<String>(
        initialValue: widget.initialValue,
        builder: (field) => InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            errorText: field.errorText,
            border: const OutlineInputBorder(),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: definition.opciones.map((option) {
              final checked = _selectedValues.contains(option);
              return FilterChip(
                label: Text(option),
                selected: checked,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedValues.add(option);
                    } else {
                      _selectedValues.remove(option);
                    }
                  });
                  _emit(_selectedValues.join(' · '));
                },
              );
            }).toList(),
          ),
        ),
      );
    }

    final numeric =
        definition.tipo == 'numero' || definition.tipo == 'numero_unidad';
    final valueField = TextFormField(
      key: ValueKey('atributo_familia_${definition.nombre}'),
      controller: _controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numeric
          ? [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9\s/.,aA+\-–—]'),
              ),
            ]
          : null,
      onChanged: (_) => _emit(),
      decoration: InputDecoration(
        labelText: label,
        hintText: definition.ejemplo.trim().isEmpty
            ? null
            : definition.ejemplo.trim(),
        helperText: helper,
        border: const OutlineInputBorder(),
      ),
    );

    if (definition.tipo != 'numero_unidad' || definition.unidades.isEmpty) {
      return valueField;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: valueField),
        const SizedBox(width: 8),
        SizedBox(
          width: 105,
          child: DropdownButtonFormField<String>(
            initialValue: definition.unidades.contains(_unit)
                ? _unit
                : definition.unidades.first,
            decoration: const InputDecoration(
              labelText: 'Unidad',
              border: OutlineInputBorder(),
            ),
            items: definition.unidades
                .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _unit = value);
              _emit();
            },
          ),
        ),
      ],
    );
  }
}
'''

# ---------------------------------------------------------------------------
# Página: seis pasos también en edición, campos y confirmaciones coherentes.
# ---------------------------------------------------------------------------
page = contents['page']
page = replace_once(
    page,
    "import '../widgets/producto_matriz_step.dart';\n",
    "import '../widgets/producto_matriz_step.dart';\nimport '../widgets/producto_atributos_familia.dart';\n",
    'importar atributos comunes',
)
page = regex_once(
    page,
    r"return state\.editando\s*\? _EditarProductoScaffold\(state: state\)\s*:\s*_RegistrarProductoScaffold\(state: state\);",
    "return _RegistrarProductoScaffold(state: state);",
    'unificar registro y edición',
)
page = page.replace("import 'dart:io';\n\n", '')
page = page.replace("import 'package:image_picker/image_picker.dart';\n", '')
page = page.replace(
    "import '../../../../core/presentation/widgets/app_notice.dart';\n",
    '',
)
page = page.replace(
    "import '../../domain/entities/catalogo_form_data.dart';\n",
    '',
)
# Elimina la navegación antigua de siete secciones y sus editores duplicados.
old_edit_start = page.find('class _EditarProductoScaffold extends StatelessWidget')
step_indicator_start = page.find('class _StepIndicator extends StatelessWidget')
if old_edit_start < 0 or step_indicator_start < 0 or step_indicator_start <= old_edit_start:
    fail('No se pudo aislar el scaffold antiguo de edición.')
page = page[:old_edit_start] + page[step_indicator_start:]
old_steps_start = page.find('class _PasoGeneralEdicion extends StatelessWidget')
shared_card_start = page.find('class _StepCard extends StatelessWidget')
if old_steps_start < 0 or shared_card_start < 0 or shared_card_start <= old_steps_start:
    fail('No se pudieron aislar los pasos antiguos de edición.')
page = page[:old_steps_start] + page[shared_card_start:]
page = replace_once(
    page,
    """      title: Text(
        'Nuevo producto',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),""",
    """      title: Text(
        state.editando ? 'Editar producto' : 'Nuevo producto',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),""",
    'título dinámico del formulario',
)
page = regex_once(
    page,
    r"_StepIndicator\(\s*paso: state\.paso,\s*tipoRegistro: state\.tipoRegistro,\s*\)",
    "_StepIndicator(state: state)",
    'usar estado completo en indicador',
)
step_indicator = r'''class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.state});

  final ProductoFormState state;

  static const _pasosInternos = ProductoFormState.pasosFlujo;
  static const _nombres = [
    'Empresa, marca y categoría',
    'Producto y variantes',
    'Venta, presentaciones y logística',
    'Precios',
    'Imágenes y archivos',
    'Publicación y revisión',
  ];
  static const _subtitulos = [
    'Selecciona la clasificación comercial del producto.',
    'Define la familia, sus características y los artículos vendibles.',
    'Configura unidades de venta, equivalencias y empaques.',
    'Asigna precios por lista, variante y presentación.',
    'Adjunta fotografías y define la imagen principal.',
    'Comprueba la información antes de publicar el producto.',
  ];

  int get _indiceVisual {
    final index = _pasosInternos.indexOf(state.paso);
    return index < 0 ? 1 : index;
  }

  String get _nombreActual {
    if (_indiceVisual != 1) return _nombres[_indiceVisual];
    return switch (state.tipoRegistro) {
      'matriz' => 'Producto y matriz de variantes',
      'unico' => 'Producto único',
      _ => 'Producto y lista de variantes',
    };
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontalPadding = constraints.maxWidth < 500 ? 16.0 : 28.0;
      final current = _indiceVisual;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          14,
          horizontalPadding,
          16,
        ),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Row(
                  children: [
                    for (var index = 0; index < _pasosInternos.length; index++) ...[
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index <= current
                                ? const Color(0xFFFFC500)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                      Builder(
                        builder: (context) {
                          final internalStep = _pasosInternos[index];
                          final accessible = state.pasoEsAccesible(internalStep);
                          return Tooltip(
                            message: accessible
                                ? 'Ir al paso ${index + 1}: ${_nombres[index]}'
                                : 'Completa los pasos anteriores',
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                key: ValueKey('paso_flujo_${index + 1}'),
                                customBorder: const CircleBorder(),
                                onTap: accessible
                                    ? () => context.read<ProductoFormBloc>().add(
                                          ProductoFormPasoSeleccionado(internalStep),
                                        )
                                    : null,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index <= current
                                        ? const Color(0xFFFFC500)
                                        : Colors.white,
                                    border: Border.all(
                                      color: accessible
                                          ? const Color(0xFFFFC500)
                                          : const Color(0xFFD0D5DD),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.inter(
                                      color: accessible
                                          ? const Color(0xFF1A1A1A)
                                          : const Color(0xFF98A2B3),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: constraints.maxWidth < 500 ? 12 : 16),
            Text(
              _nombreActual,
              style: GoogleFonts.inter(
                color: const Color(0xFF1A1A1A),
                fontSize: constraints.maxWidth < 500 ? 18 : 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitulos[_indiceVisual],
              style: GoogleFonts.inter(
                color: const Color(0xFF667085),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    },
  );
}'''
page = replace_dart_block(page, 'class _StepIndicator extends StatelessWidget', step_indicator, 'indicador de pasos')
page = replace_once(
    page,
    "        DropdownButtonFormField<String>(\n          key: ValueKey('$label-$value-${items.join('|')}'),",
    "        DropdownButtonFormField<String>(\n          key: ValueKey('$label-$value-${items.join('|')}'),",
    'validar estructura de dropdown de clasificación',
)
old_dropdown_callback = "          onChanged: items.isEmpty\n              ? null\n              : (value) =>\n                    context.read<ProductoFormBloc>().add(onChanged(value)),"
new_dropdown_callback = r'''          onChanged: items.isEmpty
              ? null
              : (nextValue) async {
                  if (nextValue == value) return;
                  var accepted = true;
                  if (state.tieneConfiguracionDependiente) {
                    accepted =
                        await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Reiniciar configuración'),
                            content: const Text(
                              'Cambiar la clasificación reiniciará atributos, '
                              'variantes, presentaciones, precios e imágenes '
                              'dependientes para evitar datos incompatibles.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Cambiar y reiniciar'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  }
                  if (!accepted || !context.mounted) return;
                  context.read<ProductoFormBloc>().add(onChanged(nextValue));
                },'''
page = replace_once(page, old_dropdown_callback, new_dropdown_callback, 'confirmar cambio de clasificación')
family_class = r'''class _PasoFamiliaTipo extends StatelessWidget {
  const _PasoFamiliaTipo({required this.state});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 20,
              compact ? 10 : 20,
              compact ? 12 : 20,
              0,
            ),
            child: _configurationCard(context, compact: compact),
          ),
          SizedBox(height: compact ? 8 : 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey('editor-${state.tipoRegistro}'),
                child: switch (state.tipoRegistro) {
                  'matriz' => ProductoMatrizStep(state: state),
                  'unico' => ProductoUnicoStep(state: state),
                  _ => ProductoVariantesStep(state: state),
                },
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _configurationCard(
    BuildContext context, {
    required bool compact,
  }) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFD5DDE8)),
    ),
    child: Padding(
      padding: EdgeInsets.all(compact ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Cómo se organiza este producto?',
            style: TextStyle(
              color: const Color(0xFF20242B),
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Elige la estructura que corresponda al catálogo del proveedor.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          SizedBox(height: compact ? 10 : 14),
          _typeSelector(context, compact: compact),
          SizedBox(height: compact ? 12 : 16),
          if (state.tipoRegistro == 'unico')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'El nombre de la familia se tomará del nombre comercial.',
                style: TextStyle(color: Color(0xFF5F4A00), fontSize: 12),
              ),
            )
          else ...[
            _familyFields(context, compact: compact),
            if (state.atributosFamilia.isNotEmpty) ...[
              const SizedBox(height: 14),
              ProductoAtributosFamilia(state: state),
            ],
          ],
        ],
      ),
    ),
  );

  Widget _typeSelector(BuildContext context, {required bool compact}) {
    final options = [
      (value: 'unico', title: 'Producto único', subtitle: 'Un artículo', icon: Icons.inventory_2_outlined),
      (value: 'variantes', title: 'Lista de variantes', subtitle: 'Medidas o modelos', icon: Icons.view_list_outlined),
      (value: 'matriz', title: 'Matriz', subtitle: 'Dos atributos como ejes', icon: Icons.grid_view_outlined),
    ];
    final children = options.map((option) => SizedBox(
      width: compact ? 176 : null,
      child: _typeOption(
        context,
        value: option.value,
        title: option.title,
        subtitle: option.subtitle,
        icon: option.icon,
        compact: compact,
      ),
    )).toList();
    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }
    return Row(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index < children.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _familyFields(BuildContext context, {required bool compact}) {
    final name = TextFormField(
      key: const Key('familia_nombre'),
      initialValue: state.nombre,
      onChanged: (value) => context.read<ProductoFormBloc>().add(
        ProductoFormFamiliaCambiada(nombre: value),
      ),
      decoration: const InputDecoration(
        labelText: 'Nombre de la familia *',
        hintText: 'Ej. Broca para metal HSS',
        border: OutlineInputBorder(),
      ),
    );
    final description = TextFormField(
      key: const Key('familia_descripcion'),
      initialValue: state.descripcion,
      onChanged: (value) => context.read<ProductoFormBloc>().add(
        ProductoFormFamiliaCambiada(descripcion: value),
      ),
      maxLines: compact ? 2 : 3,
      decoration: const InputDecoration(
        labelText: 'Descripción compartida (opcional)',
        hintText: 'Información que aplica a todas las variantes.',
        border: OutlineInputBorder(),
      ),
    );
    if (compact) {
      return Column(children: [name, const SizedBox(height: 10), description]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: name),
        const SizedBox(width: 12),
        Expanded(child: description),
      ],
    );
  }

  Widget _typeOption(
    BuildContext context, {
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool compact,
  }) {
    final selected = state.tipoRegistro == value;
    return InkWell(
      onTap: () async {
        if (selected) return;
        var accepted = true;
        if (state.tieneConfiguracionDependiente) {
          accepted =
              await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Cambiar estructura del producto'),
                  content: const Text(
                    'Se reiniciarán variantes, presentaciones, precios e '
                    'imágenes dependientes para evitar referencias inválidas.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Cambiar y reiniciar'),
                    ),
                  ],
                ),
              ) ??
              false;
        }
        if (!accepted || !context.mounted) return;
        context.read<ProductoFormBloc>().add(ProductoFormTipoCambiado(value));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 64 : 76),
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFC500).withValues(alpha: .12)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFFFC500) : const Color(0xFFD5DDE8),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF20242B), size: compact ? 20 : 24),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF667085), fontSize: 10)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFFFFC500), size: 18),
          ],
        ),
      ),
    );
  }
}'''
page = replace_dart_block(page, 'class _PasoFamiliaTipo extends StatelessWidget', family_class, 'paso producto y variantes')
contents['page'] = page

# ---------------------------------------------------------------------------
# Matriz: sin demostración, ejes de categoría, UUID estable y cero incluidas.
# ---------------------------------------------------------------------------
matrix = contents['matrix']
matrix = replace_once(
    matrix,
    "import 'package:flutter_bloc/flutter_bloc.dart';\n",
    "import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:uuid/uuid.dart';\n",
    'importar UUID en matriz',
)
matrix = replace_once(
    matrix,
    "    required this.key,\n",
    "    required this.id,\n    required this.key,\n",
    'id estable en combinación',
)
matrix = replace_once(
    matrix,
    "  final String key;\n",
    "  final String id;\n  final String key;\n",
    'campo id estable',
)
matrix = replace_once(
    matrix,
    "  _MatrixCombinationDraft copyWith({\n    bool? included,",
    "  _MatrixCombinationDraft copyWith({\n    String? id,\n    bool? included,",
    'copyWith id de matriz',
)
matrix = replace_once(
    matrix,
    "  }) => _MatrixCombinationDraft(\n    key: key,",
    "  }) => _MatrixCombinationDraft(\n    id: id ?? this.id,\n    key: key,",
    'conservar id en copyWith',
)
matrix = regex_once(
    matrix,
    r"  static const _matrixAxisOptions = \[.*?\n  \];",
    "  List<String> get _matrixAxisOptions => widget.state.atributosPermitidosComoEje\n      .map((attribute) => attribute.nombre)\n      .toSet()\n      .toList();",
    'ejes desde la categoría',
)
matrix = regex_once(
    matrix,
    r"  String _matrixDraftColumnAxis = 'Diámetro';.*?  final List<_MatrixMeasureDraft> _matrixDraftRows = \[.*?\n  \];",
    "  String _matrixDraftColumnAxis = '';\n  String _matrixDraftRowAxis = '';\n  String _matrixAppliedColumnAxis = '';\n  String _matrixAppliedRowAxis = '';\n\n  final List<_MatrixMeasureDraft> _matrixDraftColumns = [];\n  final List<_MatrixMeasureDraft> _matrixDraftRows = [];",
    'eliminar medidas de demostración',
)
matrix = replace_once(
    matrix,
    "    return family.isEmpty ? 'Perno hexagonal UNC 304' : family;",
    "    return family.isEmpty ? 'Familia sin nombre' : family;",
    'eliminar nombre de demostración',
)
initialize_matrix = r'''  void _initializeMatrix() {
    final axisOptions = _matrixAxisOptions;
    if (axisOptions.isNotEmpty) {
      _matrixDraftColumnAxis = axisOptions.first;
      _matrixAppliedColumnAxis = axisOptions.first;
    }
    if (axisOptions.length > 1) {
      _matrixDraftRowAxis = axisOptions[1];
      _matrixAppliedRowAxis = axisOptions[1];
    }

    final savedVariants = widget.state.variantes;
    if (savedVariants.isEmpty ||
        _matrixAppliedColumnAxis.isEmpty ||
        _matrixAppliedRowAxis.isEmpty) {
      _matrixAppliedColumns = const [];
      _matrixAppliedRows = const [];
      _matrixCombinations = const {};
      _matrixFocusedKey = null;
      return;
    }

    _matrixDraftColumns
      ..clear()
      ..addAll(
        _measuresFromVariants(savedVariants, _matrixAppliedColumnAxis, 'column'),
      );
    _matrixDraftRows
      ..clear()
      ..addAll(
        _measuresFromVariants(savedVariants, _matrixAppliedRowAxis, 'row'),
      );
    _matrixAppliedColumns = List.of(_matrixDraftColumns);
    _matrixAppliedRows = List.of(_matrixDraftRows);

    final combinations = <String, _MatrixCombinationDraft>{};
    for (final variant in savedVariants) {
      final row = _attributeLabel(variant, _matrixAppliedRowAxis);
      final column = _attributeLabel(variant, _matrixAppliedColumnAxis);
      if (row == null || column == null) continue;
      final key = _MatrixCombinationDraft.buildKey(row, column);
      combinations[key] = _MatrixCombinationDraft(
        id: variant.id,
        key: key,
        rowValue: row,
        columnValue: column,
        included: true,
        sku: variant.sku,
        supplierCode: variant.codigoProveedor,
        generatedName: variant.nombreCorto,
        initialActive: variant.activa,
        attributes: {
          for (final attribute in variant.atributos)
            if (attribute.nombre != _matrixAppliedColumnAxis &&
                attribute.nombre != _matrixAppliedRowAxis)
              attribute.nombre: attribute.texto,
        },
        wasEdited: true,
      );
    }
    _matrixCombinations = combinations;
    _matrixFocusedKey = combinations.keys.firstOrNull;
    final focused = _matrixFocusedCombination;
    if (focused != null) _loadMatrixEditor(focused);
  }

  List<_MatrixMeasureDraft> _measuresFromVariants(
    List<ProductoVariante> variants,
    String name,
    String prefix,
  ) {
    final result = <_MatrixMeasureDraft>[];
    final seen = <String>{};
    for (final variant in variants) {
      for (final attribute in variant.atributos) {
        if (attribute.nombre != name || !seen.add(attribute.texto)) continue;
        result.add(
          _MatrixMeasureDraft(
            id: '$prefix-${result.length + 1}',
            value: attribute.valor,
            unit: attribute.unidad,
          ),
        );
      }
    }
    return result;
  }'''
matrix = replace_dart_block(matrix, '  void _initializeMatrix()', initialize_matrix, 'inicialización limpia de matriz')
matrix = replace_once(
    matrix,
    "    bool included = true,",
    "    bool included = false,",
    'combinaciones nuevas excluidas',
)
matrix = replace_once(
    matrix,
    "    return _MatrixCombinationDraft(\n      key: key,",
    "    return _MatrixCombinationDraft(\n      id: const Uuid().v4(),\n      key: key,",
    'UUID de combinación nueva',
)
matrix = replace_once(
    matrix,
    "    context.read<ProductoFormBloc>().add(\n      ProductoFormVariantesReemplazadas(variants),\n    );",
    "    context.read<ProductoFormBloc>()\n      ..add(ProductoFormVariantesReemplazadas(variants))\n      ..add(\n        ProductoFormMatrizResumenCambiado(\n          total: _matrixCombinations.length,\n          excluidas: _matrixExcludedCount,\n        ),\n      );",
    'sincronizar resumen de matriz',
)
matrix = replace_once(
    matrix,
    "      id: 'matrix:${combination.key}',",
    "      id: combination.id,",
    'usar UUID estable en variante matricial',
)
matrix = replace_once(
    matrix,
    "class _MatrixAttributeFields {\n  _MatrixAttributeFields({String name = '', String value = ''})",
    "class _MatrixAttributeFields {\n  _MatrixAttributeFields({\n    String name = '',\n    String value = '',\n    this.managed = false,\n  })",
    'marcar atributos administrados de matriz',
)
matrix = replace_once(
    matrix,
    "  final TextEditingController nameController;\n  final TextEditingController valueController;",
    "  final TextEditingController nameController;\n  final TextEditingController valueController;\n  final bool managed;",
    'campo managed de matriz',
)
load_editor = r'''  void _loadMatrixEditor(_MatrixCombinationDraft combination) {
    _matrixVariantFormKey.currentState?.reset();
    _matrixSkuController.text = combination.sku;
    _matrixSupplierCodeController.text = combination.supplierCode;
    _matrixNameController.text = combination.generatedName;
    _matrixEditorInitialActive = combination.initialActive;

    final managedNames = widget.state.atributosDeVariante
        .where(
          (attribute) =>
              attribute.nombre != _matrixAppliedColumnAxis &&
              attribute.nombre != _matrixAppliedRowAxis,
        )
        .map((attribute) => attribute.nombre)
        .toList();
    final oldFields = List<_MatrixAttributeFields>.of(_matrixAttributeFields);
    _matrixAttributeFields
      ..clear()
      ..addAll(
        managedNames.map(
          (name) => _MatrixAttributeFields(
            name: name,
            value: combination.attributes[name] ?? '',
            managed: true,
          ),
        ),
      )
      ..addAll(
        combination.attributes.entries
            .where((entry) => !managedNames.contains(entry.key))
            .map(
              (entry) => _MatrixAttributeFields(
                name: entry.key,
                value: entry.value,
              ),
            ),
      );
    if (oldFields.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final fields in oldFields) {
          fields.dispose();
        }
      });
    }
    _matrixEditorDirty = false;
  }'''
matrix = replace_dart_block(matrix, '  void _loadMatrixEditor(', load_editor, 'cargar atributos administrados de matriz')
matrix = replace_once(
    matrix,
    "            controller: fields.nameController,\n            onChanged: (_) => _markMatrixEditorDirty(),",
    "            controller: fields.nameController,\n            readOnly: fields.managed,\n            onChanged: fields.managed ? null : (_) => _markMatrixEditorDirty(),",
    'nombre de atributo administrado de solo lectura',
)
matrix = matrix.replace('Atributos adicionales', 'Atributos técnicos de la variante')
matrix = matrix.replace('Añadir atributo', 'Añadir característica adicional')
contents['matrix'] = matrix

# ---------------------------------------------------------------------------
# Lista: aceptar rangos/compuestos y permitir característica excepcional.
# ---------------------------------------------------------------------------
variants = contents['variants']
variants = replace_once(
    variants,
    "FilteringTextInputFormatter.allow(RegExp(r'[0-9\\s/.,]'))",
    "FilteringTextInputFormatter.allow(RegExp(r'[0-9\\s/.,aA+\\-–—]'))",
    'entrada de rangos en lista',
)
variants = regex_once(
    variants,
    r"  double\? _parseVariantNumber\(String raw\) \{.*?\n  \}",
    "  double? _parseVariantNumber(String raw) {\n    final parsed = ValorTecnicoParser.parse(raw);\n    return parsed.esNumerico ? parsed.minimo : null;\n  }",
    'usar parser técnico en lista',
)
# Agrega un botón sin alterar la estructura del panel.
needle = "              ..._specs.map(_atributoField),"
replacement = "              ..._specs.map(_atributoField),\n              const SizedBox(height: 8),\n              Align(\n                alignment: Alignment.centerLeft,\n                child: TextButton.icon(\n                  key: const Key('agregar_atributo_adicional_lista'),\n                  onPressed: _agregarAtributoAdicional,\n                  icon: const Icon(Icons.add),\n                  label: const Text('Añadir característica adicional'),\n                ),\n              ),"
variants = replace_once(variants, needle, replacement, 'botón de atributo adicional en lista')
insert_before = "  void _marcarPendiente() {"
extra_method = r'''  Future<void> _agregarAtributoAdicional() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Característica adicional'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej. Norma especial',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.trim().isEmpty) return;
    if (_valores.containsKey(name) || _specs.any((spec) => spec.nombre == name)) {
      setState(() => _panelError = 'La característica “$name” ya existe.');
      return;
    }
    setState(() {
      _valores[name] = TextEditingController();
      _unidades[name] = '';
      _dirty = true;
    });
    _notificarPendiente(true);
  }

'''
variants = replace_once(variants, insert_before, extra_method + insert_before, 'método de atributo adicional en lista')
contents['variants'] = variants

# ---------------------------------------------------------------------------
# Venta: nunca crear una variante ficticia.
# ---------------------------------------------------------------------------
sales = contents['sales']
sales = replace_once(
    sales,
    "    final initialDraft =\n        state.ventaLogisticaContenido ?? _legacyDraft(variants);\n\n    return Step4SalesLogisticsContentPanel(",
    "    if (variants.isEmpty) {\n      return _MissingVariantsPanel(\n        onBack: () => context.read<ProductoFormBloc>().add(\n          const ProductoFormPasoAnterior(),\n        ),\n      );\n    }\n    final initialDraft =\n        state.ventaLogisticaContenido ?? _legacyDraft(variants);\n\n    return Step4SalesLogisticsContentPanel(",
    'bloquear venta sin variantes',
)
sales = regex_once(
    sales,
    r"    if \(source\.isEmpty\) \{\n      return \[.*?\n      \];\n    \}",
    "    if (source.isEmpty) return const [];",
    'eliminar variante temporal',
)
sales += r'''

class _MissingVariantsPanel extends StatelessWidget {
  const _MissingVariantsPanel({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 44),
              const SizedBox(height: 12),
              const Text(
                'No hay variantes vendibles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Regresa al paso 2 y registra o incluye al menos una variante real.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onBack, child: const Text('Volver al producto')),
            ],
          ),
        ),
      ),
    ),
  );
}
'''
contents['sales'] = sales

# ---------------------------------------------------------------------------
# Revisión: navegación correcta, conteos reales y terminología interna.
# ---------------------------------------------------------------------------
review = contents['review']
review = replace_once(
    review,
    "    onReviewStep: (stepNumber) => context.read<ProductoFormBloc>().add(\n      ProductoFormPasoSeleccionado(stepNumber - 1),\n    ),",
    "    onReviewStep: (stepNumber) {\n      const internalSteps = ProductoFormState.pasosFlujo;\n      final index = stepNumber - 1;\n      if (index < 0 || index >= internalSteps.length) return;\n      context.read<ProductoFormBloc>().add(\n        ProductoFormPasoSeleccionado(internalSteps[index]),\n      );\n    },",
    'navegación correcta desde revisión',
)
review = replace_once(
    review,
    "      excludedCombinationCount: 0,",
    "      excludedCombinationCount: state.matrizCombinacionesExcluidas,",
    'conteo real de combinaciones excluidas',
)
review = replace_once(
    review,
    "      initialStatus: Step7InitialStatus.active,",
    "      initialStatus: state.activo\n          ? Step7InitialStatus.active\n          : Step7InitialStatus.inactive,",
    'estado real en revisión',
)
review = replace_once(review, "      visibleInCatalog: true,\n      visibleInNewOrder: true,", "      visibleInCatalog: state.activo,\n      visibleInNewOrder: state.activo,", 'visibilidad real en revisión')
review = review.replace('Completa el SKU y el nombre', 'Completa el código interno y el nombre')
contents['review'] = review

# ---------------------------------------------------------------------------
# Actualiza pruebas del flujo anterior para las nuevas reglas coherentes.
# ---------------------------------------------------------------------------
legacy_test = contents['legacy_test']
legacy_test = regex_once(
    legacy_test,
    r"  testWidgets\('el indicador usa seis pasos y permite navegar por número',.*?\n  \}\);\n\n  testWidgets\('el paso 2 combina tipo, familia y variantes'",
    r'''  testWidgets('el indicador usa seis pasos y bloquea pasos futuros', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _FakeCatalogoRepository(),
        child: const MaterialApp(home: ProductoFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    final bloc = tester.element(find.byType(Scaffold)).read<ProductoFormBloc>();
    expect(find.byKey(const ValueKey('paso_flujo_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('paso_flujo_6')), findsOneWidget);
    expect(find.byKey(const ValueKey('paso_flujo_7')), findsNothing);
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('paso_flujo_3'))).onTap,
      isNull,
    );
    expect(bloc.state.paso, 0);

    bloc
      ..add(
        const ProductoFormClasificacionCambiada(
          empresa: 'DINA',
          marca: 'DINA',
          categoria: 'Pernería',
        ),
      )
      ..add(
        const ProductoFormClasificacionCambiada(
          subcategoria: 'Pernos métricos',
        ),
      );
    await tester.pumpAndSettle();

    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('paso_flujo_2'))).onTap,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('paso_flujo_2')));
    await tester.pumpAndSettle();
    expect(bloc.state.paso, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el paso 2 combina tipo, familia y variantes' ''',
    'prueba de navegación bloqueada',
)
legacy_test = regex_once(
    legacy_test,
    r"  testWidgets\(\n    'Matriz abre su pantalla, genera combinaciones y sincroniza variantes',.*?\n  \);\n\n  testWidgets\('Matriz no desborda en una pantalla angosta'",
    r'''  testWidgets(
    'Matriz inicia vacía y crea solo combinaciones incluidas',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepositoryProvider<CatalogoRepository>.value(
          value: _FakeCatalogoRepository(),
          child: const MaterialApp(home: ProductoFormPage()),
        ),
      );
      await tester.pumpAndSettle();

      final bloc = tester
          .element(find.byType(Scaffold))
          .read<ProductoFormBloc>();
      bloc
        ..add(
          const ProductoFormClasificacionCambiada(
            empresa: 'DINA',
            marca: 'DINA',
            categoria: 'Pernería',
          ),
        )
        ..add(
          const ProductoFormClasificacionCambiada(
            subcategoria: 'Pernos métricos',
          ),
        )
        ..add(const ProductoFormFamiliaCambiada(nombre: 'Perno hexagonal'))
        ..add(const ProductoFormTipoCambiado('matriz'))
        ..add(const ProductoFormPasoSeleccionado(1));
      await tester.pumpAndSettle();

      expect(find.text('Matriz de variantes'), findsWidgets);
      expect(
        find.text('0 combinaciones · 0 variantes a crear · 0 no existen'),
        findsOneWidget,
      );
      expect(bloc.state.variantes, isEmpty);

      Future<void> addMeasure(int chipIndex, String value) async {
        await tester.tap(
          find.widgetWithText(ActionChip, 'Añadir medida').at(chipIndex),
        );
        await tester.pumpAndSettle();
        final dialogFields = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(dialogFields.at(0), value);
        await tester.enterText(dialogFields.at(1), 'mm');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
        await tester.pumpAndSettle();
      }

      await addMeasure(0, '10');
      await addMeasure(1, '40');
      tester
          .widget<OutlinedButton>(find.byKey(const Key('actualizar_matriz')))
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      expect(
        find.text('1 combinaciones · 0 variantes a crear · 1 no existen'),
        findsOneWidget,
      );
      expect(bloc.state.variantes, isEmpty);

      await tester.ensureVisible(
        find.byKey(const Key('alternar_combinacion_matriz')),
      );
      await tester.tap(find.byKey(const Key('alternar_combinacion_matriz')));
      await tester.pumpAndSettle();
      expect(bloc.state.variantes, hasLength(1));
      expect(bloc.state.variantes.single.id, isNot(contains('matrix:')));
      expect(
        bloc.state.variantes.single.atributos.map((item) => item.nombre),
        containsAll(['Diámetro', 'Largo']),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Matriz no desborda en una pantalla angosta' ''',
    'prueba de matriz vacía',
)
legacy_test = replace_once(
    legacy_test,
    "    expect(find.text('Detalle de variante'), findsOneWidget);\n"
    "    expect(bloc.state.variantes, hasLength(14));",
    "    expect(bloc.state.variantes, isEmpty);\n"
    "    expect(\n"
    "      find.text('0 combinaciones · 0 variantes a crear · 0 no existen'),\n"
    "      findsOneWidget,\n"
    "    );",
    'prueba angosta sin variantes predeterminadas',
)
legacy_test = regex_once(
    legacy_test,
    r"  testWidgets\('la edición usa navegación lateral y guardado fijo',.*?\n  \}\);\n\}",
    r'''  testWidgets('la edición conserva el mismo flujo de seis pasos', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _FakeCatalogoRepository(),
        child: const MaterialApp(home: ProductoFormPage(productoId: 'editar')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar producto'), findsOneWidget);
    expect(find.byKey(const ValueKey('paso_flujo_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('paso_flujo_6')), findsOneWidget);
    expect(find.text('General'), findsNothing);
    expect(find.byKey(const Key('guardar_cambios')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}''',
    'prueba de edición unificada',
)
legacy_test = legacy_test.replace(
    "              unidadPredeterminada: 'mm',\n            ),",
    "              unidadPredeterminada: 'mm',\n              puedeSerEje: true,\n            ),",
)
contents['legacy_test'] = legacy_test

# ---------------------------------------------------------------------------
# Pruebas enfocadas en coherencia del estado.
# ---------------------------------------------------------------------------
test_content = r'''import 'package:flutter_test/flutter_test.dart';

import 'package:app_catalogo/features/catalogo/domain/entities/catalogo_form_data.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_variante.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/producto_form_state.dart';

void main() {
  CatalogoFormData data() => const CatalogoFormData(
    empresas: ['DINA'],
    marcas: ['DINA'],
    subcategorias: {
      'Pernería': ['Pernos métricos'],
    },
    atributos: {
      'Pernos métricos': [
        AtributoDef(
          nombre: 'Material',
          tipo: 'lista_unica',
          esVariante: false,
          requerido: true,
          opciones: ['Acero', 'Inoxidable'],
          nivelCaptura: 'familia',
        ),
        AtributoDef(
          nombre: 'Diámetro',
          tipo: 'numero_unidad',
          esVariante: true,
          requerido: true,
          unidades: ['mm'],
          puedeSerEje: true,
          nivelCaptura: 'variante',
        ),
        AtributoDef(
          nombre: 'Largo',
          tipo: 'numero_unidad',
          esVariante: true,
          requerido: true,
          unidades: ['mm'],
          puedeSerEje: true,
          nivelCaptura: 'variante',
        ),
      ],
    },
  );

  ProductoFormState classified() => ProductoFormState.initial().copyWith(
    loading: false,
    datos: data(),
    empresa: 'DINA',
    marca: 'DINA',
    categoria: 'Pernería',
    subcategoria: 'Pernos métricos',
  );

  test('los pasos futuros permanecen bloqueados hasta completar dependencias', () {
    final state = classified();
    expect(state.pasoEsAccesible(1), isTrue);
    expect(state.pasoEsAccesible(3), isFalse);
    expect(state.pasoEsAccesible(4), isFalse);
  });

  test('un atributo común requerido forma parte de la validación del paso 2', () {
    final variant = ProductoVariante(
      id: 'v1',
      sku: 'VAR-0000000001',
      nombreCorto: 'Perno M8',
      atributos: const [
        AtributoProductoVariante(nombre: 'Diámetro', valor: '8', unidad: 'mm'),
        AtributoProductoVariante(nombre: 'Largo', valor: '30', unidad: 'mm'),
      ],
    );
    final incomplete = classified().copyWith(
      paso: 1,
      nombre: 'Perno hexagonal',
      variantes: [variant],
    );
    expect(incomplete.pasoValido, isFalse);
    expect(incomplete.mensajePasoInvalido, contains('características comunes'));

    final complete = incomplete.copyWith(
      atributos: const {'Material': 'Acero'},
    );
    expect(complete.pasoValido, isTrue);
    expect(complete.pasoEsAccesible(3), isTrue);
  });

  test('el producto nuevo comienza como borrador inactivo', () {
    expect(ProductoFormState.initial().activo, isFalse);
  });
}
'''

updates = {PATHS[name]: content for name, content in contents.items()}
updates[FAMILY_WIDGET] = family_widget_content
updates[TEST_PATH] = test_content

# Todas las transformaciones se validan antes de escribir.
required_markers = {
    PATHS['state']: ['atributosFamiliaCompletos', 'pasoEsAccesible', 'matrizCombinacionesExcluidas'],
    PATHS['page']: ['ProductoAtributosFamilia', 'Nombre de la familia *', 'Completa los pasos anteriores'],
    PATHS['matrix']: ['const Uuid().v4()', 'included = false', 'ProductoFormMatrizResumenCambiado'],
    PATHS['sales']: ['No hay variantes vendibles'],
    PATHS['legacy_test']: ['bloquea pasos futuros', 'Matriz inicia vacía'],
}
for path, markers in required_markers.items():
    content = updates[path]
    for marker in markers:
        if marker not in content:
            fail(f'La validación final no encontró “{marker}” en {path}.')

timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
backup_dir = ROOT / f'.backup_fase4a_coherencia_{timestamp}'
backup_dir.mkdir(parents=True, exist_ok=False)
for path in updates:
    if not path.exists():
        continue
    target = backup_dir / path.relative_to(ROOT)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)

for path, content in updates.items():
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding='utf-8', newline='\n')
    print(f'Modificado: {path.relative_to(ROOT)}')

print(f'\nRespaldo: {backup_dir}')
print('\nFase 4A aplicada.')
print('Ejecuta:')
print('  dart format lib test')
print('  flutter test test/flujo_producto_coherencia_test.dart')
print('  flutter test test/producto_form_page_test.dart')
print('  flutter analyze')
