import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/producto_variante.dart';
import '../bloc/producto_form_bloc.dart';
import '../bloc/producto_form_event.dart';
import '../bloc/producto_form_state.dart';
import 'paso6_imagenes_corregido.dart';

class ProductoImagenesStep extends StatelessWidget {
  const ProductoImagenesStep({required this.state, super.key});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) {
    final familyId = state.productoId ?? 'familia-borrador';
    final saved = state.imagenesConfiguradas;
    final legacy = saved == null ? _legacyDraft(familyId) : null;
    final initial = saved ?? legacy;

    return Step6ImagesPanel(
      familyId: familyId,
      familyName: state.nombre.trim().isEmpty
          ? 'Familia sin nombre'
          : state.nombre.trim(),
      productLayout: switch (state.tipoRegistro) {
        'unico' => Step6ProductLayout.single,
        'matriz' => Step6ProductLayout.variantMatrix,
        _ => Step6ProductLayout.variantList,
      },
      variants: _buildVariants(),
      initialFamilyImages: initial?.familyImages ?? const [],
      initialVariantSpecificImages: initial?.variantSpecificImages ?? const [],
      initialExceptions: initial?.exceptions ?? const [],
      pickImages: _pickImages,
      processImage: (candidate) async => candidate,
      cropImage: _cropImage,
      previewBuilder: _previewImage,
      onChanged: (draft) => context.read<ProductoFormBloc>().add(
        ProductoFormImagenesConfiguradasCambiadas(draft),
      ),
      onBack: () => context.read<ProductoFormBloc>().add(
        const ProductoFormPasoAnterior(),
      ),
      onNext: (draft) => context.read<ProductoFormBloc>().add(
        ProductoFormImagenesConfiguradasCambiadas(draft, continuar: true),
      ),
    );
  }

  List<Step6VariantOption> _buildVariants() {
    final active = state.variantes.where((item) => item.activa).toList();
    final source = active.isEmpty ? state.variantes : active;
    return source.map((variant) {
      final attributes = variant.atributos
          .where((attribute) => attribute.texto.isNotEmpty)
          .toList();
      return Step6VariantOption(
        id: variant.id,
        label: _variantLabel(variant),
        sku: variant.sku,
        rowValue: state.tipoRegistro == 'matriz' && attributes.isNotEmpty
            ? attributes.first.texto
            : null,
        columnValue: state.tipoRegistro == 'matriz' && attributes.length > 1
            ? attributes[1].texto
            : null,
      );
    }).toList();
  }

  String _variantLabel(ProductoVariante variant) {
    if (variant.atributosTexto != 'Sin atributos') {
      return variant.atributosTexto;
    }
    if (variant.nombreCorto.trim().isNotEmpty) {
      return variant.nombreCorto.trim();
    }
    return variant.sku.trim().isEmpty ? variant.id : variant.sku.trim();
  }

  Future<List<Step6ImageCandidate>> _pickImages(
    Step6ImagePickRequest request,
  ) async {
    final picker = ImagePicker();
    final files = request.allowMultiple
        ? await picker.pickMultiImage(
            imageQuality: 92,
            maxWidth: 2400,
            maxHeight: 2400,
          )
        : [
            if (await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 92,
                  maxWidth: 2400,
                  maxHeight: 2400,
                )
                case final image?)
              image,
          ];
    final candidates = <Step6ImageCandidate>[];
    for (final image in files) {
      final file = File(image.path);
      candidates.add(
        Step6ImageCandidate(
          fileName: image.name,
          mimeType: image.mimeType ?? _mimeType(image.path),
          sizeBytes: await file.length(),
          localPath: image.path,
        ),
      );
    }
    return candidates;
  }

  Future<Step6ImageCandidate?> _cropImage(Step6ImageCandidate candidate) async {
    final sourcePath = candidate.localPath;
    if (sourcePath == null || sourcePath.isEmpty) return null;
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar imagen',
          toolbarColor: const Color(0xFF20242B),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFFFFC500),
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Ajustar imagen',
          doneButtonTitle: 'Guardar',
          cancelButtonTitle: 'Cancelar',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null) return null;
    final file = File(cropped.path);
    return candidate.copyWith(
      fileName: p.basename(cropped.path),
      mimeType: _mimeType(cropped.path),
      sizeBytes: await file.length(),
      localPath: cropped.path,
    );
  }

  Widget _previewImage(BuildContext context, Step6ProductImageDraft image) {
    final path = image.candidate.localPath;
    if (path != null && path.isNotEmpty) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    final bytes = image.candidate.previewBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    final url = image.candidate.remoteUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => const ColoredBox(
    color: Color(0xFFEEF1F5),
    child: Center(
      child: Icon(Icons.image_outlined, color: Color(0xFF667085), size: 38),
    ),
  );

  Step6ImagesDraft? _legacyDraft(String familyId) {
    if (state.imagenesPaths.isEmpty) return null;
    final images = state.imagenesPaths.asMap().entries.map((entry) {
      final file = File(entry.value);
      final size = file.existsSync() ? file.lengthSync() : 1;
      return Step6ProductImageDraft(
        id: 'imagen-existente-${entry.key}',
        owner: Step6ImageOwner.family,
        familyId: familyId,
        candidate: Step6ImageCandidate(
          fileName: p.basename(entry.value),
          mimeType: _mimeType(entry.value),
          sizeBytes: size,
          localPath: entry.value,
        ),
        label: entry.key == 0 ? 'Principal' : 'Detalle ${entry.key + 1}',
        order: entry.key,
        isPrimary: entry.key == 0,
        processState: Step6ImageProcessState.ready,
        syncState: Step6ImageSyncState.synced,
      );
    }).toList();
    return Step6ImagesDraft(
      familyImages: images,
      variantSpecificImages: const [],
      exceptions: const [],
    );
  }

  String _mimeType(String path) => switch (p.extension(path).toLowerCase()) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
