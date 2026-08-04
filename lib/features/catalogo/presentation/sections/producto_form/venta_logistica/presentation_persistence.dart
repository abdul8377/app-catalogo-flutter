part of '../venta_logistica_section.dart';

extension _Step4PresentationPersistence
    on _Step4SalesLogisticsContentPanelState {
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
      variantRules: {
        for (final entry in _presentationVariantRules.entries)
          if (assignedIds.contains(entry.key)) entry.key: entry.value,
      },
      linkedLogisticsPackageId: linkedPackageId,
    );

    _update(() {
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
      _update(() {});
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

    _update(() {
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
}
