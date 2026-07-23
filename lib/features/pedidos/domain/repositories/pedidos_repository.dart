import '../entities/cotizacion_pedido.dart';
import '../entities/pedido.dart';
import '../entities/pedido_detalle.dart';
import '../entities/pedido_preparacion.dart';
import '../entities/pedido_resumen.dart';
import '../entities/producto_consolidado.dart';

abstract class PedidosRepository {
  Future<HojaPedidoActiva?> obtenerHojaActiva();
  Future<HojaPedidoActiva> crearHojaActiva();
  Future<List<PedidoResumen>> obtenerPedidosResumen();
  Future<PedidoDetalle?> obtenerPedidoDetalle(String id);
  Future<CotizacionPedidoGuardada> guardarCotizacion(
    CotizacionPedidoDraft cotizacion,
  );
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
}
