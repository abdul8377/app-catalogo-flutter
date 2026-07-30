import 'package:flutter/material.dart';

// ============================================================================
// PASO 7 · REVISAR Y ACTIVAR
//
// Widget autocontenido para integrar en el PageView del registro de productos.
//
// Reglas principales:
// - "Por cotizar" es una configuración válida y genera una advertencia.
// - "Sin configurar" bloquea la activación.
// - También bloquean SKU duplicados, ausencia de presentación vendible y falta
//   de imagen principal cuando esta es obligatoria.
// - Cada tarjeta permite regresar directamente al paso correspondiente.
// - La confirmación funciona para producto único, lista y matriz de variantes.
// - La activación offline informa que la sincronización continúa pendiente.
// ============================================================================

enum Step7ProductLayout {
  single,
  variantList,
  variantMatrix,
}

enum Step7InitialStatus {
  active,
  inactive,
}

enum Step7ReviewSeverity {
  ready,
  warning,
  blocked,
}

enum Step7CardState {
  complete,
  warning,
  blocked,
  willActivate,
}

@immutable
class Step7PresentationReview {
  const Step7PresentationReview({
    required this.name,
    required this.assignedVariantCount,
  }) : assert(assignedVariantCount >= 0);

  final String name;
  final int assignedVariantCount;
}

@immutable
class Step7PricingReview {
  const Step7PricingReview({
    required this.listName,
    required this.currencyCode,
    required this.includesIgv,
    required this.totalCombinationCount,
    required this.numericPriceCount,
    required this.quoteCount,
    required this.pendingCount,
  })  : assert(totalCombinationCount >= 0),
        assert(numericPriceCount >= 0),
        assert(quoteCount >= 0),
        assert(pendingCount >= 0);

  final String listName;
  final String currencyCode;
  final bool includesIgv;

  /// Total de filas generadas por lista + variante + presentación.
  final int totalCombinationCount;

  /// Incluye precios fijos y combinaciones con rangos completos.
  final int numericPriceCount;

  /// Configuración válida que se completa posteriormente en el pedido.
  final int quoteCount;

  /// Combinaciones que todavía están "Sin configurar".
  final int pendingCount;

  int get readyCount => numericPriceCount + quoteCount;
}

@immutable
class Step7ImagesReview {
  const Step7ImagesReview({
    required this.familyImageCount,
    required this.hasFamilyPrimary,
    required this.exceptionCount,
    this.processingCount = 0,
    this.failedCount = 0,
  })  : assert(familyImageCount >= 0),
        assert(exceptionCount >= 0),
        assert(processingCount >= 0),
        assert(failedCount >= 0);

  final int familyImageCount;
  final bool hasFamilyPrimary;
  final int exceptionCount;
  final int processingCount;
  final int failedCount;
}

@immutable
class Step7ReviewData {
  const Step7ReviewData({
    required this.productId,
    required this.familyName,
    required this.companyName,
    required this.categoryName,
    required this.productLayout,
    required this.structureLabel,
    required this.includedVariantCount,
    required this.excludedCombinationCount,
    required this.duplicateSkuCount,
    required this.presentations,
    required this.logisticsPackageCount,
    required this.contentNotApplicable,
    required this.contentComponentCount,
    required this.pricing,
    required this.images,
    this.requiredInformationComplete = true,
    this.mainImageRequired = true,
    this.initialStatus = Step7InitialStatus.active,
    this.inactiveVariantCount = 0,
    this.visibleInCatalog = true,
    this.visibleInNewOrder = true,
    this.additionalBlockingIssues = const [],
  })  : assert(includedVariantCount >= 0),
        assert(excludedCombinationCount >= 0),
        assert(duplicateSkuCount >= 0),
        assert(logisticsPackageCount >= 0),
        assert(contentComponentCount >= 0),
        assert(inactiveVariantCount >= 0),
        assert(inactiveVariantCount <= includedVariantCount);

  final String productId;
  final String familyName;
  final String companyName;
  final String categoryName;
  final Step7ProductLayout productLayout;

  /// Ejemplo: "Matriz diámetro × largo", "Lista de medidas" o
  /// "Producto único".
  final String structureLabel;

  /// Para producto único debe recibirse 1.
  final int includedVariantCount;
  final int excludedCombinationCount;
  final int duplicateSkuCount;

  final List<Step7PresentationReview> presentations;
  final int logisticsPackageCount;
  final bool contentNotApplicable;
  final int contentComponentCount;

  final Step7PricingReview pricing;
  final Step7ImagesReview images;

  final bool requiredInformationComplete;
  final bool mainImageRequired;

  final Step7InitialStatus initialStatus;
  final int inactiveVariantCount;
  final bool visibleInCatalog;
  final bool visibleInNewOrder;

  /// Permite agregar validaciones del dominio sin modificar este widget.
  final List<String> additionalBlockingIssues;

  bool get isSingleProduct => productLayout == Step7ProductLayout.single;

  int get sellableAssignmentCount {
    return presentations.fold<int>(
      0,
      (total, item) => total + item.assignedVariantCount,
    );
  }
}

@immutable
class Step7ValidationResult {
  const Step7ValidationResult({
    required this.blockers,
    required this.warnings,
  });

  factory Step7ValidationResult.fromReview(Step7ReviewData data) {
    final blockers = <String>[];
    final warnings = <String>[];

    if (!data.requiredInformationComplete) {
      blockers.add(
        'Falta información obligatoria de la familia o clasificación.',
      );
    }

    if (data.includedVariantCount == 0) {
      blockers.add(
        data.isSingleProduct
            ? 'El producto único todavía no tiene una estructura válida.'
            : 'No existe ninguna variante incluida para activar.',
      );
    }

    if (data.duplicateSkuCount > 0) {
      blockers.add(
        '${data.duplicateSkuCount} '
        '${data.duplicateSkuCount == 1 ? 'SKU duplicado debe' : 'SKU duplicados deben'} '
        'corregirse.',
      );
    }

    if (data.presentations.isEmpty ||
        data.sellableAssignmentCount == 0 ||
        data.pricing.totalCombinationCount == 0) {
      blockers.add('Falta al menos una presentación vendible.');
    }

    if (data.pricing.pendingCount > 0) {
      blockers.add(
        '${data.pricing.pendingCount} '
        '${data.pricing.pendingCount == 1 ? 'combinación de precio continúa' : 'combinaciones de precio continúan'} '
        'sin configurar.',
      );
    }

    final unexplainedPriceRows = data.pricing.totalCombinationCount -
        data.pricing.numericPriceCount -
        data.pricing.quoteCount -
        data.pricing.pendingCount;
    if (unexplainedPriceRows != 0) {
      blockers.add(
        'El resumen de precios no coincide con las combinaciones vendibles.',
      );
    }

    if (data.mainImageRequired && !data.images.hasFamilyPrimary) {
      blockers.add('Falta la imagen principal de la familia.');
    }

    if (data.images.processingCount > 0) {
      blockers.add(
        '${data.images.processingCount} '
        '${data.images.processingCount == 1 ? 'imagen continúa procesándose' : 'imágenes continúan procesándose'}.',
      );
    }

    if (data.images.failedCount > 0) {
      blockers.add(
        '${data.images.failedCount} '
        '${data.images.failedCount == 1 ? 'imagen tiene' : 'imágenes tienen'} '
        'un error pendiente.',
      );
    }

    blockers.addAll(
      data.additionalBlockingIssues
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
    );

    if (data.pricing.quoteCount > 0) {
      warnings.add(
        '${data.pricing.quoteCount} '
        '${data.pricing.quoteCount == 1 ? 'combinación está configurada' : 'combinaciones están configuradas'} '
        'como “Por cotizar”. Los pedidos que '
        '${data.pricing.quoteCount == 1 ? 'la incluyan quedarán' : 'las incluyan quedarán'} '
        'pendientes de cotización.',
      );
    }

    if (data.inactiveVariantCount > 0) {
      warnings.add(
        '${data.inactiveVariantCount} '
        '${data.inactiveVariantCount == 1 ? 'variante comenzará inactiva' : 'variantes comenzarán inactivas'}.',
      );
    }

    return Step7ValidationResult(
      blockers: List.unmodifiable(blockers),
      warnings: List.unmodifiable(warnings),
    );
  }

  final List<String> blockers;
  final List<String> warnings;

  bool get canActivate => blockers.isEmpty;

  Step7ReviewSeverity get severity {
    if (blockers.isNotEmpty) {
      return Step7ReviewSeverity.blocked;
    }
    if (warnings.isNotEmpty) {
      return Step7ReviewSeverity.warning;
    }
    return Step7ReviewSeverity.ready;
  }
}

@immutable
class Step7ActivationRequest {
  const Step7ActivationRequest({
    required this.productId,
    required this.confirmed,
    required this.validation,
  });

  final String productId;
  final bool confirmed;
  final Step7ValidationResult validation;
}

@immutable
class Step7ActivationResult {
  const Step7ActivationResult({
    required this.pendingSynchronization,
    this.message,
  });

  final bool pendingSynchronization;
  final String? message;
}

typedef Step7Activator = Future<Step7ActivationResult> Function(
  Step7ActivationRequest request,
);

class Step7ReviewActivatePanel extends StatefulWidget {
  const Step7ReviewActivatePanel({
    super.key,
    required this.review,
    required this.onBack,
    required this.onReviewStep,
    required this.onActivate,
    this.onActivated,
  });

  final Step7ReviewData review;
  final VoidCallback onBack;

  /// Recibe el número visible del paso (1 a 6), no el índice del PageView.
  final ValueChanged<int> onReviewStep;
  final Step7Activator onActivate;
  final ValueChanged<Step7ActivationResult>? onActivated;

  @override
  State<Step7ReviewActivatePanel> createState() =>
      _Step7ReviewActivatePanelState();
}

class _Step7ReviewActivatePanelState
    extends State<Step7ReviewActivatePanel> {
  static const Color _primary = Color(0xFFFFC500);
  static const Color _ink = Color(0xFF242830);
  static const Color _muted = Color(0xFF667085);
  static const Color _border = Color(0xFFD5DDE8);
  static const Color _canvas = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF16794A);
  static const Color _warning = Color(0xFF9A6700);
  static const Color _danger = Color(0xFFB42318);

  bool _confirmed = false;
  bool _activating = false;
  Step7ActivationResult? _activationResult;

  Step7ValidationResult get _validation =>
      Step7ValidationResult.fromReview(widget.review);

  bool get _canSubmit =>
      _validation.canActivate &&
      _confirmed &&
      !_activating &&
      _activationResult == null;

  @override
  void didUpdateWidget(covariant Step7ReviewActivatePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.review != widget.review) {
      _confirmed = false;
      _activationResult = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildValidationBanner(),
                  const SizedBox(height: 18),
                  _buildReviewGrid(),
                  const SizedBox(height: 18),
                  if (_activationResult == null)
                    _buildConfirmation()
                  else
                    _buildActivationSuccess(_activationResult!),
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
    final validation = _validation;
    final statusText = validation.canActivate
        ? 'Borrador · listo para activar'
        : 'Borrador · requiere correcciones';
    final statusColors = validation.canActivate
        ? const _Step7Tone(
            foreground: _ink,
            background: Color(0xFFFFF3C4),
            border: Color(0xFFFFE083),
          )
        : const _Step7Tone(
            foreground: _danger,
            background: Color(0xFFFFE9E7),
            border: Color(0xFFF7B8B2),
          );

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
              'Paso 7 · Revisar y activar',
              style: TextStyle(
                color: _ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Comprueba la información final y corrige cualquier bloqueo '
              'antes de activar el producto.',
              style: TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
        _pill(
          text: statusText,
          icon: validation.canActivate
              ? Icons.edit_note_outlined
              : Icons.error_outline,
          tone: statusColors,
        ),
      ],
    );
  }

  Widget _buildValidationBanner() {
    final validation = _validation;

    switch (validation.severity) {
      case Step7ReviewSeverity.ready:
        return _statusBanner(
          icon: Icons.check_circle_outline,
          title: 'Listo para activar',
          messages: const [
            'La información obligatoria está completa. El producto puede '
                'activarse.',
          ],
          tone: const _Step7Tone(
            foreground: _success,
            background: Color(0xFFE8F6EF),
            border: Color(0xFFB8E3CD),
          ),
        );
      case Step7ReviewSeverity.warning:
        return _statusBanner(
          icon: Icons.warning_amber_rounded,
          title: 'Listo para activar con advertencias',
          messages: validation.warnings,
          tone: const _Step7Tone(
            foreground: _warning,
            background: Color(0xFFFFF7DD),
            border: Color(0xFFF3D77A),
          ),
        );
      case Step7ReviewSeverity.blocked:
        return _statusBanner(
          icon: Icons.error_outline,
          title: 'Falta información obligatoria',
          messages: validation.blockers,
          tone: const _Step7Tone(
            foreground: _danger,
            background: Color(0xFFFFECEA),
            border: Color(0xFFF2BBB5),
          ),
        );
    }
  }

  Widget _statusBanner({
    required IconData icon,
    required String title,
    required List<String> messages,
    required _Step7Tone tone,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone.foreground, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tone.foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                for (var index = 0;
                    index < messages.length && index < 3;
                    index++) ...[
                  Text(
                    messages[index],
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      height: 1.42,
                    ),
                  ),
                  if (index < messages.length - 1 && index < 2)
                    const SizedBox(height: 3),
                ],
                if (messages.length > 3) ...[
                  const SizedBox(height: 3),
                  Text(
                    '+ ${messages.length - 3} '
                    '${messages.length - 3 == 1 ? 'corrección adicional' : 'correcciones adicionales'}',
                    style: TextStyle(
                      color: tone.foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewGrid() {
    final cards = _reviewCards;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1040
            ? 3
            : constraints.maxWidth >= 680
                ? 2
                : 1;
        final cardHeight = columns == 1 ? 216.0 : 202.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) {
            return _buildReviewCard(cards[index]);
          },
        );
      },
    );
  }

  List<_Step7CardData> get _reviewCards {
    final data = widget.review;
    final price = data.pricing;
    final images = data.images;

    final familyBlocked = !data.requiredInformationComplete;
    final structureBlocked =
        data.includedVariantCount == 0 || data.duplicateSkuCount > 0;
    final salesBlocked = data.presentations.isEmpty ||
        data.sellableAssignmentCount == 0 ||
        price.totalCombinationCount == 0;
    final priceBlocked = price.pendingCount > 0 ||
        price.readyCount + price.pendingCount !=
            price.totalCombinationCount;
    final imageBlocked = images.processingCount > 0 ||
        images.failedCount > 0 ||
        (data.mainImageRequired && !images.hasFamilyPrimary);

    return [
      _Step7CardData(
        title: 'Familia y clasificación',
        state: familyBlocked
            ? Step7CardState.blocked
            : Step7CardState.complete,
        lines: [
          '${data.companyName} · ${data.categoryName}',
          data.familyName,
        ],
        stepNumber: 1,
      ),
      _Step7CardData(
        title: 'Estructura',
        state: structureBlocked
            ? Step7CardState.blocked
            : Step7CardState.complete,
        lines: [
          data.structureLabel,
          data.isSingleProduct
              ? 'Producto único incluido'
              : '${data.includedVariantCount} variantes incluidas',
          if (data.excludedCombinationCount > 0)
            '${data.excludedCombinationCount} combinaciones excluidas',
          if (data.duplicateSkuCount > 0)
            '${data.duplicateSkuCount} SKU duplicados',
        ],
        stepNumber: data.isSingleProduct ? 2 : 3,
      ),
      _Step7CardData(
        title: 'Venta y logística',
        state:
            salesBlocked ? Step7CardState.blocked : Step7CardState.complete,
        lines: [
          'Presentaciones: ${_presentationSummary(data.presentations)}',
          'Empaques logísticos: ${data.logisticsPackageCount}',
          'Contenido del producto: ${data.contentNotApplicable ? 'No aplica' : '${data.contentComponentCount} ${data.contentComponentCount == 1 ? 'componente' : 'componentes'}'}',
        ],
        stepNumber: 4,
      ),
      _Step7CardData(
        title: 'Precios',
        state: priceBlocked
            ? Step7CardState.blocked
            : price.quoteCount > 0
                ? Step7CardState.warning
                : Step7CardState.complete,
        lines: [
          'Lista ${price.listName} · ${price.currencyCode} · '
              '${price.includesIgv ? 'incluye IGV' : 'sin IGV'}',
          '${price.numericPriceCount} con precio · '
              '${price.quoteCount} por cotizar',
          if (price.pendingCount > 0)
            '${price.pendingCount} pendientes',
        ],
        stepNumber: 5,
      ),
      _Step7CardData(
        title: 'Imágenes',
        state:
            imageBlocked ? Step7CardState.blocked : Step7CardState.complete,
        lines: [
          '${images.familyImageCount} '
              '${images.familyImageCount == 1 ? 'imagen de familia' : 'imágenes de familia'}',
          '${images.exceptionCount} '
              '${images.exceptionCount == 1 ? 'variante con excepción de imagen' : 'variantes con excepción de imagen'}',
          if (images.processingCount > 0)
            '${images.processingCount} procesándose',
          if (images.failedCount > 0)
            '${images.failedCount} con error',
        ],
        stepNumber: 6,
      ),
      _Step7CardData(
        title: 'Estado inicial',
        state: Step7CardState.willActivate,
        lines: [
          'Estado inicial: '
              '${data.initialStatus == Step7InitialStatus.active ? 'Activo' : 'Inactivo'}',
          _visibilityText(data),
          data.isSingleProduct
              ? 'El producto se mostrará'
              : '${data.includedVariantCount - data.inactiveVariantCount} '
                  '${data.includedVariantCount - data.inactiveVariantCount == 1 ? 'variante se mostrará' : 'variantes se mostrarán'}',
          if (data.inactiveVariantCount > 0)
            '${data.inactiveVariantCount} '
                '${data.inactiveVariantCount == 1 ? 'variante comenzará inactiva' : 'variantes comenzarán inactivas'}',
        ],
        stepNumber: 1,
      ),
    ];
  }

  Widget _buildReviewCard(_Step7CardData card) {
    final tone = _cardTone(card.state);
    final actionLabel =
        card.state == Step7CardState.blocked ? 'Corregir' : 'Revisar';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: card.state == Step7CardState.blocked
              ? tone.border
              : _border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  card.title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _pill(
                text: _cardStateText(card.state),
                icon: _cardStateIcon(card.state),
                tone: tone,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0;
                    index < card.lines.length && index < 4;
                    index++) ...[
                  Text(
                    card.lines[index],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: card.state == Step7CardState.blocked &&
                              index == card.lines.length - 1
                          ? _danger
                          : _muted,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: card.state == Step7CardState.blocked &&
                              index == card.lines.length - 1
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  if (index < card.lines.length - 1)
                    const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _activationResult == null
                  ? () => widget.onReviewStep(card.stepNumber)
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: _ink,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(
                card.state == Step7CardState.blocked
                    ? Icons.build_circle_outlined
                    : Icons.edit_outlined,
                size: 19,
              ),
              label: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    final blocked = !_validation.canActivate;

    return Semantics(
      container: true,
      checked: _confirmed,
      button: true,
      label:
          'Confirmo que la información, las presentaciones y los precios '
          'coinciden con el catálogo del proveedor.',
      child: Material(
        color: blocked
            ? const Color(0xFFF7F8FA)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _activating
              ? null
              : () {
                  setState(() {
                    _confirmed = !_confirmed;
                  });
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: blocked ? _border : _primary,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Checkbox(
                    value: _confirmed,
                    onChanged: _activating
                        ? null
                        : (value) {
                            setState(() {
                              _confirmed = value ?? false;
                            });
                          },
                    activeColor: _ink,
                    checkColor: Colors.white,
                    side: const BorderSide(color: _ink, width: 1.5),
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Confirmo que la información, las presentaciones y los '
                    'precios coinciden con el catálogo del proveedor.',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivationSuccess(Step7ActivationResult result) {
    final text = result.message?.trim().isNotEmpty == true
        ? result.message!.trim()
        : result.pendingSynchronization
            ? 'Activado en este dispositivo · Pendiente de sincronización'
            : 'Producto activado correctamente';

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB8E3CD)),
      ),
      child: Row(
        children: [
          Icon(
            result.pendingSynchronization
                ? Icons.cloud_upload_outlined
                : Icons.check_circle_outline,
            color: _success,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _success,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previousButton = _previousButton();
            final activateButton = _activateButton();

            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Paso 7 de 7',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  activateButton,
                  const SizedBox(height: 10),
                  previousButton,
                ],
              );
            }

            return Row(
              children: [
                previousButton,
                const Expanded(
                  child: Text(
                    'Paso 7 de 7',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 14,
                    ),
                  ),
                ),
                activateButton,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _previousButton() {
    return OutlinedButton(
      onPressed: _activating ? null : widget.onBack,
      style: OutlinedButton.styleFrom(
        foregroundColor: _ink,
        minimumSize: const Size(126, 48),
        side: const BorderSide(color: Color(0xFFABB8C8)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Anterior',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _activateButton() {
    return FilledButton(
      onPressed: _canSubmit ? _activate : null,
      style: FilledButton.styleFrom(
        backgroundColor: _ink,
        disabledBackgroundColor: const Color(0xFFD6DAE0),
        disabledForegroundColor: const Color(0xFF7A828D),
        minimumSize: const Size(168, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: _activating
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Text(
              _activationResult == null
                  ? 'Activar producto'
                  : 'Producto activado',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  Future<void> _activate() async {
    final validation = _validation;
    if (!validation.canActivate || !_confirmed || _activating) {
      return;
    }

    setState(() {
      _activating = true;
    });

    try {
      final result = await widget.onActivate(
        Step7ActivationRequest(
          productId: widget.review.productId,
          confirmed: _confirmed,
          validation: validation,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activationResult = result;
        _activating = false;
      });
      widget.onActivated?.call(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _activating = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo activar el producto. Revisa la conexión e '
              'inténtalo nuevamente.',
            ),
            backgroundColor: _danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  static String _presentationSummary(
    List<Step7PresentationReview> presentations,
  ) {
    if (presentations.isEmpty) {
      return 'Sin configurar';
    }
    return presentations
        .map((item) => '${item.name} (${item.assignedVariantCount})')
        .join(' · ');
  }

  static String _visibilityText(Step7ReviewData data) {
    if (data.visibleInCatalog && data.visibleInNewOrder) {
      return 'Visible en Catálogo y Nuevo pedido';
    }
    if (data.visibleInCatalog) {
      return 'Visible solamente en Catálogo';
    }
    if (data.visibleInNewOrder) {
      return 'Visible solamente en Nuevo pedido';
    }
    return 'No será visible en Catálogo ni Nuevo pedido';
  }

  static String _cardStateText(Step7CardState state) {
    switch (state) {
      case Step7CardState.complete:
        return 'Completo';
      case Step7CardState.warning:
        return 'Advertencia';
      case Step7CardState.blocked:
        return 'Corregir';
      case Step7CardState.willActivate:
        return 'Se activará';
    }
  }

  static IconData _cardStateIcon(Step7CardState state) {
    switch (state) {
      case Step7CardState.complete:
        return Icons.check_circle_outline;
      case Step7CardState.warning:
        return Icons.warning_amber_rounded;
      case Step7CardState.blocked:
        return Icons.error_outline;
      case Step7CardState.willActivate:
        return Icons.rocket_launch_outlined;
    }
  }

  static _Step7Tone _cardTone(Step7CardState state) {
    switch (state) {
      case Step7CardState.complete:
        return const _Step7Tone(
          foreground: _success,
          background: Color(0xFFE8F6EF),
          border: Color(0xFFB8E3CD),
        );
      case Step7CardState.warning:
        return const _Step7Tone(
          foreground: _warning,
          background: Color(0xFFFFF4CF),
          border: Color(0xFFF0D36C),
        );
      case Step7CardState.blocked:
        return const _Step7Tone(
          foreground: _danger,
          background: Color(0xFFFFE9E7),
          border: Color(0xFFF2BBB5),
        );
      case Step7CardState.willActivate:
        return const _Step7Tone(
          foreground: Color(0xFF175CD3),
          background: Color(0xFFEAF2FF),
          border: Color(0xFFBCD2F4),
        );
    }
  }

  static Widget _pill({
    required String text,
    required IconData icon,
    required _Step7Tone tone,
    bool compact = false,
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 32 : 40,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 11 : 15,
        vertical: compact ? 6 : 9,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 16 : 18,
            color: tone.foreground,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: tone.foreground,
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class _Step7Tone {
  const _Step7Tone({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

@immutable
class _Step7CardData {
  const _Step7CardData({
    required this.title,
    required this.state,
    required this.lines,
    required this.stepNumber,
  });

  final String title;
  final Step7CardState state;
  final List<String> lines;
  final int stepNumber;
}

// ============================================================================
// INTEGRACIÓN CON LOS PASOS ANTERIORES
//
// 1. Step4SalesDraft:
//    presentations -> Step7PresentationReview(name, assignedVariantIds.length)
//    logisticsPackages.length
//    hasProductContent != true -> contentNotApplicable
//    contentItems.length
//
// 2. PricingStep5Draft, para la lista seleccionada:
//    fixed/quantity listos -> numericPriceCount
//    quote -> quoteCount
//    unconfigured -> pendingCount
//    sellableCombinations.length -> totalCombinationCount
//
// 3. Step6ImagesDraft:
//    familyImages.length
//    familyPrimary != null
//    exceptions.length
//    processState processing/failed -> processingCount/failedCount
//
// 4. onReviewStep recibe 1, 2, 3, 4, 5 o 6. Si el PageView usa índices
//    desde cero, navega con: pageController.animateToPage(stepNumber - 1, ...).
//
// 5. El callback onActivate debe persistir el estado local primero. Cuando no
//    haya conexión devuelve:
//
//    const Step7ActivationResult(pendingSynchronization: true)
//
//    y la pantalla mostrará:
//    "Activado en este dispositivo · Pendiente de sincronización".
// ============================================================================

