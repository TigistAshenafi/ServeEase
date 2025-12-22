// lib/core/services/service_service.dart
import 'dart:convert';
import 'package:serveease_app/core/models/service_model.dart';
import 'package:serveease_app/core/services/api_service.dart';

class ServiceService {
  /// Public: list categories
  static Future<ApiResponse<List<ServiceCategory>>> fetchCategories() async {
    try {
      final res = await ApiService.get('${ApiService.servicesBase}/categories',
          withAuth: false);
      return ApiService.handleResponse<List<ServiceCategory>>(
        res,
        (json) => (json['categories'] as List<dynamic>? ?? [])
            .map((e) => ServiceCategory.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<ServiceCategory>>(e);
    }
  }

  /// Public: services by category
  static Future<ApiResponse<List<Service>>> fetchByCategory(
      String categoryId) async {
    try {
      final res =
          await ApiService.get('${ApiService.servicesBase}/category/$categoryId');
      return ApiService.handleResponse<List<Service>>(
        res,
        (json) => (json['services'] as List<dynamic>? ?? [])
            .map((e) => Service.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<Service>>(e);
    }
  }

  /// Provider: list own services
  static Future<ApiResponse<List<Service>>> fetchProviderServices() async {
    try {
      final res = await ApiService.get(ApiService.servicesBase);
      return ApiService.handleResponse<List<Service>>(
        res,
        (json) => (json['services'] as List<dynamic>? ?? [])
            .map((e) => Service.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<Service>>(e);
    }
  }

  /// Provider: create
  static Future<ApiResponse<Service>> create({
    required String title,
    required String description,
    required String categoryId,
    required double price,
    required int durationHours,
  }) async {
    try {
      final res = await ApiService.post(
        ApiService.servicesBase,
        body: {
          'title': title,
          'description': description,
          'categoryId': categoryId,
          'price': price,
          'durationHours': durationHours,
        },
      );
      return ApiService.handleResponse<Service>(
        res,
        (json) => Service.fromJson(json['service'] ?? json),
      );
    } catch (e) {
      return ApiService.handleError<Service>(e);
    }
  }

  /// Provider: update
  static Future<ApiResponse<Service>> update({
    required String serviceId,
    String? title,
    String? description,
    String? categoryId,
    double? price,
    int? durationHours,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (categoryId != null) body['categoryId'] = categoryId;
      if (price != null) body['price'] = price;
      if (durationHours != null) body['durationHours'] = durationHours;
      if (isActive != null) body['isActive'] = isActive;

      final res = await ApiService.put(
        '${ApiService.servicesBase}/$serviceId',
        body: body,
      );
      return ApiService.handleResponse<Service>(
        res,
        (json) => Service.fromJson(json['service'] ?? json),
      );
    } catch (e) {
      return ApiService.handleError<Service>(e);
    }
  }

  /// Provider: delete (soft)
  static Future<ApiResponse<void>> deleteService(String serviceId) async {
    try {
      final res =
          await ApiService.delete('${ApiService.servicesBase}/$serviceId');
      return ApiService.handleResponse<void>(res, null);
    } catch (e) {
      return ApiService.handleError<void>(e);
    }
  }
}

