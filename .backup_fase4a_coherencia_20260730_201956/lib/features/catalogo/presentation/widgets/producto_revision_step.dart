import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/producto_form_bloc.dart';
import '../bloc/producto_form_event.dart';
import '../bloc/producto_form_state.dart';
import 'paso5_precios_corregido.dart';
import 'paso6_imagenes_corregido.dart';
import 'paso7_revisar_activar_corregido.dart';

class ProductoRevisionStep extends StatelessWidget {
  const ProductoRevisionStep({required this.state, super.key});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => Step7ReviewActivatePanel(
    review: _review,
    onBack: () =>
        context.read<ProductoFormBloc>().add(const ProductoFormPasoAnterior()),
    onReviewStep: (stepNumber) => context.read<ProductoFormBloc>().add(
      ProductoFormPasoSeleccionado(stepNumber - 1),
    ),
    onActivate: (request) {
      final completer = Completer<Step7ActivationResult>();
      context.read<ProductoFormBloc>().add(
        ProductoFormActivadoDesdeRevision(
          request: request,
          completer: completer,
        ),
      );
      return completer.future;
    },
  );

  Step7ReviewData get _review {
    final activeVariants = state.variantes
        .where((variant) => variant.activa)
        .toList();
    final duplicateSkuCount = _duplicateSkuCount(state);
    final sales = state.ventaLogisticaContenido;
    final pricing = state.preciosConfigurados;
    final images = state.imagenesConfiguradas;
    final primaryList = pricing?.lists.firstOrNull;
    final listPrices = primaryList == null
        ? const <ProductPriceDraft>[]
        : pricing!.prices
              .where((price) => price.listId == primaryList.id)
              .toList();

    return Step7ReviewData(
      productId: state.productoId ?? 'borrador-local',
      familyName: state.nombre.trim().isEmpty
          ? 'Familia sin nombre'
          : state.nombre.trim(),
      companyName: state.empresa ?? 'Sin empresa',
      categoryName: [state.categoria, state.subcategoria]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(' › '),
      productLayout: switch (state.tipoRegistro) {
        'matriz' => Step7ProductLayout.variantMatrix,
        'variantes' => Step7ProductLayout.variantList,
        _ => Step7ProductLayout.single,
      },
      structureLabel: switch (state.tipoRegistro) {
        'matriz' => 'Matriz de variantes',
        'variantes' => 'Lista de variantes',
        _ => 'Producto único',
      },
      includedVariantCount: state.variantes.length,
      excludedCombinationCount: 0,
      duplicateSkuCount: duplicateSkuCount,
      presentations: sales == null
          ? state.presentaciones
                .map(
                  (item) => Step7PresentationReview(
                    name: item.nombre,
                    assignedVariantCount: activeVariants.length,
                  ),
                )
                .toList()
          : sales.presentations
                .map(
                  (item) => Step7PresentationReview(
                    name: item.name,
                    assignedVariantCount: item.assignedVariantIds.length,
                  ),
                )
                .toList(),
      logisticsPackageCount: sales?.logisticsPackages.length ?? 0,
      contentNotApplicable: sales?.hasProductContent != true,
      contentComponentCount: sales?.contentItems.length ?? 0,
      pricing: Step7PricingReview(
        listName: primaryList?.name ?? 'Lista principal',
        currencyCode: primaryList?.currencyCode ?? 'PEN',
        includesIgv: primaryList?.includesIgv ?? true,
        totalCombinationCount:
            pricing?.sellableCombinations.length ??
            state.presentaciones.length * activeVariants.length,
        numericPriceCount: pricing == null
            ? state.precios.length
            : listPrices.where((price) => price.hasNumericPrice).length,
        quoteCount: listPrices
            .where(
              (price) => price.configuration == PriceConfigurationType.quote,
            )
            .length,
        pendingCount: pricing == null
            ? (state.precios.isEmpty ? state.presentaciones.length : 0)
            : listPrices.where((price) => !price.isReady).length,
      ),
      images: Step7ImagesReview(
        familyImageCount:
            images?.familyImages.length ?? state.imagenesPaths.length,
        hasFamilyPrimary:
            images?.familyPrimary != null || state.imagenesPaths.isNotEmpty,
        exceptionCount: images?.exceptions.length ?? 0,
        processingCount: images == null
            ? 0
            : _imageCount(images, Step6ImageProcessState.processing),
        failedCount: images == null
            ? 0
            : _imageCount(images, Step6ImageProcessState.failed),
      ),
      requiredInformationComplete:
          state.empresa != null &&
          state.marca != null &&
          state.categoria != null &&
          (!state.subcategoriaRequerida || state.subcategoria != null) &&
          state.nombre.trim().isNotEmpty,
      initialStatus: Step7InitialStatus.active,
      inactiveVariantCount: state.variantes.length - activeVariants.length,
      visibleInCatalog: true,
      visibleInNewOrder: true,
      additionalBlockingIssues: [
        if (state.edicionVariantePendiente)
          'Guarda o cancela los cambios pendientes de la variante.',
        if (!state.variantesCompletas)
          'Completa el SKU y el nombre de todas las variantes.',
        if (activeVariants.isEmpty)
          'Activa al menos una variante antes de activar el producto.',
      ],
    );
  }

  static int _duplicateSkuCount(ProductoFormState state) {
    final counts = <String, int>{};
    for (final variant in state.variantes) {
      final sku = variant.sku.trim().toUpperCase();
      if (sku.isEmpty) continue;
      counts[sku] = (counts[sku] ?? 0) + 1;
    }
    return counts.values
        .where((count) => count > 1)
        .fold(0, (total, count) => total + count);
  }

  static int _imageCount(
    Step6ImagesDraft draft,
    Step6ImageProcessState state,
  ) => [
    ...draft.familyImages,
    ...draft.variantSpecificImages,
  ].where((image) => image.processState == state).length;
}
