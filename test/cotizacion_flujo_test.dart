import 'package:app_catalogo/features/pedidos/presentation/widgets/cotizacion_totales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el descuento combinado nunca supera el subtotal', () {
    const value = CotizacionTotalesValue(
      descuentoGlobalPorcentaje: 80,
      descuentoGlobalMonto: 500,
      observaciones: '',
      vigenciaDias: 15,
      condiciones: 'Pago contra entrega',
    );

    expect(value.descuentoGeneralSobre(100), 100);
    expect(value.vigenciaDias, 15);
    expect(value.condiciones, 'Pago contra entrega');
  });

  testWidgets('el resumen usa un total claro y condiciones comerciales', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    CotizacionTotalesValue? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CotizacionTotales(
            subtotalProductos: 118,
            descuentosProductos: 0,
            value: const CotizacionTotalesValue(
              descuentoGlobalPorcentaje: 0,
              descuentoGlobalMonto: 0,
              observaciones: '',
            ),
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );

    expect(find.text('Total de cotización'), findsOneWidget);
    expect(find.textContaining('incluye IGV'), findsNothing);
    expect(find.byKey(const Key('cotizacion_vigencia_dias')), findsOneWidget);
    expect(find.byKey(const Key('cotizacion_condiciones')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('cotizacion_vigencia_dias')),
      '30',
    );
    await tester.enterText(
      find.byKey(const Key('cotizacion_condiciones')),
      'Pago a 15 días',
    );
    await tester.pump();

    expect(changed?.vigenciaDias, 30);
    expect(changed?.condiciones, 'Pago a 15 días');
    expect(tester.takeException(), isNull);
  });
}
