import '../../features/auth/domain/entities/app_permission.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../core/navigation/app_destination.dart';

/// Traduce permisos de negocio a destinos sin llevar esa decisión a widgets.
abstract final class AppDestinationAccessPolicy {
  static const requiredPermissions = <AppDestination, AppPermission>{
    AppDestination.home: AppPermission.viewHome,
    AppDestination.catalogo: AppPermission.viewCatalog,
    AppDestination.clientes: AppPermission.viewClients,
    AppDestination.nuevoPedido: AppPermission.createOrders,
    AppDestination.pedidos: AppPermission.viewOrders,
    AppDestination.hojasPedido: AppPermission.manageOrderSheets,
    AppDestination.dashboard: AppPermission.viewDashboard,
    AppDestination.estructuraCatalogo: AppPermission.manageCatalogStructure,
  };

  static bool canOpen(AuthSession session, AppDestination destination) =>
      session.hasPermission(requiredPermissions[destination]!);

  static Set<AppDestination> visibleDestinations(AuthSession session) =>
      AppDestination.values
          .where((destination) => canOpen(session, destination))
          .toSet();
}
