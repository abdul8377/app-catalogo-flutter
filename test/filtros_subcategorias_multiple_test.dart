import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo/catalogo_state.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/filtros_catalogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('permite aplicar varias subcategorías desde Más filtros', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    CatalogoFiltros? applied;
    const products = [
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
        codigo: 'TAL-001',
        nombre: 'Taladro',
        empresa: 'DINAFAST',
        marca: 'DINA',
        categoria: 'Herramientas',
        subcategoria: 'Taladros',
        unidadVenta: 'Unidad',
        precio: 150,
        sinPrecio: false,
        activo: true,
        tipoRegistro: 'unico',
        atributosClave: [],
      ),
    ];
    final state = CatalogoState(
      loading: false,
      actualizando: false,
      busqueda: '',
      filtrosRapidos: const {'Todos'},
      filtros: const CatalogoFiltros(),
      vistaGrilla: true,
      productos: products,
      productosFiltrados: products,
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

    await tester.tap(find.byKey(const Key('abrir_filtros_avanzados')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dialog_subcategorias_multiple')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('subcategoria_opcion_Pernos hexagonales')),
    );
    await tester.tap(
      find.byKey(const ValueKey('subcategoria_opcion_Taladros')),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('aplicar_subcategorias')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('aplicar_filtros_avanzados')));
    await tester.pumpAndSettle();

    expect(applied?.subcategoriasActivas, {'Pernos hexagonales', 'Taladros'});
    expect(tester.takeException(), isNull);
  });
}
