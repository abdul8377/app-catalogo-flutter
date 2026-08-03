import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo_state.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/filtros_catalogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'categoría y subcategoría se gestionan únicamente desde Más filtros',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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
              onFiltrosAplicados: (_) {},
              onFiltrosLimpiados: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('catalogo_filtro_categoria')), findsNothing);
      expect(
        find.byKey(const Key('catalogo_filtro_subcategoria')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('abrir_filtros_avanzados')));
      await tester.pumpAndSettle();

      expect(find.text('Más filtros'), findsOneWidget);
      expect(find.text('Categoría'), findsWidgets);
      expect(find.text('Subcategoría'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

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
