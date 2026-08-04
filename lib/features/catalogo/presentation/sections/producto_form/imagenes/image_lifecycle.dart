part of '../imagenes_section.dart';

extension _Step6ImageLifecycle on _Step6ImagesPanelState {
  Future<void> _addFamilyImages() async {
    final candidates = await _pick(
      const Step6ImagePickRequest(allowMultiple: true, forFamilyGallery: true),
    );
    if (candidates.isEmpty) {
      return;
    }

    final validCandidates = <Step6ImageCandidate>[];
    final rejected = <String>[];
    for (final candidate in candidates) {
      final error = _candidateValidationError(candidate);
      if (error == null) {
        validCandidates.add(candidate);
      } else {
        rejected.add('${candidate.fileName}: $error');
      }
    }

    if (rejected.isNotEmpty) {
      _showMessage(rejected.join('\n'), error: true);
    }
    if (validCandidates.isEmpty) {
      return;
    }

    final firstOrder = _familyImages.length;
    final drafts = <Step6ProductImageDraft>[];
    for (var index = 0; index < validCandidates.length; index++) {
      final candidate = validCandidates[index];
      drafts.add(
        Step6ProductImageDraft(
          id: _nextId('family-image'),
          owner: Step6ImageOwner.family,
          familyId: widget.familyId,
          candidate: candidate,
          label: _defaultLabel(firstOrder + index),
          order: firstOrder + index,
          isPrimary: false,
          processState: Step6ImageProcessState.processing,
          syncState: Step6ImageSyncState.pending,
          progress: 0.1,
        ),
      );
    }

    _update(() => _familyImages.addAll(drafts));
    _emitChanged();
    await Future.wait(drafts.map((image) => _processDraft(image.id)));
  }

  Future<List<Step6ImageCandidate>> _pick(Step6ImagePickRequest request) async {
    final picker = widget.pickImages;
    if (picker == null) {
      _showMessage(
        'Conecta pickImages con image_picker o file_picker para seleccionar '
        'archivos.',
      );
      return [];
    }

    try {
      return await picker(request);
    } catch (error) {
      _showMessage(
        'No se pudieron seleccionar las imágenes: $error',
        error: true,
      );
      return [];
    }
  }

  Future<void> _processDraft(String imageId) async {
    final current = _findImage(imageId);
    if (current == null) {
      return;
    }

    try {
      _replaceImageInState(
        current.copyWith(
          processState: Step6ImageProcessState.processing,
          progress: 0.35,
          clearError: true,
        ),
      );
      final processed = widget.processImage == null
          ? current.candidate
          : await widget.processImage!(current.candidate);
      final error = _candidateValidationError(processed);
      if (error != null) {
        throw StateError(error);
      }
      final latest = _findImage(imageId);
      if (latest == null) {
        return;
      }
      _replaceImageInState(
        latest.copyWith(
          candidate: processed,
          processState: Step6ImageProcessState.ready,
          syncState: Step6ImageSyncState.pending,
          progress: 1,
          clearError: true,
        ),
      );
      _ensureFamilyPrimary();
    } catch (error) {
      final latest = _findImage(imageId);
      if (latest != null) {
        _replaceImageInState(
          latest.copyWith(
            processState: Step6ImageProcessState.failed,
            progress: 0,
            errorMessage: error.toString(),
          ),
        );
      }
    }

    if (mounted) {
      _update(() {});
      _emitChanged();
    }
  }

  Future<void> _retryImage(Step6ProductImageDraft image) async {
    _replaceImageInState(
      image.copyWith(
        processState: Step6ImageProcessState.processing,
        progress: 0.1,
        clearError: true,
      ),
    );
    _update(() {});
    await _processDraft(image.id);
  }

  void _ensureFamilyPrimary() {
    final ready = _familyImages.where((image) => image.isReady).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    if (ready.isEmpty || ready.any((image) => image.isPrimary)) {
      return;
    }
    final id = ready.first.id;
    _familyImages = [
      for (final image in _familyImages)
        image.copyWith(isPrimary: image.id == id),
    ];
  }

  void _replaceImageInState(Step6ProductImageDraft updated) {
    final list = updated.owner == Step6ImageOwner.family
        ? _familyImages
        : _variantImages;
    final index = list.indexWhere((item) => item.id == updated.id);
    if (index >= 0) {
      list[index] = updated;
    }
  }

  Step6ProductImageDraft? _findImage(String imageId) {
    for (final image in [..._familyImages, ..._variantImages]) {
      if (image.id == imageId) {
        return image;
      }
    }
    return null;
  }

  Step6VariantImageExceptionDraft? _exceptionFor(String variantId) {
    for (final item in _exceptions) {
      if (item.variantId == variantId) {
        return item;
      }
    }
    return null;
  }

  Step6ProductImageDraft? _effectivePrimaryFor(String variantId) {
    final exception = _exceptionFor(variantId);
    if (exception != null) {
      return _findImage(exception.imageId);
    }
    return _draft.familyPrimary;
  }

  void _moveFamilyImage(String draggedId, String targetId) {
    final from = _familyImages.indexWhere((item) => item.id == draggedId);
    final target = _familyImages.indexWhere((item) => item.id == targetId);
    if (from < 0 || target < 0 || from == target) {
      return;
    }

    _update(() {
      final moved = _familyImages.removeAt(from);
      final insertion = target > _familyImages.length
          ? _familyImages.length
          : target;
      _familyImages.insert(insertion, moved);
      _familyImages = [
        for (var index = 0; index < _familyImages.length; index++)
          _familyImages[index].copyWith(order: index),
      ];
    });
    _emitChanged();
  }
}
