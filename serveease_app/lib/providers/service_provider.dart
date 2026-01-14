import 'package:flutter/material.dart';
import 'package:serveease_app/core/models/service_model.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/core/services/service_service.dart';

class ServiceProvider extends ChangeNotifier {
  List<ServiceCategory> categories = [];
  List<Service> myServices = [];
  List<Service> categoryServices = [];
  List<Service> allServices = [];
  bool isLoading = false;
  String? error;

  /// Clear all cached data to force refresh
  void clearCache() {
    categories.clear();
    myServices.clear();
    categoryServices.clear();
    allServices.clear();
    error = null;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    final res = await ServiceService.fetchCategories();
    
    isLoading = false;
    if (res.success && res.data != null) {
      categories = res.data!;
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
  }

  Future<void> loadAllServices({
    int page = 1,
    int limit = 20,
    String? search,
    String? location,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    final res = await ServiceService.fetchAllServices(
      page: page,
      limit: limit,
      search: search,
      location: location,
    );
    
    isLoading = false;
    if (res.success && res.data != null) {
      if (page == 1) {
        allServices = res.data!;
      } else {
        allServices.addAll(res.data!);
      }
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
  }

  Future<void> loadCategoryServices(String categoryId) async {
    isLoading = true;
    notifyListeners();
    final res = await ServiceService.fetchByCategory(categoryId);
    isLoading = false;
    if (res.success && res.data != null) {
      categoryServices = res.data!;
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
  }

  Future<ApiResponse<Service>> getServiceDetails(String serviceId) async {
    return await ServiceService.fetchServiceDetails(serviceId);
  }

  Future<ApiResponse<Service>> createService({
    required String title,
    required String description,
    required String categoryId,
    required double price,
    required int durationHours,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    final res = await ServiceService.create(
      title: title,
      description: description,
      categoryId: categoryId,
      price: price,
      durationHours: durationHours,
    );
    isLoading = false;
    if (res.success && res.data != null) {
      myServices.insert(0, res.data!);
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  Future<ApiResponse<Service>> updateService({
    required String id,
    String? title,
    String? description,
    String? categoryId,
    double? price,
    int? durationHours,
    bool? isActive,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    final res = await ServiceService.update(
      serviceId: id,
      title: title,
      description: description,
      categoryId: categoryId,
      price: price,
      durationHours: durationHours,
      isActive: isActive,
    );
    isLoading = false;
    if (res.success && res.data != null) {
      final idx = myServices.indexWhere((s) => s.id == id);
      if (idx != -1) myServices[idx] = res.data!;
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  Future<ApiResponse<void>> deleteService(String id) async {
    isLoading = true;
    notifyListeners();
    final res = await ServiceService.deleteService(id);
    isLoading = false;
    if (res.success) {
      myServices.removeWhere((s) => s.id == id);
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  Future<void> loadMyServices() async {
    isLoading = true;
    notifyListeners();
    final res = await ServiceService.fetchProviderServices();
    isLoading = false;
    if (res.success && res.data != null) {
      myServices = res.data!;
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
  }
}

