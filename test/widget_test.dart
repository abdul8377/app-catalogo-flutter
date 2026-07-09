import 'package:app_catalogo/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la pantalla inicial de catalogo', (tester) async {
    await tester.pumpWidget(const AppCatalogo());
    await tester.pump();

    expect(find.text('Catalogo'), findsOneWidget);
    expect(find.text('Buscar productos'), findsOneWidget);
  });
}
