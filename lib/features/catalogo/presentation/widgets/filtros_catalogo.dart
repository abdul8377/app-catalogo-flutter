import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/catalogo/catalogo_state.dart';

const _filterYellow = Color(0xFFFFC500);
const _filterInk = Color(0xFF1F1F1F);
const _filterMuted = Color(0xFF667085);
const _filterBorder = Color(0xFFE1E5EA);
const _filterSurface = Color(0xFFF7F8FA);

class FiltrosCatalogo extends StatefulWidget {
  const FiltrosCatalogo({
    required this.state,
    required this.onBusquedaCambiada,
    required this.onFiltroRapido,
    required this.onFiltrosAplicados,
    required this.onFiltrosLimpiados,
    this.modoPedido = false,
    super.key,
  });

  final CatalogoState state;
  final ValueChanged<String> onBusquedaCambiada;
  final ValueChanged<String> onFiltroRapido;
  final ValueChanged<CatalogoFiltros> onFiltrosAplicados;
  final VoidCallback onFiltrosLimpiados;
  final bool modoPedido;

  @override
  State<FiltrosCatalogo> createState() => _FiltrosCatalogoState();
}

class _FiltrosCatalogoState extends State<FiltrosCatalogo> {
  late final TextEditingController _busqueda;

  @override
  void initState() {
    super.initState();
    _busqueda = TextEditingController(text: widget.state.busqueda);
  }

  @override
  void didUpdateWidget(covariant FiltrosCatalogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_busqueda.text != widget.state.busqueda) {
      _busqueda.value = TextEditingValue(
        text: widget.state.busqueda,
        selection: TextSelection.collapsed(
          offset: widget.state.busqueda.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quickFilters = widget.modoPedido
        ? const ['Todos', 'Con precio', 'Sin precio']
        : const ['Todos', 'Activos', 'Inactivos'];

    return Material(
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _filterBorder)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('catalogo_busqueda'),
              controller: _busqueda,
              onChanged: widget.onBusquedaCambiada,
              decoration: InputDecoration(
                hintText: widget.modoPedido
                    ? 'Buscar producto para agregar al pedido…'
                    : 'Buscar por nombre, código, marca o característica…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: widget.state.busqueda.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _busqueda.clear();
                          widget.onBusquedaCambiada('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: _filterSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _filterBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _filterBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: _filterYellow,
                    width: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            LayoutBuilder(
              builder: (context, constraints) {
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('abrir_filtros_avanzados'),
                      onPressed: _abrirFiltros,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _filterInk,
                        side: const BorderSide(color: _filterYellow),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      icon: Badge(
                        isLabelVisible:
                            widget.state.filtros.cantidadActivos > 0,
                        label: Text('${widget.state.filtros.cantidadActivos}'),
                        backgroundColor: _filterYellow,
                        textColor: Colors.black,
                        child: const Icon(Icons.tune_rounded, size: 18),
                      ),
                      label: const Text('Más filtros'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('abrir_ordenamiento'),
                      onPressed: _abrirOrden,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _filterInk,
                        side: const BorderSide(color: _filterBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      icon: const Icon(Icons.sort_rounded, size: 18),
                      label: Text(
                        constraints.maxWidth < 560
                            ? 'Ordenar'
                            : widget.state.filtros.orden,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );

                final quick = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: quickFilters.map((filter) {
                      final selected = widget.state.filtrosRapidos.contains(
                        filter,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: FilterChip(
                          label: Text(filter),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) => widget.onFiltroRapido(filter),
                          selectedColor: _filterYellow,
                          backgroundColor: _filterSurface,
                          side: BorderSide(
                            color: selected ? _filterYellow : _filterBorder,
                          ),
                          labelStyle: GoogleFonts.inter(
                            color: _filterInk,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );

                if (constraints.maxWidth >= 760) {
                  return Row(
                    children: [
                      Expanded(child: quick),
                      const SizedBox(width: 12),
                      actions,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [quick, const SizedBox(height: 9), actions],
                );
              },
            ),
            if (widget.state.filtros.tieneActivos) ...[
              const SizedBox(height: 10),
              _ActiveFilters(
                filters: widget.state.filtros,
                onChanged: widget.onFiltrosAplicados,
                onClear: widget.onFiltrosLimpiados,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFiltros() async {
    final result = await showDialog<CatalogoFiltros>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => _FiltrosAvanzadosDialog(
        state: widget.state,
        modoPedido: widget.modoPedido,
      ),
    );
    if (result != null) widget.onFiltrosAplicados(result);
  }

  Future<void> _abrirOrden() async {
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => _OrdenamientoDialog(
        ordenActual: widget.state.filtros.orden,
        modoPedido: widget.modoPedido,
      ),
    );
    if (result != null) {
      widget.onFiltrosAplicados(widget.state.filtros.copyWith(orden: result));
    }
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.filters,
    required this.onChanged,
    required this.onClear,
  });

  final CatalogoFiltros filters;
  final ValueChanged<CatalogoFiltros> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (filters.empresa != null)
        _chip(
          'Empresa: ${filters.empresa}',
          () =>
              onChanged(filters.copyWith(clearEmpresa: true, clearMarca: true)),
        ),
      if (filters.marca != null)
        _chip(
          'Marca: ${filters.marca}',
          () => onChanged(filters.copyWith(clearMarca: true)),
        ),
      if (filters.categoria != null)
        _chip(
          'Categoría: ${filters.categoria}',
          () => onChanged(
            filters.copyWith(clearCategoria: true, clearSubcategoria: true),
          ),
        ),
      for (final subcategoria in filters.subcategoriasActivas)
        _chip('Subcategoría: $subcategoria', () {
          final restantes = {...filters.subcategoriasActivas}
            ..remove(subcategoria);
          onChanged(
            filters.copyWith(subcategorias: restantes, clearSubcategoria: true),
          );
        }),
      if (filters.estado != null)
        _chip(
          filters.estado!,
          () => onChanged(filters.copyWith(clearEstado: true)),
        ),
      if (filters.precio != null)
        _chip(
          filters.precio!,
          () => onChanged(filters.copyWith(clearPrecio: true)),
        ),
      if (filters.imagen != null)
        _chip(
          filters.imagen!,
          () => onChanged(filters.copyWith(clearImagen: true)),
        ),
    ];

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...chips,
        TextButton.icon(
          onPressed: onClear,
          style: TextButton.styleFrom(foregroundColor: _filterMuted),
          icon: const Icon(Icons.clear_all_rounded, size: 17),
          label: const Text('Limpiar'),
        ),
      ],
    );
  }

  Widget _chip(String label, VoidCallback onDeleted) => InputChip(
    label: Text(label),
    onDeleted: onDeleted,
    deleteIcon: const Icon(Icons.close_rounded, size: 16),
    backgroundColor: const Color(0xFFFFF8DD),
    side: const BorderSide(color: _filterYellow),
    labelStyle: GoogleFonts.inter(
      color: _filterInk,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _FiltrosAvanzadosDialog extends StatefulWidget {
  const _FiltrosAvanzadosDialog({
    required this.state,
    required this.modoPedido,
  });

  final CatalogoState state;
  final bool modoPedido;

  @override
  State<_FiltrosAvanzadosDialog> createState() =>
      _FiltrosAvanzadosDialogState();
}

class _FiltrosAvanzadosDialogState extends State<_FiltrosAvanzadosDialog> {
  late CatalogoFiltros _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.state.filtros;
  }

  List<String> _unique(Iterable<String> values) {
    final result =
        values
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return result;
  }

  List<String> get _companies =>
      _unique(widget.state.productos.map((item) => item.empresa));

  List<String> _brands(CatalogoFiltros filters) => _unique(
    widget.state.productos
        .where(
          (item) => filters.empresa == null || item.empresa == filters.empresa,
        )
        .map((item) => item.marca),
  );

  List<String> _categories(CatalogoFiltros filters) => _unique(
    widget.state.productos
        .where(
          (item) =>
              (filters.empresa == null || item.empresa == filters.empresa) &&
              (filters.marca == null || item.marca == filters.marca),
        )
        .map((item) => item.categoria),
  );

  List<String> _subcategories(CatalogoFiltros filters) => _unique(
    widget.state.productos
        .where(
          (item) =>
              (filters.empresa == null || item.empresa == filters.empresa) &&
              (filters.marca == null || item.marca == filters.marca) &&
              (filters.categoria == null ||
                  item.categoria == filters.categoria),
        )
        .map((item) => item.subcategoria),
  );

  CatalogoFiltros _normalize(CatalogoFiltros value) {
    var result = value;
    if (result.marca != null && !_brands(result).contains(result.marca)) {
      result = result.copyWith(clearMarca: true);
    }
    if (result.categoria != null &&
        !_categories(result).contains(result.categoria)) {
      result = result.copyWith(clearCategoria: true, clearSubcategoria: true);
    }

    final disponibles = _subcategories(result).toSet();
    final actuales = result.subcategoriasActivas;
    final validas = actuales.where(disponibles.contains).toSet();
    if (validas.length != actuales.length) {
      result = result.copyWith(subcategorias: validas, clearSubcategoria: true);
    }
    return result;
  }

  void _update(CatalogoFiltros value) {
    setState(() => _draft = _normalize(value));
  }

  @override
  Widget build(BuildContext context) {
    final brands = _brands(_draft);
    final categories = _categories(_draft);
    final subcategories = _subcategories(_draft);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
                color: _filterInk,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _filterYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.modoPedido
                                ? 'Filtros para el pedido'
                                : 'Más filtros del catálogo',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Combina origen comercial y clasificación sin '
                            'saturar la pantalla principal.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFB7BAC1),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _DialogSectionTitle(
                        'Origen comercial',
                        Icons.business_outlined,
                      ),
                      _DialogGrid(
                        children: [
                          _DialogSelect(
                            label: 'Empresa',
                            value: _companies.contains(_draft.empresa)
                                ? _draft.empresa
                                : null,
                            options: _companies,
                            allLabel: 'Todas las empresas',
                            onChanged: (value) => _update(
                              _draft.copyWith(
                                empresa: value,
                                clearEmpresa: value == null,
                              ),
                            ),
                          ),
                          _DialogSelect(
                            label: 'Marca',
                            value: brands.contains(_draft.marca)
                                ? _draft.marca
                                : null,
                            options: brands,
                            allLabel: _draft.empresa == null
                                ? 'Todas las marcas'
                                : 'Todas en ${_draft.empresa}',
                            onChanged: (value) => _update(
                              _draft.copyWith(
                                marca: value,
                                clearMarca: value == null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _DialogSectionTitle(
                        'Clasificación',
                        Icons.account_tree_outlined,
                      ),
                      _DialogGrid(
                        children: [
                          _DialogSelect(
                            label: 'Categoría',
                            value: categories.contains(_draft.categoria)
                                ? _draft.categoria
                                : null,
                            options: categories,
                            allLabel: 'Todas las categorías',
                            onChanged: (value) => _update(
                              _draft.copyWith(
                                categoria: value,
                                clearCategoria: value == null,
                              ),
                            ),
                          ),
                          _DialogMultiSelect(
                            key: const Key('dialog_subcategorias_multiple'),
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
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DialogSectionTitle(
                        widget.modoPedido
                            ? 'Condición de venta'
                            : 'Disponibilidad y contenido',
                        Icons.inventory_2_outlined,
                      ),
                      _DialogGrid(
                        children: [
                          if (!widget.modoPedido)
                            _DialogSelect(
                              label: 'Estado',
                              value: _draft.estado,
                              options: const ['Activo', 'Inactivo'],
                              allLabel: 'Todos los estados',
                              onChanged: (value) => _update(
                                _draft.copyWith(
                                  estado: value,
                                  clearEstado: value == null,
                                ),
                              ),
                            ),
                          _DialogSelect(
                            label: 'Precio',
                            value: _draft.precio,
                            options: const ['Con precio', 'Sin precio'],
                            allLabel: 'Con y sin precio',
                            onChanged: (value) => _update(
                              _draft.copyWith(
                                precio: value,
                                clearPrecio: value == null,
                              ),
                            ),
                          ),
                          if (!widget.modoPedido)
                            _DialogSelect(
                              label: 'Imagen',
                              value: _draft.imagen,
                              options: const ['Con imagen', 'Sin imagen'],
                              allLabel: 'Con y sin imagen',
                              onChanged: (value) => _update(
                                _draft.copyWith(
                                  imagen: value,
                                  clearImagen: value == null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(
                          () => _draft = CatalogoFiltros(orden: _draft.orden),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _filterMuted,
                          side: const BorderSide(color: _filterBorder),
                          minimumSize: const Size(0, 46),
                        ),
                        icon: const Icon(Icons.clear_all_rounded),
                        label: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('aplicar_filtros_avanzados'),
                        onPressed: () => Navigator.pop(context, _draft),
                        style: FilledButton.styleFrom(
                          backgroundColor: _filterYellow,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(0, 46),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text(
                          'Aplicar filtros',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogGrid extends StatelessWidget {
  const _DialogGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 560
          ? constraints.maxWidth
          : (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

class _DialogSectionTitle extends StatelessWidget {
  const _DialogSectionTitle(this.label, this.icon);

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _filterYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 9),
        Icon(icon, size: 18, color: _filterMuted),
        const SizedBox(width: 7),
        Text(
          label,
          style: GoogleFonts.inter(
            color: _filterInk,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _DialogMultiSelect extends StatelessWidget {
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
                              key: ValueKey('subcategoria_opcion_$option'),
                              value: draft.contains(option),
                              activeColor: _filterYellow,
                              checkColor: Colors.black,
                              controlAffinity: ListTileControlAffinity.leading,
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            const Icon(Icons.arrow_drop_down_rounded, color: _filterMuted),
          ],
        ),
      ),
    ),
  );
}

class _DialogSelect extends StatelessWidget {
  const _DialogSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.allLabel,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: ValueKey('dialog-$label-$value-${options.length}'),
    initialValue: options.contains(value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _filterSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _filterBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _filterYellow, width: 1.6),
      ),
    ),
    items: [
      DropdownMenuItem<String>(
        value: '__all__',
        child: Text(allLabel, overflow: TextOverflow.ellipsis),
      ),
      ...options.map(
        (item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis),
        ),
      ),
    ],
    onChanged: (selected) {
      onChanged(selected == '__all__' ? null : selected);
    },
  );
}

class _OrdenamientoDialog extends StatelessWidget {
  const _OrdenamientoDialog({
    required this.ordenActual,
    required this.modoPedido,
  });

  final String ordenActual;
  final bool modoPedido;

  @override
  Widget build(BuildContext context) {
    final options = modoPedido
        ? _orderOptions
              .where((item) => item.title != 'Activos primero')
              .toList()
        : _orderOptions;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
                color: _filterInk,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _filterYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.sort_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ordenar productos',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(18),
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final selected = ordenActual == option.title;
                    return Material(
                      color: selected
                          ? const Color(0xFFFFF8DD)
                          : _filterSurface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => Navigator.pop(context, option.title),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? _filterYellow : _filterBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(option.icon, color: _filterMuted),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.title,
                                      style: GoogleFonts.inter(
                                        color: _filterInk,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      option.subtitle,
                                      style: GoogleFonts.inter(
                                        color: _filterMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: selected ? _filterYellow : _filterBorder,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderOption {
  const _OrderOption(this.title, this.icon, this.subtitle);

  final String title;
  final IconData icon;
  final String subtitle;
}

const _orderOptions = [
  _OrderOption('Nombre A-Z', Icons.sort_by_alpha, 'Alfabético ascendente'),
  _OrderOption('Nombre Z-A', Icons.sort_by_alpha, 'Alfabético descendente'),
  _OrderOption(
    'Precio menor a mayor',
    Icons.arrow_upward_rounded,
    'Más económico primero',
  ),
  _OrderOption(
    'Precio mayor a menor',
    Icons.arrow_downward_rounded,
    'Mayor precio primero',
  ),
  _OrderOption(
    'Más recientes',
    Icons.access_time_rounded,
    'Últimos productos agregados',
  ),
  _OrderOption(
    'Activos primero',
    Icons.check_circle_outline_rounded,
    'Productos activos al inicio',
  ),
];
