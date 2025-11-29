import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: _roleFromString(json['role'] as String),
    );
  }

  static UserRole _roleFromString(String role) {
    switch (role.toUpperCase()) {
      case 'FARMER':
        return UserRole.farmer;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.farmer;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role == UserRole.admin ? 'ADMIN' : 'FARMER',
    };
  }
}

