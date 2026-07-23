import '../../domain/entities/cotizacion_pedido.dart';
import '../../domain/entities/pedido.dart';
import '../../domain/entities/pedido_detalle.dart';
import '../../domain/entities/pedido_preparacion.dart';
import '../../domain/entities/pedido_resumen.dart';
import '../../domain/entities/producto_consolidado.dart';
import '../../domain/repositories/pedidos_repository.dart';
import '../datasources/pedidos_local_datasource.dart';

class PedidosRepositoryImpl implements PedidosRepository {
  const PedidosRepositoryImpl(this.localDatasource);
  final PedidosLocalDatasource localDatasource;

  @override
  Future<HojaPedidoActiva?> obtenerHojaActiva() =>
      localDatasource.obtenerHojaActiva();

  @override
  Future<HojaPedidoActiva> crearHojaActiva() =>
      localDatasource.crearHojaActiva();

  @override
  Future<List<PedidoResumen>> obtenerPedidosResumen() =>
      localDatasource.obtenerPedidosResumen();

  @override
  Future<PedidoDetalle?> obtenerPedidoDetalle(String id) =>
      localDatasource.obtenerPedidoDetalle(id);

  @override
  Future<CotizacionPedidoGuardada> guardarCotizacion(
    CotizacionPedidoDraft cotizacion,
  ) => localDatasource.guardarCotizacion(cotizacion);

  @override
  Future<void> registrarPdfCotizacion({
    required String cotizacionId,
    required String pdfPath,
  }) => localDatasource.registrarPdfCotizacion(
    cotizacionId: cotizacionId,
    pdfPath: pdfPath,
  );

  @override
  Future<List<ProductoConsolidado>> obtenerProductosConsolidados() =>
      localDatasource.obtenerProductosConsolidados();

  @override
  Future<void> registrarPreparacionProducto(
    PreparacionProductoDraft preparacion,
  ) => localDatasource.registrarPreparacionProducto(preparacion);

  @override
  Future<List<PedidoPreparacion>> obtenerPedidosPreparacion() =>
      localDatasource.obtenerPedidosPreparacion();

  @override
  Future<void> cambiarEstadoPedido({
    required String pedidoId,
    required String nuevoEstado,
    String observacion = '',
  }) => localDatasource.cambiarEstadoPedido(
    pedidoId: pedidoId,
    nuevoEstado: nuevoEstado,
    observacion: observacion,
  );

  @override
  Future<void> cancelarPedido({
    required String pedidoId,
    required String motivo,
  }) => localDatasource.cancelarPedido(pedidoId: pedidoId, motivo: motivo);

  @override
  Future<void> reintentarSincronizacionPedido(String pedidoId) =>
      localDatasource.reintentarSincronizacionPedido(pedidoId);

  @override
  Future<void> marcarPedidoCargado({
    required String pedidoId,
    required int paquetes,
    String observacion = '',
  }) => localDatasource.marcarPedidoCargado(
    pedidoId: pedidoId,
    paquetes: paquetes,
    observacion: observacion,
  );

  @override
  Future<List<ClientePedido>> buscarClientes(String query) =>
      localDatasource.buscarClientes(query);

  @override
  Future<PedidoRegistrado> guardarPedido({
    required HojaPedidoActiva hoja,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) => localDatasource.guardarPedido(
    hoja: hoja,
    cliente: cliente,
    items: items,
    vendedor: vendedor,
  );
}
