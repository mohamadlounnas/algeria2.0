import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/auth/domain/entities/user.dart';

void main() {
  group('User Entity', () {
    test('should create a user with all properties', () {
      const user = User(
        id: 'user-1',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.farmer,
      );

      expect(user.id, equals('user-1'));
      expect(user.email, equals('test@example.com'));
      expect(user.name, equals('Test User'));
      expect(user.role, equals(UserRole.farmer));
    });

    test('should support admin role', () {
      const user = User(
        id: 'user-2',
        email: 'admin@example.com',
        name: 'Admin User',
        role: UserRole.admin,
      );

      expect(user.role, equals(UserRole.admin));
    });

    test('should be equal when all properties match', () {
      const user1 = User(
        id: 'user-1',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.farmer,
      );

      const user2 = User(
        id: 'user-1',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.farmer,
      );

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('should not be equal when properties differ', () {
      const user1 = User(
        id: 'user-1',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.farmer,
      );

      const user2 = User(
        id: 'user-2',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.farmer,
      );

      expect(user1, isNot(equals(user2)));
    });
  });
}

