import 'package:app_catalogo/app/navigation/main_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la barra lateral no desborda mientras se expande', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AppNavigationRail(
                isExpanded: false,
                selectedIndex: 0,
                onItemSelected: (_) {},
                onToggleExpansion: () {},
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AppNavigationRail(
                isExpanded: true,
                selectedIndex: 0,
                onItemSelected: (_) {},
                onToggleExpansion: () {},
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Estructura del catálogo'), findsOneWidget);
    expect(find.text('Alfonzo Esteban'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
