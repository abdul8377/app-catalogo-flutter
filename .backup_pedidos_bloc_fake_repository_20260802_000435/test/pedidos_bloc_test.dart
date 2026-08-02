import 'package:app_catalogo/features/catalogo/domain/entities/catalogo_form_data.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/nuevo_producto.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_detalle.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/cotizacion_pedido.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido_detalle.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido_preparacion.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido_resumen.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/producto_consolidado.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/resumen_hoy.dart';
import 'package:app_catalogo/features/pedidos/domain/repositories/pedidos_repository.dart';
import 'package:app_catalogo/features/pedidos/presentation/bloc/pedidos_bloc.dart';
import 'package:app_catalogo/features/pedidos/presentation/bloc/pedidos_event.dart';
import 'package:app_catalogo/features/home/presentation/bloc/home_bloc.dart';
import 'package:app_catalogo/features/home/presentation/bloc/home_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home actualiza automáticamente el código de la hoja activa', () async {
    final bloc = HomeBloc(_PedidosRepositoryFake());
    addTearDown(bloc.close);

    bloc.add(const HomeStarted());
    await bloc.stream.firstWhere(
      (state) => !state.loading && state.codigoHojaActiva == 'HP-2026-001',
    );

    bloc.add(const HomeRefreshed());
    await bloc.stream.firstWhere(
      (state) => state.codigoHojaActiva == 'HP-2026-002',
    );

    expect(bloc.state.tieneHojaActiva, isTrue);
    expect(bloc.state.codigoHojaActiva, 'HP-2026-002');
    expect(bloc.state.pedidosPendientes, 2);
    expect(bloc.state.productosSinPrecio, 1);
    expect(bloc.state.sincronizado, isFalse);
  });

  test('gestiona catálogo vendible, carrito, cliente y confirmación', () async {
    final pedidosRepository = _PedidosRepositoryFake();
    final bloc = PedidosBloc(_CatalogoRepositoryFake(), pedidosRepository);
    addTearDown(bloc.close);

    bloc.add(const PedidosStarted());
    await bloc.stream.firstWhere((state) => !state.loading);

    expect(
      bloc.state.productosFiltrados.map((item) => item.id),
      unorderedEquals(['precio', 'sin-precio']),
    );
    expect(bloc.state.hojaActiva?.codigo, 'HP-2026-001');

    bloc.add(
      const PedidoProductoAgregado(
        PedidoItem(
          productoId: 'precio',
          codigo: 'P-1',
          nombre: 'Perno',
          presentacion: 'Ciento',
          equivalencia: '100 UND',
          cantidad: 2,
          precioUnitario: 18.5,
          opciones: [
            PresentacionPedidoOpcion(
              nombre: 'Ciento',
              equivalencia: '100 UND',
              precio: 18.5,
            ),
          ],
        ),
      ),
    );
    bloc.add(
      const PedidoProductoAgregado(
        PedidoItem(
          productoId: 'sin-precio',
          codigo: 'H-1',
          nombre: 'Herramienta',
          presentacion: 'Unidad',
          equivalencia: '1 UND',
          cantidad: 1,
          precioUnitario: null,
        ),
      ),
    );
    await bloc.stream.firstWhere((state) => state.carrito.length == 2);

    expect(bloc.state.subtotalConocido, 37);
    expect(bloc.state.productosSinPrecio, 1);
    expect(bloc.state.totalParcial, isTrue);

    bloc.add(
      const PedidoClienteSeleccionado(
        ClientePedido(
          nombre: 'Comercial Sur',
          telefono: '987654321',
          direccion: 'Av. Sur 123',
        ),
      ),
    );
    await bloc.stream.firstWhere((state) => state.cliente != null);
    bloc.add(const PedidoConfirmado());
    await bloc.stream.firstWhere((state) => state.resultado != null);

    expect(pedidosRepository.itemsGuardados, hasLength(2));
    expect(pedidosRepository.hojaGuardada?.codigo, 'HP-2026-002');
    expect(bloc.state.resultado?.codigo, 'PED-2026-0001');
    expect(bloc.state.carrito, isEmpty);
    expect(bloc.state.cantidadProductos, 0);
  });

  test(
    'mantiene variantes separadas y recalcula el precio por cantidad',
    () async {
      final bloc = PedidosBloc(
        _CatalogoRepositoryFake(),
        _PedidosRepositoryFake(),
      );
      addTearDown(bloc.close);

      const ranges = [
        PedidoPrecioRango(desde: 1, hasta: 2, precio: 20),
        PedidoPrecioRango(desde: 3, precio: 15),
      ];
      const option = PresentacionPedidoOpcion(
        id: 'caja',
        nombre: 'Caja',
        equivalencia: '10 UND',
        equivalenteA: 10,
        unidadBase: 'UND',
        listaPrecioId: 'regular',
        listaPrecioNombre: 'Regular',
        configuracionPrecio: 'por_cantidad',
        precio: null,
        rangos: ranges,
      );

      bloc.add(
        const PedidoProductoAgregado(
          PedidoItem(
            productoId: 'familia',
            codigo: 'FAM',
            nombre: 'Producto',
            varianteId: 'var-a',
            varianteSku: 'SKU-A',
            varianteNombre: 'Variante A',
            presentacionId: 'caja',
            presentacion: 'Caja',
            equivalencia: '10 UND',
            cantidad: 1,
            precioUnitario: 20,
            precioListaId: 'regular',
            precioListaNombre: 'Regular',
            precioConfiguracion: 'por_cantidad',
            opciones: [option],
          ),
        ),
      );
      bloc.add(
        const PedidoProductoAgregado(
          PedidoItem(
            productoId: 'familia',
            codigo: 'FAM',
            nombre: 'Producto',
            varianteId: 'var-b',
            varianteSku: 'SKU-B',
            varianteNombre: 'Variante B',
            presentacionId: 'caja',
            presentacion: 'Caja',
            equivalencia: '10 UND',
            cantidad: 1,
            precioUnitario: 20,
            precioListaId: 'regular',
            precioListaNombre: 'Regular',
            precioConfiguracion: 'por_cantidad',
            opciones: [option],
          ),
        ),
      );
      await bloc.stream.firstWhere((state) => state.carrito.length == 2);

      bloc.add(
        const PedidoProductoAgregado(
          PedidoItem(
            productoId: 'familia',
            codigo: 'FAM',
            nombre: 'Producto',
            varianteId: 'var-a',
            varianteSku: 'SKU-A',
            varianteNombre: 'Variante A',
            presentacionId: 'caja',
            presentacion: 'Caja',
            equivalencia: '10 UND',
            cantidad: 2,
            precioUnitario: 20,
            precioListaId: 'regular',
            precioListaNombre: 'Regular',
            precioConfiguracion: 'por_cantidad',
            opciones: [option],
          ),
        ),
      );
      await bloc.stream.firstWhere(
        (state) =>
            state.carrito.length == 2 && state.carrito.first.cantidad == 3,
      );

      expect(bloc.state.carrito, hasLength(2));
      expect(bloc.state.carrito.first.precioUnitario, 15);
      expect(bloc.state.lineasCarrito, 2);
      expect(bloc.state.cantidadPresentaciones, 4);
    },
  );

  test('no confirma un pedido sin dirección de cliente', () async {
    final bloc = PedidosBloc(
      _CatalogoRepositoryFake(),
      _PedidosRepositoryFake(),
    );
    addTearDown(bloc.close);
    bloc.add(const PedidosStarted());
    await bloc.stream.firstWhere((state) => !state.loading);
    bloc.add(
      const PedidoProductoAgregado(
        PedidoItem(
          productoId: 'precio',
          codigo: 'P-1',
          nombre: 'Perno',
          presentacion: 'Unidad',
          equivalencia: '1 UND',
          cantidad: 1,
          precioUnitario: 2,
        ),
      ),
    );
    bloc.add(
      const PedidoClienteSeleccionado(
        ClientePedido(nombre: 'Cliente', telefono: '999999999'),
      ),
    );
    await bloc.stream.firstWhere((state) => state.cliente != null);
    bloc.add(const PedidoConfirmado());
    await bloc.stream.firstWhere((state) => state.error != null);
    expect(bloc.state.error, contains('dirección'));
  });
}

class _PedidosRepositoryFake implements PedidosRepository {
  List<PedidoItem> itemsGuardados = [];
  HojaPedidoActiva? hojaGuardada;
  int _consultasHoja = 0;

  @override
  Future<ResumenHoy> obtenerResumenHoy() async => const ResumenHoy(
    vendedorNombre: 'Prueba',
    pedidosPendientes: 2,
    pedidosEnProceso: 1,
    pedidosListos: 1,
    pedidosEntregados: 3,
    productosSinPrecio: 1,
    cambiosSinSincronizar: 2,
  );

  @override
  Future<List<ClientePedido>> buscarClientes(String query) async => const [];

  @override
  Future<HojaPedidoActiva> crearHojaActiva() async => const HojaPedidoActiva(
    id: 'h1',
    codigo: 'HP-2026-001',
    estado: 'Abierta',
  );

  @override
  Future<HojaPedidoActiva?> obtenerHojaActiva() async {
    _consultasHoja++;
    return _consultasHoja == 1
        ? const HojaPedidoActiva(
            id: 'h1',
            codigo: 'HP-2026-001',
            estado: 'Abierta',
          )
        : const HojaPedidoActiva(
            id: 'h2',
            codigo: 'HP-2026-002',
            estado: 'Abierta',
          );
  }

  @override
  Future<List<PedidoResumen>> obtenerPedidosResumen() async => const [];

  @override
  Future<PedidoDetalle?> obtenerPedidoDetalle(String id) async => null;

  @override
  Future<CotizacionPedidoGuardada> guardarCotizacion(
    CotizacionPedidoDraft cotizacion,
  ) async => CotizacionPedidoGuardada(
    id: 'cotizacion-1',
    pedidoId: cotizacion.pedidoId,
    codigo: 'COT-2026-0001',
    total: cotizacion.total,
    creadoEn: DateTime(2026),
  );

  @override
  Future<void> registrarPdfCotizacion({
    required String cotizacionId,
    required String pdfPath,
  }) async {}

  @override
  Future<List<ProductoConsolidado>> obtenerProductosConsolidados() async =>
      const [];

  @override
  Future<void> registrarPreparacionProducto(
    PreparacionProductoDraft preparacion,
  ) async {}

  @override
  Future<List<PedidoPreparacion>> obtenerPedidosPreparacion() async => const [];

  @override
  Future<void> cambiarEstadoPedido({
    required String pedidoId,
    required String nuevoEstado,
    String observacion = '',
  }) async {}

  @override
  Future<void> cancelarPedido({
    required String pedidoId,
    required String motivo,
  }) async {}

  @override
  Future<void> reintentarSincronizacionPedido(String pedidoId) async {}

  @override
  Future<void> marcarPedidoCargado({
    required String pedidoId,
    required int paquetes,
    String observacion = '',
  }) async {}

  @override
  Future<PedidoRegistrado> guardarPedido({
    required HojaPedidoActiva hoja,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) async {
    itemsGuardados = items;
    hojaGuardada = hoja;
    return PedidoRegistrado(
      id: 'pedido-1',
      codigo: 'PED-2026-0001',
      cliente: cliente.nombre,
      hojaCodigo: hoja.codigo,
      estado: 'Pendiente',
    );
  }
}

class _CatalogoRepositoryFake implements CatalogoRepository {
  @override
  Future<List<ProductoResumen>> obtenerProductos() async => const [
    ProductoResumen(
      id: 'precio',
      codigo: 'P-1',
      nombre: 'Perno',
      empresa: 'DINA',
      marca: 'DINA',
      categoria: 'Pernería',
      unidadVenta: 'Ciento',
      precio: 18.5,
      sinPrecio: false,
      activo: true,
      tipoRegistro: 'unico',
      atributosClave: [],
    ),
    ProductoResumen(
      id: 'sin-precio',
      codigo: 'H-1',
      nombre: 'Herramienta',
      empresa: 'DINA',
      marca: 'DINA',
      categoria: 'Herramientas',
      unidadVenta: 'Unidad',
      precio: null,
      sinPrecio: true,
      activo: true,
      tipoRegistro: 'unico',
      atributosClave: [],
    ),
    ProductoResumen(
      id: 'inactivo',
      codigo: 'I-1',
      nombre: 'Inactivo',
      empresa: 'DINA',
      marca: 'DINA',
      categoria: 'Otros',
      unidadVenta: 'Unidad',
      precio: 1,
      sinPrecio: false,
      activo: false,
      tipoRegistro: 'unico',
      atributosClave: [],
    ),
  ];

  @override
  Future<List<ProductoResumen>> buscarProductos(String query) async => [];
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
  @override
  Future<void> cambiarEstadoProducto(String id, {required bool activo}) async {}
}
