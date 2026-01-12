import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/providers/ai_provider.dart';
import 'package:serveease_app/providers/auth_provider.dart';
import 'package:serveease_app/shared/widgets/app_bar_language_toggle.dart';
import 'package:serveease_app/core/models/ai_models.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _message = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAI();
    });
  }

  Future<void> _initializeAI() async {
    final auth = context.read<AuthProvider>();
    final ai = context.read<AiProvider>();

    if (auth.user != null && !ai.isInitialized) {
      await ai.initialize(auth.user);
      // Update context with current screen
      ai.updateContext(currentScreen: 'ai_chat');
      // Get initial workflow guidance
      await ai.getWorkflowGuidance();
    }
  }

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;

    final ai = context.read<AiProvider>();
    await ai.send(text, currentScreen: 'ai_chat');
    _message.clear();

    // Add activity to context
    ai.addRecentActivity(
        'Asked: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}');

    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendSuggestion(AiSuggestion suggestion) async {
    final ai = context.read<AiProvider>();
    await ai.send(suggestion.text, currentScreen: 'ai_chat');

    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _startNewConversation() async {
    final ai = context.read<AiProvider>();
    await ai.startNewConversation();
  }

  Future<void> _explainFeature(String featureName) async {
    final ai = context.read<AiProvider>();
    await ai.explainFeature(featureName);

    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessage(AiMessage message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
            if (!isUser) ...[
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(List<AiSuggestion> suggestions) {
    if (suggestions.isEmpty || !_showSuggestions) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suggestions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  setState(() {
                    _showSuggestions = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return ActionChip(
                label: Text(
                  suggestion.text,
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _sendSuggestion(suggestion),
                backgroundColor: _getSuggestionColor(suggestion.type),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getSuggestionColor(String type) {
    switch (type) {
      case 'action':
        return Colors.green.shade100;
      case 'workflow':
        return Colors.blue.shade100;
      case 'question':
      default:
        return Colors.orange.shade100;
    }
  }

  Widget _buildQuickActions() {
    final auth = context.watch<AuthProvider>();
    final userRole = auth.user?.role ?? '';

    List<Map<String, String>> actions = [];

    // Role-specific quick actions
    switch (userRole) {
      case 'seeker':
        actions = [
          {'title': 'Find Services', 'feature': 'service_search'},
          {'title': 'My Requests', 'feature': 'service_requests'},
          {'title': 'How to Book', 'feature': 'booking_process'},
        ];
        break;
      case 'individual_provider':
        actions = [
          {'title': 'Create Profile', 'feature': 'provider_profile'},
          {'title': 'Add Services', 'feature': 'service_management'},
          {'title': 'Upload Certificates', 'feature': 'certificate_upload'},
        ];
        break;
      case 'organization_provider':
        actions = [
          {'title': 'Manage Employees', 'feature': 'employee_management'},
          {'title': 'Assign Tasks', 'feature': 'task_assignment'},
          {'title': 'View Analytics', 'feature': 'provider_analytics'},
        ];
        break;
      default:
        actions = [
          {'title': 'Platform Overview', 'feature': 'platform_overview'},
          {'title': 'Getting Started', 'feature': 'getting_started'},
        ];
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Help',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((action) {
              return OutlinedButton(
                onPressed: () => _explainFeature(action['feature']!),
                child: Text(
                  action['title']!,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ServeEase AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewConversation,
            tooltip: 'New Conversation',
          ),
          const AppBarLanguageToggle(
            iconColor: Colors.grey,
            textColor: Colors.black,
            isCompact: true,
          ),
        ],
      ),
      body: Column(
        children: [
          // Context indicator
          if (ai.context != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Text(
                'Role: ${ai.context!.userRole.toUpperCase()} • Screen: ${ai.context!.currentScreen ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: ai.history.length +
                  (ai.suggestions.isNotEmpty ? 1 : 0) +
                  (ai.history.isEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                // Show quick actions when conversation is empty
                if (ai.history.isEmpty && index == 0) {
                  return _buildQuickActions();
                }

                // Show suggestions after messages
                if (index == ai.history.length && ai.suggestions.isNotEmpty) {
                  return _buildSuggestions(ai.suggestions);
                }

                // Show messages
                final messageIndex = ai.history.isEmpty ? index - 1 : index;
                if (messageIndex >= 0 && messageIndex < ai.history.length) {
                  return _buildMessage(ai.history[messageIndex]);
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          if (ai.isLoading) const LinearProgressIndicator(minHeight: 2),

          if (ai.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Text(
                ai.error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      decoration: InputDecoration(
                        hintText: _getHintText(auth.user?.role),
                        border: const OutlineInputBorder(),
                        suffixIcon: ai.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _send(),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: ai.isLoading ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHintText(String? userRole) {
    switch (userRole) {
      case 'seeker':
        return 'Ask about finding services, booking, or platform features...';
      case 'individual_provider':
        return 'Ask about creating profiles, adding services, or getting approved...';
      case 'organization_provider':
        return 'Ask about managing employees, assignments, or analytics...';
      default:
        return 'Ask anything about the ServeEase platform...';
    }
  }
}
