// lib/core/models/service_request_model.dart

// import 'service_model.dart';

class ServiceRequest {
  final String id;
  final String seekerId;
  final String providerId;
  final String serviceId;
  final String status;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final DateTime? completionDate;
  final String? notes;
  final int? seekerRating;
  final String? seekerReview;
  final int? providerRating;
  final String? providerReview;
  final ServiceSummary service;
  final PartyInfo seeker;
  final PartyInfo provider;
  final String? assignedEmployeeId;
  final EmployeeInfo? assignedEmployee;
  final List<StatusChange> statusHistory;
  final String urgency;
  final DateTime? estimatedCompletionDate;
  final DateTime? actualCompletionDate;
  final bool notificationsEnabled;

  ServiceRequest({
    required this.id,
    required this.seekerId,
    required this.providerId,
    required this.serviceId,
    required this.status,
    required this.createdAt,
    this.scheduledDate,
    this.completionDate,
    this.notes,
    this.seekerRating,
    this.seekerReview,
    this.providerRating,
    this.providerReview,
    required this.service,
    required this.seeker,
    required this.provider,
    this.assignedEmployeeId,
    this.assignedEmployee,
    this.statusHistory = const [],
    this.urgency = 'medium',
    this.estimatedCompletionDate,
    this.actualCompletionDate,
    this.notificationsEnabled = true,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id']?.toString() ?? '',
      seekerId:
          json['seekerId']?.toString() ?? json['seeker_id']?.toString() ?? '',
      providerId: json['providerId']?.toString() ??
          json['provider_id']?.toString() ??
          '',
      serviceId:
          json['serviceId']?.toString() ?? json['service_id']?.toString() ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(
          json['createdAt'] ?? json['created_at'] ?? DateTime.now().toString()),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'])
          : json['scheduled_date'] != null
              ? DateTime.tryParse(json['scheduled_date'])
              : null,
      completionDate: json['completionDate'] != null
          ? DateTime.tryParse(json['completionDate'])
          : json['completion_date'] != null
              ? DateTime.tryParse(json['completion_date'])
              : null,
      notes: json['notes'],
      seekerRating: json['seekerRating'] ?? json['seeker_rating'],
      seekerReview: json['seekerReview'] ?? json['seeker_review'],
      providerRating: json['providerRating'] ?? json['provider_rating'],
      providerReview: json['providerReview'] ?? json['provider_review'],
      assignedEmployeeId: json['assigned_employee_id']?.toString(),
      assignedEmployee: json['assignedEmployee'] != null
          ? EmployeeInfo.fromJson(json['assignedEmployee'])
          : json['assigned_employee'] != null
              ? EmployeeInfo.fromJson(json['assigned_employee'])
              : null,
      statusHistory: (json['statusHistory'] as List<dynamic>? ??
              json['status_history'] as List<dynamic>? ??
              [])
          .map((e) => StatusChange.fromJson(e))
          .toList(),
      urgency: json['urgency'] ?? 'medium',
      estimatedCompletionDate: json['estimatedCompletionDate'] != null
          ? DateTime.tryParse(json['estimatedCompletionDate'])
          : json['estimated_completion_date'] != null
              ? DateTime.tryParse(json['estimated_completion_date'])
              : null,
      actualCompletionDate: json['actualCompletionDate'] != null
          ? DateTime.tryParse(json['actualCompletionDate'])
          : json['actual_completion_date'] != null
              ? DateTime.tryParse(json['actual_completion_date'])
              : null,
      notificationsEnabled:
          json['notificationsEnabled'] ?? json['notifications_enabled'] ?? true,
      service: ServiceSummary(
        title: json['service']?['title'] ??
            json['service_title'] ??
            json['serviceName'] ??
            'Unknown Service',
        price: ((json['service']?['price'] ??
                json['service_price'] ??
                json['price'] ??
                0) as num)
            .toDouble(),
        durationHours: (json['service']?['durationHours'] ??
            json['duration_hours'] ??
            json['duration'] ??
            0) as int,
      ),
      seeker: PartyInfo(
        name: json['seeker']?['name'] ?? json['seeker_name'] ?? 'Unknown Seeker',
        email: json['seeker']?['email'] ?? json['seeker_email'],
      ),
      provider: PartyInfo(
        name: json['provider']?['name'] ?? json['provider_name'] ?? 'Unknown Provider',
        email: json['provider']?['email'] ?? json['provider_email'],
        businessName:
            json['provider']?['businessName'] ?? json['provider_business_name'],
        location:
            json['provider']?['location'] ?? json['provider_location'] ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seekerId': seekerId,
      'providerId': providerId,
      'serviceId': serviceId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (scheduledDate != null)
        'scheduledDate': scheduledDate!.toIso8601String(),
      if (completionDate != null)
        'completionDate': completionDate!.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (seekerRating != null) 'seekerRating': seekerRating,
      if (seekerReview != null) 'seekerReview': seekerReview,
      if (providerRating != null) 'providerRating': providerRating,
      if (providerReview != null) 'providerReview': providerReview,
      if (assignedEmployeeId != null) 'assignedEmployeeId': assignedEmployeeId,
      'urgency': urgency,
      if (estimatedCompletionDate != null)
        'estimatedCompletionDate': estimatedCompletionDate!.toIso8601String(),
      if (actualCompletionDate != null)
        'actualCompletionDate': actualCompletionDate!.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
    };
  }

  // Helper methods for status validation
  bool canTransitionTo(String newStatus) {
    const validTransitions = {
      'pending': ['accepted', 'rejected', 'cancelled'],
      'accepted': ['assigned', 'in_progress', 'cancelled'],
      'assigned': ['in_progress', 'cancelled'],
      'in_progress': ['completed', 'cancelled'],
      'completed': [], // Terminal state
      'rejected': [], // Terminal state
      'cancelled': [], // Terminal state
    };

    return validTransitions[status]?.contains(newStatus) ?? false;
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get canBeRated =>
      isCompleted && (seekerRating == null || providerRating == null);
  bool get requiresEmployeeAssignment =>
      status == 'accepted' && assignedEmployeeId == null;
}

class ServiceSummary {
  final String title;
  final double price;
  final int durationHours;

  ServiceSummary({
    required this.title,
    required this.price,
    required this.durationHours,
  });
}

class PartyInfo {
  final String name;
  final String? email;
  final String? businessName;
  final String? location;

  PartyInfo({
    required this.name,
    this.email,
    this.businessName,
    this.location,
  });
}

class EmployeeInfo {
  final String id;
  final String name;
  final String email;
  final String position;
  final List<String> skills;

  EmployeeInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
    required this.skills,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      position: json['position'] ?? '',
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class StatusChange {
  final String fromStatus;
  final String toStatus;
  final DateTime timestamp;
  final String? notes;
  final String? changedBy;
  final String? reason;

  StatusChange({
    required this.fromStatus,
    required this.toStatus,
    required this.timestamp,
    this.notes,
    this.changedBy,
    this.reason,
  });

  factory StatusChange.fromJson(Map<String, dynamic> json) {
    return StatusChange(
      fromStatus: json['fromStatus'] ?? json['from_status'] ?? '',
      toStatus: json['toStatus'] ?? json['to_status'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
      notes: json['notes'],
      changedBy: json['changedBy'] ?? json['changed_by'],
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromStatus': fromStatus,
      'toStatus': toStatus,
      'timestamp': timestamp.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (changedBy != null) 'changedBy': changedBy,
      if (reason != null) 'reason': reason,
    };
  }
}

// Request creation data model
class ServiceRequestData {
  final String serviceId;
  final String providerId;
  final String? notes;
  final DateTime? scheduledDate;
  final String urgency;

  ServiceRequestData({
    required this.serviceId,
    required this.providerId,
    this.notes,
    this.scheduledDate,
    this.urgency = 'medium',
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'providerId': providerId,
      if (notes != null) 'notes': notes,
      if (scheduledDate != null)
        'scheduledDate': scheduledDate!.toIso8601String(),
      'urgency': urgency,
    };
  }
}
