import '../../domain/entities/pedido.dart';
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
