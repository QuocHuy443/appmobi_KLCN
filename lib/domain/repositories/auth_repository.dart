import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String identifier, String password);
  Future<User> register({
    required String name,
    required String phone,
    required String birthDate,
    required String gender,
    required String password,
    String email = '',
  });
  Future<User?> restoreSession();
  Future<void> logout();
}
