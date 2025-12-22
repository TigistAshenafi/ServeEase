// lib/providers/provider_profile_provider.dart
import 'package:flutter/material.dart';
import 'package:serveease_app/core/models/provider_model.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/core/services/provider_service.dart';


class ProviderProfileProvider extends ChangeNotifier {
  ProviderProfile? _profile;
  bool _isLoading = false;
  String? _error;

  ProviderProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _profile != null;

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ProviderService.getProfile();

    _isLoading = false;

    if (response.success) {
      _profile = response.data;
    } else {
      _error = response.message;
    }

    notifyListeners();
  }

  Future<ApiResponse<ProviderProfile>> createOrUpdateProfile({
    required String providerType,
    required String businessName,
    required String description,
    required String category,
    required String location,
    required String phone,
    List<String> certificates = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ProviderService.createOrUpdateProfile(
      providerType: providerType,
      businessName: businessName,
      description: description,
      category: category,
      location: location,
      phone: phone,
      certificates: certificates,
    );

    _isLoading = false;

    if (response.success) {
      _profile = response.data;
      notifyListeners();
    } else {
      _error = response.message;
      notifyListeners();
    }

    return response;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}