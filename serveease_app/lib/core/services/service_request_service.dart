// lib/core/services/service_request_service.dart
// import 'dart:convert';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/core/services/api_service.dart';

class ServiceRequestService {
  /// Create request by seeker
  static Future<ApiResponse<ServiceRequest>> create({
    required String serviceId,
    required String providerId,
    String? notes,
    DateTime? scheduledDate,
    String urgency = 'medium',
  }) async {
    try {
      final requestData = ServiceRequestData(
        serviceId: serviceId,
        providerId: providerId,
        notes: notes,
        scheduledDate: scheduledDate,
        urgency: urgency,
      );

      final res = await ApiService.post(
        ApiService.serviceRequestBase,
        body: requestData.toJson(),
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
    String? role, // 'seeker' or 'provider'
  }) async {
    try {
      final res = await ApiService.get(
        ApiService.serviceRequestBase,
        params: {
          'status': status,
          'page': page.toString(),
          'limit': limit.toString(),
          if (role != null) 'role': role,
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

  /// Get single request with full details
  static Future<ApiResponse<ServiceRequest>> getRequest(
      String requestId) async {
    try {
      // Validate request ID
      if (requestId.isEmpty) {
        return ApiResponse<ServiceRequest>(
          success: false,
          message: 'Request ID cannot be empty',
        );
      }

      print('ServiceRequestService: Making request to ${ApiService.serviceRequestBase}/$requestId');
      final res = await ApiService.get(
        '${ApiService.serviceRequestBase}/$requestId',
      );
      
      print('ServiceRequestService: Response status: ${res.statusCode}');
      print('ServiceRequestService: Response body: ${res.body}');
      
      return ApiService.handleResponse<ServiceRequest>(
        res,
        (json) {
          try {
            // Handle both possible response formats
            final requestData = json['request'] ?? json;
            if (requestData == null) {
              throw Exception('No request data found in response');
            }
            return ServiceRequest.fromJson(requestData);
          } catch (e) {
            throw Exception('Error parsing ServiceRequest: $e');
          }
        },
      );
    } catch (e) {
      print('ServiceRequestService: Exception: $e');
      return ApiService.handleError<ServiceRequest>(e);
    }
  }

  /// Accept request (provider only)
  static Future<ApiResponse<ServiceRequest>> acceptRequest({
    required String requestId,
    String? notes,
    DateTime? scheduledDate,
  }) async {
    try {
      final res = await ApiService.put(
        '${ApiService.serviceRequestBase}/$requestId/accept',
        body: {
          if (notes != null) 'notes': notes,
          if (scheduledDate != null)
            'scheduledDate': scheduledDate.toIso8601String(),
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

  /// Reject request (provider only)
  static Future<ApiResponse<ServiceRequest>> rejectRequest({
    required String requestId,
    required String reason,
  }) async {
    try {
      final res = await ApiService.put(
        '${ApiService.serviceRequestBase}/$requestId/reject',
        body: {
          'reason': reason,
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

  /// Assign employee (organization providers only)
  static Future<ApiResponse<ServiceRequest>> assignEmployee({
    required String requestId,
    required String employeeId,
    String? notes,
  }) async {
    try {
      final res = await ApiService.put(
        '${ApiService.serviceRequestBase}/$requestId/assign-employee',
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

  /// Update status with validation and audit trail
  static Future<ApiResponse<ServiceRequest>> updateStatus({
    required String requestId,
    required String status,
    DateTime? scheduledDate,
    DateTime? completionDate,
    String? notes,
    String? reason,
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
          if (reason != null) 'reason': reason,
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

  /// Start work on request (provider/employee)
  static Future<ApiResponse<ServiceRequest>> startWork({
    required String requestId,
    String? notes,
  }) async {
    try {
      final res = await ApiService.put(
        '${ApiService.serviceRequestBase}/$requestId/start',
        body: {
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

  /// Complete request (provider/employee)
  static Future<ApiResponse<ServiceRequest>> completeRequest({
    required String requestId,
    String? notes,
    DateTime? actualCompletionDate,
  }) async {
    try {
      final res = await ApiService.put(
        '${ApiService.serviceRequestBase}/$requestId/complete',
        body: {
          if (notes != null) 'notes': notes,
          if (actualCompletionDate != null)
            'actualCompletionDate': actualCompletionDate.toIso8601String(),
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

  /// Cancel request (seeker or provider)
  static Future<ApiResponse<ServiceRequest>> cancelRequest({
    required String requestId,
    required String reason,
  }) async {
    try {
      final res = await ApiService.put(
        '${ApiService.serviceRequestBase}/$requestId/cancel',
        body: {
          'reason': reason,
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

  /// Get request status history (audit trail)
  static Future<ApiResponse<List<StatusChange>>> getStatusHistory(
      String requestId) async {
    try {
      final res = await ApiService.get(
        '${ApiService.serviceRequestBase}/$requestId/history',
      );
      return ApiService.handleResponse<List<StatusChange>>(
        res,
        (json) => (json['history'] as List<dynamic>? ?? [])
            .map((e) => StatusChange.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<StatusChange>>(e);
    }
  }

  /// Get available employees for assignment
  static Future<ApiResponse<List<EmployeeInfo>>> getAvailableEmployees({
    required String requestId,
    List<String>? requiredSkills,
  }) async {
    try {
      final res = await ApiService.get(
        '${ApiService.serviceRequestBase}/$requestId/available-employees',
        params: {
          if (requiredSkills != null && requiredSkills.isNotEmpty)
            'skills': requiredSkills.join(','),
        },
      );
      return ApiService.handleResponse<List<EmployeeInfo>>(
        res,
        (json) => (json['employees'] as List<dynamic>? ?? [])
            .map((e) => EmployeeInfo.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<EmployeeInfo>>(e);
    }
  }

  /// Toggle notifications for request
  static Future<ApiResponse<void>> toggleNotifications({
    required String requestId,
    required bool enabled,
  }) async {
    try {
      final res = await ApiService.put(
        '${ApiService.serviceRequestBase}/$requestId/notifications',
        body: {
          'enabled': enabled,
        },
      );
      return ApiService.handleResponse<void>(res, null);
    } catch (e) {
      return ApiService.handleError<void>(e);
    }
  }

  /// Get request analytics for providers
  static Future<ApiResponse<Map<String, dynamic>>> getRequestAnalytics({
    String? timeRange, // 'week', 'month', 'year'
  }) async {
    try {
      final res = await ApiService.get(
        '${ApiService.serviceRequestBase}/analytics',
        params: {
          if (timeRange != null) 'timeRange': timeRange,
        },
      );
      return ApiService.handleResponse<Map<String, dynamic>>(
        res,
        (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiService.handleError<Map<String, dynamic>>(e);
    }
  }
}
