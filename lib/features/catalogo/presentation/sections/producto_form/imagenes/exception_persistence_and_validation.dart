part of '../imagenes_section.dart';

extension _Step6ExceptionPersistenceAndValidation on _Step6ImagesPanelState {
  void _resetInheritance(List<String> variantIds) {
    _update(() {
      _exceptions.removeWhere((item) => variantIds.contains(item.variantId));
      _removeOrphanVariantImages();
    });
    _emitChanged();
    _showMessage('Herencia restablecida.');
  }

  void _applyFamilyGalleryException(List<String> variantIds, String imageId) {
    _update(() {
      _exceptions.removeWhere((item) => variantIds.contains(item.variantId));
      _exceptions.addAll(
        variantIds.map(
          (variantId) => Step6VariantImageExceptionDraft(
            variantId: variantId,
            imageId: imageId,
            origin: Step6ExceptionOrigin.familyGallery,
          ),
        ),
      );
      _removeOrphanVariantImages();
    });
    _emitChanged();
  }

  Future<void> _applySpecificException(
    List<String> variantIds,
    Step6ImageCandidate candidate,
  ) async {
    final created = <Step6ProductImageDraft>[];
    _update(() {
      _exceptions.removeWhere((item) => variantIds.contains(item.variantId));
      for (final variantId in variantIds) {
        final image = Step6ProductImageDraft(
          id: _nextId('variant-image'),
          owner: Step6ImageOwner.variant,
          variantId: variantId,
          candidate: candidate,
          label: 'Principal específica',
          order: 0,
          isPrimary: true,
          processState: Step6ImageProcessState.processing,
          syncState: Step6ImageSyncState.pending,
          progress: 0.1,
        );
        created.add(image);
        _variantImages.add(image);
        _exceptions.add(
          Step6VariantImageExceptionDraft(
            variantId: variantId,
            imageId: image.id,
            origin: Step6ExceptionOrigin.variantSpecific,
          ),
        );
      }
      _removeOrphanVariantImages();
    });
    _emitChanged();
    await Future.wait(created.map((image) => _processDraft(image.id)));
  }

  void _removeOrphanVariantImages() {
    final usedIds = _exceptions
        .where((item) => item.origin == Step6ExceptionOrigin.variantSpecific)
        .map((item) => item.imageId)
        .toSet();
    _variantImages.removeWhere((image) => !usedIds.contains(image.id));
  }

  Future<void> _continueToReview() async {
    if (_hasProcessing) {
      _showMessage('Espera a que terminen de procesarse todas las imágenes.');
      return;
    }
    if (_hasFailed) {
      _showMessage(
        'Reintenta o elimina las imágenes con error antes de continuar.',
        error: true,
      );
      return;
    }

    if (_draft.familyPrimary == null) {
      final continueAsDraft = await _confirm(
        title: 'Producto sin imagen principal',
        message:
            'Puedes continuar a la revisión y guardar el producto como '
            'borrador, pero no podrás activarlo hasta agregar una imagen '
            'principal.',
        confirmLabel: 'Continuar como borrador',
      );
      if (!continueAsDraft) {
        return;
      }
    }
    widget.onNext(_draft);
  }

  String? _candidateValidationError(Step6ImageCandidate candidate) {
    final mime = candidate.mimeType.trim().toLowerCase();
    final extension = candidate.fileName.split('.').last.trim().toLowerCase();
    final allowedMime = {'image/jpeg', 'image/jpg', 'image/png', 'image/webp'};
    final allowedExtension = {'jpg', 'jpeg', 'png', 'webp'};

    if (!allowedMime.contains(mime) && !allowedExtension.contains(extension)) {
      return 'Formato no permitido. Usa JPG, PNG o WebP.';
    }
    if (candidate.sizeBytes <= 0) {
      return 'No se pudo determinar el tamaño del archivo.';
    }
    if (candidate.sizeBytes > widget.maxImageBytes) {
      final maxMb = widget.maxImageBytes / (1024 * 1024);
      return 'La imagen supera el máximo de ${_plainNumber(maxMb)} MB.';
    }
    if ((candidate.width != null && candidate.width! <= 0) ||
        (candidate.height != null && candidate.height! <= 0)) {
      return 'La resolución de la imagen no es válida.';
    }
    return null;
  }

  bool _isBelowRecommendation(Step6ImageCandidate candidate) {
    final width = candidate.width;
    final height = candidate.height;
    if (width == null || height == null) {
      return false;
    }
    return width < widget.recommendedMinWidth ||
        height < widget.recommendedMinHeight;
  }

  String _defaultLabel(int index) {
    const labels = ['Principal', 'Vista lateral', 'Detalle', 'Empaque'];
    return index < labels.length ? labels[index] : 'Detalle ${index + 1}';
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: destructive ? _danger : _primary,
                foregroundColor: destructive ? Colors.white : Colors.black,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? _danger : _ink,
        ),
      );
  }
}
