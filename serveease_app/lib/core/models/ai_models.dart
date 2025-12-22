// lib/core/models/ai_models.dart

class AiMessage {
  final String role; // user | assistant
  final String content;

  AiMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class AiResponse {
  final String response;
  final List<AiAction> actions;
  final List<AiMessage> history;

  AiResponse({
    required this.response,
    required this.actions,
    required this.history,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      response: json['response'] ?? '',
      actions: (json['actions'] as List<dynamic>? ?? [])
          .map((e) => AiAction.fromJson(e))
          .toList(),
      history: (json['conversationHistory'] as List<dynamic>? ?? [])
          .map((e) => AiMessage(
                role: e['role'] ?? 'assistant',
                content: e['content'] ?? '',
              ))
          .toList(),
    );
  }
}

class AiAction {
  final String type;
  final String target;
  final String description;

  AiAction({
    required this.type,
    required this.target,
    required this.description,
  });

  factory AiAction.fromJson(Map<String, dynamic> json) {
    return AiAction(
      type: json['type'] ?? '',
      target: json['target'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

