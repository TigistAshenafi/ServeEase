import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/conversation.dart';

class ChatService {
  static final Logger _logger = Logger('ChatService');
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final Dio _dio = Dio();
  io.Socket? _socket;
  
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
    final chatApiUrl = '$baseUrl/api/chat';
    _dio.options.baseUrl = chatApiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    _logger.info('ChatService: Initialized with base URL: $chatApiUrl');
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        _logger.info('ChatService: Making request to: ${options.baseUrl}${options.path}');
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          _logger.info('ChatService: Added auth header with token: ${token.substring(0, 20)}...');
        } else {
          _logger.severe('ChatService: No access token found!');
        }
        handler.next(options);
      },
      onError: (error, handler) {
        _logger.severe('Chat API Error: ${error.message}');
        _logger.severe('Chat API Error Response: ${error.response?.data}');
        _logger.severe('Chat API Error Status: ${error.response?.statusCode}');
        handler.next(error);
      },
    ));
  }

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      _logger.info('Socket already connected');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        throw Exception('No auth token found');
      }

      _logger.info('Connecting to chat socket at: $_baseUrl');
      _logger.info('Using token: ${token.substring(0, 20)}...');

      _socket = io.io(_baseUrl, 
        io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build()
      );

      _socket!.onConnect((_) {
        _logger.info('Chat socket connected successfully');
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
          _logger.info('Received new message: $data');
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

      // Listen for errors
      _socket!.on('error', (data) {
        _logger.severe('Socket error: $data');
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
    _logger.info('Attempting to join conversation: $conversationId');
    _logger.info('Socket connected: ${_socket?.connected}');
    
    if (_socket != null && _socket!.connected) {
      _logger.info('Emitting join_conversation event');
      _socket!.emit('join_conversation', {'conversationId': conversationId});
    } else {
      _logger.severe('Socket not connected, cannot join conversation');
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

  // Create conversation for service request
  Future<Conversation> createConversationForServiceRequest(String serviceRequestId) async {
    try {
      print('ChatService: Creating conversation for service request: $serviceRequestId');
      print('ChatService: Base URL is: ${_dio.options.baseUrl}');
      print('ChatService: Full URL will be: ${_dio.options.baseUrl}/conversations');
      
      final response = await _dio.post('/conversations', data: {
        'serviceRequestId': serviceRequestId,
      });

      print('ChatService: Create conversation response: ${response.data}');

      if (response.data['success']) {
        // Get the full conversation details
        final conversationId = response.data['conversation']['id'];
        print('ChatService: Getting conversation details for: $conversationId');
        return await getConversation(conversationId);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create conversation');
      }
    } catch (e) {
      print('ChatService: Error creating conversation: $e');
      if (e is DioException) {
        print('ChatService: Error response data: ${e.response?.data}');
        print('ChatService: Error status code: ${e.response?.statusCode}');
        print('ChatService: Error request URL: ${e.requestOptions.uri}');
      }
      _logger.severe('Error creating conversation for service request: $e');
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
    _logger.info('Attempting to send message via Socket.IO');
    _logger.info('Socket connected: ${_socket?.connected}');
    _logger.info('Conversation ID: $conversationId');
    _logger.info('Content: $content');
    
    if (_socket != null && _socket!.connected) {
      _logger.info('Emitting send_message event');
      _socket!.emit('send_message', {
        'conversationId': conversationId,
        'content': content,
        'messageType': messageType.name,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'replyToMessageId': replyToMessageId,
      });
    } else {
      _logger.severe('Socket not connected, cannot send message');
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
      _logger.info('Sending message via HTTP API');
      _logger.info('Conversation ID: $conversationId');
      _logger.info('Content: $content');
      _logger.info('Message Type: ${messageType.name}');
      
      final response = await _dio.post('/conversations/$conversationId/messages', data: {
        'content': content,
        'messageType': messageType.name,
        'replyToMessageId': replyToMessageId,
      });

      _logger.info('HTTP API Response: ${response.data}');

      if (response.data['success']) {
        return Message.fromJson(response.data['message']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      _logger.severe('Error sending message via HTTP: $e');
      if (e is DioException) {
        _logger.severe('Response data: ${e.response?.data}');
        _logger.severe('Status code: ${e.response?.statusCode}');
      }
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