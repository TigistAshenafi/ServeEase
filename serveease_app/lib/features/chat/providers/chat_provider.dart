import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  // State variables
  List<Conversation> _conversations = [];
  List<Message> _currentMessages = [];
  Conversation? _currentConversation;
  bool _isLoading = false;
  bool _isLoadingMessages = false;
  bool _isConnected = false;
  String? _error;
  final Map<String, bool> _typingUsers = {};
  final Map<String, bool> _onlineUsers = {};
  
  // Stream subscriptions
  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _messageStatusSubscription;
  StreamSubscription? _userStatusSubscription;

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Message> get currentMessages => _currentMessages;
  Conversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isConnected => _isConnected;
  String? get error => _error;
  Map<String, bool> get typingUsers => _typingUsers;
  Map<String, bool> get onlineUsers => _onlineUsers;

  // Initialize chat service
  Future<void> initialize(String baseUrl) async {
    try {
      await _chatService.initialize(baseUrl);
      await _chatService.connect();
      _isConnected = _chatService.isConnected;
      
      _setupStreamListeners();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Setup stream listeners for real-time updates
  void _setupStreamListeners() {
    // Listen for new messages
    _newMessageSubscription = _chatService.newMessageStream.listen((message) {
      _handleNewMessage(message);
    });

    // Listen for typing indicators
    _typingSubscription = _chatService.typingStream.listen((typing) {
      _handleTypingIndicator(typing);
    });

    // Listen for message status updates
    _messageStatusSubscription = _chatService.messageStatusStream.listen((statusUpdate) {
      _handleMessageStatusUpdate(statusUpdate);
    });

    // Listen for user status updates
    _userStatusSubscription = _chatService.userStatusStream.listen((userStatus) {
      _handleUserStatusUpdate(userStatus);
    });
  }

  // Handle new message
  void _handleNewMessage(Message message) {
    // Update current messages if viewing this conversation
    if (_currentConversation?.id == message.conversationId) {
      _currentMessages.add(message);
      
      // Mark message as read if conversation is active
      _chatService.markMessagesAsRead(message.conversationId, messageIds: [message.id]);
    }

    // Update conversation list
    _updateConversationWithMessage(message);
    notifyListeners();
  }

  // Handle typing indicator
  void _handleTypingIndicator(TypingIndicator typing) {
    if (typing.isTyping) {
      _typingUsers[typing.userId] = true;
    } else {
      _typingUsers.remove(typing.userId);
    }
    notifyListeners();
  }

  // Handle message status updates
  void _handleMessageStatusUpdate(Map<String, dynamic> statusUpdate) {
    final type = statusUpdate['type'];
    final data = statusUpdate['data'];

    switch (type) {
      case 'read':
        _handleMessagesRead(data);
        break;
      case 'edited':
        _handleMessageEdited(data);
        break;
      case 'deleted':
        _handleMessageDeleted(data);
        break;
    }
  }

  // Handle user status updates
  void _handleUserStatusUpdate(Map<String, dynamic> userStatus) {
    final type = userStatus['type'];
    final data = userStatus['data'];

    switch (type) {
      case 'online':
        _onlineUsers[data['userId']] = true;
        break;
      case 'offline':
        _onlineUsers.remove(data['userId']);
        break;
    }
    notifyListeners();
  }

  // Update conversation with new message
  void _updateConversationWithMessage(Message message) {
    final conversationIndex = _conversations.indexWhere((c) => c.id == message.conversationId);
    if (conversationIndex != -1) {
      final conversation = _conversations[conversationIndex];
      final updatedConversation = conversation.copyWith(
        lastMessage: message,
        lastMessageAt: message.createdAt,
        unreadCount: message.isFromMe ? conversation.unreadCount : conversation.unreadCount + 1,
      );
      
      // Move conversation to top
      _conversations.removeAt(conversationIndex);
      _conversations.insert(0, updatedConversation);
    }
  }

  // Handle messages read
  void _handleMessagesRead(Map<String, dynamic> data) {
    final conversationId = data['conversationId'];
    final userId = data['userId'];
    
    if (_currentConversation?.id == conversationId) {
      // Update read status for messages
      for (int i = 0; i < _currentMessages.length; i++) {
        final message = _currentMessages[i];
        if (message.senderId != userId) {
          _currentMessages[i] = message.copyWith(
            readCount: message.readCount + 1,
          );
        }
      }
      notifyListeners();
    }
  }

  // Handle message edited
  void _handleMessageEdited(Map<String, dynamic> data) {
    final messageId = data['messageId'];
    final content = data['content'];
    final editedAt = DateTime.parse(data['editedAt']);

    if (_currentConversation != null) {
      final messageIndex = _currentMessages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        _currentMessages[messageIndex] = _currentMessages[messageIndex].copyWith(
          content: content,
          isEdited: true,
          editedAt: editedAt,
        );
        notifyListeners();
      }
    }
  }

  // Handle message deleted
  void _handleMessageDeleted(Map<String, dynamic> data) {
    final messageId = data['messageId'];

    if (_currentConversation != null) {
      _currentMessages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    }
  }

  // Load conversations
  Future<void> loadConversations({bool refresh = false}) async {
    if (refresh) {
      _conversations.clear();
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversations = await _chatService.getConversations();
      _conversations = conversations;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load conversation messages
  Future<void> loadMessages(String conversationId, {bool refresh = false}) async {
    if (refresh) {
      _currentMessages.clear();
    }

    _isLoadingMessages = true;
    _error = null;
    notifyListeners();

    try {
      // Get conversation details
      _currentConversation = await _chatService.getConversation(conversationId);
      
      // Join conversation room for real-time updates
      _chatService.joinConversation(conversationId);
      
      // Load messages
      final messages = await _chatService.getMessages(conversationId);
      _currentMessages = messages;
      
      // Mark messages as read
      await _chatService.markMessagesAsRead(conversationId);
      
      // Update conversation unread count
      _updateConversationUnreadCount(conversationId, 0);
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // Create new conversation
  Future<Conversation?> createConversation({
    String? serviceRequestId,
    required String participantId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final conversation = await _chatService.createConversation(
        serviceRequestId: serviceRequestId,
        participantId: participantId,
      );

      // Add to conversations list if not already present
      if (!_conversations.any((c) => c.id == conversation.id)) {
        _conversations.insert(0, conversation);
      }

      return conversation;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send message
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    MessageType messageType = MessageType.text,
    String? replyToMessageId,
  }) async {
    try {
      // Create temporary message for immediate UI update
      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderId: 'current_user', // Replace with actual user ID
        messageType: messageType,
        content: content,
        isRead: false,
        isEdited: false,
        createdAt: DateTime.now(),
        sender: ChatUser(
          id: 'current_user',
          name: 'You',
          email: '',
        ),
        readCount: 0,
        isFromMe: true,
        status: MessageStatus.sending,
      );

      // Add to current messages immediately
      if (_currentConversation?.id == conversationId) {
        _currentMessages.add(tempMessage);
        notifyListeners();
      }

      // Send via real-time socket
      _chatService.sendMessageRealtime(
        conversationId: conversationId,
        content: content,
        messageType: messageType,
        replyToMessageId: replyToMessageId,
      );

      // Remove temporary message (real message will come via socket)
      if (_currentConversation?.id == conversationId) {
        _currentMessages.removeWhere((m) => m.id == tempMessage.id);
        notifyListeners();
      }

    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send file message
  Future<void> sendFileMessage({
    required String conversationId,
    required File file,
    MessageType messageType = MessageType.file,
  }) async {
    try {
      // Upload file first
      final fileInfo = await _chatService.uploadFile(file);
      
      // Send message with file info
      _chatService.sendMessageRealtime(
        conversationId: conversationId,
        content: fileInfo['name'],
        messageType: messageType,
        fileUrl: fileInfo['url'],
        fileName: fileInfo['name'],
        fileSize: fileInfo['size'],
      );

    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Start typing
  void startTyping(String conversationId) {
    _chatService.startTyping(conversationId);
  }

  // Stop typing
  void stopTyping(String conversationId) {
    _chatService.stopTyping(conversationId);
  }

  // Edit message
  Future<void> editMessage(String messageId, String content) async {
    try {
      await _chatService.editMessage(messageId, content);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      await _chatService.archiveConversation(conversationId);
      _conversations.removeWhere((c) => c.id == conversationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Block conversation
  Future<void> blockConversation(String conversationId) async {
    try {
      await _chatService.blockConversation(conversationId);
      _conversations.removeWhere((c) => c.id == conversationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update conversation unread count
  void _updateConversationUnreadCount(String conversationId, int unreadCount) {
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
        unreadCount: unreadCount,
      );
    }
  }

  // Leave current conversation
  void leaveCurrentConversation() {
    if (_currentConversation != null) {
      _chatService.leaveConversation(_currentConversation!.id);
      _currentConversation = null;
      _currentMessages.clear();
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Check if user is online
  bool isUserOnline(String userId) {
    return _onlineUsers[userId] ?? false;
  }

  // Check if user is typing
  bool isUserTyping(String userId) {
    return _typingUsers[userId] ?? false;
  }

  @override
  void dispose() {
    _newMessageSubscription?.cancel();
    _typingSubscription?.cancel();
    _messageStatusSubscription?.cancel();
    _userStatusSubscription?.cancel();
    _chatService.dispose();
    super.dispose();
  }
}