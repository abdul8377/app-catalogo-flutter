import '../../domain/entities/cliente.dart';
import '../../domain/entities/cliente_pedido_resumen.dart';
import '../../domain/entities/nuevo_cliente.dart';
import '../../domain/repositories/clientes_repository.dart';
import '../datasources/clientes_local_datasource.dart';

class ClientesRepositoryImpl implements ClientesRepository {
  const ClientesRepositoryImpl(this.localDatasource);

  final ClientesLocalDatasource localDatasource;

  @override
  Future<List<Cliente>> obtenerClientes() => localDatasource.obtenerClientes();

  @override
  Future<Cliente?> obtenerCliente(String id) =>
      localDatasource.obtenerCliente(id);

  @override
  Future<List<ClientePedidoResumen>> obtenerPedidosCliente(String clienteId) =>
      localDatasource.obtenerPedidosCliente(clienteId);

  @override
  Future<void> guardarCliente(NuevoCliente cliente) =>
      localDatasource.guardarCliente(cliente);

  @override
  Future<void> actualizarCliente(String id, NuevoCliente cliente) =>
      localDatasource.actualizarCliente(id, cliente);

  @override
  Future<void> cambiarEstadoCliente(String id, {required bool activo}) =>
      localDatasource.cambiarEstadoCliente(id, activo: activo);
}
