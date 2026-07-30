import 'dart:typed_data';

import 'package:flutter/material.dart';

// ============================================================================
// PASO 6 · IMÁGENES
//
// Widget autocontenido para integrar en el PageView del registro de productos.
//
// Regla de negocio:
// - La familia posee una galería compartida y una sola imagen principal.
// - Todas las variantes heredan la galería sin duplicar registros.
// - Una excepción sustituye únicamente la imagen principal de una variante.
// - Las imágenes familiares restantes continúan como imágenes secundarias.
// - En producto único se oculta por completo el panel de excepciones.
// ============================================================================

enum Step6ProductLayout { single, variantList, variantMatrix }

enum Step6ImageOwner { family, variant }

enum Step6ImageProcessState { processing, ready, failed }

enum Step6ImageSyncState { pending, synced, failed }

enum Step6ExceptionOrigin { familyGallery, variantSpecific }

enum Step6VariantFilter { all, withException, withoutException }

enum _Step6ImageAction { view, makePrimary, editLabel, crop, replace, delete }

enum _Step6ExceptionChoice { inherit, familyGallery, specificUpload }

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

typedef Step6ImagePreviewBuilder =
    Widget Function(BuildContext context, Step6ProductImageDraft image);

class Step6ImagesPanel extends StatefulWidget {
  const Step6ImagesPanel({
    super.key,
    required this.familyId,
    required this.familyName,
    required this.productLayout,
    required this.variants,
    required this.onBack,
    required this.onNext,
    this.initialFamilyImages = const [],
    this.initialVariantSpecificImages = const [],
    this.initialExceptions = const [],
    this.pickImages,
    this.processImage,
    this.cropImage,
    this.previewBuilder,
    this.onChanged,
    this.maxImageBytes = 8 * 1024 * 1024,
    this.recommendedMinWidth = 1200,
    this.recommendedMinHeight = 1200,
    this.cropAspectRatio = 1,
  });

  final String familyId;
  final String familyName;
  final Step6ProductLayout productLayout;
  final List<Step6VariantOption> variants;

  final List<Step6ProductImageDraft> initialFamilyImages;
  final List<Step6ProductImageDraft> initialVariantSpecificImages;
  final List<Step6VariantImageExceptionDraft> initialExceptions;

  /// Se conecta con image_picker, file_picker o el adaptador elegido.
  final Step6ImagePicker? pickImages;

  /// Punto de integración para comprimir, recortar y persistir localmente.
  final Step6ImageProcessor? processImage;
  final Step6ImageCropper? cropImage;
  final Step6ImagePreviewBuilder? previewBuilder;

  final int maxImageBytes;
  final int recommendedMinWidth;
  final int recommendedMinHeight;
  final double cropAspectRatio;

  final VoidCallback onBack;
  final ValueChanged<Step6ImagesDraft> onNext;
  final ValueChanged<Step6ImagesDraft>? onChanged;

  @override
  State<Step6ImagesPanel> createState() => _Step6ImagesPanelState();
}

class _Step6ImagesPanelState extends State<Step6ImagesPanel> {
  static const Color _primary = Color(0xFFFFC500);
  static const Color _ink = Color(0xFF242830);
  static const Color _muted = Color(0xFF667085);
  static const Color _border = Color(0xFFD5DDE8);
  static const Color _canvas = Color(0xFFF8FAFC);
  static const Color _soft = Color(0xFFF2F5F9);
  static const Color _selection = Color(0xFF1E5AA8);
  static const Color _success = Color(0xFF18794E);
  static const Color _danger = Color(0xFFB42318);

  late List<Step6ProductImageDraft> _familyImages;
  late List<Step6ProductImageDraft> _variantImages;
  late List<Step6VariantImageExceptionDraft> _exceptions;

  final TextEditingController _variantSearchController =
      TextEditingController();
  Step6VariantFilter _variantFilter = Step6VariantFilter.all;
  String? _selectedVariantId;
  bool _multiSelect = false;
  final Set<String> _selectedVariantIds = <String>{};

  int _idSequence = DateTime.now().microsecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _familyImages = _normalizeFamilyImages(widget.initialFamilyImages);
    _variantImages = List<Step6ProductImageDraft>.of(
      widget.initialVariantSpecificImages,
    );
    _exceptions = List<Step6VariantImageExceptionDraft>.of(
      widget.initialExceptions,
    );
    _reconcileState();
    if (widget.variants.isNotEmpty) {
      _selectedVariantId = widget.variants.first.id;
    }
    _variantSearchController.addListener(_refreshVariantList);
  }

  @override
  void didUpdateWidget(covariant Step6ImagesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final validIds = widget.variants.map((item) => item.id).toSet();
    _exceptions.removeWhere((item) => !validIds.contains(item.variantId));
    _selectedVariantIds.removeWhere((id) => !validIds.contains(id));
    if (_selectedVariantId != null && !validIds.contains(_selectedVariantId)) {
      _selectedVariantId = widget.variants.isEmpty
          ? null
          : widget.variants.first.id;
    }
  }

  @override
  void dispose() {
    _variantSearchController
      ..removeListener(_refreshVariantList)
      ..dispose();
    super.dispose();
  }

  Step6ImagesDraft get _draft {
    final family = [..._familyImages]
      ..sort((a, b) => a.order.compareTo(b.order));
    final variant = [..._variantImages]
      ..sort((a, b) {
        final owner = (a.variantId ?? '').compareTo(b.variantId ?? '');
        return owner == 0 ? a.order.compareTo(b.order) : owner;
      });
    return Step6ImagesDraft(
      familyImages: List.unmodifiable(family),
      variantSpecificImages: List.unmodifiable(variant),
      exceptions: List.unmodifiable(_exceptions),
    );
  }

  bool get _hasProcessing => _draft.hasProcessing;
  bool get _hasFailed => _draft.hasFailed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final showExceptions =
                          widget.productLayout != Step6ProductLayout.single;
                      final sideBySide =
                          showExceptions && constraints.maxWidth >= 1080;

                      if (!showExceptions) {
                        return _buildFamilyGallery();
                      }

                      if (sideBySide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _buildFamilyGallery()),
                            const SizedBox(width: 22),
                            SizedBox(
                              width: 430,
                              child: _buildVariantExceptions(),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFamilyGallery(),
                          const SizedBox(height: 22),
                          _buildVariantExceptions(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final primaryCount = _familyImages.where((image) => image.isPrimary).length;
    return Wrap(
      spacing: 18,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paso 6 · Imágenes',
              style: TextStyle(
                color: _ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Administra la galería compartida y las excepciones visuales.',
              style: TextStyle(color: _muted, fontSize: 14, height: 1.4),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Familia: ${widget.familyName} · '
              '${widget.variants.length} '
              '${widget.variants.length == 1 ? 'variante' : 'variantes'}',
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _buildSummaryBadge(
              '${_familyImages.length} imágenes de familia · '
              '$primaryCount principal · '
              '${_exceptions.length} '
              '${_exceptions.length == 1 ? 'excepción' : 'excepciones'}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5CC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFE58A)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFamilyGallery() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Galería de la familia',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Todas las variantes heredan estas imágenes.',
                    style: TextStyle(color: _muted, fontSize: 14),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _hasProcessing ? null : _addFamilyImages,
                style: _outlinedStyle(),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('+ Agregar imágenes'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildImageRequirements(),
          if (_hasProcessing) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              minHeight: 4,
              color: _selection,
              backgroundColor: Color(0xFFDCE6F4),
            ),
          ],
          const SizedBox(height: 18),
          if (_familyImages.isEmpty)
            _buildEmptyGallery()
          else
            _buildReorderableGrid(),
        ],
      ),
    );
  }

  Widget _buildImageRequirements() {
    final maxMb = widget.maxImageBytes / (1024 * 1024);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _muted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'JPG, PNG o WebP · máximo ${_plainNumber(maxMb)} MB · '
              'recomendado ${widget.recommendedMinWidth} × '
              '${widget.recommendedMinHeight} px · recorte '
              '${_ratioLabel(widget.cropAspectRatio)}.',
              style: const TextStyle(color: _muted, fontSize: 14, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGallery() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 46),
      decoration: BoxDecoration(
        color: _canvas,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.photo_library_outlined, size: 42, color: _muted),
          const SizedBox(height: 12),
          const Text(
            'Aún no hay imágenes en la galería.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Puedes guardar el producto como borrador. Para activarlo en el '
            'paso 7 deberá existir una imagen principal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _addFamilyImages,
            style: _outlinedStyle(),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Agregar imágenes'),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 780
            ? 3
            : constraints.maxWidth >= 510
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _familyImages.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) {
            final image = _familyImages[index];
            return LongPressDraggable<String>(
              data: image.id,
              maxSimultaneousDrags: image.isReady ? 1 : 0,
              feedback: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 240,
                  height: 280,
                  child: _buildImageCard(image, index),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.35,
                child: _buildImageCard(image, index),
              ),
              child: DragTarget<String>(
                onWillAcceptWithDetails: (details) => details.data != image.id,
                onAcceptWithDetails: (details) {
                  _moveFamilyImage(details.data, image.id);
                },
                builder: (context, candidates, rejected) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      border: candidates.isEmpty
                          ? null
                          : Border.all(color: _selection, width: 2),
                    ),
                    child: _buildImageCard(image, index),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageCard(Step6ProductImageDraft image, int index) {
    final belowRecommendation = _isBelowRecommendation(image.candidate);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: image.isPrimary ? _primary : _border,
          width: image.isPrimary ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImagePreview(image),
                Positioned(
                  top: 9,
                  left: 9,
                  child: image.isPrimary
                      ? _statusBadge(
                          icon: Icons.star,
                          label: 'Principal',
                          background: const Color(0xFFFFF3BF),
                          foreground: _ink,
                        )
                      : _statusBadge(
                          icon: Icons.drag_indicator,
                          label: 'Posición ${index + 1}',
                          background: Colors.white.withOpacity(0.94),
                          foreground: _ink,
                        ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: PopupMenuButton<_Step6ImageAction>(
                    tooltip: 'Acciones de imagen',
                    constraints: const BoxConstraints(minWidth: 220),
                    onSelected: (action) => _handleImageAction(action, image),
                    itemBuilder: (context) => [
                      _imageMenuItem(
                        _Step6ImageAction.view,
                        Icons.open_in_full,
                        'Ver en tamaño completo',
                      ),
                      _imageMenuItem(
                        _Step6ImageAction.makePrimary,
                        Icons.star_outline,
                        'Establecer como principal',
                        enabled: !image.isPrimary && image.isReady,
                      ),
                      _imageMenuItem(
                        _Step6ImageAction.editLabel,
                        Icons.label_outline,
                        'Editar etiqueta',
                      ),
                      _imageMenuItem(
                        _Step6ImageAction.crop,
                        Icons.crop,
                        'Ajustar o recortar',
                        enabled: image.isReady,
                      ),
                      _imageMenuItem(
                        _Step6ImageAction.replace,
                        Icons.find_replace_outlined,
                        'Reemplazar',
                        enabled:
                            image.processState !=
                            Step6ImageProcessState.processing,
                      ),
                      _imageMenuItem(
                        _Step6ImageAction.delete,
                        Icons.delete_outline,
                        'Eliminar',
                        foreground: _danger,
                      ),
                    ],
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_vert),
                    ),
                  ),
                ),
                if (image.processState == Step6ImageProcessState.processing)
                  _buildProcessingOverlay(image),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                if (image.processState == Step6ImageProcessState.failed)
                  _buildFailedStatus(image)
                else
                  _buildSyncStatus(image),
                if (belowRecommendation &&
                    image.processState == Step6ImageProcessState.ready) ...[
                  const SizedBox(height: 7),
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFF8A5A00),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Resolución menor a la recomendada',
                          style: TextStyle(
                            color: Color(0xFF8A5A00),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_Step6ImageAction> _imageMenuItem(
    _Step6ImageAction value,
    IconData icon,
    String label, {
    bool enabled = true,
    Color foreground = _ink,
  }) {
    return PopupMenuItem<_Step6ImageAction>(
      value: value,
      enabled: enabled,
      height: 48,
      child: Row(
        children: [
          Icon(icon, color: enabled ? foreground : _muted, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: enabled ? foreground : _muted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(Step6ProductImageDraft image) {
    if (widget.previewBuilder != null) {
      return ClipRect(child: widget.previewBuilder!(context, image));
    }

    final bytes = image.candidate.previewBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
    }

    final url = image.candidate.remoteUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPreviewPlaceholder(image),
      );
    }

    return _buildPreviewPlaceholder(image);
  }

  Widget _buildPreviewPlaceholder(Step6ProductImageDraft image) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            (constraints.hasBoundedWidth && constraints.maxWidth < 100) ||
            (constraints.hasBoundedHeight && constraints.maxHeight < 100);
        return ColoredBox(
          color: const Color(0xFFEEF1F5),
          child: Center(
            child: compact
                ? const Icon(Icons.image_outlined, color: _muted, size: 28)
                : Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: _muted,
                          size: 38,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          image.candidate.fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildProcessingOverlay(Step6ProductImageDraft image) {
    return ColoredBox(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Procesando ${(image.progress * 100).round()} %',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedStatus(Step6ProductImageDraft image) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: _danger, size: 19),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'No se pudo procesar',
            style: TextStyle(
              color: _danger,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _retryImage(image),
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          child: const Text('Reintentar'),
        ),
      ],
    );
  }

  Widget _buildSyncStatus(Step6ProductImageDraft image) {
    final synced = image.syncState == Step6ImageSyncState.synced;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: synced ? _success : _muted,
          size: 19,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            synced
                ? 'Sincronizada'
                : 'Guardada localmente · Pendiente de sincronizar',
            style: TextStyle(
              color: synced ? _success : _muted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantExceptions() {
    final filtered = _filteredVariants;
    return _panel(
      background: _canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Excepciones por variante',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton.icon(
                onPressed: _toggleMultiSelect,
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                icon: Icon(
                  _multiSelect ? Icons.close : Icons.library_add_check_outlined,
                ),
                label: Text(
                  _multiSelect ? 'Cancelar selección' : 'Seleccionar varias',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInheritanceNote(),
          const SizedBox(height: 14),
          TextField(
            controller: _variantSearchController,
            style: const TextStyle(fontSize: 14),
            decoration: _inputDecoration(
              'Buscar por medida o SKU',
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(Step6VariantFilter.all, 'Todas'),
              _filterChip(Step6VariantFilter.withException, 'Con excepción'),
              _filterChip(Step6VariantFilter.withoutException, 'Sin excepción'),
            ],
          ),
          if (_multiSelect) ...[
            const SizedBox(height: 12),
            _buildBulkSelectionBar(filtered),
          ],
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            _buildNoVariantsState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 9),
              itemBuilder: (context, index) =>
                  _buildVariantRow(filtered[index]),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _exceptionActionEnabled
                ? () => _openExceptionEditor(_exceptionTargetIds)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: _selection,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(
              _multiSelect ? Icons.content_copy_outlined : Icons.tune_outlined,
            ),
            label: Text(
              _multiSelect ? 'Aplicar la misma imagen' : 'Configurar excepción',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInheritanceNote() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8E5F6)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_tree_outlined, color: _selection, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Herencia automática\n'
              'Todas las variantes utilizan la galería familiar. Configura '
              'una excepción solamente cuando una variante tenga una '
              'apariencia diferente.',
              style: TextStyle(color: _ink, fontSize: 14, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(Step6VariantFilter filter, String label) {
    final selected = _variantFilter == filter;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        setState(() => _variantFilter = filter);
      },
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: _selection,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _selection : _border),
      showCheckmark: true,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _buildBulkSelectionBar(List<Step6VariantOption> visible) {
    final visibleIds = visible.map((item) => item.id).toSet();
    final allVisibleSelected =
        visibleIds.isNotEmpty && _selectedVariantIds.containsAll(visibleIds);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Checkbox(
            value: allVisibleSelected,
            onChanged: (_) {
              setState(() {
                if (allVisibleSelected) {
                  _selectedVariantIds.removeAll(visibleIds);
                } else {
                  _selectedVariantIds.addAll(visibleIds);
                }
              });
            },
          ),
          Expanded(
            child: Text(
              '${_selectedVariantIds.length} '
              '${_selectedVariantIds.length == 1 ? 'variante seleccionada' : 'variantes seleccionadas'}',
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVariantsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: const Text(
        'No hay variantes que coincidan con la búsqueda o el filtro.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted, fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget _buildVariantRow(Step6VariantOption variant) {
    final exception = _exceptionFor(variant.id);
    final selected = _multiSelect
        ? _selectedVariantIds.contains(variant.id)
        : _selectedVariantId == variant.id;
    final effectiveImage = _effectivePrimaryFor(variant.id);

    return InkWell(
      onTap: () {
        setState(() {
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
                  setState(() {
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

  Widget _buildBottomNavigation() {
    final primaryReady = _draft.familyPrimary != null;
    final statusText = _hasProcessing
        ? 'Hay imágenes procesándose'
        : _hasFailed
        ? 'Reintenta o elimina las imágenes con error'
        : primaryReady
        ? 'Imagen principal lista'
        : 'Falta una imagen principal para activar';
    final statusIcon = _hasProcessing
        ? Icons.hourglass_top
        : _hasFailed
        ? Icons.error_outline
        : primaryReady
        ? Icons.check_circle_outline
        : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final back = OutlinedButton(
            onPressed: widget.onBack,
            style: _outlinedStyle(),
            child: const Text('Anterior'),
          );
          final status = Row(
            children: [
              Icon(
                statusIcon,
                color: primaryReady && !_hasProcessing && !_hasFailed
                    ? _success
                    : _muted,
                size: 20,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '$statusText · Paso 6 de 7',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 14),
                ),
              ),
            ],
          );
          final next = FilledButton(
            onPressed: _hasProcessing ? null : _continueToReview,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(220, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Siguiente: revisar y activar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          );

          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                next,
                const SizedBox(height: 10),
                Row(
                  children: [
                    back,
                    const SizedBox(width: 12),
                    Expanded(child: status),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              back,
              const Spacer(),
              Flexible(child: status),
              const Spacer(),
              next,
            ],
          );
        },
      ),
    );
  }

  Widget _panel({required Widget child, Color background = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _statusBadge({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 17),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _selection, width: 2),
      ),
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _ink,
      minimumSize: const Size(44, 46),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      side: const BorderSide(color: Color(0xFFB9C4D2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }

  List<Step6VariantOption> get _filteredVariants {
    final query = _variantSearchController.text.trim().toLowerCase();
    return widget.variants.where((variant) {
      final hasException = _exceptionFor(variant.id) != null;
      final matchesFilter = switch (_variantFilter) {
        Step6VariantFilter.all => true,
        Step6VariantFilter.withException => hasException,
        Step6VariantFilter.withoutException => !hasException,
      };
      final searchable = '${variant.label} ${variant.sku ?? ''}'.toLowerCase();
      return matchesFilter && (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  bool get _exceptionActionEnabled {
    if (_multiSelect) {
      return _selectedVariantIds.isNotEmpty;
    }
    return _selectedVariantId != null;
  }

  List<String> get _exceptionTargetIds {
    if (_multiSelect) {
      return _selectedVariantIds.toList();
    }
    return _selectedVariantId == null ? [] : [_selectedVariantId!];
  }

  void _refreshVariantList() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleMultiSelect() {
    setState(() {
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

    setState(() => _familyImages.addAll(drafts));
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
      setState(() {});
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
    setState(() {});
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

    setState(() {
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
    setState(() {
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
    setState(() {});
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
      setState(() {});
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
    setState(() {});
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

    setState(() {
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

  void _resetInheritance(List<String> variantIds) {
    setState(() {
      _exceptions.removeWhere((item) => variantIds.contains(item.variantId));
      _removeOrphanVariantImages();
    });
    _emitChanged();
    _showMessage('Herencia restablecida.');
  }

  void _applyFamilyGalleryException(List<String> variantIds, String imageId) {
    setState(() {
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
    setState(() {
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

  static String _skuSuffix(Step6VariantOption variant) {
    final sku = variant.sku?.trim();
    return sku == null || sku.isEmpty ? '' : ' · SKU $sku';
  }
}

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

String _plainNumber(num value) {
  final number = value.toDouble();
  if (number == number.roundToDouble()) {
    return number.toInt().toString();
  }
  return number
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _ratioLabel(double ratio) {
  if ((ratio - 1).abs() < 0.001) {
    return '1:1';
  }
  if ((ratio - (4 / 3)).abs() < 0.001) {
    return '4:3';
  }
  if ((ratio - (3 / 2)).abs() < 0.001) {
    return '3:2';
  }
  return _plainNumber(ratio);
}

// ============================================================================
// INTEGRACIÓN CON EL FLUJO EXISTENTE
// ============================================================================
//
// Step6ImagesDraft? _step6Draft;
//
// List<Step6VariantOption> _buildStep6Variants() {
//   return _buildStep4Variants().map((variant) {
//     return Step6VariantOption(
//       id: variant.id,
//       label: variant.label,
//       sku: _skuForVariant(variant.id),
//       rowValue: variant.rowValue,
//       columnValue: variant.columnValue,
//     );
//   }).toList();
// }
//
// Step6ProductLayout get _step6ProductLayout {
//   if (_selectedTypeIndex == 0) return Step6ProductLayout.single;
//   if (_selectedTypeIndex == 1) return Step6ProductLayout.variantList;
//   return Step6ProductLayout.variantMatrix;
// }
//
// Step6ImagesPanel(
//   familyId: _familyId,
//   familyName: _familyName ?? 'Familia sin nombre',
//   productLayout: _step6ProductLayout,
//   variants: _buildStep6Variants(),
//   initialFamilyImages: _step6Draft?.familyImages ?? const [],
//   initialVariantSpecificImages:
//       _step6Draft?.variantSpecificImages ?? const [],
//   initialExceptions: _step6Draft?.exceptions ?? const [],
//   pickImages: _pickStep6Images,
//   processImage: _processAndSaveImageLocally,
//   cropImage: _openImageCropper,
//   onChanged: (draft) => _step6Draft = draft,
//   onBack: () => _pageController.previousPage(
//     duration: const Duration(milliseconds: 250),
//     curve: Curves.easeOut,
//   ),
//   onNext: (draft) {
//     _step6Draft = draft;
//     _pageController.nextPage(
//       duration: const Duration(milliseconds: 250),
//       curve: Curves.easeOut,
//     );
//   },
// ),
//
// En el paso 7:
//
// if (!(_step6Draft?.canActivate ?? false)) {
//   // Permitir "Guardar borrador", pero impedir "Activar producto".
// }
//
// Persistencia:
// - familyImages -> producto_imagenes con familia_id.
// - variantSpecificImages -> producto_imagenes con variante_id.
// - familyGallery -> producto_imagen_excepciones.imagen_familia_id.
// - variantSpecific -> producto_imagen_excepciones.imagen_variante_id.
// - Ausencia de excepción = herencia; no se copian imágenes por variante.
// - Al reemplazar una excepción específica, elimina la asociación anterior y
//   su imagen huérfana antes de insertar la nueva, dentro de una transacción.
