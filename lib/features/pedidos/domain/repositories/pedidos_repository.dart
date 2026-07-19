import '../entities/pedido.dart';

abstract class PedidosRepository {
  Future<HojaPedidoActiva?> obtenerHojaActiva();
  Future<HojaPedidoActiva> crearHojaActiva();
  Future<List<ClientePedido>> buscarClientes(String query);
  Future<PedidoRegistrado> guardarPedido({
    required HojaPedidoActiva hoja,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  });
}
