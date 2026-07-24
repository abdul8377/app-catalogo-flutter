import '../entities/dashboard_data.dart';

abstract class DashboardRepository {
  Future<DashboardData> obtenerDashboard(DashboardFiltro filtro);

  Future<void> marcarPedidoCargado({
    required String pedidoId,
    required int paquetes,
    String observacion = '',
  });
}
