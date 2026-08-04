import 'package:app_catalogo/features/auth/domain/entities/app_permission.dart';
import 'package:app_catalogo/features/auth/domain/entities/app_role.dart';
import 'package:app_catalogo/features/auth/domain/entities/app_user.dart';
import 'package:app_catalogo/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'la sesión administradora heredada conserva identidad y acceso total',
    () {
      const session = AuthSession.legacyAdministrator;

      expect(session.user.displayName, 'Alfonzo Esteban');
      expect(session.primaryRoleName, 'Administrador');
      expect(AppPermission.values.every(session.hasPermission), isTrue);
      expect(session.sellerScope.includesAllSellers, isTrue);
    },
  );

  test(
    'la sesión vendedor limita administración y datos de otros vendedores',
    () {
      const session = AuthSession.legacySeller;

      expect(session.primaryRoleName, 'Vendedor');
      expect(session.hasPermission(AppPermission.createOrders), isTrue);
      expect(
        session.hasPermission(AppPermission.manageCatalogStructure),
        isFalse,
      );
      expect(
        session.sellerScope.includes(
          organizationId: 'legacy-organization',
          sellerId: 'legacy-seller',
        ),
        isTrue,
      );
      expect(
        session.sellerScope.includes(
          organizationId: 'legacy-organization',
          sellerId: 'seller-2',
        ),
        isFalse,
      );
    },
  );

  test(
    'un rol dinámico puede combinarse sin añadir nuevos tipos de usuario',
    () {
      const session = AuthSession(
        user: AppUser(
          id: 'user-supervisor',
          organizationId: 'organization-1',
          displayName: 'Supervisora Norte',
          sellerId: 'seller-north',
        ),
        roles: <AppRole>[
          AppRole(
            id: 'regional-supervisor',
            name: 'Supervisora regional',
            permissions: <AppPermission>{
              AppPermission.viewHome,
              AppPermission.viewDashboard,
              AppPermission.viewAllSellers,
            },
          ),
        ],
      );

      expect(session.primaryRoleName, 'Supervisora regional');
      expect(session.hasPermission(AppPermission.viewDashboard), isTrue);
      expect(session.hasPermission(AppPermission.createOrders), isFalse);
      expect(session.sellerScope.includesAllSellers, isTrue);
      expect(
        session.sellerScope.includes(
          organizationId: 'organization-2',
          sellerId: 'seller-north',
        ),
        isFalse,
      );
    },
  );
}
