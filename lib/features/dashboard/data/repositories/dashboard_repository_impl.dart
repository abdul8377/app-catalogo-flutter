import '../../../pedidos/domain/repositories/pedidos_repository.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this.localDatasource, this.pedidosRepository);

  final DashboardLocalDatasource localDatasource;
  final PedidosRepository pedidosRepository;

  @override
  Future<DashboardData> obtenerDashboard(DashboardFiltro filtro) =>
      localDatasource.obtenerDashboard(filtro);

  @override
  Future<void> marcarPedidoCargado({
    required String pedidoId,
    required int paquetes,
    String observacion = '',
  }) => pedidosRepository.marcarPedidoCargado(
    pedidoId: pedidoId,
    paquetes: paquetes,
    observacion: observacion,
  );
}
