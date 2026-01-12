import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/conversation.dart';

class ChatService {
  static final Logger _logger = Logger('ChatService');
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final Dio _dio = Dio();
  io.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Stream controllers for real-time events
  final StreamController<Message> _newMessageController = StreamController<Message>.broadcast();
  final StreamController<List<Conversation>> _conversationsController = StreamController<List<Conversation>>.broadcast();
  final StreamController<TypingIndicator> _typingController = StreamController<TypingIndicator>.broadcast();
  final StreamController<Map<String, dynamic>> _messageStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userStatusController = StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Message> get newMessageStream => _newMessageController.stream;
  Stream<List<Conversation>> get conversationsStream => _conversationsController.stream;
  Stream<TypingIndicator> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get messageStatusStream => _messageStatusController.stream;
  Stream<Map<String, dynamic>> get userStatusStream => _userStatusController.stream;

  String? _baseUrl;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> initialize(String baseUrl) async {
    _baseUrl = baseUrl;
    
    // Configure Dio
    _dio.options.baseUrl = '$baseUrl/api/chat';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        _logger.severe('Chat API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('No auth token found');
      }

      _socket = io.io(_baseUrl, 
        io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build()
      );

      _socket!.onConnect((_) {
        _logger.info('Chat socket connected');
        _isConnected = true;
      });

      _socket!.onDisconnect((_) {
        _logger.warning('Chat socket disconnected');
        _isConnected = false;
      });

      _socket!.onConnectError((error) {
        _logger.severe('Chat socket connection error: $error');
        _isConnected = false;
      });

      // Listen for new messages
      _socket!.on('new_message', (data) {
        try {
          final message = Message.fromJson(data);
          _newMessageController.add(message);
        } catch (e) {
          _logger.severe('Error parsing new message: $e');
        }
      });

      // Listen for typing indicators
      _socket!.on('user_typing', (data) {
        try {
          final typing = TypingIndicator.fromJson(data);
          _typingController.add(typing);
        } catch (e) {
          _logger.severe('Error parsing typing indicator: $e');
        }
      });

      // Listen for message status updates
      _socket!.on('messages_read', (data) {
        _messageStatusController.add({
          'type': 'read',
          'data': data,
        });
      });

      _socket!.on('message_edited', (data) {
        _messageStatusController.add({
          'type': 'edited',
          'data': data,
        });
      });

      _socket!.on('message_deleted', (data) {
        _messageStatusController.add({
          'type': 'deleted',
          'data': data,
        });
      });

      // Listen for user status updates
      _socket!.on('user_online', (data) {
        _userStatusController.add({
          'type': 'online',
          'data': data,
        });
      });

      _socket!.on('user_offline', (data) {
        _userStatusController.add({
          'type': 'offline',
          'data': data,
        });
      });

      _socket!.connect();
    } catch (e) {
      _logger.severe('Error connecting to chat socket: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  // Join a conversation room
  void joinConversation(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_conversation', {'conversationId': conversationId});
    }
  }

  // Leave a conversation room
  void leaveConversation(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_conversation', {'conversationId': conversationId});
    }
  }

  // Send typing indicator
  void startTyping(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing_start', {'conversationId': conversationId});
    }
  }

  void stopTyping(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing_stop', {'conversationId': conversationId});
    }
  }

  // API Methods

  // Get conversations
  Future<List<Conversation>> getConversations({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get('/conversations', queryParameters: {
        'page': page,
        'limit': limit,
      });

      if (response.data['success']) {
        final List<dynamic> conversationsJson = response.data['conversations'];
        return conversationsJson.map((json) => Conversation.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get conversations');
      }
    } catch (e) {
      _logger.severe('Error getting conversations: $e');
      rethrow;
    }
  }

  // Get specific conversation
  Future<Conversation> getConversation(String conversationId) async {
    try {
      final response = await _dio.get('/conversations/$conversationId');

      if (response.data['success']) {
        return Conversation.fromJson(response.data['conversation']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get conversation');
      }
    } catch (e) {
      _logger.severe('Error getting conversation: $e');
      rethrow;
    }
  }

  // Create conversation
  Future<Conversation> createConversation({
    String? serviceRequestId,
    required String participantId,
  }) async {
    try {
      final response = await _dio.post('/conversations', data: {
        'serviceRequestId': serviceRequestId,
        'participantId': participantId,
      });

      if (response.data['success']) {
        // Get the full conversation details
        return await getConversation(response.data['conversation']['id']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create conversation');
      }
    } catch (e) {
      _logger.severe('Error creating conversation: $e');
      rethrow;
    }
  }

  // Get messages
  Future<List<Message>> getMessages(String conversationId, {int page = 1, int limit = 50}) async {
    try {
      final response = await _dio.get('/conversations/$conversationId/messages', queryParameters: {
        'page': page,
        'limit': limit,
      });

      if (response.data['success']) {
        final List<dynamic> messagesJson = response.data['messages'];
        return messagesJson.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get messages');
      }
    } catch (e) {
      _logger.severe('Error getting messages: $e');
      rethrow;
    }
  }

  // Send message via Socket.IO (real-time)
  void sendMessageRealtime({
    required String conversationId,
    required String content,
    MessageType messageType = MessageType.text,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
  }) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_message', {
        'conversationId': conversationId,
        'content': content,
        'messageType': messageType.name,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'replyToMessageId': replyToMessageId,
      });
    }
  }

  // Send message via HTTP (fallback)
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    MessageType messageType = MessageType.text,
    String? replyToMessageId,
  }) async {
    try {
      final response = await _dio.post('/conversations/$conversationId/messages', data: {
        'content': content,
        'messageType': messageType.name,
        'replyToMessageId': replyToMessageId,
      });

      if (response.data['success']) {
        return Message.fromJson(response.data['message']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      _logger.severe('Error sending message: $e');
      rethrow;
    }
  }

  // Upload file
  Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      });

      final response = await _dio.post('/upload', data: formData);

      if (response.data['success']) {
        return response.data['file'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload file');
      }
    } catch (e) {
      _logger.severe('Error uploading file: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, {List<String>? messageIds}) async {
    try {
      await _dio.post('/conversations/$conversationId/read', data: {
        'messageIds': messageIds,
      });

      // Also emit via socket for real-time updates
      if (_socket != null && _socket!.connected) {
        _socket!.emit('mark_messages_read', {
          'conversationId': conversationId,
          'messageIds': messageIds,
        });
      }
    } catch (e) {
      _logger.severe('Error marking messages as read: $e');
      rethrow;
    }
  }

  // Edit message
  Future<void> editMessage(String messageId, String content) async {
    try {
      final response = await _dio.put('/messages/$messageId', data: {
        'content': content,
      });

      if (!response.data['success']) {
        throw Exception(response.data['message'] ?? 'Failed to edit message');
      }
    } catch (e) {
      _logger.severe('Error editing message: $e');
      rethrow;
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      final response = await _dio.delete('/messages/$messageId');

      if (!response.data['success']) {
        throw Exception(response.data['message'] ?? 'Failed to delete message');
      }
    } catch (e) {
      _logger.severe('Error deleting message: $e');
      rethrow;
    }
  }

  // Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      final response = await _dio.put('/conversations/$conversationId/archive');

      if (!response.data['success']) {
        throw Exception(response.data['message'] ?? 'Failed to archive conversation');
      }
    } catch (e) {
      _logger.severe('Error archiving conversation: $e');
      rethrow;
    }
  }

  // Block conversation
  Future<void> blockConversation(String conversationId) async {
    try {
      final response = await _dio.put('/conversations/$conversationId/block');

      if (!response.data['success']) {
        throw Exception(response.data['message'] ?? 'Failed to block conversation');
      }
    } catch (e) {
      _logger.severe('Error blocking conversation: $e');
      rethrow;
    }
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _newMessageController.close();
    _conversationsController.close();
    _typingController.close();
    _messageStatusController.close();
    _userStatusController.close();
  }
}