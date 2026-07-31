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
    expect(find.text('Marcas'), findsWidgets);
    expect(find.text('Categorías'), findsWidgets);
    expect(find.text('Categorías por marca'), findsWidgets);
    expect(find.text('DINAFAST'), findsOneWidget);
    expect(find.text('Nueva empresa'), findsOneWidget);

    await tester.tap(find.text('Ver marcas').first);
    await tester.pumpAndSettle();
    expect(find.text('DINA'), findsOneWidget);

    await tester.tap(find.text('Categorías').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pernería').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gestionar atributos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gestionar atributos'));
    await tester.pumpAndSettle();
    expect(find.text('Gestionar atributos · Pernería'), findsOneWidget);
    expect(find.text('Nuevo atributo'), findsOneWidget);
    expect(find.text('Agregar atributo'), findsNothing);
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
    atributos: [
      AtributoCategoriaCatalogo(
        id: 'diametro',
        categoriaId: 1,
        categoriaNombre: 'Pernería',
        nombre: 'Diámetro',
        clave: 'diametro',
        tipoDato: 'numero_unidad',
        nivelCaptura: 'variante',
        requeridoActivar: true,
        visibleFicha: true,
        filtrable: true,
        puedeSerEje: true,
        activoNuevos: true,
        orden: 0,
        activo: true,
        magnitud: 'Longitud',
        codigosUnidad: ['mm'],
        unidadPredeterminada: 'mm',
      ),
    ],
    unidades: [
      UnidadMedidaCatalogo(
        id: 'unit-mm',
        codigo: 'mm',
        nombre: 'Milímetro',
        simbolo: 'mm',
        magnitud: 'Longitud',
        factorBase: 1,
      ),
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
  Future<void> guardarAtributosCategoria({
    required int categoriaId,
    required List<AtributoCategoriaCatalogo> atributos,
  }) async {}

  @override
  Future<ImpactoEstructura> obtenerImpacto({
    required String tipo,
    required int id,
  }) async => const ImpactoEstructura(productos: 0, marcas: 0, categorias: 0);
}
