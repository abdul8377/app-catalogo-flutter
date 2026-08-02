import 'package:app_catalogo/features/catalogo/domain/entities/catalogo_form_data.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/nuevo_producto.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_detalle.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/producto_detalle_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el diálogo lista el detalle recuperado del repositorio', (
    tester,
  ) async {
    var editado = false;
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
                  onEditar: (_) => editado = true,
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

    expect(find.text('Perno hexagonal métrico'), findsOneWidget);
    expect(find.text('Rosca'), findsOneWidget);
    expect(find.text('RF'), findsOneWidget);
    expect(find.text('Ciento · 100 UND'), findsOneWidget);
    expect(find.text('S/ 160.00'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);

    await tester.ensureVisible(find.text('Editar'));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(editado, isTrue);
    expect(find.text('Detalle del producto'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _DetalleRepositoryFake implements CatalogoRepository {
  @override
  Future<ProductoDetalle?> obtenerDetalleProducto(String id) async =>
      ProductoDetalle(
        id: id,
        codigo: 'PER-001',
        nombre: 'Perno hexagonal métrico',
        descripcion: 'Perno industrial de alta resistencia.',
        empresa: 'DINA',
        marca: 'DINA',
        categoria: 'Pernería',
        subcategoria: 'Pernos métricos',
        tipoRegistro: 'matriz',
        atributos: const {'Rosca': 'RF'},
        presentaciones: const [
          PresentacionProducto(nombre: 'Ciento', unidad: '100 UND'),
        ],
        precios: const [PrecioProducto(presentacion: 'Ciento', valor: 160)],
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
