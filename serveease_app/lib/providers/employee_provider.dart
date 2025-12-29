import 'package:flutter/material.dart';
import 'package:serveease_app/core/models/employee_model.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/core/services/employee_service.dart';

class EmployeeProvider extends ChangeNotifier {
  List<Employee> employees = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
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

  Future<ApiResponse<Employee>> add({
    required String employeeName,
    required String email,
    required String role,
    String? phone,
    List<String>? skills,
  }) async {
    final res = await EmployeeService.add(
      employeeName: employeeName,
      email: email,
      role: role,
      phone: phone,
      skills: skills,
    );
    if (res.success && res.data != null) {
      employees.insert(0, res.data!);
      notifyListeners();
    }
    return res;
  }

  Future<ApiResponse<Employee>> update(
    String id, {
    String? employeeName,
    String? email,
    String? role,
    String? phone,
    List<String>? skills,
    bool? isActive,
  }) async {
    final res = await EmployeeService.update(
      employeeId: id,
      employeeName: employeeName,
      email: email,
      role: role,
      phone: phone,
      skills: skills,
      isActive: isActive,
    );
    if (res.success && res.data != null) {
      final idx = employees.indexWhere((e) => e.id == id);
      if (idx != -1) employees[idx] = res.data!;
      notifyListeners();
    }
    return res;
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

