part of '../precios_section.dart';

extension _Step5PriceEditingActions on _Step5PricingPanelState {
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

    _update(_closeEditor);
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

    _update(() {
      _editableRanges.add(_EditableQuantityRange(from: from));
    });
  }

  void _removeQuantityRange(int index) {
    late final _EditableQuantityRange removed;
    _update(() {
      removed = _editableRanges.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.dispose();
    });
  }

  void _togglePriceSelection(ProductPriceDraft price, bool selected) {
    _update(() {
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

    _update(() {
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
}
