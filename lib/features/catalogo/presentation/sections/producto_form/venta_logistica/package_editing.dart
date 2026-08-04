part of '../venta_logistica_section.dart';

extension _Step4PackageEditing on _Step4SalesLogisticsContentPanelState {
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
      _update(() {});
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
      _update(() {});
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

    _update(() {
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

    _update(() {
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
}
