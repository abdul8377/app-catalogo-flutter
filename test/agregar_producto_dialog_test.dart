import 'package:app_catalogo/features/catalogo/domain/entities/catalogo_form_data.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/nuevo_producto.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_detalle.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_variante.dart';
import 'package:app_catalogo/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido.dart';
import 'package:app_catalogo/features/pedidos/presentation/widgets/agregar_producto_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la matriz conserva variante, presentación, lista y precio', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    PedidoItem? result;
    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _RepositoryFake(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  result = await AgregarProductoDialog.show(
                    context,
                    productoId: 'family',
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('pedido_eje_Largo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 in').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('pedido_eje_Diámetro')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3/8 in').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('cantidad_presentaciones')),
      '2',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('confirmar_agregar_producto')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.productoId, 'family');
    expect(result!.varianteId, 'var-4');
    expect(result!.varianteSku, 'PER-038X2');
    expect(result!.presentacionId, 'ciento');
    expect(result!.precioListaId, 'regular');
    expect(result!.cantidad, 2);
    expect(result!.precioUnitario, 40);
    expect(result!.atributosVariante['Largo'], '2 in');
    expect(result!.atributosVariante['Diámetro'], '3/8 in');
    expect(tester.takeException(), isNull);
  });
}

class _RepositoryFake implements CatalogoRepository {
  @override
  Future<ProductoDetalle?> obtenerDetalleProducto(
    String id,
  ) async => ProductoDetalle(
    id: 'family',
    codigo: 'PER-FAM',
    nombre: 'Perno hexagonal',
    descripcion: '',
    empresa: 'DINA',
    marca: 'DINA',
    categoria: 'Pernería',
    subcategoria: 'Pernos',
    tipoRegistro: 'matriz',
    atributos: const {'Material': 'Acero'},
    variantes: const [
      ProductoVariante(
        id: 'var-1',
        sku: 'PER-025X1',
        nombreCorto: 'Perno 1/4 × 1',
        atributos: [
          AtributoProductoVariante(nombre: 'Largo', valor: '1', unidad: 'in'),
          AtributoProductoVariante(
            nombre: 'Diámetro',
            valor: '1/4',
            unidad: 'in',
          ),
        ],
      ),
      ProductoVariante(
        id: 'var-2',
        sku: 'PER-038X1',
        nombreCorto: 'Perno 3/8 × 1',
        atributos: [
          AtributoProductoVariante(nombre: 'Largo', valor: '1', unidad: 'in'),
          AtributoProductoVariante(
            nombre: 'Diámetro',
            valor: '3/8',
            unidad: 'in',
          ),
        ],
      ),
      ProductoVariante(
        id: 'var-3',
        sku: 'PER-025X2',
        nombreCorto: 'Perno 1/4 × 2',
        atributos: [
          AtributoProductoVariante(nombre: 'Largo', valor: '2', unidad: 'in'),
          AtributoProductoVariante(
            nombre: 'Diámetro',
            valor: '1/4',
            unidad: 'in',
          ),
        ],
      ),
      ProductoVariante(
        id: 'var-4',
        sku: 'PER-038X2',
        nombreCorto: 'Perno 3/8 × 2',
        atributos: [
          AtributoProductoVariante(nombre: 'Largo', valor: '2', unidad: 'in'),
          AtributoProductoVariante(
            nombre: 'Diámetro',
            valor: '3/8',
            unidad: 'in',
          ),
        ],
      ),
    ],
    presentaciones: const [
      PresentacionProducto(nombre: 'Ciento', unidad: '100 UND'),
    ],
    precios: const [],
    ventaLogisticaContenido: const {
      'presentations': [
        {
          'id': 'ciento',
          'name': 'Ciento',
          'base_unit': 'UND',
          'equivalent_to': 100,
          'minimum_order': 1,
          'purchase_increment': 1,
          'assigned_variant_ids': ['var-1', 'var-2', 'var-3', 'var-4'],
          'default_variant_ids': ['var-1', 'var-2', 'var-3', 'var-4'],
          'variant_rules': [],
        },
      ],
    },
    preciosConfigurados: const {
      'lists': [
        {
          'id': 'regular',
          'name': 'Regular',
          'currency_code': 'PEN',
          'includes_igv': true,
        },
      ],
      'prices': [
        {
          'list_id': 'regular',
          'variant_id': 'var-1',
          'presentation_id': 'ciento',
          'configuration': 'fixed',
          'fixed_price': 10,
          'ranges': [],
        },
        {
          'list_id': 'regular',
          'variant_id': 'var-2',
          'presentation_id': 'ciento',
          'configuration': 'fixed',
          'fixed_price': 20,
          'ranges': [],
        },
        {
          'list_id': 'regular',
          'variant_id': 'var-3',
          'presentation_id': 'ciento',
          'configuration': 'fixed',
          'fixed_price': 30,
          'ranges': [],
        },
        {
          'list_id': 'regular',
          'variant_id': 'var-4',
          'presentation_id': 'ciento',
          'configuration': 'fixed',
          'fixed_price': 40,
          'ranges': [],
        },
      ],
    },
    activo: true,
    creadoEn: DateTime(2026),
  );

  @override
  Future<void> cambiarEstadoProducto(String id, {required bool activo}) async {}

  @override
  Future<List<ProductoResumen>> buscarProductos(String query) async => [];

  @override
  Future<CatalogoFormData> obtenerDatosFormulario() async =>
      const CatalogoFormData(
        empresas: [],
        marcas: [],
        subcategorias: {},
        atributos: {},
      );

  @override
  Future<List<ProductoResumen>> obtenerProductos() async => [];

  @override
  Future<void> guardarProducto(NuevoProducto producto) async {}

  @override
  Future<void> actualizarProducto(String id, NuevoProducto producto) async {}
}
