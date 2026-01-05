class Employee {
  final String id;
  final String organizationId;
  final String userId;
  final String employeeName;
  final String email;
  final String? phone;
  final String role;
  final List<String> skills;
  final bool isActive;
  final DateTime? hireDate;
  final Map<String, dynamic>? documents;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.employeeName,
    required this.email,
    this.phone,
    required this.role,
    required this.skills,
    required this.isActive,
    this.hireDate,
    this.documents,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convenience getters for compatibility
  String get name => employeeName;
  String get position => role;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ?? json['organization_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      employeeName: json['employeeName'] ?? json['employee_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      skills: json['skills'] != null 
          ? List<String>.from(json['skills'])
          : [],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      hireDate: json['hireDate'] != null 
          ? DateTime.tryParse(json['hireDate']) 
          : json['hire_date'] != null 
              ? DateTime.tryParse(json['hire_date'])
              : null,
      documents: json['documents'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeName': employeeName,
      'email': email,
      if (phone != null) 'phone': phone,
      'role': role,
      'skills': skills,
      if (hireDate != null) 'hireDate': hireDate!.toIso8601String(),
    };
  }

  Employee copyWith({
    String? id,
    String? organizationId,
    String? userId,
    String? employeeName,
    String? email,
    String? phone,
    String? role,
    List<String>? skills,
    bool? isActive,
    DateTime? hireDate,
    Map<String, dynamic>? documents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      employeeName: employeeName ?? this.employeeName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      skills: skills ?? this.skills,
      isActive: isActive ?? this.isActive,
      hireDate: hireDate ?? this.hireDate,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}