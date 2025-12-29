// lib/models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool emailVerified;
  final DateTime? createdAt;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.emailVerified,
    this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      emailVerified: json['emailVerified'] ?? json['email_verified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
  
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? emailVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
}