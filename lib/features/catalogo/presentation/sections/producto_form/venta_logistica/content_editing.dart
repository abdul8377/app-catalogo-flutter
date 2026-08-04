part of '../venta_logistica_section.dart';

extension _Step4ContentEditing on _Step4SalesLogisticsContentPanelState {
  void _startNewContentItem({bool rebuild = true}) {
    _editingContentIndex = null;
    _componentNameController.clear();
    _componentQuantityController.text = '1';
    _componentUnit = widget.baseUnits.contains('PZA')
        ? 'PZA'
        : widget.baseUnits.first;
    _relatedCatalogVariantId = null;

    if (rebuild && mounted) {
      _update(() {});
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
      _update(() {});
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

    _update(() {
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

    _update(() {
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

    _update(() {
      _contentItems.removeAt(globalIndex);
      _startNewContentItem(rebuild: false);
    });
    _emitChanged();
  }
}
