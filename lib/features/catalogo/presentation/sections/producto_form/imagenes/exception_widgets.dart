part of '../imagenes_section.dart';

extension _Step6ExceptionWidgets on _Step6ImagesPanelState {
  Widget _exceptionRadio({
    required _Step6ExceptionChoice value,
    required _Step6ExceptionChoice groupValue,
    required String title,
    required String subtitle,
    required ValueChanged<_Step6ExceptionChoice> onChanged,
    bool enabled = true,
  }) {
    return RadioListTile<_Step6ExceptionChoice>(
      value: value,
      groupValue: groupValue,
      onChanged: enabled
          ? (value) {
              if (value != null) {
                onChanged(value);
              }
            }
          : null,
      contentPadding: EdgeInsets.zero,
      activeColor: _selection,
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? _ink : _muted,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: _muted, fontSize: 14, height: 1.35),
      ),
    );
  }

  Widget _buildFamilyImageChoices({
    required String? selectedId,
    required ValueChanged<String> onSelected,
  }) {
    final images =
        _familyImages
            .where((image) => image.isReady && !image.isPrimary)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final image in images)
          InkWell(
            onTap: () => onSelected(image.id),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selectedId == image.id ? _selection : _border,
                  width: selectedId == image.id ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 94,
                    height: 72,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: _buildImagePreview(image),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        selectedId == image.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selectedId == image.id ? _selection : _muted,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          image.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _ink, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExceptionPreview({
    required Step6ProductImageDraft? preview,
    required Step6ImageCandidate? candidate,
    required _Step6ExceptionChoice choice,
  }) {
    return Container(
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: candidate?.previewBytes != null
          ? Image.memory(candidate!.previewBytes!, fit: BoxFit.contain)
          : preview != null
          ? _buildImagePreview(preview)
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  choice == _Step6ExceptionChoice.inherit
                      ? 'La familia todavía no tiene una imagen principal.'
                      : 'Selecciona una imagen para ver la vista previa.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, fontSize: 14),
                ),
              ),
            ),
    );
  }
}
