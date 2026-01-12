class EmployeePerformance {
  final String employeeId;
  final int totalAssignments;
  final int completedAssignments;
  final double averageRating;
  final double completionRate;
  final double averageCompletionTimeHours;
  final DateTime calculatedAt;

  EmployeePerformance({
    required this.employeeId,
    required this.totalAssignments,
    required this.completedAssignments,
    required this.averageRating,
    required this.completionRate,
    required this.averageCompletionTimeHours,
    required this.calculatedAt,
  });

  factory EmployeePerformance.fromJson(Map<String, dynamic> json) {
    return EmployeePerformance(
      employeeId: json['employeeId']?.toString() ??
          json['employee_id']?.toString() ??
          '',
      totalAssignments:
          json['totalAssignments'] ?? json['total_assignments'] ?? 0,
      completedAssignments:
          json['completedAssignments'] ?? json['completed_assignments'] ?? 0,
      averageRating:
          (json['averageRating'] ?? json['average_rating'] ?? 0.0).toDouble(),
      completionRate:
          (json['completionRate'] ?? json['completion_rate'] ?? 0.0).toDouble(),
      averageCompletionTimeHours: (json['averageCompletionTimeHours'] ??
              json['average_completion_time_hours'] ??
              0.0)
          .toDouble(),
      calculatedAt: DateTime.parse(json['calculatedAt'] ??
          json['calculated_at'] ??
          DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'totalAssignments': totalAssignments,
      'completedAssignments': completedAssignments,
      'averageRating': averageRating,
      'completionRate': completionRate,
      'averageCompletionTimeHours': averageCompletionTimeHours,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }
}

class AvailabilitySchedule {
  final String employeeId;
  final Map<String, List<TimeSlot>> weeklySchedule; // day -> time slots
  final List<DateRange> unavailableDates;
  final bool isCurrentlyAvailable;
  final DateTime updatedAt;

  AvailabilitySchedule({
    required this.employeeId,
    required this.weeklySchedule,
    required this.unavailableDates,
    required this.isCurrentlyAvailable,
    required this.updatedAt,
  });

  factory AvailabilitySchedule.fromJson(Map<String, dynamic> json) {
    final weeklyScheduleJson =
        json['weeklySchedule'] ?? json['weekly_schedule'] ?? {};
    final weeklySchedule = <String, List<TimeSlot>>{};

    weeklyScheduleJson.forEach((day, slots) {
      weeklySchedule[day] = (slots as List<dynamic>)
          .map((slot) => TimeSlot.fromJson(slot))
          .toList();
    });

    return AvailabilitySchedule(
      employeeId: json['employeeId']?.toString() ??
          json['employee_id']?.toString() ??
          '',
      weeklySchedule: weeklySchedule,
      unavailableDates:
          (json['unavailableDates'] ?? json['unavailable_dates'] ?? [])
              .map<DateRange>((date) => DateRange.fromJson(date))
              .toList(),
      isCurrentlyAvailable: json['isCurrentlyAvailable'] ??
          json['is_currently_available'] ??
          true,
      updatedAt: DateTime.parse(
          json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    final weeklyScheduleJson = <String, dynamic>{};
    weeklySchedule.forEach((day, slots) {
      weeklyScheduleJson[day] = slots.map((slot) => slot.toJson()).toList();
    });

    return {
      'employeeId': employeeId,
      'weeklySchedule': weeklyScheduleJson,
      'unavailableDates':
          unavailableDates.map((date) => date.toJson()).toList(),
      'isCurrentlyAvailable': isCurrentlyAvailable,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class TimeSlot {
  final String startTime; // HH:mm format
  final String endTime; // HH:mm format

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['startTime'] ?? json['start_time'] ?? '',
      endTime: json['endTime'] ?? json['end_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class DateRange {
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;

  DateRange({
    required this.startDate,
    required this.endDate,
    this.reason,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      startDate: DateTime.parse(json['startDate'] ?? json['start_date']),
      endDate: DateTime.parse(json['endDate'] ?? json['end_date']),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (reason != null) 'reason': reason,
    };
  }
}
