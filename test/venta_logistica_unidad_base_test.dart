import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_catalogo/features/catalogo/presentation/models/producto_form/venta_logistica_draft.dart';
import 'package:app_catalogo/features/catalogo/presentation/sections/producto_form/venta_logistica_section.dart';

void main() {
  testWidgets('una presentacion importada con UND no rompe el dropdown', (
    tester,
  ) async {
    const variant = Step4VariantOption(id: 'v1', label: 'Unidad');
    const presentation = SalesPresentationDraft(
      id: 'p1',
      name: 'Unidad',
      baseUnit: 'UND',
      equivalentTo: 1,
      minimumOrder: 1,
      purchaseIncrement: 1,
      allowsDecimals: false,
      assignedVariantIds: {'v1'},
      defaultVariantIds: {'v1'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Step4SalesLogisticsContentPanel(
            familyName: 'Producto de prueba',
            variantLayout: Step4VariantLayout.single,
            variants: const [variant],
            initialPresentations: const [presentation],
            onBack: () {},
            onNext: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('UND'), findsWidgets);
  });
}
