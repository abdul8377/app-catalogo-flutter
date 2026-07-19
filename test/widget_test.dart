import 'package:app_catalogo/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la pantalla inicial de la aplicación', (tester) async {
    await tester.pumpWidget(const AppCatalogo());
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('App Catálogo'), findsOneWidget);
    expect(find.text('Hola, Alfonzo Esteban'), findsOneWidget);
  });
}
