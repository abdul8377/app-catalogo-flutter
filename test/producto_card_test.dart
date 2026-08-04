import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/producto_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el botón Editar ejecuta su acción', (tester) async {
    var editarPresionado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 350,
            height: 540,
            child: ProductoCard(
              producto: const ProductoResumen(
                id: '1',
                codigo: 'PER-001',
                nombre: 'Perno hexagonal',
                empresa: 'DINA',
                marca: 'DINA',
                categoria: 'Pernería',
                unidadVenta: 'Ciento',
                precio: 18,
                sinPrecio: false,
                activo: true,
                tipoRegistro: 'unico',
                atributosClave: ['Rosca: RF'],
              ),
              isGrid: true,
              onVerDetalle: () {},
              onEditar: () => editarPresionado = true,
              onCambiarEstado: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(editarPresionado, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la tarjeta vendible solo muestra Ver y Agregar', (tester) async {
    var agregado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 350,
            height: 520,
            child: ProductoCard(
              producto: const ProductoResumen(
                id: 'venta',
                codigo: 'PER-002',
                nombre: 'Perno para pedido',
                empresa: 'DINA',
                marca: 'DINA',
                categoria: 'Pernería',
                unidadVenta: 'Ciento',
                precio: 20,
                sinPrecio: false,
                activo: true,
                tipoRegistro: 'unico',
                atributosClave: [],
              ),
              isGrid: true,
              onVerDetalle: () {},
              onAgregar: () => agregado = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Editar'), findsNothing);
    expect(find.text('Desactivar'), findsNothing);
    expect(find.text('SKU: PER-002'), findsOneWidget);
    expect(find.text('Activo'), findsOneWidget);
    await tester.tap(find.text('Agregar'));
    expect(agregado, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'la imagen ocupa el cuadro un 20% más alto',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 580,
              child: ProductoCard(
                producto: const ProductoResumen(
                  id: 'imagen',
                  codigo: 'IMG-001',
                  nombre: 'Producto con imagen',
                  empresa: 'DINA',
                  marca: 'DINA',
                  categoria: 'Pernería',
                  unidadVenta: 'Unidad',
                  precio: 10,
                  sinPrecio: false,
                  activo: true,
                  tipoRegistro: 'unico',
                  atributosClave: [],
                  imagenPath: 'imagen-no-disponible.jpg',
                ),
                isGrid: true,
                onVerDetalle: () {},
                onAgregar: () {},
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('producto_imagen_imagen'))).height,
        228,
      );
      expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
    },
    tags: const ['baseline-known-failure'],
  );
}
