import 'package:flutter/material.dart';

part '../forms/category_attribute_editor.dart';
part '../models/category_attribute_models.dart';
part '../widgets/category_attributes/category_attribute_common_widgets.dart';
part '../widgets/category_attributes/category_attribute_fields.dart';
part '../widgets/category_attributes/category_attribute_table.dart';

// ============================================================================
// CATEGORÍAS > GESTIONAR ATRIBUTOS
//
// Subpantalla autocontenida para tablet y móvil.
//
// Reglas principales:
// - Los atributos heredados son de solo lectura.
// - Los atributos propios se editan y ordenan en esta categoría.
// - La categoría habilita un atributo como posible eje; el producto decide si
//   realmente lo utiliza como eje.
// - Los atributos y opciones utilizados se desactivan, no se eliminan.
// - Cada atributo se guarda desde su editor. El orden se guarda por separado.
// ============================================================================

const _yellow = Color(0xFFFFC500);
const _background = Color(0xFFF4F6F8);
const _border = Color(0xFFDCE1E7);
const _text = Color(0xFF20242A);
const _muted = Color(0xFF697386);
const _green = Color(0xFF168A50);
const _greenSoft = Color(0xFFE6F6EE);
const _red = Color(0xFFB42318);
const _redSoft = Color(0xFFFEECEB);
const _blueSoft = Color(0xFFFFF4CC);

ThemeData _attributeManagerTheme(BuildContext context) {
  final base = Theme.of(context);
  const overlay = Color(0x26FFC500);
  const focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: _yellow, width: 1.6),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: _yellow,
      onPrimary: Colors.black,
      secondary: _yellow,
      onSecondary: Colors.black,
      surfaceTint: _yellow,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _yellow,
        foregroundColor: Colors.black,
        overlayColor: overlay,
        shadowColor: const Color(0x52FFC500),
        elevation: 1,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _text,
        side: const BorderSide(color: _yellow),
        overlayColor: overlay,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _text,
        overlayColor: overlay,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: const Color(0xFFFFF4CC),
      checkmarkColor: Colors.black,
      side: const BorderSide(color: _yellow),
      labelStyle: const TextStyle(color: _text),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: Colors.white,
      focusedBorder: focusedBorder,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _border),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: _border),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
  );
}

class CategoryAttributesManagerPage extends StatefulWidget {
  const CategoryAttributesManagerPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryPath,
    required this.attributes,
    this.units = demoUnits,
    this.onBack,
    this.onAttributesChanged,
    this.onSaveOrder,
    this.onOpenOwnerCategory,
    this.onShowAffectedProducts,
    this.reservedNamesInDescendants = const {},
    this.reservedKeysInDescendants = const {},
  });

  final String categoryId;
  final String categoryName;
  final List<String> categoryPath;
  final List<CategoryAttributeDefinition> attributes;
  final List<AttributeUnit> units;
  final VoidCallback? onBack;
  final ValueChanged<List<CategoryAttributeDefinition>>? onAttributesChanged;
  final ValueChanged<List<String>>? onSaveOrder;
  final ValueChanged<String>? onOpenOwnerCategory;
  final ValueChanged<String>? onShowAffectedProducts;

  /// Deben venir del repositorio al editar una categoría superior. Evitan
  /// crear un nombre o clave que ya existe en cualquier descendiente.
  final Set<String> reservedNamesInDescendants;
  final Set<String> reservedKeysInDescendants;

  static const demoUnits = <AttributeUnit>[
    AttributeUnit(
      code: 'mm',
      label: 'Milímetro (mm)',
      magnitude: 'Longitud',
      factorToBase: 1,
    ),
    AttributeUnit(
      code: 'in',
      label: 'Pulgada (pulgada)',
      magnitude: 'Longitud',
      factorToBase: 25.4,
    ),
    AttributeUnit(
      code: 'cm',
      label: 'Centímetro (cm)',
      magnitude: 'Longitud',
      factorToBase: 10,
    ),
    AttributeUnit(
      code: 'g',
      label: 'Gramo (g)',
      magnitude: 'Masa',
      factorToBase: 1,
    ),
    AttributeUnit(
      code: 'kg',
      label: 'Kilogramo (kg)',
      magnitude: 'Masa',
      factorToBase: 1000,
    ),
  ];

  factory CategoryAttributesManagerPage.demo({Key? key}) {
    const categoryId = 'drill-bits';
    return CategoryAttributesManagerPage(
      key: key,
      categoryId: categoryId,
      categoryName: 'Brocas',
      categoryPath: const ['Herramientas', 'Accesorios', 'Brocas'],
      attributes: const [
        CategoryAttributeDefinition(
          id: 'attr-main-material',
          ownerCategoryId: 'accessories',
          ownerCategoryName: 'Accesorios',
          name: 'Material principal',
          keyName: 'material_principal',
          helpText: 'Material predominante del producto.',
          dataType: CategoryAttributeDataType.singleList,
          captureLevel: AttributeCaptureLevel.family,
          requiredToActivate: true,
          visibleInTechnicalSheet: true,
          filterable: true,
          canBeVariantAxis: false,
          activeForNewProducts: true,
          order: 0,
          active: true,
          inherited: true,
          usedByProductCount: 142,
          affectedCategoryCount: 4,
          options: [
            CategoryAttributeOption(
              id: 'hss',
              label: 'HSS',
              code: 'hss',
              active: true,
              usedByProductCount: 72,
            ),
            CategoryAttributeOption(
              id: 'cobalt',
              label: 'Cobalto',
              code: 'cobalto',
              active: true,
              usedByProductCount: 28,
            ),
            CategoryAttributeOption(
              id: 'carbide',
              label: 'Carburo',
              code: 'carburo',
              active: true,
              usedByProductCount: 42,
            ),
          ],
        ),
        CategoryAttributeDefinition(
          id: 'attr-brand-line',
          ownerCategoryId: 'accessories',
          ownerCategoryName: 'Accesorios',
          name: 'Línea del fabricante',
          keyName: 'linea_fabricante',
          dataType: CategoryAttributeDataType.shortText,
          captureLevel: AttributeCaptureLevel.family,
          requiredToActivate: false,
          visibleInTechnicalSheet: true,
          filterable: false,
          canBeVariantAxis: false,
          activeForNewProducts: true,
          order: 1,
          active: true,
          inherited: true,
          usedByProductCount: 38,
        ),
        CategoryAttributeDefinition(
          id: 'attr-diameter',
          ownerCategoryId: categoryId,
          ownerCategoryName: 'Brocas',
          name: 'Diámetro',
          keyName: 'diametro',
          helpText: 'Indica el diámetro nominal de la broca.',
          dataType: CategoryAttributeDataType.numberWithUnit,
          captureLevel: AttributeCaptureLevel.variant,
          requiredToActivate: true,
          visibleInTechnicalSheet: true,
          filterable: true,
          canBeVariantAxis: true,
          activeForNewProducts: true,
          order: 0,
          active: true,
          inherited: false,
          minimum: 0.5,
          maximum: 80,
          decimals: 2,
          magnitude: 'Longitud',
          allowedUnitCodes: ['mm', 'in'],
          defaultUnitCode: 'mm',
          usedByProductCount: 96,
          affectedCategoryCount: 3,
          usedAsAxisByProductCount: 18,
        ),
        CategoryAttributeDefinition(
          id: 'attr-total-length',
          ownerCategoryId: categoryId,
          ownerCategoryName: 'Brocas',
          name: 'Longitud total',
          keyName: 'longitud_total',
          helpText: 'Longitud total de extremo a extremo.',
          dataType: CategoryAttributeDataType.numberWithUnit,
          captureLevel: AttributeCaptureLevel.decideWhenRegistering,
          requiredToActivate: false,
          visibleInTechnicalSheet: true,
          filterable: true,
          canBeVariantAxis: true,
          activeForNewProducts: true,
          order: 1,
          active: true,
          inherited: false,
          minimum: 1,
          maximum: 1000,
          decimals: 2,
          magnitude: 'Longitud',
          allowedUnitCodes: ['mm', 'in'],
          defaultUnitCode: 'mm',
          usedByProductCount: 84,
          affectedCategoryCount: 3,
          usedAsAxisByProductCount: 4,
        ),
        CategoryAttributeDefinition(
          id: 'attr-shank',
          ownerCategoryId: categoryId,
          ownerCategoryName: 'Brocas',
          name: 'Tipo de vástago',
          keyName: 'tipo_vastago',
          dataType: CategoryAttributeDataType.singleList,
          captureLevel: AttributeCaptureLevel.family,
          requiredToActivate: false,
          visibleInTechnicalSheet: true,
          filterable: true,
          canBeVariantAxis: false,
          activeForNewProducts: true,
          order: 2,
          active: true,
          inherited: false,
          usedByProductCount: 60,
          affectedCategoryCount: 3,
          options: [
            CategoryAttributeOption(
              id: 'cylindrical',
              label: 'Cilíndrico',
              code: 'cilindrico',
              active: true,
            ),
            CategoryAttributeOption(
              id: 'hexagonal',
              label: 'Hexagonal',
              code: 'hexagonal',
              active: true,
            ),
            CategoryAttributeOption(
              id: 'sds-plus',
              label: 'SDS Plus',
              code: 'sds_plus',
              active: true,
            ),
          ],
        ),
        CategoryAttributeDefinition(
          id: 'attr-use',
          ownerCategoryId: categoryId,
          ownerCategoryName: 'Brocas',
          name: 'Uso recomendado',
          keyName: 'uso_recomendado',
          dataType: CategoryAttributeDataType.multipleList,
          captureLevel: AttributeCaptureLevel.family,
          requiredToActivate: false,
          visibleInTechnicalSheet: true,
          filterable: false,
          canBeVariantAxis: false,
          activeForNewProducts: true,
          order: 3,
          active: true,
          inherited: false,
          maximumSelections: 4,
          usedByProductCount: 52,
          affectedCategoryCount: 3,
          options: [
            CategoryAttributeOption(
              id: 'metal',
              label: 'Metal',
              code: 'metal',
              active: true,
            ),
            CategoryAttributeOption(
              id: 'steel',
              label: 'Acero',
              code: 'acero',
              active: true,
            ),
            CategoryAttributeOption(
              id: 'wood',
              label: 'Madera',
              code: 'madera',
              active: true,
            ),
          ],
        ),
        CategoryAttributeDefinition(
          id: 'attr-working-length',
          ownerCategoryId: categoryId,
          ownerCategoryName: 'Brocas',
          name: 'Longitud útil',
          keyName: 'longitud_util',
          dataType: CategoryAttributeDataType.numberWithUnit,
          captureLevel: AttributeCaptureLevel.variant,
          requiredToActivate: false,
          visibleInTechnicalSheet: true,
          filterable: false,
          canBeVariantAxis: false,
          activeForNewProducts: true,
          order: 4,
          active: true,
          inherited: false,
          decimals: 2,
          magnitude: 'Longitud',
          allowedUnitCodes: ['mm', 'in'],
          defaultUnitCode: 'mm',
          usedByProductCount: 34,
          affectedCategoryCount: 3,
        ),
        CategoryAttributeDefinition(
          id: 'attr-old-standard',
          ownerCategoryId: categoryId,
          ownerCategoryName: 'Brocas',
          name: 'Norma anterior',
          keyName: 'norma_anterior',
          dataType: CategoryAttributeDataType.shortText,
          captureLevel: AttributeCaptureLevel.family,
          requiredToActivate: false,
          visibleInTechnicalSheet: true,
          filterable: false,
          canBeVariantAxis: false,
          activeForNewProducts: false,
          order: 5,
          active: false,
          inherited: false,
          usedByProductCount: 12,
          affectedCategoryCount: 3,
          syncState: AttributeSyncState.pending,
        ),
      ],
    );
  }

  @override
  State<CategoryAttributesManagerPage> createState() =>
      _CategoryAttributesManagerPageState();
}

class _CategoryAttributesManagerPageState
    extends State<CategoryAttributesManagerPage> {
  late List<CategoryAttributeDefinition> _attributes;
  final _searchController = TextEditingController();
  AttributeListFilter _filter = AttributeListFilter.all;
  String? _editorAttributeId;
  bool _creating = false;
  bool _reordering = false;
  bool _orderDirty = false;

  @override
  void initState() {
    super.initState();
    _attributes = [...widget.attributes];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryAttributeDefinition> get _effectiveAttributes {
    return _attributes
        .where(
          (attribute) =>
              attribute.ownerCategoryId == widget.categoryId ||
              attribute.inherited,
        )
        .toList();
  }

  List<CategoryAttributeDefinition> get _filteredAttributes {
    final query = _searchController.text.trim().toLowerCase();
    return _effectiveAttributes.where((attribute) {
      final matchesQuery =
          query.isEmpty || attribute.name.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        AttributeListFilter.all => true,
        AttributeListFilter.own => !attribute.inherited,
        AttributeListFilter.inherited => attribute.inherited,
        AttributeListFilter.inactive => !attribute.active,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  CategoryAttributeDefinition? get _editingAttribute {
    final id = _editorAttributeId;
    if (id == null) return null;
    for (final attribute in _attributes) {
      if (attribute.id == id) return attribute;
    }
    return null;
  }

  bool get _editorOpen => _creating || _editingAttribute != null;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _attributeManagerTheme(context),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final compactEditor = !wide;
              if (compactEditor && _editorOpen) {
                return _buildCompactEditor();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 24 : 16,
                        16,
                        wide ? 24 : 16,
                        20,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildListPanel()),
                          if (wide && _editorOpen) ...[
                            const SizedBox(width: 16),
                            SizedBox(width: 470, child: _buildEditorPanel()),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final ownCount = _effectiveAttributes
        .where((item) => !item.inherited)
        .length;
    final inheritedCount = _effectiveAttributes
        .where((item) => item.inherited)
        .length;
    final hasPendingSync = _effectiveAttributes.any(
      (item) => item.syncState == AttributeSyncState.pending,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;

          final heading = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: 'Volver a categorías',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed:
                    widget.onBack ??
                    () {
                      Navigator.maybePop(context);
                    },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestionar atributos · ${widget.categoryName}',
                      softWrap: true,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Define los datos técnicos que se solicitarán al '
                      'registrar productos de esta categoría.',
                      softWrap: true,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _SecondaryButton(
                label: 'Vista previa del formulario',
                icon: Icons.visibility_outlined,
                onPressed: _showFormPreview,
              ),
              _PrimaryButton(
                label: 'Nuevo atributo',
                icon: Icons.add_rounded,
                onPressed: _startCreating,
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                heading,
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: actions,
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 20),
                    Flexible(child: actions),
                  ],
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _InfoPill(
                    icon: Icons.account_tree_outlined,
                    label: 'Ruta: ${widget.categoryPath.join(' > ')}',
                  ),
                  _InfoPill(
                    icon: Icons.data_object_rounded,
                    label:
                        '${_effectiveAttributes.length} atributos · '
                        '$ownCount propios · $inheritedCount heredados',
                  ),
                  if (hasPendingSync)
                    const _InfoPill(
                      icon: Icons.cloud_upload_outlined,
                      label:
                          'Guardada localmente · Pendiente de sincronización',
                      background: Color(0xFFFFF4CC),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListPanel() {
    final filtered = _filteredAttributes;
    final inherited = filtered
        .where((attribute) => attribute.inherited)
        .toList();
    final own = filtered.where((attribute) => !attribute.inherited).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 760;
                final search = TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar atributo',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                final controls = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...AttributeListFilter.values.map(
                      (filter) => _FilterChip(
                        label: _filterLabel(filter),
                        selected: _filter == filter,
                        onSelected: () {
                          setState(() => _filter = filter);
                        },
                      ),
                    ),
                    _SecondaryButton(
                      label: _reordering ? 'Cancelar orden' : 'Reordenar',
                      icon: Icons.reorder_rounded,
                      onPressed: () {
                        setState(() {
                          _reordering = !_reordering;
                          if (!_reordering) _orderDirty = false;
                        });
                      },
                    ),
                    if (_reordering)
                      _PrimaryButton(
                        label: 'Guardar orden',
                        icon: Icons.save_outlined,
                        onPressed: _orderDirty ? _saveOrder : null,
                      ),
                  ],
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [search, const SizedBox(height: 10), controls],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 12),
                    Flexible(flex: 2, child: controls),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState(
                    title: 'No se encontraron atributos',
                    message: 'Cambia la búsqueda o el filtro seleccionado.',
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (inherited.isNotEmpty)
                          _buildAttributeSection(
                            title: 'Heredados de la categoría superior',
                            subtitle: 'Solo lectura',
                            attributes: inherited,
                            inherited: true,
                          ),
                        if (inherited.isNotEmpty && own.isNotEmpty)
                          const SizedBox(height: 20),
                        if (own.isNotEmpty)
                          _buildAttributeSection(
                            title: 'Propios de ${widget.categoryName}',
                            subtitle: _reordering
                                ? 'Arrastra para ordenar'
                                : 'Editables',
                            attributes: own,
                            inherited: false,
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeSection({
    required String title,
    required String subtitle,
    required List<CategoryAttributeDefinition> attributes,
    required bool inherited,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _InfoPill(label: '$subtitle · ${attributes.length}'),
          ],
        ),
        const SizedBox(height: 10),
        const _AttributeTableHeader(),
        if (_reordering && !inherited)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: attributes.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final ordered = [...attributes];
              final moved = ordered.removeAt(oldIndex);
              ordered.insert(newIndex, moved);
              setState(() {
                for (var index = 0; index < ordered.length; index++) {
                  final sourceIndex = _attributes.indexWhere(
                    (item) => item.id == ordered[index].id,
                  );
                  _attributes[sourceIndex] = _attributes[sourceIndex].copyWith(
                    order: index,
                  );
                }
                _orderDirty = true;
              });
            },
            itemBuilder: (context, index) {
              final attribute = attributes[index];
              return _AttributeRow(
                key: ValueKey(attribute.id),
                attribute: attribute,
                selected: _editorAttributeId == attribute.id,
                reorderIndex: index,
                onOpen: () => _openAttribute(attribute),
              );
            },
          )
        else
          ...attributes.map(
            (attribute) => _AttributeRow(
              key: ValueKey(attribute.id),
              attribute: attribute,
              selected: _editorAttributeId == attribute.id,
              onOpen: () => _openAttribute(attribute),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Volver a atributos',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: _closeEditor,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _creating
                      ? 'Nuevo atributo'
                      : 'Editar atributo · ${_editingAttribute?.name ?? ''}',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _buildEditorPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorPanel() {
    final attribute = _editingAttribute;
    return _AttributeEditor(
      key: ValueKey(_creating ? 'new' : attribute?.id),
      categoryId: widget.categoryId,
      categoryName: widget.categoryName,
      attribute: attribute,
      readOnly: attribute?.inherited ?? false,
      units: widget.units,
      reservedNames:
          _effectiveAttributes
              .where((item) => item.id != attribute?.id)
              .map((item) => _canonicalAttributeIdentity(item.name))
              .toSet()
            ..addAll(
              widget.reservedNamesInDescendants.map(
                _canonicalAttributeIdentity,
              ),
            ),
      reservedKeys:
          _effectiveAttributes
              .where((item) => item.id != attribute?.id)
              .map((item) => item.keyName.toLowerCase())
              .toSet()
            ..addAll(
              widget.reservedKeysInDescendants.map(
                (value) => value.toLowerCase(),
              ),
            ),
      onCancel: _closeEditor,
      onSave: _saveAttribute,
      onDelete: attribute == null ? null : () => _deleteAttribute(attribute),
      onOpenOwnerCategory: attribute?.inherited == true
          ? () => _openOwnerCategory(attribute!)
          : null,
      onShowAffectedProducts: attribute == null
          ? null
          : () => _showAffectedProducts(attribute),
    );
  }

  void _startCreating() {
    setState(() {
      _creating = true;
      _editorAttributeId = null;
    });
  }

  void _openAttribute(CategoryAttributeDefinition attribute) {
    setState(() {
      _creating = false;
      _editorAttributeId = attribute.id;
    });
  }

  void _closeEditor() {
    setState(() {
      _creating = false;
      _editorAttributeId = null;
    });
  }

  void _saveAttribute(CategoryAttributeDefinition attribute) {
    setState(() {
      final index = _attributes.indexWhere((item) => item.id == attribute.id);
      if (index < 0) {
        final ownCount = _attributes
            .where((item) => item.ownerCategoryId == widget.categoryId)
            .length;
        _attributes.add(attribute.copyWith(order: ownCount));
      } else {
        _attributes[index] = attribute;
      }
      _creating = false;
      _editorAttributeId = attribute.id;
    });
    widget.onAttributesChanged?.call(List.unmodifiable(_attributes));
    _showMessage(
      attribute.syncState == AttributeSyncState.pending
          ? 'Guardado localmente. Queda pendiente de sincronización.'
          : 'Atributo guardado.',
    );
  }

  Future<void> _deleteAttribute(CategoryAttributeDefinition attribute) async {
    if (attribute.inherited) return;
    if (attribute.usedByProductCount > 0) {
      _showMessage(
        'Este atributo está utilizado por ${attribute.usedByProductCount} '
        'productos. Desactívalo en lugar de eliminarlo.',
        error: true,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar atributo'),
        content: Text(
          'Se eliminará “${attribute.name}”. Esta acción solo está disponible '
          'porque todavía no tiene valores registrados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _attributes.removeWhere((item) => item.id == attribute.id);
      _creating = false;
      _editorAttributeId = null;
    });
    widget.onAttributesChanged?.call(List.unmodifiable(_attributes));
  }

  void _saveOrder() {
    final own =
        _attributes
            .where((item) => item.ownerCategoryId == widget.categoryId)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    widget.onSaveOrder?.call(own.map((item) => item.id).toList());
    widget.onAttributesChanged?.call(List.unmodifiable(_attributes));
    setState(() {
      _orderDirty = false;
      _reordering = false;
    });
    _showMessage('Orden guardado.');
  }

  void _openOwnerCategory(CategoryAttributeDefinition attribute) {
    final callback = widget.onOpenOwnerCategory;
    if (callback != null) {
      callback(attribute.ownerCategoryId);
      return;
    }
    _showMessage(
      'Abre la categoría propietaria: ${attribute.ownerCategoryName}.',
    );
  }

  void _showAffectedProducts(CategoryAttributeDefinition attribute) {
    final callback = widget.onShowAffectedProducts;
    if (callback != null) {
      callback(attribute.id);
      return;
    }
    _showMessage(
      '${attribute.usedByProductCount} productos usan ${attribute.name}.',
    );
  }

  Future<void> _showFormPreview() async {
    final visible =
        _effectiveAttributes
            .where((item) => item.active && item.activeForNewProducts)
            .toList()
          ..sort((a, b) {
            if (a.inherited != b.inherited) return a.inherited ? -1 : 1;
            return a.order.compareTo(b.order);
          });
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vista previa del formulario',
                            style: TextStyle(
                              color: _text,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Registro de producto · ${widget.categoryName}',
                            style: const TextStyle(color: _muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _PreviewField(attribute: visible[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? _red : _text),
    );
  }
}
