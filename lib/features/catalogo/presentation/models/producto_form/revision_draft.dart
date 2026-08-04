import 'package:flutter/foundation.dart';

enum Step7ProductLayout { single, variantList, variantMatrix }

enum Step7InitialStatus { active, inactive }

enum Step7ReviewSeverity { ready, warning, blocked }

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
    this.listSummaries = const [],
  }) : assert(totalCombinationCount >= 0),
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
  final List<String> listSummaries;

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
  }) : assert(familyImageCount >= 0),
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
  }) : assert(includedVariantCount >= 0),
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
  const Step7ValidationResult({required this.blockers, required this.warnings});

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
        '${data.duplicateSkuCount == 1 ? 'código interno duplicado debe' : 'códigos internos duplicados deben'} '
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

    final unexplainedPriceRows =
        data.pricing.totalCombinationCount -
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

typedef Step7Activator =
    Future<Step7ActivationResult> Function(Step7ActivationRequest request);
