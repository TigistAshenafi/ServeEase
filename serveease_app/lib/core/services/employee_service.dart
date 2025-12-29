// lib/core/services/employee_service.dart
import 'package:serveease_app/core/models/employee_model.dart';
import 'package:serveease_app/core/services/api_service.dart';

class EmployeeService {
  /// List employees for organization
  static Future<ApiResponse<List<Employee>>> list() async {
    try {
      final res = await ApiService.get(ApiService.employeeBase);
      return ApiService.handleResponse<List<Employee>>(
        res,
        (json) => (json['employees'] as List<dynamic>? ?? [])
            .map((e) => Employee.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<Employee>>(e);
    }
  }

  /// Add employee
  static Future<ApiResponse<Employee>> add({
    required String employeeName,
    required String email,
    required String role,
    String? phone,
    List<String>? skills,
    String? hireDate,
  }) async {
    try {
      final res = await ApiService.post(
        ApiService.employeeBase,
        body: {
          'employeeName': employeeName,
          'email': email,
          'role': role,
          if (phone != null) 'phone': phone,
          if (skills != null) 'skills': skills,
          if (hireDate != null) 'hireDate': hireDate,
        },
      );
      return ApiService.handleResponse<Employee>(
        res,
        (json) => Employee.fromJson(json['employee'] ?? json),
      );
    } catch (e) {
      return ApiService.handleError<Employee>(e);
    }
  }

  /// Update employee
  static Future<ApiResponse<Employee>> update({
    required String employeeId,
    String? employeeName,
    String? email,
    String? role,
    String? phone,
    List<String>? skills,
    bool? isActive,
    String? hireDate,
  }) async {
    final body = <String, dynamic>{};
    if (employeeName != null) body['employeeName'] = employeeName;
    if (email != null) body['email'] = email;
    if (role != null) body['role'] = role;
    if (phone != null) body['phone'] = phone;
    if (skills != null) body['skills'] = skills;
    if (isActive != null) body['isActive'] = isActive;
    if (hireDate != null) body['hireDate'] = hireDate;

    try {
      final res = await ApiService.put(
        '${ApiService.employeeBase}/$employeeId',
        body: body,
      );
      return ApiService.handleResponse<Employee>(
        res,
        (json) => Employee.fromJson(json['employee'] ?? json),
      );
    } catch (e) {
      return ApiService.handleError<Employee>(e);
    }
  }

  /// Remove employee (soft delete)
  static Future<ApiResponse<void>> remove(String employeeId) async {
    try {
      final res =
          await ApiService.delete('${ApiService.employeeBase}/$employeeId');
      return ApiService.handleResponse<void>(res, null);
    } catch (e) {
      return ApiService.handleError<void>(e);
    }
  }

  /// Available employees for a service (organization)
  static Future<ApiResponse<List<Employee>>> availableForService(
      String serviceId) async {
    try {
      final res =
          await ApiService.get('${ApiService.employeeBase}/available/$serviceId');
      return ApiService.handleResponse<List<Employee>>(
        res,
        (json) => (json['employees'] as List<dynamic>? ?? [])
            .map((e) => Employee.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<Employee>>(e);
    }
  }
}

