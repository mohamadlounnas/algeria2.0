import 'package:dio/dio.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../../../core/constants/api_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio dio;

  AuthRepositoryImpl({required this.dio});

  @override
  Future<({User user, String token})> signIn(String email, String password) async {
    try {
      final response = await dio.post(
        '${ApiConstants.auth}/sign-in',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      return (user: user, token: token);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Sign in failed');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<({User user, String token})> signUp(String email, String password, String name) async {
    try {
      final response = await dio.post(
        '${ApiConstants.auth}/sign-up',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      return (user: user, token: token);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Sign up failed');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<User> getCurrentUser() async {
    try {
      final response = await dio.get('${ApiConstants.auth}/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get user');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<void> signOut() async {
    // Token is cleared in the provider
    // No API call needed for sign out
  }
}

