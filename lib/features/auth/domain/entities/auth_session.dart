import 'package:equatable/equatable.dart';

import 'app_permission.dart';
import 'app_role.dart';
import 'app_user.dart';
import 'seller_scope.dart';

/// Snapshot inmutable de identidad, roles y alcance de datos.
class AuthSession extends Equatable {
  const AuthSession({required this.user, required this.roles});

  final AppUser user;
  final List<AppRole> roles;

  bool hasPermission(AppPermission permission) =>
      roles.any((role) => role.allows(permission));

  String get primaryRoleName => roles.isEmpty ? 'Usuario' : roles.first.name;

  SellerScope get sellerScope => SellerScope(
    organizationId: user.organizationId,
    sellerId: user.sellerId,
    includesAllSellers: hasPermission(AppPermission.viewAllSellers),
  );

  static const legacyAdministrator = AuthSession(
    user: AppUser(
      id: 'legacy-administrator',
      organizationId: 'legacy-organization',
      displayName: 'Alfonzo Esteban',
      sellerId: 'legacy-seller',
    ),
    roles: <AppRole>[AppRole.administrator],
  );

  static const legacySeller = AuthSession(
    user: AppUser(
      id: 'legacy-seller',
      organizationId: 'legacy-organization',
      displayName: 'Alfonzo Esteban',
      sellerId: 'legacy-seller',
    ),
    roles: <AppRole>[AppRole.seller],
  );

  @override
  List<Object?> get props => [user, roles];
}
