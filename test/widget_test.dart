import 'package:app_catalogo/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la pantalla inicial de la aplicación', (tester) async {
    await tester.pumpWidget(const AppCatalogo());
    await tester.pumpAndSettle();

    expect(find.text('App Catálogo'), findsOneWidget);
    expect(find.textContaining('Hola,'), findsOneWidget);
  });
}
