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
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id']?.toString() ?? '',
      seekerId: json['seekerId']?.toString() ??
          json['seeker_id']?.toString() ??
          '',
      providerId: json['providerId']?.toString() ??
          json['provider_id']?.toString() ??
          '',
      serviceId: json['serviceId']?.toString() ??
          json['service_id']?.toString() ??
          '',
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
      service: ServiceSummary(
        title: json['service']?['title'] ??
            json['service_title'] ??
            json['serviceName'] ??
            '',
        price: (json['service']?['price'] ??
                json['service_price'] ??
                json['price'] ??
                0)
            .toDouble(),
        durationHours: json['service']?['durationHours'] ??
            json['duration_hours'] ??
            json['duration'] ??
            0,
      ),
      seeker: PartyInfo(
        name: json['seeker']?['name'] ?? json['seeker_name'] ?? '',
        email: json['seeker']?['email'] ?? json['seeker_email'],
      ),
      provider: PartyInfo(
        name: json['provider']?['name'] ?? json['provider_name'] ?? '',
        email: json['provider']?['email'] ?? json['provider_email'],
        businessName:
            json['provider']?['businessName'] ?? json['provider_business_name'],
        location:
            json['provider']?['location'] ?? json['provider_location'] ?? '',
      ),
    );
  }
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

