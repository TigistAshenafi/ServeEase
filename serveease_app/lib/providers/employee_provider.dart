import 'package:flutter/material.dart';
import 'package:serveease_app/core/models/employee_model.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/core/services/employee_service.dart';

class EmployeeProvider extends ChangeNotifier {
  List<Employee> employees = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchEmployees() async {
    isLoading = true;
    notifyListeners();
    final res = await EmployeeService.list();
    isLoading = false;
    if (res.success && res.data != null) {
      employees = res.data!;
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
  }

  Future<ApiResponse<Employee>> addEmployee({
    required String name,
    required String email,
    required String phone,
    required String position,
    List<String> skills = const [],
  }) async {
    final res = await EmployeeService.add(
      employeeName: name,
      email: email,
      role: position,
      phone: phone,
      skills: skills,
    );
    if (res.success && res.data != null) {
      employees.insert(0, res.data!);
      notifyListeners();
    } else {
      error = res.message;
      notifyListeners();
    }
    return res;
  }

  Future<ApiResponse<Employee>> updateEmployee({
    required String employeeId,
    required String name,
    required String email,
    required String phone,
    required String position,
    List<String> skills = const [],
  }) async {
    final res = await EmployeeService.update(
      employeeId: employeeId,
      employeeName: name,
      email: email,
      role: position,
      phone: phone,
      skills: skills,
    );
    if (res.success && res.data != null) {
      final idx = employees.indexWhere((e) => e.id == employeeId);
      if (idx != -1) employees[idx] = res.data!;
      notifyListeners();
    } else {
      error = res.message;
      notifyListeners();
    }
    return res;
  }

  Future<ApiResponse<void>> toggleEmployeeStatus(String employeeId) async {
    final employee = employees.firstWhere((e) => e.id == employeeId);
    final res = await EmployeeService.update(
      employeeId: employeeId,
      isActive: !employee.isActive,
    );
    if (res.success && res.data != null) {
      final idx = employees.indexWhere((e) => e.id == employeeId);
      if (idx != -1) employees[idx] = res.data!;
      notifyListeners();
    }
    return ApiResponse<void>(success: res.success, message: res.message);
  }

  Future<ApiResponse<void>> remove(String id) async {
    final res = await EmployeeService.remove(id);
    if (res.success) {
      employees.removeWhere((e) => e.id == id);
      notifyListeners();
    }
    return res;
  }
}

