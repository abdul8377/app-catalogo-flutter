import 'package:flutter/material.dart';

part '../models/catalog_structure_models.dart';
part 'catalog_structure/brand_categories_tab.dart';
part 'catalog_structure/brand_form.dart';
part 'catalog_structure/brands_tab.dart';
part 'catalog_structure/categories_tab.dart';
part 'catalog_structure/category_attributes.dart';
part 'catalog_structure/category_form.dart';
part 'catalog_structure/category_summary.dart';
part 'catalog_structure/category_tree_widgets.dart';
part 'catalog_structure/companies_tab.dart';
part 'catalog_structure/company_form.dart';
part 'catalog_structure/dialog_form_widgets.dart';
part 'catalog_structure/empty_state.dart';
part 'catalog_structure/header_and_tabs.dart';
part 'catalog_structure/relation_category_tile.dart';
part 'catalog_structure/selection_widgets.dart';
part 'catalog_structure/state_sync.dart';
part 'catalog_structure/status_actions.dart';
part 'catalog_structure/status_metric_widgets.dart';
part 'catalog_structure/toolbar_and_relations.dart';

// ============================================================================
// PANEL DE ESTRUCTURA DEL CATÁLOGO
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
const _catalogYellowSoft = Color(0xFFFFF4CC);
const _catalogBlueSoft = _catalogYellowSoft;

ThemeData _catalogModuleTheme(BuildContext context) {
  final base = Theme.of(context);
  const overlay = Color(0x26FFC500);
  const shadow = Color(0x52FFC500);
  const focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: _catalogYellow, width: 1.6),
    borderRadius: BorderRadius.all(Radius.circular(11)),
  );

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: _catalogYellow,
      onPrimary: Colors.black,
      secondary: _catalogYellow,
      onSecondary: Colors.black,
      surfaceTint: _catalogYellow,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _catalogYellow,
        foregroundColor: Colors.black,
        overlayColor: overlay,
        shadowColor: shadow,
        elevation: 1,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _catalogText,
        side: const BorderSide(color: _catalogYellow),
        overlayColor: overlay,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _catalogText,
        overlayColor: overlay,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: _catalogYellowSoft,
      checkmarkColor: Colors.black,
      side: const BorderSide(color: _catalogYellow),
      labelStyle: const TextStyle(color: _catalogText),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: Colors.white,
      focusedBorder: focusedBorder,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _catalogBorder),
        borderRadius: BorderRadius.all(Radius.circular(11)),
      ),
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: _catalogBorder),
        borderRadius: BorderRadius.all(Radius.circular(11)),
      ),
    ),
  );
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
    this.onAttributesChanged,
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
  final ValueChanged<List<CategoryAttributeDefinition>>? onAttributesChanged;
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
  String? _brandCompanyFilterId;

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
    _brandCompanyFilterId = null;
    _savedRelations = _relationMap(_relations);
    _workingRelations = _copyRelationMap(_savedRelations);
  }

  @override
  void didUpdateWidget(covariant CatalogStructurePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final companiesChanged =
        _companiesFingerprint(oldWidget.companies) !=
        _companiesFingerprint(widget.companies);
    final brandsChanged =
        _brandsFingerprint(oldWidget.brands) !=
        _brandsFingerprint(widget.brands);
    final categoriesChanged =
        _categoriesFingerprint(oldWidget.categories) !=
        _categoriesFingerprint(widget.categories);
    final attributesChanged =
        _attributesFingerprint(oldWidget.attributes) !=
        _attributesFingerprint(widget.attributes);
    final relationsChanged =
        _relationsFingerprint(oldWidget.relations) !=
        _relationsFingerprint(widget.relations);

    final selectedCategoryName = _firstWhereOrNull(
      _categories,
      (item) => item.id == _selectedCategoryId,
    )?.name;
    final selectedCompanyName = _firstWhereOrNull(
      _companies,
      (item) => item.id == _selectedCompanyId,
    )?.name;
    final selectedBrandName = _firstWhereOrNull(
      _brands,
      (item) => item.id == _selectedBrandId,
    )?.name;

    if (companiesChanged) _companies = [...widget.companies];
    if (brandsChanged) _brands = [...widget.brands];
    if (categoriesChanged) _categories = [...widget.categories];
    if (attributesChanged) _attributes = [...widget.attributes];
    if (relationsChanged) {
      _relations = [...widget.relations];
      _savedRelations = _relationMap(_relations);
      _workingRelations = _copyRelationMap(_savedRelations);
    }

    if (_selectedCategoryId != null &&
        !_categories.any((item) => item.id == _selectedCategoryId)) {
      _selectedCategoryId = _firstWhereOrNull(
        _categories,
        (item) => item.name == selectedCategoryName,
      )?.id;
      _selectedCategoryId ??= _categories.isEmpty ? null : _categories.first.id;
    }

    if (_selectedCompanyId != null &&
        !_companies.any((item) => item.id == _selectedCompanyId)) {
      _selectedCompanyId = _firstWhereOrNull(
        _companies,
        (item) => item.name == selectedCompanyName,
      )?.id;
      _selectedCompanyId ??= _companies.isEmpty ? null : _companies.first.id;
    }

    if (_selectedBrandId != null &&
        !_brands.any((item) => item.id == _selectedBrandId)) {
      _selectedBrandId = _firstWhereOrNull(
        _brands,
        (item) => item.name == selectedBrandName,
      )?.id;
      _selectedBrandId ??= _firstBrandIdFor(_selectedCompanyId);
    }

    if (_brandCompanyFilterId != null &&
        !_companies.any((item) => item.id == _brandCompanyFilterId)) {
      _brandCompanyFilterId = null;
    }
  }

  void _update(VoidCallback callback) => setState(callback);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _catalogModuleTheme(context),
      child: ColoredBox(
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
      ),
    );
  }
}
