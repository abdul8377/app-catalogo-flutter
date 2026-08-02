import 'package:app_catalogo/features/catalogo/domain/entities/catalogo_form_data.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/nuevo_producto.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_detalle.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_variante.dart';
import 'package:app_catalogo/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/producto_detalle_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la ficha de matriz muestra combinaciones y precios exactos', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var edited = false;
    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _DetalleRepositoryFake(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => ProductoDetalleDialog.show(
                  context,
                  productoId: '1',
                  onEditar: (_) => edited = true,
                  onCambiarEstado: (_) {},
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Ficha del producto'), findsOneWidget);
    expect(find.text('Perno hexagonal métrico'), findsOneWidget);
    expect(find.text('Matriz de variantes'), findsWidgets);
    expect(find.textContaining('Filas: Largo'), findsOneWidget);
    expect(find.textContaining('Columnas: Diámetro'), findsOneWidget);
    expect(find.textContaining('PER-025X1'), findsWidgets);
    expect(find.textContaining('PER-038X1'), findsWidgets);
    expect(find.textContaining('Ciento · 100 UND'), findsWidgets);
    expect(find.textContaining('Regular: S/ 160.00'), findsWidgets);
    expect(find.text('Editar'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Editar'));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(edited, isTrue);
    expect(find.text('Ficha del producto'), findsNothing);
  });
}

class _DetalleRepositoryFake implements CatalogoRepository {
  @override
  Future<ProductoDetalle?> obtenerDetalleProducto(
    String id,
  ) async => ProductoDetalle(
    id: id,
    codigo: 'PER-FAM',
    nombre: 'Perno hexagonal métrico',
    descripcion: 'Familia de pernos de acero inoxidable.',
    empresa: 'DINA',
    marca: 'DINA',
    categoria: 'Pernería',
    subcategoria: 'Pernos métricos',
    tipoRegistro: 'matriz',
    atributos: const {'Material': 'Acero inoxidable'},
    variantes: const [
      ProductoVariante(
        id: 'var-1',
        sku: 'PER-025X1',
        codigoProveedor: 'FAB-001',
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
        codigoProveedor: 'FAB-002',
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
    ],
    presentaciones: const [
      PresentacionProducto(nombre: 'Ciento', unidad: '100 UND'),
    ],
    precios: const [],
    ventaLogisticaContenido: const {
      'presentations': [
        {
          'id': 'pres-100',
          'name': 'Ciento',
          'base_unit': 'UND',
          'equivalent_to': 100,
          'minimum_order': 1,
          'purchase_increment': 1,
          'assigned_variant_ids': ['var-1', 'var-2'],
          'default_variant_ids': ['var-1', 'var-2'],
          'variant_rules': [],
        },
      ],
      'logistics_packages': [],
      'content_items': [],
    },
    preciosConfigurados: const {
      'lists': [
        {'id': 'regular', 'name': 'Regular', 'currency_code': 'PEN'},
      ],
      'prices': [
        {
          'list_id': 'regular',
          'variant_id': 'var-1',
          'presentation_id': 'pres-100',
          'configuration': 'fixed',
          'fixed_price': 160,
          'ranges': [],
        },
        {
          'list_id': 'regular',
          'variant_id': 'var-2',
          'presentation_id': 'pres-100',
          'configuration': 'quote',
          'fixed_price': null,
          'ranges': [],
        },
      ],
    },
    activo: true,
    creadoEn: DateTime(2026, 7, 13),
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
