import 'package:app_catalogo/app/navigation/app_destination_access_policy.dart';
import 'package:app_catalogo/core/navigation/app_destination.dart';
import 'package:app_catalogo/features/auth/domain/entities/app_permission.dart';
import 'package:app_catalogo/features/auth/domain/entities/app_role.dart';
import 'package:app_catalogo/features/auth/domain/entities/app_user.dart';
import 'package:app_catalogo/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('administración mantiene los ocho destinos históricos', () {
    expect(
      AppDestinationAccessPolicy.visibleDestinations(
        AuthSession.legacyAdministrator,
      ),
      AppDestination.values.toSet(),
    );
  });

  test('vendedor mantiene exactamente los destinos históricos 0 a 6', () {
    expect(
      AppDestinationAccessPolicy.visibleDestinations(AuthSession.legacySeller),
      AppDestination.values.take(7).toSet(),
    );
  });

  test('un rol dinámico habilita destinos no contiguos por permiso', () {
    const session = AuthSession(
      user: AppUser(
        id: 'auditor',
        organizationId: 'organization-1',
        displayName: 'Auditor',
      ),
      roles: <AppRole>[
        AppRole(
          id: 'auditor-role',
          name: 'Auditoría',
          permissions: <AppPermission>{
            AppPermission.viewHome,
            AppPermission.viewDashboard,
          },
        ),
      ],
    );

    expect(
      AppDestinationAccessPolicy.visibleDestinations(session),
      <AppDestination>{AppDestination.home, AppDestination.dashboard},
    );
  });
}
