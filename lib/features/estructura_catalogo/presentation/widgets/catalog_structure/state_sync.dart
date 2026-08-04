part of '../catalog_structure_panel.dart';

extension _CatalogStateSync on _CatalogStructurePanelState {
  int _companiesFingerprint(List<CatalogCompany> items) => Object.hashAll(
    items.map(
      (item) => Object.hash(
        item.id,
        item.name,
        item.initials,
        item.ruc,
        item.phone,
        item.address,
        item.brandCount,
        item.productCount,
        item.active,
      ),
    ),
  );

  int _brandsFingerprint(List<CatalogBrand> items) => Object.hashAll(
    items.map(
      (item) => Object.hash(
        item.id,
        item.companyId,
        item.name,
        item.initials,
        item.productCount,
        item.active,
      ),
    ),
  );

  int _categoriesFingerprint(List<CatalogCategory> items) => Object.hashAll(
    items.map(
      (item) => Object.hash(
        item.id,
        item.parentId,
        item.name,
        item.description,
        item.directProductCount,
        item.includingDescendantProductCount,
        item.active,
      ),
    ),
  );

  int _attributesFingerprint(List<CategoryAttributeDefinition> items) =>
      Object.hashAll(
        items.map(
          (item) => Object.hash(
            item.id,
            item.categoryId,
            item.name,
            item.type,
            Object.hashAll(item.units),
            Object.hashAll(item.options),
            item.required,
            item.filterable,
            item.variantAxis,
            item.multiple,
            item.active,
            item.usedByProductCount,
          ),
        ),
      );

  int _relationsFingerprint(List<BrandCategoryRelation> items) =>
      Object.hashAll(
        items.map(
          (item) => Object.hash(
            item.brandId,
            item.categoryId,
            item.activeProductCount,
          ),
        ),
      );

  Map<String, Set<String>> _relationMap(List<BrandCategoryRelation> source) {
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
}
