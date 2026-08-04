part of '../pages/gestionar_atributos_categoria.dart';

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
