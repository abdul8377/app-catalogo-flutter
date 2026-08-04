import 'package:flutter/foundation.dart';

enum Step6ProductLayout { single, variantList, variantMatrix }

enum Step6ImageOwner { family, variant }

enum Step6ImageProcessState { processing, ready, failed }

enum Step6ImageSyncState { pending, synced, failed }

enum Step6ExceptionOrigin { familyGallery, variantSpecific }

@immutable
class Step6VariantOption {
  const Step6VariantOption({
    required this.id,
    required this.label,
    this.sku,
    this.rowValue,
    this.columnValue,
  });

  final String id;
  final String label;
  final String? sku;

  /// Útiles para conservar el contexto de una matriz, aunque la pantalla
  /// muestra una lista de excepciones.
  final String? rowValue;
  final String? columnValue;
}

@immutable
class Step6ImageCandidate {
  const Step6ImageCandidate({
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.width,
    this.height,
    this.localPath,
    this.remoteUrl,
    this.previewBytes,
    this.contentHash,
  });

  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final int? width;
  final int? height;

  /// SQLite puede guardar [localPath] como fuente offline.
  final String? localPath;

  /// MySQL/backend puede entregar [remoteUrl] después de sincronizar.
  final String? remoteUrl;

  /// Vista previa opcional y multiplataforma. No debe persistirse en la BD.
  final Uint8List? previewBytes;

  /// Permite que el repositorio reutilice el mismo archivo físico cuando una
  /// carga específica se aplica a varias variantes.
  final String? contentHash;

  Step6ImageCandidate copyWith({
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    int? width,
    int? height,
    String? localPath,
    String? remoteUrl,
    Uint8List? previewBytes,
    String? contentHash,
  }) {
    return Step6ImageCandidate(
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      previewBytes: previewBytes ?? this.previewBytes,
      contentHash: contentHash ?? this.contentHash,
    );
  }
}

@immutable
class Step6ProductImageDraft {
  const Step6ProductImageDraft({
    required this.id,
    required this.owner,
    required this.candidate,
    required this.label,
    required this.order,
    required this.isPrimary,
    required this.processState,
    required this.syncState,
    this.familyId,
    this.variantId,
    this.progress = 1,
    this.errorMessage,
  }) : assert(
         (owner == Step6ImageOwner.family &&
                 familyId != null &&
                 variantId == null) ||
             (owner == Step6ImageOwner.variant &&
                 familyId == null &&
                 variantId != null),
         'Cada imagen debe pertenecer a una familia o a una variante, '
         'pero nunca a ambas.',
       ),
       assert(order >= 0),
       assert(progress >= 0 && progress <= 1);

  final String id;
  final Step6ImageOwner owner;
  final String? familyId;
  final String? variantId;
  final Step6ImageCandidate candidate;
  final String label;
  final int order;

  /// Para la familia identifica su principal. En una imagen específica,
  /// la excepción es la que determina que sustituye a la principal.
  final bool isPrimary;
  final Step6ImageProcessState processState;
  final Step6ImageSyncState syncState;
  final double progress;
  final String? errorMessage;

  bool get isReady => processState == Step6ImageProcessState.ready;

  Step6ProductImageDraft copyWith({
    Step6ImageCandidate? candidate,
    String? label,
    int? order,
    bool? isPrimary,
    Step6ImageProcessState? processState,
    Step6ImageSyncState? syncState,
    double? progress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return Step6ProductImageDraft(
      id: id,
      owner: owner,
      familyId: familyId,
      variantId: variantId,
      candidate: candidate ?? this.candidate,
      label: label ?? this.label,
      order: order ?? this.order,
      isPrimary: isPrimary ?? this.isPrimary,
      processState: processState ?? this.processState,
      syncState: syncState ?? this.syncState,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

@immutable
class Step6VariantImageExceptionDraft {
  const Step6VariantImageExceptionDraft({
    required this.variantId,
    required this.imageId,
    required this.origin,
  });

  final String variantId;
  final String imageId;
  final Step6ExceptionOrigin origin;
}

@immutable
class Step6ImagesDraft {
  const Step6ImagesDraft({
    required this.familyImages,
    required this.variantSpecificImages,
    required this.exceptions,
  });

  final List<Step6ProductImageDraft> familyImages;
  final List<Step6ProductImageDraft> variantSpecificImages;
  final List<Step6VariantImageExceptionDraft> exceptions;

  Step6ProductImageDraft? get familyPrimary {
    for (final image in familyImages) {
      if (image.isPrimary && image.isReady) {
        return image;
      }
    }
    return null;
  }

  bool get hasProcessing {
    return [
      ...familyImages,
      ...variantSpecificImages,
    ].any((image) => image.processState == Step6ImageProcessState.processing);
  }

  bool get hasFailed {
    return [
      ...familyImages,
      ...variantSpecificImages,
    ].any((image) => image.processState == Step6ImageProcessState.failed);
  }

  /// El paso 6 puede guardarse como borrador sin imágenes. La activación del
  /// paso 7 sí debe exigir esta condición.
  bool get canActivate => familyPrimary != null && !hasProcessing && !hasFailed;

  Step6VariantImageExceptionDraft? exceptionFor(String variantId) {
    for (final item in exceptions) {
      if (item.variantId == variantId) {
        return item;
      }
    }
    return null;
  }

  Step6ProductImageDraft? imageById(String imageId) {
    for (final image in [...familyImages, ...variantSpecificImages]) {
      if (image.id == imageId) {
        return image;
      }
    }
    return null;
  }

  /// Orden efectivo para catálogo/pedido:
  /// 1) excepción o principal familiar;
  /// 2) todas las imágenes familiares restantes según [order].
  List<Step6ProductImageDraft> effectiveGalleryFor(String variantId) {
    final orderedFamily = [...familyImages]
      ..sort((a, b) => a.order.compareTo(b.order));
    final exception = exceptionFor(variantId);
    final effectivePrimary = exception == null
        ? familyPrimary
        : imageById(exception.imageId);

    if (effectivePrimary == null) {
      return orderedFamily.where((image) => image.isReady).toList();
    }

    return [
      effectivePrimary,
      ...orderedFamily.where(
        (image) => image.isReady && image.id != effectivePrimary.id,
      ),
    ];
  }
}

@immutable
class Step6ImagePickRequest {
  const Step6ImagePickRequest({
    required this.allowMultiple,
    required this.forFamilyGallery,
    this.variantIds = const [],
  });

  final bool allowMultiple;
  final bool forFamilyGallery;
  final List<String> variantIds;
}

typedef Step6ImagePicker =
    Future<List<Step6ImageCandidate>> Function(Step6ImagePickRequest request);

typedef Step6ImageProcessor =
    Future<Step6ImageCandidate> Function(Step6ImageCandidate candidate);

typedef Step6ImageCropper =
    Future<Step6ImageCandidate?> Function(Step6ImageCandidate candidate);

Map<String, dynamic> step6ImagesDraftToMap(Step6ImagesDraft draft) {
  Map<String, dynamic> candidateToMap(Step6ImageCandidate candidate) {
    return {
      'file_name': candidate.fileName,
      'mime_type': candidate.mimeType,
      'size_bytes': candidate.sizeBytes,
      'width': candidate.width,
      'height': candidate.height,
      'local_path': candidate.localPath,
      'remote_url': candidate.remoteUrl,
      'content_hash': candidate.contentHash,
    };
  }

  Map<String, dynamic> imageToMap(Step6ProductImageDraft image) {
    return {
      'id': image.id,
      'owner': image.owner.name,
      'family_id': image.familyId,
      'variant_id': image.variantId,
      'candidate': candidateToMap(image.candidate),
      'label': image.label,
      'order': image.order,
      'is_primary': image.isPrimary,
      'process_state': image.processState.name,
      'sync_state': image.syncState.name,
      'progress': image.progress,
      'error_message': image.errorMessage,
    };
  }

  return {
    'family_images': draft.familyImages.map(imageToMap).toList(),
    'variant_specific_images': draft.variantSpecificImages
        .map(imageToMap)
        .toList(),
    'exceptions': draft.exceptions.map((item) {
      return {
        'variant_id': item.variantId,
        'image_id': item.imageId,
        'origin': item.origin.name,
      };
    }).toList(),
  };
}

Step6ImagesDraft? step6ImagesDraftFromMap(Map<String, dynamic>? map) {
  if (map == null || map.isEmpty) {
    return null;
  }

  T enumValue<T extends Enum>(Iterable<T> values, Object? raw, T fallback) {
    return values.firstWhere(
      (item) => item.name == raw?.toString(),
      orElse: () => fallback,
    );
  }

  Step6ImageCandidate candidateFrom(Object? raw) {
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    return Step6ImageCandidate(
      fileName: map['file_name']?.toString() ?? '',
      mimeType: map['mime_type']?.toString() ?? '',
      sizeBytes: (map['size_bytes'] as num?)?.toInt() ?? 0,
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      localPath: map['local_path'] as String?,
      remoteUrl: map['remote_url'] as String?,
      contentHash: map['content_hash'] as String?,
    );
  }

  Step6ProductImageDraft? imageFrom(Object? raw, Step6ImageOwner owner) {
    if (raw is! Map) {
      return null;
    }
    final item = Map<String, dynamic>.from(raw);
    final familyId = item['family_id'] as String?;
    final variantId = item['variant_id'] as String?;
    if ((owner == Step6ImageOwner.family &&
            (familyId == null || variantId != null)) ||
        (owner == Step6ImageOwner.variant &&
            (variantId == null || familyId != null))) {
      return null;
    }
    return Step6ProductImageDraft(
      id: item['id']?.toString() ?? '',
      owner: owner,
      familyId: familyId,
      variantId: variantId,
      candidate: candidateFrom(item['candidate']),
      label: item['label']?.toString() ?? 'Detalle',
      order: (item['order'] as num?)?.toInt() ?? 0,
      isPrimary: item['is_primary'] as bool? ?? false,
      processState: enumValue(
        Step6ImageProcessState.values,
        item['process_state'],
        Step6ImageProcessState.ready,
      ),
      syncState: enumValue(
        Step6ImageSyncState.values,
        item['sync_state'],
        Step6ImageSyncState.pending,
      ),
      progress: (item['progress'] as num?)?.toDouble() ?? 1,
      errorMessage: item['error_message'] as String?,
    );
  }

  final familyImages = (map['family_images'] as List? ?? const [])
      .map((raw) => imageFrom(raw, Step6ImageOwner.family))
      .whereType<Step6ProductImageDraft>()
      .toList();
  final variantImages = (map['variant_specific_images'] as List? ?? const [])
      .map((raw) => imageFrom(raw, Step6ImageOwner.variant))
      .whereType<Step6ProductImageDraft>()
      .toList();
  final exceptions = (map['exceptions'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return Step6VariantImageExceptionDraft(
          variantId: item['variant_id']?.toString() ?? '',
          imageId: item['image_id']?.toString() ?? '',
          origin: enumValue(
            Step6ExceptionOrigin.values,
            item['origin'],
            Step6ExceptionOrigin.familyGallery,
          ),
        );
      })
      .where((item) => item.variantId.isNotEmpty && item.imageId.isNotEmpty)
      .toList();

  if (familyImages.isEmpty && variantImages.isEmpty && exceptions.isEmpty) {
    return null;
  }
  return Step6ImagesDraft(
    familyImages: familyImages,
    variantSpecificImages: variantImages,
    exceptions: exceptions,
  );
}
