import 'package:app_catalogo/features/catalogo/domain/entities/catalogo_form_data.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/nuevo_producto.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_detalle.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo/catalogo_bloc.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo/catalogo_event.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/catalogo/catalogo_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carga, busca y filtra los productos del repositorio', () async {
    final repository = _CatalogoRepositoryFake();
    final bloc = CatalogoBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const CatalogoStarted());
    await bloc.stream.firstWhere((state) => !state.loading);
    expect(bloc.state.productosFiltrados, hasLength(2));

    bloc.add(const CatalogoBusquedaCambiada('taladro'));
    await bloc.stream.firstWhere((state) => state.busqueda == 'taladro');
    expect(bloc.state.productosFiltrados.single.codigo, 'TAL-020');

    bloc.add(const CatalogoBusquedaCambiada(''));
    await bloc.stream.firstWhere((state) => state.busqueda.isEmpty);
    bloc.add(const CatalogoFiltroRapidoCambiado('Sin precio'));
    await bloc.stream.firstWhere(
      (state) => state.filtrosRapidos.contains('Sin precio'),
    );
    expect(bloc.state.productosFiltrados.single.codigo, 'TAL-020');

    bloc.add(const CatalogoFiltroRapidoCambiado('Todos'));
    await bloc.stream.firstWhere(
      (state) => state.filtrosRapidos.contains('Todos'),
    );
    bloc.add(
      const CatalogoFiltrosAplicados(
        CatalogoFiltros(subcategorias: {'Pernos hexagonales', 'Taladros'}),
      ),
    );
    await bloc.stream.firstWhere(
      (state) => state.filtros.subcategoriasActivas.length == 2,
    );
    expect(bloc.state.productosFiltrados, hasLength(2));

    bloc.add(
      const CatalogoFiltrosAplicados(
        CatalogoFiltros(
          categoria: 'Pernería',
          subcategoria: 'Pernos hexagonales',
        ),
      ),
    );
    await bloc.stream.firstWhere(
      (state) => state.filtros.subcategoria == 'Pernos hexagonales',
    );
    expect(bloc.state.productosFiltrados.single.codigo, 'PER-001');
  });
}

class _CatalogoRepositoryFake implements CatalogoRepository {
  final productos = const [
    ProductoResumen(
      id: '1',
      codigo: 'PER-001',
      nombre: 'Perno hexagonal',
      empresa: 'DINA',
      marca: 'DINA',
      categoria: 'Pernería',
      subcategoria: 'Pernos hexagonales',
      unidadVenta: 'Ciento',
      precio: 18,
      sinPrecio: false,
      activo: true,
      tipoRegistro: 'matriz',
      atributosClave: ['Rosca: RF'],
    ),
    ProductoResumen(
      id: '2',
      codigo: 'TAL-020',
      nombre: 'Taladro 20V',
      empresa: 'Garibaldi',
      marca: 'Garibaldi',
      categoria: 'Herramientas eléctricas',
      subcategoria: 'Taladros',
      unidadVenta: 'UND',
      precio: null,
      sinPrecio: true,
      activo: true,
      tipoRegistro: 'unico',
      atributosClave: ['Voltaje: 20V'],
    ),
  ];

  @override
  Future<List<ProductoResumen>> obtenerProductos() async => productos;
  @override
  Future<List<ProductoResumen>> buscarProductos(String query) async =>
      productos;
  @override
  Future<void> cambiarEstadoProducto(String id, {required bool activo}) async {}
  @override
  Future<ProductoDetalle?> obtenerDetalleProducto(String id) async => null;
  @override
  Future<CatalogoFormData> obtenerDatosFormulario() async =>
      const CatalogoFormData(
        empresas: [],
        marcas: [],
        subcategorias: {},
        atributos: {},
      );
  @override
  Future<void> guardarProducto(NuevoProducto producto) async {}
  @override
  Future<void> actualizarProducto(String id, NuevoProducto producto) async {}
}
