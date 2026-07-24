import 'package:app_catalogo/features/catalogo/domain/entities/catalogo_form_data.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/nuevo_producto.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_detalle.dart';
import 'package:app_catalogo/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/producto_form_bloc.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/producto_form_event.dart';
import 'package:app_catalogo/features/catalogo/presentation/pages/producto_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'agrega presentación y precio sin desbordar en pantalla angosta',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepositoryProvider<CatalogoRepository>.value(
          value: _FakeCatalogoRepository(),
          child: const MaterialApp(home: ProductoFormPage()),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final bloc = context.read<ProductoFormBloc>();
      bloc.add(
        const ProductoFormClasificacionCambiada(
          empresa: 'DINA',
          marca: 'DINA',
          categoria: 'Pernería',
        ),
      );
      await tester.pump();
      bloc.add(
        const ProductoFormClasificacionCambiada(
          subcategoria: 'Pernos métricos',
        ),
      );
      bloc.add(
        const ProductoFormFamiliaCambiada(
          codigo: 'TEST-001',
          nombre: 'Perno de prueba',
        ),
      );
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        bloc.add(const ProductoFormPasoSiguiente());
        await tester.pump();
      }
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre (ej. Docena)'),
        'Docena',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Equivalencia (ej. 12 UND)'),
        '12 UND',
      );
      await tester.tap(find.byKey(const Key('agregar_presentacion')));
      await tester.pumpAndSettle();

      expect(find.text('Docena'), findsWidgets);
      await tester.enterText(
        find.widgetWithText(TextField, 'Precio en soles'),
        '21.50',
      );
      await tester.ensureVisible(find.byKey(const Key('agregar_precio')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('agregar_precio')));
      await tester.pumpAndSettle();

      expect(find.text('S/ 21.50'), findsOneWidget);

      bloc.add(const ProductoFormPasoSiguiente());
      await tester.pumpAndSettle();
      bloc.add(
        const ProductoFormImagenesAgregadas([
          'imagen-principal.jpg',
          'imagen-secundaria.jpg',
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 imágenes adjuntas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('precarga y actualiza un producto existente', () async {
    final repository = _FakeCatalogoRepository();
    final bloc = ProductoFormBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const ProductoFormStarted(productoId: 'editar'));
    await bloc.stream.firstWhere((state) => !state.loading);

    expect(bloc.state.editando, isTrue);
    expect(bloc.state.codigo, 'EDIT-001');
    expect(bloc.state.nombre, 'Producto editable');

    bloc.add(const ProductoFormGuardado());
    await bloc.stream.firstWhere((state) => state.guardado);
    expect(repository.idActualizado, 'editar');
    expect(repository.productoActualizado?.codigo, 'EDIT-001');
  });

  test(
    'administra varias imágenes y conserva la principal al actualizar',
    () async {
      final repository = _FakeCatalogoRepository();
      final bloc = ProductoFormBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const ProductoFormStarted(productoId: 'editar'));
      await bloc.stream.firstWhere((state) => !state.loading);

      bloc.add(
        const ProductoFormImagenesAgregadas(['primera.jpg', 'segunda.jpg']),
      );
      await bloc.stream.firstWhere((state) => state.imagenesPaths.length == 2);
      bloc.add(const ProductoFormImagenPrincipalCambiada(1));
      await bloc.stream.firstWhere(
        (state) => state.imagenesPaths.first == 'segunda.jpg',
      );
      bloc.add(const ProductoFormImagenReemplazada(1, 'reemplazo.jpg'));
      await bloc.stream.firstWhere(
        (state) => state.imagenesPaths.last == 'reemplazo.jpg',
      );
      bloc.add(const ProductoFormImagenReordenada(1, 0));
      await bloc.stream.firstWhere(
        (state) => state.imagenesPaths.first == 'reemplazo.jpg',
      );
      bloc.add(const ProductoFormImagenEliminada(1));
      await bloc.stream.firstWhere((state) => state.imagenesPaths.length == 1);
      bloc.add(const ProductoFormEstadoCambiado(false));
      await bloc.stream.firstWhere((state) => !state.activo);
      bloc.add(const ProductoFormGuardado());
      await bloc.stream.firstWhere((state) => state.guardado);

      expect(repository.productoActualizado?.imagenesPaths, ['reemplazo.jpg']);
      expect(repository.productoActualizado?.activo, isFalse);
    },
  );

  testWidgets('la edición usa navegación lateral y guardado fijo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _FakeCatalogoRepository(),
        child: const MaterialApp(home: ProductoFormPage(productoId: 'editar')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar Producto'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Imágenes'), findsOneWidget);
    expect(find.byKey(const Key('guardar_cambios')), findsOneWidget);

    await tester.tap(find.text('Imágenes'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('seleccionar_imagenes')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeCatalogoRepository implements CatalogoRepository {
  String? idActualizado;
  NuevoProducto? productoActualizado;

  @override
  Future<void> cambiarEstadoProducto(String id, {required bool activo}) async {}

  @override
  Future<CatalogoFormData> obtenerDatosFormulario() async =>
      const CatalogoFormData(
        empresas: ['DINA'],
        marcas: ['DINA'],
        subcategorias: {
          'Pernería': ['Pernos métricos'],
        },
        atributos: {'Pernería': []},
        marcasPorEmpresa: {
          'DINA': ['DINA'],
        },
        categoriasPorMarca: {
          'DINA::DINA': ['Pernería'],
        },
      );

  @override
  Future<void> guardarProducto(NuevoProducto producto) async {}

  @override
  Future<void> actualizarProducto(String id, NuevoProducto producto) async {
    idActualizado = id;
    productoActualizado = producto;
  }

  @override
  Future<List<ProductoResumen>> buscarProductos(String query) async => [];

  @override
  Future<ProductoDetalle?> obtenerDetalleProducto(String id) async {
    if (id != 'editar') return null;
    return ProductoDetalle(
      id: id,
      codigo: 'EDIT-001',
      nombre: 'Producto editable',
      descripcion: 'Descripción',
      empresa: 'DINA',
      marca: 'DINA',
      categoria: 'Pernería',
      subcategoria: 'Pernos métricos',
      tipoRegistro: 'unico',
      atributos: const {'Rosca': 'RF'},
      presentaciones: const [
        PresentacionProducto(nombre: 'Unidad', unidad: '1 UND'),
      ],
      precios: const [PrecioProducto(presentacion: 'Unidad', valor: 2)],
      activo: true,
      creadoEn: DateTime(2026, 7, 13),
    );
  }

  @override
  Future<List<ProductoResumen>> obtenerProductos() async => [];
}
