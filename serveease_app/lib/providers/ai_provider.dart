import 'package:flutter/material.dart';
import 'package:serveease_app/core/models/ai_models.dart';
import 'package:serveease_app/core/models/user_model.dart';
import 'package:serveease_app/core/services/ai_client_service.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AiProvider extends ChangeNotifier {
  List<AiMessage> history = [];
  bool isLoading = false;
  String? error;
  String? lastResponse;
  ConversationSession? currentSession;
  List<ConversationSession> conversationHistory = [];
  List<AiSuggestion> suggestions = [];
  AiContext? _context;

  // Initialize AI provider with user context
  Future<void> initialize(User? user) async {
    if (user != null) {
      _context = AiContext(
        userRole: user.role,
        recentActivities: [],
      );
      await _loadConversationHistory();
      await _loadCurrentSession();
    }
  }

  // Load conversation history from local storage and server
  Future<void> _loadConversationHistory() async {
    try {
      final response = await AiClientService.getConversationHistory(limit: 20);
      if (response.success && response.data != null) {
        conversationHistory = response.data!;
        await _saveLocalConversationHistory();
        notifyListeners();
      }
    } catch (e) {
      // Fallback to local storage
      await _loadLocalConversationHistory();
    }
  }

  // Load current session from local storage
  Future<void> _loadCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString('current_ai_session');
      if (sessionData != null) {
        final sessionJson = jsonDecode(sessionData);
        currentSession = ConversationSession.fromJson(sessionJson);
        history = currentSession!.messages;
        notifyListeners();
      }
    } catch (e) {
      // Start fresh if loading fails
      await startNewConversation();
    }
  }

  // Save current session to local storage
  Future<void> _saveCurrentSession() async {
    if (currentSession != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'current_ai_session', jsonEncode(currentSession!.toJson()));
      } catch (e) {
        // Handle save error silently
      }
    }
  }

  // Load conversation history from local storage
  Future<void> _loadLocalConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData = prefs.getString('ai_conversation_history');
      if (historyData != null) {
        final historyJson = jsonDecode(historyData) as List<dynamic>;
        conversationHistory =
            historyJson.map((e) => ConversationSession.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      // Handle load error silently
    }
  }

  // Save conversation history to local storage
  Future<void> _saveLocalConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = conversationHistory.map((e) => e.toJson()).toList();
      await prefs.setString('ai_conversation_history', jsonEncode(historyJson));
    } catch (e) {
      // Handle save error silently
    }
  }

  // Start a new conversation session
  Future<void> startNewConversation() async {
    try {
      final response =
          await AiClientService.startNewConversation(context: _context);
      if (response.success && response.data != null) {
        currentSession = response.data!;
        history = [];
        suggestions = [];
        await _saveCurrentSession();
        notifyListeners();
      }
    } catch (e) {
      // Create local session if server fails
      currentSession = ConversationSession(
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _context?.userRole ?? 'anonymous',
        messages: [],
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        context: _context,
      );
      history = [];
      suggestions = [];
      await _saveCurrentSession();
      notifyListeners();
    }
  }

  // Send message with context awareness
  Future<ApiResponse<AiResponse>> send(String message,
      {String? currentScreen}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    // Update context with current screen
    if (currentScreen != null && _context != null) {
      _context = AiContext(
        userRole: _context!.userRole,
        currentScreen: currentScreen,
        userPreferences: _context!.userPreferences,
        recentActivities: _context!.recentActivities,
      );
    }

    // Add user message to history
    final userMessage = AiMessage(role: 'user', content: message);
    history.add(userMessage);

    final res = await AiClientService.chat(
      message: message,
      history: history,
      context: _context,
      sessionId: currentSession?.sessionId,
    );

    isLoading = false;
    if (res.success && res.data != null) {
      history = res.data!.history;
      lastResponse = res.data!.response;
      suggestions = res.data!.suggestions;

      // Update current session
      if (currentSession != null) {
        currentSession = ConversationSession(
          sessionId: currentSession!.sessionId,
          userId: currentSession!.userId,
          messages: history,
          createdAt: currentSession!.createdAt,
          lastActivity: DateTime.now(),
          context: res.data!.context ?? _context,
        );
        await _saveCurrentSession();
      }
    } else {
      error = res.message;
    }
    notifyListeners();
    return res;
  }

  // Get workflow guidance based on user role and current context
  Future<void> getWorkflowGuidance({String? currentTask}) async {
    if (_context == null) return;

    try {
      final response = await AiClientService.getWorkflowGuidance(
        userRole: _context!.userRole,
        currentTask: currentTask,
        context: _context!.userPreferences,
      );

      if (response.success && response.data != null) {
        suggestions = response.data!;
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently for guidance
    }
  }

  // Load a specific conversation session
  Future<void> loadConversation(String sessionId) async {
    try {
      final response = await AiClientService.getConversation(sessionId);
      if (response.success && response.data != null) {
        currentSession = response.data!;
        history = currentSession!.messages;
        _context = currentSession!.context ?? _context;
        await _saveCurrentSession();
        notifyListeners();
      }
    } catch (e) {
      error = 'Failed to load conversation';
      notifyListeners();
    }
  }

  // Update user context (e.g., when user navigates to different screens)
  void updateContext({
    String? currentScreen,
    Map<String, dynamic>? preferences,
    List<String>? recentActivities,
  }) {
    if (_context != null) {
      _context = AiContext(
        userRole: _context!.userRole,
        currentScreen: currentScreen ?? _context!.currentScreen,
        userPreferences: preferences ?? _context!.userPreferences,
        recentActivities: recentActivities ?? _context!.recentActivities,
      );
    }
  }

  // Add recent activity to context
  void addRecentActivity(String activity) {
    if (_context != null) {
      final activities = List<String>.from(_context!.recentActivities);
      activities.insert(0, activity);
      if (activities.length > 10) {
        activities.removeLast();
      }

      _context = AiContext(
        userRole: _context!.userRole,
        currentScreen: _context!.currentScreen,
        userPreferences: _context!.userPreferences,
        recentActivities: activities,
      );
    }
  }

  // Get AI explanation for a platform feature
  Future<void> explainFeature(String featureName) async {
    if (_context == null) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await AiClientService.explainFeature(
        featureName: featureName,
        userRole: _context!.userRole,
      );

      if (response.success && response.data != null) {
        final explanation = response.data!['explanation'] as String?;
        if (explanation != null) {
          // Add explanation as assistant message
          final assistantMessage = AiMessage(
            role: 'assistant',
            content: explanation,
          );
          history.add(assistantMessage);
          lastResponse = explanation;
        }
      }
    } catch (e) {
      error = 'Failed to get feature explanation';
    }

    isLoading = false;
    notifyListeners();
  }

  // Clear current conversation
  void clearConversation() {
    history.clear();
    suggestions.clear();
    currentSession = null;
    lastResponse = null;
    error = null;
    notifyListeners();
  }

  // Get context for external use
  AiContext? get context => _context;

  // Check if AI is initialized
  bool get isInitialized => _context != null;
}
