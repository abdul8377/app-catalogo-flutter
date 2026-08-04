part of '../widgets/catalog_structure_panel.dart';

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
