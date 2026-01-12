// lib/core/models/ai_models.dart

class AiMessage {
  final String role; // user | assistant
  final String content;
  final DateTime timestamp;
  final String? messageId;

  AiMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.messageId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        if (messageId != null) 'messageId': messageId,
      };

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      messageId: json['messageId'],
    );
  }
}

class AiResponse {
  final String response;
  final List<AiAction> actions;
  final List<AiMessage> history;
  final AiContext? context;
  final List<AiSuggestion> suggestions;

  AiResponse({
    required this.response,
    required this.actions,
    required this.history,
    this.context,
    this.suggestions = const [],
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      response: json['response'] ?? '',
      actions: (json['actions'] as List<dynamic>? ?? [])
          .map((e) => AiAction.fromJson(e))
          .toList(),
      history: (json['conversationHistory'] as List<dynamic>? ?? [])
          .map((e) => AiMessage.fromJson(e))
          .toList(),
      context:
          json['context'] != null ? AiContext.fromJson(json['context']) : null,
      suggestions: (json['suggestions'] as List<dynamic>? ?? [])
          .map((e) => AiSuggestion.fromJson(e))
          .toList(),
    );
  }
}

class AiAction {
  final String type;
  final String target;
  final String description;
  final Map<String, dynamic>? parameters;

  AiAction({
    required this.type,
    required this.target,
    required this.description,
    this.parameters,
  });

  factory AiAction.fromJson(Map<String, dynamic> json) {
    return AiAction(
      type: json['type'] ?? '',
      target: json['target'] ?? '',
      description: json['description'] ?? '',
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }
}

class AiContext {
  final String userRole;
  final String? currentScreen;
  final Map<String, dynamic>? userPreferences;
  final List<String> recentActivities;

  AiContext({
    required this.userRole,
    this.currentScreen,
    this.userPreferences,
    this.recentActivities = const [],
  });

  factory AiContext.fromJson(Map<String, dynamic> json) {
    return AiContext(
      userRole: json['userRole'] ?? '',
      currentScreen: json['currentScreen'],
      userPreferences: json['userPreferences'] as Map<String, dynamic>?,
      recentActivities: (json['recentActivities'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userRole': userRole,
        if (currentScreen != null) 'currentScreen': currentScreen,
        if (userPreferences != null) 'userPreferences': userPreferences,
        'recentActivities': recentActivities,
      };
}

class AiSuggestion {
  final String text;
  final String type; // question, action, workflow
  final String? actionTarget;
  final Map<String, dynamic>? parameters;

  AiSuggestion({
    required this.text,
    required this.type,
    this.actionTarget,
    this.parameters,
  });

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    return AiSuggestion(
      text: json['text'] ?? '',
      type: json['type'] ?? 'question',
      actionTarget: json['actionTarget'],
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }
}

class ConversationSession {
  final String sessionId;
  final String userId;
  final List<AiMessage> messages;
  final DateTime createdAt;
  final DateTime lastActivity;
  final AiContext? context;

  ConversationSession({
    required this.sessionId,
    required this.userId,
    required this.messages,
    required this.createdAt,
    required this.lastActivity,
    this.context,
  });

  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    return ConversationSession(
      sessionId: json['sessionId'] ?? '',
      userId: json['userId'] ?? '',
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((e) => AiMessage.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastActivity: DateTime.parse(json['lastActivity']),
      context:
          json['context'] != null ? AiContext.fromJson(json['context']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'userId': userId,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'lastActivity': lastActivity.toIso8601String(),
        if (context != null) 'context': context!.toJson(),
      };
}
