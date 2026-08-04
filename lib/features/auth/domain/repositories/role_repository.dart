import '../entities/app_role.dart';

/// Puerto para una futura fuente local o remota de roles configurables.
abstract interface class RoleRepository {
  Future<List<AppRole>> getRoles();

  Future<void> saveRole(AppRole role);

  Future<void> deleteRole(String roleId);

  Future<void> assignRoles({
    required String userId,
    required Set<String> roleIds,
  });
}
