import 'package:flutter/material.dart';

// ============================================================================
// PASO 4 · VENTA, LOGÍSTICA Y CONTENIDO
//
// Widget autocontenido para integrar en el PageView del registro de productos.
//
// Reglas principales:
// - Presentaciones de venta: obligatorias.
// - Empaques logísticos: opcionales y sin precio.
// - Contenido del producto: opcional y definido por variante.
// - No se gestionan imágenes ni precios en este paso.
// - El alcance variante + presentación alimenta automáticamente el paso 5.
// ============================================================================

enum Step4VariantLayout { single, list, matrix }

enum Step4Section { salesPresentations, logisticsPackages, productContent }

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

class Step4SalesLogisticsContentPanel extends StatefulWidget {
  const Step4SalesLogisticsContentPanel({
    super.key,
    required this.familyName,
    required this.variantLayout,
    required this.variants,
    required this.onBack,
    required this.onNext,
    this.initialPresentations = const [],
    this.initialLogisticsPackages = const [],
    this.initialContentItems = const [],
    this.initialUsesLogisticsPackages,
    this.initialHasProductContent,
    this.catalogVariants = const [],
    this.baseUnits = const [
      'PZA',
      'M',
      'KG',
      'JGO',
      'ROLLO',
      'CAJA',
      'PAR',
      'L',
    ],
    this.onChanged,
  }) : assert(variants.length > 0, 'El paso 4 necesita al menos una variante.'),
       assert(
         baseUnits.length > 0,
         'El paso 4 necesita al menos una unidad de medida.',
       );

  final String familyName;
  final Step4VariantLayout variantLayout;
  final List<Step4VariantOption> variants;

  final List<SalesPresentationDraft> initialPresentations;
  final List<LogisticsPackageDraft> initialLogisticsPackages;
  final List<ProductContentItemDraft> initialContentItems;
  final bool? initialUsesLogisticsPackages;
  final bool? initialHasProductContent;
  final List<CatalogVariantOption> catalogVariants;
  final List<String> baseUnits;

  final VoidCallback onBack;
  final ValueChanged<Step4SalesDraft> onNext;
  final ValueChanged<Step4SalesDraft>? onChanged;

  @override
  State<Step4SalesLogisticsContentPanel> createState() =>
      _Step4SalesLogisticsContentPanelState();
}

class _Step4SalesLogisticsContentPanelState
    extends State<Step4SalesLogisticsContentPanel> {
  static const Color _primary = Color(0xFFFFC500);
  static const Color _ink = Color(0xFF242830);
  static const Color _muted = Color(0xFF667085);
  static const Color _border = Color(0xFFD5DDE8);
  static const Color _soft = Color(0xFFF4F6F9);
  static const Color _canvas = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF18794E);

  Step4Section _section = Step4Section.salesPresentations;

  late List<SalesPresentationDraft> _presentations;
  late List<LogisticsPackageDraft> _packages;
  late List<ProductContentItemDraft> _contentItems;
  bool? _usesPackages;
  bool? _hasContent;

  int _idSequence = DateTime.now().microsecondsSinceEpoch;

  // --------------------------------------------------------------------------
  // Editor de presentaciones
  // --------------------------------------------------------------------------

  final GlobalKey<FormState> _presentationFormKey = GlobalKey<FormState>();
  final TextEditingController _presentationNameController =
      TextEditingController();
  final TextEditingController _presentationEquivalentController =
      TextEditingController(text: '1');
  final TextEditingController _presentationMinimumController =
      TextEditingController(text: '1');
  final TextEditingController _presentationIncrementController =
      TextEditingController(text: '1');

  int? _editingPresentationIndex;
  String _presentationBaseUnit = 'PZA';
  bool _presentationAllowsDecimals = false;
  bool _presentationIsDefault = true;
  bool _presentationForAllVariants = true;
  Set<String> _presentationVariantIds = <String>{};

  // --------------------------------------------------------------------------
  // Editor de empaques
  // --------------------------------------------------------------------------

  final GlobalKey<FormState> _packageFormKey = GlobalKey<FormState>();
  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _packageContainsController =
      TextEditingController(text: '1');
  final TextEditingController _packageSupplierCodeController =
      TextEditingController();
  final TextEditingController _packageDescriptionController =
      TextEditingController();

  int? _editingPackageIndex;
  PackageContentKind _packageContentKind = PackageContentKind.salesPresentation;
  String? _packageContentReferenceId;
  bool _packageForAllVariants = true;
  Set<String> _packageVariantIds = <String>{};

  // --------------------------------------------------------------------------
  // Editor de contenido
  // --------------------------------------------------------------------------

  final GlobalKey<FormState> _contentFormKey = GlobalKey<FormState>();
  final TextEditingController _componentNameController =
      TextEditingController();
  final TextEditingController _componentQuantityController =
      TextEditingController(text: '1');
  final ScrollController _contentTableScrollController = ScrollController();

  String _componentUnit = 'PZA';
  String? _relatedCatalogVariantId;
  String? _selectedContentVariantId;
  int? _editingContentIndex;

  Set<String> get _allVariantIds =>
      widget.variants.map((item) => item.id).toSet();

  Step4SalesDraft get _draft {
    return Step4SalesDraft(
      presentations: List.unmodifiable(_presentations),
      usesLogisticsPackages: _usesPackages,
      logisticsPackages: List.unmodifiable(_packages),
      hasProductContent: _hasContent,
      contentItems: List.unmodifiable(_contentItems),
    );
  }

  @override
  void initState() {
    super.initState();

    _presentations = [...widget.initialPresentations];
    _packages = [...widget.initialLogisticsPackages];
    _contentItems = [...widget.initialContentItems];
    _usesPackages =
        widget.initialUsesLogisticsPackages ??
        (widget.initialLogisticsPackages.isNotEmpty ? true : null);
    _hasContent =
        widget.initialHasProductContent ??
        (widget.initialContentItems.isNotEmpty ? true : null);
    _selectedContentVariantId = widget.variants.first.id;

    if (_presentations.isEmpty) {
      _startNewPresentation(rebuild: false);
    } else {
      _loadPresentation(0, rebuild: false);
    }

    if (_packages.isEmpty) {
      _startNewPackage(rebuild: false);
    } else {
      _loadPackage(0, rebuild: false);
    }

    _startNewContentItem(rebuild: false);
  }

  @override
  void dispose() {
    _presentationNameController.dispose();
    _presentationEquivalentController.dispose();
    _presentationMinimumController.dispose();
    _presentationIncrementController.dispose();
    _packageNameController.dispose();
    _packageContainsController.dispose();
    _packageSupplierCodeController.dispose();
    _packageDescriptionController.dispose();
    _componentNameController.dispose();
    _componentQuantityController.dispose();
    _contentTableScrollController.dispose();
    super.dispose();
  }

  String _newId(String prefix) {
    _idSequence += 1;
    return '$prefix-$_idSequence';
  }

  void _emitChanged() {
    widget.onChanged?.call(_draft);
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : _ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================================
  // LÓGICA · PRESENTACIONES
  // ==========================================================================

  void _startNewPresentation({bool rebuild = true}) {
    _editingPresentationIndex = null;
    _presentationNameController.clear();
    _presentationEquivalentController.text = '1';
    _presentationMinimumController.text = '1';
    _presentationIncrementController.text = '1';
    _presentationBaseUnit = widget.baseUnits.contains('PZA')
        ? 'PZA'
        : widget.baseUnits.first;
    _presentationAllowsDecimals = false;
    _presentationIsDefault = _presentations.isEmpty;
    _presentationForAllVariants = true;
    _presentationVariantIds = {..._allVariantIds};

    if (rebuild && mounted) {
      setState(() {});
    }
  }

  void _loadPresentation(int index, {bool rebuild = true}) {
    final presentation = _presentations[index];
    _editingPresentationIndex = index;
    _presentationNameController.text = presentation.name;
    _presentationEquivalentController.text = _step4PlainNumber(
      presentation.equivalentTo,
    );
    _presentationMinimumController.text = _step4PlainNumber(
      presentation.minimumOrder,
    );
    _presentationIncrementController.text = _step4PlainNumber(
      presentation.purchaseIncrement,
    );
    _presentationBaseUnit = presentation.baseUnit;
    _presentationAllowsDecimals = presentation.allowsDecimals;
    _presentationIsDefault = presentation.defaultVariantIds.isNotEmpty;
    _presentationVariantIds = {...presentation.assignedVariantIds};
    _presentationForAllVariants =
        _presentationVariantIds.length == _allVariantIds.length &&
        _presentationVariantIds.containsAll(_allVariantIds);

    if (rebuild && mounted) {
      setState(() {});
    }
  }

  void _cancelPresentationChanges() {
    final index = _editingPresentationIndex;
    if (index == null) {
      _startNewPresentation();
      return;
    }

    _loadPresentation(index);
  }

  void _savePresentation() {
    if (!(_presentationFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final assignedIds = widget.variantLayout == Step4VariantLayout.single
        ? <String>{widget.variants.first.id}
        : _presentationForAllVariants
        ? {..._allVariantIds}
        : {..._presentationVariantIds};

    if (assignedIds.isEmpty) {
      _showMessage(
        'Selecciona al menos una variante para esta presentación.',
        error: true,
      );
      return;
    }

    final equivalent = _parsePositive(_presentationEquivalentController.text);
    final minimum = _parsePositive(_presentationMinimumController.text);
    final increment = _parsePositive(_presentationIncrementController.text);

    if (equivalent == null || minimum == null || increment == null) {
      _showMessage(
        'Equivalencia, pedido mínimo e incremento deben ser mayores que cero.',
        error: true,
      );
      return;
    }

    final existingIndex = _editingPresentationIndex;
    final id = existingIndex == null
        ? _newId('presentation')
        : _presentations[existingIndex].id;

    final linkedPackageId = existingIndex == null
        ? null
        : _presentations[existingIndex].linkedLogisticsPackageId;

    final defaults = _presentationIsDefault ? {...assignedIds} : <String>{};

    if (_presentationIsDefault) {
      _presentations = _presentations.map((item) {
        if (item.id == id) {
          return item;
        }

        return item.copyWith(
          defaultVariantIds: item.defaultVariantIds.difference(assignedIds),
        );
      }).toList();
    }

    final saved = SalesPresentationDraft(
      id: id,
      name: _presentationNameController.text.trim(),
      baseUnit: _presentationBaseUnit,
      equivalentTo: equivalent,
      minimumOrder: minimum,
      purchaseIncrement: increment,
      allowsDecimals: _presentationAllowsDecimals,
      assignedVariantIds: assignedIds,
      defaultVariantIds: defaults,
      linkedLogisticsPackageId: linkedPackageId,
    );

    setState(() {
      if (existingIndex == null) {
        _presentations.add(saved);
        _editingPresentationIndex = _presentations.length - 1;
      } else {
        _presentations[existingIndex] = saved;
      }
    });

    _synchronizePackagesUsingPresentation(saved);
    _emitChanged();
    _showMessage(
      existingIndex == null
          ? 'Presentación guardada.'
          : 'Cambios de la presentación guardados.',
    );
  }

  void _synchronizePackagesUsingPresentation(
    SalesPresentationDraft presentation,
  ) {
    var changed = false;

    _packages = _packages.map((item) {
      if (item.contentKind != PackageContentKind.salesPresentation ||
          item.contentReferenceId != presentation.id) {
        return item;
      }

      changed = true;
      return item.copyWith(
        totalBaseUnits: item.contains * presentation.equivalentTo,
        baseUnit: presentation.baseUnit,
      );
    }).toList();

    if (changed && mounted) {
      setState(() {});
    }
  }

  Future<void> _deletePresentation(int index) async {
    final presentation = _presentations[index];
    final usedByPackage = _packages.any(
      (item) =>
          item.contentKind == PackageContentKind.salesPresentation &&
          item.contentReferenceId == presentation.id,
    );

    if (usedByPackage) {
      _showMessage(
        'No se puede eliminar: un empaque logístico contiene esta presentación.',
        error: true,
      );
      return;
    }

    final confirmed = await _confirm(
      title: 'Eliminar presentación',
      message:
          'También desaparecerán sus combinaciones de precio en el paso 5.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _presentations.removeAt(index);
      if (_presentations.isEmpty) {
        _startNewPresentation(rebuild: false);
      } else {
        _loadPresentation(0, rebuild: false);
      }
    });

    _emitChanged();
  }

  bool _validatePresentationsForNext() {
    if (_presentations.isEmpty) {
      _showMessage('Agrega al menos una presentación de venta.', error: true);
      return false;
    }

    final uncovered = widget.variants.where((variant) {
      return !_presentations.any(
        (item) => item.assignedVariantIds.contains(variant.id),
      );
    }).toList();

    if (uncovered.isNotEmpty) {
      _showMessage(
        'Falta una presentación de venta para: '
        '${uncovered.map((item) => item.label).join(', ')}.',
        error: true,
      );
      return false;
    }

    final withoutDefault = widget.variants.where((variant) {
      final count = _presentations
          .where((item) => item.defaultVariantIds.contains(variant.id))
          .length;
      return count != 1;
    }).toList();

    if (withoutDefault.isNotEmpty) {
      _showMessage(
        'Define una presentación predeterminada para cada variante.',
        error: true,
      );
      return false;
    }

    return true;
  }

  // ==========================================================================
  // LÓGICA · EMPAQUES
  // ==========================================================================

  void _startNewPackage({bool rebuild = true}) {
    _editingPackageIndex = null;
    _packageNameController.clear();
    _packageContainsController.text = '1';
    _packageSupplierCodeController.clear();
    _packageDescriptionController.clear();
    _packageContentKind = _presentations.isEmpty
        ? PackageContentKind.baseUnit
        : PackageContentKind.salesPresentation;
    _packageContentReferenceId = _presentations.isEmpty
        ? widget.baseUnits.first
        : _presentations.first.id;
    _packageForAllVariants = true;
    _packageVariantIds = {..._allVariantIds};

    if (rebuild && mounted) {
      setState(() {});
    }
  }

  void _loadPackage(int index, {bool rebuild = true}) {
    final package = _packages[index];
    _editingPackageIndex = index;
    _packageNameController.text = package.name;
    _packageContainsController.text = _step4PlainNumber(package.contains);
    _packageSupplierCodeController.text = package.supplierCode ?? '';
    _packageDescriptionController.text = package.description ?? '';
    _packageContentKind = package.contentKind;
    _packageContentReferenceId = package.contentReferenceId;
    _packageVariantIds = {...package.assignedVariantIds};
    _packageForAllVariants =
        _packageVariantIds.length == _allVariantIds.length &&
        _packageVariantIds.containsAll(_allVariantIds);

    if (rebuild && mounted) {
      setState(() {});
    }
  }

  Future<void> _setPackageUsage(bool value) async {
    if (!value && _packages.isNotEmpty) {
      final confirmed = await _confirm(
        title: 'Marcar como “No aplica”',
        message:
            'Se eliminarán los empaques logísticos registrados. Las presentaciones vinculadas se conservarán como presentaciones independientes.',
        confirmLabel: 'Continuar',
        destructive: true,
      );

      if (!confirmed || !mounted) {
        return;
      }

      final packageIds = _packages.map((item) => item.id).toSet();
      _presentations = _presentations.map((item) {
        if (!packageIds.contains(item.linkedLogisticsPackageId)) {
          return item;
        }

        return item.copyWith(clearLinkedLogisticsPackageId: true);
      }).toList();
      _packages.clear();
    }

    setState(() {
      _usesPackages = value;
      if (value && _packages.isEmpty) {
        _startNewPackage(rebuild: false);
      }
    });
    _emitChanged();
  }

  ({double total, String baseUnit})? get _currentPackageEquivalence {
    final contains = _parsePositive(_packageContainsController.text);
    final referenceId = _packageContentReferenceId;

    if (contains == null || referenceId == null) {
      return null;
    }

    if (_packageContentKind == PackageContentKind.baseUnit) {
      return (total: contains, baseUnit: referenceId);
    }

    final presentation = _presentationById(referenceId);
    if (presentation == null) {
      return null;
    }

    return (
      total: contains * presentation.equivalentTo,
      baseUnit: presentation.baseUnit,
    );
  }

  void _cancelPackageChanges() {
    final index = _editingPackageIndex;
    if (index == null) {
      _startNewPackage();
      return;
    }

    _loadPackage(index);
  }

  void _savePackage() {
    if (!(_packageFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final assignedIds = widget.variantLayout == Step4VariantLayout.single
        ? <String>{widget.variants.first.id}
        : _packageForAllVariants
        ? {..._allVariantIds}
        : {..._packageVariantIds};

    if (assignedIds.isEmpty) {
      _showMessage(
        'Selecciona al menos una variante para el empaque.',
        error: true,
      );
      return;
    }

    final contains = _parsePositive(_packageContainsController.text);
    final equivalence = _currentPackageEquivalence;
    final referenceId = _packageContentReferenceId;

    if (contains == null || equivalence == null || referenceId == null) {
      _showMessage(
        'Completa correctamente el contenido del empaque.',
        error: true,
      );
      return;
    }

    final existingIndex = _editingPackageIndex;
    final id = existingIndex == null
        ? _newId('package')
        : _packages[existingIndex].id;
    final linkedPresentationId = existingIndex == null
        ? null
        : _packages[existingIndex].linkedSalesPresentationId;

    final saved = LogisticsPackageDraft(
      id: id,
      name: _packageNameController.text.trim(),
      contains: contains,
      contentKind: _packageContentKind,
      contentReferenceId: referenceId,
      totalBaseUnits: equivalence.total,
      baseUnit: equivalence.baseUnit,
      assignedVariantIds: assignedIds,
      supplierCode: _nullIfEmpty(_packageSupplierCodeController.text),
      description: _nullIfEmpty(_packageDescriptionController.text),
      linkedSalesPresentationId: linkedPresentationId,
    );

    setState(() {
      if (existingIndex == null) {
        _packages.add(saved);
        _editingPackageIndex = _packages.length - 1;
      } else {
        _packages[existingIndex] = saved;
      }
      _synchronizeLinkedPresentationFromPackage(saved);
    });

    _emitChanged();
    _showMessage(
      existingIndex == null
          ? 'Empaque logístico guardado.'
          : 'Cambios del empaque guardados.',
    );
  }

  void _synchronizeLinkedPresentationFromPackage(
    LogisticsPackageDraft package,
  ) {
    final linkedId = package.linkedSalesPresentationId;
    if (linkedId == null) {
      return;
    }

    final index = _presentations.indexWhere((item) => item.id == linkedId);
    if (index == -1) {
      return;
    }

    final current = _presentations[index];
    _presentations[index] = current.copyWith(
      name: '${package.name} x${_step4PlainNumber(package.totalBaseUnits)}',
      baseUnit: package.baseUnit,
      equivalentTo: package.totalBaseUnits,
      assignedVariantIds: package.assignedVariantIds,
      defaultVariantIds: current.defaultVariantIds.intersection(
        package.assignedVariantIds,
      ),
    );
  }

  void _openOrCreateLinkedPresentation() {
    final packageIndex = _editingPackageIndex;
    if (packageIndex == null) {
      _showMessage('Guarda primero el empaque logístico.', error: true);
      return;
    }

    final package = _packages[packageIndex];
    final linkedId = package.linkedSalesPresentationId;

    if (linkedId != null) {
      final presentationIndex = _presentations.indexWhere(
        (item) => item.id == linkedId,
      );

      if (presentationIndex != -1) {
        setState(() {
          _section = Step4Section.salesPresentations;
          _loadPresentation(presentationIndex, rebuild: false);
        });
        return;
      }
    }

    final presentationId = _newId('presentation');
    final presentation = SalesPresentationDraft(
      id: presentationId,
      name: '${package.name} x${_step4PlainNumber(package.totalBaseUnits)}',
      baseUnit: package.baseUnit,
      equivalentTo: package.totalBaseUnits,
      minimumOrder: 1,
      purchaseIncrement: 1,
      allowsDecimals: false,
      assignedVariantIds: {...package.assignedVariantIds},
      defaultVariantIds: <String>{},
      linkedLogisticsPackageId: package.id,
    );

    setState(() {
      _presentations.add(presentation);
      _packages[packageIndex] = package.copyWith(
        linkedSalesPresentationId: presentationId,
      );
      _section = Step4Section.salesPresentations;
      _loadPresentation(_presentations.length - 1, rebuild: false);
    });

    _emitChanged();
    _showMessage(
      'Se creó una presentación de venta separada. Su precio se configurará en el paso 5.',
    );
  }

  Future<void> _deletePackage(int index) async {
    final package = _packages[index];
    final confirmed = await _confirm(
      title: 'Eliminar empaque',
      message:
          'La presentación de venta vinculada, si existe, se conservará como independiente.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      final linkedId = package.linkedSalesPresentationId;
      if (linkedId != null) {
        final presentationIndex = _presentations.indexWhere(
          (item) => item.id == linkedId,
        );
        if (presentationIndex != -1) {
          _presentations[presentationIndex] = _presentations[presentationIndex]
              .copyWith(clearLinkedLogisticsPackageId: true);
        }
      }

      _packages.removeAt(index);
      if (_packages.isEmpty) {
        _startNewPackage(rebuild: false);
      } else {
        _loadPackage(0, rebuild: false);
      }
    });

    _emitChanged();
  }

  // ==========================================================================
  // LÓGICA · CONTENIDO
  // ==========================================================================

  void _startNewContentItem({bool rebuild = true}) {
    _editingContentIndex = null;
    _componentNameController.clear();
    _componentQuantityController.text = '1';
    _componentUnit = widget.baseUnits.contains('PZA')
        ? 'PZA'
        : widget.baseUnits.first;
    _relatedCatalogVariantId = null;

    if (rebuild && mounted) {
      setState(() {});
    }
  }

  void _loadContentItem(int globalIndex, {bool rebuild = true}) {
    final item = _contentItems[globalIndex];
    _editingContentIndex = globalIndex;
    _selectedContentVariantId = item.ownerVariantId;
    _componentNameController.text = item.componentName;
    _componentQuantityController.text = _step4PlainNumber(item.quantity);
    _componentUnit = item.unit;
    _relatedCatalogVariantId = item.relatedCatalogVariantId;

    if (rebuild && mounted) {
      setState(() {});
    }
  }

  Future<void> _setContentUsage(bool value) async {
    if (!value && _contentItems.isNotEmpty) {
      final confirmed = await _confirm(
        title: 'Marcar como “No aplica”',
        message:
            'Se eliminará el contenido registrado para todas las variantes.',
        confirmLabel: 'Continuar',
        destructive: true,
      );

      if (!confirmed || !mounted) {
        return;
      }

      _contentItems.clear();
    }

    setState(() {
      _hasContent = value;
      if (value) {
        _selectedContentVariantId ??= widget.variants.first.id;
        _startNewContentItem(rebuild: false);
      }
    });
    _emitChanged();
  }

  void _saveContentItem() {
    if (!(_contentFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final ownerVariantId =
        _selectedContentVariantId ?? widget.variants.first.id;
    final quantity = _parsePositive(_componentQuantityController.text);

    if (quantity == null) {
      _showMessage('La cantidad debe ser mayor que cero.', error: true);
      return;
    }

    final existingIndex = _editingContentIndex;
    final saved = ProductContentItemDraft(
      id: existingIndex == null
          ? _newId('content')
          : _contentItems[existingIndex].id,
      ownerVariantId: ownerVariantId,
      componentName: _componentNameController.text.trim(),
      quantity: quantity,
      unit: _componentUnit,
      relatedCatalogVariantId: _relatedCatalogVariantId,
    );

    setState(() {
      if (existingIndex == null) {
        _contentItems.add(saved);
      } else {
        _contentItems[existingIndex] = saved;
      }
      _startNewContentItem(rebuild: false);
    });

    _emitChanged();
    _showMessage(
      existingIndex == null
          ? 'Componente agregado.'
          : 'Cambios del componente guardados.',
    );
  }

  Future<void> _deleteContentItem(int globalIndex) async {
    final confirmed = await _confirm(
      title: 'Eliminar componente',
      message: 'Este elemento dejará de formar parte del producto.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _contentItems.removeAt(globalIndex);
      _startNewContentItem(rebuild: false);
    });
    _emitChanged();
  }

  Future<void> _pickCatalogVariant() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        var query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final options = widget.catalogVariants.where((item) {
              return item.label.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Buscar en el catálogo'),
              content: SizedBox(
                width: 520,
                height: 430,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      onChanged: (value) {
                        setDialogState(() {
                          query = value.trim();
                        });
                      },
                      decoration: _inputDecoration(
                        label: 'Producto o variante',
                        hint: 'Ej. Broca HSS 3 mm',
                        prefixIcon: Icons.search,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      leading: const Icon(Icons.link_off),
                      title: const Text('Sin producto relacionado'),
                      onTap: () => Navigator.pop(context, ''),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: options.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron coincidencias.',
                                style: TextStyle(color: _muted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.inventory_2_outlined,
                                  ),
                                  title: Text(option.label),
                                  onTap: () =>
                                      Navigator.pop(context, option.id),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _relatedCatalogVariantId = result.isEmpty ? null : result;
    });
  }

  Future<void> _copyContentToOtherVariants() async {
    final sourceId = _selectedContentVariantId ?? widget.variants.first.id;
    final sourceItems = _contentItems
        .where((item) => item.ownerVariantId == sourceId)
        .toList();

    if (sourceItems.isEmpty) {
      _showMessage(
        'Agrega componentes antes de copiar el contenido.',
        error: true,
      );
      return;
    }

    final candidates = widget.variants
        .where((item) => item.id != sourceId)
        .toList();

    if (candidates.isEmpty) {
      _showMessage('No existen otras variantes a las cuales copiar.');
      return;
    }

    final selected = <String>{};
    var replaceExisting = false;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Copiar contenido'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona las variantes de destino.',
                      style: TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView(
                        shrinkWrap: true,
                        children: candidates.map((variant) {
                          final checked = selected.contains(variant.id);
                          return CheckboxListTile(
                            value: checked,
                            title: Text(variant.label),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value ?? false) {
                                  selected.add(variant.id);
                                } else {
                                  selected.remove(variant.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: replaceExisting,
                      title: const Text('Reemplazar el contenido existente'),
                      subtitle: const Text(
                        'Si no se activa, los componentes se agregarán a la lista actual.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setDialogState(() {
                          replaceExisting = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: _ink,
                  ),
                  child: const Text('Copiar contenido'),
                ),
              ],
            );
          },
        );
      },
    );

    if (accepted != true || !mounted) {
      return;
    }

    setState(() {
      if (replaceExisting) {
        _contentItems.removeWhere(
          (item) => selected.contains(item.ownerVariantId),
        );
      }

      for (final targetId in selected) {
        for (final source in sourceItems) {
          _contentItems.add(
            ProductContentItemDraft(
              id: _newId('content'),
              ownerVariantId: targetId,
              componentName: source.componentName,
              quantity: source.quantity,
              unit: source.unit,
              relatedCatalogVariantId: source.relatedCatalogVariantId,
            ),
          );
        }
      }
    });

    _emitChanged();
    _showMessage('Contenido copiado a ${selected.length} variantes.');
  }

  // ==========================================================================
  // ALCANCE DE VARIANTES
  // ==========================================================================

  Future<Set<String>?> _selectVariants(Set<String> initialSelection) {
    if (widget.variantLayout == Step4VariantLayout.single) {
      return Future.value({..._allVariantIds});
    }

    if (widget.variantLayout == Step4VariantLayout.matrix &&
        widget.variants.every(
          (item) => item.rowValue != null && item.columnValue != null,
        )) {
      return _showMatrixVariantSelector(initialSelection);
    }

    return _showListVariantSelector(initialSelection);
  }

  Future<Set<String>?> _showListVariantSelector(Set<String> initialSelection) {
    final selected = {...initialSelection};

    return showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Variantes seleccionadas'),
              content: SizedBox(
                width: 560,
                height: 470,
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: selected.isEmpty
                          ? false
                          : selected.length == widget.variants.length
                          ? true
                          : null,
                      tristate:
                          selected.isNotEmpty &&
                          selected.length != widget.variants.length,
                      title: Text(
                        'Seleccionar todas (${widget.variants.length})',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value ?? false) {
                            selected
                              ..clear()
                              ..addAll(_allVariantIds);
                          } else {
                            selected.clear();
                          }
                        });
                      },
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.variants.length,
                        itemBuilder: (context, index) {
                          final variant = widget.variants[index];
                          return CheckboxListTile(
                            value: selected.contains(variant.id),
                            title: Text(variant.label),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value ?? false) {
                                  selected.add(variant.id);
                                } else {
                                  selected.remove(variant.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, {...selected}),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: _ink,
                  ),
                  child: Text('Aplicar selección (${selected.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Set<String>?> _showMatrixVariantSelector(
    Set<String> initialSelection,
  ) async {
    final selected = {...initialSelection};
    final matrixScrollController = ScrollController();
    final rows = widget.variants.map((item) => item.rowValue!).toSet().toList();
    final columns = widget.variants
        .map((item) => item.columnValue!)
        .toSet()
        .toList();

    Step4VariantOption? cell(String row, String column) {
      for (final variant in widget.variants) {
        if (variant.rowValue == row && variant.columnValue == column) {
          return variant;
        }
      }
      return null;
    }

    bool rowSelected(String row) {
      final ids = widget.variants
          .where((item) => item.rowValue == row)
          .map((item) => item.id)
          .toSet();
      return ids.isNotEmpty && selected.containsAll(ids);
    }

    bool columnSelected(String column) {
      final ids = widget.variants
          .where((item) => item.columnValue == column)
          .map((item) => item.id)
          .toSet();
      return ids.isNotEmpty && selected.containsAll(ids);
    }

    void toggleRow(String row, bool value) {
      final ids = widget.variants
          .where((item) => item.rowValue == row)
          .map((item) => item.id);
      if (value) {
        selected.addAll(ids);
      } else {
        selected.removeAll(ids);
      }
    }

    void toggleColumn(String column, bool value) {
      final ids = widget.variants
          .where((item) => item.columnValue == column)
          .map((item) => item.id);
      if (value) {
        selected.addAll(ids);
      } else {
        selected.removeAll(ids);
      }
    }

    try {
      return await showDialog<Set<String>>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Seleccionar en la matriz'),
                content: SizedBox(
                  width: 880,
                  height: 520,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: selected.isEmpty
                                ? false
                                : selected.length == widget.variants.length
                                ? true
                                : null,
                            tristate:
                                selected.isNotEmpty &&
                                selected.length != widget.variants.length,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value ?? false) {
                                  selected
                                    ..clear()
                                    ..addAll(_allVariantIds);
                                } else {
                                  selected.clear();
                                }
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Toda la matriz · ${selected.length} de ${widget.variants.length} seleccionadas',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Scrollbar(
                          controller: matrixScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: matrixScrollController,
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: Table(
                                defaultColumnWidth: const FixedColumnWidth(138),
                                border: TableBorder.all(color: _border),
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: _soft,
                                    ),
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          'Fila ↓ / Columna →',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      ...columns.map((column) {
                                        return InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              toggleColumn(
                                                column,
                                                !columnSelected(column),
                                              );
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: columnSelected(column),
                                                  onChanged: (value) {
                                                    setDialogState(() {
                                                      toggleColumn(
                                                        column,
                                                        value ?? false,
                                                      );
                                                    });
                                                  },
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    column,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                  ...rows.map((row) {
                                    return TableRow(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              toggleRow(row, !rowSelected(row));
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: rowSelected(row),
                                                  onChanged: (value) {
                                                    setDialogState(() {
                                                      toggleRow(
                                                        row,
                                                        value ?? false,
                                                      );
                                                    });
                                                  },
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    row,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        ...columns.map((column) {
                                          final variant = cell(row, column);
                                          if (variant == null) {
                                            return const SizedBox(
                                              height: 58,
                                              child: Center(
                                                child: Text(
                                                  'No existe',
                                                  style: TextStyle(
                                                    color: _muted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          final checked = selected.contains(
                                            variant.id,
                                          );
                                          return InkWell(
                                            onTap: () {
                                              setDialogState(() {
                                                checked
                                                    ? selected.remove(
                                                        variant.id,
                                                      )
                                                    : selected.add(variant.id);
                                              });
                                            },
                                            child: SizedBox(
                                              height: 58,
                                              child: Center(
                                                child: Checkbox(
                                                  value: checked,
                                                  onChanged: (value) {
                                                    setDialogState(() {
                                                      if (value ?? false) {
                                                        selected.add(
                                                          variant.id,
                                                        );
                                                      } else {
                                                        selected.remove(
                                                          variant.id,
                                                        );
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(context, {...selected}),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: _ink,
                    ),
                    child: Text('Aplicar selección (${selected.length})'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      matrixScrollController.dispose();
    }
  }

  // ==========================================================================
  // NAVEGACIÓN
  // ==========================================================================

  void _goToSection(Step4Section section) {
    setState(() {
      _section = section;
    });
  }

  void _handleBack() {
    switch (_section) {
      case Step4Section.salesPresentations:
        widget.onBack();
        break;
      case Step4Section.logisticsPackages:
        _goToSection(Step4Section.salesPresentations);
        break;
      case Step4Section.productContent:
        _goToSection(Step4Section.logisticsPackages);
        break;
    }
  }

  void _handleNext() {
    switch (_section) {
      case Step4Section.salesPresentations:
        if (!_validatePresentationsForNext()) {
          return;
        }
        _goToSection(Step4Section.logisticsPackages);
        break;
      case Step4Section.logisticsPackages:
        if (_usesPackages == null) {
          _showMessage(
            'Indica si el producto utiliza empaques logísticos.',
            error: true,
          );
          return;
        }
        if (_usesPackages == true && _packages.isEmpty) {
          _showMessage(
            'Agrega un empaque o selecciona “No aplica”.',
            error: true,
          );
          return;
        }
        _goToSection(Step4Section.productContent);
        break;
      case Step4Section.productContent:
        if (_hasContent == null) {
          _showMessage(
            'Indica si el producto contiene varios elementos.',
            error: true,
          );
          return;
        }
        if (_hasContent == true && _contentItems.isEmpty) {
          _showMessage(
            'Agrega al menos un componente o selecciona “No aplica”.',
            error: true,
          );
          return;
        }
        if (!_validatePresentationsForNext()) {
          _goToSection(Step4Section.salesPresentations);
          return;
        }
        widget.onNext(_draft);
        break;
    }
  }

  // ==========================================================================
  // INTERFAZ GENERAL
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 22),
                      _buildTabs(),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: KeyedSubtree(
                          key: ValueKey(_section),
                          child: _buildCurrentSection(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 780;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paso 3 · Venta, logística y contenido',
              style: TextStyle(
                color: _ink,
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Define cómo compra el cliente y, cuando corresponda, cómo se transporta el producto o qué incluye.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
            ),
          ],
        );

        final familyBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4C7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Familia: ${widget.familyName} · '
            '${widget.variants.length} '
            '${widget.variants.length == 1 ? 'variante' : 'variantes'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: familyBadge),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: familyBadge,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              section: Step4Section.salesPresentations,
              title: 'Presentaciones de venta',
              status:
                  '${_presentations.length} ${_presentations.length == 1 ? 'configurada' : 'configuradas'}',
              requiredSection: true,
            ),
          ),
          Expanded(
            child: _buildTab(
              section: Step4Section.logisticsPackages,
              title: 'Empaques logísticos',
              status: _usesPackages == false
                  ? 'Opcional · No aplica'
                  : _usesPackages == true
                  ? 'Opcional · ${_packages.length} ${_packages.length == 1 ? 'registrado' : 'registrados'}'
                  : 'Opcional · Sin definir',
            ),
          ),
          Expanded(
            child: _buildTab(
              section: Step4Section.productContent,
              title: 'Contenido del producto',
              status: _hasContent == false
                  ? 'Opcional · No aplica'
                  : _hasContent == true
                  ? 'Opcional · ${_contentItems.length} ${_contentItems.length == 1 ? 'componente' : 'componentes'}'
                  : 'Opcional · Sin definir',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required Step4Section section,
    required String title,
    required String status,
    bool requiredSection = false,
  }) {
    final selected = _section == section;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _goToSection(section),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? _ink : _muted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              requiredSection ? 'Obligatoria · $status' : status,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? _muted : _muted.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 3,
              width: selected ? 110 : 0,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSection() {
    switch (_section) {
      case Step4Section.salesPresentations:
        return _buildPresentationsSection();
      case Step4Section.logisticsPackages:
        return _buildPackagesSection();
      case Step4Section.productContent:
        return _buildContentSection();
    }
  }

  Widget _responsivePanels({
    required Widget left,
    required Widget right,
    double leftFlex = 58,
    double rightFlex = 42,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 960) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 18), right],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex.round(), child: left),
            const SizedBox(width: 18),
            Expanded(flex: rightFlex.round(), child: right),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // INTERFAZ · PRESENTACIONES
  // ==========================================================================

  Widget _buildPresentationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionIntro(
          icon: Icons.shopping_bag_outlined,
          title: '¿Cómo puede pedir este producto el cliente?',
          description:
              'Registra las opciones vendibles, por ejemplo: unidad, docena, ciento, caja x500, kilogramo, metro o rollo.',
          trailing: _statusPill(
            'Obligatoria',
            color: _ink,
            background: const Color(0xFFFFF4C7),
          ),
        ),
        const SizedBox(height: 14),
        _responsivePanels(
          left: _buildPresentationList(),
          right: _buildPresentationEditor(),
        ),
      ],
    );
  }

  Widget _buildPresentationList() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Presentaciones configuradas',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusPill(
                '${_presentations.length}',
                color: _ink,
                background: const Color(0xFFFFF4C7),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_presentations.isEmpty)
            _emptyState(
              icon: Icons.sell_outlined,
              title: 'Aún no hay presentaciones',
              description:
                  'Crea la primera forma en que el cliente podrá pedir este producto.',
            )
          else
            ...List.generate(_presentations.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPresentationCard(index),
              );
            }),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _startNewPresentation,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva presentación'),
              style: _outlinedButtonStyle(),
            ),
          ),
          const SizedBox(height: 16),
          _neutralNote(
            'Los precios de cada combinación variante + presentación se configuran en el paso 5.',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationCard(int index) {
    final item = _presentations[index];
    final selected = _editingPresentationIndex == index;
    final allDefault =
        item.defaultVariantIds.isNotEmpty &&
        item.defaultVariantIds.length == item.assignedVariantIds.length;
    final partialDefault = item.defaultVariantIds.isNotEmpty && !allDefault;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _loadPresentation(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFBEB) : _canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _primary : _border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Acciones',
                  onSelected: (value) {
                    if (value == 'edit') {
                      _loadPresentation(index);
                    } else if (value == 'delete') {
                      _deletePresentation(index);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '${_step4PlainNumber(item.equivalentTo)} ${item.baseUnit}'
              ' · Pedido mínimo: ${_step4PlainNumber(item.minimumOrder)}'
              ' · Incremento: ${_step4PlainNumber(item.purchaseIncrement)}',
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 11),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: [
                if (allDefault)
                  _statusPill(
                    'Predeterminada',
                    color: _success,
                    background: const Color(0xFFE6F6ED),
                  ),
                if (partialDefault)
                  _statusPill(
                    'Predeterminada en ${item.defaultVariantIds.length}',
                    color: _success,
                    background: const Color(0xFFE6F6ED),
                  ),
                _statusPill(
                  'Asignada a ${item.assignedVariantIds.length} de ${widget.variants.length} variantes',
                  color: _muted,
                  background: const Color(0xFFEEF1F5),
                ),
                _statusPill(
                  item.allowsDecimals ? 'Cantidad decimal' : 'Cantidad entera',
                  color: _muted,
                  background: const Color(0xFFEEF1F5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresentationEditor() {
    final editing = _editingPresentationIndex != null;

    return _panel(
      background: _canvas,
      child: Form(
        key: _presentationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Editar presentación' : 'Nueva presentación',
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _labeledField(
              label: 'Nombre de la presentación *',
              child: TextFormField(
                controller: _presentationNameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(hint: 'Ej. Ciento o Caja x500'),
                validator: _requiredText,
              ),
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: 'Unidad de medida *',
              child: DropdownButtonFormField<String>(
                value: _presentationBaseUnit,
                isExpanded: true,
                decoration: _inputDecoration(),
                items: widget.baseUnits.map((unit) {
                  return DropdownMenuItem(value: unit, child: Text(unit));
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _presentationBaseUnit = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 560;
                final fields = [
                  _labeledField(
                    label: 'Equivale a *',
                    child: TextFormField(
                      controller: _presentationEquivalentController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(
                        suffixText: _presentationBaseUnit,
                      ),
                      validator: _positiveNumberValidator,
                    ),
                  ),
                  _labeledField(
                    label: 'Pedido mínimo *',
                    child: TextFormField(
                      controller: _presentationMinimumController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(),
                      validator: _positiveNumberValidator,
                    ),
                  ),
                  _labeledField(
                    label: 'Se puede pedir en múltiplos de *',
                    child: TextFormField(
                      controller: _presentationIncrementController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(),
                      validator: _positiveNumberValidator,
                    ),
                  ),
                ];

                if (narrow) {
                  return Column(
                    children: [
                      fields[0],
                      const SizedBox(height: 14),
                      fields[1],
                      const SizedBox(height: 14),
                      fields[2],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: fields[0]),
                    const SizedBox(width: 10),
                    Expanded(child: fields[1]),
                    const SizedBox(width: 10),
                    Expanded(child: fields[2]),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: 'Cantidad permitida',
              child: DropdownButtonFormField<bool>(
                value: _presentationAllowsDecimals,
                isExpanded: true,
                decoration: _inputDecoration(),
                items: const [
                  DropdownMenuItem(
                    value: false,
                    child: Text('Solo cantidades enteras'),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text('Cantidades decimales'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _presentationAllowsDecimals = value ?? false;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeColor: _ink,
              activeTrackColor: _primary,
              value: _presentationIsDefault,
              title: const Text(
                'Presentación predeterminada',
                style: TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Solo puede existir una predeterminada para cada variante.',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
              onChanged: (value) {
                setState(() {
                  _presentationIsDefault = value;
                });
              },
            ),
            const Divider(height: 28),
            _buildScopeEditor(
              title: 'Disponible para',
              allSelected: _presentationForAllVariants,
              selectedIds: _presentationVariantIds,
              onAllChanged: (value) {
                setState(() {
                  _presentationForAllVariants = value;
                  if (value) {
                    _presentationVariantIds = {..._allVariantIds};
                  }
                });
              },
              onChangeSelection: () async {
                final result = await _selectVariants(_presentationVariantIds);
                if (result == null || !mounted) {
                  return;
                }
                setState(() {
                  _presentationVariantIds = result;
                  _presentationForAllVariants =
                      result.length == _allVariantIds.length &&
                      result.containsAll(_allVariantIds);
                });
              },
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final cancelButton = OutlinedButton(
                  onPressed: _cancelPresentationChanges,
                  style: _outlinedButtonStyle(),
                  child: const Text('Cancelar'),
                );
                final saveButton = FilledButton(
                  onPressed: _savePresentation,
                  style: _primaryButtonStyle(),
                  child: Text(
                    editing ? 'Guardar cambios' : 'Guardar presentación',
                  ),
                );
                if (constraints.maxWidth < 430) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      saveButton,
                      const SizedBox(height: 10),
                      cancelButton,
                    ],
                  );
                }
                return Row(
                  children: [cancelButton, const Spacer(), saveButton],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // INTERFAZ · EMPAQUES
  // ==========================================================================

  Widget _buildPackagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionIntro(
          icon: Icons.inventory_2_outlined,
          title:
              '¿Este producto utiliza empaques de transporte o abastecimiento?',
          description:
              'Los empaques logísticos no tienen precio, salvo que también se creen como presentación de venta.',
          trailing: _buildBinaryChoice(
            negativeLabel: 'No aplica',
            positiveLabel: 'Sí, agregar empaque',
            currentValue: _usesPackages,
            onChanged: _setPackageUsage,
          ),
        ),
        const SizedBox(height: 14),
        if (_usesPackages == null)
          _undecidedOptionalState(
            icon: Icons.local_shipping_outlined,
            title: 'Define si esta sección aplica',
            description:
                'Por ejemplo: caja máster, pallet, carrete o empaque del proveedor.',
          )
        else if (_usesPackages == false)
          _notApplicableState(
            icon: Icons.check_circle_outline,
            title: 'Empaques logísticos · No aplica',
            description:
                'La sección está completada y no se mostrarán formularios vacíos.',
            onChange: () => _setPackageUsage(true),
          )
        else
          _responsivePanels(
            left: _buildPackageList(),
            right: _buildPackageEditor(),
            leftFlex: 43,
            rightFlex: 57,
          ),
      ],
    );
  }

  Widget _buildPackageList() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Empaques registrados',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusPill(
                '${_packages.length}',
                color: _ink,
                background: const Color(0xFFFFF4C7),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_packages.isEmpty)
            _emptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Aún no hay empaques',
              description:
                  'Agrega cómo llega, se almacena o se transporta el producto.',
            )
          else
            ...List.generate(_packages.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPackageCard(index),
              );
            }),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _startNewPackage,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo empaque'),
              style: _outlinedButtonStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(int index) {
    final item = _packages[index];
    final selected = _editingPackageIndex == index;
    final containedLabel = _packageContainedLabel(item);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _loadPackage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFBEB) : _canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _primary : _border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _statusPill(
                  'Solo logístico',
                  color: _muted,
                  background: const Color(0xFFEEF1F5),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Acciones',
                  onSelected: (value) {
                    if (value == 'edit') {
                      _loadPackage(index);
                    } else if (value == 'delete') {
                      _deletePackage(index);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Contiene ${_step4PlainNumber(item.contains)} × $containedLabel',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 9),
            Text(
              'Equivalencia total: '
              '${_step4PlainNumber(item.totalBaseUnits)} ${item.baseUnit}',
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: [
                _statusPill(
                  'Aplica a ${item.assignedVariantIds.length} de ${widget.variants.length}',
                  color: _muted,
                  background: const Color(0xFFEEF1F5),
                ),
                if (item.linkedSalesPresentationId != null)
                  _statusPill(
                    'Presentación vinculada',
                    color: _success,
                    background: const Color(0xFFE6F6ED),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageEditor() {
    final editing = _editingPackageIndex != null;
    final equivalence = _currentPackageEquivalence;
    final linkedId = editing
        ? _packages[_editingPackageIndex!].linkedSalesPresentationId
        : null;

    return _panel(
      background: _canvas,
      child: Form(
        key: _packageFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Editar empaque' : 'Nuevo empaque',
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 560;

                final name = _labeledField(
                  label: 'Nombre del empaque *',
                  child: TextFormField(
                    controller: _packageNameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(hint: 'Ej. Caja máster'),
                    validator: _requiredText,
                  ),
                );
                final contains = _labeledField(
                  label: 'Contiene *',
                  child: TextFormField(
                    controller: _packageContainsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration(),
                    validator: _positiveNumberValidator,
                  ),
                );

                if (narrow) {
                  return Column(
                    children: [name, const SizedBox(height: 14), contains],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: name),
                    const SizedBox(width: 12),
                    Expanded(child: contains),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: 'Tipo de contenido *',
              child: DropdownButtonFormField<PackageContentKind>(
                value: _packageContentKind,
                isExpanded: true,
                decoration: _inputDecoration(),
                items: const [
                  DropdownMenuItem(
                    value: PackageContentKind.baseUnit,
                    child: Text('Unidad de medida'),
                  ),
                  DropdownMenuItem(
                    value: PackageContentKind.salesPresentation,
                    child: Text('Presentación de venta'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _packageContentKind = value;
                    _packageContentReferenceId =
                        value == PackageContentKind.baseUnit
                        ? widget.baseUnits.first
                        : _presentations.isEmpty
                        ? null
                        : _presentations.first.id;
                  });
                },
              ),
            ),
            const SizedBox(height: 14),
            _buildPackageContainedSelector(),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calculate_outlined,
                      color: _ink,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Equivalencia logística calculada',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          equivalence == null
                              ? 'Completa el contenido'
                              : 'Equivalencia total: '
                                    '${_step4PlainNumber(equivalence.total)} '
                                    '${equivalence.baseUnit}',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: 'Código del proveedor (opcional)',
              child: TextFormField(
                controller: _packageSupplierCodeController,
                decoration: _inputDecoration(hint: 'Ej. CM-PER-1000'),
              ),
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: 'Descripción (opcional)',
              child: TextFormField(
                controller: _packageDescriptionController,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  hint: 'Detalles de almacenamiento o transporte.',
                ),
              ),
            ),
            const Divider(height: 28),
            _buildScopeEditor(
              title: 'Aplica a',
              allSelected: _packageForAllVariants,
              selectedIds: _packageVariantIds,
              onAllChanged: (value) {
                setState(() {
                  _packageForAllVariants = value;
                  if (value) {
                    _packageVariantIds = {..._allVariantIds};
                  }
                });
              },
              onChangeSelection: () async {
                final result = await _selectVariants(_packageVariantIds);
                if (result == null || !mounted) {
                  return;
                }
                setState(() {
                  _packageVariantIds = result;
                  _packageForAllVariants =
                      result.length == _allVariantIds.length &&
                      result.containsAll(_allVariantIds);
                });
              },
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿El cliente también puede pedir este empaque?',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Se creará una presentación de venta separada y vinculada. El precio se asignará en el paso 5.',
                    style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 11),
                  OutlinedButton.icon(
                    onPressed: editing ? _openOrCreateLinkedPresentation : null,
                    icon: Icon(
                      linkedId == null ? Icons.add_link : Icons.open_in_new,
                      size: 18,
                    ),
                    label: Text(
                      linkedId == null
                          ? 'Crear presentación de venta vinculada'
                          : 'Abrir presentación vinculada',
                    ),
                    style: _outlinedButtonStyle(),
                  ),
                  if (!editing) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Guarda primero el empaque.',
                      style: TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final cancelButton = OutlinedButton(
                  onPressed: _cancelPackageChanges,
                  style: _outlinedButtonStyle(),
                  child: const Text('Cancelar'),
                );
                final saveButton = FilledButton(
                  onPressed: _savePackage,
                  style: _primaryButtonStyle(),
                  child: Text(editing ? 'Guardar cambios' : 'Guardar empaque'),
                );
                if (constraints.maxWidth < 430) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      saveButton,
                      const SizedBox(height: 10),
                      cancelButton,
                    ],
                  );
                }
                return Row(
                  children: [cancelButton, const Spacer(), saveButton],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageContainedSelector() {
    if (_packageContentKind == PackageContentKind.baseUnit) {
      return _labeledField(
        label: 'Unidad contenida *',
        child: DropdownButtonFormField<String>(
          value: widget.baseUnits.contains(_packageContentReferenceId)
              ? _packageContentReferenceId
              : widget.baseUnits.first,
          isExpanded: true,
          decoration: _inputDecoration(),
          items: widget.baseUnits.map((unit) {
            return DropdownMenuItem(value: unit, child: Text(unit));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _packageContentReferenceId = value;
            });
          },
        ),
      );
    }

    return _labeledField(
      label: 'Presentación contenida *',
      child: DropdownButtonFormField<String>(
        value:
            _presentations.any((item) => item.id == _packageContentReferenceId)
            ? _packageContentReferenceId
            : null,
        isExpanded: true,
        decoration: _inputDecoration(
          hint: _presentations.isEmpty
              ? 'Primero crea una presentación'
              : 'Selecciona una presentación',
        ),
        items: _presentations.map((item) {
          return DropdownMenuItem(
            value: item.id,
            child: Text(
              '${item.name} · ${_step4PlainNumber(item.equivalentTo)} ${item.baseUnit}',
            ),
          );
        }).toList(),
        onChanged: _presentations.isEmpty
            ? null
            : (value) {
                setState(() {
                  _packageContentReferenceId = value;
                });
              },
        validator: (value) {
          if (_packageContentKind == PackageContentKind.salesPresentation &&
              value == null) {
            return 'Selecciona la presentación contenida.';
          }
          return null;
        },
      ),
    );
  }

  // ==========================================================================
  // INTERFAZ · CONTENIDO
  // ==========================================================================

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionIntro(
          icon: Icons.category_outlined,
          title: '¿El producto vendido contiene varios elementos?',
          description:
              'Utiliza esta sección para juegos, kits, sets de accesorios o paquetes compuestos.',
          trailing: _buildBinaryChoice(
            negativeLabel: 'No aplica',
            positiveLabel: 'Sí, definir contenido',
            currentValue: _hasContent,
            onChanged: _setContentUsage,
          ),
        ),
        const SizedBox(height: 14),
        if (_hasContent == null)
          _undecidedOptionalState(
            icon: Icons.handyman_outlined,
            title: 'Define si esta sección aplica',
            description:
                'Cada componente puede escribirse manualmente y, de forma opcional, relacionarse con una variante del catálogo.',
          )
        else if (_hasContent == false)
          _notApplicableState(
            icon: Icons.check_circle_outline,
            title: 'Contenido del producto · No aplica',
            description:
                'La sección está completada. El producto no representa un juego o kit.',
            onChange: () => _setContentUsage(true),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.variants.length > 1) ...[
                _buildContentVariantToolbar(),
                const SizedBox(height: 14),
              ],
              _responsivePanels(
                left: _buildContentTable(),
                right: _buildContentEditor(),
                leftFlex: 65,
                rightFlex: 35,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildContentVariantToolbar() {
    return _panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final selector = Row(
            children: [
              const Text(
                'Contenido de la variante:',
                style: TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedContentVariantId,
                  isExpanded: true,
                  decoration: _inputDecoration(dense: true),
                  items: widget.variants.map((variant) {
                    return DropdownMenuItem(
                      value: variant.id,
                      child: Text(variant.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedContentVariantId = value;
                      _startNewContentItem(rebuild: false);
                    });
                  },
                ),
              ),
            ],
          );

          final copyButton = OutlinedButton.icon(
            onPressed: _copyContentToOtherVariants,
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            label: const Text('Copiar contenido a otras variantes'),
            style: _outlinedButtonStyle(),
          );

          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [selector, const SizedBox(height: 10), copyButton],
            );
          }

          return Row(
            children: [
              Expanded(child: selector),
              const SizedBox(width: 18),
              copyButton,
            ],
          );
        },
      ),
    );
  }

  List<MapEntry<int, ProductContentItemDraft>> get _visibleContentEntries {
    final variantId = _selectedContentVariantId ?? widget.variants.first.id;
    final entries = <MapEntry<int, ProductContentItemDraft>>[];

    for (var index = 0; index < _contentItems.length; index++) {
      final item = _contentItems[index];
      if (item.ownerVariantId == variantId) {
        entries.add(MapEntry(index, item));
      }
    }

    return entries;
  }

  Widget _buildContentTable() {
    final entries = _visibleContentEntries;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Contenido del producto',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusPill(
                _contentCounterLabel(entries.map((e) => e.value).toList()),
                color: _ink,
                background: const Color(0xFFFFF4C7),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            _emptyState(
              icon: Icons.category_outlined,
              title: 'Aún no hay componentes',
              description:
                  'Agrega el primer elemento incluido en esta variante.',
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 420),
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Scrollbar(
                controller: _contentTableScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _contentTableScrollController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(_soft),
                      columns: const [
                        DataColumn(label: Text('Elemento incluido')),
                        DataColumn(label: Text('Cantidad')),
                        DataColumn(label: Text('Unidad')),
                        DataColumn(label: Text('Producto relacionado')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: entries.map((entry) {
                        final item = entry.value;
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  item.componentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(_step4PlainNumber(item.quantity))),
                            DataCell(Text(item.unit)),
                            DataCell(
                              SizedBox(
                                width: 190,
                                child: Text(
                                  _catalogVariantLabel(
                                        item.relatedCatalogVariantId,
                                      ) ??
                                      'Sin relación',
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        _loadContentItem(entry.key),
                                    child: const Text('Editar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _deleteContentItem(entry.key),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                    ),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          _neutralNote(
            'El precio del juego se configura en el paso 5; no se asigna a cada componente.',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildContentEditor() {
    final editing = _editingContentIndex != null;
    final relatedLabel = _catalogVariantLabel(_relatedCatalogVariantId);

    return _panel(
      background: _canvas,
      child: Form(
        key: _contentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Editar componente' : 'Agregar componente',
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _labeledField(
              label: 'Nombre del componente *',
              child: TextFormField(
                controller: _componentNameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(hint: 'Ej. Broca 3 mm'),
                validator: _requiredText,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final quantity = _labeledField(
                  label: 'Cantidad *',
                  child: TextFormField(
                    controller: _componentQuantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(),
                    validator: _positiveNumberValidator,
                  ),
                );
                final unit = _labeledField(
                  label: 'Unidad *',
                  child: DropdownButtonFormField<String>(
                    value: _componentUnit,
                    isExpanded: true,
                    decoration: _inputDecoration(),
                    items: widget.baseUnits.map((item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _componentUnit = value;
                      });
                    },
                  ),
                );

                if (constraints.maxWidth < 420) {
                  return Column(
                    children: [quantity, const SizedBox(height: 14), unit],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: quantity),
                    const SizedBox(width: 12),
                    Expanded(child: unit),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: 'Producto o variante relacionada (opcional)',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _pickCatalogVariant,
                child: InputDecorator(
                  decoration: _inputDecoration(suffixIcon: Icons.search),
                  child: Text(
                    relatedLabel ?? 'Buscar en el catálogo',
                    style: TextStyle(
                      color: relatedLabel == null ? _muted : _ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'El nombre puede guardarse aunque el componente no exista en el catálogo.',
              style: TextStyle(color: _muted, fontSize: 10, height: 1.35),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final cancelButton = OutlinedButton(
                  onPressed: _startNewContentItem,
                  style: _outlinedButtonStyle(),
                  child: const Text('Cancelar'),
                );
                final saveButton = FilledButton(
                  onPressed: _saveContentItem,
                  style: _primaryButtonStyle(),
                  child: Text(
                    editing ? 'Guardar cambios' : 'Agregar componente',
                  ),
                );
                if (constraints.maxWidth < 430) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      saveButton,
                      const SizedBox(height: 10),
                      cancelButton,
                    ],
                  );
                }
                return Row(
                  children: [cancelButton, const Spacer(), saveButton],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // COMPONENTES COMPARTIDOS
  // ==========================================================================

  Widget _buildSectionIntro({
    required IconData icon,
    required String title,
    required String description,
    required Widget trailing,
  }) {
    return _panel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final text = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4C7),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _ink, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 850) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: 14), trailing],
            );
          }

          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 20),
              Flexible(child: trailing),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBinaryChoice({
    required String negativeLabel,
    required String positiveLabel,
    required bool? currentValue,
    required ValueChanged<bool> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        ChoiceChip(
          selected: currentValue == false,
          onSelected: (_) => onChanged(false),
          label: Text(negativeLabel),
          selectedColor: _ink,
          backgroundColor: _soft,
          labelStyle: TextStyle(
            color: currentValue == false ? Colors.white : _ink,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          side: BorderSide(color: currentValue == false ? _ink : _border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        ChoiceChip(
          selected: currentValue == true,
          onSelected: (_) => onChanged(true),
          label: Text(positiveLabel),
          selectedColor: _primary,
          backgroundColor: _soft,
          labelStyle: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          side: BorderSide(color: currentValue == true ? _primary : _border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ],
    );
  }

  Widget _buildScopeEditor({
    required String title,
    required bool allSelected,
    required Set<String> selectedIds,
    required ValueChanged<bool> onAllChanged,
    required VoidCallback onChangeSelection,
  }) {
    if (widget.variantLayout == Step4VariantLayout.single) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: _success, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Variante automática · ${widget.variants.first.label}',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _radioOption(
          selected: allSelected,
          title: 'Todas las variantes (${widget.variants.length})',
          onTap: () => onAllChanged(true),
        ),
        const SizedBox(height: 7),
        _radioOption(
          selected: !allSelected,
          title: 'Variantes seleccionadas (${selectedIds.length})',
          onTap: () => onAllChanged(false),
        ),
        if (!allSelected) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onChangeSelection,
              icon: const Icon(Icons.tune, size: 17),
              label: const Text('Cambiar selección'),
              style: _outlinedButtonStyle(compact: true),
            ),
          ),
        ],
      ],
    );
  }

  Widget _radioOption({
    required bool selected,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _primary : _border),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              activeColor: _ink,
              onChanged: (_) => onTap(),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _undecidedOptionalState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return _panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 42),
        child: Column(
          children: [
            Icon(icon, size: 44, color: _muted),
            const SizedBox(height: 13),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notApplicableState({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onChange,
  }) {
    return _panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F6ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: _success),
            ),
            const SizedBox(height: 13),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onChange,
              style: _outlinedButtonStyle(),
              child: const Text('Cambiar respuesta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: _muted),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _neutralNote(String message, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _muted, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required Widget child,
    Color background = Colors.white,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _statusPill(
    String label, {
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _buildBottomNavigation() {
    String nextLabel;
    switch (_section) {
      case Step4Section.salesPresentations:
        nextLabel = 'Siguiente: empaques';
        break;
      case Step4Section.logisticsPackages:
        nextLabel = 'Siguiente: contenido';
        break;
      case Step4Section.productContent:
        nextLabel = 'Siguiente: precios';
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final backButton = OutlinedButton(
              onPressed: _handleBack,
              style: _outlinedButtonStyle(),
              child: const Text('Anterior'),
            );
            final nextButton = FilledButton(
              onPressed: _handleNext,
              style: _primaryButtonStyle(),
              child: Text(nextLabel),
            );
            const progress = Text(
              'Paso 4 de 7',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12),
            );
            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nextButton,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      backButton,
                      const Expanded(child: progress),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                backButton,
                const Expanded(child: progress),
                nextButton,
              ],
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? label,
    String? hint,
    String? suffixText,
    IconData? suffixIcon,
    IconData? prefixIcon,
    bool dense = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      isDense: dense,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 13,
        vertical: dense ? 11 : 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade600, width: 2),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: _ink,
      disabledBackgroundColor: const Color(0xFFE6E8EC),
      disabledForegroundColor: _muted,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    );
  }

  ButtonStyle _outlinedButtonStyle({bool compact = false}) {
    return OutlinedButton.styleFrom(
      foregroundColor: _ink,
      side: const BorderSide(color: Color(0xFFBAC4D2)),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 13 : 18,
        vertical: compact ? 10 : 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  // ==========================================================================
  // UTILIDADES
  // ==========================================================================

  SalesPresentationDraft? _presentationById(String id) {
    for (final item in _presentations) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  String _packageContainedLabel(LogisticsPackageDraft package) {
    if (package.contentKind == PackageContentKind.baseUnit) {
      return package.contentReferenceId;
    }

    return _presentationById(package.contentReferenceId)?.name ??
        'Presentación eliminada';
  }

  String? _catalogVariantLabel(String? id) {
    if (id == null) {
      return null;
    }

    for (final item in widget.catalogVariants) {
      if (item.id == id) {
        return item.label;
      }
    }
    return null;
  }

  String _contentCounterLabel(List<ProductContentItemDraft> items) {
    if (items.isEmpty) {
      return '0 componentes';
    }

    final units = items.map((item) => item.unit).toSet();
    if (units.length == 1) {
      final unit = units.first;
      final total = items.fold<double>(0, (sum, item) => sum + item.quantity);

      if (unit == 'PZA') {
        return '${_step4PlainNumber(total)} '
            '${total == 1 ? 'pieza' : 'piezas'} en total';
      }

      return '${_step4PlainNumber(total)} $unit en total';
    }

    return '${items.length} '
        '${items.length == 1 ? 'componente registrado' : 'componentes registrados'}';
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  String? _positiveNumberValidator(String? value) {
    if (_parsePositive(value ?? '') == null) {
      return 'Ingresa un valor mayor que cero.';
    }
    return null;
  }

  double? _parsePositive(String source) {
    final normalized = source.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  String? _nullIfEmpty(String source) {
    final value = source.trim();
    return value.isEmpty ? null : value;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: destructive ? Colors.red.shade700 : _primary,
                foregroundColor: destructive ? Colors.white : _ink,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
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

String _step4PlainNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

// ============================================================================
// INTEGRACIÓN CON EL FLUJO EXISTENTE
// ============================================================================
//
// 1) Guarda el resultado del paso 4 en el State:
//
// Step4SalesDraft? _step4Draft;
//
// 2) Convierte las variantes del paso 3:
//
// List<Step4VariantOption> _buildStep4Variants() {
//   if (_selectedTypeIndex == 0) {
//     return [
//       Step4VariantOption(
//         id: _singleVariantId,
//         label: _singleNameController.text.trim(),
//       ),
//     ];
//   }
//
//   if (_selectedTypeIndex == 1) {
//     return _variants.map((variant) {
//       return Step4VariantOption(
//         id: variant.id,
//         label: variant.name,
//       );
//     }).toList();
//   }
//
//   return _matrixVariants.map((variant) {
//     return Step4VariantOption(
//       id: variant.id,
//       label: variant.name,
//       rowValue: variant.rowValue,
//       columnValue: variant.columnValue,
//     );
//   }).toList();
// }
//
// Step4VariantLayout get _step4VariantLayout {
//   if (_selectedTypeIndex == 0) {
//     return Step4VariantLayout.single;
//   }
//   if (_selectedTypeIndex == 1) {
//     return Step4VariantLayout.list;
//   }
//   return Step4VariantLayout.matrix;
// }
//
// 3) Sustituye _buildIncompleteStep(3) en el PageView:
//
// Step4SalesLogisticsContentPanel(
//   familyName: _familyName ?? 'Familia sin nombre',
//   variantLayout: _step4VariantLayout,
//   variants: _buildStep4Variants(),
//   initialPresentations:
//       _step4Draft?.presentations ?? const [],
//   initialLogisticsPackages:
//       _step4Draft?.logisticsPackages ?? const [],
//   initialContentItems:
//       _step4Draft?.contentItems ?? const [],
//   initialUsesLogisticsPackages:
//       _step4Draft?.usesLogisticsPackages,
//   initialHasProductContent:
//       _step4Draft?.hasProductContent,
//   catalogVariants: _catalogVariantsForRelation,
//   onChanged: (draft) {
//     _step4Draft = draft;
//   },
//   onBack: () {
//     _pageController.previousPage(
//       duration: const Duration(milliseconds: 250),
//       curve: Curves.easeOut,
//     );
//   },
//   onNext: (draft) {
//     _step4Draft = draft;
//     _pageController.nextPage(
//       duration: const Duration(milliseconds: 250),
//       curve: Curves.easeOut,
//     );
//   },
// ),
//
// 4) Conecta el paso 4 con paso5_precios_corregido.dart:
//
// List<SellablePriceCombination> _buildSellablePriceCombinations() {
//   final draft = _step4Draft;
//   if (draft == null) {
//     return [];
//   }
//
//   return draft.presentations.expand((presentation) {
//     return presentation.assignedVariantIds.map((variantId) {
//       final variant = _buildStep4Variants().firstWhere(
//         (item) => item.id == variantId,
//       );
//
//       return SellablePriceCombination(
//         variantId: variant.id,
//         variantLabel: variant.label,
//         presentationId: presentation.id,
//         presentationLabel: presentation.name,
//         baseUnit: presentation.baseUnit,
//         equivalentToBaseUnit: presentation.equivalentTo,
//         minimumOrder: presentation.minimumOrder,
//         purchaseIncrement: presentation.purchaseIncrement,
//       );
//     });
//   }).toList();
// }
//
// Ninguna fila de precio se crea manualmente: cada una nace de una asignación
// válida variante + presentación guardada en este paso.
