import 'package:flutter_test/flutter_test.dart';
import 'package:serveease_app/providers/ai_provider.dart';
import 'package:serveease_app/core/models/user_model.dart';
import 'package:serveease_app/core/models/ai_models.dart';

void main() {
  group('AI Provider Tests', () {
    late AiProvider aiProvider;

    setUp(() {
      aiProvider = AiProvider();
    });

    test('should initialize with user context', () async {
      final mockUser = User(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        role: 'seeker',
        emailVerified: true,
      );

      await aiProvider.initialize(mockUser);

      expect(aiProvider.isInitialized, true);
      expect(aiProvider.context?.userRole, 'seeker');
    });

    test('should update context correctly', () async {
      final mockUser = User(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        role: 'individual_provider',
        emailVerified: true,
      );

      await aiProvider.initialize(mockUser);

      aiProvider.updateContext(
        currentScreen: 'service_management',
        preferences: {'theme': 'dark'},
      );

      expect(aiProvider.context?.currentScreen, 'service_management');
      expect(aiProvider.context?.userPreferences?['theme'], 'dark');
    });

    test('should add recent activities', () async {
      final mockUser = User(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        role: 'seeker',
        emailVerified: true,
      );

      await aiProvider.initialize(mockUser);

      aiProvider.addRecentActivity('Searched for plumbing services');
      aiProvider.addRecentActivity('Viewed provider profile');

      expect(aiProvider.context?.recentActivities.length, 2);
      expect(aiProvider.context?.recentActivities.first,
          'Viewed provider profile');
      expect(aiProvider.context?.recentActivities.last,
          'Searched for plumbing services');
    });

    test('should clear conversation', () async {
      final mockUser = User(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        role: 'seeker',
        emailVerified: true,
      );

      await aiProvider.initialize(mockUser);

      // Add some mock data
      aiProvider.history.add(AiMessage(role: 'user', content: 'Hello'));
      aiProvider.suggestions
          .add(AiSuggestion(text: 'Test suggestion', type: 'question'));

      aiProvider.clearConversation();

      expect(aiProvider.history.isEmpty, true);
      expect(aiProvider.suggestions.isEmpty, true);
      expect(aiProvider.currentSession, null);
      expect(aiProvider.lastResponse, null);
      expect(aiProvider.error, null);
    });

    test('should handle different user roles', () async {
      final roles = ['seeker', 'individual_provider', 'organization_provider'];

      for (final role in roles) {
        final mockUser = User(
          id: '1',
          name: 'Test User',
          email: 'test@example.com',
          role: role,
          emailVerified: true,
        );

        await aiProvider.initialize(mockUser);

        expect(aiProvider.context?.userRole, role);
        expect(aiProvider.isInitialized, true);
      }
    });
  });

  group('AI Models Tests', () {
    test('AiMessage should serialize correctly', () {
      final message = AiMessage(
        role: 'user',
        content: 'Test message',
        timestamp: DateTime(2024, 1, 1),
        messageId: 'msg_123',
      );

      final json = message.toJson();

      expect(json['role'], 'user');
      expect(json['content'], 'Test message');
      expect(json['timestamp'], '2024-01-01T00:00:00.000');
      expect(json['messageId'], 'msg_123');
    });

    test('AiMessage should deserialize correctly', () {
      final json = {
        'role': 'assistant',
        'content': 'Test response',
        'timestamp': '2024-01-01T12:00:00.000Z',
        'messageId': 'msg_456',
      };

      final message = AiMessage.fromJson(json);

      expect(message.role, 'assistant');
      expect(message.content, 'Test response');
      expect(message.messageId, 'msg_456');
      expect(message.timestamp.year, 2024);
    });

    test('AiContext should serialize correctly', () {
      final context = AiContext(
        userRole: 'seeker',
        currentScreen: 'service_search',
        userPreferences: {'theme': 'light'},
        recentActivities: ['searched services', 'viewed profile'],
      );

      final json = context.toJson();

      expect(json['userRole'], 'seeker');
      expect(json['currentScreen'], 'service_search');
      expect(json['userPreferences']['theme'], 'light');
      expect(json['recentActivities'].length, 2);
    });

    test('AiSuggestion should deserialize correctly', () {
      final json = {
        'text': 'How to create a service?',
        'type': 'question',
        'actionTarget': 'service_creation',
        'parameters': {'category': 'help'},
      };

      final suggestion = AiSuggestion.fromJson(json);

      expect(suggestion.text, 'How to create a service?');
      expect(suggestion.type, 'question');
      expect(suggestion.actionTarget, 'service_creation');
      expect(suggestion.parameters?['category'], 'help');
    });
  });
}
