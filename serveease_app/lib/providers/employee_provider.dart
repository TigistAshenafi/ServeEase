import 'package:flutter/material.dart';
import 'package:serveease_app/core/models/employee_model.dart';
import 'package:serveease_app/core/models/employee_performance_model.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/core/services/employee_service.dart';

class EmployeeProvider extends ChangeNotifier {
  List<Employee> employees = [];
  Map<String, EmployeePerformance> employeePerformances = {};
  Map<String, AvailabilitySchedule> employeeAvailabilities = {};
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
      employeePerformances.remove(id);
      employeeAvailabilities.remove(id);
      notifyListeners();
    }
    return res;
  }

  /// Get employees with matching skills
  Future<ApiResponse<List<Employee>>> getEmployeesWithMatchingSkills({
    required List<String> requiredSkills,
    String? organizationId,
  }) async {
    return await EmployeeService.getEmployeesWithMatchingSkills(
      requiredSkills: requiredSkills,
      organizationId: organizationId,
    );
  }

  /// Get employee performance
  Future<ApiResponse<EmployeePerformance>> getEmployeePerformance(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await EmployeeService.getEmployeePerformance(
      employeeId,
      startDate: startDate,
      endDate: endDate,
    );

    if (res.success && res.data != null) {
      employeePerformances[employeeId] = res.data!;
      notifyListeners();
    }

    return res;
  }

  /// Get employee availability
  Future<ApiResponse<AvailabilitySchedule>> getEmployeeAvailability(
    String employeeId,
  ) async {
    final res = await EmployeeService.getEmployeeAvailability(employeeId);

    if (res.success && res.data != null) {
      employeeAvailabilities[employeeId] = res.data!;
      notifyListeners();
    }

    return res;
  }

  /// Update employee availability
  Future<ApiResponse<AvailabilitySchedule>> updateEmployeeAvailability(
    String employeeId,
    AvailabilitySchedule availability,
  ) async {
    final res = await EmployeeService.updateEmployeeAvailability(
      employeeId,
      availability,
    );

    if (res.success && res.data != null) {
      employeeAvailabilities[employeeId] = res.data!;
      notifyListeners();
    }

    return res;
  }

  /// Get available employees for a time slot
  Future<ApiResponse<List<Employee>>> getAvailableEmployeesForTimeSlot({
    required DateTime startTime,
    required DateTime endTime,
    List<String>? requiredSkills,
    String? organizationId,
  }) async {
    return await EmployeeService.getAvailableEmployeesForTimeSlot(
      startTime: startTime,
      endTime: endTime,
      requiredSkills: requiredSkills,
      organizationId: organizationId,
    );
  }

  /// Get cached performance for employee
  EmployeePerformance? getCachedPerformance(String employeeId) {
    return employeePerformances[employeeId];
  }

  /// Get cached availability for employee
  AvailabilitySchedule? getCachedAvailability(String employeeId) {
    return employeeAvailabilities[employeeId];
  }
}
