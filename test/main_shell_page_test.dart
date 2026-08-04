import 'package:app_catalogo/app/navigation/main_shell_page.dart';
import 'package:app_catalogo/core/navigation/app_destination.dart';
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

  testWidgets('el rail administrador conserva el mapeo público 0 a 7', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selectedIndexes = <int>[];

    await _pumpExpandedRail(
      tester,
      isAdministrator: true,
      onItemSelected: selectedIndexes.add,
    );

    for (final label in _administratorLabels) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    expect(selectedIndexes, List<int>.generate(8, (index) => index));
    expect(find.text('Estructura del catálogo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el rail vendedor conserva 0 a 6 y oculta solo administración', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selectedIndexes = <int>[];

    await _pumpExpandedRail(
      tester,
      isAdministrator: false,
      onItemSelected: selectedIndexes.add,
    );

    for (final label in _administratorLabels.take(7)) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    expect(selectedIndexes, List<int>.generate(7, (index) => index));
    expect(find.text('Estructura del catálogo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el rail admite permisos no contiguos e identidad dinámica', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selectedIndexes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AppNavigationRail(
                isExpanded: true,
                selectedIndex: AppDestination.home.navigationIndex,
                onItemSelected: selectedIndexes.add,
                onToggleExpansion: () {},
                allowedDestinations: const <AppDestination>{
                  AppDestination.home,
                  AppDestination.dashboard,
                },
                userName: 'Supervisora Norte',
                roleLabel: 'Supervisora regional',
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Catálogo'), findsNothing);
    expect(find.text('Supervisora Norte'), findsOneWidget);
    expect(find.text('Supervisora regional'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pump();
    expect(selectedIndexes, [AppDestination.dashboard.navigationIndex]);
  });
}

const _administratorLabels = <String>[
  'Inicio',
  'Catálogo',
  'Clientes',
  'Nuevo pedido',
  'Pedidos',
  'Hojas de pedido',
  'Dashboard',
  'Estructura del catálogo',
];

Future<void> _pumpExpandedRail(
  WidgetTester tester, {
  required bool isAdministrator,
  required ValueChanged<int> onItemSelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            AppNavigationRail(
              isExpanded: true,
              selectedIndex: 0,
              onItemSelected: onItemSelected,
              onToggleExpansion: () {},
              isAdministrator: isAdministrator,
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
