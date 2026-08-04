part of '../imagenes_section.dart';

extension _Step6ImageActions on _Step6ImagesPanelState {
  Future<void> _handleImageAction(
    _Step6ImageAction action,
    Step6ProductImageDraft image,
  ) async {
    switch (action) {
      case _Step6ImageAction.view:
        await _showFullImage(image);
        break;
      case _Step6ImageAction.makePrimary:
        _makeFamilyPrimary(image.id);
        break;
      case _Step6ImageAction.editLabel:
        await _editImageLabel(image);
        break;
      case _Step6ImageAction.crop:
        await _cropFamilyImage(image);
        break;
      case _Step6ImageAction.replace:
        await _replaceFamilyImage(image);
        break;
      case _Step6ImageAction.delete:
        await _deleteImage(image);
        break;
    }
  }

  void _makeFamilyPrimary(String imageId) {
    _update(() {
      _familyImages = [
        for (final image in _familyImages)
          image.copyWith(isPrimary: image.id == imageId),
      ];
    });
    _emitChanged();
  }

  Future<void> _showFullImage(Step6ProductImageDraft image) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 10, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          image.label,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Cerrar',
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ColoredBox(
                    color: _soft,
                    child: Center(
                      child: InteractiveViewer(
                        minScale: 0.7,
                        maxScale: 4,
                        child: _buildImagePreview(image),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editImageLabel(Step6ProductImageDraft image) async {
    final controller = TextEditingController(text: image.label);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar etiqueta'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 60,
            style: const TextStyle(fontSize: 14),
            decoration: _inputDecoration('Etiqueta de la imagen'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (result == null) {
      return;
    }
    _replaceImageInState(image.copyWith(label: result));
    _update(() {});
    _emitChanged();
  }

  Future<void> _cropFamilyImage(Step6ProductImageDraft image) async {
    final cropper = widget.cropImage;
    if (cropper == null) {
      _showMessage(
        'Conecta cropImage con el recortador elegido para mantener la '
        'proporción ${_ratioLabel(widget.cropAspectRatio)}.',
      );
      return;
    }

    try {
      final cropped = await cropper(image.candidate);
      if (cropped == null) {
        return;
      }
      final error = _candidateValidationError(cropped);
      if (error != null) {
        _showMessage(error, error: true);
        return;
      }
      _replaceImageInState(
        image.copyWith(
          candidate: cropped,
          processState: Step6ImageProcessState.processing,
          syncState: Step6ImageSyncState.pending,
          progress: 0.1,
        ),
      );
      _update(() {});
      await _processDraft(image.id);
    } catch (error) {
      _showMessage('No se pudo recortar la imagen: $error', error: true);
    }
  }

  Future<void> _replaceFamilyImage(Step6ProductImageDraft image) async {
    final candidates = await _pick(
      const Step6ImagePickRequest(allowMultiple: false, forFamilyGallery: true),
    );
    if (candidates.isEmpty) {
      return;
    }
    final candidate = candidates.first;
    final error = _candidateValidationError(candidate);
    if (error != null) {
      _showMessage(error, error: true);
      return;
    }

    _replaceImageInState(
      image.copyWith(
        candidate: candidate,
        processState: Step6ImageProcessState.processing,
        syncState: Step6ImageSyncState.pending,
        progress: 0.1,
        clearError: true,
      ),
    );
    _update(() {});
    _emitChanged();
    await _processDraft(image.id);
  }

  Future<void> _deleteImage(Step6ProductImageDraft image) async {
    final assignedCount = _exceptions
        .where((item) => item.imageId == image.id)
        .length;
    final parts = <String>[];
    if (image.isPrimary) {
      parts.add(
        'Es la imagen principal. Si quedan otras imágenes, la primera '
        'disponible pasará a ser principal.',
      );
    }
    if (assignedCount > 0) {
      parts.add(
        'Está asignada a $assignedCount '
        '${assignedCount == 1 ? 'variante' : 'variantes'}. '
        'Esas variantes restablecerán la herencia.',
      );
    }
    parts.add('Esta acción quitará la imagen del borrador.');

    final confirmed = await _confirm(
      title: 'Eliminar imagen',
      message: parts.join('\n\n'),
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    _update(() {
      if (image.owner == Step6ImageOwner.family) {
        _familyImages.removeWhere((item) => item.id == image.id);
        _familyImages = [
          for (var index = 0; index < _familyImages.length; index++)
            _familyImages[index].copyWith(order: index),
        ];
      } else {
        _variantImages.removeWhere((item) => item.id == image.id);
      }
      _exceptions.removeWhere((item) => item.imageId == image.id);
      _ensureFamilyPrimary();
    });
    _emitChanged();
  }
}
