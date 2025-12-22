import 'package:flutter/material.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/core/services/service_request_service.dart';

class ServiceRequestProvider extends ChangeNotifier {
  List<ServiceRequest> requests = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchRequests({String status = 'all'}) async {
    isLoading = true;
    notifyListeners();
    final res = await ServiceRequestService.list(status: status);
    isLoading = false;
    if (res.success && res.data != null) {
      requests = res.data!;
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
  }

  Future<ApiResponse<ServiceRequest>> createRequest(
      {required String serviceId, String? notes}) async {
    isLoading = true;
    notifyListeners();
    final res =
        await ServiceRequestService.create(serviceId: serviceId, notes: notes);
    isLoading = false;
    if (res.success && res.data != null) {
      requests.insert(0, res.data!);
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  Future<ApiResponse<ServiceRequest>> updateStatus({
    required String requestId,
    required String status,
    DateTime? scheduledDate,
    DateTime? completionDate,
    String? notes,
  }) async {
    final res = await ServiceRequestService.updateStatus(
      requestId: requestId,
      status: status,
      scheduledDate: scheduledDate,
      completionDate: completionDate,
      notes: notes,
    );
    if (res.success && res.data != null) {
      final idx = requests.indexWhere((r) => r.id == requestId);
      if (idx != -1) requests[idx] = res.data!;
      notifyListeners();
    }
    return res;
  }

  Future<ApiResponse<ServiceRequest>> assignEmployee({
    required String requestId,
    required String employeeId,
  }) async {
    final res = await ServiceRequestService.assignEmployee(
      requestId: requestId,
      employeeId: employeeId,
    );
    if (res.success && res.data != null) {
      final idx = requests.indexWhere((r) => r.id == requestId);
      if (idx != -1) requests[idx] = res.data!;
      notifyListeners();
    }
    return res;
  }

  Future<ApiResponse<void>> addRating({
    required String requestId,
    required int rating,
    String? review,
    bool isProviderReview = false,
  }) {
    return ServiceRequestService.addRating(
      requestId: requestId,
      rating: rating,
      review: review,
      isProviderReview: isProviderReview,
    );
  }
}

