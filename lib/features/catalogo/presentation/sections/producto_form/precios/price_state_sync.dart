part of '../precios_section.dart';

extension _Step5PriceStateSync on _Step5PricingPanelState {
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

    _update(() {
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

    _update(() {
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

    _update(() {
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
}
