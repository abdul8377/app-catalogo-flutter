part of '../venta_logistica_section.dart';

extension _Step4PresentationEditor on _Step4SalesLogisticsContentPanelState {
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
                  _update(() {
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
                  _update(() {
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
                _update(() {
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
                _update(() {
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
                _update(() {
                  _presentationVariantIds = result;
                  _presentationForAllVariants =
                      result.length == _allVariantIds.length &&
                      result.containsAll(_allVariantIds);
                });
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('reglas_presentacion_por_variante'),
              onPressed: _presentationVariantIds.isEmpty
                  ? null
                  : _editPresentationVariantRules,
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                'Excepciones por variante '
                '(${_presentationVariantRules.length})',
              ),
              style: _outlinedButtonStyle(),
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
}
