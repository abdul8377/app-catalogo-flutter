import 'package:app_catalogo/features/estructura_catalogo/domain/entities/estructura_catalogo.dart';
import 'package:app_catalogo/features/estructura_catalogo/domain/repositories/estructura_catalogo_repository.dart';
import 'package:app_catalogo/features/estructura_catalogo/presentation/pages/estructura_catalogo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra las cuatro vistas y el detalle de empresa', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepositoryProvider<EstructuraCatalogoRepository>.value(
        value: _EstructuraRepositoryFake(),
        child: const MaterialApp(home: EstructuraCatalogoPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Empresas'), findsWidgets);
    expect(find.text('Marcas'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Relaciones'), findsOneWidget);
    expect(find.text('DINAFAST'), findsOneWidget);
    expect(find.text('Nueva empresa'), findsOneWidget);

    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('20601234567'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el modo vendedor no presenta acciones administrativas', (
    tester,
  ) async {
    await tester.pumpWidget(
      RepositoryProvider<EstructuraCatalogoRepository>.value(
        value: _EstructuraRepositoryFake(),
        child: const MaterialApp(
          home: EstructuraCatalogoPage(puedeAdministrar: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva empresa'), findsNothing);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Desactivar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _EstructuraRepositoryFake implements EstructuraCatalogoRepository {
  static const snapshot = EstructuraCatalogoSnapshot(
    empresas: [
      EmpresaCatalogo(
        id: 1,
        nombre: 'DINAFAST',
        ruc: '20601234567',
        telefono: '999888777',
        direccion: 'Av. Industrial 100',
        activa: true,
        cantidadMarcas: 1,
        cantidadCategorias: 1,
        cantidadProductos: 4,
        principalesMarcas: ['DINA'],
      ),
    ],
    marcas: [
      MarcaCatalogo(
        id: 1,
        empresaId: 1,
        nombre: 'DINA',
        empresaNombre: 'DINAFAST',
        activa: true,
        categorias: ['Pernería'],
        cantidadProductos: 4,
      ),
    ],
    categorias: [
      CategoriaCatalogo(
        id: 1,
        nombre: 'Pernería',
        descripcion: 'Elementos de fijación',
        activa: true,
        marcas: ['DINA'],
        empresas: ['DINAFAST'],
        cantidadProductos: 4,
      ),
    ],
    relaciones: [
      RelacionMarcaCategoria(marcaId: 1, categoriaId: 1, activa: true),
    ],
  );

  @override
  Future<EstructuraCatalogoSnapshot> obtenerEstructura() async => snapshot;

  @override
  Future<void> cambiarEstado({
    required String tipo,
    required int id,
    required bool activo,
  }) async {}

  @override
  Future<void> guardarCategoria({
    int? id,
    required CategoriaCatalogoDraft categoria,
  }) async {}

  @override
  Future<void> guardarEmpresa({
    int? id,
    required EmpresaCatalogoDraft empresa,
  }) async {}

  @override
  Future<void> guardarMarca({
    int? id,
    required MarcaCatalogoDraft marca,
  }) async {}

  @override
  Future<void> guardarRelaciones({
    required int marcaId,
    required Set<int> categoriaIds,
  }) async {}

  @override
  Future<ImpactoEstructura> obtenerImpacto({
    required String tipo,
    required int id,
  }) async => const ImpactoEstructura(productos: 0, marcas: 0, categorias: 0);
}
