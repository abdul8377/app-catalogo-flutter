import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/producto_form/producto_form_bloc.dart';
import '../bloc/producto_form/producto_form_event.dart';
import '../bloc/producto_form/producto_form_state.dart';
import '../models/producto_form/imagenes_draft.dart';
import '../models/producto_form/precios_draft.dart';
import '../models/producto_form/revision_draft.dart';
import '../sections/producto_form/revision_section.dart';

class ProductoRevisionStep extends StatelessWidget {
  const ProductoRevisionStep({required this.state, super.key});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => Step7ReviewActivatePanel(
    review: _review,
    onBack: () =>
        context.read<ProductoFormBloc>().add(const ProductoFormPasoAnterior()),
    onReviewStep: (stepNumber) {
      const internalSteps = ProductoFormState.pasosFlujo;
      final index = stepNumber - 1;
      if (index < 0 || index >= internalSteps.length) return;
      context.read<ProductoFormBloc>().add(
        ProductoFormPasoSeleccionado(internalSteps[index]),
      );
    },
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
    final configuredLists = pricing?.lists ?? const <PriceListDraft>[];
    final listPrices = pricing?.prices ?? const <ProductPriceDraft>[];

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
      excludedCombinationCount: state.matrizCombinacionesExcluidas,
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
        listName: configuredLists.isEmpty
            ? 'Sin listas'
            : '${configuredLists.length} listas',
        currencyCode:
            configuredLists.map((list) => list.currencyCode).toSet().length == 1
            ? configuredLists.first.currencyCode
            : 'Múltiple',
        includesIgv:
            configuredLists.isNotEmpty &&
            configuredLists.every((list) => list.includesIgv),
        totalCombinationCount:
            pricing?.prices.length ??
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
        listSummaries: configuredLists.map((list) {
          final pricesForList = listPrices
              .where((price) => price.listId == list.id)
              .toList();
          final pending = pricesForList.where((price) => !price.isReady).length;
          return '${list.name} · ${list.currencyCode} · '
              '${list.includesIgv ? 'Con IGV' : 'Sin IGV'} · '
              '${pricesForList.length - pending}/${pricesForList.length} combinaciones listas';
        }).toList(),
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
          state.nombre.trim().isNotEmpty &&
          state.atributosFamiliaCompletos,
      initialStatus: state.activo
          ? Step7InitialStatus.active
          : Step7InitialStatus.inactive,
      inactiveVariantCount: state.variantes.length - activeVariants.length,
      visibleInCatalog: state.activo,
      visibleInNewOrder: state.activo,
      additionalBlockingIssues: [
        if (state.edicionVariantePendiente)
          'Guarda o cancela los cambios pendientes de la variante.',
        if (!state.variantesCompletas)
          'Completa el código interno y el nombre de todas las variantes.',
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
