part of '../imagenes_section.dart';

extension _Step6StateReconciliation on _Step6ImagesPanelState {
  void _refreshVariantList() {
    if (mounted) {
      _update(() {});
    }
  }

  void _toggleMultiSelect() {
    _update(() {
      _multiSelect = !_multiSelect;
      _selectedVariantIds.clear();
    });
  }

  List<Step6ProductImageDraft> _normalizeFamilyImages(
    List<Step6ProductImageDraft> source,
  ) {
    final ordered = [...source]..sort((a, b) => a.order.compareTo(b.order));
    var primaryFound = false;
    return [
      for (var index = 0; index < ordered.length; index++)
        ordered[index].copyWith(
          order: index,
          isPrimary: ordered[index].isPrimary && !primaryFound
              ? (primaryFound = true)
              : false,
        ),
    ];
  }

  void _reconcileState() {
    final variantIds = widget.variants.map((item) => item.id).toSet();
    final familyIds = _familyImages.map((item) => item.id).toSet();
    final variantImageById = {
      for (final image in _variantImages) image.id: image,
    };

    _variantImages.removeWhere(
      (image) => !variantIds.contains(image.variantId),
    );
    _exceptions.removeWhere((item) {
      if (!variantIds.contains(item.variantId)) {
        return true;
      }
      if (item.origin == Step6ExceptionOrigin.familyGallery) {
        return !familyIds.contains(item.imageId);
      }
      final image = variantImageById[item.imageId];
      return image == null || image.variantId != item.variantId;
    });
    _removeOrphanVariantImages();
  }

  void _emitChanged() {
    widget.onChanged?.call(_draft);
  }

  String _nextId(String prefix) => '$prefix-${_idSequence++}';
}
