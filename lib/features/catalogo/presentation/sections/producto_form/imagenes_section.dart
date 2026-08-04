import 'package:flutter/material.dart';

import '../../models/producto_form/imagenes_draft.dart';

part 'imagenes/exception_editor.dart';
part 'imagenes/exception_persistence_and_validation.dart';
part 'imagenes/exception_widgets.dart';
part 'imagenes/gallery_section.dart';
part 'imagenes/image_actions.dart';
part 'imagenes/image_card_and_preview.dart';
part 'imagenes/image_lifecycle.dart';
part 'imagenes/navigation_and_common_widgets.dart';
part 'imagenes/state_reconciliation.dart';
part 'imagenes/variant_exceptions_section.dart';
part 'imagenes/variant_row.dart';

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

enum Step6VariantFilter { all, withException, withoutException }

enum _Step6ImageAction { view, makePrimary, editLabel, crop, replace, delete }

enum _Step6ExceptionChoice { inherit, familyGallery, specificUpload }

const Color _primary = Color(0xFFFFC500);
const Color _ink = Color(0xFF242830);
const Color _muted = Color(0xFF667085);
const Color _border = Color(0xFFD5DDE8);
const Color _canvas = Color(0xFFF8FAFC);
const Color _soft = Color(0xFFF2F5F9);
const Color _selection = Color(0xFF1E5AA8);
const Color _success = Color(0xFF18794E);
const Color _danger = Color(0xFFB42318);

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
  void _update(VoidCallback callback) => setState(callback);

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

String _skuSuffix(Step6VariantOption variant) {
  final sku = variant.sku?.trim();
  return sku == null || sku.isEmpty ? '' : ' · SKU $sku';
}
