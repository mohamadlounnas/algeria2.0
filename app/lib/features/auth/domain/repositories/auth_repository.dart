import '../entities/user.dart';

abstract class AuthRepository {
  Future<({User user, String token})> signIn(String email, String password);
  Future<({User user, String token})> signUp(String email, String password, String name);
  Future<User> getCurrentUser();
  Future<void> signOut();
}

