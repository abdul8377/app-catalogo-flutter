part of '../venta_logistica_section.dart';

extension _Step4PackageEditor on _Step4SalesLogisticsContentPanelState {
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
                    onChanged: (_) => _update(() {}),
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

                  _update(() {
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
                _update(() {
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
                _update(() {
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
            _update(() {
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
                _update(() {
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
}
