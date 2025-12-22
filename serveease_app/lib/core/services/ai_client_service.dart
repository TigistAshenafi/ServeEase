// lib/core/services/ai_client_service.dart
import 'package:serveease_app/core/models/ai_models.dart';
import 'package:serveease_app/core/services/api_service.dart';

class AiClientService {
  /// Chat with AI
  static Future<ApiResponse<AiResponse>> chat({
    required String message,
    List<AiMessage> history = const [],
  }) async {
    try {
      final res = await ApiService.post(
        '${ApiService.aiBase}/chat',
        body: {
          'message': message,
          'conversationHistory': history.map((h) => h.toJson()).toList(),
        },
      );
      return ApiService.handleResponse<AiResponse>(
        res,
        (json) => AiResponse.fromJson(json),
      );
    } catch (e) {
      return ApiService.handleError<AiResponse>(e);
    }
  }

  /// Recommendations for services (AI assisted)
  static Future<ApiResponse<List<dynamic>>> recommendations(
      {String? query, String? category}) async {
    try {
      final res = await ApiService.get(
        '${ApiService.aiBase}/recommendations/services',
        params: {
          if (query != null) 'query': query,
          if (category != null) 'category': category,
        },
      );
      return ApiService.handleResponse<List<dynamic>>(
          res, (json) => json['recommendations'] as List<dynamic>? ?? []);
    } catch (e) {
      return ApiService.handleError<List<dynamic>>(e);
    }
  }
}

