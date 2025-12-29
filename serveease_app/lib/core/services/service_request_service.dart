// lib/core/services/service_request_service.dart
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/core/services/api_service.dart';

class ServiceRequestService {
  /// Create request by seeker
  static Future<ApiResponse<ServiceRequest>> create({
    required String serviceId,
    String? notes,
  }) async {
    try {
      final res = await ApiService.post(
        ApiService.serviceRequestBase,
        body: {'serviceId': serviceId, if (notes != null) 'notes': notes},
      );
      return ApiService.handleResponse<ServiceRequest>(
        res,
        (json) => ServiceRequest.fromJson(json['request'] ?? json),
      );
    } catch (e) {
      return ApiService.handleError<ServiceRequest>(e);
    }
  }

  /// List current user's requests (seeker or provider)
  static Future<ApiResponse<List<ServiceRequest>>> list({
    String status = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await ApiService.get(
        ApiService.serviceRequestBase,
        params: {
          'status': status,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      return ApiService.handleResponse<List<ServiceRequest>>(
        res,
        (json) => (json['requests'] as List<dynamic>? ?? [])
            .map((e) => ServiceRequest.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<ServiceRequest>>(e);
    }
  }

  /// Assign employee (providers only)
  static Future<ApiResponse<ServiceRequest>> assignEmployee({
    required String requestId,
    required String employeeId,
  }) async {
    try {
      final res = await ApiService.put(
        '${ApiService.serviceRequestBase}/$requestId/assign-employee',
        body: {'employeeId': employeeId},
      );
      return ApiService.handleResponse<ServiceRequest>(
        res,
        (json) => ServiceRequest.fromJson(json['request'] ?? json),
      );
    } catch (e) {
      return ApiService.handleError<ServiceRequest>(e);
    }
  }

  /// Update status (provider or seeker depending on backend rules)
  static Future<ApiResponse<ServiceRequest>> updateStatus({
    required String requestId,
    required String status,
    DateTime? scheduledDate,
    DateTime? completionDate,
    String? notes,
  }) async {
    try {
      final res = await ApiService.put(
        '${ApiService.serviceRequestBase}/$requestId/status',
        body: {
          'status': status,
          if (scheduledDate != null)
            'scheduledDate': scheduledDate.toIso8601String(),
          if (completionDate != null)
            'completionDate': completionDate.toIso8601String(),
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

  /// Add rating/review
  static Future<ApiResponse<void>> addRating({
    required String requestId,
    required int rating,
    String? review,
    bool isProviderReview = false,
  }) async {
    try {
      final res = await ApiService.post(
        '${ApiService.serviceRequestBase}/$requestId/rating',
        body: {
          'rating': rating,
          if (review != null) 'review': review,
          'isProviderReview': isProviderReview,
        },
      );
      return ApiService.handleResponse<void>(res, null);
    } catch (e) {
      return ApiService.handleError<void>(e);
    }
  }
}

