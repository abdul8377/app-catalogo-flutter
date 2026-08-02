import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo_state.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/filtros_catalogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra categoría y subcategoría como clasificación principal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    CatalogoFiltros? applied;
    final state = CatalogoState(
      loading: false,
      actualizando: false,
      busqueda: '',
      filtrosRapidos: const {'Todos'},
      filtros: const CatalogoFiltros(),
      vistaGrilla: true,
      productos: const [
        ProductoResumen(
          id: '1',
          codigo: 'PER-001',
          nombre: 'Perno hexagonal',
          empresa: 'DINAFAST',
          marca: 'DINA',
          categoria: 'Pernería',
          subcategoria: 'Pernos hexagonales',
          unidadVenta: 'Ciento',
          precio: 20,
          sinPrecio: false,
          activo: true,
          tipoRegistro: 'matriz',
          atributosClave: [],
        ),
        ProductoResumen(
          id: '2',
          codigo: 'BRO-001',
          nombre: 'Broca HSS',
          empresa: 'UYUSTOOLS',
          marca: 'UYUSTOOLS',
          categoria: 'Accesorios',
          subcategoria: 'Brocas',
          unidadVenta: 'Unidad',
          precio: null,
          sinPrecio: true,
          activo: true,
          tipoRegistro: 'lista',
          atributosClave: [],
        ),
      ],
      productosFiltrados: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FiltrosCatalogo(
            state: state,
            onBusquedaCambiada: (_) {},
            onFiltroRapido: (_) {},
            onFiltrosAplicados: (value) => applied = value,
            onFiltrosLimpiados: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('catalogo_filtro_categoria')), findsOneWidget);
    expect(
      find.byKey(const Key('catalogo_filtro_subcategoria')),
      findsOneWidget,
    );
    expect(find.text('Con variantes'), findsNothing);
    expect(find.text('Sin imagen'), findsNothing);

    await tester.tap(find.byKey(const Key('catalogo_filtro_categoria')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pernería').last);
    await tester.pumpAndSettle();

    expect(applied?.categoria, 'Pernería');
    expect(tester.takeException(), isNull);
  });

  testWidgets('nuevo pedido usa filtros comerciales compactos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = CatalogoState(
      loading: false,
      actualizando: false,
      busqueda: '',
      filtrosRapidos: const {'Todos'},
      filtros: const CatalogoFiltros(),
      vistaGrilla: true,
      productos: const [],
      productosFiltrados: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FiltrosCatalogo(
            state: state,
            modoPedido: true,
            onBusquedaCambiada: (_) {},
            onFiltroRapido: (_) {},
            onFiltrosAplicados: (_) {},
            onFiltrosLimpiados: () {},
          ),
        ),
      ),
    );

    expect(find.text('Con precio'), findsOneWidget);
    expect(find.text('Sin precio'), findsOneWidget);
    expect(find.text('Activos'), findsNothing);
    expect(find.text('Inactivos'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
