import 'package:serveease_app/core/models/employee_model.dart';
import 'package:serveease_app/core/models/employee_performance_model.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/core/services/api_service.dart';

class EmployeeAssignmentService {
  /// Assign employee to a service request
  static Future<ApiResponse<ServiceRequest>> assignEmployee({
    required String requestId,
    required String employeeId,
    String? notes,
  }) async {
    try {
      final res = await ApiService.put(
        '${ApiService.serviceRequestBase}/$requestId/assign',
        body: {
          'employeeId': employeeId,
          if (notes != null) 'notes': notes,
        },
      );

      return ApiService.handleResponse<ServiceRequest>(
        res,
        (json) => ServiceRequest.fromJson(json['request'] ?? json),
      );
    } catch (e) {
      return ApiService.handleError<ServiceRequest>(e);
    }
  }

  /// Get assignment recommendations based on skills, performance, and availability
  static Future<ApiResponse<List<EmployeeAssignmentRecommendation>>>
      getAssignmentRecommendations({
    required String requestId,
    required List<String> requiredSkills,
    DateTime? preferredStartTime,
    DateTime? preferredEndTime,
  }) async {
    try {
      final queryParams = {
        'requiredSkills': requiredSkills.join(','),
        if (preferredStartTime != null)
          'preferredStartTime': preferredStartTime.toIso8601String(),
        if (preferredEndTime != null)
          'preferredEndTime': preferredEndTime.toIso8601String(),
      };

      final res = await ApiService.get(
        '${ApiService.serviceRequestBase}/$requestId/assignment-recommendations',
        params: queryParams,
      );

      return ApiService.handleResponse<List<EmployeeAssignmentRecommendation>>(
        res,
        (json) => (json['recommendations'] as List<dynamic>? ?? [])
            .map((e) => EmployeeAssignmentRecommendation.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<EmployeeAssignmentRecommendation>>(e);
    }
  }

  /// Calculate skill match score between employee and required skills
  static double calculateSkillMatchScore(
    List<String> employeeSkills,
    List<String> requiredSkills,
  ) {
    if (requiredSkills.isEmpty) return 1.0;
    if (employeeSkills.isEmpty) return 0.0;

    final normalizedEmployeeSkills =
        employeeSkills.map((skill) => skill.toLowerCase().trim()).toSet();
    final normalizedRequiredSkills =
        requiredSkills.map((skill) => skill.toLowerCase().trim()).toSet();

    final matchingSkills =
        normalizedEmployeeSkills.intersection(normalizedRequiredSkills);

    return matchingSkills.length / normalizedRequiredSkills.length;
  }

  /// Calculate overall assignment score considering multiple factors
  static double calculateAssignmentScore({
    required double skillMatchScore,
    required double performanceScore,
    required double availabilityScore,
    Map<String, double> weights = const {
      'skills': 0.4,
      'performance': 0.35,
      'availability': 0.25,
    },
  }) {
    return (skillMatchScore * (weights['skills'] ?? 0.4)) +
        (performanceScore * (weights['performance'] ?? 0.35)) +
        (availabilityScore * (weights['availability'] ?? 0.25));
  }

  /// Get performance score from employee performance metrics
  static double getPerformanceScore(EmployeePerformance? performance) {
    if (performance == null) return 0.5; // Default neutral score

    // Normalize completion rate (0-1) and average rating (0-1 from 1-5 scale)
    final completionScore = performance.completionRate;
    final ratingScore = performance.averageRating > 0
        ? (performance.averageRating - 1) / 4 // Convert 1-5 to 0-1
        : 0.5;

    // Weight completion rate more heavily than rating
    return (completionScore * 0.6) + (ratingScore * 0.4);
  }

  /// Check if employee is available for a time slot
  static bool isEmployeeAvailable(
    AvailabilitySchedule? availability,
    DateTime startTime,
    DateTime endTime,
  ) {
    if (availability == null) return true; // Assume available if no schedule

    // Check if currently available
    if (!availability.isCurrentlyAvailable) return false;

    // Check unavailable dates
    for (final unavailableRange in availability.unavailableDates) {
      if (startTime.isBefore(unavailableRange.endDate) &&
          endTime.isAfter(unavailableRange.startDate)) {
        return false;
      }
    }

    // Check weekly schedule
    final dayOfWeek = _getDayOfWeek(startTime);
    final timeSlots = availability.weeklySchedule[dayOfWeek];

    if (timeSlots == null || timeSlots.isEmpty) return false;

    final requestStartTime =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final requestEndTime =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    // Check if request time falls within any available time slot
    for (final slot in timeSlots) {
      if (_isTimeInSlot(requestStartTime, requestEndTime, slot)) {
        return true;
      }
    }

    return false;
  }

  static String _getDayOfWeek(DateTime date) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[date.weekday - 1];
  }

  static bool _isTimeInSlot(String startTime, String endTime, TimeSlot slot) {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    final slotStart = _parseTime(slot.startTime);
    final slotEnd = _parseTime(slot.endTime);

    return start >= slotStart && end <= slotEnd;
  }

  static int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class EmployeeAssignmentRecommendation {
  final Employee employee;
  final double skillMatchScore;
  final double performanceScore;
  final double availabilityScore;
  final double overallScore;
  final List<String> matchingSkills;
  final List<String> missingSkills;
  final String? availabilityNote;

  EmployeeAssignmentRecommendation({
    required this.employee,
    required this.skillMatchScore,
    required this.performanceScore,
    required this.availabilityScore,
    required this.overallScore,
    required this.matchingSkills,
    required this.missingSkills,
    this.availabilityNote,
  });

  factory EmployeeAssignmentRecommendation.fromJson(Map<String, dynamic> json) {
    return EmployeeAssignmentRecommendation(
      employee: Employee.fromJson(json['employee']),
      skillMatchScore: (json['skillMatchScore'] ?? 0.0).toDouble(),
      performanceScore: (json['performanceScore'] ?? 0.0).toDouble(),
      availabilityScore: (json['availabilityScore'] ?? 0.0).toDouble(),
      overallScore: (json['overallScore'] ?? 0.0).toDouble(),
      matchingSkills: List<String>.from(json['matchingSkills'] ?? []),
      missingSkills: List<String>.from(json['missingSkills'] ?? []),
      availabilityNote: json['availabilityNote'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee': employee.toJson(),
      'skillMatchScore': skillMatchScore,
      'performanceScore': performanceScore,
      'availabilityScore': availabilityScore,
      'overallScore': overallScore,
      'matchingSkills': matchingSkills,
      'missingSkills': missingSkills,
      if (availabilityNote != null) 'availabilityNote': availabilityNote,
    };
  }
}
