// lib/core/services/ai_client_service.dart
import 'package:serveease_app/core/models/ai_models.dart';
import 'package:serveease_app/core/services/api_service.dart';

class AiClientService {
  /// Chat with AI with context awareness
  static Future<ApiResponse<AiResponse>> chat({
    required String message,
    List<AiMessage> history = const [],
    AiContext? context,
    String? sessionId,
  }) async {
    try {
      final res = await ApiService.post(
        '${ApiService.aiBase}/chat',
        body: {
          'message': message,
          'conversationHistory': history.map((h) => h.toJson()).toList(),
          if (context != null) 'context': context.toJson(),
          if (sessionId != null) 'sessionId': sessionId,
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

  /// Get conversation history for a user
  static Future<ApiResponse<List<ConversationSession>>> getConversationHistory({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final res = await ApiService.get(
        '${ApiService.aiBase}/conversations',
        params: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );
      return ApiService.handleResponse<List<ConversationSession>>(
        res,
        (json) => (json['conversations'] as List<dynamic>? ?? [])
            .map((e) => ConversationSession.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<ConversationSession>>(e);
    }
  }

  /// Get a specific conversation session
  static Future<ApiResponse<ConversationSession>> getConversation(
      String sessionId) async {
    try {
      final res = await ApiService.get(
        '${ApiService.aiBase}/conversations/$sessionId',
      );
      return ApiService.handleResponse<ConversationSession>(
        res,
        (json) => ConversationSession.fromJson(json),
      );
    } catch (e) {
      return ApiService.handleError<ConversationSession>(e);
    }
  }

  /// Start a new conversation session
  static Future<ApiResponse<ConversationSession>> startNewConversation({
    AiContext? context,
  }) async {
    try {
      final res = await ApiService.post(
        '${ApiService.aiBase}/conversations',
        body: {
          if (context != null) 'context': context.toJson(),
        },
      );
      return ApiService.handleResponse<ConversationSession>(
        res,
        (json) => ConversationSession.fromJson(json),
      );
    } catch (e) {
      return ApiService.handleError<ConversationSession>(e);
    }
  }

  /// Get AI-powered workflow guidance
  static Future<ApiResponse<List<AiSuggestion>>> getWorkflowGuidance({
    required String userRole,
    String? currentTask,
    Map<String, dynamic>? context,
  }) async {
    try {
      final res = await ApiService.post(
        '${ApiService.aiBase}/guidance',
        body: {
          'userRole': userRole,
          if (currentTask != null) 'currentTask': currentTask,
          if (context != null) 'context': context,
        },
      );
      return ApiService.handleResponse<List<AiSuggestion>>(
        res,
        (json) => (json['suggestions'] as List<dynamic>? ?? [])
            .map((e) => AiSuggestion.fromJson(e))
            .toList(),
      );
    } catch (e) {
      return ApiService.handleError<List<AiSuggestion>>(e);
    }
  }

  /// Recommendations for services (AI assisted)
  static Future<ApiResponse<List<dynamic>>> recommendations({
    String? query,
    String? category,
    AiContext? context,
  }) async {
    try {
      final res = await ApiService.post(
        '${ApiService.aiBase}/recommendations/services',
        body: {
          if (query != null) 'query': query,
          if (category != null) 'category': category,
          if (context != null) 'context': context.toJson(),
        },
      );
      return ApiService.handleResponse<List<dynamic>>(
          res, (json) => json['recommendations'] as List<dynamic>? ?? []);
    } catch (e) {
      return ApiService.handleError<List<dynamic>>(e);
    }
  }

  /// Get platform feature explanations
  static Future<ApiResponse<Map<String, dynamic>>> explainFeature({
    required String featureName,
    required String userRole,
  }) async {
    try {
      final res = await ApiService.post(
        '${ApiService.aiBase}/explain',
        body: {
          'featureName': featureName,
          'userRole': userRole,
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
