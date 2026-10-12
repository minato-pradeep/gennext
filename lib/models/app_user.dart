import 'user_permissions.dart';

class AppUser {
  final String id;
  final String username;
  final String password;
  final String role; // 'master', 'owner', 'security', 'visitor'
  final String name;
  final String apartment;
  final String phone;
  final DateTime createdAt;
  bool isActive;
  UserPermissions permissions;

  AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.name,
    required this.apartment,
    required this.phone,
    required this.createdAt,
    this.isActive = true,
    required this.permissions,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
      apartment: json['apartment'] as String,
      phone: json['phone'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      permissions: UserPermissions.fromJson(json['permissions'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'password': password,
    'role': role,
    'name': name,
    'apartment': apartment,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
    'permissions': permissions.toJson(),
  };
}