import 'package:flutter/material.dart';

import '../../models/producto_form/precios_draft.dart';

part 'precios/bulk_and_price_lists.dart';
part 'precios/footer_and_formatting.dart';
part 'precios/header_and_toolbar.dart';
part 'precios/matrix_cells.dart';
part 'precios/navigation_and_messages.dart';
part 'precios/price_editing_actions.dart';
part 'precios/price_editor.dart';
part 'precios/price_state_sync.dart';
part 'precios/price_table_and_matrix.dart';
part 'precios/quantity_editor_and_badges.dart';

// ============================================================================
// PASO 5 · PRECIOS
//
// Widget autocontenido para integrar en el PageView del registro de productos.
// Las filas NO se crean manualmente: se generan desde cada combinación válida
// variante + presentación recibida desde el paso 4.
// ============================================================================

enum PriceScreenView { table, matrix }

enum PriceFilter { all, pending, quote }

const Color _primary = Color(0xFFFFC500);
const Color _ink = Color(0xFF20242B);
const Color _muted = Color(0xFF667085);
const Color _border = Color(0xFFD5DDE8);
const Color _canvas = Color(0xFFF8FAFC);
const Color _success = Color(0xFF16794A);
const Color _danger = Color(0xFFC62828);

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
  void _update(VoidCallback callback) => setState(callback);

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

  int get _totalPendingCount => _prices.where((item) => !item.isReady).length;

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

String _currencySymbol(String code) {
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

String _formatDate(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');

  return '${twoDigits(value.day)}/'
      '${twoDigits(value.month)}/${value.year}';
}
