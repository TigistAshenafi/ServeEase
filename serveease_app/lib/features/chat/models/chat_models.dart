import 'package:equatable/equatable.dart';

// Message Types
enum MessageType {
  text,
  image,
  audio,
  file,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

// Chat Message Model
class ChatMessage extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? replyToId;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.replyToId,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderAvatar: json['senderAvatar'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      replyToId: json['replyToId'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'replyToId': replyToId,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      replyToId: replyToId ?? this.replyToId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        senderName,
        senderAvatar,
        content,
        type,
        status,
        timestamp,
        replyToId,
        metadata,
      ];
}

// Chat Room Model
class ChatRoom extends Equatable {
  final String id;
  final String name;
  final String? avatar;
  final List<String> participantIds;
  final List<ChatParticipant> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? serviceRequestId;
  final ChatType type;

  const ChatRoom({
    required this.id,
    required this.name,
    this.avatar,
    required this.participantIds,
    required this.participants,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.serviceRequestId,
    required this.type,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      participantIds: List<String>.from(json['participantIds'] ?? []),
      participants: (json['participants'] as List?)
              ?.map((p) => ChatParticipant.fromJson(p))
              .toList() ??
          [],
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      serviceRequestId: json['serviceRequestId'],
      type: ChatType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ChatType.direct,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'participantIds': participantIds,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'serviceRequestId': serviceRequestId,
      'type': type.toString().split('.').last,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    String? avatar,
    List<String>? participantIds,
    List<ChatParticipant>? participants,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serviceRequestId,
    ChatType? type,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceRequestId: serviceRequestId ?? this.serviceRequestId,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatar,
        participantIds,
        participants,
        lastMessage,
        unreadCount,
        createdAt,
        updatedAt,
        serviceRequestId,
        type,
      ];
}

// Chat Participant Model
class ChatParticipant extends Equatable {
  final String id;
  final String name;
  final String? avatar;
  final String role;
  final bool isOnline;
  final DateTime? lastSeen;

  const ChatParticipant({
    required this.id,
    required this.name,
    this.avatar,
    required this.role,
    required this.isOnline,
    this.lastSeen,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      role: json['role'],
      isOnline: json['isOnline'] ?? false,
      lastSeen:
          json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'role': role,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, avatar, role, isOnline, lastSeen];
}

// Chat Type Enum
enum ChatType {
  direct,
  group,
  support,
}

// Typing Indicator Model
class TypingIndicator extends Equatable {
  final String userId;
  final String userName;
  final String chatId;
  final DateTime timestamp;

  const TypingIndicator({
    required this.userId,
    required this.userName,
    required this.chatId,
    required this.timestamp,
  });

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      userId: json['userId'],
      userName: json['userName'],
      chatId: json['chatId'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'chatId': chatId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, userName, chatId, timestamp];
}
