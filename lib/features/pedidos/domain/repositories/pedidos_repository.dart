import '../entities/cotizacion_pedido.dart';
import '../entities/pedido.dart';
import '../entities/pedido_detalle.dart';
import '../entities/pedido_preparacion.dart';
import '../entities/pedido_resumen.dart';
import '../entities/producto_consolidado.dart';
import '../entities/resumen_hoy.dart';

abstract class PedidosRepository {
  Future<HojaPedidoActiva?> obtenerHojaActiva();
  Future<ResumenHoy> obtenerResumenHoy() async => const ResumenHoy(
    vendedorNombre: 'Usuario',
    pedidosPendientes: 0,
    pedidosEnProceso: 0,
    pedidosListos: 0,
    pedidosEntregados: 0,
    productosSinPrecio: 0,
    cambiosSinSincronizar: 0,
  );
  Future<HojaPedidoActiva> crearHojaActiva();
  Future<List<PedidoResumen>> obtenerPedidosResumen();
  Future<PedidoDetalle?> obtenerPedidoDetalle(String id);
  Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id) async => null;
  Future<CotizacionPedidoGuardada> guardarCotizacion(
    CotizacionPedidoDraft cotizacion,
  );
  Future<CotizacionPedidoGuardada> actualizarCotizacion({
    required String cotizacionId,
    required CotizacionPedidoDraft cotizacion,
  }) => guardarCotizacion(cotizacion);
  Future<void> registrarPdfCotizacion({
    required String cotizacionId,
    required String pdfPath,
  });
  Future<List<ProductoConsolidado>> obtenerProductosConsolidados();
  Future<void> registrarPreparacionProducto(
    PreparacionProductoDraft preparacion,
  );
  Future<List<PedidoPreparacion>> obtenerPedidosPreparacion();
  Future<void> cambiarEstadoPedido({
    required String pedidoId,
    required String nuevoEstado,
    String observacion = '',
  });
  Future<void> cancelarPedido({
    required String pedidoId,
    required String motivo,
  });
  Future<void> reactivarPedido({
    required String pedidoId,
    String observacion = '',
  }) => cambiarEstadoPedido(
    pedidoId: pedidoId,
    nuevoEstado: 'Pendiente',
    observacion: observacion,
  );
  Future<void> reintentarSincronizacionPedido(String pedidoId);
  Future<void> marcarPedidoCargado({
    required String pedidoId,
    required int paquetes,
    String observacion = '',
  });
  Future<List<ClientePedido>> buscarClientes(String query);
  Future<PedidoRegistrado> guardarPedido({
    required HojaPedidoActiva hoja,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  });
  Future<PedidoRegistrado> actualizarPedido({
    required String pedidoId,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) => throw UnimplementedError(
    'Este repositorio no implementa la edición de pedidos.',
  );
}
