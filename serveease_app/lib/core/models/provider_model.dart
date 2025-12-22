// lib/models/provider_profile.dart
import 'package:flutter/material.dart';

class ProviderProfile {
  final String id;
  final String userId;
  final String providerType; // 'individual' or 'organization'
  final String businessName;
  final String description;
  final String category;
  final String location;
  final String phone;
  final String? profileImageUrl;
  final List<String> certificates;
  final bool isApproved;
  final DateTime? approvalDate;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProviderUser? user;

  ProviderProfile({
    required this.id,
    required this.userId,
    required this.providerType,
    required this.businessName,
    required this.description,
    required this.category,
    required this.location,
    required this.phone,
    this.profileImageUrl,
    required this.certificates,
    required this.isApproved,
    this.approvalDate,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      providerType: json['providerType'] ?? json['provider_type'] ?? 'individual',
      businessName: json['businessName'] ?? json['business_name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      phone: json['phone'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? json['profile_image_url'],
      certificates: json['certificates'] != null
          ? List<String>.from(json['certificates'])
          : [],
      isApproved: json['isApproved'] ?? json['is_approved'] ?? false,
      approvalDate: json['approvalDate'] != null
          ? DateTime.parse(json['approvalDate'])
          : json['approval_date'] != null
              ? DateTime.parse(json['approval_date'])
              : null,
      adminNotes: json['adminNotes'] ?? json['admin_notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
      user: json['user'] != null ? ProviderUser.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerType': providerType,
      'businessName': businessName,
      'description': description,
      'category': category,
      'location': location,
      'phone': phone,
      'certificates': certificates,
    };
  }

  ProviderProfile copyWith({
    String? id,
    String? userId,
    String? providerType,
    String? businessName,
    String? description,
    String? category,
    String? location,
    String? phone,
    String? profileImageUrl,
    List<String>? certificates,
    bool? isApproved,
    DateTime? approvalDate,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProviderUser? user,
  }) {
    return ProviderProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      providerType: providerType ?? this.providerType,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      certificates: certificates ?? this.certificates,
      isApproved: isApproved ?? this.isApproved,
      approvalDate: approvalDate ?? this.approvalDate,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }
}

class ProviderUser {
  final String name;
  final String email;

  ProviderUser({
    required this.name,
    required this.email,
  });

  factory ProviderUser.fromJson(Map<String, dynamic> json) {
    return ProviderUser(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

// Categories for provider services
const List<Map<String, dynamic>> providerCategories = [
  {'id': 'plumbing', 'name': 'Plumbing', 'icon': Icons.plumbing, 'color': Colors.blue},
  {'id': 'electrical', 'name': 'Electrical', 'icon': Icons.electrical_services, 'color': Colors.orange},
  {'id': 'cleaning', 'name': 'Cleaning', 'icon': Icons.cleaning_services, 'color': Colors.green},
  {'id': 'moving', 'name': 'Moving & Transport', 'icon': Icons.local_shipping, 'color': Colors.purple},
  {'id': 'repair', 'name': 'Repair & Maintenance', 'icon': Icons.build, 'color': Colors.red},
  {'id': 'landscaping', 'name': 'Landscaping', 'icon': Icons.grass, 'color': Colors.lightGreen},
  {'id': 'painting', 'name': 'Painting', 'icon': Icons.format_paint, 'color': Colors.pink},
  {'id': 'carpentry', 'name': 'Carpentry', 'icon': Icons.construction, 'color': Colors.brown},
  {'id': 'computer', 'name': 'Computer Services', 'icon': Icons.computer, 'color': Colors.indigo},
  {'id': 'event', 'name': 'Event Services', 'icon': Icons.event, 'color': Colors.deepPurple},
  {'id': 'health', 'name': 'Health & Wellness', 'icon': Icons.health_and_safety, 'color': Colors.teal},
  {'id': 'education', 'name': 'Education & Tutoring', 'icon': Icons.school, 'color': Colors.deepOrange},
];