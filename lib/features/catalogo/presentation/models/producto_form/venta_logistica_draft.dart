import 'package:flutter/foundation.dart';

enum Step4VariantLayout { single, list, matrix }

enum PackageContentKind { baseUnit, salesPresentation }

@immutable
class Step4VariantOption {
  const Step4VariantOption({
    required this.id,
    required this.label,
    this.rowValue,
    this.columnValue,
  });

  final String id;
  final String label;

  /// Solo se usan cuando [Step4VariantLayout.matrix] está activo.
  final String? rowValue;
  final String? columnValue;
}

@immutable
class CatalogVariantOption {
  const CatalogVariantOption({required this.id, required this.label});

  final String id;
  final String label;
}

@immutable
class SalesPresentationVariantRule {
  const SalesPresentationVariantRule({
    required this.variantId,
    required this.equivalentTo,
    required this.minimumOrder,
    required this.purchaseIncrement,
  });

  final String variantId;
  final double equivalentTo;
  final double minimumOrder;
  final double purchaseIncrement;
}

@immutable
class SalesPresentationDraft {
  const SalesPresentationDraft({
    required this.id,
    required this.name,
    required this.baseUnit,
    required this.equivalentTo,
    required this.minimumOrder,
    required this.purchaseIncrement,
    required this.allowsDecimals,
    required this.assignedVariantIds,
    required this.defaultVariantIds,
    this.variantRules = const {},
    this.linkedLogisticsPackageId,
  });

  final String id;
  final String name;
  final String baseUnit;
  final double equivalentTo;
  final double minimumOrder;
  final double purchaseIncrement;
  final bool allowsDecimals;

  /// Estas asignaciones generan las combinaciones vendibles del paso 5.
  final Set<String> assignedVariantIds;

  /// Una presentación puede ser predeterminada para algunas variantes.
  /// El widget garantiza como máximo una predeterminada por variante.
  final Set<String> defaultVariantIds;

  /// Excepciones de equivalencia, mínimo e incremento por variante.
  final Map<String, SalesPresentationVariantRule> variantRules;

  SalesPresentationVariantRule ruleFor(String variantId) =>
      variantRules[variantId] ??
      SalesPresentationVariantRule(
        variantId: variantId,
        equivalentTo: equivalentTo,
        minimumOrder: minimumOrder,
        purchaseIncrement: purchaseIncrement,
      );

  /// Se informa cuando nació desde un empaque logístico.
  final String? linkedLogisticsPackageId;

  SalesPresentationDraft copyWith({
    String? name,
    String? baseUnit,
    double? equivalentTo,
    double? minimumOrder,
    double? purchaseIncrement,
    bool? allowsDecimals,
    Set<String>? assignedVariantIds,
    Set<String>? defaultVariantIds,
    Map<String, SalesPresentationVariantRule>? variantRules,
    String? linkedLogisticsPackageId,
    bool clearLinkedLogisticsPackageId = false,
  }) {
    return SalesPresentationDraft(
      id: id,
      name: name ?? this.name,
      baseUnit: baseUnit ?? this.baseUnit,
      equivalentTo: equivalentTo ?? this.equivalentTo,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      purchaseIncrement: purchaseIncrement ?? this.purchaseIncrement,
      allowsDecimals: allowsDecimals ?? this.allowsDecimals,
      assignedVariantIds: assignedVariantIds ?? this.assignedVariantIds,
      defaultVariantIds: defaultVariantIds ?? this.defaultVariantIds,
      variantRules: variantRules ?? this.variantRules,
      linkedLogisticsPackageId: clearLinkedLogisticsPackageId
          ? null
          : linkedLogisticsPackageId ?? this.linkedLogisticsPackageId,
    );
  }
}

@immutable
class LogisticsPackageDraft {
  const LogisticsPackageDraft({
    required this.id,
    required this.name,
    required this.contains,
    required this.contentKind,
    required this.contentReferenceId,
    required this.totalBaseUnits,
    required this.baseUnit,
    required this.assignedVariantIds,
    this.supplierCode,
    this.description,
    this.linkedSalesPresentationId,
  });

  final String id;
  final String name;
  final double contains;
  final PackageContentKind contentKind;

  /// Código de unidad o id de la presentación contenida.
  final String contentReferenceId;

  final double totalBaseUnits;
  final String baseUnit;
  final Set<String> assignedVariantIds;
  final String? supplierCode;
  final String? description;
  final String? linkedSalesPresentationId;

  LogisticsPackageDraft copyWith({
    String? name,
    double? contains,
    PackageContentKind? contentKind,
    String? contentReferenceId,
    double? totalBaseUnits,
    String? baseUnit,
    Set<String>? assignedVariantIds,
    String? supplierCode,
    String? description,
    String? linkedSalesPresentationId,
    bool clearLinkedSalesPresentationId = false,
  }) {
    return LogisticsPackageDraft(
      id: id,
      name: name ?? this.name,
      contains: contains ?? this.contains,
      contentKind: contentKind ?? this.contentKind,
      contentReferenceId: contentReferenceId ?? this.contentReferenceId,
      totalBaseUnits: totalBaseUnits ?? this.totalBaseUnits,
      baseUnit: baseUnit ?? this.baseUnit,
      assignedVariantIds: assignedVariantIds ?? this.assignedVariantIds,
      supplierCode: supplierCode ?? this.supplierCode,
      description: description ?? this.description,
      linkedSalesPresentationId: clearLinkedSalesPresentationId
          ? null
          : linkedSalesPresentationId ?? this.linkedSalesPresentationId,
    );
  }
}

@immutable
class ProductContentItemDraft {
  const ProductContentItemDraft({
    required this.id,
    required this.ownerVariantId,
    required this.componentName,
    required this.quantity,
    required this.unit,
    this.relatedCatalogVariantId,
  });

  final String id;

  /// Variante del kit/juego a la que pertenece este contenido.
  final String ownerVariantId;
  final String componentName;
  final double quantity;
  final String unit;
  final String? relatedCatalogVariantId;

  ProductContentItemDraft copyWith({
    String? ownerVariantId,
    String? componentName,
    double? quantity,
    String? unit,
    String? relatedCatalogVariantId,
    bool clearRelatedCatalogVariantId = false,
  }) {
    return ProductContentItemDraft(
      id: id,
      ownerVariantId: ownerVariantId ?? this.ownerVariantId,
      componentName: componentName ?? this.componentName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      relatedCatalogVariantId: clearRelatedCatalogVariantId
          ? null
          : relatedCatalogVariantId ?? this.relatedCatalogVariantId,
    );
  }
}

@immutable
class Step4SalesDraft {
  const Step4SalesDraft({
    required this.presentations,
    required this.usesLogisticsPackages,
    required this.logisticsPackages,
    required this.hasProductContent,
    required this.contentItems,
  });

  final List<SalesPresentationDraft> presentations;
  final bool? usesLogisticsPackages;
  final List<LogisticsPackageDraft> logisticsPackages;
  final bool? hasProductContent;
  final List<ProductContentItemDraft> contentItems;

  int get sellableCombinationCount {
    return presentations.fold<int>(
      0,
      (total, item) => total + item.assignedVariantIds.length,
    );
  }
}

Map<String, dynamic> step4SalesDraftToMap(Step4SalesDraft draft) {
  return {
    'presentations': draft.presentations.map((item) {
      return {
        'id': item.id,
        'name': item.name,
        'base_unit': item.baseUnit,
        'equivalent_to': item.equivalentTo,
        'minimum_order': item.minimumOrder,
        'purchase_increment': item.purchaseIncrement,
        'allows_decimals': item.allowsDecimals,
        'assigned_variant_ids': item.assignedVariantIds.toList(),
        'default_variant_ids': item.defaultVariantIds.toList(),
        'variant_rules': item.variantRules.values.map((rule) {
          return {
            'variant_id': rule.variantId,
            'equivalent_to': rule.equivalentTo,
            'minimum_order': rule.minimumOrder,
            'purchase_increment': rule.purchaseIncrement,
          };
        }).toList(),
        'linked_logistics_package_id': item.linkedLogisticsPackageId,
      };
    }).toList(),
    'uses_logistics_packages': draft.usesLogisticsPackages,
    'logistics_packages': draft.logisticsPackages.map((item) {
      return {
        'id': item.id,
        'name': item.name,
        'contains': item.contains,
        'content_kind': item.contentKind.name,
        'content_reference_id': item.contentReferenceId,
        'total_base_units': item.totalBaseUnits,
        'base_unit': item.baseUnit,
        'assigned_variant_ids': item.assignedVariantIds.toList(),
        'supplier_code': item.supplierCode,
        'description': item.description,
        'linked_sales_presentation_id': item.linkedSalesPresentationId,
      };
    }).toList(),
    'has_product_content': draft.hasProductContent,
    'content_items': draft.contentItems.map((item) {
      return {
        'id': item.id,
        'owner_variant_id': item.ownerVariantId,
        'component_name': item.componentName,
        'quantity': item.quantity,
        'unit': item.unit,
        'related_catalog_variant_id': item.relatedCatalogVariantId,
      };
    }).toList(),
  };
}

Step4SalesDraft? step4SalesDraftFromMap(Map<String, dynamic>? map) {
  if (map == null || map.isEmpty) {
    return null;
  }

  Set<String> stringSet(Object? source) {
    return source is List ? source.whereType<String>().toSet() : <String>{};
  }

  final presentations = (map['presentations'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return SalesPresentationDraft(
          id: item['id']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          baseUnit: item['base_unit']?.toString() ?? 'PZA',
          equivalentTo: (item['equivalent_to'] as num?)?.toDouble() ?? 1,
          minimumOrder: (item['minimum_order'] as num?)?.toDouble() ?? 1,
          purchaseIncrement:
              (item['purchase_increment'] as num?)?.toDouble() ?? 1,
          allowsDecimals: item['allows_decimals'] as bool? ?? false,
          assignedVariantIds: stringSet(item['assigned_variant_ids']),
          defaultVariantIds: stringSet(item['default_variant_ids']),
          variantRules: {
            for (final rawRule
                in (item['variant_rules'] as List? ?? const [])
                    .whereType<Map>())
              if (rawRule['variant_id'] != null)
                rawRule['variant_id'].toString(): SalesPresentationVariantRule(
                  variantId: rawRule['variant_id'].toString(),
                  equivalentTo:
                      (rawRule['equivalent_to'] as num?)?.toDouble() ?? 1,
                  minimumOrder:
                      (rawRule['minimum_order'] as num?)?.toDouble() ?? 1,
                  purchaseIncrement:
                      (rawRule['purchase_increment'] as num?)?.toDouble() ?? 1,
                ),
          },
          linkedLogisticsPackageId:
              item['linked_logistics_package_id'] as String?,
        );
      })
      .toList();
  final packages = (map['logistics_packages'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return LogisticsPackageDraft(
          id: item['id']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          contains: (item['contains'] as num?)?.toDouble() ?? 1,
          contentKind: item['content_kind'] == PackageContentKind.baseUnit.name
              ? PackageContentKind.baseUnit
              : PackageContentKind.salesPresentation,
          contentReferenceId: item['content_reference_id']?.toString() ?? '',
          totalBaseUnits: (item['total_base_units'] as num?)?.toDouble() ?? 1,
          baseUnit: item['base_unit']?.toString() ?? 'PZA',
          assignedVariantIds: stringSet(item['assigned_variant_ids']),
          supplierCode: item['supplier_code'] as String?,
          description: item['description'] as String?,
          linkedSalesPresentationId:
              item['linked_sales_presentation_id'] as String?,
        );
      })
      .toList();
  final contentItems = (map['content_items'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return ProductContentItemDraft(
          id: item['id']?.toString() ?? '',
          ownerVariantId: item['owner_variant_id']?.toString() ?? '',
          componentName: item['component_name']?.toString() ?? '',
          quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
          unit: item['unit']?.toString() ?? 'PZA',
          relatedCatalogVariantId:
              item['related_catalog_variant_id'] as String?,
        );
      })
      .toList();

  return Step4SalesDraft(
    presentations: presentations,
    usesLogisticsPackages: map['uses_logistics_packages'] as bool?,
    logisticsPackages: packages,
    hasProductContent: map['has_product_content'] as bool?,
    contentItems: contentItems,
  );
}
