part of '../venta_logistica_section.dart';

extension _Step4PackageRelations on _Step4SalesLogisticsContentPanelState {
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
        _update(() {
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

    _update(() {
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

    _update(() {
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
}
