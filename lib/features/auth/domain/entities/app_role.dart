import 'package:equatable/equatable.dart';

import 'app_permission.dart';

/// Rol configurable. El identificador y el nombre no están limitados a un enum.
class AppRole extends Equatable {
  const AppRole({
    required this.id,
    required this.name,
    required this.permissions,
    this.isSystem = false,
  });

  final String id;
  final String name;
  final Set<AppPermission> permissions;
  final bool isSystem;

  bool allows(AppPermission permission) => permissions.contains(permission);

  static const administrator = AppRole(
    id: 'administrator',
    name: 'Administrador',
    permissions: <AppPermission>{...AppPermission.values},
    isSystem: true,
  );

  static const seller = AppRole(
    id: 'seller',
    name: 'Vendedor',
    permissions: <AppPermission>{
      AppPermission.viewHome,
      AppPermission.viewCatalog,
      AppPermission.viewClients,
      AppPermission.manageClients,
      AppPermission.createOrders,
      AppPermission.viewOrders,
      AppPermission.manageOrderSheets,
      AppPermission.viewDashboard,
    },
    isSystem: true,
  );

  @override
  List<Object?> get props => [id, name, permissions, isSystem];
}
