from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil
import subprocess

ROOT = Path.cwd()
EXPECTED_HEAD = "21517315da055204666ac2c11e0755690e634777"

CATALOGO_STATE = ROOT / (
    "lib/features/catalogo/presentation/bloc/catalogo_state.dart"
)
CATALOGO_BLOC = ROOT / (
    "lib/features/catalogo/presentation/bloc/catalogo_bloc.dart"
)
FILTROS = ROOT / (
    "lib/features/catalogo/presentation/widgets/filtros_catalogo.dart"
)
PEDIDOS_STATE = ROOT / (
    "lib/features/pedidos/presentation/bloc/pedidos_state.dart"
)
PEDIDOS_BLOC = ROOT / (
    "lib/features/pedidos/presentation/bloc/pedidos_bloc.dart"
)
PRECIOS = ROOT / (
    "lib/features/catalogo/presentation/widgets/paso5_precios_corregido.dart"
)
PDF_SERVICE = ROOT / (
    "lib/features/pedidos/data/services/cotizacion_pdf_service.dart"
)
CATALOGO_TEST = ROOT / "test/catalogo_bloc_test.dart"
PDF_TEST = ROOT / "test/cotizacion_pdf_service_test.dart"

MULTI_FILTER_TEST = ROOT / "test/filtros_subcategorias_multiple_test.dart"
ORDER_FILTER_TEST = ROOT / "test/pedidos_subcategorias_filtro_test.dart"
SAFE_AREA_TEST = ROOT / "test/precios_footer_safe_area_test.dart"

MODIFIED_PATHS = [
    CATALOGO_STATE,
    CATALOGO_BLOC,
    FILTROS,
    PEDIDOS_STATE,
    PEDIDOS_BLOC,
    PRECIOS,
    PDF_SERVICE,
    CATALOGO_TEST,
    PDF_TEST,
]
NEW_PATHS = [
    MULTI_FILTER_TEST,
    ORDER_FILTER_TEST,
    SAFE_AREA_TEST,
]


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        fail(
            f"No se pudo aplicar “{label}”. "
            f"Se esperaba 1 coincidencia y se encontraron {count}."
        )
    return source.replace(old, new, 1)


def replace_between(
    source: str,
    start_marker: str,
    end_marker: str,
    replacement: str,
    label: str,
) -> str:
    starts = source.count(start_marker)
    ends = source.count(end_marker)
    if starts != 1 or ends != 1:
        fail(
            f"No se pudo delimitar “{label}”. "
            f"Inicio: {starts}; fin: {ends}."
        )
    start = source.index(start_marker)
    end = source.index(end_marker, start)
    return source[:start] + replacement.rstrip() + "\n\n" + source[end:]


try:
    head = subprocess.check_output(
        ["git", "rev-parse", "HEAD"],
        cwd=ROOT,
        text=True,
    ).strip()
except Exception as error:
    fail(f"No se pudo leer el commit actual: {error}")

if head != EXPECTED_HEAD:
    fail(
        "El repositorio local no está en el commit validado. "
        f"Esperado: {EXPECTED_HEAD}; actual: {head}."
    )

for path in MODIFIED_PATHS:
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

for path in NEW_PATHS:
    if path.exists():
        fail(f"Ya existe {path.relative_to(ROOT)}")

sources = {
    path: path.read_text(encoding="utf-8")
    for path in MODIFIED_PATHS
}

catalogo_state = sources[CATALOGO_STATE]
catalogo_bloc = sources[CATALOGO_BLOC]
filtros = sources[FILTROS]
pedidos_state = sources[PEDIDOS_STATE]
pedidos_bloc = sources[PEDIDOS_BLOC]
precios = sources[PRECIOS]
pdf_service = sources[PDF_SERVICE]
catalogo_test = sources[CATALOGO_TEST]
pdf_test = sources[PDF_TEST]

# ---------------------------------------------------------------------------
# 1. Filtro múltiple real de subcategorías.
# ---------------------------------------------------------------------------
catalogo_filtros_class = r"""class CatalogoFiltros extends Equatable {
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
}"""
catalogo_state = replace_between(
    catalogo_state,
    "class CatalogoFiltros extends Equatable {\n",
    "class CatalogoState extends Equatable {\n",
    catalogo_filtros_class,
    "modelo de filtros múltiples",
)

catalogo_bloc = replace_once(
    catalogo_bloc,
    """    final f = estado.filtros;
    productos = productos
""",
    """    final f = estado.filtros;
    final subcategorias = f.subcategoriasActivas;
    productos = productos
""",
    "subcategorías activas del catálogo",
)
catalogo_bloc = replace_once(
    catalogo_bloc,
    """              (f.subcategoria == null || p.subcategoria == f.subcategoria) &&
""",
    """              (subcategorias.isEmpty ||
                  subcategorias.contains(p.subcategoria)) &&
""",
    "filtrado múltiple del catálogo",
)

old_active_subcategory = """      if (filters.subcategoria != null)
        _chip(
          'Subcategoría: ${filters.subcategoria}',
          () => onChanged(filters.copyWith(clearSubcategoria: true)),
        ),
"""
new_active_subcategory = """      for (final subcategoria in filters.subcategoriasActivas)
        _chip(
          'Subcategoría: $subcategoria',
          () {
            final restantes = {...filters.subcategoriasActivas}
              ..remove(subcategoria);
            onChanged(
              filters.copyWith(
                subcategorias: restantes,
                clearSubcategoria: true,
              ),
            );
          },
        ),
"""
filtros = replace_once(
    filtros,
    old_active_subcategory,
    new_active_subcategory,
    "chips de subcategorías activas",
)

old_normalize = """  CatalogoFiltros _normalize(CatalogoFiltros value) {
    var result = value;
    if (!_brands(result).contains(result.marca)) {
      result = result.copyWith(clearMarca: true);
    }
    if (!_categories(result).contains(result.categoria)) {
      result = result.copyWith(clearCategoria: true, clearSubcategoria: true);
    }
    if (!_subcategories(result).contains(result.subcategoria)) {
      result = result.copyWith(clearSubcategoria: true);
    }
    return result;
  }
"""
new_normalize = """  CatalogoFiltros _normalize(CatalogoFiltros value) {
    var result = value;
    if (!_brands(result).contains(result.marca)) {
      result = result.copyWith(clearMarca: true);
    }
    if (!_categories(result).contains(result.categoria)) {
      result = result.copyWith(
        clearCategoria: true,
        clearSubcategoria: true,
      );
    }

    final disponibles = _subcategories(result).toSet();
    final actuales = result.subcategoriasActivas;
    final validas = actuales.where(disponibles.contains).toSet();
    if (validas.length != actuales.length) {
      result = result.copyWith(
        subcategorias: validas,
        clearSubcategoria: true,
      );
    }
    return result;
  }
"""
filtros = replace_once(
    filtros,
    old_normalize,
    new_normalize,
    "normalización de subcategorías múltiples",
)

old_subcategory_select = """                          _DialogSelect(
                            label: 'Subcategoría',
                            value: subcategories.contains(_draft.subcategoria)
                                ? _draft.subcategoria
                                : null,
                            options: subcategories,
                            allLabel: 'Todas las subcategorías',
                            onChanged: (value) => _update(
                              _draft.copyWith(
                                subcategoria: value,
                                clearSubcategoria: value == null,
                              ),
                            ),
                          ),
"""
new_subcategory_select = """                          _DialogMultiSelect(
                            key: const Key(
                              'dialog_subcategorias_multiple',
                            ),
                            label: 'Subcategorías',
                            selected: _draft.subcategoriasActivas,
                            options: subcategories,
                            allLabel: 'Todas las subcategorías',
                            onChanged: (values) => _update(
                              _draft.copyWith(
                                subcategorias: values,
                                clearSubcategoria: true,
                              ),
                            ),
                          ),
"""
filtros = replace_once(
    filtros,
    old_subcategory_select,
    new_subcategory_select,
    "selector múltiple de subcategorías",
)

filtros = replace_once(
    filtros,
    """                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, _draft),
""",
    """                      child: FilledButton.icon(
                        key: const Key('aplicar_filtros_avanzados'),
                        onPressed: () => Navigator.pop(context, _draft),
""",
    "clave del botón aplicar filtros",
)

multi_select_widget = r"""class _DialogMultiSelect extends StatelessWidget {
  const _DialogMultiSelect({
    required this.label,
    required this.selected,
    required this.options,
    required this.allLabel,
    required this.onChanged,
    super.key,
  });

  final String label;
  final Set<String> selected;
  final List<String> options;
  final String allLabel;
  final ValueChanged<Set<String>> onChanged;

  String get _summary {
    final values = selected.where(options.contains).toList()..sort();
    if (values.isEmpty) return allLabel;
    if (values.length == 1) return values.single;
    return '${values.length} subcategorías';
  }

  Future<void> _open(BuildContext context) async {
    var draft = selected.where(options.contains).toSet();
    final result = await showDialog<Set<String>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .42),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(label),
          content: SizedBox(
            width: 450,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: options.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No hay subcategorías disponibles para los filtros '
                        'seleccionados.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: options
                          .map(
                            (option) => CheckboxListTile(
                              key: ValueKey(
                                'subcategoria_opcion_$option',
                              ),
                              value: draft.contains(option),
                              activeColor: _filterYellow,
                              checkColor: Colors.black,
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              title: Text(option),
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    draft.add(option);
                                  } else {
                                    draft.remove(option);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
          actions: [
            TextButton(
              key: const Key('limpiar_subcategorias'),
              onPressed: draft.isEmpty
                  ? null
                  : () => setDialogState(draft.clear),
              child: const Text('Limpiar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('aplicar_subcategorias'),
              onPressed: () =>
                  Navigator.pop(dialogContext, Set<String>.of(draft)),
              style: FilledButton.styleFrom(
                backgroundColor: _filterYellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: options.isEmpty ? null : () => _open(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: selected.isEmpty,
        decoration: InputDecoration(
          labelText: label,
          enabled: options.isNotEmpty,
          filled: true,
          fillColor: _filterSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _filterBorder),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _filterBorder),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected.isEmpty ? _filterMuted : _filterInk,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: _filterMuted,
            ),
          ],
        ),
      ),
    ),
  );
}

"""
filtros = replace_once(
    filtros,
    "class _DialogSelect extends StatelessWidget {\n",
    multi_select_widget + "class _DialogSelect extends StatelessWidget {\n",
    "componente de selección múltiple",
)

# Nuevo pedido comparte el mismo filtro, pero necesita guardar el conjunto.
pedidos_state = replace_once(
    pedidos_state,
    """    this.subcategoria,
    this.estado,
""",
    """    this.subcategoria,
    this.subcategoriasSeleccionadas = const {},
    this.estado,
""",
    "parámetro de subcategorías en PedidosState",
)
pedidos_state = replace_once(
    pedidos_state,
    """  final String? subcategoria;
  final String? estado;
""",
    """  final String? subcategoria;
  final Set<String> subcategoriasSeleccionadas;
  final String? estado;
""",
    "campo de subcategorías en PedidosState",
)
pedidos_state = replace_once(
    pedidos_state,
    """  final String? error;

  List<ProductoResumen> get productosFiltrados {
""",
    """  final String? error;

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
""",
    "getter de subcategorías activas del pedido",
)
pedidos_state = replace_once(
    pedidos_state,
    """          (subcategoria == null || producto.subcategoria == subcategoria) &&
""",
    """          (subcategoriasActivas.isEmpty ||
              subcategoriasActivas.contains(producto.subcategoria)) &&
""",
    "filtrado múltiple en Nuevo pedido",
)
pedidos_state = replace_once(
    pedidos_state,
    """  int get filtrosAvanzadosActivos => [
    empresa,
    marca,
    categoria,
    subcategoria,
    estado,
    imagen,
  ].whereType<String>().length;
  CatalogoFiltros get catalogoFiltros => CatalogoFiltros(
    empresa: empresa,
    marca: marca,
    categoria: categoria,
    subcategoria: subcategoria,
    estado: estado,
    precio: filtroPrecio == 'Todos' ? null : filtroPrecio,
    imagen: imagen,
    orden: orden,
  );
""",
    """  int get filtrosAvanzadosActivos =>
      [
        empresa,
        marca,
        categoria,
        estado,
        imagen,
      ].whereType<String>().length +
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
""",
    "resumen de filtros múltiples del pedido",
)
pedidos_state = replace_once(
    pedidos_state,
    """    String? subcategoria,
    String? estado,
""",
    """    String? subcategoria,
    Set<String>? subcategoriasSeleccionadas,
    String? estado,
""",
    "copyWith de subcategorías del pedido",
)
pedidos_state = replace_once(
    pedidos_state,
    """    subcategoria: limpiarFiltros ? null : subcategoria ?? this.subcategoria,
    estado: limpiarFiltros ? null : estado ?? this.estado,
""",
    """    subcategoria: limpiarFiltros || subcategoriasSeleccionadas != null
        ? null
        : subcategoria ?? this.subcategoria,
    subcategoriasSeleccionadas: limpiarFiltros
        ? const {}
        : subcategoria != null
        ? const {}
        : subcategoriasSeleccionadas ?? this.subcategoriasSeleccionadas,
    estado: limpiarFiltros ? null : estado ?? this.estado,
""",
    "persistencia de subcategorías del pedido",
)
pedidos_state = replace_once(
    pedidos_state,
    """    categoria,
    subcategoria,
    estado,
""",
    """    categoria,
    subcategoria,
    subcategoriasSeleccionadas,
    estado,
""",
    "props de subcategorías del pedido",
)

pedidos_bloc = replace_once(
    pedidos_bloc,
    """              subcategoria: filtros.subcategoria,
              estado: filtros.estado,
""",
    """              subcategoriasSeleccionadas: filtros.subcategoriasActivas,
              estado: filtros.estado,
""",
    "aplicación del filtro múltiple en Nuevo pedido",
)

# ---------------------------------------------------------------------------
# 2. Botón de precios por encima de la navegación del sistema.
# ---------------------------------------------------------------------------
safe_footer = r"""  Widget _buildFooter() {
    return SafeArea(
      key: const Key('precios_footer_safe_area'),
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final back = OutlinedButton(
              onPressed: widget.onBack,
              style: _outlinedStyle(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Anterior'),
              ),
            );
            const progress = Text(
              'Paso 5 de 7',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12),
            );
            final next = FilledButton(
              onPressed: _continueToImages,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Siguiente: imágenes',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            );

            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  next,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: back),
                      const Expanded(child: progress),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                back,
                const Expanded(child: progress),
                next,
              ],
            );
          },
        ),
      ),
    );
  }"""
precios = replace_between(
    precios,
    "  Widget _buildFooter() {\n",
    "  Widget _buildEmptyFilteredState() {\n",
    safe_footer,
    "pie seguro del paso de precios",
)

# ---------------------------------------------------------------------------
# 3. Normalización de símbolos técnicos no soportados por la fuente PDF.
# ---------------------------------------------------------------------------
normalizer = r"""String normalizarTextoCotizacionPdf(String value) {
  var normalized = value;
  const replacements = <String, String>{
    '\u00A0': ' ',
    '″': ' in',
    '′': "'",
    '×': ' x ',
    '·': ' - ',
    '–': '-',
    '—': '-',
    '…': '...',
    '“': '"',
    '”': '"',
    '‘': "'",
    '’': "'",
    '⌀': 'Diam. ',
    'Ø': 'Diam. ',
    'ø': 'diam. ',
    '²': '2',
    '³': '3',
    'µ': 'u',
    '®': '(R)',
    '™': '(TM)',
  };
  replacements.forEach((source, target) {
    normalized = normalized.replaceAll(source, target);
  });
  normalized = normalized
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' ?\n ?'), '\n');
  return normalized.trim();
}

"""
pdf_service = replace_once(
    pdf_service,
    """import '../../domain/entities/pedido_detalle.dart';

class CotizacionPdfProducto {
""",
    """import '../../domain/entities/pedido_detalle.dart';

""" + normalizer + """class CotizacionPdfProducto {
""",
    "normalizador de texto del PDF",
)
pdf_service = replace_once(
    pdf_service,
    """    return variante.isEmpty ? producto.codigo.trim() : variante;
""",
    """    return normalizarTextoCotizacionPdf(
      variante.isEmpty ? producto.codigo.trim() : variante,
    );
""",
    "normalización del código del PDF",
)
pdf_service = replace_once(
    pdf_service,
    """    return partes.join(' · ');
""",
    """    return normalizarTextoCotizacionPdf(partes.join(' · '));
""",
    "normalización de la descripción del PDF",
)
pdf_service = replace_once(
    pdf_service,
    """        child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
""",
    """        child: pw.Text(
          normalizarTextoCotizacionPdf(value),
          style: const pw.TextStyle(fontSize: 8),
        ),
""",
    "normalización de datos de cotización",
)
pdf_service = replace_once(
    pdf_service,
    """        pw.TextSpan(text: value.isEmpty ? 'No especificado' : value),
""",
    """        pw.TextSpan(
          text: normalizarTextoCotizacionPdf(
            value.isEmpty ? 'No especificado' : value,
          ),
        ),
""",
    "normalización de datos del cliente",
)
pdf_service = replace_once(
    pdf_service,
    """        child: pw.Text(
          value,
          textAlign: align,
          style: const pw.TextStyle(fontSize: 7),
        ),
""",
    """        child: pw.Text(
          normalizarTextoCotizacionPdf(value),
          textAlign: align,
          style: const pw.TextStyle(fontSize: 7),
        ),
""",
    "normalización de celdas del PDF",
)
pdf_service = replace_once(
    pdf_service,
    """        pw.Text(
          item.producto.nombre,
          style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold),
        ),
""",
    """        pw.Text(
          normalizarTextoCotizacionPdf(item.producto.nombre),
          style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold),
        ),
""",
    "normalización del nombre del producto",
)
pdf_service = replace_once(
    pdf_service,
    """          pw.Text(
            item.descripcion,
            style: const pw.TextStyle(fontSize: 6.7, color: _dark),
          ),
""",
    """          pw.Text(
            normalizarTextoCotizacionPdf(item.descripcion),
            style: const pw.TextStyle(fontSize: 6.7, color: _dark),
          ),
""",
    "normalización del detalle del producto",
)
pdf_service = replace_once(
    pdf_service,
    """        pw.Text(producto.presentacion, style: const pw.TextStyle(fontSize: 7)),
""",
    """        pw.Text(
          normalizarTextoCotizacionPdf(producto.presentacion),
          style: const pw.TextStyle(fontSize: 7),
        ),
""",
    "normalización de la presentación",
)
pdf_service = replace_once(
    pdf_service,
    """          pw.Text(
            producto.equivalencia.trim(),
            style: const pw.TextStyle(fontSize: 6.4, color: _muted),
          ),
""",
    """          pw.Text(
            normalizarTextoCotizacionPdf(producto.equivalencia),
            style: const pw.TextStyle(fontSize: 6.4, color: _muted),
          ),
""",
    "normalización de equivalencia",
)
pdf_service = replace_once(
    pdf_service,
    """    final observacion = observaciones.trim().isEmpty
        ? 'Los precios unitarios y subtotales se muestran sin IGV. '
              'Stock, disponibilidad y fecha de entrega están sujetos a '
              'confirmación al momento de registrar el pedido.'
        : observaciones.trim();
""",
    """    final observacion = normalizarTextoCotizacionPdf(
      observaciones.trim().isEmpty
          ? 'Los precios unitarios y subtotales se muestran sin IGV. '
                'Stock, disponibilidad y fecha de entrega están sujetos a '
                'confirmación al momento de registrar el pedido.'
          : observaciones,
    );
""",
    "normalización de observaciones",
)

# ---------------------------------------------------------------------------
# 4. Pruebas dirigidas.
# ---------------------------------------------------------------------------
multi_catalog_test = """    bloc.add(
      const CatalogoFiltrosAplicados(
        CatalogoFiltros(
          subcategorias: {'Pernos hexagonales', 'Taladros'},
        ),
      ),
    );
    await bloc.stream.firstWhere(
      (state) => state.filtros.subcategoriasActivas.length == 2,
    );
    expect(bloc.state.productosFiltrados, hasLength(2));

"""
catalogo_test = replace_once(
    catalogo_test,
    """    bloc.add(
      const CatalogoFiltrosAplicados(
        CatalogoFiltros(
          categoria: 'Pernería',
""",
    multi_catalog_test + """    bloc.add(
      const CatalogoFiltrosAplicados(
        CatalogoFiltros(
          categoria: 'Pernería',
""",
    "prueba múltiple del catálogo",
)

pdf_test = replace_once(
    pdf_test,
    """void main() {
  test('genera una cotización PDF válida', () async {
""",
    """void main() {
  test('normaliza símbolos técnicos incompatibles con la fuente PDF', () {
    expect(
      normalizarTextoCotizacionPdf(
        'Perno 1/4″ × 1″ · Diámetro: 1/4″ — acero',
      ),
      'Perno 1/4 in x 1 in - Diámetro: 1/4 in - acero',
    );
  });

  test('genera una cotización PDF válida', () async {
""",
    "prueba de normalización del PDF",
)
pdf_test = replace_once(
    pdf_test,
    """      varianteNombre: 'Perno hexagonal 1/4 x 4',
      atributosVariante: {'Diámetro': '1/4 in', 'Largo': '4 in'},
""",
    """      varianteNombre: 'Perno hexagonal 1/4″ × 4″',
      atributosVariante: {'Diámetro': '1/4″', 'Largo': '4″'},
""",
    "datos técnicos de la prueba PDF",
)

multi_filter_test = r"""import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo_state.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/filtros_catalogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('permite aplicar varias subcategorías desde Más filtros', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    CatalogoFiltros? applied;
    const products = [
      ProductoResumen(
        id: '1',
        codigo: 'PER-001',
        nombre: 'Perno hexagonal',
        empresa: 'DINAFAST',
        marca: 'DINA',
        categoria: 'Pernería',
        subcategoria: 'Pernos hexagonales',
        unidadVenta: 'Ciento',
        precio: 20,
        sinPrecio: false,
        activo: true,
        tipoRegistro: 'matriz',
        atributosClave: [],
      ),
      ProductoResumen(
        id: '2',
        codigo: 'TAL-001',
        nombre: 'Taladro',
        empresa: 'DINAFAST',
        marca: 'DINA',
        categoria: 'Herramientas',
        subcategoria: 'Taladros',
        unidadVenta: 'Unidad',
        precio: 150,
        sinPrecio: false,
        activo: true,
        tipoRegistro: 'unico',
        atributosClave: [],
      ),
    ];
    final state = CatalogoState(
      loading: false,
      actualizando: false,
      busqueda: '',
      filtrosRapidos: const {'Todos'},
      filtros: const CatalogoFiltros(),
      vistaGrilla: true,
      productos: products,
      productosFiltrados: products,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FiltrosCatalogo(
            state: state,
            onBusquedaCambiada: (_) {},
            onFiltroRapido: (_) {},
            onFiltrosAplicados: (value) => applied = value,
            onFiltrosLimpiados: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('abrir_filtros_avanzados')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('dialog_subcategorias_multiple')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey('subcategoria_opcion_Pernos hexagonales'),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('subcategoria_opcion_Taladros')),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('aplicar_subcategorias')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('aplicar_filtros_avanzados')));
    await tester.pumpAndSettle();

    expect(
      applied?.subcategoriasActivas,
      {'Pernos hexagonales', 'Taladros'},
    );
    expect(tester.takeException(), isNull);
  });
}
"""

order_filter_test = r"""import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/pedidos/presentation/bloc/pedidos_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Nuevo pedido filtra por una o varias subcategorías', () {
    const products = [
      ProductoResumen(
        id: '1',
        codigo: 'PER-001',
        nombre: 'Perno hexagonal',
        empresa: 'DINAFAST',
        marca: 'DINA',
        categoria: 'Pernería',
        subcategoria: 'Pernos hexagonales',
        unidadVenta: 'Ciento',
        precio: 20,
        sinPrecio: false,
        activo: true,
        tipoRegistro: 'matriz',
        atributosClave: [],
      ),
      ProductoResumen(
        id: '2',
        codigo: 'TAL-001',
        nombre: 'Taladro',
        empresa: 'DINAFAST',
        marca: 'DINA',
        categoria: 'Herramientas',
        subcategoria: 'Taladros',
        unidadVenta: 'Unidad',
        precio: 150,
        sinPrecio: false,
        activo: true,
        tipoRegistro: 'unico',
        atributosClave: [],
      ),
    ];

    final multiple = PedidosState.initial().copyWith(
      loading: false,
      productos: products,
      subcategoriasSeleccionadas: const {
        'Pernos hexagonales',
        'Taladros',
      },
    );
    expect(multiple.productosFiltrados, hasLength(2));

    final single = multiple.copyWith(
      subcategoriasSeleccionadas: const {'Taladros'},
    );
    expect(single.productosFiltrados.single.codigo, 'TAL-001');
  });
}
"""

safe_area_test = r"""import 'package:app_catalogo/features/catalogo/presentation/widgets/paso5_precios_corregido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el botón para ir a imágenes queda dentro de SafeArea', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Step5PricingPanel(
            familyName: 'Pernos',
            totalVariantCount: 1,
            sellableCombinations: const [
              SellablePriceCombination(
                variantId: 'variant-1',
                variantLabel: 'Perno 1/4',
                presentationId: 'presentation-1',
                presentationLabel: 'Caja',
                baseUnit: 'UND',
                equivalentToBaseUnit: 100,
              ),
            ],
            onBack: () {},
            onNext: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('precios_footer_safe_area')),
      findsOneWidget,
    );
    expect(find.text('Siguiente: imágenes'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Siguiente: imágenes'),
        matching: find.byType(SafeArea),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
"""

updates = {
    CATALOGO_STATE: catalogo_state,
    CATALOGO_BLOC: catalogo_bloc,
    FILTROS: filtros,
    PEDIDOS_STATE: pedidos_state,
    PEDIDOS_BLOC: pedidos_bloc,
    PRECIOS: precios,
    PDF_SERVICE: pdf_service,
    CATALOGO_TEST: catalogo_test,
    PDF_TEST: pdf_test,
}
new_files = {
    MULTI_FILTER_TEST: multi_filter_test,
    ORDER_FILTER_TEST: order_filter_test,
    SAFE_AREA_TEST: safe_area_test,
}

# ---------------------------------------------------------------------------
# Validación final antes de escribir.
# ---------------------------------------------------------------------------
required_results = {
    CATALOGO_STATE: [
        "final Set<String> subcategorias;",
        "Set<String> get subcategoriasActivas",
    ],
    CATALOGO_BLOC: [
        "final subcategorias = f.subcategoriasActivas;",
        "subcategorias.contains(p.subcategoria)",
    ],
    FILTROS: [
        "class _DialogMultiSelect extends StatelessWidget",
        "dialog_subcategorias_multiple",
        "subcategoria_opcion_$option",
        "aplicar_filtros_avanzados",
    ],
    PEDIDOS_STATE: [
        "final Set<String> subcategoriasSeleccionadas;",
        "Set<String> get subcategoriasActivas",
        "subcategoriasActivas.contains(producto.subcategoria)",
    ],
    PEDIDOS_BLOC: [
        "subcategoriasSeleccionadas: filtros.subcategoriasActivas",
    ],
    PRECIOS: [
        "key: const Key('precios_footer_safe_area')",
        "minimum: const EdgeInsets.only(bottom: 8)",
    ],
    PDF_SERVICE: [
        "String normalizarTextoCotizacionPdf(String value)",
        "'″': ' in'",
        "normalizarTextoCotizacionPdf(item.producto.nombre)",
    ],
    CATALOGO_TEST: [
        "subcategorias: {'Pernos hexagonales', 'Taladros'}",
    ],
    PDF_TEST: [
        "normaliza símbolos técnicos incompatibles",
        "Perno hexagonal 1/4″ × 4″",
    ],
}

for path, markers in required_results.items():
    content = updates[path]
    for marker in markers:
        if marker not in content:
            fail(
                f"El resultado de {path.relative_to(ROOT)} "
                f"no contiene el marcador esperado: {marker}"
            )

for path, content in new_files.items():
    if not content.strip():
        fail(f"El archivo nuevo {path.relative_to(ROOT)} quedó vacío.")

for forbidden in (
    "(f.subcategoria == null || p.subcategoria == f.subcategoria)",
    "(subcategoria == null || producto.subcategoria == subcategoria)",
):
    if forbidden in "\n".join(updates.values()):
        fail(f"Permanece el filtro antiguo: {forbidden}")

backup_dir = ROOT / (
    ".backup_filtros_safearea_pdf_v1_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    target = backup_dir / path.relative_to(ROOT)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

for path, content in new_files.items():
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Creado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nAplicado:")
print("- Subcategorías múltiples funcionales en Catálogo y Nuevo pedido.")
print("- Botón Siguiente: imágenes protegido por SafeArea.")
print("- Símbolos técnicos del PDF convertidos a texto compatible.")
print("No se modificó SQLite ni app_catalogo.db.")
print("\nEjecuta:")
print("  dart format lib test")
print("  flutter test test/catalogo_bloc_test.dart")
print("  flutter test test/filtros_catalogo_test.dart")
print("  flutter test test/filtros_subcategorias_multiple_test.dart")
print("  flutter test test/pedidos_subcategorias_filtro_test.dart")
print("  flutter test test/precios_footer_safe_area_test.dart")
print("  flutter test test/cotizacion_pdf_service_test.dart")
print("  flutter test test/pedidos_bloc_test.dart")
print("  flutter analyze")
