import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/catalogo_form_data.dart';
import '../../domain/entities/producto_variante.dart';
import '../bloc/producto_form_bloc.dart';
import '../bloc/producto_form_event.dart';
import '../bloc/producto_form_state.dart';
import 'paso4_venta_logistica_contenido.dart';

class ProductoVentaLogisticaStep extends StatelessWidget {
  const ProductoVentaLogisticaStep({required this.state, super.key});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) {
    final variants = _buildVariants();
    final initialDraft =
        state.ventaLogisticaContenido ?? _legacyDraft(variants);

    return Step4SalesLogisticsContentPanel(
      familyName: state.nombre.trim().isEmpty
          ? 'Familia sin nombre'
          : state.nombre.trim(),
      variantLayout: switch (state.tipoRegistro) {
        'unico' => Step4VariantLayout.single,
        'matriz' => Step4VariantLayout.matrix,
        _ => Step4VariantLayout.list,
      },
      variants: variants,
      initialPresentations: initialDraft.presentations,
      initialLogisticsPackages: initialDraft.logisticsPackages,
      initialContentItems: initialDraft.contentItems,
      initialUsesLogisticsPackages: initialDraft.usesLogisticsPackages,
      initialHasProductContent: initialDraft.hasProductContent,
      catalogVariants: variants
          .map(
            (variant) =>
                CatalogVariantOption(id: variant.id, label: variant.label),
          )
          .toList(),
      onChanged: (draft) => context.read<ProductoFormBloc>().add(
        ProductoFormVentaLogisticaCambiada(draft),
      ),
      onBack: () => context.read<ProductoFormBloc>().add(
        const ProductoFormPasoAnterior(),
      ),
      onNext: (draft) => context.read<ProductoFormBloc>().add(
        ProductoFormVentaLogisticaCambiada(draft, continuar: true),
      ),
    );
  }

  List<Step4VariantOption> _buildVariants() {
    final active = state.variantes.where((variant) => variant.activa).toList();
    final source = active.isEmpty ? state.variantes : active;
    if (source.isEmpty) {
      return [
        Step4VariantOption(
          id: 'variante-temporal',
          label: state.nombre.trim().isEmpty
              ? 'Variante del producto'
              : state.nombre.trim(),
        ),
      ];
    }

    return source.asMap().entries.map((entry) {
      final variant = entry.value;
      final attributes = variant.atributos
          .where((attribute) => attribute.texto.isNotEmpty)
          .toList();
      return Step4VariantOption(
        id: variant.id,
        label: _variantLabel(variant, entry.key),
        rowValue: state.tipoRegistro == 'matriz' && attributes.isNotEmpty
            ? attributes.first.texto
            : null,
        columnValue: state.tipoRegistro == 'matriz' && attributes.length > 1
            ? attributes[1].texto
            : null,
      );
    }).toList();
  }

  String _variantLabel(ProductoVariante variant, int index) {
    if (variant.nombreCorto.trim().isNotEmpty) {
      return variant.nombreCorto.trim();
    }
    if (variant.sku.trim().isNotEmpty) return variant.sku.trim();
    return 'Variante ${index + 1}';
  }

  Step4SalesDraft _legacyDraft(List<Step4VariantOption> variants) {
    final variantIds = variants.map((variant) => variant.id).toSet();
    final presentations = state.presentaciones.asMap().entries.map((entry) {
      final parsedUnit = _parseLegacyUnit(entry.value);
      return SalesPresentationDraft(
        id: 'presentacion-existente-${entry.key}',
        name: entry.value.nombre,
        baseUnit: parsedUnit.$2,
        equivalentTo: parsedUnit.$1,
        minimumOrder: 1,
        purchaseIncrement: 1,
        allowsDecimals: false,
        assignedVariantIds: variantIds,
        defaultVariantIds: entry.key == 0 ? variantIds : const {},
      );
    }).toList();

    return Step4SalesDraft(
      presentations: presentations,
      usesLogisticsPackages: null,
      logisticsPackages: const [],
      hasProductContent: null,
      contentItems: const [],
    );
  }

  (double, String) _parseLegacyUnit(PresentacionProducto presentation) {
    final source = presentation.unidad.trim();
    final match = RegExp(
      r'^([0-9]+(?:[.,][0-9]+)?)\s+(.+)$',
    ).firstMatch(source);
    final quantity =
        double.tryParse(match?.group(1)?.replaceAll(',', '.') ?? '') ?? 1;
    final unit = (match?.group(2) ?? source).trim().toUpperCase();
    const supported = {'PZA', 'M', 'KG', 'JGO', 'ROLLO', 'CAJA', 'PAR', 'L'};
    return (quantity, supported.contains(unit) ? unit : 'PZA');
  }
}
