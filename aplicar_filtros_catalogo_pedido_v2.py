from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()

FILTERS = ROOT / "lib/features/catalogo/presentation/widgets/filtros_catalogo.dart"
CATALOG_STATE = ROOT / "lib/features/catalogo/presentation/bloc/catalogo_state.dart"
CATALOG_BLOC = ROOT / "lib/features/catalogo/presentation/bloc/catalogo_bloc.dart"
NEW_ORDER = ROOT / "lib/features/pedidos/presentation/pages/nuevo_pedido_page.dart"
ORDER_STATE = ROOT / "lib/features/pedidos/presentation/bloc/pedidos_state.dart"
ORDER_BLOC = ROOT / "lib/features/pedidos/presentation/bloc/pedidos_bloc.dart"
CATALOG_TEST = ROOT / "test/catalogo_bloc_test.dart"
FILTER_TEST = ROOT / "test/filtros_catalogo_test.dart"


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


for path in (
    FILTERS,
    CATALOG_STATE,
    CATALOG_BLOC,
    NEW_ORDER,
    ORDER_STATE,
    ORDER_BLOC,
    CATALOG_TEST,
):
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

filters = FILTERS.read_text(encoding="utf-8")
catalog_state = CATALOG_STATE.read_text(encoding="utf-8")
catalog_bloc = CATALOG_BLOC.read_text(encoding="utf-8")
new_order = NEW_ORDER.read_text(encoding="utf-8")
order_state = ORDER_STATE.read_text(encoding="utf-8")
order_bloc = ORDER_BLOC.read_text(encoding="utf-8")
catalog_test = CATALOG_TEST.read_text(encoding="utf-8")

if "this.subcategoria" in catalog_state:
    fail("Los filtros por subcategoría ya parecen estar aplicados.")
if "modoPedido: true" in new_order:
    fail("Nuevo pedido ya parece usar el modo de filtros comerciales.")

NEW_FILTERS_FILE = "import 'package:flutter/material.dart';\nimport 'package:google_fonts/google_fonts.dart';\n\nimport '../bloc/catalogo_state.dart';\n\nconst _filterYellow = Color(0xFFFFC500);\nconst _filterInk = Color(0xFF1F1F1F);\nconst _filterMuted = Color(0xFF667085);\nconst _filterBorder = Color(0xFFE1E5EA);\nconst _filterSurface = Color(0xFFF7F8FA);\n\nclass FiltrosCatalogo extends StatefulWidget {\n  const FiltrosCatalogo({\n    required this.state,\n    required this.onBusquedaCambiada,\n    required this.onFiltroRapido,\n    required this.onFiltrosAplicados,\n    required this.onFiltrosLimpiados,\n    this.modoPedido = false,\n    super.key,\n  });\n\n  final CatalogoState state;\n  final ValueChanged<String> onBusquedaCambiada;\n  final ValueChanged<String> onFiltroRapido;\n  final ValueChanged<CatalogoFiltros> onFiltrosAplicados;\n  final VoidCallback onFiltrosLimpiados;\n  final bool modoPedido;\n\n  @override\n  State<FiltrosCatalogo> createState() => _FiltrosCatalogoState();\n}\n\nclass _FiltrosCatalogoState extends State<FiltrosCatalogo> {\n  late final TextEditingController _busqueda;\n\n  @override\n  void initState() {\n    super.initState();\n    _busqueda = TextEditingController(text: widget.state.busqueda);\n  }\n\n  @override\n  void didUpdateWidget(covariant FiltrosCatalogo oldWidget) {\n    super.didUpdateWidget(oldWidget);\n    if (_busqueda.text != widget.state.busqueda) {\n      _busqueda.value = TextEditingValue(\n        text: widget.state.busqueda,\n        selection: TextSelection.collapsed(\n          offset: widget.state.busqueda.length,\n        ),\n      );\n    }\n  }\n\n  @override\n  void dispose() {\n    _busqueda.dispose();\n    super.dispose();\n  }\n\n  List<String> _unique(Iterable<String> values) {\n    final result = values\n        .map((value) => value.trim())\n        .where((value) => value.isNotEmpty)\n        .toSet()\n        .toList()\n      ..sort();\n    return result;\n  }\n\n  List<String> _categories(CatalogoFiltros filters) => _unique(\n    widget.state.productos\n        .where(\n          (item) =>\n              (filters.empresa == null ||\n                  item.empresa == filters.empresa) &&\n              (filters.marca == null || item.marca == filters.marca),\n        )\n        .map((item) => item.categoria),\n  );\n\n  List<String> _subcategories(CatalogoFiltros filters) => _unique(\n    widget.state.productos\n        .where(\n          (item) =>\n              (filters.empresa == null ||\n                  item.empresa == filters.empresa) &&\n              (filters.marca == null || item.marca == filters.marca) &&\n              (filters.categoria == null ||\n                  item.categoria == filters.categoria),\n        )\n        .map((item) => item.subcategoria),\n  );\n\n  void _changeCategory(String? value) {\n    var next = widget.state.filtros.copyWith(\n      categoria: value,\n      clearCategoria: value == null,\n    );\n    final available = _subcategories(next);\n    if (!available.contains(next.subcategoria)) {\n      next = next.copyWith(clearSubcategoria: true);\n    }\n    widget.onFiltrosAplicados(next);\n  }\n\n  void _changeSubcategory(String? value) {\n    widget.onFiltrosAplicados(\n      widget.state.filtros.copyWith(\n        subcategoria: value,\n        clearSubcategoria: value == null,\n      ),\n    );\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final categories = _categories(widget.state.filtros);\n    final subcategories = _subcategories(widget.state.filtros);\n    final quickFilters = widget.modoPedido\n        ? const ['Todos', 'Con precio', 'Sin precio']\n        : const ['Todos', 'Activos', 'Inactivos'];\n\n    return Material(\n      color: Colors.white,\n      child: Container(\n        width: double.infinity,\n        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),\n        decoration: const BoxDecoration(\n          color: Colors.white,\n          border: Border(bottom: BorderSide(color: _filterBorder)),\n        ),\n        child: Column(\n          crossAxisAlignment: CrossAxisAlignment.stretch,\n          children: [\n            TextField(\n              key: const Key('catalogo_busqueda'),\n              controller: _busqueda,\n              onChanged: widget.onBusquedaCambiada,\n              decoration: InputDecoration(\n                hintText: widget.modoPedido\n                    ? 'Buscar producto para agregar al pedido…'\n                    : 'Buscar por nombre, código, marca o característica…',\n                prefixIcon: const Icon(Icons.search_rounded),\n                suffixIcon: widget.state.busqueda.isEmpty\n                    ? null\n                    : IconButton(\n                        tooltip: 'Limpiar búsqueda',\n                        onPressed: () {\n                          _busqueda.clear();\n                          widget.onBusquedaCambiada('');\n                        },\n                        icon: const Icon(Icons.close_rounded),\n                      ),\n                filled: true,\n                fillColor: _filterSurface,\n                border: OutlineInputBorder(\n                  borderRadius: BorderRadius.circular(13),\n                  borderSide: const BorderSide(color: _filterBorder),\n                ),\n                enabledBorder: OutlineInputBorder(\n                  borderRadius: BorderRadius.circular(13),\n                  borderSide: const BorderSide(color: _filterBorder),\n                ),\n                focusedBorder: OutlineInputBorder(\n                  borderRadius: BorderRadius.circular(13),\n                  borderSide: const BorderSide(\n                    color: _filterYellow,\n                    width: 1.6,\n                  ),\n                ),\n              ),\n            ),\n            const SizedBox(height: 12),\n            LayoutBuilder(\n              builder: (context, constraints) {\n                final narrow = constraints.maxWidth < 690;\n                final fieldWidth = narrow\n                    ? constraints.maxWidth\n                    : (constraints.maxWidth - 12) / 2;\n                return Wrap(\n                  spacing: 12,\n                  runSpacing: 10,\n                  children: [\n                    SizedBox(\n                      width: fieldWidth,\n                      child: _ClassificationSelect(\n                        key: const Key('catalogo_filtro_categoria'),\n                        label: 'Categoría',\n                        icon: Icons.category_outlined,\n                        value: categories.contains(\n                          widget.state.filtros.categoria,\n                        )\n                            ? widget.state.filtros.categoria\n                            : null,\n                        options: categories,\n                        allLabel: 'Todas las categorías',\n                        onChanged: _changeCategory,\n                      ),\n                    ),\n                    SizedBox(\n                      width: fieldWidth,\n                      child: _ClassificationSelect(\n                        key: const Key('catalogo_filtro_subcategoria'),\n                        label: 'Subcategoría',\n                        icon: Icons.subdirectory_arrow_right_rounded,\n                        value: subcategories.contains(\n                          widget.state.filtros.subcategoria,\n                        )\n                            ? widget.state.filtros.subcategoria\n                            : null,\n                        options: subcategories,\n                        allLabel: widget.state.filtros.categoria == null\n                            ? 'Todas las subcategorías'\n                            : 'Todas en ${widget.state.filtros.categoria}',\n                        onChanged: _changeSubcategory,\n                      ),\n                    ),\n                  ],\n                );\n              },\n            ),\n            const SizedBox(height: 10),\n            LayoutBuilder(\n              builder: (context, constraints) {\n                final actions = Wrap(\n                  spacing: 8,\n                  runSpacing: 8,\n                  children: [\n                    OutlinedButton.icon(\n                      key: const Key('abrir_filtros_avanzados'),\n                      onPressed: _abrirFiltros,\n                      style: OutlinedButton.styleFrom(\n                        foregroundColor: _filterInk,\n                        side: const BorderSide(color: _filterYellow),\n                        shape: RoundedRectangleBorder(\n                          borderRadius: BorderRadius.circular(11),\n                        ),\n                      ),\n                      icon: Badge(\n                        isLabelVisible:\n                            widget.state.filtros.cantidadActivos > 0,\n                        label: Text(\n                          '${widget.state.filtros.cantidadActivos}',\n                        ),\n                        backgroundColor: _filterYellow,\n                        textColor: Colors.black,\n                        child: const Icon(Icons.tune_rounded, size: 18),\n                      ),\n                      label: const Text('Más filtros'),\n                    ),\n                    OutlinedButton.icon(\n                      key: const Key('abrir_ordenamiento'),\n                      onPressed: _abrirOrden,\n                      style: OutlinedButton.styleFrom(\n                        foregroundColor: _filterInk,\n                        side: const BorderSide(color: _filterBorder),\n                        shape: RoundedRectangleBorder(\n                          borderRadius: BorderRadius.circular(11),\n                        ),\n                      ),\n                      icon: const Icon(Icons.sort_rounded, size: 18),\n                      label: Text(\n                        constraints.maxWidth < 560\n                            ? 'Ordenar'\n                            : widget.state.filtros.orden,\n                        maxLines: 1,\n                        overflow: TextOverflow.ellipsis,\n                      ),\n                    ),\n                  ],\n                );\n\n                final quick = SingleChildScrollView(\n                  scrollDirection: Axis.horizontal,\n                  child: Row(\n                    children: quickFilters.map((filter) {\n                      final selected =\n                          widget.state.filtrosRapidos.contains(filter);\n                      return Padding(\n                        padding: const EdgeInsets.only(right: 7),\n                        child: FilterChip(\n                          label: Text(filter),\n                          selected: selected,\n                          showCheckmark: false,\n                          onSelected: (_) => widget.onFiltroRapido(filter),\n                          selectedColor: _filterYellow,\n                          backgroundColor: _filterSurface,\n                          side: BorderSide(\n                            color: selected\n                                ? _filterYellow\n                                : _filterBorder,\n                          ),\n                          labelStyle: GoogleFonts.inter(\n                            color: _filterInk,\n                            fontSize: 12,\n                            fontWeight: selected\n                                ? FontWeight.w800\n                                : FontWeight.w600,\n                          ),\n                        ),\n                      );\n                    }).toList(),\n                  ),\n                );\n\n                if (constraints.maxWidth >= 760) {\n                  return Row(\n                    children: [\n                      Expanded(child: quick),\n                      const SizedBox(width: 12),\n                      actions,\n                    ],\n                  );\n                }\n                return Column(\n                  crossAxisAlignment: CrossAxisAlignment.stretch,\n                  children: [\n                    quick,\n                    const SizedBox(height: 9),\n                    actions,\n                  ],\n                );\n              },\n            ),\n            if (widget.state.filtros.tieneActivos) ...[\n              const SizedBox(height: 10),\n              _ActiveFilters(\n                filters: widget.state.filtros,\n                onChanged: widget.onFiltrosAplicados,\n                onClear: widget.onFiltrosLimpiados,\n              ),\n            ],\n          ],\n        ),\n      ),\n    );\n  }\n\n  Future<void> _abrirFiltros() async {\n    final result = await showDialog<CatalogoFiltros>(\n      context: context,\n      barrierColor: Colors.black.withValues(alpha: 0.58),\n      builder: (_) => _FiltrosAvanzadosDialog(\n        state: widget.state,\n        modoPedido: widget.modoPedido,\n      ),\n    );\n    if (result != null) widget.onFiltrosAplicados(result);\n  }\n\n  Future<void> _abrirOrden() async {\n    final result = await showDialog<String>(\n      context: context,\n      barrierColor: Colors.black.withValues(alpha: 0.58),\n      builder: (_) => _OrdenamientoDialog(\n        ordenActual: widget.state.filtros.orden,\n        modoPedido: widget.modoPedido,\n      ),\n    );\n    if (result != null) {\n      widget.onFiltrosAplicados(\n        widget.state.filtros.copyWith(orden: result),\n      );\n    }\n  }\n}\n\nclass _ClassificationSelect extends StatelessWidget {\n  const _ClassificationSelect({\n    required super.key,\n    required this.label,\n    required this.icon,\n    required this.value,\n    required this.options,\n    required this.allLabel,\n    required this.onChanged,\n  });\n\n  final String label;\n  final IconData icon;\n  final String? value;\n  final List<String> options;\n  final String allLabel;\n  final ValueChanged<String?> onChanged;\n\n  @override\n  Widget build(BuildContext context) => DropdownButtonFormField<String>(\n    key: ValueKey('$label-$value-${options.length}'),\n    initialValue: options.contains(value) ? value : null,\n    isExpanded: true,\n    decoration: InputDecoration(\n      labelText: label,\n      prefixIcon: Icon(icon, size: 19),\n      filled: true,\n      fillColor: Colors.white,\n      border: OutlineInputBorder(\n        borderRadius: BorderRadius.circular(12),\n      ),\n      enabledBorder: OutlineInputBorder(\n        borderRadius: BorderRadius.circular(12),\n        borderSide: const BorderSide(color: _filterBorder),\n      ),\n      focusedBorder: OutlineInputBorder(\n        borderRadius: BorderRadius.circular(12),\n        borderSide: const BorderSide(color: _filterYellow, width: 1.6),\n      ),\n    ),\n    items: [\n      DropdownMenuItem<String>(\n        value: '__all__',\n        child: Text(allLabel, overflow: TextOverflow.ellipsis),\n      ),\n      ...options.map(\n        (item) => DropdownMenuItem<String>(\n          value: item,\n          child: Text(item, overflow: TextOverflow.ellipsis),\n        ),\n      ),\n    ],\n    onChanged: (selected) {\n      onChanged(selected == '__all__' ? null : selected);\n    },\n  );\n}\n\nclass _ActiveFilters extends StatelessWidget {\n  const _ActiveFilters({\n    required this.filters,\n    required this.onChanged,\n    required this.onClear,\n  });\n\n  final CatalogoFiltros filters;\n  final ValueChanged<CatalogoFiltros> onChanged;\n  final VoidCallback onClear;\n\n  @override\n  Widget build(BuildContext context) {\n    final chips = <Widget>[\n      if (filters.empresa != null)\n        _chip(\n          'Empresa: ${filters.empresa}',\n          () => onChanged(filters.copyWith(clearEmpresa: true, clearMarca: true)),\n        ),\n      if (filters.marca != null)\n        _chip(\n          'Marca: ${filters.marca}',\n          () => onChanged(filters.copyWith(clearMarca: true)),\n        ),\n      if (filters.categoria != null)\n        _chip(\n          'Categoría: ${filters.categoria}',\n          () => onChanged(\n            filters.copyWith(\n              clearCategoria: true,\n              clearSubcategoria: true,\n            ),\n          ),\n        ),\n      if (filters.subcategoria != null)\n        _chip(\n          'Subcategoría: ${filters.subcategoria}',\n          () => onChanged(filters.copyWith(clearSubcategoria: true)),\n        ),\n      if (filters.estado != null)\n        _chip(\n          filters.estado!,\n          () => onChanged(filters.copyWith(clearEstado: true)),\n        ),\n      if (filters.precio != null)\n        _chip(\n          filters.precio!,\n          () => onChanged(filters.copyWith(clearPrecio: true)),\n        ),\n      if (filters.imagen != null)\n        _chip(\n          filters.imagen!,\n          () => onChanged(filters.copyWith(clearImagen: true)),\n        ),\n    ];\n\n    return Wrap(\n      spacing: 7,\n      runSpacing: 7,\n      crossAxisAlignment: WrapCrossAlignment.center,\n      children: [\n        ...chips,\n        TextButton.icon(\n          onPressed: onClear,\n          style: TextButton.styleFrom(foregroundColor: _filterMuted),\n          icon: const Icon(Icons.clear_all_rounded, size: 17),\n          label: const Text('Limpiar'),\n        ),\n      ],\n    );\n  }\n\n  Widget _chip(String label, VoidCallback onDeleted) => InputChip(\n    label: Text(label),\n    onDeleted: onDeleted,\n    deleteIcon: const Icon(Icons.close_rounded, size: 16),\n    backgroundColor: const Color(0xFFFFF8DD),\n    side: const BorderSide(color: _filterYellow),\n    labelStyle: GoogleFonts.inter(\n      color: _filterInk,\n      fontSize: 10,\n      fontWeight: FontWeight.w700,\n    ),\n  );\n}\n\nclass _FiltrosAvanzadosDialog extends StatefulWidget {\n  const _FiltrosAvanzadosDialog({\n    required this.state,\n    required this.modoPedido,\n  });\n\n  final CatalogoState state;\n  final bool modoPedido;\n\n  @override\n  State<_FiltrosAvanzadosDialog> createState() =>\n      _FiltrosAvanzadosDialogState();\n}\n\nclass _FiltrosAvanzadosDialogState extends State<_FiltrosAvanzadosDialog> {\n  late CatalogoFiltros _draft;\n\n  @override\n  void initState() {\n    super.initState();\n    _draft = widget.state.filtros;\n  }\n\n  List<String> _unique(Iterable<String> values) {\n    final result = values\n        .map((value) => value.trim())\n        .where((value) => value.isNotEmpty)\n        .toSet()\n        .toList()\n      ..sort();\n    return result;\n  }\n\n  List<String> get _companies =>\n      _unique(widget.state.productos.map((item) => item.empresa));\n\n  List<String> _brands(CatalogoFiltros filters) => _unique(\n    widget.state.productos\n        .where(\n          (item) =>\n              filters.empresa == null ||\n              item.empresa == filters.empresa,\n        )\n        .map((item) => item.marca),\n  );\n\n  List<String> _categories(CatalogoFiltros filters) => _unique(\n    widget.state.productos\n        .where(\n          (item) =>\n              (filters.empresa == null ||\n                  item.empresa == filters.empresa) &&\n              (filters.marca == null || item.marca == filters.marca),\n        )\n        .map((item) => item.categoria),\n  );\n\n  List<String> _subcategories(CatalogoFiltros filters) => _unique(\n    widget.state.productos\n        .where(\n          (item) =>\n              (filters.empresa == null ||\n                  item.empresa == filters.empresa) &&\n              (filters.marca == null || item.marca == filters.marca) &&\n              (filters.categoria == null ||\n                  item.categoria == filters.categoria),\n        )\n        .map((item) => item.subcategoria),\n  );\n\n  CatalogoFiltros _normalize(CatalogoFiltros value) {\n    var result = value;\n    if (!_brands(result).contains(result.marca)) {\n      result = result.copyWith(clearMarca: true);\n    }\n    if (!_categories(result).contains(result.categoria)) {\n      result = result.copyWith(\n        clearCategoria: true,\n        clearSubcategoria: true,\n      );\n    }\n    if (!_subcategories(result).contains(result.subcategoria)) {\n      result = result.copyWith(clearSubcategoria: true);\n    }\n    return result;\n  }\n\n  void _update(CatalogoFiltros value) {\n    setState(() => _draft = _normalize(value));\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final brands = _brands(_draft);\n    final categories = _categories(_draft);\n    final subcategories = _subcategories(_draft);\n\n    return Dialog(\n      backgroundColor: Colors.transparent,\n      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),\n      child: ConstrainedBox(\n        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),\n        child: Material(\n          color: Colors.white,\n          borderRadius: BorderRadius.circular(24),\n          clipBehavior: Clip.antiAlias,\n          child: Column(\n            mainAxisSize: MainAxisSize.min,\n            children: [\n              Container(\n                width: double.infinity,\n                padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),\n                color: _filterInk,\n                child: Row(\n                  children: [\n                    Container(\n                      width: 42,\n                      height: 42,\n                      decoration: BoxDecoration(\n                        color: _filterYellow,\n                        borderRadius: BorderRadius.circular(12),\n                      ),\n                      child: const Icon(Icons.tune_rounded, color: Colors.black),\n                    ),\n                    const SizedBox(width: 12),\n                    Expanded(\n                      child: Column(\n                        crossAxisAlignment: CrossAxisAlignment.start,\n                        children: [\n                          Text(\n                            widget.modoPedido\n                                ? 'Filtros para el pedido'\n                                : 'Más filtros del catálogo',\n                            style: GoogleFonts.inter(\n                              color: Colors.white,\n                              fontSize: 19,\n                              fontWeight: FontWeight.w800,\n                            ),\n                          ),\n                          Text(\n                            'Combina origen comercial y clasificación sin '\n                            'saturar la pantalla principal.',\n                            style: GoogleFonts.inter(\n                              color: const Color(0xFFB7BAC1),\n                              fontSize: 11,\n                            ),\n                          ),\n                        ],\n                      ),\n                    ),\n                    IconButton(\n                      tooltip: 'Cerrar',\n                      onPressed: () => Navigator.pop(context),\n                      icon: const Icon(Icons.close_rounded, color: Colors.white),\n                    ),\n                  ],\n                ),\n              ),\n              Flexible(\n                child: SingleChildScrollView(\n                  padding: const EdgeInsets.all(20),\n                  child: Column(\n                    crossAxisAlignment: CrossAxisAlignment.stretch,\n                    children: [\n                      const _DialogSectionTitle(\n                        'Origen comercial',\n                        Icons.business_outlined,\n                      ),\n                      _DialogGrid(\n                        children: [\n                          _DialogSelect(\n                            label: 'Empresa',\n                            value: _companies.contains(_draft.empresa)\n                                ? _draft.empresa\n                                : null,\n                            options: _companies,\n                            allLabel: 'Todas las empresas',\n                            onChanged: (value) => _update(\n                              _draft.copyWith(\n                                empresa: value,\n                                clearEmpresa: value == null,\n                              ),\n                            ),\n                          ),\n                          _DialogSelect(\n                            label: 'Marca',\n                            value: brands.contains(_draft.marca)\n                                ? _draft.marca\n                                : null,\n                            options: brands,\n                            allLabel: _draft.empresa == null\n                                ? 'Todas las marcas'\n                                : 'Todas en ${_draft.empresa}',\n                            onChanged: (value) => _update(\n                              _draft.copyWith(\n                                marca: value,\n                                clearMarca: value == null,\n                              ),\n                            ),\n                          ),\n                        ],\n                      ),\n                      const SizedBox(height: 20),\n                      const _DialogSectionTitle(\n                        'Clasificación',\n                        Icons.account_tree_outlined,\n                      ),\n                      _DialogGrid(\n                        children: [\n                          _DialogSelect(\n                            label: 'Categoría',\n                            value: categories.contains(_draft.categoria)\n                                ? _draft.categoria\n                                : null,\n                            options: categories,\n                            allLabel: 'Todas las categorías',\n                            onChanged: (value) => _update(\n                              _draft.copyWith(\n                                categoria: value,\n                                clearCategoria: value == null,\n                              ),\n                            ),\n                          ),\n                          _DialogSelect(\n                            label: 'Subcategoría',\n                            value: subcategories.contains(_draft.subcategoria)\n                                ? _draft.subcategoria\n                                : null,\n                            options: subcategories,\n                            allLabel: 'Todas las subcategorías',\n                            onChanged: (value) => _update(\n                              _draft.copyWith(\n                                subcategoria: value,\n                                clearSubcategoria: value == null,\n                              ),\n                            ),\n                          ),\n                        ],\n                      ),\n                      const SizedBox(height: 20),\n                      _DialogSectionTitle(\n                        widget.modoPedido\n                            ? 'Condición de venta'\n                            : 'Disponibilidad y contenido',\n                        Icons.inventory_2_outlined,\n                      ),\n                      _DialogGrid(\n                        children: [\n                          if (!widget.modoPedido)\n                            _DialogSelect(\n                              label: 'Estado',\n                              value: _draft.estado,\n                              options: const ['Activo', 'Inactivo'],\n                              allLabel: 'Todos los estados',\n                              onChanged: (value) => _update(\n                                _draft.copyWith(\n                                  estado: value,\n                                  clearEstado: value == null,\n                                ),\n                              ),\n                            ),\n                          _DialogSelect(\n                            label: 'Precio',\n                            value: _draft.precio,\n                            options: const ['Con precio', 'Sin precio'],\n                            allLabel: 'Con y sin precio',\n                            onChanged: (value) => _update(\n                              _draft.copyWith(\n                                precio: value,\n                                clearPrecio: value == null,\n                              ),\n                            ),\n                          ),\n                          if (!widget.modoPedido)\n                            _DialogSelect(\n                              label: 'Imagen',\n                              value: _draft.imagen,\n                              options: const ['Con imagen', 'Sin imagen'],\n                              allLabel: 'Con y sin imagen',\n                              onChanged: (value) => _update(\n                                _draft.copyWith(\n                                  imagen: value,\n                                  clearImagen: value == null,\n                                ),\n                              ),\n                            ),\n                        ],\n                      ),\n                    ],\n                  ),\n                ),\n              ),\n              const Divider(height: 1),\n              Padding(\n                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),\n                child: Row(\n                  children: [\n                    Expanded(\n                      child: OutlinedButton.icon(\n                        onPressed: () => setState(\n                          () => _draft = CatalogoFiltros(\n                            orden: _draft.orden,\n                          ),\n                        ),\n                        style: OutlinedButton.styleFrom(\n                          foregroundColor: _filterMuted,\n                          side: const BorderSide(color: _filterBorder),\n                          minimumSize: const Size(0, 46),\n                        ),\n                        icon: const Icon(Icons.clear_all_rounded),\n                        label: const Text('Limpiar'),\n                      ),\n                    ),\n                    const SizedBox(width: 12),\n                    Expanded(\n                      child: FilledButton.icon(\n                        onPressed: () => Navigator.pop(context, _draft),\n                        style: FilledButton.styleFrom(\n                          backgroundColor: _filterYellow,\n                          foregroundColor: Colors.black,\n                          minimumSize: const Size(0, 46),\n                        ),\n                        icon: const Icon(Icons.check_rounded),\n                        label: const Text(\n                          'Aplicar filtros',\n                          style: TextStyle(fontWeight: FontWeight.w700),\n                        ),\n                      ),\n                    ),\n                  ],\n                ),\n              ),\n            ],\n          ),\n        ),\n      ),\n    );\n  }\n}\n\nclass _DialogGrid extends StatelessWidget {\n  const _DialogGrid({required this.children});\n\n  final List<Widget> children;\n\n  @override\n  Widget build(BuildContext context) => LayoutBuilder(\n    builder: (context, constraints) {\n      final width = constraints.maxWidth < 560\n          ? constraints.maxWidth\n          : (constraints.maxWidth - 12) / 2;\n      return Wrap(\n        spacing: 12,\n        runSpacing: 12,\n        children: children\n            .map((child) => SizedBox(width: width, child: child))\n            .toList(),\n      );\n    },\n  );\n}\n\nclass _DialogSectionTitle extends StatelessWidget {\n  const _DialogSectionTitle(this.label, this.icon);\n\n  final String label;\n  final IconData icon;\n\n  @override\n  Widget build(BuildContext context) => Padding(\n    padding: const EdgeInsets.only(bottom: 10),\n    child: Row(\n      children: [\n        Container(\n          width: 4,\n          height: 20,\n          decoration: BoxDecoration(\n            color: _filterYellow,\n            borderRadius: BorderRadius.circular(2),\n          ),\n        ),\n        const SizedBox(width: 9),\n        Icon(icon, size: 18, color: _filterMuted),\n        const SizedBox(width: 7),\n        Text(\n          label,\n          style: GoogleFonts.inter(\n            color: _filterInk,\n            fontSize: 14,\n            fontWeight: FontWeight.w800,\n          ),\n        ),\n      ],\n    ),\n  );\n}\n\nclass _DialogSelect extends StatelessWidget {\n  const _DialogSelect({\n    required this.label,\n    required this.value,\n    required this.options,\n    required this.allLabel,\n    required this.onChanged,\n  });\n\n  final String label;\n  final String? value;\n  final List<String> options;\n  final String allLabel;\n  final ValueChanged<String?> onChanged;\n\n  @override\n  Widget build(BuildContext context) => DropdownButtonFormField<String>(\n    key: ValueKey('dialog-$label-$value-${options.length}'),\n    initialValue: options.contains(value) ? value : null,\n    isExpanded: true,\n    decoration: InputDecoration(\n      labelText: label,\n      filled: true,\n      fillColor: _filterSurface,\n      border: OutlineInputBorder(\n        borderRadius: BorderRadius.circular(12),\n      ),\n      enabledBorder: OutlineInputBorder(\n        borderRadius: BorderRadius.circular(12),\n        borderSide: const BorderSide(color: _filterBorder),\n      ),\n      focusedBorder: OutlineInputBorder(\n        borderRadius: BorderRadius.circular(12),\n        borderSide: const BorderSide(color: _filterYellow, width: 1.6),\n      ),\n    ),\n    items: [\n      DropdownMenuItem<String>(\n        value: '__all__',\n        child: Text(allLabel, overflow: TextOverflow.ellipsis),\n      ),\n      ...options.map(\n        (item) => DropdownMenuItem<String>(\n          value: item,\n          child: Text(item, overflow: TextOverflow.ellipsis),\n        ),\n      ),\n    ],\n    onChanged: (selected) {\n      onChanged(selected == '__all__' ? null : selected);\n    },\n  );\n}\n\nclass _OrdenamientoDialog extends StatelessWidget {\n  const _OrdenamientoDialog({\n    required this.ordenActual,\n    required this.modoPedido,\n  });\n\n  final String ordenActual;\n  final bool modoPedido;\n\n  @override\n  Widget build(BuildContext context) {\n    final options = modoPedido\n        ? _orderOptions\n            .where((item) => item.title != 'Activos primero')\n            .toList()\n        : _orderOptions;\n\n    return Dialog(\n      backgroundColor: Colors.transparent,\n      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),\n      child: ConstrainedBox(\n        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),\n        child: Material(\n          color: Colors.white,\n          borderRadius: BorderRadius.circular(24),\n          clipBehavior: Clip.antiAlias,\n          child: Column(\n            mainAxisSize: MainAxisSize.min,\n            children: [\n              Container(\n                width: double.infinity,\n                padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),\n                color: _filterInk,\n                child: Row(\n                  children: [\n                    Container(\n                      width: 42,\n                      height: 42,\n                      decoration: BoxDecoration(\n                        color: _filterYellow,\n                        borderRadius: BorderRadius.circular(12),\n                      ),\n                      child: const Icon(Icons.sort_rounded),\n                    ),\n                    const SizedBox(width: 12),\n                    Expanded(\n                      child: Text(\n                        'Ordenar productos',\n                        style: GoogleFonts.inter(\n                          color: Colors.white,\n                          fontSize: 19,\n                          fontWeight: FontWeight.w800,\n                        ),\n                      ),\n                    ),\n                    IconButton(\n                      onPressed: () => Navigator.pop(context),\n                      icon: const Icon(Icons.close_rounded, color: Colors.white),\n                    ),\n                  ],\n                ),\n              ),\n              Flexible(\n                child: ListView.separated(\n                  shrinkWrap: true,\n                  padding: const EdgeInsets.all(18),\n                  itemCount: options.length,\n                  separatorBuilder: (_, _) => const SizedBox(height: 8),\n                  itemBuilder: (context, index) {\n                    final option = options[index];\n                    final selected = ordenActual == option.title;\n                    return Material(\n                      color: selected\n                          ? const Color(0xFFFFF8DD)\n                          : _filterSurface,\n                      borderRadius: BorderRadius.circular(14),\n                      child: InkWell(\n                        onTap: () => Navigator.pop(context, option.title),\n                        borderRadius: BorderRadius.circular(14),\n                        child: Container(\n                          padding: const EdgeInsets.all(13),\n                          decoration: BoxDecoration(\n                            borderRadius: BorderRadius.circular(14),\n                            border: Border.all(\n                              color: selected\n                                  ? _filterYellow\n                                  : _filterBorder,\n                            ),\n                          ),\n                          child: Row(\n                            children: [\n                              Icon(option.icon, color: _filterMuted),\n                              const SizedBox(width: 12),\n                              Expanded(\n                                child: Column(\n                                  crossAxisAlignment: CrossAxisAlignment.start,\n                                  children: [\n                                    Text(\n                                      option.title,\n                                      style: GoogleFonts.inter(\n                                        color: _filterInk,\n                                        fontSize: 13,\n                                        fontWeight: FontWeight.w800,\n                                      ),\n                                    ),\n                                    Text(\n                                      option.subtitle,\n                                      style: GoogleFonts.inter(\n                                        color: _filterMuted,\n                                        fontSize: 10,\n                                      ),\n                                    ),\n                                  ],\n                                ),\n                              ),\n                              Icon(\n                                selected\n                                    ? Icons.check_circle_rounded\n                                    : Icons.circle_outlined,\n                                color: selected\n                                    ? _filterYellow\n                                    : _filterBorder,\n                              ),\n                            ],\n                          ),\n                        ),\n                      ),\n                    );\n                  },\n                ),\n              ),\n            ],\n          ),\n        ),\n      ),\n    );\n  }\n}\n\nclass _OrderOption {\n  const _OrderOption(this.title, this.icon, this.subtitle);\n\n  final String title;\n  final IconData icon;\n  final String subtitle;\n}\n\nconst _orderOptions = [\n  _OrderOption('Nombre A-Z', Icons.sort_by_alpha, 'Alfabético ascendente'),\n  _OrderOption('Nombre Z-A', Icons.sort_by_alpha, 'Alfabético descendente'),\n  _OrderOption(\n    'Precio menor a mayor',\n    Icons.arrow_upward_rounded,\n    'Más económico primero',\n  ),\n  _OrderOption(\n    'Precio mayor a menor',\n    Icons.arrow_downward_rounded,\n    'Mayor precio primero',\n  ),\n  _OrderOption(\n    'Más recientes',\n    Icons.access_time_rounded,\n    'Últimos productos agregados',\n  ),\n  _OrderOption(\n    'Activos primero',\n    Icons.check_circle_outline_rounded,\n    'Productos activos al inicio',\n  ),\n];\n"
NEW_TEST_FILE = "import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';\nimport 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo_state.dart';\nimport 'package:app_catalogo/features/catalogo/presentation/widgets/filtros_catalogo.dart';\nimport 'package:flutter/material.dart';\nimport 'package:flutter_test/flutter_test.dart';\n\nvoid main() {\n  testWidgets('muestra categoría y subcategoría como clasificación principal', (\n    tester,\n  ) async {\n    await tester.binding.setSurfaceSize(const Size(900, 700));\n    addTearDown(() => tester.binding.setSurfaceSize(null));\n\n    CatalogoFiltros? applied;\n    final state = CatalogoState(\n      loading: false,\n      actualizando: false,\n      busqueda: '',\n      filtrosRapidos: const {'Todos'},\n      filtros: const CatalogoFiltros(),\n      vistaGrilla: true,\n      productos: const [\n        ProductoResumen(\n          id: '1',\n          codigo: 'PER-001',\n          nombre: 'Perno hexagonal',\n          empresa: 'DINAFAST',\n          marca: 'DINA',\n          categoria: 'Pernería',\n          subcategoria: 'Pernos hexagonales',\n          unidadVenta: 'Ciento',\n          precio: 20,\n          sinPrecio: false,\n          activo: true,\n          tipoRegistro: 'matriz',\n          atributosClave: [],\n        ),\n        ProductoResumen(\n          id: '2',\n          codigo: 'BRO-001',\n          nombre: 'Broca HSS',\n          empresa: 'UYUSTOOLS',\n          marca: 'UYUSTOOLS',\n          categoria: 'Accesorios',\n          subcategoria: 'Brocas',\n          unidadVenta: 'Unidad',\n          precio: null,\n          sinPrecio: true,\n          activo: true,\n          tipoRegistro: 'lista',\n          atributosClave: [],\n        ),\n      ],\n      productosFiltrados: const [],\n    );\n\n    await tester.pumpWidget(\n      MaterialApp(\n        home: Scaffold(\n          body: FiltrosCatalogo(\n            state: state,\n            onBusquedaCambiada: (_) {},\n            onFiltroRapido: (_) {},\n            onFiltrosAplicados: (value) => applied = value,\n            onFiltrosLimpiados: () {},\n          ),\n        ),\n      ),\n    );\n\n    expect(find.byKey(const Key('catalogo_filtro_categoria')), findsOneWidget);\n    expect(\n      find.byKey(const Key('catalogo_filtro_subcategoria')),\n      findsOneWidget,\n    );\n    expect(find.text('Con variantes'), findsNothing);\n    expect(find.text('Sin imagen'), findsNothing);\n\n    await tester.tap(find.byKey(const Key('catalogo_filtro_categoria')));\n    await tester.pumpAndSettle();\n    await tester.tap(find.text('Pernería').last);\n    await tester.pumpAndSettle();\n\n    expect(applied?.categoria, 'Pernería');\n    expect(tester.takeException(), isNull);\n  });\n\n  testWidgets('nuevo pedido usa filtros comerciales compactos', (tester) async {\n    await tester.binding.setSurfaceSize(const Size(900, 700));\n    addTearDown(() => tester.binding.setSurfaceSize(null));\n\n    final state = CatalogoState(\n      loading: false,\n      actualizando: false,\n      busqueda: '',\n      filtrosRapidos: const {'Todos'},\n      filtros: const CatalogoFiltros(),\n      vistaGrilla: true,\n      productos: const [],\n      productosFiltrados: const [],\n    );\n\n    await tester.pumpWidget(\n      MaterialApp(\n        home: Scaffold(\n          body: FiltrosCatalogo(\n            state: state,\n            modoPedido: true,\n            onBusquedaCambiada: (_) {},\n            onFiltroRapido: (_) {},\n            onFiltrosAplicados: (_) {},\n            onFiltrosLimpiados: () {},\n          ),\n        ),\n      ),\n    );\n\n    expect(find.text('Con precio'), findsOneWidget);\n    expect(find.text('Sin precio'), findsOneWidget);\n    expect(find.text('Activos'), findsNothing);\n    expect(find.text('Inactivos'), findsNothing);\n    expect(tester.takeException(), isNull);\n  });\n}\n"

# ---------------------------------------------------------------------------
# Estado del catálogo: subcategoría y copyWith coherente.
# ---------------------------------------------------------------------------

catalog_state = replace_once(
    catalog_state,
    "    this.categoria,\n"
    "    this.estado,\n",
    "    this.categoria,\n"
    "    this.subcategoria,\n"
    "    this.estado,\n",
    "agregar subcategoría al constructor de filtros",
)
catalog_state = replace_once(
    catalog_state,
    "  final String? empresa, marca, categoria, estado, precio, imagen;\n",
    "  final String? empresa, marca, categoria, subcategoria, estado, precio, imagen;\n",
    "agregar campo subcategoría",
)
catalog_state = replace_once(
    catalog_state,
    "      categoria != null ||\n"
    "      estado != null ||\n",
    "      categoria != null ||\n"
    "      subcategoria != null ||\n"
    "      estado != null ||\n",
    "contar subcategoría activa",
)
catalog_state = replace_once(
    catalog_state,
    "    categoria,\n"
    "    estado,\n"
    "    precio,\n"
    "    imagen,\n"
    "    orden,\n"
    "  ];\n",
    "    categoria,\n"
    "    subcategoria,\n"
    "    estado,\n"
    "    precio,\n"
    "    imagen,\n"
    "    orden,\n"
    "  ];\n",
    "agregar subcategoría a props",
)

copy_with = """  int get cantidadActivos => [
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
    subcategoria: clearSubcategoria
        ? null
        : subcategoria ?? this.subcategoria,
    estado: clearEstado ? null : estado ?? this.estado,
    precio: clearPrecio ? null : precio ?? this.precio,
    imagen: clearImagen ? null : imagen ?? this.imagen,
    orden: orden ?? this.orden,
  );

"""
catalog_state = replace_once(
    catalog_state,
    "  @override\n"
    "  List<Object?> get props => [\n",
    copy_with
    + "  @override\n"
    "  List<Object?> get props => [\n",
    "agregar copyWith a filtros",
)
catalog_state = replace_once(
    catalog_state,
    "  List<String> get categorias => _unicos(productos.map((p) => p.categoria));\n",
    "  List<String> get categorias => _unicos(productos.map((p) => p.categoria));\n"
    "  List<String> get subcategorias => _unicos(\n"
    "    productos.map((p) => p.subcategoria).where((value) => value.isNotEmpty),\n"
    "  );\n",
    "exponer subcategorías disponibles",
)

# ---------------------------------------------------------------------------
# BLoC del catálogo: limpiar quick filters y filtrar subcategoría.
# ---------------------------------------------------------------------------

catalog_bloc = replace_once(
    catalog_bloc,
    "    on<CatalogoFiltrosLimpiados>(\n"
    "      (_, emit) =>\n"
    "          emit(_filtrar(state.copyWith(filtros: const CatalogoFiltros()))),\n"
    "    );\n",
    "    on<CatalogoFiltrosLimpiados>(\n"
    "      (_, emit) => emit(\n"
    "        _filtrar(\n"
    "          state.copyWith(\n"
    "            filtros: const CatalogoFiltros(),\n"
    "            filtrosRapidos: const {'Todos'},\n"
    "          ),\n"
    "        ),\n"
    "      ),\n"
    "    );\n",
    "limpiar todos los filtros del catálogo",
)
catalog_bloc = replace_once(
    catalog_bloc,
    "          p.categoria.toLowerCase().contains(texto) ||\n"
    "          p.atributosClave.any((a) => a.toLowerCase().contains(texto));\n",
    "          p.categoria.toLowerCase().contains(texto) ||\n"
    "          p.subcategoria.toLowerCase().contains(texto) ||\n"
    "          p.atributosClave.any((a) => a.toLowerCase().contains(texto));\n",
    "buscar por subcategoría",
)
catalog_bloc = replace_once(
    catalog_bloc,
    "              (f.categoria == null || p.categoria == f.categoria) &&\n"
    "              (f.estado == null ||\n",
    "              (f.categoria == null || p.categoria == f.categoria) &&\n"
    "              (f.subcategoria == null ||\n"
    "                  p.subcategoria == f.subcategoria) &&\n"
    "              (f.estado == null ||\n",
    "filtrar por subcategoría",
)

# ---------------------------------------------------------------------------
# Nuevo pedido: modo compacto y estado por subcategoría.
# ---------------------------------------------------------------------------

new_order = replace_once(
    new_order,
    "                FiltrosCatalogo(\n"
    "                  state: _catalogoState(state),\n",
    "                FiltrosCatalogo(\n"
    "                  state: _catalogoState(state),\n"
    "                  modoPedido: true,\n",
    "activar filtros de venta",
)

order_state = replace_once(
    order_state,
    "    this.categoria,\n"
    "    this.estado,\n",
    "    this.categoria,\n"
    "    this.subcategoria,\n"
    "    this.estado,\n",
    "agregar subcategoría al estado de pedidos",
)
order_state = replace_once(
    order_state,
    "  final String? categoria;\n"
    "  final String? estado;\n",
    "  final String? categoria;\n"
    "  final String? subcategoria;\n"
    "  final String? estado;\n",
    "declarar subcategoría en pedidos",
)
order_state = replace_once(
    order_state,
    "          producto.categoria.toLowerCase().contains(query) ||\n"
    "          producto.atributosClave.any(\n",
    "          producto.categoria.toLowerCase().contains(query) ||\n"
    "          producto.subcategoria.toLowerCase().contains(query) ||\n"
    "          producto.atributosClave.any(\n",
    "buscar subcategoría en nuevo pedido",
)
order_state = replace_once(
    order_state,
    "          (categoria == null || producto.categoria == categoria) &&\n"
    "          (estado == null || estado == 'Activo') &&\n",
    "          (categoria == null || producto.categoria == categoria) &&\n"
    "          (subcategoria == null ||\n"
    "              producto.subcategoria == subcategoria) &&\n"
    "          (estado == null || estado == 'Activo') &&\n",
    "filtrar subcategoría en nuevo pedido",
)
order_state = replace_once(
    order_state,
    "  List<String> get categorias =>\n"
    "      ({for (final item in productos) item.categoria}.toList()..sort());\n"
    "  int get filtrosAvanzadosActivos =>\n"
    "      [empresa, marca, categoria, estado, imagen].whereType<String>().length;\n",
    "  List<String> get categorias =>\n"
    "      ({for (final item in productos) item.categoria}.toList()..sort());\n"
    "  List<String> get subcategorias =>\n"
    "      ({\n"
    "        for (final item in productos)\n"
    "          if (item.subcategoria.isNotEmpty) item.subcategoria,\n"
    "      }.toList()..sort());\n"
    "  int get filtrosAvanzadosActivos => [\n"
    "    empresa,\n"
    "    marca,\n"
    "    categoria,\n"
    "    subcategoria,\n"
    "    estado,\n"
    "    imagen,\n"
    "  ].whereType<String>().length;\n",
    "exponer subcategorías en nuevo pedido",
)
order_state = replace_once(
    order_state,
    "    categoria: categoria,\n"
    "    estado: estado,\n",
    "    categoria: categoria,\n"
    "    subcategoria: subcategoria,\n"
    "    estado: estado,\n",
    "pasar subcategoría a filtros compartidos",
)
order_state = replace_once(
    order_state,
    "    String? categoria,\n"
    "    String? estado,\n",
    "    String? categoria,\n"
    "    String? subcategoria,\n"
    "    String? estado,\n",
    "agregar subcategoría a copyWith de pedidos",
)
order_state = replace_once(
    order_state,
    "    categoria: limpiarFiltros ? null : categoria ?? this.categoria,\n"
    "    estado: limpiarFiltros ? null : estado ?? this.estado,\n",
    "    categoria: limpiarFiltros ? null : categoria ?? this.categoria,\n"
    "    subcategoria: limpiarFiltros\n"
    "        ? null\n"
    "        : subcategoria ?? this.subcategoria,\n"
    "    estado: limpiarFiltros ? null : estado ?? this.estado,\n",
    "copiar subcategoría en pedidos",
)
order_state = replace_once(
    order_state,
    "    categoria,\n"
    "    estado,\n"
    "    imagen,\n",
    "    categoria,\n"
    "    subcategoria,\n"
    "    estado,\n"
    "    imagen,\n",
    "agregar subcategoría a props de pedidos",
)

order_bloc = replace_once(
    order_bloc,
    "              categoria: filtros.categoria,\n"
    "              estado: filtros.estado,\n",
    "              categoria: filtros.categoria,\n"
    "              subcategoria: filtros.subcategoria,\n"
    "              estado: filtros.estado,\n",
    "aplicar subcategoría en nuevo pedido",
)

# ---------------------------------------------------------------------------
# Widget completo y pruebas.
# ---------------------------------------------------------------------------

catalog_test = replace_once(
    catalog_test,
    "import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo_event.dart';\n",
    "import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo_event.dart';\n"
    "import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo_state.dart';\n",
    "importar filtros en prueba",
)
catalog_test = replace_once(
    catalog_test,
    "      categoria: 'Pernería',\n"
    "      unidadVenta: 'Ciento',\n",
    "      categoria: 'Pernería',\n"
    "      subcategoria: 'Pernos hexagonales',\n"
    "      unidadVenta: 'Ciento',\n",
    "agregar subcategoría al perno de prueba",
)
catalog_test = replace_once(
    catalog_test,
    "      categoria: 'Herramientas eléctricas',\n"
    "      unidadVenta: 'UND',\n",
    "      categoria: 'Herramientas eléctricas',\n"
    "      subcategoria: 'Taladros',\n"
    "      unidadVenta: 'UND',\n",
    "agregar subcategoría al taladro de prueba",
)

extra_assertions = """    bloc.add(const CatalogoFiltroRapidoCambiado('Todos'));
    await bloc.stream.firstWhere(
      (state) => state.filtrosRapidos.contains('Todos'),
    );
    bloc.add(
      const CatalogoFiltrosAplicados(
        CatalogoFiltros(
          categoria: 'Pernería',
          subcategoria: 'Pernos hexagonales',
        ),
      ),
    );
    await bloc.stream.firstWhere(
      (state) =>
          state.filtros.subcategoria == 'Pernos hexagonales',
    );
    expect(bloc.state.productosFiltrados.single.codigo, 'PER-001');
"""
catalog_test = replace_once(
    catalog_test,
    "    expect(bloc.state.productosFiltrados.single.codigo, 'TAL-020');\n"
    "  });\n",
    "    expect(bloc.state.productosFiltrados.single.codigo, 'TAL-020');\n\n"
    + extra_assertions
    + "  });\n",
    "probar clasificación categoría y subcategoría",
)

updates = {
    FILTERS: NEW_FILTERS_FILE,
    CATALOG_STATE: catalog_state,
    CATALOG_BLOC: catalog_bloc,
    NEW_ORDER: new_order,
    ORDER_STATE: order_state,
    ORDER_BLOC: order_bloc,
    CATALOG_TEST: catalog_test,
}

backup_dir = ROOT / (
    ".backup_filtros_clasificacion_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

paths_to_backup = list(updates)
if FILTER_TEST.exists():
    paths_to_backup.append(FILTER_TEST)

for path in paths_to_backup:
    destination = backup_dir / path.relative_to(ROOT)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, destination)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

filter_test_existed = FILTER_TEST.exists()
FILTER_TEST.write_text(NEW_TEST_FILE, encoding="utf-8", newline="\n")
print(
    f"{'Actualizado' if filter_test_existed else 'Creado'}: "
    f"{FILTER_TEST.relative_to(ROOT)}"
)

print(f"\nRespaldo: {backup_dir}")
print("\nFiltros jerárquicos de Catálogo y Nuevo pedido aplicados; la prueba existente fue respaldada.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/catalogo_bloc_test.dart")
print("  flutter test test/filtros_catalogo_test.dart")
print("  flutter analyze")
