import 'package:flutter/foundation.dart';
import 'package:serveease_app/core/models/provider_model.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/core/services/provider_service.dart';

class AdminProvider extends ChangeNotifier {
  List<ProviderProfile> providers = [];
  bool isLoading = false;
  String? error;
  int page = 1;
  int total = 0;

  Future<void> fetchProviders({String status = 'all', int page = 1}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final res = await ProviderService.listProviders(
      status: status,
      page: page,
      limit: 20,
    );

    isLoading = false;
    if (res.success && res.data != null) {
      providers = res.data!;
      this.page = page;
      error = null;
    } else {
      error = res.message;
    }
    notifyListeners();
  }

  Future<ApiResponse<ProviderProfile>> approve(
    String providerId, {
    String? notes,
  }) async {
    final res = await ProviderService.approveProvider(
      providerId: providerId,
      adminNotes: notes,
    );
    if (res.success && res.data != null) {
      final idx = providers.indexWhere((p) => p.id == providerId);
      if (idx != -1) {
        providers[idx] = res.data!;
        notifyListeners();
      }
    }
    return res;
  }

  Future<ApiResponse<ProviderProfile>> reject(
    String providerId, {
    String? notes,
  }) async {
    final res = await ProviderService.rejectProvider(
      providerId: providerId,
      adminNotes: notes,
    );
    if (res.success && res.data != null) {
      final idx = providers.indexWhere((p) => p.id == providerId);
      if (idx != -1) {
        providers[idx] = res.data!;
        notifyListeners();
      }
    }
    return res;
  }
}

