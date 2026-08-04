import '../entities/auth_session.dart';

/// Puerto para conectar autenticación local o remota sin acoplarla a la UI.
abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();

  Stream<AuthSession?> watchSession();

  Future<AuthSession> signIn({
    required String identifier,
    required String secret,
  });

  Future<void> signOut();
}
