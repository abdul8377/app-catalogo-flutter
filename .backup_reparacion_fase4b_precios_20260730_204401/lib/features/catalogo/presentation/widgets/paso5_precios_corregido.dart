import 'package:flutter/material.dart';

// ============================================================================
// PASO 5 · PRECIOS
//
// Widget autocontenido para integrar en el PageView del registro de productos.
// Las filas NO se crean manualmente: se generan desde cada combinación válida
// variante + presentación recibida desde el paso 4.
// ============================================================================

enum PriceConfigurationType { fixed, quantity, quote, unconfigured }

enum PriceScreenView { table, matrix }

enum PriceFilter { all, pending, quote }

@immutable
class SellablePriceCombination {
  const SellablePriceCombination({
    required this.variantId,
    required this.variantLabel,
    required this.presentationId,
    required this.presentationLabel,
    required this.baseUnit,
    required this.equivalentToBaseUnit,
    this.minimumOrder = 1,
    this.purchaseIncrement = 1,
  });

  final String variantId;
  final String variantLabel;
  final String presentationId;
  final String presentationLabel;
  final String baseUnit;
  final double equivalentToBaseUnit;
  final double minimumOrder;
  final double purchaseIncrement;

  String get sourceKey => '$variantId::$presentationId';
}

@immutable
class PriceListDraft {
  const PriceListDraft({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.includesIgv,
    required this.validFrom,
    this.validUntil,
  });

  final String id;
  final String name;
  final String currencyCode;
  final bool includesIgv;
  final DateTime validFrom;
  final DateTime? validUntil;

  PriceListDraft copyWith({
    String? name,
    String? currencyCode,
    bool? includesIgv,
    DateTime? validFrom,
    DateTime? validUntil,
    bool clearValidUntil = false,
  }) {
    return PriceListDraft(
      id: id,
      name: name ?? this.name,
      currencyCode: currencyCode ?? this.currencyCode,
      includesIgv: includesIgv ?? this.includesIgv,
      validFrom: validFrom ?? this.validFrom,
      validUntil: clearValidUntil ? null : validUntil ?? this.validUntil,
    );
  }
}

@immutable
class QuantityPriceRange {
  const QuantityPriceRange({
    required this.from,
    required this.until,
    required this.pricePerPresentation,
  });

  final double from;
  final double? until;
  final double pricePerPresentation;
}

@immutable
class ProductPriceDraft {
  const ProductPriceDraft({
    required this.listId,
    required this.variantId,
    required this.presentationId,
    required this.configuration,
    this.fixedPrice,
    this.ranges = const [],
  });

  final String listId;
  final String variantId;
  final String presentationId;
  final PriceConfigurationType configuration;
  final double? fixedPrice;
  final List<QuantityPriceRange> ranges;

  String get key => '$listId::$variantId::$presentationId';

  bool get isReady {
    switch (configuration) {
      case PriceConfigurationType.fixed:
        return fixedPrice != null;
      case PriceConfigurationType.quantity:
        return ranges.isNotEmpty;
      case PriceConfigurationType.quote:
        return true;
      case PriceConfigurationType.unconfigured:
        return false;
    }
  }

  bool get hasNumericPrice => fixedPrice != null || ranges.isNotEmpty;

  ProductPriceDraft copyWith({
    PriceConfigurationType? configuration,
    double? fixedPrice,
    bool clearFixedPrice = false,
    List<QuantityPriceRange>? ranges,
  }) {
    return ProductPriceDraft(
      listId: listId,
      variantId: variantId,
      presentationId: presentationId,
      configuration: configuration ?? this.configuration,
      fixedPrice: clearFixedPrice ? null : fixedPrice ?? this.fixedPrice,
      ranges: ranges ?? this.ranges,
    );
  }
}

@immutable
class PricingStep5Draft {
  const PricingStep5Draft({
    required this.lists,
    required this.prices,
    required this.sellableCombinations,
  });

  final List<PriceListDraft> lists;
  final List<ProductPriceDraft> prices;
  final List<SellablePriceCombination> sellableCombinations;

  int pendingForList(String listId) {
    return prices
        .where((item) => item.listId == listId && !item.isReady)
        .length;
  }

  bool canActivate(String listId) => pendingForList(listId) == 0;
}

class _EditableQuantityRange {
  _EditableQuantityRange({
    String from = '',
    String until = '',
    String price = '',
  }) : fromController = TextEditingController(text: from),
       untilController = TextEditingController(text: until),
       priceController = TextEditingController(text: price);

  factory _EditableQuantityRange.fromDraft(QuantityPriceRange range) {
    return _EditableQuantityRange(
      from: _plainNumber(range.from),
      until: range.until == null ? '' : _plainNumber(range.until!),
      price: range.pricePerPresentation.toStringAsFixed(2),
    );
  }

  final TextEditingController fromController;
  final TextEditingController untilController;
  final TextEditingController priceController;

  void dispose() {
    fromController.dispose();
    untilController.dispose();
    priceController.dispose();
  }
}

class _BulkPriceResult {
  const _BulkPriceResult({required this.configuration, this.fixedPrice});

  final PriceConfigurationType configuration;
  final double? fixedPrice;
}

class Step5PricingPanel extends StatefulWidget {
  const Step5PricingPanel({
    super.key,
    required this.familyName,
    required this.totalVariantCount,
    required this.sellableCombinations,
    required this.onBack,
    required this.onNext,
    this.initialLists = const [],
    this.initialPrices = const [],
    this.onChanged,
  });

  final String familyName;
  final int totalVariantCount;

  /// Debe venir del paso 4. Cada elemento representa una asignación válida
  /// variante + presentación. Una combinación que no esté aquí será "No aplica"
  /// en la matriz y no generará una fila editable.
  final List<SellablePriceCombination> sellableCombinations;

  final List<PriceListDraft> initialLists;
  final List<ProductPriceDraft> initialPrices;
  final VoidCallback onBack;
  final ValueChanged<PricingStep5Draft> onNext;
  final ValueChanged<PricingStep5Draft>? onChanged;

  @override
  State<Step5PricingPanel> createState() => _Step5PricingPanelState();
}

class _Step5PricingPanelState extends State<Step5PricingPanel> {
  static const Color _primary = Color(0xFFFFC500);
  static const Color _ink = Color(0xFF20242B);
  static const Color _muted = Color(0xFF667085);
  static const Color _border = Color(0xFFD5DDE8);
  static const Color _canvas = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF16794A);
  static const Color _danger = Color(0xFFC62828);

  late List<PriceListDraft> _lists;
  late List<ProductPriceDraft> _prices;

  List<PriceListDraft> get _catalogPriceLists => [
    PriceListDraft(
      id: 'regular',
      name: 'Regular',
      currencyCode: 'PEN',
      includesIgv: true,
      validFrom: DateTime(2020),
    ),
    PriceListDraft(
      id: 'mayorista',
      name: 'Mayorista',
      currencyCode: 'PEN',
      includesIgv: true,
      validFrom: DateTime(2020),
    ),
    PriceListDraft(
      id: 'exportacion',
      name: 'Exportación',
      currencyCode: 'USD',
      includesIgv: false,
      validFrom: DateTime(2020),
    ),
  ];

  String? _selectedListId;
  String? _presentationFilterId;
  String? _editorPriceKey;

  PriceScreenView _screenView = PriceScreenView.table;
  PriceFilter _filter = PriceFilter.all;
  final Set<String> _selectedPriceKeys = <String>{};

  PriceConfigurationType _editorConfiguration =
      PriceConfigurationType.unconfigured;

  final TextEditingController _fixedPriceController = TextEditingController();

  final List<_EditableQuantityRange> _editableRanges = [];

  @override
  void initState() {
    super.initState();

    _lists = widget.initialLists.isEmpty
        ? [
            PriceListDraft(
              id: 'regular',
              name: 'Regular',
              currencyCode: 'PEN',
              includesIgv: true,
              validFrom: DateTime.now(),
            ),
          ]
        : List<PriceListDraft>.of(widget.initialLists);

    _selectedListId = _lists.first.id;
    _prices = List<ProductPriceDraft>.of(widget.initialPrices);
    _syncGeneratedRows();
  }

  @override
  void didUpdateWidget(covariant Step5PricingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldKeys = oldWidget.sellableCombinations
        .map((item) => item.sourceKey)
        .toSet();

    final newKeys = widget.sellableCombinations
        .map((item) => item.sourceKey)
        .toSet();

    if (oldKeys.length != newKeys.length || !oldKeys.containsAll(newKeys)) {
      _syncGeneratedRows();
      _selectedPriceKeys.removeWhere(
        (key) => !_prices.any((item) => item.key == key),
      );

      if (_editorPriceKey != null &&
          !_prices.any((item) => item.key == _editorPriceKey)) {
        _closeEditor();
      }
    }
  }

  @override
  void dispose() {
    _fixedPriceController.dispose();
    _disposeEditableRanges();
    super.dispose();
  }

  PriceListDraft get _selectedList {
    return _lists.firstWhere(
      (item) => item.id == _selectedListId,
      orElse: () => _lists.first,
    );
  }

  List<SellablePriceCombination> get _uniqueSources {
    final seen = <String>{};

    return widget.sellableCombinations
        .where((item) => seen.add(item.sourceKey))
        .toList();
  }

  List<ProductPriceDraft> get _activeListRows {
    final listId = _selectedList.id;
    return _prices.where((item) => item.listId == listId).toList();
  }

  int get _pendingCount =>
      _activeListRows.where((item) => !item.isReady).length;

  int get _totalPendingCount =>
      _prices.where((item) => !item.isReady).length;

  int get _quoteCount => _activeListRows
      .where((item) => item.configuration == PriceConfigurationType.quote)
      .length;

  int get _pricedCount => _activeListRows
      .where(
        (item) =>
            (item.configuration == PriceConfigurationType.fixed &&
                item.fixedPrice != null) ||
            (item.configuration == PriceConfigurationType.quantity &&
                item.ranges.isNotEmpty),
      )
      .length;

  int get _readyCount => _activeListRows.length - _pendingCount;

  ProductPriceDraft? get _editorPrice {
    final key = _editorPriceKey;
    if (key == null) {
      return null;
    }

    for (final price in _prices) {
      if (price.key == key) {
        return price;
      }
    }

    return null;
  }

  SellablePriceCombination? get _editorSource {
    final price = _editorPrice;
    if (price == null) {
      return null;
    }

    return _findSource(price.variantId, price.presentationId);
  }

  PricingStep5Draft get _draft {
    return PricingStep5Draft(
      lists: List<PriceListDraft>.unmodifiable(_lists),
      prices: List<ProductPriceDraft>.unmodifiable(_prices),
      sellableCombinations: List<SellablePriceCombination>.unmodifiable(
        _uniqueSources,
      ),
    );
  }

  void _syncGeneratedRows() {
    final existing = {for (final item in _prices) item.key: item};

    final generated = <ProductPriceDraft>[];

    for (final list in _lists) {
      for (final source in _uniqueSources) {
        final key = '${list.id}::${source.variantId}::${source.presentationId}';

        generated.add(
          existing[key] ??
              ProductPriceDraft(
                listId: list.id,
                variantId: source.variantId,
                presentationId: source.presentationId,
                configuration: PriceConfigurationType.unconfigured,
              ),
        );
      }
    }

    _prices = generated;
  }

  SellablePriceCombination? _findSource(
    String variantId,
    String presentationId,
  ) {
    for (final source in _uniqueSources) {
      if (source.variantId == variantId &&
          source.presentationId == presentationId) {
        return source;
      }
    }

    return null;
  }

  ProductPriceDraft? _findActivePrice(String variantId, String presentationId) {
    final listId = _selectedList.id;

    for (final price in _prices) {
      if (price.listId == listId &&
          price.variantId == variantId &&
          price.presentationId == presentationId) {
        return price;
      }
    }

    return null;
  }

  List<ProductPriceDraft> get _filteredRows {
    return _activeListRows.where((price) {
      if (_presentationFilterId != null &&
          price.presentationId != _presentationFilterId) {
        return false;
      }

      switch (_filter) {
        case PriceFilter.pending:
          return !price.isReady;
        case PriceFilter.quote:
          return price.configuration == PriceConfigurationType.quote;
        case PriceFilter.all:
          return true;
      }
    }).toList();
  }

  void _notifyChanged() {
    widget.onChanged?.call(_draft);
  }

  void _replacePrice(ProductPriceDraft updated) {
    final index = _prices.indexWhere((item) => item.key == updated.key);

    if (index == -1) {
      return;
    }

    setState(() {
      _prices[index] = updated;
    });

    _notifyChanged();
  }

  void _disposeEditableRanges() {
    for (final range in _editableRanges) {
      range.dispose();
    }
    _editableRanges.clear();
  }

  void _detachEditableRanges() {
    if (_editableRanges.isEmpty) {
      return;
    }

    final detached = List<_EditableQuantityRange>.of(_editableRanges);
    _editableRanges.clear();

    // Los TextField que usan estos controladores continúan montados hasta el
    // siguiente frame. Disponerlos antes de que Flutter desactive sus
    // dependencias puede romper el desmontaje del árbol.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final range in detached) {
        range.dispose();
      }
    });
  }

  void _closeEditor() {
    _detachEditableRanges();
    _fixedPriceController.clear();
    _editorPriceKey = null;
    _editorConfiguration = PriceConfigurationType.unconfigured;
  }

  void _openEditor(ProductPriceDraft price) {
    _detachEditableRanges();

    _fixedPriceController.text = price.fixedPrice == null
        ? ''
        : price.fixedPrice!.toStringAsFixed(2);

    _editableRanges.addAll(price.ranges.map(_EditableQuantityRange.fromDraft));

    if (price.configuration == PriceConfigurationType.quantity &&
        _editableRanges.isEmpty) {
      final source = _findSource(price.variantId, price.presentationId);

      _editableRanges.add(
        _EditableQuantityRange(from: _plainNumber(source?.minimumOrder ?? 1)),
      );
    }

    setState(() {
      _editorPriceKey = price.key;
      _editorConfiguration = price.configuration;
    });
  }

  void _changeEditorConfiguration(PriceConfigurationType configuration) {
    if (configuration == PriceConfigurationType.quantity &&
        _editableRanges.isEmpty) {
      final source = _editorSource;
      _editableRanges.add(
        _EditableQuantityRange(from: _plainNumber(source?.minimumOrder ?? 1)),
      );
    }

    setState(() {
      _editorConfiguration = configuration;
    });
  }

  double? _parseDecimal(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  Future<bool> _confirmFreePrice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Confirmar producto gratuito'),
          content: const Text(
            'El valor 0.00 se guardará como un precio válido y gratuito. '
            'No se considerará pendiente ni por cotizar.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Confirmar 0.00'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _saveEditor() async {
    final current = _editorPrice;
    final source = _editorSource;

    if (current == null || source == null) {
      return;
    }

    ProductPriceDraft updated;

    switch (_editorConfiguration) {
      case PriceConfigurationType.unconfigured:
        updated = current.copyWith(
          configuration: PriceConfigurationType.unconfigured,
          clearFixedPrice: true,
          ranges: const [],
        );
        break;

      case PriceConfigurationType.quote:
        updated = current.copyWith(
          configuration: PriceConfigurationType.quote,
          clearFixedPrice: true,
          ranges: const [],
        );
        break;

      case PriceConfigurationType.fixed:
        final rawValue = _fixedPriceController.text.trim();

        if (rawValue.isEmpty) {
          updated = current.copyWith(
            configuration: PriceConfigurationType.unconfigured,
            clearFixedPrice: true,
            ranges: const [],
          );
          break;
        }

        final price = _parseDecimal(rawValue);
        if (price == null || price < 0) {
          _showMessage('Ingresa un precio válido mayor o igual a 0.');
          return;
        }

        if (price == 0 && !await _confirmFreePrice()) {
          return;
        }

        if (!mounted) {
          return;
        }

        updated = current.copyWith(
          configuration: PriceConfigurationType.fixed,
          fixedPrice: price,
          ranges: const [],
        );
        break;

      case PriceConfigurationType.quantity:
        final validation = _validateQuantityRanges(source);

        if (validation.error != null) {
          _showMessage(validation.error!);
          return;
        }

        if (validation.ranges.any((range) => range.pricePerPresentation == 0) &&
            !await _confirmFreePrice()) {
          return;
        }

        if (!mounted) {
          return;
        }

        updated = current.copyWith(
          configuration: PriceConfigurationType.quantity,
          clearFixedPrice: true,
          ranges: validation.ranges,
        );
        break;
    }

    _replacePrice(updated);

    if (!mounted) {
      return;
    }

    setState(_closeEditor);
  }

  ({String? error, List<QuantityPriceRange> ranges}) _validateQuantityRanges(
    SellablePriceCombination source,
  ) {
    if (_editableRanges.isEmpty) {
      return (error: 'Agrega al menos un rango.', ranges: const []);
    }

    final parsed = <QuantityPriceRange>[];

    for (var index = 0; index < _editableRanges.length; index++) {
      final editable = _editableRanges[index];
      final from = _parseDecimal(editable.fromController.text);
      final until = _parseDecimal(editable.untilController.text);
      final price = _parseDecimal(editable.priceController.text);

      if (from == null || from <= 0) {
        return (
          error: 'El inicio del rango ${index + 1} no es válido.',
          ranges: const [],
        );
      }

      if (until != null && until < from) {
        return (
          error:
              'El final del rango ${index + 1} no puede ser menor que el inicio.',
          ranges: const [],
        );
      }

      if (price == null || price < 0) {
        return (
          error: 'El precio del rango ${index + 1} no es válido.',
          ranges: const [],
        );
      }

      parsed.add(
        QuantityPriceRange(
          from: from,
          until: until,
          pricePerPresentation: price,
        ),
      );
    }

    parsed.sort((a, b) => a.from.compareTo(b.from));

    const epsilon = 0.000001;
    final expectedFirst = source.minimumOrder;

    if ((parsed.first.from - expectedFirst).abs() > epsilon) {
      return (
        error:
            'El primer rango debe comenzar en ${_plainNumber(expectedFirst)}.',
        ranges: const [],
      );
    }

    for (var index = 1; index < parsed.length; index++) {
      final previous = parsed[index - 1];
      final current = parsed[index];

      if (previous.until == null) {
        return (
          error: 'Un rango sin límite debe ser el último.',
          ranges: const [],
        );
      }

      if (current.from <= previous.until! + epsilon) {
        return (
          error: 'Los rangos ${index} y ${index + 1} se superponen.',
          ranges: const [],
        );
      }

      final expectedFrom = previous.until! + source.purchaseIncrement;

      if ((current.from - expectedFrom).abs() > epsilon) {
        return (
          error: 'Hay un vacío entre los rangos ${index} y ${index + 1}.',
          ranges: const [],
        );
      }
    }

    if (parsed.last.until != null) {
      return (
        error: 'El último rango debe quedar sin límite.',
        ranges: const [],
      );
    }

    return (error: null, ranges: parsed);
  }

  void _addQuantityRange() {
    final source = _editorSource;
    String from = '';

    if (_editableRanges.isEmpty) {
      from = _plainNumber(source?.minimumOrder ?? 1);
    } else {
      final previousUntil = _parseDecimal(
        _editableRanges.last.untilController.text,
      );

      if (previousUntil != null) {
        from = _plainNumber(previousUntil + (source?.purchaseIncrement ?? 1));
      }
    }

    setState(() {
      _editableRanges.add(_EditableQuantityRange(from: from));
    });
  }

  void _removeQuantityRange(int index) {
    late final _EditableQuantityRange removed;
    setState(() {
      removed = _editableRanges.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.dispose();
    });
  }

  void _togglePriceSelection(ProductPriceDraft price, bool selected) {
    setState(() {
      if (selected) {
        _selectedPriceKeys.add(price.key);
      } else {
        _selectedPriceKeys.remove(price.key);
      }
    });
  }

  Future<void> _configureSelected() async {
    final selectedRows = _activeListRows
        .where((item) => _selectedPriceKeys.contains(item.key))
        .toList();

    if (selectedRows.isEmpty) {
      return;
    }

    final presentationIds = selectedRows
        .map((item) => item.presentationId)
        .toSet();

    final mixedPresentations = presentationIds.length > 1;
    final result = await _showBulkDialog(
      selectedRows.length,
      mixedPresentations,
    );

    if (result == null || !mounted) {
      return;
    }

    if (mixedPresentations &&
        result.configuration == PriceConfigurationType.fixed) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Presentaciones diferentes'),
            content: const Text(
              'La selección mezcla presentaciones distintas. '
              'El mismo importe se copiará como precio completo de cada '
              'presentación, no como precio por unidad base.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Aplicar de todos modos'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() {
      for (final selected in selectedRows) {
        final index = _prices.indexWhere((item) => item.key == selected.key);

        if (index == -1) {
          continue;
        }

        switch (result.configuration) {
          case PriceConfigurationType.fixed:
            _prices[index] = selected.copyWith(
              configuration: PriceConfigurationType.fixed,
              fixedPrice: result.fixedPrice,
              ranges: const [],
            );
            break;
          case PriceConfigurationType.quote:
            _prices[index] = selected.copyWith(
              configuration: PriceConfigurationType.quote,
              clearFixedPrice: true,
              ranges: const [],
            );
            break;
          case PriceConfigurationType.unconfigured:
            _prices[index] = selected.copyWith(
              configuration: PriceConfigurationType.unconfigured,
              clearFixedPrice: true,
              ranges: const [],
            );
            break;
          case PriceConfigurationType.quantity:
            break;
        }
      }

      _selectedPriceKeys.clear();
      _closeEditor();
    });

    _notifyChanged();
  }

  Future<_BulkPriceResult?> _showBulkDialog(
    int selectedCount,
    bool mixedPresentations,
  ) async {
    var rawPrice = '';
    var configuration = PriceConfigurationType.fixed;

    final result = await showDialog<_BulkPriceResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Configurar $selectedCount seleccionadas'),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<PriceConfigurationType>(
                      value: configuration,
                      decoration: _inputDecoration('Configuración'),
                      items: const [
                        DropdownMenuItem(
                          value: PriceConfigurationType.fixed,
                          child: Text('Precio fijo'),
                        ),
                        DropdownMenuItem(
                          value: PriceConfigurationType.quote,
                          child: Text('Por cotizar'),
                        ),
                        DropdownMenuItem(
                          value: PriceConfigurationType.unconfigured,
                          child: Text('Dejar pendiente'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          configuration = value;
                        });
                      },
                    ),
                    if (configuration == PriceConfigurationType.fixed) ...[
                      const SizedBox(height: 16),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          rawPrice = value;
                        },
                        decoration: _inputDecoration(
                          'Precio por presentación',
                          prefixText:
                              '${_currencySymbol(_selectedList.currencyCode)} ',
                        ),
                      ),
                    ],
                    if (mixedPresentations) ...[
                      const SizedBox(height: 14),
                      _buildInlineNote(
                        'La selección contiene presentaciones diferentes. '
                        'Antes de copiar un precio fijo se solicitará '
                        'confirmación.',
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Los rangos por cantidad se configuran individualmente '
                      'para respetar el pedido mínimo y el incremento de cada '
                      'presentación.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    double? price;

                    if (configuration == PriceConfigurationType.fixed) {
                      price = _parseDecimal(rawPrice);
                      if (price == null || price < 0) {
                        _showMessage(
                          'Ingresa un precio válido mayor o igual a 0.',
                        );
                        return;
                      }

                      if (price == 0 && !await _confirmFreePrice()) {
                        return;
                      }
                    }

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      _BulkPriceResult(
                        configuration: configuration,
                        fixedPrice: price,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<void> _selectPriceLists() async {
    final available = <String, PriceListDraft>{
      for (final list in _catalogPriceLists) list.id: list,
      for (final list in _lists) list.id: list,
    }.values.toList();
    final selected = _lists.map((list) => list.id).toSet();
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Listas aplicables al producto'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'La moneda y el tratamiento de IGV provienen de la lista. '
                  'No se redefinen dentro del producto.',
                  style: TextStyle(color: _muted),
                ),
                const SizedBox(height: 12),
                ...available.map(
                  (list) => CheckboxListTile(
                    value: selected.contains(list.id),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(list.name),
                    subtitle: Text(
                      '${list.currencyCode} · '
                      '${list.includesIgv ? 'Con IGV' : 'Sin IGV'}',
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value ?? false) {
                          selected.add(list.id);
                        } else {
                          selected.remove(list.id);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, {...selected}),
              child: const Text('Aplicar listas'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _lists = available.where((list) => result.contains(list.id)).toList();
      if (!_lists.any((list) => list.id == _selectedListId)) {
        _selectedListId = _lists.first.id;
      }
      _syncGeneratedRows();
      _selectedPriceKeys.clear();
      _closeEditor();
    });
    _notifyChanged();
  }







) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(value),
                ),
                style: _outlinedStyle(),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClear,
                tooltip: 'Quitar fecha final',
                icon: const Icon(Icons.close),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _changeSelectedList(String listId) {
    if (listId == _selectedListId || !_lists.any((item) => item.id == listId)) {
      return;
    }

    setState(() {
      _selectedListId = listId;
      _selectedPriceKeys.clear();
      _presentationFilterId = null;
      _filter = PriceFilter.all;
      _closeEditor();
    });
  }

  void _requestSelectedListChange(String? listId) {
    if (listId == null || listId == _selectedListId) {
      return;
    }

    // DropdownButton notifica mientras su ruta emergente termina de cerrarse.
    // Cambiar el subárbol en el mismo callback puede desactivar dependencias
    // que todavía pertenecen al overlay.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _changeSelectedList(listId);
      }
    });
  }

  Future<void> _continueToImages() async {
    if (_totalPendingCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Continuar con $_totalPendingCount pendientes'),
            content: const Text(
              'Puedes continuar y guardar el producto como borrador. '
              'Sin embargo, las combinaciones pendientes impedirán '
              'la activación definitiva en el paso 7.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Revisar precios'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Continuar como borrador'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    widget.onNext(_draft);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildListConfiguration(),
                  const SizedBox(height: 18),
                  _buildToolbar(),
                  const SizedBox(height: 14),
                  _buildMainContent(),
                  const SizedBox(height: 16),
                  _buildBottomRule(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 18,
      runSpacing: 14,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paso 4 · Precios',
              style: TextStyle(
                color: _ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Define cómo se calcula el precio de cada combinación de '
              'variante y presentación vendible.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3C4),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
                  'Familia: ${widget.familyName} · '
                  '${widget.totalVariantCount} variantes',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_activeListRows.length} combinaciones vendibles · '
                '$_pricedCount listas · $_quoteCount por cotizar · '
                '$_pendingCount pendientes',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListConfiguration() {
    final list = _selectedList;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      decoration: BoxDecoration(
        color: _canvas,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 14,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Lista: ',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: const Key('price_list_selector'),
                        value: list.id,
                        isDense: true,
                        items: _lists
                            .map(
                              (item) => DropdownMenuItem(
                                key: ValueKey('price_list_option_${item.id}'),
                                value: item.id,
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _lists.length > 1
                            ? _requestSelectedListChange
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${_currencySymbol(list.currencyCode)} · '
                  'Importes ${list.includesIgv ? 'con' : 'sin'} IGV · '
                  'Desde ${_formatDate(list.validFrom)} · '
                  '${list.validUntil == null ? 'Sin fecha final' : 'Hasta ${_formatDate(list.validUntil!)}'}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                key: const Key('seleccionar_listas_precios'),
                onPressed: _selectPriceLists,
                icon: const Icon(Icons.playlist_add_check, size: 18),
                label: const Text('Seleccionar listas'),
                style: _outlinedStyle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final presentationOptions = <String, String>{};

    for (final source in _uniqueSources) {
      presentationOptions.putIfAbsent(
        source.presentationId,
        () => source.presentationLabel,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildFilterChip(label: 'Todas', filter: PriceFilter.all),
              _buildFilterChip(
                label: 'Pendientes',
                filter: PriceFilter.pending,
              ),
              _buildFilterChip(label: 'Por cotizar', filter: PriceFilter.quote),
              SizedBox(
                width: 205,
                child: DropdownButtonFormField<String>(
                  value: _presentationFilterId ?? '__all__',
                  isDense: true,
                  decoration: _inputDecoration('Presentación'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '__all__',
                      child: Text('Todas'),
                    ),
                    ...presentationOptions.entries.map(
                      (item) => DropdownMenuItem<String>(
                        value: item.key,
                        child: Text(item.value),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _presentationFilterId = value == '__all__' ? null : value;
                    });
                  },
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_selectedPriceKeys.isNotEmpty)
                FilledButton.icon(
                  onPressed: _configureSelected,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(
                    'Configurar seleccionadas '
                    '(${_selectedPriceKeys.length})',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                  ),
                ),
              SegmentedButton<PriceScreenView>(
                segments: const [
                  ButtonSegment(
                    value: PriceScreenView.table,
                    icon: Icon(Icons.table_rows_outlined),
                    label: Text('Tabla'),
                  ),
                  ButtonSegment(
                    value: PriceScreenView.matrix,
                    icon: Icon(Icons.grid_view_outlined),
                    label: Text('Matriz'),
                  ),
                ],
                selected: {_screenView},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  setState(() {
                    _screenView = selection.first;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required PriceFilter filter,
  }) {
    return FilterChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) {
        setState(() {
          _filter = filter;
        });
      },
      selectedColor: _primary.withOpacity(0.22),
      checkmarkColor: _ink,
      side: const BorderSide(color: _border),
      labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1050;
        final editor = _editorPrice == null ? null : _buildEditorPanel();

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _screenView == PriceScreenView.table
                  ? _buildPriceTable()
                  : _buildPriceMatrix(),
              if (editor != null) ...[const SizedBox(height: 16), editor],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _screenView == PriceScreenView.table
                  ? _buildPriceTable()
                  : _buildPriceMatrix(),
            ),
            if (editor != null) ...[
              const SizedBox(width: 16),
              SizedBox(width: 410, child: editor),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPriceTable() {
    final rows = _filteredRows;

    if (_activeListRows.isEmpty) {
      return _buildNoCombinationsState();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: rows.isEmpty
          ? _buildEmptyFilteredState()
          : LayoutBuilder(
              builder: (context, constraints) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowHeight: 44,
                        dataRowMinHeight: 62,
                        dataRowMaxHeight: 72,
                        horizontalMargin: 12,
                        columnSpacing: 24,
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFFF0F3F7),
                        ),
                        columns: const [
                          DataColumn(label: Text('')),
                          DataColumn(label: Text('Variante')),
                          DataColumn(label: Text('Presentación')),
                          DataColumn(label: Text('Configuración')),
                          DataColumn(label: Text('Precio o detalle')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acción')),
                        ],
                        rows: rows.map(_buildPriceDataRow).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  DataRow _buildPriceDataRow(ProductPriceDraft price) {
    final source = _findSource(price.variantId, price.presentationId)!;

    final selected = _selectedPriceKeys.contains(price.key);

    return DataRow(
      selected: selected,
      color: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return _primary.withOpacity(0.13);
        }
        return Colors.white;
      }),
      cells: [
        DataCell(
          Checkbox(
            value: selected,
            activeColor: _ink,
            onChanged: (value) {
              _togglePriceSelection(price, value ?? false);
            },
          ),
        ),
        DataCell(
          SizedBox(
            width: 135,
            child: Text(
              source.variantLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 115,
            child: Text(
              source.presentationLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(_buildConfigurationBadge(price.configuration)),
        DataCell(
          SizedBox(
            width: 190,
            child: Text(
              _priceDetail(price, source),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    price.configuration == PriceConfigurationType.unconfigured
                    ? _muted
                    : _ink,
              ),
            ),
          ),
        ),
        DataCell(_buildReadyBadge(price)),
        DataCell(
          TextButton(
            onPressed: () {
              _openEditor(price);
            },
            child: Text(
              price.configuration == PriceConfigurationType.unconfigured
                  ? 'Configurar'
                  : price.configuration == PriceConfigurationType.quantity
                  ? 'Ver rangos'
                  : 'Editar',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceMatrix() {
    final variants = <String, String>{};
    final presentations = <String, String>{};

    for (final source in _uniqueSources) {
      variants.putIfAbsent(source.variantId, () => source.variantLabel);

      if (_presentationFilterId == null ||
          source.presentationId == _presentationFilterId) {
        presentations.putIfAbsent(
          source.presentationId,
          () => source.presentationLabel,
        );
      }
    }

    if (variants.isEmpty || presentations.isEmpty) {
      return _buildNoCombinationsState();
    }

    final tableWidth = 190.0 + presentations.length * 190.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FixedColumnWidth(190),
              for (var index = 0; index < presentations.length; index++)
                index + 1: const FixedColumnWidth(190),
            },
            border: TableBorder.all(
              color: _border,
              width: 1,
              borderRadius: BorderRadius.circular(10),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF0F3F7)),
                children: [
                  _buildMatrixHeaderCell('Variante \\ Presentación'),
                  ...presentations.values.map(_buildMatrixHeaderCell),
                ],
              ),
              ...variants.entries.map((variant) {
                return TableRow(
                  children: [
                    _buildMatrixVariantCell(variant.value),
                    ...presentations.entries.map(
                      (presentation) => _buildMatrixPriceCell(
                        variantId: variant.key,
                        presentationId: presentation.key,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixHeaderCell(String label) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixVariantCell(String label) {
    return SizedBox(
      height: 88,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixPriceCell({
    required String variantId,
    required String presentationId,
  }) {
    final source = _findSource(variantId, presentationId);
    final price = _findActivePrice(variantId, presentationId);

    if (source == null || price == null) {
      return Container(
        height: 88,
        color: const Color(0xFFF4F5F7),
        alignment: Alignment.center,
        child: const Text(
          'No aplica',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final selected = _selectedPriceKeys.contains(price.key);
    final hiddenByStateFilter =
        (_filter == PriceFilter.pending && price.isReady) ||
        (_filter == PriceFilter.quote &&
            price.configuration != PriceConfigurationType.quote);

    if (hiddenByStateFilter) {
      return Container(
        height: 88,
        color: const Color(0xFFF8F9FA),
        alignment: Alignment.center,
        child: const Text('—', style: TextStyle(color: _muted, fontSize: 12)),
      );
    }

    return Material(
      color: selected ? _primary.withOpacity(0.14) : Colors.white,
      child: InkWell(
        onTap: () {
          _openEditor(price);
        },
        child: SizedBox(
          height: 88,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: selected,
                  activeColor: _ink,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) {
                    _togglePriceSelection(price, value ?? false);
                  },
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _matrixPriceText(price),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              price.configuration ==
                                  PriceConfigurationType.unconfigured
                              ? _danger
                              : _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        price.isReady ? 'Lista' : 'Configurar',
                        style: TextStyle(
                          color: price.isReady ? _success : _muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorPanel() {
    final price = _editorPrice!;
    final source = _editorSource!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _canvas,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Configurar precio',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(_closeEditor);
                },
                tooltip: 'Cerrar editor',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReadOnlyLine('Variante', source.variantLabel),
                const SizedBox(height: 9),
                _buildReadOnlyLine('Presentación', source.presentationLabel),
                const SizedBox(height: 9),
                _buildReadOnlyLine(
                  'Lista',
                  '${_selectedList.name} · '
                      '${_currencySymbol(_selectedList.currencyCode)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'Configuración',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildConfigurationChoice(
                PriceConfigurationType.fixed,
                'Precio fijo',
              ),
              _buildConfigurationChoice(
                PriceConfigurationType.quantity,
                'Por cantidad',
              ),
              _buildConfigurationChoice(
                PriceConfigurationType.quote,
                'Por cotizar',
              ),
              _buildConfigurationChoice(
                PriceConfigurationType.unconfigured,
                'Sin configurar',
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_editorConfiguration == PriceConfigurationType.fixed)
            _buildFixedEditor(source),
          if (_editorConfiguration == PriceConfigurationType.quantity)
            _buildQuantityEditor(source),
          if (_editorConfiguration == PriceConfigurationType.quote)
            _buildInlineNote(
              'El producto podrá agregarse al pedido, pero su precio '
              'deberá completarse posteriormente. El total general '
              'se mostrará como “Pendiente de cotización”, nunca como cero.',
              icon: Icons.request_quote_outlined,
            ),
          if (_editorConfiguration == PriceConfigurationType.unconfigured)
            _buildInlineNote(
              'Esta combinación quedará pendiente. Puede guardarse en '
              'el borrador, pero impedirá activar el producto en el paso 7.',
              icon: Icons.pending_actions_outlined,
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(_closeEditor);
                  },
                  style: _outlinedStyle(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saveEditor,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Text(
                    price.configuration == PriceConfigurationType.unconfigured
                        ? 'Guardar configuración'
                        : 'Guardar cambios',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationChoice(PriceConfigurationType value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _editorConfiguration == value,
      onSelected: (_) {
        _changeEditorConfiguration(value);
      },
      selectedColor: _primary.withOpacity(0.25),
      checkmarkColor: _ink,
      side: const BorderSide(color: _border),
      labelStyle: const TextStyle(
        color: _ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildFixedEditor(SellablePriceCombination source) {
    final parsedPrice = _parseDecimal(_fixedPriceController.text);

    final reference = parsedPrice == null || source.equivalentToBaseUnit <= 0
        ? null
        : parsedPrice / source.equivalentToBaseUnit;

    final symbol = _currencySymbol(_selectedList.currencyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _fixedPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) {
            setState(() {});
          },
          decoration: _inputDecoration(
            'Precio por ${source.presentationLabel}',
            prefixText: '$symbol ',
            helperText: 'Vacío = pendiente. 0.00 = gratuito con confirmación.',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            reference == null
                ? 'Referencia por unidad base: —'
                : 'Referencia: $symbol '
                      '${reference.toStringAsFixed(3)} por '
                      '${source.baseUnit}',
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityEditor(SellablePriceCombination source) {
    final symbol = _currencySymbol(_selectedList.currencyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Los rangos se expresan en cantidades de '
          '${source.presentationLabel}. El rango alcanzado aplica a '
          'toda la cantidad pedida.',
          style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          _editableRanges.length,
          (index) =>
              _buildQuantityRangeRow(index, symbol, source.presentationLabel),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addQuantityRange,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar rango'),
            style: _outlinedStyle(),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'El primer rango debe iniciar en el pedido mínimo; no se '
          'permiten vacíos, repeticiones, cruces ni superposiciones. '
          'El último debe quedar sin límite.',
          style: TextStyle(color: _muted, fontSize: 11, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildQuantityRangeRow(int index, String symbol, String presentation) {
    final range = _editableRanges[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rango ${index + 1}',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _removeQuantityRange(index);
                },
                tooltip: 'Eliminar rango',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline,
                  color: _danger,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: range.fromController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Desde'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: range.untilController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Hasta', hintText: 'Sin límite'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: range.priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
              'Precio por $presentation',
              prefixText: '$symbol ',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationBadge(PriceConfigurationType configuration) {
    late final String label;
    late final Color background;
    late final Color foreground;

    switch (configuration) {
      case PriceConfigurationType.fixed:
        label = 'Precio fijo';
        background = const Color(0xFFE7F7EF);
        foreground = _success;
        break;
      case PriceConfigurationType.quantity:
        label = 'Por cantidad';
        background = const Color(0xFFEAF2FF);
        foreground = const Color(0xFF1D4ED8);
        break;
      case PriceConfigurationType.quote:
        label = 'Por cotizar';
        background = const Color(0xFFFFF3C4);
        foreground = const Color(0xFF8A6500);
        break;
      case PriceConfigurationType.unconfigured:
        label = 'Sin configurar';
        background = const Color(0xFFF0F2F5);
        foreground = _muted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildReadyBadge(ProductPriceDraft price) {
    final ready = price.isReady;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ready ? Icons.check_circle_outline : Icons.pending_outlined,
          size: 17,
          color: ready ? _success : _danger,
        ),
        const SizedBox(width: 5),
        Text(
          ready ? 'Lista' : 'Pendiente',
          style: TextStyle(
            color: ready ? _success : _danger,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _priceDetail(
    ProductPriceDraft price,
    SellablePriceCombination source,
  ) {
    final symbol = _currencySymbol(_selectedList.currencyCode);

    switch (price.configuration) {
      case PriceConfigurationType.fixed:
        return price.fixedPrice == null
            ? '—'
            : '$symbol ${price.fixedPrice!.toStringAsFixed(2)} '
                  'por ${source.presentationLabel}';
      case PriceConfigurationType.quantity:
        return price.ranges.isEmpty
            ? '—'
            : '${price.ranges.length} '
                  '${price.ranges.length == 1 ? 'rango' : 'rangos'}';
      case PriceConfigurationType.quote:
        return 'Se define en el pedido';
      case PriceConfigurationType.unconfigured:
        return '—';
    }
  }

  String _matrixPriceText(ProductPriceDraft price) {
    final symbol = _currencySymbol(_selectedList.currencyCode);

    switch (price.configuration) {
      case PriceConfigurationType.fixed:
        return price.fixedPrice == null
            ? 'Pendiente'
            : '$symbol ${price.fixedPrice!.toStringAsFixed(2)}';
      case PriceConfigurationType.quantity:
        return price.ranges.isEmpty
            ? 'Pendiente'
            : '${price.ranges.length} '
                  '${price.ranges.length == 1 ? 'rango' : 'rangos'}';
      case PriceConfigurationType.quote:
        return 'Por cotizar';
      case PriceConfigurationType.unconfigured:
        return 'Pendiente';
    }
  }

  Widget _buildBottomRule() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _canvas,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const rule = Text(
            'Un campo vacío queda pendiente. Un valor de 0.00 '
            'significa gratuito y requiere confirmación.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
          );

          final summary = Text(
            '$_readyCount de ${_activeListRows.length} combinaciones '
            'listas · $_pendingCount pendientes',
            style: TextStyle(
              color: _pendingCount == 0 ? _success : _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          );

          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [rule, const SizedBox(height: 10), summary],
            );
          }

          return Row(
            children: [
              Expanded(child: rule),
              const SizedBox(width: 18),
              summary,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final back = OutlinedButton(
            onPressed: widget.onBack,
            style: _outlinedStyle(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Anterior'),
            ),
          );
          const progress = Text(
            'Paso 5 de 7',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          );
          final next = FilledButton(
            onPressed: _continueToImages,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Text(
              'Siguiente: imágenes',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          );

          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                next,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: back),
                    const Expanded(child: progress),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              back,
              const Expanded(child: progress),
              next,
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 44),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_outlined, color: _muted, size: 34),
          SizedBox(height: 10),
          Text(
            'No hay combinaciones para estos filtros.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCombinationsState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      decoration: BoxDecoration(
        color: _canvas,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.sell_outlined, color: _muted, size: 38),
          SizedBox(height: 10),
          Text(
            'No hay combinaciones vendibles.',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 5),
          Text(
            'Regresa al paso 4 y asigna al menos una presentación '
            'de venta a una variante.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineNote(
    String message, {
    IconData icon = Icons.info_outline,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _muted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? prefixText,
    String? hintText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      hintText: hintText,
      helperText: helperText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
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
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _ink,
      side: const BorderSide(color: Color(0xFFBAC4D2)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  static String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return 'US\$';
      case 'EUR':
        return '€';
      case 'PEN':
      default:
        return 'S/';
    }
  }

  static String _formatDate(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(value.day)}/'
        '${twoDigits(value.month)}/${value.year}';
  }
}

Map<String, dynamic> step5PricingDraftToMap(PricingStep5Draft draft) {
  return {
    'lists': draft.lists.map((item) {
      return {
        'id': item.id,
        'name': item.name,
        'currency_code': item.currencyCode,
        'includes_igv': item.includesIgv,
        'valid_from': item.validFrom.toIso8601String(),
        'valid_until': item.validUntil?.toIso8601String(),
      };
    }).toList(),
    'prices': draft.prices.map((item) {
      return {
        'list_id': item.listId,
        'variant_id': item.variantId,
        'presentation_id': item.presentationId,
        'configuration': item.configuration.name,
        'fixed_price': item.fixedPrice,
        'ranges': item.ranges.map((range) {
          return {
            'from': range.from,
            'until': range.until,
            'price_per_presentation': range.pricePerPresentation,
          };
        }).toList(),
      };
    }).toList(),
    'sellable_combinations': draft.sellableCombinations.map((item) {
      return {
        'variant_id': item.variantId,
        'variant_label': item.variantLabel,
        'presentation_id': item.presentationId,
        'presentation_label': item.presentationLabel,
        'base_unit': item.baseUnit,
        'equivalent_to_base_unit': item.equivalentToBaseUnit,
        'minimum_order': item.minimumOrder,
        'purchase_increment': item.purchaseIncrement,
      };
    }).toList(),
  };
}

PricingStep5Draft? step5PricingDraftFromMap(Map<String, dynamic>? map) {
  if (map == null || map.isEmpty) {
    return null;
  }

  DateTime safeDate(Object? value, {DateTime? fallback}) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        fallback ??
        DateTime.now();
  }

  PriceConfigurationType configurationFrom(Object? value) {
    return PriceConfigurationType.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => PriceConfigurationType.unconfigured,
    );
  }

  final lists = (map['lists'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return PriceListDraft(
          id: item['id']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          currencyCode: item['currency_code']?.toString() ?? 'USD',
          includesIgv: item['includes_igv'] as bool? ?? true,
          validFrom: safeDate(item['valid_from']),
          validUntil: item['valid_until'] == null
              ? null
              : DateTime.tryParse(item['valid_until'].toString()),
        );
      })
      .where((item) => item.id.isNotEmpty)
      .toList();

  final prices = (map['prices'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw);
        final ranges = (item['ranges'] as List? ?? const [])
            .whereType<Map>()
            .map((rawRange) {
              final range = Map<String, dynamic>.from(rawRange);
              return QuantityPriceRange(
                from: (range['from'] as num?)?.toDouble() ?? 0,
                until: (range['until'] as num?)?.toDouble(),
                pricePerPresentation:
                    (range['price_per_presentation'] as num?)?.toDouble() ?? 0,
              );
            })
            .toList();
        return ProductPriceDraft(
          listId: item['list_id']?.toString() ?? '',
          variantId: item['variant_id']?.toString() ?? '',
          presentationId: item['presentation_id']?.toString() ?? '',
          configuration: configurationFrom(item['configuration']),
          fixedPrice: (item['fixed_price'] as num?)?.toDouble(),
          ranges: ranges,
        );
      })
      .where(
        (item) =>
            item.listId.isNotEmpty &&
            item.variantId.isNotEmpty &&
            item.presentationId.isNotEmpty,
      )
      .toList();

  final combinations = (map['sellable_combinations'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return SellablePriceCombination(
          variantId: item['variant_id']?.toString() ?? '',
          variantLabel: item['variant_label']?.toString() ?? '',
          presentationId: item['presentation_id']?.toString() ?? '',
          presentationLabel: item['presentation_label']?.toString() ?? '',
          baseUnit: item['base_unit']?.toString() ?? 'PZA',
          equivalentToBaseUnit:
              (item['equivalent_to_base_unit'] as num?)?.toDouble() ?? 1,
          minimumOrder: (item['minimum_order'] as num?)?.toDouble() ?? 1,
          purchaseIncrement:
              (item['purchase_increment'] as num?)?.toDouble() ?? 1,
        );
      })
      .where(
        (item) => item.variantId.isNotEmpty && item.presentationId.isNotEmpty,
      )
      .toList();

  if (lists.isEmpty && prices.isEmpty && combinations.isEmpty) {
    return null;
  }

  return PricingStep5Draft(
    lists: lists,
    prices: prices,
    sellableCombinations: combinations,
  );
}

String _plainNumber(double value) {
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
// 1) Convierte las asignaciones del paso 4 a SellablePriceCombination:
//
// List<SellablePriceCombination> _buildSellablePriceCombinations() {
//   return _salesPresentations.expand((presentation) {
//     return presentation.assignedVariantIds.map((variantId) {
//       final variant = _findVariantById(variantId);
//
//       return SellablePriceCombination(
//         variantId: variant.id,
//         variantLabel: variant.shortName,
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
// 2) Sustituye _buildIncompleteStep(4) en el PageView:
//
// Step5PricingPanel(
//   familyName: _familyName ?? 'Familia sin nombre',
//   totalVariantCount: _variants.length,
//   sellableCombinations: _buildSellablePriceCombinations(),
//   initialLists: _savedPriceLists,
//   initialPrices: _savedProductPrices,
//   onChanged: (draft) {
//     _savedPriceLists = draft.lists;
//     _savedProductPrices = draft.prices;
//   },
//   onBack: () {
//     _pageController.previousPage(
//       duration: const Duration(milliseconds: 250),
//       curve: Curves.easeOut,
//     );
//   },
//   onNext: (draft) {
//     _savedPriceLists = draft.lists;
//     _savedProductPrices = draft.prices;
//
//     _pageController.nextPage(
//       duration: const Duration(milliseconds: 250),
//       curve: Curves.easeOut,
//     );
//   },
// ),
//
// 3) En el paso 7:
//
// final pricing = PricingStep5Draft(
//   lists: _savedPriceLists,
//   prices: _savedProductPrices,
//   sellableCombinations: _buildSellablePriceCombinations(),
// );
//
// if (!pricing.canActivate(_savedPriceLists.first.id)) {
//   // Impedir activación definitiva; sí permitir guardar borrador.
// }
//
// "Sin configurar" no necesita guardarse en producto_precios. Es la ausencia
// de un registro para la combinación válida lista + variante + presentación.
