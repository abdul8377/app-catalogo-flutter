import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/producto_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'la tarjeta resume presentaciones sin desbordar en su altura real',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const product = ProductoResumen(
        id: 'product-1',
        codigo: 'BRO-001',
        nombre: 'Broca HSS larga para metal',
        empresa: 'UYUSTOOLS',
        marca: 'UYUSTOOLS',
        categoria: 'Accesorios',
        subcategoria: 'Brocas',
        unidadVenta: 'Unidad',
        precio: 25,
        sinPrecio: false,
        activo: true,
        tipoRegistro: 'variantes',
        atributosClave: [],
        presentaciones: [
          'Unidad',
          'Blíster',
          'Paquete',
          'Caja',
          'Docena',
          'Ciento',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 520,
                child: ProductoCard(
                  producto: product,
                  isGrid: true,
                  onVerDetalle: () {},
                  onAgregar: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('+3 más'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const Key('producto_imagen_product-1')))
            .height,
        212,
      );
      final cardBottom = tester.getBottomRight(find.byType(ProductoCard)).dy;
      final buttonBottom = tester.getBottomRight(find.text('Agregar')).dy;
      expect(cardBottom - buttonBottom, lessThan(34));
      expect(find.text('Agregar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
