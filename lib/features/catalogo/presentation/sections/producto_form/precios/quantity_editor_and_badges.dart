part of '../precios_section.dart';

extension _Step5QuantityEditorAndBadges on _Step5PricingPanelState {
  Widget _buildQuantityEditor(SellablePriceCombination source) {
    final symbol = _currencySymbol(_selectedList.currencyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Los rangos se expresan en cantidades de '
          '${source.presentationLabel}. El rango alcanzado aplica a '
          'toda la cantidad pedida.',
          style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          _editableRanges.length,
          (index) =>
              _buildQuantityRangeRow(index, symbol, source.presentationLabel),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addQuantityRange,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar rango'),
            style: _outlinedStyle(),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'El primer rango debe iniciar en el pedido mínimo; no se '
          'permiten vacíos, repeticiones, cruces ni superposiciones. '
          'El último debe quedar sin límite.',
          style: TextStyle(color: _muted, fontSize: 11, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildQuantityRangeRow(int index, String symbol, String presentation) {
    final range = _editableRanges[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rango ${index + 1}',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _removeQuantityRange(index);
                },
                tooltip: 'Eliminar rango',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline,
                  color: _danger,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: range.fromController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Desde'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: range.untilController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Hasta', hintText: 'Sin límite'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: range.priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
              'Precio por $presentation',
              prefixText: '$symbol ',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationBadge(PriceConfigurationType configuration) {
    late final String label;
    late final Color background;
    late final Color foreground;

    switch (configuration) {
      case PriceConfigurationType.fixed:
        label = 'Precio fijo';
        background = const Color(0xFFE7F7EF);
        foreground = _success;
        break;
      case PriceConfigurationType.quantity:
        label = 'Por cantidad';
        background = const Color(0xFFEAF2FF);
        foreground = const Color(0xFF1D4ED8);
        break;
      case PriceConfigurationType.quote:
        label = 'Por cotizar';
        background = const Color(0xFFFFF3C4);
        foreground = const Color(0xFF8A6500);
        break;
      case PriceConfigurationType.unconfigured:
        label = 'Sin configurar';
        background = const Color(0xFFF0F2F5);
        foreground = _muted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildReadyBadge(ProductPriceDraft price) {
    final ready = price.isReady;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ready ? Icons.check_circle_outline : Icons.pending_outlined,
          size: 17,
          color: ready ? _success : _danger,
        ),
        const SizedBox(width: 5),
        Text(
          ready ? 'Lista' : 'Pendiente',
          style: TextStyle(
            color: ready ? _success : _danger,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
