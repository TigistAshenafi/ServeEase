import 'package:flutter/material.dart';
import 'package:serveease_app/core/models/ai_models.dart';
import 'package:serveease_app/core/services/ai_client_service.dart';
import 'package:serveease_app/core/services/api_service.dart';

class AiProvider extends ChangeNotifier {
  List<AiMessage> history = [];
  bool isLoading = false;
  String? error;
  String? lastResponse;

  Future<ApiResponse<AiResponse>> send(String message) async {
    isLoading = true;
    error = null;
    notifyListeners();

    history.add(AiMessage(role: 'user', content: message));

    final res = await AiClientService.chat(
      message: message,
      history: history,
    );

    isLoading = false;
    if (res.success && res.data != null) {
      history = res.data!.history;
      lastResponse = res.data!.response;
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }
}

