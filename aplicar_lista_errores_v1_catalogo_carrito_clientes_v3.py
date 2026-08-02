from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()

FILTERS = ROOT / "lib/features/catalogo/presentation/widgets/filtros_catalogo.dart"
PRODUCT_CARD = ROOT / "lib/features/catalogo/presentation/widgets/producto_card.dart"
CATALOG_PAGE = ROOT / "lib/features/catalogo/presentation/pages/catalogo_page.dart"
NEW_ORDER_PAGE = ROOT / "lib/features/pedidos/presentation/pages/nuevo_pedido_page.dart"
PRODUCT_DETAIL = ROOT / "lib/features/catalogo/presentation/widgets/producto_detalle_dialog.dart"
CONFIRM_ORDER = ROOT / "lib/features/pedidos/presentation/widgets/confirmar_pedido_dialog.dart"
CLIENT_FORM = ROOT / "lib/features/clientes/presentation/widgets/cliente_formulario.dart"
CLIENT_DETAIL = ROOT / "lib/features/clientes/presentation/widgets/cliente_detalle_dialog.dart"

FILTERS_TEST = ROOT / "test/filtros_catalogo_test.dart"
PRODUCT_DETAIL_TEST = ROOT / "test/producto_detalle_dialog_test.dart"
CLIENTS_TEST = ROOT / "test/clientes_page_test.dart"
PRODUCT_CARD_TEST = ROOT / "test/producto_card_layout_test.dart"


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
    start_count = source.count(start_marker)
    end_count = source.count(end_marker)
    if start_count != 1 or end_count != 1:
        fail(
            f"No se pudo delimitar “{label}”. "
            f"Inicio: {start_count}; fin: {end_count}."
        )
    start = source.index(start_marker)
    end = source.index(end_marker, start)
    return source[:start] + replacement.rstrip() + "\n\n" + source[end:]


required_paths = [
    FILTERS,
    PRODUCT_CARD,
    CATALOG_PAGE,
    NEW_ORDER_PAGE,
    PRODUCT_DETAIL,
    CONFIRM_ORDER,
    CLIENT_FORM,
    CLIENT_DETAIL,
    FILTERS_TEST,
    PRODUCT_DETAIL_TEST,
    CLIENTS_TEST,
]
for path in required_paths:
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

if PRODUCT_CARD_TEST.exists():
    fail(f"Ya existe {PRODUCT_CARD_TEST.relative_to(ROOT)}")

sources = {
    path: path.read_text(encoding="utf-8")
    for path in required_paths
}

# Validar primero el estado exacto esperado.
expected_markers = {
    FILTERS: [
        "class _ClassificationSelect extends StatelessWidget",
        "key: const Key('catalogo_filtro_categoria')",
        "key: const Key('catalogo_filtro_subcategoria')",
        "key: const Key('abrir_filtros_avanzados')",
    ],
    PRODUCT_CARD: [
        "_imagen(height: compacto ? 158 : 228)",
        "if (expandido) const Spacer() else const SizedBox(height: 16)",
        "fit: BoxFit.cover",
    ],
    CATALOG_PAGE: [
        "mainAxisExtent: constraints.maxWidth < 500 ? 560 : 580",
    ],
    NEW_ORDER_PAGE: [
        "mainAxisExtent: constraints.maxWidth < 500 ? 560 : 580",
        "builder: (dialogContext) => AlertDialog(",
        "title: const Text('Pedido registrado correctamente')",
    ],
    PRODUCT_DETAIL: [
        "SizedBox(width: 330, height: 285, child: gallery)",
        "SizedBox(height: 280, child: gallery)",
    ],
    CONFIRM_ORDER: [
        "final width = (constraints.maxWidth * .85).clamp(320.0, 980.0);",
        "final height = constraints.maxHeight * .9;",
        "Widget _header(BuildContext context) => Container(",
    ],
    CLIENT_FORM: [
        "height: 150,",
        "child: _buildFotoPreview(),",
    ],
    CLIENT_DETAIL: [
        "height: 200,",
        "child: _fotoUbicacion(cliente.fotoUbicacionPath),",
    ],
    FILTERS_TEST: [
        "muestra categoría y subcategoría como clasificación principal",
        "catalogo_filtro_categoria",
    ],
    PRODUCT_DETAIL_TEST: [
        "la ficha de matriz muestra combinaciones y precios exactos",
        "await tester.pumpAndSettle();",
    ],
    CLIENTS_TEST: [
        "lista clientes y filtra sin desbordar en pantalla angosta",
        "class _ClientesRepositoryFake implements ClientesRepository",
    ],
}
for path, markers in expected_markers.items():
    content = sources[path]
    for marker in markers:
        if marker not in content:
            fail(
                f"{path.relative_to(ROOT)} no contiene el marcador esperado: "
                f"{marker}"
            )

filters = sources[FILTERS]
card = sources[PRODUCT_CARD]
catalog_page = sources[CATALOG_PAGE]
new_order = sources[NEW_ORDER_PAGE]
product_detail = sources[PRODUCT_DETAIL]
confirm_order = sources[CONFIRM_ORDER]
client_form = sources[CLIENT_FORM]
client_detail = sources[CLIENT_DETAIL]
filters_test = sources[FILTERS_TEST]
product_detail_test = sources[PRODUCT_DETAIL_TEST]
clients_test = sources[CLIENTS_TEST]

# 1. Filtros: categoría y subcategoría quedan únicamente en Más filtros.
filters = replace_between(
    filters,
    "  @override\n"
    "  void dispose() {\n"
    "    _busqueda.dispose();\n"
    "    super.dispose();\n"
    "  }\n\n"
    "  List<String> _unique(Iterable<String> values) {",
    "    final quickFilters = widget.modoPedido",
    "  @override\n"
    "  void dispose() {\n"
    "    _busqueda.dispose();\n"
    "    super.dispose();\n"
    "  }\n\n"
    "  @override\n"
    "  Widget build(BuildContext context) {",
    "helpers de clasificación principal",
)

filters = replace_between(
    filters,
    "            const SizedBox(height: 12),\n"
    "            LayoutBuilder(\n"
    "              builder: (context, constraints) {\n"
    "                final narrow = constraints.maxWidth < 690;",
    "            LayoutBuilder(\n"
    "              builder: (context, constraints) {\n"
    "                final actions = Wrap(",
    "            const SizedBox(height: 10),",
    "clasificación redundante bajo el buscador",
)

filters = replace_between(
    filters,
    "class _ClassificationSelect extends StatelessWidget {",
    "class _ActiveFilters extends StatelessWidget {",
    "",
    "widget de clasificación principal",
)

# Comprobaciones estructurales antes de continuar con otros archivos.
for obsolete_marker in [
    "key: const Key('catalogo_filtro_categoria')",
    "key: const Key('catalogo_filtro_subcategoria')",
    "class _ClassificationSelect extends StatelessWidget",
    "final categories = _categories(widget.state.filtros);",
    "final subcategories = _subcategories(widget.state.filtros);",
]:
    if obsolete_marker in filters:
        fail(
            "La clasificación redundante no se retiró por completo: "
            f"{obsolete_marker}"
        )

for required_marker in [
    "key: const Key('abrir_filtros_avanzados')",
    "class _FiltrosAvanzadosDialog extends StatefulWidget",
    "label: 'Categoría'",
    "label: 'Subcategoría'",
]:
    if required_marker not in filters:
        fail(
            "La corrección dañaría el modal Más filtros; falta: "
            f"{required_marker}"
        )

# 2. Tarjetas de producto: menor altura, imagen sin recorte y chips controlados.
card = replace_once(
    card,
    "      final compacto = constraints.maxHeight < 500;\n",
    "      final compacto = constraints.maxHeight < 450;\n",
    "umbral compacto de la tarjeta",
)
card = replace_once(
    card,
    "          _imagen(height: compacto ? 158 : 228),\n",
    "          _imagen(height: compacto ? 142 : 176),\n",
    "altura de imagen en grilla",
)
card = replace_once(
    card,
    "          children: [_imagen(height: 204), contenido],\n",
    "          children: [_imagen(height: 172), contenido],\n",
    "altura de imagen en lista angosta",
)
card = replace_once(
    card,
    "            SizedBox(width: 264, child: _imagen(height: 264)),\n",
    "            SizedBox(width: 220, child: _imagen(height: 220)),\n",
    "tamaño de imagen en lista amplia",
)
card = replace_once(
    card,
    "      fit: BoxFit.cover,\n",
    "      fit: BoxFit.contain,\n",
    "evitar recorte de imagen de tarjeta",
)
card = replace_once(
    card,
    "        if (expandido) const Spacer() else const SizedBox(height: 16),\n",
    "        SizedBox(height: expandido ? 12 : 14),\n",
    "eliminar espacio flexible excesivo",
)

old_tags = """  Widget _etiquetasAdministrativas(bool compacto) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: [
      _chipTipo(),
      ..._presentaciones
          .take(compacto ? 2 : 3)
          .map((presentacion) => _chipPresentacion(presentacion)),
    ],
  );
"""
new_tags = """  Widget _etiquetasAdministrativas(bool compacto) {
    final presentations = _presentaciones
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final limit = compacto ? 2 : 3;
    final hidden = presentations.length - limit;

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _chipTipo(),
        ...presentations
            .take(limit)
            .map((presentacion) => _chipPresentacion(presentacion)),
        if (hidden > 0) _chipMasPresentaciones(hidden),
      ],
    );
  }

  Widget _chipMasPresentaciones(int cantidad) => Container(
    key: Key('producto_presentaciones_restantes_${producto.id}'),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F4F7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFD0D5DD)),
    ),
    child: Text(
      '+$cantidad más',
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF475467),
      ),
    ),
  );
"""
card = replace_once(
    card,
    old_tags,
    new_tags,
    "resumen de presentaciones en chips",
)

for path_name, content in (
    ("Catálogo", catalog_page),
    ("Nuevo pedido", new_order),
):
    updated = replace_once(
        content,
        "mainAxisExtent: constraints.maxWidth < 500 ? 560 : 580",
        "mainAxisExtent: constraints.maxWidth < 500 ? 500 : 480",
        f"altura de tarjetas en {path_name}",
    )
    if path_name == "Catálogo":
        catalog_page = updated
    else:
        new_order = updated

# 3. Galería del detalle del producto: 30 % más alta.
product_detail = replace_once(
    product_detail,
    "            SizedBox(width: 330, height: 285, child: gallery),\n",
    "            SizedBox(\n"
    "              key: const Key('producto_detalle_galeria'),\n"
    "              width: 350,\n"
    "              height: 371,\n"
    "              child: gallery,\n"
    "            ),\n",
    "galería amplia de escritorio",
)
product_detail = replace_once(
    product_detail,
    "          SizedBox(height: 280, child: gallery),\n",
    "          SizedBox(\n"
    "            key: const Key('producto_detalle_galeria'),\n"
    "            height: 364,\n"
    "            child: gallery,\n"
    "          ),\n",
    "galería amplia en pantalla angosta",
)

# 4. Carrito: modal más ancho y encabezado/flujo visual más claro.
confirm_order = replace_once(
    confirm_order,
    "          final width = (constraints.maxWidth * .85).clamp(320.0, 980.0);\n"
    "          final height = constraints.maxHeight * .9;\n",
    "          final width = constraints.maxWidth > 1180\n"
    "              ? 1180.0\n"
    "              : constraints.maxWidth * .96;\n"
    "          final height = constraints.maxHeight > 920\n"
    "              ? 920.0\n"
    "              : constraints.maxHeight * .94;\n",
    "dimensiones del modal del carrito",
)
confirm_order = replace_once(
    confirm_order,
    "          return Container(\n"
    "            width: width,\n"
    "            height: height,\n",
    "          return Container(\n"
    "            key: const Key('confirmar_pedido_dialog_surface'),\n"
    "            width: width,\n"
    "            height: height,\n",
    "clave de superficie del carrito",
)

new_header = """  Widget _header(BuildContext context) => Container(
    color: darkColor,
    padding: const EdgeInsets.fromLTRB(20, 15, 12, 15),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _paso == 0
                ? Icons.shopping_cart_checkout_rounded
                : _paso == 1
                ? Icons.person_outline_rounded
                : Icons.fact_check_outlined,
            color: darkColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirmar pedido',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _pasoDescripcion,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFFB7BAC1),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ],
    ),
  );

  String get _pasoDescripcion => switch (_paso) {
    0 => 'Revisa variantes, presentaciones, cantidades y precios.',
    1 => 'Selecciona un cliente o registra sus datos de entrega.',
    _ => 'Comprueba toda la información antes de guardar.',
  };
"""
confirm_order = replace_between(
    confirm_order,
    "  Widget _header(BuildContext context) => Container(",
    "  Widget _stepper() => Padding(",
    new_header,
    "encabezado del modal del carrito",
)

old_step_chip_start = "  Widget _buildStepChip(String label, int stepIndex) {"
old_step_chip_end = "  Widget _error(String value) => Container("
new_step_chip = """  Widget _buildStepChip(String label, int stepIndex) {
    final isActive = _paso == stepIndex;
    final isCompleted = stepIndex < _paso;
    final color = isActive
        ? primaryColor
        : isCompleted
        ? const Color(0xFFD1FADF)
        : const Color(0xFFF2F4F7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? primaryColor
              : isCompleted
              ? const Color(0xFF6CE9A6)
              : const Color(0xFFE1E5EA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? darkColor : Colors.white,
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Color(0xFF067647),
                  )
                : Text(
                    '${stepIndex + 1}',
                    style: GoogleFonts.inter(
                      color: isActive ? Colors.white : darkColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              fontSize: 12,
              color: darkColor,
            ),
          ),
        ],
      ),
    );
  }
"""
confirm_order = replace_between(
    confirm_order,
    old_step_chip_start,
    old_step_chip_end,
    new_step_chip,
    "indicador de pasos del carrito",
)

new_success = """  Future<void> _mostrarResultado(
    BuildContext context,
    PedidoRegistrado resultado,
  ) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 590),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                color: const Color(0xFFECFDF3),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xFF12B76A),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Pedido registrado',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: darkColor,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Quedó guardado localmente en la hoja activa.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475467),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    _resultadoRow('Código', resultado.codigo),
                    _resultadoRow('Cliente', resultado.cliente),
                    _resultadoRow('Hoja de pedido', resultado.hojaCodigo),
                    _resultadoRow('Estado inicial', resultado.estado),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cerrar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              context.read<PedidosBloc>().add(
                                const PedidoNuevoSolicitado(),
                              );
                              Navigator.pop(dialogContext);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(0, 46),
                            ),
                            icon: const Icon(Icons.add_shopping_cart_rounded),
                            label: const Text('Nuevo pedido'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _resultadoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF667085),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              color: darkColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
"""
new_order = replace_between(
    new_order,
    "  Future<void> _mostrarResultado(",
    "}\n\nclass _CarritoBar extends StatelessWidget {",
    new_success,
    "confirmación final del pedido",
)

# 5. Imágenes de clientes: 40 % más altas y sin recorte.
client_form = replace_once(
    client_form,
    "            child: Container(\n"
    "              height: 150,\n"
    "              width: double.infinity,\n",
    "            child: Container(\n"
    "              key: const Key('cliente_form_foto'),\n"
    "              height: 210,\n"
    "              width: double.infinity,\n",
    "altura de foto en formulario de cliente",
)
client_form = replace_once(
    client_form,
    "            fit: BoxFit.cover,\n",
    "            fit: BoxFit.contain,\n",
    "evitar recorte de foto en formulario",
)

client_detail = replace_once(
    client_detail,
    "              child: Container(\n"
    "                height: 200,\n"
    "                width: double.infinity,\n",
    "              child: Container(\n"
    "                key: const Key('cliente_detalle_foto'),\n"
    "                height: 280,\n"
    "                width: double.infinity,\n",
    "altura de foto en detalle de cliente",
)
client_detail = replace_once(
    client_detail,
    "        fit: BoxFit.cover,\n",
    "        fit: BoxFit.contain,\n",
    "evitar recorte de foto en detalle",
)

# Prueba de filtros actualizada al nuevo criterio.
filters_test = """import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo_state.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/filtros_catalogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'categoría y subcategoría se gestionan únicamente desde Más filtros',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = CatalogoState(
        loading: false,
        actualizando: false,
        busqueda: '',
        filtrosRapidos: const {'Todos'},
        filtros: const CatalogoFiltros(),
        vistaGrilla: true,
        productos: const [
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
        ],
        productosFiltrados: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FiltrosCatalogo(
              state: state,
              onBusquedaCambiada: (_) {},
              onFiltroRapido: (_) {},
              onFiltrosAplicados: (_) {},
              onFiltrosLimpiados: () {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('catalogo_filtro_categoria')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('catalogo_filtro_subcategoria')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const Key('abrir_filtros_avanzados')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Más filtros'), findsOneWidget);
      expect(find.text('Categoría'), findsWidgets);
      expect(find.text('Subcategoría'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('nuevo pedido usa filtros comerciales compactos', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = CatalogoState(
      loading: false,
      actualizando: false,
      busqueda: '',
      filtrosRapidos: const {'Todos'},
      filtros: const CatalogoFiltros(),
      vistaGrilla: true,
      productos: const [],
      productosFiltrados: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FiltrosCatalogo(
            state: state,
            modoPedido: true,
            onBusquedaCambiada: (_) {},
            onFiltroRapido: (_) {},
            onFiltrosAplicados: (_) {},
            onFiltrosLimpiados: () {},
          ),
        ),
      ),
    );

    expect(find.text('Con precio'), findsOneWidget);
    expect(find.text('Sin precio'), findsOneWidget);
    expect(find.text('Activos'), findsNothing);
    expect(find.text('Inactivos'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
"""

# Prueba de altura de la galería.
detail_anchor = (
    "    await tester.tap(find.text('Abrir'));\n"
    "    await tester.pumpAndSettle();\n"
)
detail_insert = (
    detail_anchor
    + "\n"
    + "    final gallerySize = tester.getSize(\n"
    + "      find.byKey(const Key('producto_detalle_galeria')),\n"
    + "    );\n"
    + "    expect(gallerySize.height, greaterThanOrEqualTo(364));\n"
)
product_detail_test = replace_once(
    product_detail_test,
    detail_anchor,
    detail_insert,
    "comprobación de altura de galería",
)

# Pruebas de imágenes de clientes.
clients_test = replace_once(
    clients_test,
    "import 'package:app_catalogo/features/clientes/presentation/pages/clientes_page.dart';\n",
    "import 'package:app_catalogo/features/clientes/presentation/pages/clientes_page.dart';\n"
    "import 'package:app_catalogo/features/clientes/presentation/widgets/cliente_detalle_dialog.dart';\n"
    "import 'package:app_catalogo/features/clientes/presentation/widgets/cliente_formulario.dart';\n",
    "imports de pruebas de imágenes de cliente",
)

client_tests = """  testWidgets('la foto del formulario tiene mayor altura', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClienteFormulario(),
          ),
        ),
      ),
    );

    final size = tester.getSize(
      find.byKey(const Key('cliente_form_foto')),
    );
    expect(size.height, 210);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la foto del detalle tiene mayor altura', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<ClientesRepository>.value(
        value: _ClientesRepositoryFake(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => ClienteDetalleDialog.show(
                  context,
                  clienteId: '1',
                ),
                child: const Text('Abrir detalle'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubicación'));
    await tester.pumpAndSettle();

    final size = tester.getSize(
      find.byKey(const Key('cliente_detalle_foto')),
    );
    expect(size.height, 280);
    expect(tester.takeException(), isNull);
  });

"""
clients_test = replace_once(
    clients_test,
    "}\n\nclass _ClientesRepositoryFake implements ClientesRepository {",
    client_tests
    + "}\n\nclass _ClientesRepositoryFake implements ClientesRepository {",
    "pruebas de altura de imágenes de cliente",
)

product_card_test = """import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/producto_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la tarjeta compacta resume presentaciones sin desbordar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const product = ProductoResumen(
      id: 'product-1',
      codigo: 'BRO-001',
      nombre: 'Broca HSS larga para metal',
      empresa: 'UYUSTOOLS',
      marca: 'UYUSTOOLS',
      categoria: 'Accesorios',
      subcategoria: 'Brocas',
      unidadVenta: 'Unidad',
      precio: 25,
      sinPrecio: false,
      activo: true,
      tipoRegistro: 'variantes',
      atributosClave: [],
      presentaciones: [
        'Unidad',
        'Blíster',
        'Paquete',
        'Caja',
        'Docena',
        'Ciento',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 480,
              child: ProductoCard(
                producto: product,
                isGrid: true,
                onVerDetalle: () {},
                onAgregar: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('+4 más'), findsOneWidget);
    expect(find.text('Agregar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
"""

updates = {
    FILTERS: filters,
    PRODUCT_CARD: card,
    CATALOG_PAGE: catalog_page,
    NEW_ORDER_PAGE: new_order,
    PRODUCT_DETAIL: product_detail,
    CONFIRM_ORDER: confirm_order,
    CLIENT_FORM: client_form,
    CLIENT_DETAIL: client_detail,
    FILTERS_TEST: filters_test,
    PRODUCT_DETAIL_TEST: product_detail_test,
    CLIENTS_TEST: clients_test,
    PRODUCT_CARD_TEST: product_card_test,
}

# Todo el contenido se construyó en memoria. Respaldar y escribir al final.
for path, content in updates.items():
    if not content.strip():
        fail(f"El resultado para {path.relative_to(ROOT)} está vacío.")

backup_dir = ROOT / (
    ".backup_lista_errores_v1_catalogo_carrito_clientes_v3_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    if path.exists():
        destination = backup_dir / path.relative_to(ROOT)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)

for path, content in updates.items():
    path.parent.mkdir(parents=True, exist_ok=True)
    existed = path.exists()
    path.write_text(content, encoding="utf-8", newline="\n")
    print(
        f"{'Modificado' if existed else 'Creado'}: "
        f"{path.relative_to(ROOT)}"
    )

print(f"\nRespaldo: {backup_dir}")
print("\nAplicadas las correcciones v3 de Catálogo, Nuevo pedido, carrito y clientes.")
print("No se modificó SQLite ni app_catalogo.db.")
print("\nEjecuta:")
print("  dart format lib test")
print("  flutter test test/filtros_catalogo_test.dart")
print("  flutter test test/producto_card_layout_test.dart")
print("  flutter test test/producto_detalle_dialog_test.dart")
print("  flutter test test/clientes_page_test.dart")
print("  flutter test test/agregar_producto_dialog_test.dart")
print("  flutter test test/pedidos_bloc_test.dart")
print("  flutter analyze")
