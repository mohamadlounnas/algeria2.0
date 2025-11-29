import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/auth/data/models/user_model.dart';
import 'package:dowa/features/auth/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    test('should create UserModel from JSON', () {
      final json = {
        'id': 'user-1',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'FARMER',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals('user-1'));
      expect(user.email, equals('test@example.com'));
      expect(user.name, equals('Test User'));
      expect(user.role, equals(UserRole.farmer));
    });

    test('should parse ADMIN role correctly', () {
      final json = {
        'id': 'user-2',
        'email': 'admin@example.com',
        'name': 'Admin User',
        'role': 'ADMIN',
      };

      final user = UserModel.fromJson(json);

      expect(user.role, equals(UserRole.admin));
    });

    test('should convert to JSON', () {
      const user = UserModel(
        id: 'user-1',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.farmer,
      );

      final json = user.toJson();

      expect(json['id'], equals('user-1'));
      expect(json['email'], equals('test@example.com'));
      expect(json['name'], equals('Test User'));
      expect(json['role'], equals('FARMER'));
    });

    test('should convert admin role to JSON correctly', () {
      const user = UserModel(
        id: 'user-2',
        email: 'admin@example.com',
        name: 'Admin User',
        role: UserRole.admin,
      );

      final json = user.toJson();

      expect(json['role'], equals('ADMIN'));
    });

    test('should implement User entity', () {
      const user = UserModel(
        id: 'user-1',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.farmer,
      );

      expect(user, isA<User>());
    });
  });
}

