import 'package:app_catalogo/features/catalogo/presentation/widgets/paso5_precios_corregido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el botón para ir a imágenes queda dentro de SafeArea', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Step5PricingPanel(
            familyName: 'Pernos',
            totalVariantCount: 1,
            sellableCombinations: const [
              SellablePriceCombination(
                variantId: 'variant-1',
                variantLabel: 'Perno 1/4',
                presentationId: 'presentation-1',
                presentationLabel: 'Caja',
                baseUnit: 'UND',
                equivalentToBaseUnit: 100,
              ),
            ],
            onBack: () {},
            onNext: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('precios_footer_safe_area')), findsOneWidget);
    expect(find.text('Siguiente: imágenes'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Siguiente: imágenes'),
        matching: find.byType(SafeArea),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
