import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/catalogo_form_data.dart';
import '../../domain/entities/producto_variante.dart';
import '../bloc/producto_form/producto_form_bloc.dart';
import '../bloc/producto_form/producto_form_event.dart';
import '../bloc/producto_form/producto_form_state.dart';
import '../models/producto_form/precios_draft.dart';
import '../models/producto_form/venta_logistica_draft.dart';
import '../sections/producto_form/precios_section.dart';

class ProductoPreciosStep extends StatelessWidget {
  const ProductoPreciosStep({required this.state, super.key});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) {
    final combinations = _buildSellableCombinations();
    final saved = state.preciosConfigurados;

    return Step5PricingPanel(
      familyName: state.nombre.trim().isEmpty
          ? 'Familia sin nombre'
          : state.nombre.trim(),
      totalVariantCount: state.variantes.where((item) => item.activa).length,
      sellableCombinations: combinations,
      initialLists: saved?.lists ?? const [],
      initialPrices: saved?.prices ?? const [],
      onChanged: (draft) => context.read<ProductoFormBloc>().add(
        ProductoFormPreciosConfiguradosCambiados(draft),
      ),
      onBack: () => context.read<ProductoFormBloc>().add(
        const ProductoFormPasoAnterior(),
      ),
      onNext: (draft) => context.read<ProductoFormBloc>().add(
        ProductoFormPreciosConfiguradosCambiados(draft, continuar: true),
      ),
    );
  }

  List<SellablePriceCombination> _buildSellableCombinations() {
    final draft = state.ventaLogisticaContenido;
    if (draft != null) {
      return draft.presentations.expand((presentation) {
        return presentation.assignedVariantIds.map((variantId) {
          return _combinationFromPresentation(
            variantId: variantId,
            presentation: presentation,
          );
        });
      }).toList();
    }

    final variants = state.variantes.where((item) => item.activa).toList();
    final sourceVariants = variants.isEmpty ? state.variantes : variants;
    return state.presentaciones.asMap().entries.expand((entry) {
      final parsed = _parseLegacyUnit(entry.value);
      return sourceVariants.map(
        (variant) => SellablePriceCombination(
          variantId: variant.id,
          variantLabel: _variantLabel(variant),
          presentationId: 'presentacion-existente-${entry.key}',
          presentationLabel: entry.value.nombre,
          baseUnit: parsed.$2,
          equivalentToBaseUnit: parsed.$1,
        ),
      );
    }).toList();
  }

  SellablePriceCombination _combinationFromPresentation({
    required String variantId,
    required SalesPresentationDraft presentation,
  }) {
    final variant = state.variantes
        .where((item) => item.id == variantId)
        .firstOrNull;
    final rule = presentation.ruleFor(variantId);
    return SellablePriceCombination(
      variantId: variantId,
      variantLabel: variant == null ? variantId : _variantLabel(variant),
      presentationId: presentation.id,
      presentationLabel: presentation.name,
      baseUnit: presentation.baseUnit,
      equivalentToBaseUnit: rule.equivalentTo,
      minimumOrder: rule.minimumOrder,
      purchaseIncrement: rule.purchaseIncrement,
    );
  }

  String _variantLabel(ProductoVariante variant) {
    if (variant.nombreCorto.trim().isNotEmpty) {
      return variant.nombreCorto.trim();
    }
    if (variant.sku.trim().isNotEmpty) return variant.sku.trim();
    return variant.id;
  }

  (double, String) _parseLegacyUnit(PresentacionProducto presentation) {
    final source = presentation.unidad.trim();
    final match = RegExp(
      r'^([0-9]+(?:[.,][0-9]+)?)\s+(.+)$',
    ).firstMatch(source);
    final quantity =
        double.tryParse(match?.group(1)?.replaceAll(',', '.') ?? '') ?? 1;
    final unit = (match?.group(2) ?? source).trim().toUpperCase();
    return (quantity, unit.isEmpty ? 'PZA' : unit);
  }
}
