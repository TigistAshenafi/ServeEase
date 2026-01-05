class Conversation {
  final String id;
  final String? serviceRequestId;
  final String? serviceTitle;
  final String status;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final ConversationParticipants participants;
  final ChatUser otherParticipant;
  final Message? lastMessage;
  final int unreadCount;

  Conversation({
    required this.id,
    this.serviceRequestId,
    this.serviceTitle,
    required this.status,
    required this.lastMessageAt,
    required this.createdAt,
    required this.participants,
    required this.otherParticipant,
    this.lastMessage,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      serviceRequestId: json['serviceRequestId'],
      serviceTitle: json['serviceTitle'],
      status: json['status'],
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      createdAt: DateTime.parse(json['createdAt']),
      participants: ConversationParticipants.fromJson(json['participants']),
      otherParticipant: ChatUser.fromJson(json['otherParticipant']),
      lastMessage: json['lastMessage'] != null 
          ? Message.fromJson(json['lastMessage']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceRequestId': serviceRequestId,
      'serviceTitle': serviceTitle,
      'status': status,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'participants': participants.toJson(),
      'otherParticipant': otherParticipant.toJson(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
    };
  }

  Conversation copyWith({
    String? id,
    String? serviceRequestId,
    String? serviceTitle,
    String? status,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    ConversationParticipants? participants,
    ChatUser? otherParticipant,
    Message? lastMessage,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      serviceRequestId: serviceRequestId ?? this.serviceRequestId,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      status: status ?? this.status,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
      otherParticipant: otherParticipant ?? this.otherParticipant,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ConversationParticipants {
  final ChatUser seeker;
  final ChatUser provider;

  ConversationParticipants({
    required this.seeker,
    required this.provider,
  });

  factory ConversationParticipants.fromJson(Map<String, dynamic> json) {
    return ConversationParticipants(
      seeker: ChatUser.fromJson(json['seeker']),
      provider: ChatUser.fromJson(json['provider']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seeker': seeker.toJson(),
      'provider': provider.toJson(),
    };
  }
}

class ChatUser {
  final String id;
  final String name;
  final String email;
  final String? role;
  final String? avatarUrl;
  final bool? isOnline;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.avatarUrl,
    this.isOnline,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      avatarUrl: json['avatarUrl'],
      isOnline: json['isOnline'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
    };
  }

  ChatUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
    bool? isOnline,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType messageType;
  final String content;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final bool isRead;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;
  final ChatUser sender;
  final ReplyMessage? replyTo;
  final int readCount;
  final bool isFromMe;
  final MessageStatus status;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    required this.content,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.isRead,
    required this.isEdited,
    this.editedAt,
    required this.createdAt,
    required this.sender,
    this.replyTo,
    required this.readCount,
    required this.isFromMe,
    this.status = MessageStatus.sent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversationId'],
      senderId: json['senderId'],
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['messageType'],
        orElse: () => MessageType.text,
      ),
      content: json['content'],
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      isRead: json['isRead'] ?? false,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      sender: ChatUser.fromJson(json['sender']),
      replyTo: json['replyTo'] != null ? ReplyMessage.fromJson(json['replyTo']) : null,
      readCount: json['readCount'] ?? 0,
      isFromMe: json['isFromMe'] ?? false,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'messageType': messageType.name,
      'content': content,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'isRead': isRead,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'sender': sender.toJson(),
      'replyTo': replyTo?.toJson(),
      'readCount': readCount,
      'isFromMe': isFromMe,
      'status': status.name,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    MessageType? messageType,
    String? content,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    bool? isRead,
    bool? isEdited,
    DateTime? editedAt,
    DateTime? createdAt,
    ChatUser? sender,
    ReplyMessage? replyTo,
    int? readCount,
    bool? isFromMe,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
      replyTo: replyTo ?? this.replyTo,
      readCount: readCount ?? this.readCount,
      isFromMe: isFromMe ?? this.isFromMe,
      status: status ?? this.status,
    );
  }
}

class ReplyMessage {
  final String id;
  final String content;
  final String senderName;

  ReplyMessage({
    required this.id,
    required this.content,
    required this.senderName,
  });

  factory ReplyMessage.fromJson(Map<String, dynamic> json) {
    return ReplyMessage(
      id: json['id'],
      content: json['content'],
      senderName: json['senderName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderName': senderName,
    };
  }
}

enum MessageType {
  text,
  image,
  file,
  location,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class TypingIndicator {
  final String conversationId;
  final String userId;
  final String userName;
  final bool isTyping;

  TypingIndicator({
    required this.conversationId,
    required this.userId,
    required this.userName,
    required this.isTyping,
  });

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      conversationId: json['conversationId'],
      userId: json['userId'],
      userName: json['userName'],
      isTyping: json['isTyping'],
    );
  }
}