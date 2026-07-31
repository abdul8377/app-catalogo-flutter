import 'package:flutter/material.dart';

// ============================================================================
// ESTRUCTURA DEL CATÁLOGO
//
// Widget autocontenido para el módulo de administración.
//
// Reglas:
// - Empresa 1 ─ N Marca.
// - Categoría global, jerárquica y reutilizable.
// - Marca N ─ N Categoría mediante marca_categorias.
// - Los atributos se definen en Categorías y se heredan desde los ancestros.
// - Los valores se completan después en la familia o en sus variantes.
// ============================================================================

const _catalogYellow = Color(0xFFFFC500);
const _catalogBackground = Color(0xFFF4F6F8);
const _catalogBorder = Color(0xFFDCE1E7);
const _catalogText = Color(0xFF20242A);
const _catalogMuted = Color(0xFF697386);
const _catalogGreen = Color(0xFF168A50);
const _catalogGreenSoft = Color(0xFFE6F6EE);
const _catalogRed = Color(0xFFB42318);
const _catalogRedSoft = Color(0xFFFEECEB);
const _catalogBlueSoft = Color(0xFFEFF6FF);

enum CatalogStructureTab { companies, brands, categories, brandCategories }

enum CatalogRecordFilter { all, active, inactive }

enum CategoryDetailSection { summary, attributes }

enum CategoryAttributeType { text, number, list, boolean, date }

@immutable
class CatalogCompany {
  const CatalogCompany({
    required this.id,
    required this.name,
    required this.initials,
    required this.brandCount,
    required this.productCount,
    required this.active,
    this.ruc,
    this.phone,
    this.address,
  });

  final String id;
  final String name;
  final String initials;
  final String? ruc;
  final String? phone;
  final String? address;
  final int brandCount;

  /// Incluye todos los productos, activos e inactivos.
  final int productCount;
  final bool active;

  CatalogCompany copyWith({
    String? name,
    String? initials,
    String? ruc,
    String? phone,
    String? address,
    int? brandCount,
    int? productCount,
    bool? active,
  }) {
    return CatalogCompany(
      id: id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      ruc: ruc ?? this.ruc,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      brandCount: brandCount ?? this.brandCount,
      productCount: productCount ?? this.productCount,
      active: active ?? this.active,
    );
  }
}

@immutable
class CatalogBrand {
  const CatalogBrand({
    required this.id,
    required this.companyId,
    required this.name,
    required this.initials,
    required this.productCount,
    required this.active,
  });

  final String id;
  final String companyId;
  final String name;
  final String initials;
  final int productCount;
  final bool active;

  CatalogBrand copyWith({
    String? companyId,
    String? name,
    String? initials,
    int? productCount,
    bool? active,
  }) {
    return CatalogBrand(
      id: id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      productCount: productCount ?? this.productCount,
      active: active ?? this.active,
    );
  }
}

@immutable
class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.directProductCount,
    required this.includingDescendantProductCount,
    required this.active,
    this.parentId,
    this.description,
  });

  final String id;
  final String? parentId;
  final String name;
  final String? description;
  final int directProductCount;
  final int includingDescendantProductCount;
  final bool active;

  CatalogCategory copyWith({
    String? parentId,
    bool clearParent = false,
    String? name,
    String? description,
    int? directProductCount,
    int? includingDescendantProductCount,
    bool? active,
  }) {
    return CatalogCategory(
      id: id,
      parentId: clearParent ? null : parentId ?? this.parentId,
      name: name ?? this.name,
      description: description ?? this.description,
      directProductCount: directProductCount ?? this.directProductCount,
      includingDescendantProductCount:
          includingDescendantProductCount ??
          this.includingDescendantProductCount,
      active: active ?? this.active,
    );
  }
}

@immutable
class CategoryAttributeDefinition {
  const CategoryAttributeDefinition({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.type,
    required this.required,
    required this.filterable,
    required this.variantAxis,
    required this.multiple,
    required this.active,
    this.units = const [],
    this.options = const [],
    this.usedByProductCount = 0,
  });

  final String id;
  final String categoryId;
  final String name;
  final CategoryAttributeType type;
  final List<String> units;
  final List<String> options;
  final bool required;
  final bool filterable;
  final bool variantAxis;
  final bool multiple;
  final bool active;
  final int usedByProductCount;

  CategoryAttributeDefinition copyWith({
    String? name,
    CategoryAttributeType? type,
    List<String>? units,
    List<String>? options,
    bool? required,
    bool? filterable,
    bool? variantAxis,
    bool? multiple,
    bool? active,
    int? usedByProductCount,
  }) {
    return CategoryAttributeDefinition(
      id: id,
      categoryId: categoryId,
      name: name ?? this.name,
      type: type ?? this.type,
      units: units ?? this.units,
      options: options ?? this.options,
      required: required ?? this.required,
      filterable: filterable ?? this.filterable,
      variantAxis: variantAxis ?? this.variantAxis,
      multiple: multiple ?? this.multiple,
      active: active ?? this.active,
      usedByProductCount: usedByProductCount ?? this.usedByProductCount,
    );
  }
}

@immutable
class BrandCategoryRelation {
  const BrandCategoryRelation({
    required this.brandId,
    required this.categoryId,
    required this.activeProductCount,
  });

  final String brandId;
  final String categoryId;
  final int activeProductCount;

  bool get isLocked => activeProductCount > 0;
}

@immutable
class EffectiveCategoryAttribute {
  const EffectiveCategoryAttribute({
    required this.definition,
    required this.originCategory,
    required this.inherited,
  });

  final CategoryAttributeDefinition definition;
  final CatalogCategory originCategory;
  final bool inherited;
}

class CatalogStructurePanel extends StatefulWidget {
  const CatalogStructurePanel({
    super.key,
    required this.companies,
    required this.brands,
    required this.categories,
    required this.attributes,
    required this.relations,
    this.initialTab = CatalogStructureTab.companies,
    this.onCompaniesChanged,
    this.onBrandsChanged,
    this.onCategoriesChanged,
    this.onRelationsChanged,
    this.onManageCategoryAttributes,
  });

  final List<CatalogCompany> companies;
  final List<CatalogBrand> brands;
  final List<CatalogCategory> categories;
  final List<CategoryAttributeDefinition> attributes;
  final List<BrandCategoryRelation> relations;
  final CatalogStructureTab initialTab;

  final ValueChanged<List<CatalogCompany>>? onCompaniesChanged;
  final ValueChanged<List<CatalogBrand>>? onBrandsChanged;
  final ValueChanged<List<CatalogCategory>>? onCategoriesChanged;
  final ValueChanged<List<BrandCategoryRelation>>? onRelationsChanged;
  final ValueChanged<String>? onManageCategoryAttributes;

  factory CatalogStructurePanel.demo({Key? key}) {
    return CatalogStructurePanel(
      key: key,
      companies: const [
        CatalogCompany(
          id: 'company-dinafast',
          name: 'DINFAST',
          initials: 'DF',
          ruc: '20123456789',
          brandCount: 2,
          productCount: 286,
          active: true,
        ),
        CatalogCompany(
          id: 'company-uyus',
          name: 'UYUSTOOLS S.A.C.',
          initials: 'UY',
          ruc: '20678912345',
          brandCount: 1,
          productCount: 164,
          active: true,
        ),
        CatalogCompany(
          id: 'company-garibaldi',
          name: 'Distribuidora Garibaldi',
          initials: 'DG',
          ruc: '20456789123',
          brandCount: 3,
          productCount: 341,
          active: true,
        ),
      ],
      brands: const [
        CatalogBrand(
          id: 'brand-dina',
          companyId: 'company-dinafast',
          name: 'DINA',
          initials: 'DI',
          productCount: 224,
          active: true,
        ),
        CatalogBrand(
          id: 'brand-dinaplast',
          companyId: 'company-dinafast',
          name: 'DINAPLAST',
          initials: 'DP',
          productCount: 62,
          active: true,
        ),
        CatalogBrand(
          id: 'brand-uyus',
          companyId: 'company-uyus',
          name: 'UYUSTOOLS',
          initials: 'UY',
          productCount: 164,
          active: true,
        ),
        CatalogBrand(
          id: 'brand-garibaldi',
          companyId: 'company-garibaldi',
          name: 'Garibaldi',
          initials: 'GA',
          productCount: 186,
          active: true,
        ),
      ],
      categories: const [
        CatalogCategory(
          id: 'tools',
          name: 'Herramientas eléctricas',
          directProductCount: 84,
          includingDescendantProductCount: 142,
          active: true,
        ),
        CatalogCategory(
          id: 'wireless',
          parentId: 'tools',
          name: 'Inalámbricas',
          directProductCount: 0,
          includingDescendantProductCount: 58,
          active: true,
        ),
        CatalogCategory(
          id: 'drills',
          parentId: 'wireless',
          name: 'Taladros',
          directProductCount: 24,
          includingDescendantProductCount: 24,
          active: true,
        ),
        CatalogCategory(
          id: 'batteries',
          parentId: 'wireless',
          name: 'Baterías y cargadores',
          directProductCount: 34,
          includingDescendantProductCount: 34,
          active: true,
        ),
        CatalogCategory(
          id: 'accessories',
          name: 'Accesorios y consumibles',
          directProductCount: 190,
          includingDescendantProductCount: 286,
          active: true,
        ),
        CatalogCategory(
          id: 'drill-bits',
          parentId: 'accessories',
          name: 'Brocas',
          description: 'Brocas reutilizadas por todas las marcas habilitadas.',
          directProductCount: 0,
          includingDescendantProductCount: 96,
          active: true,
        ),
        CatalogCategory(
          id: 'metal-bits',
          parentId: 'drill-bits',
          name: 'Para metal',
          directProductCount: 42,
          includingDescendantProductCount: 42,
          active: true,
        ),
        CatalogCategory(
          id: 'concrete-bits',
          parentId: 'drill-bits',
          name: 'Para concreto',
          directProductCount: 31,
          includingDescendantProductCount: 31,
          active: true,
        ),
        CatalogCategory(
          id: 'wood-bits',
          parentId: 'drill-bits',
          name: 'Para madera',
          directProductCount: 23,
          includingDescendantProductCount: 23,
          active: true,
        ),
      ],
      attributes: const [
        CategoryAttributeDefinition(
          id: 'attr-diameter',
          categoryId: 'drill-bits',
          name: 'Diámetro',
          type: CategoryAttributeType.number,
          units: ['mm', 'pulgada'],
          required: true,
          filterable: true,
          variantAxis: true,
          multiple: false,
          active: true,
          usedByProductCount: 96,
        ),
        CategoryAttributeDefinition(
          id: 'attr-length',
          categoryId: 'drill-bits',
          name: 'Largo',
          type: CategoryAttributeType.number,
          units: ['mm', 'pulgada'],
          required: true,
          filterable: true,
          variantAxis: true,
          multiple: false,
          active: true,
          usedByProductCount: 96,
        ),
        CategoryAttributeDefinition(
          id: 'attr-material',
          categoryId: 'drill-bits',
          name: 'Material',
          type: CategoryAttributeType.list,
          options: ['HSS', 'Cobalto', 'Carburo'],
          required: true,
          filterable: true,
          variantAxis: false,
          multiple: false,
          active: true,
          usedByProductCount: 87,
        ),
        CategoryAttributeDefinition(
          id: 'attr-shank',
          categoryId: 'drill-bits',
          name: 'Tipo de vástago',
          type: CategoryAttributeType.list,
          options: ['Cilíndrico', 'Hexagonal', 'SDS Plus'],
          required: false,
          filterable: true,
          variantAxis: false,
          multiple: false,
          active: true,
          usedByProductCount: 40,
        ),
        CategoryAttributeDefinition(
          id: 'attr-coating',
          categoryId: 'metal-bits',
          name: 'Recubrimiento',
          type: CategoryAttributeType.list,
          options: ['Óxido negro', 'Titanio', 'Sin recubrimiento'],
          required: false,
          filterable: true,
          variantAxis: false,
          multiple: false,
          active: true,
          usedByProductCount: 30,
        ),
      ],
      relations: const [
        BrandCategoryRelation(
          brandId: 'brand-dina',
          categoryId: 'drill-bits',
          activeProductCount: 72,
        ),
        BrandCategoryRelation(
          brandId: 'brand-dina',
          categoryId: 'metal-bits',
          activeProductCount: 42,
        ),
        BrandCategoryRelation(
          brandId: 'brand-dina',
          categoryId: 'concrete-bits',
          activeProductCount: 18,
        ),
        BrandCategoryRelation(
          brandId: 'brand-uyus',
          categoryId: 'drill-bits',
          activeProductCount: 24,
        ),
        BrandCategoryRelation(
          brandId: 'brand-garibaldi',
          categoryId: 'drill-bits',
          activeProductCount: 0,
        ),
      ],
    );
  }

  @override
  State<CatalogStructurePanel> createState() => _CatalogStructurePanelState();
}

class _CatalogStructurePanelState extends State<CatalogStructurePanel> {
  late CatalogStructureTab _tab;
  CategoryDetailSection _categorySection = CategoryDetailSection.summary;
  CatalogRecordFilter _filter = CatalogRecordFilter.all;

  late List<CatalogCompany> _companies;
  late List<CatalogBrand> _brands;
  late List<CatalogCategory> _categories;
  late List<CategoryAttributeDefinition> _attributes;
  late List<BrandCategoryRelation> _relations;

  String _query = '';
  String _relationCategoryQuery = '';
  String? _selectedCategoryId;
  String? _selectedCompanyId;
  String? _selectedBrandId;

  late Map<String, Set<String>> _savedRelations;
  late Map<String, Set<String>> _workingRelations;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _companies = [...widget.companies];
    _brands = [...widget.brands];
    _categories = [...widget.categories];
    _attributes = [...widget.attributes];
    _relations = [...widget.relations];
    _selectedCategoryId = _categories.isEmpty ? null : _categories.first.id;
    _selectedCompanyId = _companies.isEmpty ? null : _companies.first.id;
    _selectedBrandId = _firstBrandIdFor(_selectedCompanyId);
    _savedRelations = _relationMap(_relations);
    _workingRelations = _copyRelationMap(_savedRelations);
  }

  Map<String, Set<String>> _relationMap(
    List<BrandCategoryRelation> source,
  ) {
    final rootIds = _categories
        .where((category) => category.parentId == null)
        .map((category) => category.id)
        .toSet();
    final result = <String, Set<String>>{};
    for (final relation in source) {
      if (!rootIds.contains(relation.categoryId)) continue;
      result.putIfAbsent(relation.brandId, () => <String>{});
      result[relation.brandId]!.add(relation.categoryId);
    }
    return result;
  }

  Map<String, Set<String>> _copyRelationMap(Map<String, Set<String>> source) {
    return source.map((key, value) => MapEntry(key, Set<String>.from(value)));
  }

  String? _firstBrandIdFor(String? companyId) {
    if (companyId == null) return null;
    for (final brand in _brands) {
      if (brand.companyId == companyId) return brand.id;
    }
    return null;
  }

  CatalogCompany? get _selectedCompany {
    return _firstWhereOrNull(
      _companies,
      (item) => item.id == _selectedCompanyId,
    );
  }

  CatalogBrand? get _selectedBrand {
    return _firstWhereOrNull(_brands, (item) => item.id == _selectedBrandId);
  }

  CatalogCategory? get _selectedCategory {
    return _firstWhereOrNull(
      _categories,
      (item) => item.id == _selectedCategoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _catalogBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 46,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMainTabs(),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: KeyedSubtree(
                            key: ValueKey(_tab),
                            child: _buildCurrentTab(constraints.maxWidth),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estructura del catálogo',
            style: TextStyle(
              color: _catalogText,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(switch (_tab) {
            CatalogStructureTab.companies =>
              'Las empresas agrupan marcas; no poseen categorías directamente.',
            CatalogStructureTab.brands =>
              'Cada marca pertenece a una empresa y utiliza categorías globales.',
            CatalogStructureTab.categories =>
              'Categorías globales de dos niveles, con atributos e herencia.',
            CatalogStructureTab.brandCategories =>
              'Define qué categorías globales puede utilizar cada marca.',
          }, style: const TextStyle(color: _catalogMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMainTabs() {
    final items = <(CatalogStructureTab, String)>[
      (CatalogStructureTab.companies, 'Empresas'),
      (CatalogStructureTab.brands, 'Marcas'),
      (CatalogStructureTab.categories, 'Categorías'),
      (CatalogStructureTab.brandCategories, 'Categorías por marca'),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _catalogBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            if (compact) {
              return Wrap(
                spacing: 4,
                runSpacing: 4,
                children: items.map((item) {
                  return SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: _mainTabButton(item.$1, item.$2),
                  );
                }).toList(),
              );
            }
            return Row(
              children: items.map((item) {
                return Expanded(child: _mainTabButton(item.$1, item.$2));
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _mainTabButton(CatalogStructureTab value, String label) {
    final selected = _tab == value;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () {
          setState(() {
            _tab = value;
            _query = '';
            _filter = CatalogRecordFilter.all;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _catalogYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? const Color(0xFFE3A900) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _catalogText,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(double width) {
    return switch (_tab) {
      CatalogStructureTab.companies => _buildCompanies(width),
      CatalogStructureTab.brands => _buildBrands(width),
      CatalogStructureTab.categories => _buildCategories(width),
      CatalogStructureTab.brandCategories => _buildBrandCategories(width),
    };
  }

  Widget _buildCompanies(double width) {
    final visible = _companies.where((company) {
      final matchesQuery =
          company.name.toLowerCase().contains(_query.toLowerCase()) ||
          (company.ruc ?? '').contains(_query);
      return matchesQuery && _matchesStatus(company.active);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(
          searchHint: 'Buscar empresa por nombre o RUC',
          createLabel: 'Nueva empresa',
          onCreate: _showCompanyForm,
          showStatusFilters: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '${visible.length} ${visible.length == 1 ? 'empresa' : 'empresas'}',
              style: const TextStyle(
                color: _catalogText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            const _InfoPill(
              label: 'Productos: activos e inactivos',
              color: _catalogBlueSoft,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const _EmptyState(
            title: 'No se encontraron empresas',
            message: 'Ajusta la búsqueda o el filtro de estado.',
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: visible.map((company) {
              return SizedBox(
                width: width >= 900 ? (width - 16) / 2 : width,
                child: _buildCompanyCard(company),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCompanyCard(CatalogCompany company) {
    final companyBrands = _brands
        .where((brand) => brand.companyId == company.id)
        .toList();
    final categoryIds = <String>{};
    for (final brand in companyBrands) {
      categoryIds.addAll(_savedRelations[brand.id] ?? const <String>{});
    }

    return _CatalogCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _InitialsAvatar(
                initials: company.initials,
                color: _catalogYellow,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        color: _catalogText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (company.ruc != null &&
                        company.ruc!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'RUC ${company.ruc}',
                        style: const TextStyle(
                          color: _catalogMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(active: company.active),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Marcas',
                  value: '${companyBrands.length}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Categorías vía marcas',
                  value: '${categoryIds.length}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Productos totales',
                  value: '${company.productCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SecondaryButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: () => _showCompanyForm(existing: company),
              ),
              _SecondaryButton(
                label: 'Ver marcas',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  setState(() {
                    _tab = CatalogStructureTab.brands;
                    _selectedCompanyId = company.id;
                    _query = '';
                  });
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Más acciones para ${company.name}',
                onSelected: (value) {
                  if (value == 'status') {
                    _confirmCompanyStatusChange(company);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    child: Text(
                      company.active
                          ? 'Desactivar empresa'
                          : 'Activar empresa',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrands(double width) {
    final visible = _brands.where((brand) {
      final company = _companyById(brand.companyId);
      final text = '${brand.name} ${company?.name ?? ''}'.toLowerCase();
      final matchesCompany =
          _selectedCompanyId == null || brand.companyId == _selectedCompanyId;
      return matchesCompany &&
          text.contains(_query.toLowerCase()) &&
          _matchesStatus(brand.active);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(
          searchHint: 'Buscar marca o empresa',
          createLabel: 'Nueva marca',
          onCreate: _showBrandForm,
          showStatusFilters: true,
          secondaryLabel: 'Administrar categorías por marca',
          onSecondary: () {
            setState(() {
              _tab = CatalogStructureTab.brandCategories;
              _selectedBrandId ??= _firstBrandIdFor(_selectedCompanyId);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildCompanyFilter(),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          const _EmptyState(
            title: 'No se encontraron marcas',
            message: 'Cada marca debe pertenecer a una empresa.',
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: visible.map((brand) {
              return SizedBox(
                width: width >= 1100
                    ? (width - 32) / 3
                    : width >= 720
                    ? (width - 16) / 2
                    : width,
                child: _buildBrandCard(brand),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCompanyFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todas las empresas'),
          selected: _selectedCompanyId == null,
          onSelected: (_) => setState(() => _selectedCompanyId = null),
        ),
        ..._companies.map((company) {
          return ChoiceChip(
            label: Text(company.name),
            selected: _selectedCompanyId == company.id,
            onSelected: (_) {
              setState(() => _selectedCompanyId = company.id);
            },
          );
        }),
      ],
    );
  }

  Widget _buildBrandCard(CatalogBrand brand) {
    final company = _companyById(brand.companyId);
    final relationIds = _savedRelations[brand.id] ?? const <String>{};
    final related = _categories
        .where(
          (category) =>
              category.parentId == null &&
              relationIds.contains(category.id),
        )
        .toList();

    return _CatalogCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _InitialsAvatar(
                initials: brand.initials,
                color: const Color(0xFF2F66EB),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.name,
                      style: const TextStyle(
                        color: _catalogText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Empresa: ${company?.name ?? 'Sin empresa'}',
                      style: const TextStyle(
                        color: _catalogMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(active: brand.active),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Categorías principales habilitadas',
            style: TextStyle(color: _catalogMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (related.isEmpty)
            const Text(
              'Sin categorías habilitadas',
              style: TextStyle(color: _catalogMuted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...related
                    .take(3)
                    .map((category) => _InfoPill(label: category.name)),
                if (related.length > 3)
                  _InfoPill(label: '+${related.length - 3}'),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            '${brand.productCount} productos totales',
            style: const TextStyle(
              color: _catalogText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SecondaryButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: () => _showBrandForm(existing: brand),
              ),
              _SecondaryButton(
                label: 'Administrar categorías',
                icon: Icons.account_tree_outlined,
                onPressed: () {
                  setState(() {
                    _tab = CatalogStructureTab.brandCategories;
                    _selectedCompanyId = brand.companyId;
                    _selectedBrandId = brand.id;
                  });
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Más acciones para ${brand.name}',
                onSelected: (value) {
                  if (value == 'status') {
                    _confirmBrandStatusChange(brand);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    child: Text(
                      brand.active
                          ? 'Desactivar marca'
                          : 'Activar marca',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(double width) {
    final narrow = width < 880;
    final tree = _buildCategoryTreePanel();
    final detail = _buildCategoryDetailPanel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(
          searchHint: 'Buscar categoría o subcategoría',
          createLabel: 'Nueva categoría raíz',
          onCreate: _showCategoryForm,
          showStatusFilters: true,
        ),
        const SizedBox(height: 16),
        if (narrow)
          Column(children: [tree, const SizedBox(height: 16), detail])
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: tree),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: detail),
            ],
          ),
      ],
    );
  }

  Widget _buildCategoryTreePanel() {
    final roots = _categories
        .where((category) => category.parentId == null)
        .toList();
    final rows = <Widget>[];
    for (final root in roots) {
      _appendCategoryRows(rows, root, 0);
    }

    return _CatalogCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Categorías y subcategorías',
                    style: TextStyle(
                      color: _catalogText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _InfoPill(label: '${_categories.length} categorías'),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(children: rows),
            ),
          ),
        ],
      ),
    );
  }

  void _appendCategoryRows(
    List<Widget> target,
    CatalogCategory category,
    int depth,
  ) {
    final descendants = _descendantsOf(category.id);
    final query = _query.toLowerCase();
    final selfMatchesQuery = category.name.toLowerCase().contains(query);
    final descendantMatchesQuery = descendants.any(
      (item) => item.name.toLowerCase().contains(query),
    );
    final selfMatchesStatus = _matchesStatus(category.active);
    final descendantMatchesStatus = descendants.any(
      (item) => _matchesStatus(item.active),
    );

    if (_query.isNotEmpty &&
        !selfMatchesQuery &&
        !descendantMatchesQuery) {
      return;
    }
    if (_filter != CatalogRecordFilter.all &&
        !selfMatchesStatus &&
        !descendantMatchesStatus) {
      return;
    }

    target.add(
      _CategoryTreeTile(
        category: category,
        depth: depth,
        selected: category.id == _selectedCategoryId,
        hasChildren: _childrenOf(category.id).isNotEmpty,
        onTap: () => setState(() {
          _selectedCategoryId = category.id;
          _categorySection = CategoryDetailSection.summary;
        }),
        onEdit: () => _showCategoryForm(existing: category),
        onAddChild: category.parentId == null && category.active
            ? () => _showCategoryForm(
                parentId: category.id,
                createSubcategory: true,
              )
            : null,
        onToggleStatus: () => _confirmCategoryStatusChange(category),
      ),
    );

    for (final child in _childrenOf(category.id)) {
      _appendCategoryRows(target, child, depth + 1);
    }
  }

  Widget _buildCategoryDetailPanel() {
    final category = _selectedCategory;
    if (category == null) {
      return const _EmptyState(
        title: 'Selecciona una categoría',
        message: 'Verás su resumen y sus atributos en este panel.',
      );
    }

    return _CatalogCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _InfoPill(
                            label: 'SELECCIONADA',
                            color: Color(0xFFFFE277),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(active: category.active),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category.name,
                        style: const TextStyle(
                          color: _catalogText,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _buildCategorySectionTabs(),
          ),
          const Divider(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _categorySection == CategoryDetailSection.summary
                ? _buildCategorySummary(category)
                : _buildAttributeManager(category),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySectionTabs() {
    return Row(
      children: [
        Expanded(
          child: _sectionTab(
            label: 'Resumen',
            selected: _categorySection == CategoryDetailSection.summary,
            onTap: () {
              setState(() {
                _categorySection = CategoryDetailSection.summary;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _sectionTab(
            label: 'Vista previa de atributos',
            selected: _categorySection == CategoryDetailSection.attributes,
            onTap: () {
              setState(() {
                _categorySection = CategoryDetailSection.attributes;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF5CC) : Colors.white,
          border: Border.all(color: selected ? _catalogYellow : _catalogBorder),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _catalogText,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySummary(CatalogCategory category) {
    final parent = _categoryById(category.parentId);
    final children = _childrenOf(category.id);
    final relatedBrandIds = _savedRelations.entries
        .where((entry) {
          final rootId = category.parentId ?? category.id;
          return entry.value.contains(rootId);
        })
        .map((entry) => entry.key)
        .toSet();
    final effective = _effectiveAttributesFor(category.id);
    final ownCount = effective.where((item) => !item.inherited).length;
    final inheritedCount = effective.where((item) => item.inherited).length;
    final attributeCallback = widget.onManageCategoryAttributes;

    return Padding(
      key: const ValueKey('summary'),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabelValue(
            label: 'Ruta',
            value: parent == null
                ? category.name
                : '${parent.name} > ${category.name}',
          ),
          const SizedBox(height: 14),
          _LabelValue(
            label: 'Tipo',
            value: parent == null ? 'Categoría principal' : 'Subcategoría',
          ),
          if (category.description != null &&
              category.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _LabelValue(label: 'Descripción', value: category.description!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Subcategorías',
                  style: TextStyle(color: _catalogMuted, fontSize: 12),
                ),
              ),
              if (category.parentId == null)
                _SecondaryButton(
                  label: 'Añadir subcategoría',
                  icon: Icons.add_rounded,
                  onPressed: category.active
                      ? () => _showCategoryForm(
                          parentId: category.id,
                          createSubcategory: true,
                        )
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (category.parentId != null)
            Text(
              'Pertenece a ${parent?.name ?? 'una categoría superior'}.',
              style: const TextStyle(color: _catalogMuted),
            )
          else if (children.isEmpty)
            const Text('Sin subcategorías')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: children
                  .map(
                    (child) => ActionChip(
                      label: Text(child.name),
                      onPressed: () {
                        setState(() {
                          _selectedCategoryId = child.id;
                          _categorySection = CategoryDetailSection.summary;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  value: '${category.directProductCount}',
                  label: 'productos directos',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  value: '${category.includingDescendantProductCount}',
                  label: 'incluyendo subcategorías',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  value: '${relatedBrandIds.length}',
                  label: 'marcas habilitadas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: '$ownCount atributos propios'),
              _InfoPill(
                label: '$inheritedCount heredados',
                color: _catalogBlueSoft,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SecondaryButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: () => _showCategoryForm(existing: category),
              ),
              _SecondaryButton(
                label: 'Gestionar atributos',
                icon: Icons.tune_rounded,
                onPressed: attributeCallback == null
                    ? null
                    : () => attributeCallback(category.id),
              ),
              _SecondaryButton(
                label: 'Ver asignaciones',
                icon: Icons.link_rounded,
                onPressed: () {
                  final root = parent ?? category;
                  setState(() {
                    _tab = CatalogStructureTab.brandCategories;
                    _relationCategoryQuery = root.name;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            category.parentId == null
                ? 'Al desactivar esta categoría, sus subcategorías dejarán de '
                      'estar disponibles para nuevos productos, pero conservarán '
                      'su estado y sus datos históricos.'
                : 'La disponibilidad también depende de que la categoría '
                      'superior permanezca activa.',
            style: const TextStyle(
              color: _catalogMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeManager(CatalogCategory category) {
    final effective = _effectiveAttributesFor(category.id);
    final ownCount = effective.where((item) => !item.inherited).length;
    final inheritedCount = effective.where((item) => item.inherited).length;
    final callback = widget.onManageCategoryAttributes;

    return Padding(
      key: const ValueKey('attributes'),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _catalogBlueSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Esta es una vista previa. La creación, edición, orden y '
              'configuración avanzada se realizan únicamente en la '
              'subpantalla Gestionar atributos.',
              style: TextStyle(
                color: _catalogText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InfoPill(label: '$ownCount propios'),
              _InfoPill(
                label: '$inheritedCount heredados',
                color: _catalogBlueSoft,
              ),
              _PrimaryButton(
                label: 'Abrir gestión de atributos',
                icon: Icons.tune_rounded,
                onPressed: callback == null
                    ? null
                    : () => callback(category.id),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (effective.isEmpty)
            const _EmptyState(
              title: 'Sin atributos definidos',
              message:
                  'Abre Gestionar atributos para definir los datos técnicos.',
              compact: true,
            )
          else
            ...effective.map(_buildAttributeCard),
        ],
      ),
    );
  }

  Widget _buildAttributeCard(EffectiveCategoryAttribute item) {
    final attribute = item.definition;
    final details = <String>[
      _attributeTypeLabel(attribute.type),
      if (attribute.units.isNotEmpty) attribute.units.join(', '),
      if (attribute.required) 'Obligatorio',
      if (attribute.filterable) 'Filtrable',
      if (attribute.variantAxis) 'Posible eje',
      if (attribute.multiple) 'Selección múltiple',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.inherited ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(color: _catalogBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            attribute.variantAxis
                ? Icons.grid_view_rounded
                : Icons.data_object_rounded,
            color: attribute.active ? _catalogText : _catalogMuted,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      attribute.name,
                      style: const TextStyle(
                        color: _catalogText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _InfoPill(
                      label: item.inherited
                          ? 'Heredado de ${item.originCategory.name}'
                          : 'Propio de ${item.originCategory.name}',
                      color: item.inherited
                          ? _catalogBlueSoft
                          : const Color(0xFFF1F3F6),
                    ),
                    if (!attribute.active)
                      const _InfoPill(
                        label: 'Inactivo',
                        color: _catalogRedSoft,
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  details.join(' · '),
                  style: const TextStyle(
                    color: _catalogMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (attribute.options.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: attribute.options
                        .take(6)
                        .map((value) => _InfoPill(label: value))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCategories(double width) {
    final compact = width < 920;
    final companyPanel = _relationCompanyPanel();
    final brandPanel = _relationBrandPanel();
    final categoryPanel = _relationCategoryPanel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selecciona de izquierda a derecha',
          style: TextStyle(
            color: _catalogText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'La relación se guarda con categorías principales. '
          'Sus subcategorías quedan disponibles automáticamente.',
          style: TextStyle(color: _catalogMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (compact)
          Column(
            children: [
              companyPanel,
              const SizedBox(height: 12),
              brandPanel,
              const SizedBox(height: 12),
              categoryPanel,
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: companyPanel),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: brandPanel),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: categoryPanel),
            ],
          ),
        const SizedBox(height: 16),
        _relationSaveBar(),
      ],
    );
  }

  Widget _relationCompanyPanel() {
    return _SelectionPanel(
      title: '1 · Empresa',
      children: _companies.map((company) {
        final selected = company.id == _selectedCompanyId;
        return _SelectionTile(
          selected: selected,
          enabled: company.active,
          title: company.name,
          subtitle:
              '${company.brandCount} marcas · ${company.productCount} productos',
          onTap: () {
            setState(() {
              _selectedCompanyId = company.id;
              _selectedBrandId = _firstBrandIdFor(company.id);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _relationBrandPanel() {
    final companyBrands = _brands
        .where((brand) => brand.companyId == _selectedCompanyId)
        .toList();
    return _SelectionPanel(
      title: '2 · Marca',
      children: companyBrands.map((brand) {
        final selected = brand.id == _selectedBrandId;
        final count = (_workingRelations[brand.id] ?? const <String>{}).length;
        return _SelectionTile(
          selected: selected,
          enabled: brand.active,
          title: brand.name,
          subtitle: '$count categorías principales habilitadas',
          onTap: () => setState(() => _selectedBrandId = brand.id),
        );
      }).toList(),
    );
  }

  Widget _relationCategoryPanel() {
    final brand = _selectedBrand;
    if (brand == null) {
      return const _SelectionPanel(
        title: '3 · Categorías principales',
        children: [
          _EmptyState(
            title: 'Selecciona una marca',
            message: 'Luego podrás editar sus categorías.',
            compact: true,
          ),
        ],
      );
    }

    final rows = <Widget>[];
    for (final root in _categories.where((item) => item.parentId == null)) {
      _appendRelationCategoryRows(rows, root, 0, brand);
    }

    return _SelectionPanel(
      title: '3 · Categorías principales',
      header: TextFormField(
        onChanged: (value) {
          setState(() => _relationCategoryQuery = value);
        },
        initialValue: _relationCategoryQuery,
        decoration: const InputDecoration(
          hintText: 'Buscar categoría o subcategoría',
          prefixIcon: Icon(Icons.search_rounded),
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      children: rows,
    );
  }

  void _appendRelationCategoryRows(
    List<Widget> target,
    CatalogCategory category,
    int depth,
    CatalogBrand brand,
  ) {
    if (category.parentId != null) return;

    final children = _childrenOf(category.id);
    final query = _relationCategoryQuery.toLowerCase();
    final selfMatches = category.name.toLowerCase().contains(query);
    final childMatches = children.any(
      (item) => item.name.toLowerCase().contains(query),
    );
    if (_relationCategoryQuery.isNotEmpty &&
        !selfMatches &&
        !childMatches) {
      return;
    }

    final saved = _savedRelations[brand.id] ?? const <String>{};
    final working = _workingRelations[brand.id] ?? const <String>{};
    final checked = working.contains(category.id);
    final wasSaved = saved.contains(category.id);
    final relation = _relationFor(brand.id, category.id);
    final locked = relation?.isLocked ?? false;
    final added = checked && !wasSaved;
    final removalPending = !checked && wasSaved;

    target.add(
      _RelationCategoryTile(
        category: category,
        depth: 0,
        checked: checked,
        added: added,
        removalPending: removalPending,
        locked: locked,
        productCount: relation?.activeProductCount ?? 0,
        brandName: brand.name,
        onChanged: category.active
            ? (value) => _changeRelation(
                brand: brand,
                category: category,
                selected: value,
              )
            : null,
        onViewProducts: locked
            ? () => _showMessage(
                '${relation!.activeProductCount} productos activos de '
                '${brand.name} usan ${category.name}.',
              )
            : null,
      ),
    );

    if (children.isNotEmpty) {
      target.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(42, 0, 8, 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              const Text(
                'Incluye:',
                style: TextStyle(
                  color: _catalogMuted,
                  fontSize: 11,
                ),
              ),
              ...children.map(
                (child) => _InfoPill(
                  label: child.name,
                  color: child.active
                      ? const Color(0xFFF1F3F6)
                      : _catalogRedSoft,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _relationSaveBar() {
    final brand = _selectedBrand;
    if (brand == null) return const SizedBox.shrink();
    final saved = _savedRelations[brand.id] ?? const <String>{};
    final working = _workingRelations[brand.id] ?? const <String>{};
    final added = working.difference(saved).length;
    final removed = saved.difference(working).length;
    final changed = added > 0 || removed > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D5),
        border: Border.all(color: const Color(0xFFFFE17A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            _selectedCompany?.name ?? 'Empresa',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const Icon(Icons.arrow_forward_rounded, size: 18),
          Text(brand.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const Icon(Icons.arrow_forward_rounded, size: 18),
          Text(
            changed
                ? '$added ${added == 1 ? 'añadida' : 'añadidas'} · '
                      '$removed ${removed == 1 ? 'retirada' : 'retiradas'}'
                : '${working.length} categorías principales · Sin cambios',
          ),
          _PrimaryButton(
            label: 'Guardar cambios',
            onPressed: changed ? _saveRelations : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar({
    required String searchHint,
    required String createLabel,
    required VoidCallback onCreate,
    required bool showStatusFilters,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: (MediaQuery.sizeOf(context).width - 40)
                  .clamp(240.0, 480.0)
                  .toDouble(),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: _catalogBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: _catalogBorder),
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (secondaryLabel != null && onSecondary != null)
                  _SecondaryButton(
                    label: secondaryLabel,
                    onPressed: onSecondary,
                  ),
                _PrimaryButton(
                  label: createLabel,
                  icon: Icons.add_rounded,
                  onPressed: onCreate,
                ),
              ],
            ),
          ],
        ),
        if (showStatusFilters) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _filterChip(CatalogRecordFilter.all, 'Todas'),
              _filterChip(CatalogRecordFilter.active, 'Activas'),
              _filterChip(CatalogRecordFilter.inactive, 'Inactivas'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _filterChip(CatalogRecordFilter filter, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  bool _matchesStatus(bool active) {
    return switch (_filter) {
      CatalogRecordFilter.all => true,
      CatalogRecordFilter.active => active,
      CatalogRecordFilter.inactive => !active,
    };
  }

  List<CatalogCategory> _childrenOf(String parentId) {
    return _categories
        .where((category) => category.parentId == parentId)
        .toList();
  }

  List<CatalogCategory> _descendantsOf(String categoryId) {
    final result = <CatalogCategory>[];
    for (final child in _childrenOf(categoryId)) {
      result.add(child);
      result.addAll(_descendantsOf(child.id));
    }
    return result;
  }

  List<CatalogCategory> _ancestorChain(String categoryId) {
    final result = <CatalogCategory>[];
    var current = _categoryById(categoryId);
    final visited = <String>{};
    while (current != null && visited.add(current.id)) {
      result.add(current);
      current = _categoryById(current.parentId);
    }
    return result;
  }

  List<EffectiveCategoryAttribute> _effectiveAttributesFor(String categoryId) {
    final chain = _ancestorChain(categoryId);
    final result = <EffectiveCategoryAttribute>[];
    for (final origin in chain.reversed) {
      final definitions = _attributes
          .where((attribute) => attribute.categoryId == origin.id)
          .toList();
      for (final definition in definitions) {
        result.add(
          EffectiveCategoryAttribute(
            definition: definition,
            originCategory: origin,
            inherited: origin.id != categoryId,
          ),
        );
      }
    }
    return result;
  }

  CatalogCompany? _companyById(String? id) {
    return _firstWhereOrNull(_companies, (item) => item.id == id);
  }

  CatalogCategory? _categoryById(String? id) {
    return _firstWhereOrNull(_categories, (item) => item.id == id);
  }

  BrandCategoryRelation? _relationFor(String brandId, String categoryId) {
    return _firstWhereOrNull(
      _relations,
      (item) => item.brandId == brandId && item.categoryId == categoryId,
    );
  }

  void _changeRelation({
    required CatalogBrand brand,
    required CatalogCategory category,
    required bool selected,
  }) {
    if (category.parentId != null) {
      _showMessage(
        'Las subcategorías se habilitan mediante su categoría principal.',
        error: true,
      );
      return;
    }

    final relation = _relationFor(brand.id, category.id);
    if (!selected && (relation?.isLocked ?? false)) {
      _showMessage(
        'No puede retirarse: ${relation!.activeProductCount} productos activos '
        'usan esta relación.',
        error: true,
      );
      return;
    }

    setState(() {
      final working = _workingRelations.putIfAbsent(
        brand.id,
        () => <String>{},
      );
      if (selected) {
        working.add(category.id);
      } else {
        working.remove(category.id);
      }
    });
  }
) {
    final relation = _relationFor(brand.id, category.id);
    if (!selected && (relation?.isLocked ?? false)) {
      _showMessage(
        'No puede retirarse: ${relation!.activeProductCount} productos activos '
        'usan esta relación.',
        error: true,
      );
      return;
    }

    setState(() {
      final working = _workingRelations.putIfAbsent(brand.id, () => <String>{});
      if (selected) {
        working.add(category.id);
        if (_includeChildrenWhenSelecting) {
          working.addAll(
            _descendantsOf(
              category.id,
            ).where((item) => item.active).map((item) => item.id),
          );
        }
      } else {
        working.remove(category.id);
      }
    });
  }

  void _saveRelations() {
    final brand = _selectedBrand;
    if (brand == null) return;
    final working = _workingRelations[brand.id] ?? const <String>{};
    final oldByCategory = {
      for (final relation in _relations.where(
        (item) => item.brandId == brand.id,
      ))
        relation.categoryId: relation,
    };
    final next = _relations
        .where((relation) => relation.brandId != brand.id)
        .toList();
    for (final categoryId in working) {
      next.add(
        oldByCategory[categoryId] ??
            BrandCategoryRelation(
              brandId: brand.id,
              categoryId: categoryId,
              activeProductCount: 0,
            ),
      );
    }

    setState(() {
      _relations = next;
      _savedRelations[brand.id] = Set<String>.from(working);
    });
    widget.onRelationsChanged?.call(List.unmodifiable(_relations));
    _showMessage('Categorías de ${brand.name} actualizadas.');
  }

  Future<void> _showCompanyForm({CatalogCompany? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name);
    final rucController = TextEditingController(text: existing?.ruc);
    final phoneController = TextEditingController(text: existing?.phone);
    final addressController = TextEditingController(text: existing?.address);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            existing == null ? 'Nueva empresa' : 'Editar empresa',
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      key: const Key('estructura_empresa_nombre'),
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                      ),
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) {
                          return 'El nombre es obligatorio.';
                        }
                        final duplicate = _companies.any(
                          (item) =>
                              item.id != existing?.id &&
                              item.name.trim().toLowerCase() ==
                                  name.toLowerCase(),
                        );
                        return duplicate
                            ? 'Ya existe una empresa con ese nombre.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: rucController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'RUC (opcional)',
                      ),
                      validator: (value) {
                        final ruc = value?.trim() ?? '';
                        if (ruc.isEmpty) return null;
                        return RegExp(r'^\d{11}$').hasMatch(ruc)
                            ? null
                            : 'El RUC debe contener 11 dígitos.';
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Dirección (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'El estado se administra desde las acciones de la '
                      'empresa para mostrar antes el impacto.',
                      style: TextStyle(
                        color: _catalogMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      rucController.dispose();
      phoneController.dispose();
      addressController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final ruc = _emptyToNull(rucController.text);
    final phone = _emptyToNull(phoneController.text);
    final address = _emptyToNull(addressController.text);
    nameController.dispose();
    rucController.dispose();
    phoneController.dispose();
    addressController.dispose();

    setState(() {
      if (existing == null) {
        _companies.add(
          CatalogCompany(
            id: 'company-${DateTime.now().microsecondsSinceEpoch}',
            name: name,
            initials: _initialsFor(name),
            ruc: ruc,
            phone: phone,
            address: address,
            brandCount: 0,
            productCount: 0,
            active: true,
          ),
        );
      } else {
        final index = _companies.indexWhere(
          (item) => item.id == existing.id,
        );
        _companies[index] = existing.copyWith(
          name: name,
          initials: _initialsFor(name),
          ruc: ruc,
          phone: phone,
          address: address,
          active: existing.active,
        );
      }
    });
    widget.onCompaniesChanged?.call(List.unmodifiable(_companies));
  }
) async {
    final nameController = TextEditingController(text: existing?.name);
    final rucController = TextEditingController(text: existing?.ruc);
    final phoneController = TextEditingController(text: existing?.phone);
    final addressController = TextEditingController(text: existing?.address);
    var active = existing?.active ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Nueva empresa' : 'Editar empresa',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                        ),
                      ),
                      TextField(
                        controller: rucController,
                        decoration: const InputDecoration(
                          labelText: 'RUC (opcional)',
                        ),
                      ),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (opcional)',
                        ),
                      ),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección (opcional)',
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Empresa activa'),
                        value: active,
                        onChanged: (value) {
                          setDialogState(() => active = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved != true || !mounted) return;

    setState(() {
      final name = nameController.text.trim();
      if (existing == null) {
        _companies.add(
          CatalogCompany(
            id: 'company-${DateTime.now().microsecondsSinceEpoch}',
            name: name,
            initials: _initialsFor(name),
            ruc: _emptyToNull(rucController.text),
            phone: _emptyToNull(phoneController.text),
            address: _emptyToNull(addressController.text),
            brandCount: 0,
            productCount: 0,
            active: active,
          ),
        );
      } else {
        final index = _companies.indexWhere((item) => item.id == existing.id);
        _companies[index] = existing.copyWith(
          name: name,
          initials: _initialsFor(name),
          ruc: _emptyToNull(rucController.text),
          phone: _emptyToNull(phoneController.text),
          address: _emptyToNull(addressController.text),
          active: active,
        );
      }
    });
    widget.onCompaniesChanged?.call(List.unmodifiable(_companies));
  }

  Future<void> _showBrandForm({CatalogBrand? existing}) async {
    final availableCompanies = _companies
        .where(
          (company) =>
              company.active || company.id == existing?.companyId,
        )
        .toList();
    if (availableCompanies.isEmpty) {
      _showMessage('Primero registra una empresa activa.', error: true);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name);
    var companyId =
        existing?.companyId ??
        _selectedCompanyId ??
        availableCompanies.first.id;
    final ownerLocked = existing != null && existing.productCount > 0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Nueva marca' : 'Editar marca',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: companyId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Empresa propietaria *',
                          ),
                          items: availableCompanies
                              .map(
                                (company) => DropdownMenuItem(
                                  value: company.id,
                                  child: Text(company.name),
                                ),
                              )
                              .toList(),
                          validator: (value) => value == null
                              ? 'Selecciona una empresa.'
                              : null,
                          onChanged: ownerLocked
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setDialogState(() => companyId = value);
                                },
                        ),
                        if (ownerLocked) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _catalogBlueSoft,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'La empresa propietaria no puede cambiarse '
                              'porque esta marca tiene '
                              '${existing!.productCount} productos.',
                              style: const TextStyle(
                                color: _catalogText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('estructura_marca_nombre'),
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre *',
                          ),
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) {
                              return 'El nombre es obligatorio.';
                            }
                            final duplicate = _brands.any(
                              (item) =>
                                  item.id != existing?.id &&
                                  item.companyId == companyId &&
                                  item.name.trim().toLowerCase() ==
                                      name.toLowerCase(),
                            );
                            return duplicate
                                ? 'La empresa ya tiene una marca con ese nombre.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Las categorías de la marca se administran en '
                          'Categorías por marca.',
                          style: TextStyle(
                            color: _catalogMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      return;
    }

    final name = nameController.text.trim();
    nameController.dispose();

    setState(() {
      if (existing == null) {
        _brands.add(
          CatalogBrand(
            id: 'brand-${DateTime.now().microsecondsSinceEpoch}',
            companyId: companyId,
            name: name,
            initials: _initialsFor(name),
            productCount: 0,
            active: true,
          ),
        );
      } else {
        final index = _brands.indexWhere(
          (item) => item.id == existing.id,
        );
        _brands[index] = existing.copyWith(
          companyId: companyId,
          name: name,
          initials: _initialsFor(name),
          active: existing.active,
        );
      }
    });
    widget.onBrandsChanged?.call(List.unmodifiable(_brands));
  }
) async {
    if (_companies.isEmpty) {
      _showMessage('Primero registra una empresa.', error: true);
      return;
    }
    final nameController = TextEditingController(text: existing?.name);
    var companyId =
        existing?.companyId ?? _selectedCompanyId ?? _companies.first.id;
    var active = existing?.active ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Nueva marca' : 'Editar marca'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: companyId,
                      decoration: const InputDecoration(
                        labelText: 'Empresa propietaria *',
                      ),
                      items: _companies
                          .where((company) => company.active)
                          .map(
                            (company) => DropdownMenuItem(
                              value: company.id,
                              child: Text(company.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => companyId = value);
                        }
                      },
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre *'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Marca activa'),
                      value: active,
                      onChanged: (value) {
                        setDialogState(() => active = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved != true || !mounted) return;

    setState(() {
      final name = nameController.text.trim();
      if (existing == null) {
        _brands.add(
          CatalogBrand(
            id: 'brand-${DateTime.now().microsecondsSinceEpoch}',
            companyId: companyId,
            name: name,
            initials: _initialsFor(name),
            productCount: 0,
            active: active,
          ),
        );
      } else {
        final index = _brands.indexWhere((item) => item.id == existing.id);
        _brands[index] = existing.copyWith(
          companyId: companyId,
          name: name,
          initials: _initialsFor(name),
          active: active,
        );
      }
    });
    widget.onBrandsChanged?.call(List.unmodifiable(_brands));
  }

  Future<void> _showCategoryForm({
    CatalogCategory? existing,
    String? parentId,
    bool createSubcategory = false,
  }) async {
    final isExistingChild = existing?.parentId != null;
    final isSubcategory = createSubcategory || isExistingChild;
    var selectedParentId = existing?.parentId ?? parentId;

    if (isSubcategory && selectedParentId == null) {
      _showMessage(
        'Selecciona primero una categoría principal.',
        error: true,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name);
    final descriptionController = TextEditingController(
      text: existing?.description,
    );
    final activeRoots = _categories
        .where(
          (item) =>
              item.parentId == null &&
              (item.active || item.id == selectedParentId),
        )
        .toList();

    final title = existing == null
        ? isSubcategory
              ? 'Nueva subcategoría'
              : 'Nueva categoría raíz'
        : isExistingChild
        ? 'Editar subcategoría'
        : 'Editar categoría raíz';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSubcategory)
                          DropdownButtonFormField<String>(
                            initialValue: selectedParentId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Categoría superior *',
                              helperText:
                                  'La subcategoría heredará sus atributos.',
                            ),
                            items: activeRoots
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.name),
                                  ),
                                )
                                .toList(),
                            validator: (value) => value == null
                                ? 'Selecciona una categoría superior.'
                                : null,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedParentId = value;
                              });
                            },
                          )
                        else
                          const InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Nivel',
                            ),
                            child: Text('Categoría principal'),
                          ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('estructura_categoria_nombre'),
                          controller: nameController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: isSubcategory
                                ? 'Nombre de la subcategoría *'
                                : 'Nombre de la categoría *',
                          ),
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) {
                              return 'El nombre es obligatorio.';
                            }
                            final effectiveParent = isSubcategory
                                ? selectedParentId
                                : null;
                            final duplicate = _categories.any(
                              (item) =>
                                  item.id != existing?.id &&
                                  item.parentId == effectiveParent &&
                                  item.name.trim().toLowerCase() ==
                                      name.toLowerCase(),
                            );
                            return duplicate
                                ? 'Ya existe un registro con ese nombre '
                                      'en el mismo nivel.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _catalogBlueSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isSubcategory
                                ? 'Las marcas se relacionan con la categoría '
                                      'principal. Esta subcategoría quedará '
                                      'disponible automáticamente.'
                                : 'Después podrás añadir subcategorías y '
                                      'gestionar los atributos técnicos.',
                            style: const TextStyle(
                              color: _catalogText,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(existing == null ? 'Crear' : 'Guardar cambios'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      descriptionController.dispose();
      return;
    }

    final savedName = nameController.text.trim();
    final savedDescription = _emptyToNull(descriptionController.text);
    nameController.dispose();
    descriptionController.dispose();

    setState(() {
      if (existing == null) {
        final created = CatalogCategory(
          id: 'category-${DateTime.now().microsecondsSinceEpoch}',
          parentId: isSubcategory ? selectedParentId : null,
          name: savedName,
          description: savedDescription,
          directProductCount: 0,
          includingDescendantProductCount: 0,
          active: true,
        );
        _categories.add(created);
        _selectedCategoryId = created.id;
      } else {
        final index = _categories.indexWhere(
          (item) => item.id == existing.id,
        );
        _categories[index] = existing.copyWith(
          parentId: isExistingChild ? selectedParentId : null,
          clearParent: !isExistingChild,
          name: savedName,
          description: savedDescription,
          active: existing.active,
        );
        _selectedCategoryId = existing.id;
      }
      _categorySection = CategoryDetailSection.summary;
    });
    widget.onCategoriesChanged?.call(List.unmodifiable(_categories));
  }
) async {
    final nameController = TextEditingController(text: existing?.name);
    final descriptionController = TextEditingController(
      text: existing?.description,
    );
    var parentId = existing?.parentId;
    var active = existing?.active ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final invalidParents = existing == null
                ? const <String>{}
                : <String>{
                    existing.id,
                    ..._descendantsOf(existing.id).map((item) => item.id),
                  };
            return AlertDialog(
              title: Text(
                existing == null ? 'Nueva categoría' : 'Editar categoría',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                        ),
                      ),
                      DropdownButtonFormField<String?>(
                        value: parentId,
                        decoration: const InputDecoration(
                          labelText: 'Categoría superior (opcional)',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Nivel raíz'),
                          ),
                          ..._categories
                              .where(
                                (item) =>
                                    item.active &&
                                    !invalidParents.contains(item.id),
                              )
                              .map(
                                (item) => DropdownMenuItem<String?>(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                              ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => parentId = value);
                        },
                      ),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Categoría activa'),
                        value: active,
                        onChanged: (value) {
                          setDialogState(() => active = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final duplicate = _categories.any(
                      (item) =>
                          item.id != existing?.id &&
                          item.parentId == parentId &&
                          item.name.toLowerCase() == name.toLowerCase(),
                    );
                    if (name.isEmpty || duplicate) {
                      _showMessage(
                        duplicate
                            ? 'Ya existe una categoría con ese nombre dentro del mismo nivel.'
                            : 'El nombre es obligatorio.',
                        error: true,
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved != true || !mounted) return;

    setState(() {
      final name = nameController.text.trim();
      if (existing == null) {
        final created = CatalogCategory(
          id: 'category-${DateTime.now().microsecondsSinceEpoch}',
          parentId: parentId,
          name: name,
          description: _emptyToNull(descriptionController.text),
          directProductCount: 0,
          includingDescendantProductCount: 0,
          active: active,
        );
        _categories.add(created);
        _selectedCategoryId = created.id;
      } else {
        final index = _categories.indexWhere((item) => item.id == existing.id);
        _categories[index] = existing.copyWith(
          parentId: parentId,
          clearParent: parentId == null,
          name: name,
          description: _emptyToNull(descriptionController.text),
          active: active,
        );
      }
    });
    widget.onCategoriesChanged?.call(List.unmodifiable(_categories));
  }

) async {
    final nameController = TextEditingController(text: existing?.name);
    final unitsController = TextEditingController(
      text: existing?.units.join(', '),
    );
    final optionsController = TextEditingController(
      text: existing?.options.join(', '),
    );
    var type = existing?.type ?? CategoryAttributeType.text;
    var required = existing?.required ?? false;
    var filterable = existing?.filterable ?? false;
    var variantAxis = existing?.variantAxis ?? false;
    var multiple = existing?.multiple ?? false;
    var active = existing?.active ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Nuevo atributo' : 'Editar atributo',
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Categoría: ${category.name}',
                          style: const TextStyle(
                            color: _catalogMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          hintText: 'Ej. Diámetro',
                        ),
                      ),
                      DropdownButtonFormField<CategoryAttributeType>(
                        value: type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de dato *',
                        ),
                        items: CategoryAttributeType.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(_attributeTypeLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            type = value;
                            if (type != CategoryAttributeType.list) {
                              multiple = false;
                            }
                          });
                        },
                      ),
                      if (type == CategoryAttributeType.number)
                        TextField(
                          controller: unitsController,
                          decoration: const InputDecoration(
                            labelText: 'Unidades permitidas',
                            hintText: 'mm, pulgada',
                          ),
                        ),
                      if (type == CategoryAttributeType.list)
                        TextField(
                          controller: optionsController,
                          decoration: const InputDecoration(
                            labelText: 'Valores permitidos *',
                            hintText: 'HSS, Cobalto, Carburo',
                          ),
                        ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Obligatorio'),
                        value: required,
                        onChanged: (value) {
                          setDialogState(() => required = value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Filtrable'),
                        value: filterable,
                        onChanged: (value) {
                          setDialogState(() => filterable = value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Puede generar variantes'),
                        subtitle: const Text(
                          'Podrá utilizarse como eje en lista o matriz.',
                        ),
                        value: variantAxis,
                        onChanged: (value) {
                          setDialogState(() => variantAxis = value);
                        },
                      ),
                      if (type == CategoryAttributeType.list)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Selección múltiple'),
                          value: multiple,
                          onChanged: (value) {
                            setDialogState(() => multiple = value);
                          },
                        ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Atributo activo'),
                        value: active,
                        onChanged: (value) {
                          setDialogState(() => active = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final duplicate = _effectiveAttributesFor(category.id).any(
                      (item) =>
                          item.definition.id != existing?.id &&
                          item.definition.name.toLowerCase() ==
                              name.toLowerCase(),
                    );
                    final missingOptions =
                        type == CategoryAttributeType.list &&
                        _splitValues(optionsController.text).isEmpty;
                    if (name.isEmpty || duplicate || missingOptions) {
                      _showMessage(
                        duplicate
                            ? 'Ya existe un atributo propio o heredado con ese nombre.'
                            : missingOptions
                            ? 'Una lista necesita valores permitidos.'
                            : 'El nombre es obligatorio.',
                        error: true,
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(
                    existing == null ? 'Guardar atributo' : 'Guardar cambios',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved != true || !mounted) return;

    final definition = CategoryAttributeDefinition(
      id: existing?.id ?? 'attribute-${DateTime.now().microsecondsSinceEpoch}',
      categoryId: category.id,
      name: nameController.text.trim(),
      type: type,
      units: type == CategoryAttributeType.number
          ? _splitValues(unitsController.text)
          : const [],
      options: type == CategoryAttributeType.list
          ? _splitValues(optionsController.text)
          : const [],
      required: required,
      filterable: filterable,
      variantAxis: variantAxis,
      multiple: multiple,
      active: active,
      usedByProductCount: existing?.usedByProductCount ?? 0,
    );

    setState(() {
      if (existing == null) {
        _attributes.add(definition);
      } else {
        final index = _attributes.indexWhere((item) => item.id == existing.id);
        _attributes[index] = definition;
      }
    });
    widget.onAttributesChanged?.call(List.unmodifiable(_attributes));
  }

  Future<void> _confirmCompanyStatusChange(CatalogCompany company) async {
    if (company.active) {
      final brands = _brands.where(
        (brand) => brand.companyId == company.id && brand.active,
      );
      final confirmed = await _confirm(
        title: 'Desactivar empresa',
        message:
            'Sus ${brands.length} marcas dejarán de estar disponibles para '
            'registrar productos. El historial se conservará.',
        action: 'Desactivar',
      );
      if (!confirmed) return;
    }

    setState(() {
      final index = _companies.indexWhere((item) => item.id == company.id);
      _companies[index] = company.copyWith(active: !company.active);
    });
    widget.onCompaniesChanged?.call(List.unmodifiable(_companies));
  }

  Future<void> _confirmBrandStatusChange(
    CatalogBrand brand,
  ) async {
    final company = _companyById(brand.companyId);
    if (!brand.active && (company == null || !company.active)) {
      _showMessage(
        'Activa primero la empresa propietaria.',
        error: true,
      );
      return;
    }

    if (brand.active) {
      final confirmed = await _confirm(
        title: 'Desactivar marca',
        message:
            'La marca dejará de estar disponible para nuevos productos. '
            'Sus ${brand.productCount} productos conservarán su clasificación '
            'y el historial.',
        action: 'Desactivar',
      );
      if (!confirmed) return;
    }

    setState(() {
      final index = _brands.indexWhere((item) => item.id == brand.id);
      _brands[index] = brand.copyWith(active: !brand.active);
    });
    widget.onBrandsChanged?.call(List.unmodifiable(_brands));
  }

  Future<void> _confirmCategoryStatusChange(
    CatalogCategory category,
  ) async {
    if (category.active) {
      final descendants = _descendantsOf(category.id);
      final confirmed = await _confirm(
        title: category.parentId == null
            ? 'Desactivar categoría'
            : 'Desactivar subcategoría',
        message: category.parentId == null
            ? 'La categoría dejará de estar disponible para nuevos productos. '
                  'Sus ${descendants.length} subcategorías quedarán bloqueadas '
                  'por dependencia, pero conservarán su estado y el historial.'
            : 'La subcategoría dejará de estar disponible para nuevos '
                  'productos. El historial se conservará.',
        action: 'Desactivar',
      );
      if (!confirmed) return;
    } else {
      final parent = _categoryById(category.parentId);
      if (parent != null && !parent.active) {
        _showMessage(
          'Primero activa la categoría superior ${parent.name}.',
          error: true,
        );
        return;
      }
    }

    setState(() {
      final index = _categories.indexWhere(
        (item) => item.id == category.id,
      );
      _categories[index] = category.copyWith(active: !category.active);
    });
    widget.onCategoriesChanged?.call(List.unmodifiable(_categories));
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(action),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? _catalogRed : _catalogText,
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _catalogBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: _catalogYellow,
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _catalogText,
          side: const BorderSide(color: _catalogBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials, required this.color});

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: color.computeLuminance() > .55 ? Colors.black : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return _InfoPill(
      label: active ? 'Activa' : 'Inactiva',
      color: active ? _catalogGreenSoft : _catalogRedSoft,
      textColor: active ? _catalogGreen : _catalogRed,
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    this.color = const Color(0xFFF1F3F6),
    this.textColor = _catalogText,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _catalogMuted, fontSize: 11)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: _catalogText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _catalogText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: _catalogMuted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _catalogMuted, fontSize: 12)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: _catalogText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CategoryTreeTile extends StatelessWidget {
  const _CategoryTreeTile({
    required this.category,
    required this.depth,
    required this.selected,
    required this.hasChildren,
    required this.onTap,
    required this.onEdit,
    required this.onToggleStatus,
    this.onAddChild,
  });

  final CatalogCategory category;
  final int depth;
  final bool selected;
  final bool hasChildren;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onAddChild;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF5CC) : Colors.white,
        border: Border.all(
          color: selected ? _catalogYellow : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: Row(
            children: [
              SizedBox(width: 12 + depth * 22),
              Icon(
                hasChildren
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.subdirectory_arrow_right_rounded,
                size: 18,
                color: _catalogMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: category.active
                        ? _catalogText
                        : _catalogMuted,
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${category.includingDescendantProductCount} prod.',
                style: const TextStyle(
                  color: _catalogMuted,
                  fontSize: 12,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Acciones para ${category.name}',
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'add_child') onAddChild?.call();
                  if (value == 'status') onToggleStatus();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar'),
                  ),
                  if (onAddChild != null)
                    const PopupMenuItem(
                      value: 'add_child',
                      child: Text('Añadir subcategoría'),
                    ),
                  PopupMenuItem(
                    value: 'status',
                    child: Text(
                      category.active ? 'Desactivar' : 'Activar',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.title,
    required this.children,
    this.header,
  });

  final String title;
  final Widget? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _CatalogCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _catalogText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (header != null) ...[const SizedBox(height: 12), header!],
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: SingleChildScrollView(child: Column(children: children)),
          ),
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF5CC) : Colors.white,
        border: Border.all(color: selected ? _catalogYellow : _catalogBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        enabled: enabled,
        minTileHeight: 58,
        leading: Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected ? const Color(0xFFE7AD00) : _catalogBorder,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _catalogText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: _catalogMuted, fontSize: 11),
        ),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

class _RelationCategoryTile extends StatelessWidget {
  const _RelationCategoryTile({
    required this.category,
    required this.depth,
    required this.checked,
    required this.added,
    required this.removalPending,
    required this.locked,
    required this.productCount,
    required this.brandName,
    required this.onChanged,
    required this.onViewProducts,
  });

  final CatalogCategory category;
  final int depth;
  final bool checked;
  final bool added;
  final bool removalPending;
  final bool locked;
  final int productCount;
  final String brandName;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onViewProducts;

  @override
  Widget build(BuildContext context) {
    final status = added
        ? 'Añadida en esta edición'
        : removalPending
        ? 'Eliminación pendiente'
        : locked
        ? 'Vinculada · $productCount productos activos'
        : checked
        ? 'Ya vinculada'
        : 'Disponible';

    return Container(
      margin: EdgeInsets.only(left: depth * 20.0, bottom: 7),
      decoration: BoxDecoration(
        color: removalPending
            ? _catalogRedSoft
            : added
            ? _catalogGreenSoft
            : checked
            ? const Color(0xFFFFFAE8)
            : Colors.white,
        border: Border.all(
          color: removalPending
              ? const Color(0xFFF4A6A1)
              : added
              ? const Color(0xFF99D6B7)
              : checked
              ? _catalogYellow
              : _catalogBorder,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CheckboxListTile(
        value: checked,
        onChanged: onChanged == null
            ? null
            : (value) => onChanged!(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        secondary: locked
            ? IconButton(
                tooltip: 'Ver productos afectados de $brandName',
                onPressed: onViewProducts,
                icon: const Icon(Icons.lock_outline_rounded),
              )
            : null,
        title: Text(
          category.name,
          style: const TextStyle(
            color: _catalogText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          status,
          style: TextStyle(
            color: removalPending
                ? _catalogRed
                : added
                ? _catalogGreen
                : _catalogMuted,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    this.compact = false,
  });

  final String title;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _catalogBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: _catalogMuted,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _catalogText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _catalogMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

String _attributeTypeLabel(CategoryAttributeType type) {
  return switch (type) {
    CategoryAttributeType.text => 'Texto',
    CategoryAttributeType.number => 'Número',
    CategoryAttributeType.list => 'Lista',
    CategoryAttributeType.boolean => 'Sí / No',
    CategoryAttributeType.date => 'Fecha',
  };
}

String _initialsFor(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '—';
  if (parts.length == 1) {
    final end = parts.first.length >= 2 ? 2 : parts.first.length;
    return parts.first.substring(0, end).toUpperCase();
  }
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

