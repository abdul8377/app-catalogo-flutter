import 'package:app_catalogo/features/hojas_pedido/presentation/dialogs/crear_hoja_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('acepta el vendedor inyectado sin cambiar el formulario', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CrearHojaDialog(
            codigoSugerido: 'HP-2026-001',
            vendedorInicial: 'Vendedora Norte',
          ),
        ),
      ),
    );

    expect(find.text('Vendedora Norte'), findsOneWidget);
    expect(find.text('Vendedor responsable *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
