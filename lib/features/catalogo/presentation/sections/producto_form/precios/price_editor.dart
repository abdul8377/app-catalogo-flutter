part of '../precios_section.dart';

extension _Step5PriceEditor on _Step5PricingPanelState {
  Widget _buildEditorPanel() {
    final price = _editorPrice!;
    final source = _editorSource!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _canvas,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Configurar precio',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _update(_closeEditor);
                },
                tooltip: 'Cerrar editor',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReadOnlyLine('Variante', source.variantLabel),
                const SizedBox(height: 9),
                _buildReadOnlyLine('Presentación', source.presentationLabel),
                const SizedBox(height: 9),
                _buildReadOnlyLine(
                  'Lista',
                  '${_selectedList.name} · '
                      '${_currencySymbol(_selectedList.currencyCode)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'Configuración',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildConfigurationChoice(
                PriceConfigurationType.fixed,
                'Precio fijo',
              ),
              _buildConfigurationChoice(
                PriceConfigurationType.quantity,
                'Por cantidad',
              ),
              _buildConfigurationChoice(
                PriceConfigurationType.quote,
                'Por cotizar',
              ),
              _buildConfigurationChoice(
                PriceConfigurationType.unconfigured,
                'Sin configurar',
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_editorConfiguration == PriceConfigurationType.fixed)
            _buildFixedEditor(source),
          if (_editorConfiguration == PriceConfigurationType.quantity)
            _buildQuantityEditor(source),
          if (_editorConfiguration == PriceConfigurationType.quote)
            _buildInlineNote(
              'El producto podrá agregarse al pedido, pero su precio '
              'deberá completarse posteriormente. El total general '
              'se mostrará como “Pendiente de cotización”, nunca como cero.',
              icon: Icons.request_quote_outlined,
            ),
          if (_editorConfiguration == PriceConfigurationType.unconfigured)
            _buildInlineNote(
              'Esta combinación quedará pendiente. Puede guardarse en '
              'el borrador, pero impedirá activar el producto en el paso 7.',
              icon: Icons.pending_actions_outlined,
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _update(_closeEditor);
                  },
                  style: _outlinedStyle(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saveEditor,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Text(
                    price.configuration == PriceConfigurationType.unconfigured
                        ? 'Guardar configuración'
                        : 'Guardar cambios',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationChoice(PriceConfigurationType value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _editorConfiguration == value,
      onSelected: (_) {
        _changeEditorConfiguration(value);
      },
      selectedColor: _primary.withOpacity(0.25),
      checkmarkColor: _ink,
      side: const BorderSide(color: _border),
      labelStyle: const TextStyle(
        color: _ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildFixedEditor(SellablePriceCombination source) {
    final parsedPrice = _parseDecimal(_fixedPriceController.text);

    final reference = parsedPrice == null || source.equivalentToBaseUnit <= 0
        ? null
        : parsedPrice / source.equivalentToBaseUnit;

    final symbol = _currencySymbol(_selectedList.currencyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _fixedPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) {
            _update(() {});
          },
          decoration: _inputDecoration(
            'Precio por ${source.presentationLabel}',
            prefixText: '$symbol ',
            helperText: 'Vacío = pendiente. 0.00 = gratuito con confirmación.',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            reference == null
                ? 'Referencia por unidad base: —'
                : 'Referencia: $symbol '
                      '${reference.toStringAsFixed(3)} por '
                      '${source.baseUnit}',
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
