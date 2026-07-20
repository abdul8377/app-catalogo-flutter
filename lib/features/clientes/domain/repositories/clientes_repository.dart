import '../entities/cliente.dart';
import '../entities/cliente_pedido_resumen.dart';
import '../entities/nuevo_cliente.dart';

abstract class ClientesRepository {
  Future<List<Cliente>> obtenerClientes();
  Future<Cliente?> obtenerCliente(String id);
  Future<List<ClientePedidoResumen>> obtenerPedidosCliente(String clienteId);
  Future<void> guardarCliente(NuevoCliente cliente);
  Future<void> actualizarCliente(String id, NuevoCliente cliente);
  Future<void> cambiarEstadoCliente(String id, {required bool activo});
}
