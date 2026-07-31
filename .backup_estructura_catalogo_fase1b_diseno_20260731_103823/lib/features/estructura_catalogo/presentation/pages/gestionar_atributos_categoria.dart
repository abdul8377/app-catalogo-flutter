import 'package:flutter/material.dart';

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
const _blue = Color(0xFF2563EB);
const _blueSoft = Color(0xFFEFF6FF);

enum CategoryAttributeDataType {
  shortText,
  number,
  numberWithUnit,
  singleList,
  multipleList,
  yesNo,
}

enum AttributeCaptureLevel { family, variant, decideWhenRegistering }

enum AttributeListFilter { all, own, inherited, inactive }

enum AttributeSyncState { synced, pending }

@immutable
class AttributeUnit {
  const AttributeUnit({
    required this.code,
    required this.label,
    required this.magnitude,
    required this.factorToBase,
  });

  final String code;
  final String label;
  final String magnitude;

  /// Convierte el valor escrito a la unidad base de la magnitud.
  /// Para longitud, la unidad base usada en este ejemplo es milímetro.
  final double factorToBase;
}

@immutable
class CategoryAttributeOption {
  const CategoryAttributeOption({
    required this.id,
    required this.label,
    required this.code,
    required this.active,
    this.usedByProductCount = 0,
  });

  final String id;
  final String label;
  final String code;
  final bool active;
  final int usedByProductCount;

  CategoryAttributeOption copyWith({
    String? label,
    String? code,
    bool? active,
    int? usedByProductCount,
  }) {
    return CategoryAttributeOption(
      id: id,
      label: label ?? this.label,
      code: code ?? this.code,
      active: active ?? this.active,
      usedByProductCount: usedByProductCount ?? this.usedByProductCount,
    );
  }
}

@immutable
class CategoryAttributeDefinition {
  const CategoryAttributeDefinition({
    required this.id,
    required this.ownerCategoryId,
    required this.ownerCategoryName,
    required this.name,
    required this.keyName,
    required this.dataType,
    required this.captureLevel,
    required this.requiredToActivate,
    required this.visibleInTechnicalSheet,
    required this.filterable,
    required this.canBeVariantAxis,
    required this.activeForNewProducts,
    required this.order,
    required this.active,
    required this.inherited,
    this.helpText,
    this.textMaxLength,
    this.example,
    this.minimum,
    this.maximum,
    this.decimals = 0,
    this.magnitude,
    this.allowedUnitCodes = const [],
    this.defaultUnitCode,
    this.options = const [],
    this.maximumSelections,
    this.trueLabel,
    this.falseLabel,
    this.usedByProductCount = 0,
    this.affectedCategoryCount = 0,
    this.usedAsAxisByProductCount = 0,
    this.syncState = AttributeSyncState.synced,
  });

  final String id;
  final String ownerCategoryId;
  final String ownerCategoryName;
  final String name;
  final String keyName;
  final String? helpText;
  final CategoryAttributeDataType dataType;
  final AttributeCaptureLevel captureLevel;
  final bool requiredToActivate;
  final bool visibleInTechnicalSheet;
  final bool filterable;
  final bool canBeVariantAxis;
  final bool activeForNewProducts;
  final int order;
  final bool active;
  final bool inherited;

  final int? textMaxLength;
  final String? example;
  final double? minimum;
  final double? maximum;
  final int decimals;
  final String? magnitude;
  final List<String> allowedUnitCodes;
  final String? defaultUnitCode;
  final List<CategoryAttributeOption> options;
  final int? maximumSelections;
  final String? trueLabel;
  final String? falseLabel;

  final int usedByProductCount;
  final int affectedCategoryCount;
  final int usedAsAxisByProductCount;
  final AttributeSyncState syncState;

  bool get structureLocked => usedByProductCount > 0;

  bool get supportsVariantAxis {
    return dataType == CategoryAttributeDataType.number ||
        dataType == CategoryAttributeDataType.numberWithUnit ||
        dataType == CategoryAttributeDataType.singleList;
  }

  CategoryAttributeDefinition copyWith({
    String? ownerCategoryId,
    String? ownerCategoryName,
    String? name,
    String? keyName,
    String? helpText,
    bool clearHelpText = false,
    CategoryAttributeDataType? dataType,
    AttributeCaptureLevel? captureLevel,
    bool? requiredToActivate,
    bool? visibleInTechnicalSheet,
    bool? filterable,
    bool? canBeVariantAxis,
    bool? activeForNewProducts,
    int? order,
    bool? active,
    bool? inherited,
    int? textMaxLength,
    bool clearTextMaxLength = false,
    String? example,
    bool clearExample = false,
    double? minimum,
    bool clearMinimum = false,
    double? maximum,
    bool clearMaximum = false,
    int? decimals,
    String? magnitude,
    bool clearMagnitude = false,
    List<String>? allowedUnitCodes,
    String? defaultUnitCode,
    bool clearDefaultUnitCode = false,
    List<CategoryAttributeOption>? options,
    int? maximumSelections,
    bool clearMaximumSelections = false,
    String? trueLabel,
    bool clearTrueLabel = false,
    String? falseLabel,
    bool clearFalseLabel = false,
    int? usedByProductCount,
    int? affectedCategoryCount,
    int? usedAsAxisByProductCount,
    AttributeSyncState? syncState,
  }) {
    return CategoryAttributeDefinition(
      id: id,
      ownerCategoryId: ownerCategoryId ?? this.ownerCategoryId,
      ownerCategoryName: ownerCategoryName ?? this.ownerCategoryName,
      name: name ?? this.name,
      keyName: keyName ?? this.keyName,
      helpText: clearHelpText ? null : helpText ?? this.helpText,
      dataType: dataType ?? this.dataType,
      captureLevel: captureLevel ?? this.captureLevel,
      requiredToActivate: requiredToActivate ?? this.requiredToActivate,
      visibleInTechnicalSheet:
          visibleInTechnicalSheet ?? this.visibleInTechnicalSheet,
      filterable: filterable ?? this.filterable,
      canBeVariantAxis: canBeVariantAxis ?? this.canBeVariantAxis,
      activeForNewProducts: activeForNewProducts ?? this.activeForNewProducts,
      order: order ?? this.order,
      active: active ?? this.active,
      inherited: inherited ?? this.inherited,
      textMaxLength: clearTextMaxLength
          ? null
          : textMaxLength ?? this.textMaxLength,
      example: clearExample ? null : example ?? this.example,
      minimum: clearMinimum ? null : minimum ?? this.minimum,
      maximum: clearMaximum ? null : maximum ?? this.maximum,
      decimals: decimals ?? this.decimals,
      magnitude: clearMagnitude ? null : magnitude ?? this.magnitude,
      allowedUnitCodes: allowedUnitCodes ?? this.allowedUnitCodes,
      defaultUnitCode: clearDefaultUnitCode
          ? null
          : defaultUnitCode ?? this.defaultUnitCode,
      options: options ?? this.options,
      maximumSelections: clearMaximumSelections
          ? null
          : maximumSelections ?? this.maximumSelections,
      trueLabel: clearTrueLabel ? null : trueLabel ?? this.trueLabel,
      falseLabel: clearFalseLabel ? null : falseLabel ?? this.falseLabel,
      usedByProductCount: usedByProductCount ?? this.usedByProductCount,
      affectedCategoryCount:
          affectedCategoryCount ?? this.affectedCategoryCount,
      usedAsAxisByProductCount:
          usedAsAxisByProductCount ?? this.usedAsAxisByProductCount,
      syncState: syncState ?? this.syncState,
    );
  }
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
          query.isEmpty ||
          attribute.name.toLowerCase().contains(query) ||
          attribute.keyName.toLowerCase().contains(query);
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
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            final compactEditor = constraints.maxWidth < 860;
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
                          SizedBox(width: 430, child: _buildEditorPanel()),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                      style: const TextStyle(
                        color: _text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Define los datos técnicos que se solicitarán al registrar '
                      'productos de esta categoría.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
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
              ),
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
                  label: 'Guardada localmente · Pendiente de sincronización',
                  background: Color(0xFFFFF4CC),
                ),
            ],
          ),
        ],
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
                    hintText: 'Buscar por nombre o clave',
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

class _AttributeEditor extends StatefulWidget {
  const _AttributeEditor({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.attribute,
    required this.readOnly,
    required this.units,
    required this.reservedNames,
    required this.reservedKeys,
    required this.onCancel,
    required this.onSave,
    this.onDelete,
    this.onOpenOwnerCategory,
    this.onShowAffectedProducts,
  });

  final String categoryId;
  final String categoryName;
  final CategoryAttributeDefinition? attribute;
  final bool readOnly;
  final List<AttributeUnit> units;
  final Set<String> reservedNames;
  final Set<String> reservedKeys;
  final VoidCallback onCancel;
  final ValueChanged<CategoryAttributeDefinition> onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenOwnerCategory;
  final VoidCallback? onShowAffectedProducts;

  @override
  State<_AttributeEditor> createState() => _AttributeEditorState();
}

class _AttributeEditorState extends State<_AttributeEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _keyController;
  late final TextEditingController _helpController;
  late final TextEditingController _textLengthController;
  late final TextEditingController _exampleController;
  late final TextEditingController _minimumController;
  late final TextEditingController _maximumController;
  late final TextEditingController _decimalsController;
  late final TextEditingController _maximumSelectionsController;
  late final TextEditingController _trueLabelController;
  late final TextEditingController _falseLabelController;

  late CategoryAttributeDataType _type;
  late AttributeCaptureLevel _captureLevel;
  late bool _requiredToActivate;
  late bool _visibleInTechnicalSheet;
  late bool _filterable;
  late bool _canBeVariantAxis;
  late bool _activeForNewProducts;
  late bool _active;
  late String? _magnitude;
  late List<String> _allowedUnits;
  late String? _defaultUnit;
  late List<CategoryAttributeOption> _options;
  bool _keyEditedManually = false;

  CategoryAttributeDefinition? get _source => widget.attribute;
  bool get _structureLocked => _source?.structureLocked ?? false;

  @override
  void initState() {
    super.initState();
    final source = _source;
    _nameController = TextEditingController(text: source?.name);
    _keyController = TextEditingController(text: source?.keyName);
    _helpController = TextEditingController(text: source?.helpText);
    _textLengthController = TextEditingController(
      text: source?.textMaxLength?.toString(),
    );
    _exampleController = TextEditingController(text: source?.example);
    _minimumController = TextEditingController(
      text: source?.minimum?.toString(),
    );
    _maximumController = TextEditingController(
      text: source?.maximum?.toString(),
    );
    _decimalsController = TextEditingController(
      text: (source?.decimals ?? 0).toString(),
    );
    _maximumSelectionsController = TextEditingController(
      text: source?.maximumSelections?.toString(),
    );
    _trueLabelController = TextEditingController(text: source?.trueLabel);
    _falseLabelController = TextEditingController(text: source?.falseLabel);

    _type = source?.dataType ?? CategoryAttributeDataType.shortText;
    _captureLevel =
        source?.captureLevel ?? AttributeCaptureLevel.decideWhenRegistering;
    _requiredToActivate = source?.requiredToActivate ?? false;
    _visibleInTechnicalSheet = source?.visibleInTechnicalSheet ?? true;
    _filterable = source?.filterable ?? false;
    _canBeVariantAxis = source?.canBeVariantAxis ?? false;
    _activeForNewProducts = source?.activeForNewProducts ?? true;
    _active = source?.active ?? true;
    _magnitude = source?.magnitude;
    _allowedUnits = [...?source?.allowedUnitCodes];
    _defaultUnit = source?.defaultUnitCode;
    _options = [...?source?.options];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _helpController.dispose();
    _textLengthController.dispose();
    _exampleController.dispose();
    _minimumController.dispose();
    _maximumController.dispose();
    _decimalsController.dispose();
    _maximumSelectionsController.dispose();
    _trueLabelController.dispose();
    _falseLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.readOnly;
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
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _source == null
                            ? 'Nuevo atributo'
                            : readOnly
                            ? 'Ver atributo heredado'
                            : 'Editar atributo',
                        style: const TextStyle(
                          color: _text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        readOnly
                            ? 'Propietaria: ${_source?.ownerCategoryName}'
                            : 'Categoría: ${widget.categoryName}',
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar editor',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  if (readOnly)
                    _Notice(
                      text:
                          'Este atributo se hereda automáticamente. Para modificar '
                          'su estructura, abre ${_source?.ownerCategoryName}.',
                      actionLabel: 'Editar en categoría propietaria',
                      onAction: widget.onOpenOwnerCategory,
                    ),
                  if (_structureLocked && !readOnly)
                    _Notice(
                      text:
                          'Usado por ${_source?.usedByProductCount} productos. '
                          'El tipo, la clave y las unidades quedan protegidos.',
                      actionLabel: 'Ver productos afectados',
                      onAction: widget.onShowAffectedProducts,
                    ),
                  if (!readOnly && (_source?.affectedCategoryCount ?? 0) > 0)
                    _Notice(
                      text:
                          'Los cambios de comportamiento se reflejarán en '
                          '${_source!.affectedCategoryCount} categorías '
                          'descendientes y en sus formularios de registro.',
                    ),
                  const _SectionTitle('Información básica'),
                  TextFormField(
                    controller: _nameController,
                    enabled: !readOnly,
                    onChanged: (value) {
                      if (!_keyEditedManually && !_structureLocked) {
                        _keyController.text = _toKey(value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Nombre del atributo *',
                      hintText: 'Ej. Diámetro',
                    ),
                    validator: (value) {
                      final normalized = _canonicalAttributeIdentity(
                        value ?? '',
                      );
                      if (normalized.isEmpty) {
                        return 'El nombre es obligatorio.';
                      }
                      if (widget.reservedNames.contains(normalized)) {
                        return 'Ya existe en esta cadena de categorías.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _keyController,
                    enabled: !readOnly && !_structureLocked,
                    onChanged: (_) => _keyEditedManually = true,
                    decoration: InputDecoration(
                      labelText: 'Clave interna',
                      helperText: _structureLocked
                          ? 'Protegida porque el atributo ya tiene valores.'
                          : 'Se genera automáticamente y no se muestra al cliente.',
                    ),
                    validator: (value) {
                      final normalized = value?.trim().toLowerCase() ?? '';
                      if (normalized.isEmpty) {
                        return 'La clave interna es obligatoria.';
                      }
                      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(normalized)) {
                        return 'Usa minúsculas, números y guion bajo.';
                      }
                      if (widget.reservedKeys.contains(normalized)) {
                        return 'Ya existe en esta cadena de categorías.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _helpController,
                    enabled: !readOnly,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Texto de ayuda',
                      hintText: 'Indica el diámetro nominal de la broca.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CategoryAttributeDataType>(
                    value: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de dato *',
                    ),
                    items: CategoryAttributeDataType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_dataTypeLabel(type)),
                          ),
                        )
                        .toList(),
                    onChanged: readOnly || _structureLocked
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _type = value;
                              if (!_supportsAxis(value)) {
                                _canBeVariantAxis = false;
                              }
                            });
                          },
                  ),
                  const _SectionTitle('Comportamiento'),
                  DropdownButtonFormField<AttributeCaptureLevel>(
                    value: _captureLevel,
                    decoration: const InputDecoration(
                      labelText: 'Nivel de captura recomendado',
                    ),
                    items: AttributeCaptureLevel.values
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(_captureLevelLabel(level)),
                          ),
                        )
                        .toList(),
                    onChanged: readOnly
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _captureLevel = value);
                            }
                          },
                  ),
                  const SizedBox(height: 10),
                  _EditorSwitch(
                    title: 'Obligatorio para activar el producto',
                    value: _requiredToActivate,
                    readOnly: readOnly,
                    onChanged: (value) {
                      setState(() => _requiredToActivate = value);
                    },
                  ),
                  _EditorSwitch(
                    title: 'Mostrar en la ficha técnica',
                    value: _visibleInTechnicalSheet,
                    readOnly: readOnly,
                    onChanged: (value) {
                      setState(() => _visibleInTechnicalSheet = value);
                    },
                  ),
                  _EditorSwitch(
                    title: 'Disponible como filtro del catálogo',
                    value: _filterable,
                    readOnly: readOnly,
                    onChanged: (value) {
                      setState(() => _filterable = value);
                    },
                  ),
                  _EditorSwitch(
                    title: 'Puede utilizarse como eje de variante',
                    subtitle: _supportsAxis(_type)
                        ? 'La decisión final se toma al registrar el producto.'
                        : 'Disponible solo para Número, Número con unidad y '
                              'Lista de una opción.',
                    value: _canBeVariantAxis,
                    readOnly: readOnly || !_supportsAxis(_type),
                    onChanged: (value) {
                      if (!value &&
                          (_source?.usedAsAxisByProductCount ?? 0) > 0) {
                        _showAxisProtection();
                        return;
                      }
                      setState(() => _canBeVariantAxis = value);
                    },
                  ),
                  _EditorSwitch(
                    title: 'Activo para nuevos productos',
                    subtitle:
                        _source?.usedByProductCount != null &&
                            _source!.usedByProductCount > 0
                        ? 'Desactivarlo conserva los valores históricos.'
                        : null,
                    value: _activeForNewProducts,
                    readOnly: readOnly,
                    onChanged: (value) {
                      if (!value &&
                          (_source?.usedAsAxisByProductCount ?? 0) > 0) {
                        _showAxisProtection();
                        return;
                      }
                      setState(() => _activeForNewProducts = value);
                    },
                  ),
                  if (!readOnly)
                    _EditorSwitch(
                      title: 'Atributo activo',
                      value: _active,
                      readOnly: false,
                      onChanged: (value) {
                        if (!value &&
                            (_source?.usedAsAxisByProductCount ?? 0) > 0) {
                          _showAxisProtection();
                          return;
                        }
                        setState(() => _active = value);
                      },
                    ),
                  _buildTypeConfiguration(readOnly),
                  if (!readOnly && _source != null) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(
                        _structureLocked
                            ? 'No se puede eliminar: atributo utilizado'
                            : 'Eliminar atributo',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(readOnly ? 'Cerrar' : 'Cancelar'),
                ),
                if (!readOnly) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _yellow,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(140, 44),
                    ),
                    onPressed: _submit,
                    child: Text(
                      _source == null ? 'Crear atributo' : 'Guardar cambios',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeConfiguration(bool readOnly) {
    switch (_type) {
      case CategoryAttributeDataType.shortText:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Configuración del texto'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _textLengthController,
                    enabled: !readOnly,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Longitud máxima',
                    ),
                    validator: _positiveIntegerValidator,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _exampleController,
                    enabled: !readOnly,
                    decoration: const InputDecoration(labelText: 'Ejemplo'),
                  ),
                ),
              ],
            ),
          ],
        );
      case CategoryAttributeDataType.number:
        return _numberConfiguration(
          readOnly: readOnly,
          title: 'Configuración del número',
        );
      case CategoryAttributeDataType.numberWithUnit:
        final magnitudes =
            widget.units.map((unit) => unit.magnitude).toSet().toList()..sort();
        final compatibleUnits = widget.units
            .where((unit) => unit.magnitude == _magnitude)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Configuración de número con unidad'),
            DropdownButtonFormField<String>(
              value: _magnitude,
              decoration: const InputDecoration(labelText: 'Magnitud *'),
              items: magnitudes
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: readOnly || _structureLocked
                  ? null
                  : (value) {
                      setState(() {
                        _magnitude = value;
                        _allowedUnits.clear();
                        _defaultUnit = null;
                      });
                    },
              validator: (value) {
                if (_type == CategoryAttributeDataType.numberWithUnit &&
                    value == null) {
                  return 'Selecciona una magnitud.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Unidades permitidas *',
              style: TextStyle(color: _text, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: compatibleUnits.map((unit) {
                final selected = _allowedUnits.contains(unit.code);
                return FilterChip(
                  label: Text(unit.label),
                  selected: selected,
                  onSelected: readOnly || _structureLocked
                      ? null
                      : (value) {
                          setState(() {
                            if (value) {
                              _allowedUnits.add(unit.code);
                              _defaultUnit ??= unit.code;
                            } else {
                              _allowedUnits.remove(unit.code);
                              if (_defaultUnit == unit.code) {
                                _defaultUnit = _allowedUnits.isEmpty
                                    ? null
                                    : _allowedUnits.first;
                              }
                            }
                          });
                        },
                );
              }).toList(),
            ),
            if (_magnitude != null && _allowedUnits.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Selecciona al menos una unidad compatible.',
                  style: TextStyle(color: _red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _allowedUnits.contains(_defaultUnit) ? _defaultUnit : null,
              decoration: const InputDecoration(
                labelText: 'Unidad predeterminada *',
              ),
              items: widget.units
                  .where((unit) => _allowedUnits.contains(unit.code))
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit.code,
                      child: Text(unit.label),
                    ),
                  )
                  .toList(),
              onChanged: readOnly || _structureLocked
                  ? null
                  : (value) => setState(() => _defaultUnit = value),
              validator: (value) {
                if (_type == CategoryAttributeDataType.numberWithUnit &&
                    value == null) {
                  return 'Selecciona la unidad predeterminada.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _numberConfiguration(
              readOnly: readOnly,
              title: 'Rango permitido',
              includeSectionTitle: false,
            ),
            const SizedBox(height: 10),
            const _Notice(
              text:
                  'Los valores se guardan también normalizados en la unidad base '
                  'para ordenar y filtrar correctamente.',
            ),
          ],
        );
      case CategoryAttributeDataType.singleList:
      case CategoryAttributeDataType.multipleList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Opciones permitidas'),
            if (_type == CategoryAttributeDataType.multipleList) ...[
              TextFormField(
                controller: _maximumSelectionsController,
                enabled: !readOnly,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad máxima seleccionable',
                ),
                validator: _positiveIntegerValidator,
              ),
              const SizedBox(height: 12),
            ],
            _OptionEditor(
              options: _options,
              readOnly: readOnly,
              onChanged: (options) => setState(() => _options = options),
            ),
          ],
        );
      case CategoryAttributeDataType.yesNo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Etiquetas opcionales'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _trueLabelController,
                    enabled: !readOnly,
                    decoration: const InputDecoration(
                      labelText: 'Etiqueta para Sí',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _falseLabelController,
                    enabled: !readOnly,
                    decoration: const InputDecoration(
                      labelText: 'Etiqueta para No',
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _numberConfiguration({
    required bool readOnly,
    required String title,
    bool includeSectionTitle = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (includeSectionTitle) _SectionTitle(title),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minimumController,
                enabled: !readOnly,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Mínimo'),
                validator: _numberValidator,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _maximumController,
                enabled: !readOnly,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Máximo'),
                validator: _numberValidator,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _decimalsController,
                enabled: !readOnly,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Decimales'),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 0 || parsed > 6) {
                    return 'Entre 0 y 6.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showAxisProtection() async {
    final source = _source;
    if (source == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eje utilizado por productos'),
        content: Text(
          '${source.usedAsAxisByProductCount} productos utilizan '
          '“${source.name}” como eje. Revísalos antes de desactivar esta '
          'capacidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onShowAffectedProducts?.call();
            },
            child: const Text('Ver productos afectados'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final minimum = _parseDouble(_minimumController.text);
    final maximum = _parseDouble(_maximumController.text);
    if (minimum != null && maximum != null && minimum > maximum) {
      _showError('El mínimo no puede ser mayor que el máximo.');
      return;
    }
    if (_type == CategoryAttributeDataType.numberWithUnit &&
        (_magnitude == null || _allowedUnits.isEmpty || _defaultUnit == null)) {
      _showError(
        'Selecciona magnitud, unidades permitidas y unidad predeterminada.',
      );
      return;
    }
    if ((_type == CategoryAttributeDataType.singleList ||
            _type == CategoryAttributeDataType.multipleList) &&
        _options.where((option) => option.active).isEmpty) {
      _showError('La lista debe tener al menos una opción activa.');
      return;
    }
    final normalizedLabels = <String>{};
    final normalizedCodes = <String>{};
    for (final option in _options) {
      if (!normalizedLabels.add(option.label.trim().toLowerCase()) ||
          !normalizedCodes.add(option.code.trim().toLowerCase())) {
        _showError('No se permiten opciones ni códigos duplicados.');
        return;
      }
    }

    final source = _source;
    final attribute = CategoryAttributeDefinition(
      id: source?.id ?? 'attribute-${DateTime.now().microsecondsSinceEpoch}',
      ownerCategoryId: source?.ownerCategoryId ?? widget.categoryId,
      ownerCategoryName: source?.ownerCategoryName ?? widget.categoryName,
      name: _nameController.text.trim(),
      keyName: _keyController.text.trim(),
      helpText: _emptyToNull(_helpController.text),
      dataType: _type,
      captureLevel: _captureLevel,
      requiredToActivate: _requiredToActivate,
      visibleInTechnicalSheet: _visibleInTechnicalSheet,
      filterable: _filterable,
      canBeVariantAxis: _supportsAxis(_type) ? _canBeVariantAxis : false,
      activeForNewProducts: _activeForNewProducts,
      order: source?.order ?? 0,
      active: _active,
      inherited: false,
      textMaxLength: _type == CategoryAttributeDataType.shortText
          ? int.tryParse(_textLengthController.text.trim())
          : null,
      example: _type == CategoryAttributeDataType.shortText
          ? _emptyToNull(_exampleController.text)
          : null,
      minimum:
          _type == CategoryAttributeDataType.number ||
              _type == CategoryAttributeDataType.numberWithUnit
          ? minimum
          : null,
      maximum:
          _type == CategoryAttributeDataType.number ||
              _type == CategoryAttributeDataType.numberWithUnit
          ? maximum
          : null,
      decimals:
          _type == CategoryAttributeDataType.number ||
              _type == CategoryAttributeDataType.numberWithUnit
          ? int.tryParse(_decimalsController.text.trim()) ?? 0
          : 0,
      magnitude: _type == CategoryAttributeDataType.numberWithUnit
          ? _magnitude
          : null,
      allowedUnitCodes: _type == CategoryAttributeDataType.numberWithUnit
          ? _allowedUnits
          : const [],
      defaultUnitCode: _type == CategoryAttributeDataType.numberWithUnit
          ? _defaultUnit
          : null,
      options:
          _type == CategoryAttributeDataType.singleList ||
              _type == CategoryAttributeDataType.multipleList
          ? _options
          : const [],
      maximumSelections: _type == CategoryAttributeDataType.multipleList
          ? int.tryParse(_maximumSelectionsController.text.trim())
          : null,
      trueLabel: _type == CategoryAttributeDataType.yesNo
          ? _emptyToNull(_trueLabelController.text)
          : null,
      falseLabel: _type == CategoryAttributeDataType.yesNo
          ? _emptyToNull(_falseLabelController.text)
          : null,
      usedByProductCount: source?.usedByProductCount ?? 0,
      affectedCategoryCount: source?.affectedCategoryCount ?? 0,
      usedAsAxisByProductCount: source?.usedAsAxisByProductCount ?? 0,
      syncState: AttributeSyncState.pending,
    );
    widget.onSave(attribute);
  }

  String? _positiveIntegerValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Debe ser mayor que cero.';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (_parseDouble(value) == null) return 'Número inválido.';
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: _red));
  }
}

class _OptionEditor extends StatefulWidget {
  const _OptionEditor({
    required this.options,
    required this.readOnly,
    required this.onChanged,
  });

  final List<CategoryAttributeOption> options;
  final bool readOnly;
  final ValueChanged<List<CategoryAttributeOption>> onChanged;

  @override
  State<_OptionEditor> createState() => _OptionEditorState();
}

class _OptionEditorState extends State<_OptionEditor> {
  final _labelController = TextEditingController();
  final _codeController = TextEditingController();
  String? _editingId;

  CategoryAttributeOption? get _editingOption {
    final id = _editingId;
    if (id == null) return null;
    for (final option in widget.options) {
      if (option.id == id) return option;
    }
    return null;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Opción',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Código',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Estado',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(width: 44),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...widget.options.map(_buildOptionRow),
            ],
          ),
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Opción',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _codeController,
                  enabled: (_editingOption?.usedByProductCount ?? 0) == 0,
                  decoration: InputDecoration(
                    labelText: 'Código',
                    isDense: true,
                    helperText: (_editingOption?.usedByProductCount ?? 0) > 0
                        ? 'Protegido por uso'
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: _editingId == null
                    ? 'Agregar opción'
                    : 'Guardar opción',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: _saveOption,
                icon: Icon(
                  _editingId == null ? Icons.add_rounded : Icons.check_rounded,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOptionRow(CategoryAttributeOption option) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              option.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              option.code,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              option.active ? 'Activa' : 'Inactiva',
              style: TextStyle(
                color: option.active ? _green : _muted,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: widget.readOnly
                ? null
                : PopupMenuButton<String>(
                    tooltip: 'Acciones de ${option.label}',
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editingId = option.id;
                        _labelController.text = option.label;
                        _codeController.text = option.code;
                        setState(() {});
                      } else if (value == 'status') {
                        _updateOption(option.copyWith(active: !option.active));
                      } else if (value == 'remove') {
                        if (option.usedByProductCount > 0) {
                          _updateOption(option.copyWith(active: false));
                        } else {
                          widget.onChanged(
                            widget.options
                                .where((item) => item.id != option.id)
                                .toList(),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(
                        value: 'status',
                        child: Text(option.active ? 'Desactivar' : 'Activar'),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          option.usedByProductCount > 0
                              ? 'Desactivar'
                              : 'Eliminar',
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _saveOption() {
    final label = _labelController.text.trim();
    final code = _codeController.text.trim().isEmpty
        ? _toKey(label)
        : _toKey(_codeController.text);
    if (label.isEmpty || code.isEmpty) return;
    final duplicate = widget.options.any(
      (option) =>
          option.id != _editingId &&
          (option.label.toLowerCase() == label.toLowerCase() ||
              option.code.toLowerCase() == code.toLowerCase()),
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La opción o su código ya existe.'),
          backgroundColor: _red,
        ),
      );
      return;
    }

    final updated = [...widget.options];
    if (_editingId == null) {
      updated.add(
        CategoryAttributeOption(
          id: 'option-${DateTime.now().microsecondsSinceEpoch}',
          label: label,
          code: code,
          active: true,
        ),
      );
    } else {
      final index = updated.indexWhere((option) => option.id == _editingId);
      final current = updated[index];
      updated[index] = current.copyWith(
        label: label,
        code: current.usedByProductCount > 0 ? current.code : code,
      );
    }
    _editingId = null;
    _labelController.clear();
    _codeController.clear();
    widget.onChanged(updated);
    setState(() {});
  }

  void _updateOption(CategoryAttributeOption option) {
    final updated = [...widget.options];
    final index = updated.indexWhere((item) => item.id == option.id);
    updated[index] = option;
    widget.onChanged(updated);
  }
}

class _AttributeTableHeader extends StatelessWidget {
  const _AttributeTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: _border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Atributo')),
          Expanded(flex: 2, child: Text('Tipo')),
          Expanded(flex: 4, child: Text('Configuración')),
          Expanded(flex: 2, child: Text('Origen')),
          Expanded(flex: 2, child: Text('Productos')),
          Expanded(flex: 2, child: Text('Estado')),
          SizedBox(width: 92, child: Text('Acción')),
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({
    super.key,
    required this.attribute,
    required this.selected,
    required this.onOpen,
    this.reorderIndex,
  });

  final CategoryAttributeDefinition attribute;
  final bool selected;
  final VoidCallback onOpen;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    final settings = <String>[
      if (attribute.requiredToActivate) 'Obligatorio',
      if (attribute.filterable) 'Filtrable',
      if (attribute.visibleInTechnicalSheet) 'Visible en ficha',
      if (attribute.canBeVariantAxis) 'Eje permitido',
    ];
    return InkWell(
      onTap: onOpen,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFAE6) : Colors.white,
          border: Border(
            left: BorderSide(
              color: selected ? _yellow : _border,
              width: selected ? 4 : 1,
            ),
            right: const BorderSide(color: _border),
            bottom: const BorderSide(color: _border),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  if (reorderIndex != null) ...[
                    ReorderableDragStartListener(
                      index: reorderIndex!,
                      child: const SizedBox(
                        width: 38,
                        height: 44,
                        child: Icon(Icons.drag_indicator_rounded),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attribute.name,
                          style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          attribute.keyName,
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _dataTypeLabel(attribute.dataType),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                settings.isEmpty
                    ? 'Sin reglas adicionales'
                    : settings.join(' · '),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                attribute.inherited ? 'Heredado' : attribute.ownerCategoryName,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${attribute.usedByProductCount}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: _StatusLabel(
                active: attribute.active && attribute.activeForNewProducts,
                pendingSync: attribute.syncState == AttributeSyncState.pending,
              ),
            ),
            SizedBox(
              width: 92,
              child: TextButton(
                onPressed: onOpen,
                child: Text(attribute.inherited ? 'Ver' : 'Editar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewField extends StatelessWidget {
  const _PreviewField({required this.attribute});

  final CategoryAttributeDefinition attribute;

  @override
  Widget build(BuildContext context) {
    final label =
        '${attribute.name}${attribute.requiredToActivate ? ' *' : ''}';
    switch (attribute.dataType) {
      case CategoryAttributeDataType.shortText:
        return TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: attribute.example,
            helperText: attribute.helpText,
          ),
        );
      case CategoryAttributeDataType.number:
        return TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: '10',
            helperText: attribute.helpText,
          ),
        );
      case CategoryAttributeDataType.numberWithUnit:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: '10',
                  helperText: attribute.helpText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                value: attribute.defaultUnitCode,
                decoration: const InputDecoration(labelText: 'Unidad'),
                items: attribute.allowedUnitCodes
                    .map(
                      (code) =>
                          DropdownMenuItem(value: code, child: Text(code)),
                    )
                    .toList(),
                onChanged: null,
              ),
            ),
          ],
        );
      case CategoryAttributeDataType.singleList:
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            helperText: attribute.helpText,
          ),
          items: attribute.options
              .where((option) => option.active)
              .map(
                (option) => DropdownMenuItem(
                  value: option.id,
                  child: Text(option.label),
                ),
              )
              .toList(),
          onChanged: null,
        );
      case CategoryAttributeDataType.multipleList:
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            helperText: attribute.helpText,
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: attribute.options
                .where((option) => option.active)
                .take(2)
                .map(
                  (option) => Chip(label: Text(option.label), onDeleted: null),
                )
                .toList(),
          ),
        );
      case CategoryAttributeDataType.yesNo:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: attribute.helpText == null
              ? null
              : Text(attribute.helpText!),
          value: false,
          onChanged: null,
        );
    }
  }
}

class _EditorSwitch extends StatelessWidget {
  const _EditorSwitch({
    required this.title,
    required this.value,
    required this.readOnly,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final bool readOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: readOnly ? null : onChanged,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: _text,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _blueSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(color: _text, fontSize: 13, height: 1.35),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.active, required this.pendingSync});

  final bool active;
  final bool pendingSync;

  @override
  Widget build(BuildContext context) {
    final label = pendingSync
        ? 'Pendiente sync'
        : active
        ? 'Activo'
        : 'Inactivo';
    final background = pendingSync
        ? const Color(0xFFFFF4CC)
        : active
        ? _greenSoft
        : _redSoft;
    final foreground = pendingSync
        ? const Color(0xFF8A5A00)
        : active
        ? _green
        : _red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pendingSync
                ? Icons.cloud_upload_outlined
                : active
                ? Icons.check_circle_outline
                : Icons.pause_circle_outline,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    this.icon,
    this.background = const Color(0xFFF1F3F5),
  });

  final String label;
  final IconData? icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: _muted),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              color: _text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      selectedColor: const Color(0xFFFFF4C2),
      side: BorderSide(color: selected ? _yellow : _border),
      onSelected: (_) => onSelected(),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: _yellow,
        foregroundColor: Colors.black,
        minimumSize: const Size(0, 44),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _text,
        side: const BorderSide(color: _border),
        minimumSize: const Size(0, 44),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.data_object_rounded, size: 38, color: _muted),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: _text, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

String _dataTypeLabel(CategoryAttributeDataType type) {
  return switch (type) {
    CategoryAttributeDataType.shortText => 'Texto corto',
    CategoryAttributeDataType.number => 'Número',
    CategoryAttributeDataType.numberWithUnit => 'Número con unidad',
    CategoryAttributeDataType.singleList => 'Lista de una opción',
    CategoryAttributeDataType.multipleList => 'Lista de varias opciones',
    CategoryAttributeDataType.yesNo => 'Sí / No',
  };
}

String _captureLevelLabel(AttributeCaptureLevel level) {
  return switch (level) {
    AttributeCaptureLevel.family => 'Compartido por toda la familia',
    AttributeCaptureLevel.variant => 'Cambia por variante',
    AttributeCaptureLevel.decideWhenRegistering =>
      'Se decide al registrar el producto',
  };
}

String _filterLabel(AttributeListFilter filter) {
  return switch (filter) {
    AttributeListFilter.all => 'Todos',
    AttributeListFilter.own => 'Propios',
    AttributeListFilter.inherited => 'Heredados',
    AttributeListFilter.inactive => 'Inactivos',
  };
}

bool _supportsAxis(CategoryAttributeDataType type) {
  return type == CategoryAttributeDataType.number ||
      type == CategoryAttributeDataType.numberWithUnit ||
      type == CategoryAttributeDataType.singleList;
}

String _toKey(String value) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var normalized = value.trim().toLowerCase();
  accents.forEach((source, replacement) {
    normalized = normalized.replaceAll(source, replacement);
  });
  normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  normalized = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized;
}

String _canonicalAttributeIdentity(String value) {
  final normalized = _toKey(value).replaceAll('_', '');
  if (value.trim() == 'Ø' || normalized == 'diameter' || normalized == 'diam') {
    return 'diametro';
  }
  return normalized;
}

double? _parseDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
