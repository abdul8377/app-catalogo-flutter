part of '../venta_logistica_section.dart';

extension _Step4ContentEditor on _Step4SalesLogisticsContentPanelState {
  Widget _buildContentEditor() {
    final editing = _editingContentIndex != null;
    final relatedLabel = _catalogVariantLabel(_relatedCatalogVariantId);

    return _panel(
      background: _canvas,
      child: Form(
        key: _contentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Editar componente' : 'Agregar componente',
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _labeledField(
              label: 'Nombre del componente *',
              child: TextFormField(
                controller: _componentNameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(hint: 'Ej. Broca 3 mm'),
                validator: _requiredText,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final quantity = _labeledField(
                  label: 'Cantidad *',
                  child: TextFormField(
                    controller: _componentQuantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(),
                    validator: _positiveNumberValidator,
                  ),
                );
                final unit = _labeledField(
                  label: 'Unidad *',
                  child: DropdownButtonFormField<String>(
                    value: _componentUnit,
                    isExpanded: true,
                    decoration: _inputDecoration(),
                    items: widget.baseUnits.map((item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _update(() {
                        _componentUnit = value;
                      });
                    },
                  ),
                );

                if (constraints.maxWidth < 420) {
                  return Column(
                    children: [quantity, const SizedBox(height: 14), unit],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: quantity),
                    const SizedBox(width: 12),
                    Expanded(child: unit),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: 'Producto o variante relacionada (opcional)',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _pickCatalogVariant,
                child: InputDecorator(
                  decoration: _inputDecoration(suffixIcon: Icons.search),
                  child: Text(
                    relatedLabel ?? 'Buscar en el catálogo',
                    style: TextStyle(
                      color: relatedLabel == null ? _muted : _ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'El nombre puede guardarse aunque el componente no exista en el catálogo.',
              style: TextStyle(color: _muted, fontSize: 10, height: 1.35),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final cancelButton = OutlinedButton(
                  onPressed: _startNewContentItem,
                  style: _outlinedButtonStyle(),
                  child: const Text('Cancelar'),
                );
                final saveButton = FilledButton(
                  onPressed: _saveContentItem,
                  style: _primaryButtonStyle(),
                  child: Text(
                    editing ? 'Guardar cambios' : 'Agregar componente',
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
  // COMPONENTES COMPARTIDOS
  // ==========================================================================
}
