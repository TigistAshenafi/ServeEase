// lib/core/models/employee_model.dart

class Employee {
  final String id;
  final String organizationId;
  final String? userId;
  final String employeeName;
  final String email;
  final String? phone;
  final String role;
  final List<String> skills;
  final bool isActive;
  final DateTime? hireDate;

  Employee({
    required this.id,
    required this.organizationId,
    required this.employeeName,
    required this.email,
    required this.role,
    required this.skills,
    required this.isActive,
    this.userId,
    this.phone,
    this.hireDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ??
          json['organization_id']?.toString() ??
          '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString(),
      employeeName: json['employeeName'] ?? json['employee_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      skills: json['skills'] != null
          ? List<String>.from(json['skills'])
          : <String>[],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      hireDate: json['hireDate'] != null
          ? DateTime.tryParse(json['hireDate'])
          : json['hire_date'] != null
              ? DateTime.tryParse(json['hire_date'])
              : null,
    );
  }
}

