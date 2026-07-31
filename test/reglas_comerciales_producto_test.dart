import 'package:flutter_test/flutter_test.dart';

import 'package:app_catalogo/features/catalogo/presentation/widgets/paso4_venta_logistica_contenido.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/paso5_precios_corregido.dart';

void main() {
  test('una presentación resuelve excepciones por variante', () {
    const presentation = SalesPresentationDraft(
      id: 'empaque',
      name: 'Empaque',
      baseUnit: 'PZA',
      equivalentTo: 10,
      minimumOrder: 1,
      purchaseIncrement: 1,
      allowsDecimals: false,
      assignedVariantIds: {'v1', 'v2'},
      defaultVariantIds: {'v1', 'v2'},
      variantRules: {
        'v2': SalesPresentationVariantRule(
          variantId: 'v2',
          equivalentTo: 5,
          minimumOrder: 2,
          purchaseIncrement: 2,
        ),
      },
    );

    expect(presentation.ruleFor('v1').equivalentTo, 10);
    expect(presentation.ruleFor('v2').equivalentTo, 5);
    expect(presentation.ruleFor('v2').minimumOrder, 2);
  });

  test('las reglas comerciales se serializan y restauran', () {
    const draft = Step4SalesDraft(
      presentations: [
        SalesPresentationDraft(
          id: 'caja',
          name: 'Caja',
          baseUnit: 'PZA',
          equivalentTo: 20,
          minimumOrder: 1,
          purchaseIncrement: 1,
          allowsDecimals: false,
          assignedVariantIds: {'v1'},
          defaultVariantIds: {'v1'},
          variantRules: {
            'v1': SalesPresentationVariantRule(
              variantId: 'v1',
              equivalentTo: 12,
              minimumOrder: 1,
              purchaseIncrement: 1,
            ),
          },
        ),
      ],
      usesLogisticsPackages: false,
      logisticsPackages: [],
      hasProductContent: false,
      contentItems: [],
    );

    final restored = step4SalesDraftFromMap(step4SalesDraftToMap(draft));
    expect(restored?.presentations.single.ruleFor('v1').equivalentTo, 12);
  });

  test(
    'activar requiere que todas las listas seleccionadas estén completas',
    () {
      final draft = PricingStep5Draft(
        lists: [
          PriceListDraft(
            id: 'regular',
            name: 'Regular',
            currencyCode: 'PEN',
            includesIgv: true,
            validFrom: DateTime(2026),
          ),
          PriceListDraft(
            id: 'mayorista',
            name: 'Mayorista',
            currencyCode: 'PEN',
            includesIgv: true,
            validFrom: DateTime(2026),
          ),
        ],
        prices: const [
          ProductPriceDraft(
            listId: 'regular',
            variantId: 'v1',
            presentationId: 'unidad',
            configuration: PriceConfigurationType.fixed,
            fixedPrice: 10,
          ),
          ProductPriceDraft(
            listId: 'mayorista',
            variantId: 'v1',
            presentationId: 'unidad',
            configuration: PriceConfigurationType.unconfigured,
          ),
        ],
        sellableCombinations: const [
          SellablePriceCombination(
            variantId: 'v1',
            variantLabel: 'Producto',
            presentationId: 'unidad',
            presentationLabel: 'Unidad',
            baseUnit: 'PZA',
            equivalentToBaseUnit: 1,
          ),
        ],
      );

      expect(draft.canActivate('regular'), isTrue);
      expect(draft.canActivate('mayorista'), isFalse);
    },
  );
}
