import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo_state.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/filtros_catalogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('los diálogos de filtros funcionan en pantalla angosta', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    CatalogoFiltros? resultado;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FiltrosCatalogo(
            state: CatalogoState.initial().copyWith(loading: false),
            onBusquedaCambiada: (_) {},
            onFiltroRapido: (_) {},
            onFiltrosAplicados: (value) => resultado = value,
            onFiltrosLimpiados: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('abrir_filtros_avanzados')));
    await tester.pumpAndSettle();
    expect(find.text('Filtros avanzados'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Limpiar todo'));
    await tester.pumpAndSettle();
    expect(resultado, const CatalogoFiltros());

    await tester.tap(find.byKey(const Key('abrir_ordenamiento')));
    await tester.pumpAndSettle();
    expect(find.text('Ordenar productos'), findsOneWidget);
    await tester.tap(find.text('Más recientes'));
    await tester.pumpAndSettle();
    expect(resultado?.orden, 'Más recientes');
    expect(tester.takeException(), isNull);
  });
}
