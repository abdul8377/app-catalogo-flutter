part of '../precios_section.dart';

extension _Step5FooterAndFormatting on _Step5PricingPanelState {
  String _priceDetail(
    ProductPriceDraft price,
    SellablePriceCombination source,
  ) {
    final symbol = _currencySymbol(_selectedList.currencyCode);

    switch (price.configuration) {
      case PriceConfigurationType.fixed:
        return price.fixedPrice == null
            ? '—'
            : '$symbol ${price.fixedPrice!.toStringAsFixed(2)} '
                  'por ${source.presentationLabel}';
      case PriceConfigurationType.quantity:
        return price.ranges.isEmpty
            ? '—'
            : '${price.ranges.length} '
                  '${price.ranges.length == 1 ? 'rango' : 'rangos'}';
      case PriceConfigurationType.quote:
        return 'Se define en el pedido';
      case PriceConfigurationType.unconfigured:
        return '—';
    }
  }

  String _matrixPriceText(ProductPriceDraft price) {
    final symbol = _currencySymbol(_selectedList.currencyCode);

    switch (price.configuration) {
      case PriceConfigurationType.fixed:
        return price.fixedPrice == null
            ? 'Pendiente'
            : '$symbol ${price.fixedPrice!.toStringAsFixed(2)}';
      case PriceConfigurationType.quantity:
        return price.ranges.isEmpty
            ? 'Pendiente'
            : '${price.ranges.length} '
                  '${price.ranges.length == 1 ? 'rango' : 'rangos'}';
      case PriceConfigurationType.quote:
        return 'Por cotizar';
      case PriceConfigurationType.unconfigured:
        return 'Pendiente';
    }
  }

  Widget _buildBottomRule() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _canvas,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const rule = Text(
            'Un campo vacío queda pendiente. Un valor de 0.00 '
            'significa gratuito y requiere confirmación.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
          );

          final summary = Text(
            '$_readyCount de ${_activeListRows.length} combinaciones '
            'listas · $_pendingCount pendientes',
            style: TextStyle(
              color: _pendingCount == 0 ? _success : _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          );

          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [rule, const SizedBox(height: 10), summary],
            );
          }

          return Row(
            children: [
              Expanded(child: rule),
              const SizedBox(width: 18),
              summary,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      key: const Key('precios_footer_safe_area'),
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final back = OutlinedButton(
              onPressed: widget.onBack,
              style: _outlinedStyle(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Anterior'),
              ),
            );
            const progress = Text(
              'Paso 5 de 7',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12),
            );
            final next = FilledButton(
              onPressed: _continueToImages,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Siguiente: imágenes',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            );

            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  next,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: back),
                      const Expanded(child: progress),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                back,
                const Expanded(child: progress),
                next,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 44),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_outlined, color: _muted, size: 34),
          SizedBox(height: 10),
          Text(
            'No hay combinaciones para estos filtros.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCombinationsState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      decoration: BoxDecoration(
        color: _canvas,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.sell_outlined, color: _muted, size: 38),
          SizedBox(height: 10),
          Text(
            'No hay combinaciones vendibles.',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 5),
          Text(
            'Regresa al paso 4 y asigna al menos una presentación '
            'de venta a una variante.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineNote(
    String message, {
    IconData icon = Icons.info_outline,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _muted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? prefixText,
    String? hintText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      hintText: hintText,
      helperText: helperText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _ink,
      side: const BorderSide(color: Color(0xFFBAC4D2)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
