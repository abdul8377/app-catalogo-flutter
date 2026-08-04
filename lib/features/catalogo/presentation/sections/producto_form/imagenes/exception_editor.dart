part of '../imagenes_section.dart';

extension _Step6ExceptionEditor on _Step6ImagesPanelState {
  Future<void> _openExceptionEditor(List<String> variantIds) async {
    if (variantIds.isEmpty) {
      return;
    }

    final existing = variantIds
        .map(_exceptionFor)
        .whereType<Step6VariantImageExceptionDraft>()
        .toList();
    final allSameFamilyImage =
        existing.length == variantIds.length &&
        existing.every(
          (item) =>
              item.origin == Step6ExceptionOrigin.familyGallery &&
              item.imageId == existing.first.imageId,
        );
    final singleExisting = variantIds.length == 1 && existing.isNotEmpty
        ? existing.first
        : null;

    var choice = allSameFamilyImage
        ? _Step6ExceptionChoice.familyGallery
        : singleExisting?.origin == Step6ExceptionOrigin.variantSpecific
        ? _Step6ExceptionChoice.specificUpload
        : _Step6ExceptionChoice.inherit;
    String? selectedFamilyImageId = allSameFamilyImage
        ? existing.first.imageId
        : null;
    String? existingSpecificImageId =
        singleExisting?.origin == Step6ExceptionOrigin.variantSpecific
        ? singleExisting?.imageId
        : null;
    Step6ImageCandidate? uploadedSpecific;

    final variantLabels = variantIds
        .map((id) => widget.variants.firstWhere((item) => item.id == id))
        .toList();

    final action = await showDialog<_Step6ExceptionChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Step6ProductImageDraft? preview;
            if (choice == _Step6ExceptionChoice.inherit) {
              preview = _draft.familyPrimary;
            } else if (choice == _Step6ExceptionChoice.familyGallery) {
              preview = selectedFamilyImageId == null
                  ? null
                  : _findImage(selectedFamilyImageId!);
            } else if (existingSpecificImageId != null &&
                uploadedSpecific == null) {
              preview = _findImage(existingSpecificImageId!);
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  variantIds.length == 1
                                      ? 'Imagen principal de la variante'
                                      : 'Aplicar imagen a '
                                            '${variantIds.length} variantes',
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  variantIds.length == 1
                                      ? '${variantLabels.first.label}'
                                            '${_skuSuffix(variantLabels.first)}'
                                      : variantLabels
                                            .map((item) => item.label)
                                            .take(3)
                                            .join(' · '),
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            tooltip: 'Cerrar',
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _exceptionRadio(
                        value: _Step6ExceptionChoice.inherit,
                        groupValue: choice,
                        title: 'Usar la imagen principal de la familia',
                        subtitle: 'No crea una excepción.',
                        onChanged: (value) {
                          setDialogState(() => choice = value);
                        },
                      ),
                      _exceptionRadio(
                        value: _Step6ExceptionChoice.familyGallery,
                        groupValue: choice,
                        title: 'Elegir otra imagen de la galería familiar',
                        subtitle: 'Solo cambia qué imagen aparece primero.',
                        enabled: _familyImages.any(
                          (image) => image.isReady && !image.isPrimary,
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            choice = value;
                            selectedFamilyImageId ??= _familyImages
                                .where(
                                  (image) => image.isReady && !image.isPrimary,
                                )
                                .first
                                .id;
                          });
                        },
                      ),
                      if (choice == _Step6ExceptionChoice.familyGallery) ...[
                        const SizedBox(height: 10),
                        _buildFamilyImageChoices(
                          selectedId: selectedFamilyImageId,
                          onSelected: (id) {
                            setDialogState(() => selectedFamilyImageId = id);
                          },
                        ),
                      ],
                      _exceptionRadio(
                        value: _Step6ExceptionChoice.specificUpload,
                        groupValue: choice,
                        title: 'Subir una imagen específica',
                        subtitle: variantIds.length == 1
                            ? 'La imagen pertenecerá solo a esta variante.'
                            : 'Se crea una referencia por variante y el '
                                  'repositorio puede reutilizar el mismo archivo.',
                        onChanged: (value) {
                          setDialogState(() => choice = value);
                        },
                      ),
                      if (choice == _Step6ExceptionChoice.specificUpload) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await _pick(
                              Step6ImagePickRequest(
                                allowMultiple: false,
                                forFamilyGallery: false,
                                variantIds: variantIds,
                              ),
                            );
                            if (result.isEmpty) {
                              return;
                            }
                            final error = _candidateValidationError(
                              result.first,
                            );
                            if (error != null) {
                              _showMessage(error, error: true);
                              return;
                            }
                            setDialogState(() {
                              uploadedSpecific = result.first;
                              existingSpecificImageId = null;
                            });
                          },
                          style: _outlinedStyle(),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            uploadedSpecific == null &&
                                    existingSpecificImageId == null
                                ? 'Seleccionar imagen específica'
                                : 'Reemplazar imagen seleccionada',
                          ),
                        ),
                        if (uploadedSpecific != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            uploadedSpecific!.fileName,
                            style: const TextStyle(color: _muted, fontSize: 14),
                          ),
                        ],
                        if (uploadedSpecific == null &&
                            existingSpecificImageId != null &&
                            _findImage(
                                  existingSpecificImageId!,
                                )?.processState ==
                                Step6ImageProcessState.failed) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final failed = _findImage(
                                existingSpecificImageId!,
                              );
                              if (failed == null) {
                                return;
                              }
                              await _retryImage(failed);
                              setDialogState(() {});
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar imagen con error'),
                          ),
                        ],
                      ],
                      const SizedBox(height: 18),
                      _buildExceptionPreview(
                        preview: preview,
                        candidate: uploadedSpecific,
                        choice: choice,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          if (existing.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => Navigator.pop(
                                dialogContext,
                                _Step6ExceptionChoice.inherit,
                              ),
                              icon: const Icon(Icons.undo),
                              label: const Text('Restablecer herencia'),
                            )
                          else
                            const SizedBox.shrink(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: _outlinedStyle(),
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: 10),
                              FilledButton(
                                onPressed: () {
                                  if (choice ==
                                          _Step6ExceptionChoice.familyGallery &&
                                      selectedFamilyImageId == null) {
                                    _showMessage(
                                      'Selecciona una imagen de la galería.',
                                      error: true,
                                    );
                                    return;
                                  }
                                  if (choice ==
                                          _Step6ExceptionChoice
                                              .specificUpload &&
                                      uploadedSpecific == null &&
                                      existingSpecificImageId == null) {
                                    _showMessage(
                                      'Selecciona una imagen específica.',
                                      error: true,
                                    );
                                    return;
                                  }
                                  Navigator.pop(dialogContext, choice);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(170, 46),
                                ),
                                child: const Text(
                                  'Guardar excepción',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (action == null) {
      return;
    }

    if (action == _Step6ExceptionChoice.inherit) {
      _resetInheritance(variantIds);
      return;
    }
    if (action == _Step6ExceptionChoice.familyGallery) {
      _applyFamilyGalleryException(variantIds, selectedFamilyImageId!);
      return;
    }
    if (uploadedSpecific != null) {
      await _applySpecificException(variantIds, uploadedSpecific!);
    }
  }
}
