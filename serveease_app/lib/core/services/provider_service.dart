// lib/services/provider_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:serveease_app/core/models/provider_model.dart';
import '../services/api_service.dart';

// Service Category Model
class ServiceCategory {
  final String id;
  final String name;
  final String? description;
  final String? icon;

  ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
    );
  }
}

class ProviderService {
  // Get service categories from backend
  static Future<ApiResponse<List<ServiceCategory>>> getServiceCategories() async {
    try {
      log('📤 Fetching service categories', name: 'ProviderService');

      final response = await ApiService.get(
        '${ApiService.servicesBase}/categories',
        withAuth: false, // Categories are public
      );

      log('📥 Categories response: ${response.statusCode}', name: 'ProviderService');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final categories = (json['categories'] as List<dynamic>)
            .map((categoryJson) => ServiceCategory.fromJson(categoryJson))
            .toList();

        return ApiResponse<List<ServiceCategory>>(
          success: true,
          message: 'Categories loaded successfully',
          data: categories,
        );
      } else {
        final json = jsonDecode(response.body);
        return ApiResponse<List<ServiceCategory>>(
          success: false,
          message: json['message'] ?? 'Failed to load categories',
        );
      }
    } catch (e) {
      log('❌ Get categories error: $e', name: 'ProviderService');
      return ApiResponse<List<ServiceCategory>>(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  // Create or update provider profile
  static Future<ApiResponse<ProviderProfile>> createOrUpdateProfile({
    required String providerType,
    required String businessName,
    required String description,
    required String category,
    required String location,
    required String phone,
    List<String> certificates = const [],
  }) async {
    try {
      final url = '${ApiService.providerBase}/profile';

      log('📤 Creating/Updating provider profile', name: 'ProviderService');

      final response = await ApiService.post(
        url,
        body: {
          'providerType': providerType,
          'businessName': businessName,
          'description': description,
          'category': category,
          'location': location,
          'phone': phone,
          'certificates': certificates,
        },
      );

      log('📥 Profile response: ${response.statusCode}', name: 'ProviderService');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse<ProviderProfile>(
          success: true,
          message: json['message'],
          data: ProviderProfile.fromJson(json['profile']),
        );
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final json = jsonDecode(response.body);
        return ApiResponse<ProviderProfile>(
          success: false,
          message: json['message'] ?? 'Failed to save profile',
        );
      } else {
        return ApiResponse<ProviderProfile>(
          success: false,
          message: 'Server error. Please try again.',
        );
      }
    } catch (e) {
      log('❌ Profile error: $e', name: 'ProviderService');
      return ApiResponse<ProviderProfile>(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  // Get provider profile
  static Future<ApiResponse<ProviderProfile>> getProfile() async {
    try {
      final url = '${ApiService.providerBase}/profile';

      log('📤 Fetching provider profile', name: 'ProviderService');

      final response = await ApiService.get(url);

      log('📥 Profile fetch response: ${response.statusCode}', name: 'ProviderService');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse<ProviderProfile>(
          success: true,
          message: json['message'] ?? 'Profile loaded successfully',
          data: ProviderProfile.fromJson(json['profile']),
        );
      } else if (response.statusCode == 404) {
        return ApiResponse<ProviderProfile>(
          success: false,
          message: 'Profile not found. Please create one.',
        );
      } else {
        final json = jsonDecode(response.body);
        return ApiResponse<ProviderProfile>(
          success: false,
          message: json['message'] ?? 'Failed to load profile',
        );
      }
    } catch (e) {
      log('❌ Get profile error: $e', name: 'ProviderService');
      return ApiResponse<ProviderProfile>(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  // Upload certificate/image
  static Future<ApiResponse<String>> uploadCertificate({
    required String filePath,
    required String fileName,
  }) async {
    // This is a placeholder - you'll need to implement actual file upload
    // using multipart request or a cloud service
    await Future.delayed(Duration(seconds: 2));
    
    // Simulate successful upload
    return ApiResponse<String>(
      success: true,
      message: 'Certificate uploaded successfully',
      data: 'https://example.com/certificates/$fileName',
    );
  }

  /// Admin: list provider profiles
  static Future<ApiResponse<List<ProviderProfile>>> listProviders({
    String status = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '${ApiService.providerBase}/admin/providers',
        params: {
          'status': status,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      return ApiService.handleResponse<List<ProviderProfile>>(
        response,
        (json) => (json['providers'] as List<dynamic>? ?? [])
            .map((e) => ProviderProfile.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<ProviderProfile>>(e);
    }
  }

  /// Admin: approve provider application
  static Future<ApiResponse<ProviderProfile>> approveProvider({
    required String providerId,
    String? adminNotes,
  }) async {
    try {
      final response = await ApiService.put(
        '${ApiService.providerBase}/admin/providers/$providerId/approve',
        body: {
          if (adminNotes != null && adminNotes.isNotEmpty)
            'adminNotes': adminNotes,
        },
      );

      return ApiService.handleResponse<ProviderProfile>(
        response,
        (json) => ProviderProfile.fromJson(
          (json['profile'] ?? json)..['id'] = providerId,
        ),
      );
    } catch (e) {
      return ApiService.handleError<ProviderProfile>(e);
    }
  }

  /// Admin: reject provider application
  static Future<ApiResponse<ProviderProfile>> rejectProvider({
    required String providerId,
    String? adminNotes,
  }) async {
    try {
      final response = await ApiService.put(
        '${ApiService.providerBase}/admin/providers/$providerId/reject',
        body: {
          if (adminNotes != null && adminNotes.isNotEmpty)
            'adminNotes': adminNotes,
        },
      );

      return ApiService.handleResponse<ProviderProfile>(
        response,
        (json) => ProviderProfile.fromJson(
          (json['profile'] ?? json)..['id'] = providerId,
        ),
      );
    } catch (e) {
      return ApiService.handleError<ProviderProfile>(e);
    }
  }
}