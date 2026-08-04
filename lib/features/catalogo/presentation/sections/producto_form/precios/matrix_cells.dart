part of '../precios_section.dart';

extension _Step5MatrixCells on _Step5PricingPanelState {
  Widget _buildMatrixHeaderCell(String label) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixVariantCell(String label) {
    return SizedBox(
      height: 88,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixPriceCell({
    required String variantId,
    required String presentationId,
  }) {
    final source = _findSource(variantId, presentationId);
    final price = _findActivePrice(variantId, presentationId);

    if (source == null || price == null) {
      return Container(
        height: 88,
        color: const Color(0xFFF4F5F7),
        alignment: Alignment.center,
        child: const Text(
          'No aplica',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final selected = _selectedPriceKeys.contains(price.key);
    final hiddenByStateFilter =
        (_filter == PriceFilter.pending && price.isReady) ||
        (_filter == PriceFilter.quote &&
            price.configuration != PriceConfigurationType.quote);

    if (hiddenByStateFilter) {
      return Container(
        height: 88,
        color: const Color(0xFFF8F9FA),
        alignment: Alignment.center,
        child: const Text('—', style: TextStyle(color: _muted, fontSize: 12)),
      );
    }

    return Material(
      color: selected ? _primary.withOpacity(0.14) : Colors.white,
      child: InkWell(
        onTap: () {
          _openEditor(price);
        },
        child: SizedBox(
          height: 88,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: selected,
                  activeColor: _ink,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) {
                    _togglePriceSelection(price, value ?? false);
                  },
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _matrixPriceText(price),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              price.configuration ==
                                  PriceConfigurationType.unconfigured
                              ? _danger
                              : _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        price.isReady ? 'Lista' : 'Configurar',
                        style: TextStyle(
                          color: price.isReady ? _success : _muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
