import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/core/services/service_request_service.dart';

class ServiceRequestProvider extends ChangeNotifier {
  static final _logger = Logger('ServiceRequestProvider');

  List<ServiceRequest> requests = [];
  ServiceRequest? selectedRequest;
  List<StatusChange> statusHistory = [];
  List<EmployeeInfo> availableEmployees = [];
  Map<String, dynamic>? analytics;
  bool isLoading = false;
  bool isUpdating = false;
  String? error;

  // Fetch requests with enhanced filtering
  Future<void> fetchRequests({
    String status = 'all',
    String? role,
    int page = 1,
    int limit = 20,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final res = await ServiceRequestService.list(
      status: status,
      role: role,
      page: page,
      limit: limit,
    );

    isLoading = false;
    if (res.success && res.data != null) {
      requests = res.data!;
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
  }

  // Get single request with full details
  Future<void> fetchRequestDetails(String requestId) async {
    try {
      _logger.info('Fetching request details for ID: $requestId');
      isLoading = true;
      error = null;
      notifyListeners();

      // Validate request ID
      if (requestId.isEmpty) {
        throw Exception('Request ID cannot be empty');
      }

      _logger.info('Making API call to: ${ApiService.serviceRequestBase}/$requestId');
      final res = await ServiceRequestService.getRequest(requestId);
      _logger.info('API Response: success=${res.success}, message=${res.message}');

      isLoading = false;
      if (res.success && res.data != null) {
        selectedRequest = res.data!;
        error = null;
        _logger.info('Request loaded successfully: ${selectedRequest!.service.title}');
        // Also fetch status history
        try {
          await fetchStatusHistory(requestId);
        } catch (historyError) {
          _logger.warning('Failed to load status history: $historyError');
          // Don't fail the whole request if history fails
        }
      } else {
        error = res.message.isNotEmpty ? res.message : 'Failed to load request details';
        _logger.warning('Failed to load request: ${res.message}');
      }
    } catch (e) {
      isLoading = false;
      error = 'Error loading request: ${e.toString()}';
      _logger.severe('Exception in fetchRequestDetails: $e');
    }
    notifyListeners();
  }

  // Create new service request
  Future<ApiResponse<ServiceRequest>> createRequest({
    required String serviceId,
    required String providerId,
    String? notes,
    DateTime? scheduledDate,
    String urgency = 'medium',
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final res = await ServiceRequestService.create(
      serviceId: serviceId,
      providerId: providerId,
      notes: notes,
      scheduledDate: scheduledDate,
      urgency: urgency,
    );

    isLoading = false;
    if (res.success && res.data != null) {
      requests.insert(0, res.data!);
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  // Accept request (provider only)
  Future<ApiResponse<ServiceRequest>> acceptRequest({
    required String requestId,
    String? notes,
    DateTime? scheduledDate,
  }) async {
    isUpdating = true;
    error = null;
    notifyListeners();

    final res = await ServiceRequestService.acceptRequest(
      requestId: requestId,
      notes: notes,
      scheduledDate: scheduledDate,
    );

    isUpdating = false;
    if (res.success && res.data != null) {
      _updateRequestInList(res.data!);
      if (selectedRequest?.id == requestId) {
        selectedRequest = res.data!;
      }
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  // Reject request (provider only)
  Future<ApiResponse<ServiceRequest>> rejectRequest({
    required String requestId,
    required String reason,
  }) async {
    isUpdating = true;
    error = null;
    notifyListeners();

    final res = await ServiceRequestService.rejectRequest(
      requestId: requestId,
      reason: reason,
    );

    isUpdating = false;
    if (res.success && res.data != null) {
      _updateRequestInList(res.data!);
      if (selectedRequest?.id == requestId) {
        selectedRequest = res.data!;
      }
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  // Assign employee (organization providers only)
  Future<ApiResponse<ServiceRequest>> assignEmployee({
    required String requestId,
    required String employeeId,
    String? notes,
  }) async {
    isUpdating = true;
    error = null;
    notifyListeners();

    final res = await ServiceRequestService.assignEmployee(
      requestId: requestId,
      employeeId: employeeId,
      notes: notes,
    );

    isUpdating = false;
    if (res.success && res.data != null) {
      _updateRequestInList(res.data!);
      if (selectedRequest?.id == requestId) {
        selectedRequest = res.data!;
      }
      error = null;

      // Send assignment notification
      await _sendAssignmentNotification(res.data!, employeeId, notes);
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  /// Send notification when employee is assigned
  Future<void> _sendAssignmentNotification(
    ServiceRequest request,
    String employeeId,
    String? notes,
  ) async {
    try {
      // This would typically call a notification service
      // For now, we'll just track the assignment
      _logger.info(
          'Assignment notification sent for request ${request.id} to employee $employeeId');
      if (notes != null && notes.isNotEmpty) {
        _logger.info('Assignment notes: $notes');
      }
    } catch (e) {
      _logger.severe('Failed to send assignment notification: $e');
    }
  }

  // Update request status with validation
  Future<ApiResponse<ServiceRequest>> updateStatus({
    required String requestId,
    required String status,
    DateTime? scheduledDate,
    DateTime? completionDate,
    String? notes,
    String? reason,
  }) async {
    isUpdating = true;
    error = null;
    notifyListeners();

    final res = await ServiceRequestService.updateStatus(
      requestId: requestId,
      status: status,
      scheduledDate: scheduledDate,
      completionDate: completionDate,
      notes: notes,
      reason: reason,
    );

    isUpdating = false;
    if (res.success && res.data != null) {
      _updateRequestInList(res.data!);
      if (selectedRequest?.id == requestId) {
        selectedRequest = res.data!;
      }
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  // Start work on request
  Future<ApiResponse<ServiceRequest>> startWork({
    required String requestId,
    String? notes,
  }) async {
    isUpdating = true;
    error = null;
    notifyListeners();

    final res = await ServiceRequestService.startWork(
      requestId: requestId,
      notes: notes,
    );

    isUpdating = false;
    if (res.success && res.data != null) {
      _updateRequestInList(res.data!);
      if (selectedRequest?.id == requestId) {
        selectedRequest = res.data!;
      }
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  // Complete request
  Future<ApiResponse<ServiceRequest>> completeRequest({
    required String requestId,
    String? notes,
    DateTime? actualCompletionDate,
  }) async {
    isUpdating = true;
    error = null;
    notifyListeners();

    final res = await ServiceRequestService.completeRequest(
      requestId: requestId,
      notes: notes,
      actualCompletionDate: actualCompletionDate,
    );

    isUpdating = false;
    if (res.success && res.data != null) {
      _updateRequestInList(res.data!);
      if (selectedRequest?.id == requestId) {
        selectedRequest = res.data!;
      }
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  // Cancel request
  Future<ApiResponse<ServiceRequest>> cancelRequest({
    required String requestId,
    required String reason,
  }) async {
    isUpdating = true;
    error = null;
    notifyListeners();

    final res = await ServiceRequestService.cancelRequest(
      requestId: requestId,
      reason: reason,
    );

    isUpdating = false;
    if (res.success && res.data != null) {
      _updateRequestInList(res.data!);
      if (selectedRequest?.id == requestId) {
        selectedRequest = res.data!;
      }
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  // Add rating and review
  Future<ApiResponse<void>> addRating({
    required String requestId,
    required int rating,
    String? review,
    bool isProviderReview = false,
  }) async {
    final res = await ServiceRequestService.addRating(
      requestId: requestId,
      rating: rating,
      review: review,
      isProviderReview: isProviderReview,
    );

    if (res.success) {
      // Refresh the request to get updated rating
      await fetchRequestDetails(requestId);
    }

    return res;
  }

  // Fetch status history (audit trail)
  Future<void> fetchStatusHistory(String requestId) async {
    final res = await ServiceRequestService.getStatusHistory(requestId);
    if (res.success && res.data != null) {
      statusHistory = res.data!;
      notifyListeners();
    }
  }

  // Fetch available employees for assignment
  Future<void> fetchAvailableEmployees({
    required String requestId,
    List<String>? requiredSkills,
  }) async {
    final res = await ServiceRequestService.getAvailableEmployees(
      requestId: requestId,
      requiredSkills: requiredSkills,
    );
    if (res.success && res.data != null) {
      availableEmployees = res.data!;
      notifyListeners();
    }
  }

  // Toggle notifications
  Future<ApiResponse<void>> toggleNotifications({
    required String requestId,
    required bool enabled,
  }) async {
    final res = await ServiceRequestService.toggleNotifications(
      requestId: requestId,
      enabled: enabled,
    );

    if (res.success) {
      // Update local request if it's the selected one
      if (selectedRequest?.id == requestId) {
        selectedRequest = ServiceRequest(
          id: selectedRequest!.id,
          seekerId: selectedRequest!.seekerId,
          providerId: selectedRequest!.providerId,
          serviceId: selectedRequest!.serviceId,
          status: selectedRequest!.status,
          createdAt: selectedRequest!.createdAt,
          scheduledDate: selectedRequest!.scheduledDate,
          completionDate: selectedRequest!.completionDate,
          notes: selectedRequest!.notes,
          seekerRating: selectedRequest!.seekerRating,
          seekerReview: selectedRequest!.seekerReview,
          providerRating: selectedRequest!.providerRating,
          providerReview: selectedRequest!.providerReview,
          service: selectedRequest!.service,
          seeker: selectedRequest!.seeker,
          provider: selectedRequest!.provider,
          assignedEmployeeId: selectedRequest!.assignedEmployeeId,
          assignedEmployee: selectedRequest!.assignedEmployee,
          statusHistory: selectedRequest!.statusHistory,
          urgency: selectedRequest!.urgency,
          estimatedCompletionDate: selectedRequest!.estimatedCompletionDate,
          actualCompletionDate: selectedRequest!.actualCompletionDate,
          notificationsEnabled: enabled,
        );
        notifyListeners();
      }
    }

    return res;
  }

  // Fetch analytics
  Future<void> fetchAnalytics({String? timeRange}) async {
    final res = await ServiceRequestService.getRequestAnalytics(
      timeRange: timeRange,
    );
    if (res.success && res.data != null) {
      analytics = res.data!;
      notifyListeners();
    }
  }

  // Helper method to update request in list
  void _updateRequestInList(ServiceRequest updatedRequest) {
    final index = requests.indexWhere((r) => r.id == updatedRequest.id);
    if (index != -1) {
      requests[index] = updatedRequest;
    }
  }

  // Clear selected request
  void clearSelectedRequest() {
    selectedRequest = null;
    statusHistory.clear();
    availableEmployees.clear();
    notifyListeners();
  }

  // Clear error
  void clearError() {
    error = null;
    notifyListeners();
  }

  // Get requests by status
  List<ServiceRequest> getRequestsByStatus(String status) {
    if (status == 'all') return requests;
    return requests.where((r) => r.status == status).toList();
  }

  // Get pending requests count
  int get pendingRequestsCount =>
      requests.where((r) => r.status == 'pending').length;

  // Get in-progress requests count
  int get inProgressRequestsCount =>
      requests.where((r) => r.status == 'in_progress').length;

  // Get completed requests count
  int get completedRequestsCount =>
      requests.where((r) => r.status == 'completed').length;

  // Check if request can be rated
  bool canRateRequest(ServiceRequest request, {required bool isProvider}) {
    if (!request.isCompleted) return false;
    if (isProvider) {
      return request.providerRating == null;
    } else {
      return request.seekerRating == null;
    }
  }
}
