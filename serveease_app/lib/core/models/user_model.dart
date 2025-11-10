class UserModel {
  final String id;
  final String? name;
  final String email;
  final String role;

  UserModel({
    required this.id,
    this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String?,
    email: json['email'] as String,
    role: json['role'] as String,
  );
}
