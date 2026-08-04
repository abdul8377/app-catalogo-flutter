part of '../imagenes_section.dart';

extension _Step6VariantRow on _Step6ImagesPanelState {
  Widget _buildVariantRow(Step6VariantOption variant) {
    final exception = _exceptionFor(variant.id);
    final selected = _multiSelect
        ? _selectedVariantIds.contains(variant.id)
        : _selectedVariantId == variant.id;
    final effectiveImage = _effectivePrimaryFor(variant.id);

    return InkWell(
      onTap: () {
        _update(() {
          if (_multiSelect) {
            if (!_selectedVariantIds.add(variant.id)) {
              _selectedVariantIds.remove(variant.id);
            }
          } else {
            _selectedVariantId = variant.id;
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _selection : _border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 5,
              height: 76,
              decoration: BoxDecoration(
                color: selected ? _selection : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: effectiveImage == null
                    ? const ColoredBox(
                        color: _soft,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: _muted,
                        ),
                      )
                    : _buildImagePreview(effectiveImage),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (variant.sku != null &&
                        variant.sku!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'SKU: ${variant.sku}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          exception == null
                              ? Icons.account_tree_outlined
                              : Icons.photo_camera_back_outlined,
                          color: exception == null ? _muted : _selection,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            exception == null
                                ? 'Hereda la imagen principal'
                                : 'Principal reemplazada',
                            style: TextStyle(
                              color: exception == null ? _muted : _selection,
                              fontSize: 14,
                              fontWeight: exception == null
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_multiSelect)
              Checkbox(
                value: selected,
                onChanged: (_) {
                  _update(() {
                    if (!_selectedVariantIds.add(variant.id)) {
                      _selectedVariantIds.remove(variant.id);
                    }
                  });
                },
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? _selection : _muted,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
