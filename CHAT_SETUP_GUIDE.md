# ServeEase Chat Feature Setup Guide

## 🚀 Overview

This guide will help you set up the complete real-time chat feature for ServeEase, including both backend (Node.js + Socket.IO) and frontend (Flutter) implementations.

## 📋 Features Implemented

### Backend Features
- **Real-time messaging** with Socket.IO
- **Message types**: Text, Images, Files, Location
- **Message status**: Sent, Delivered, Read receipts
- **Typing indicators** in real-time
- **File uploads** with support for images and documents
- **Message editing and deletion**
- **Conversation management** (archive, block)
- **User online/offline status**
- **Message replies** and threading
- **Conversation creation** from service requests

### Frontend Features
- **Real-time chat interface** with Socket.IO client
- **Message bubbles** with different styles for sent/received
- **Image viewer** with zoom and pan
- **File sharing** with image picker and file picker
- **Emoji picker** for enhanced messaging
- **Typing indicators** with animated dots
- **Message actions** (reply, edit, delete, copy)
- **Conversation list** with unread counts
- **Online status indicators**
- **Pull-to-refresh** for conversations

## 🛠 Backend Setup

### 1. Install Dependencies

```bash
cd serveease_backend
npm install socket.io
```

### 2. Database Setup

Run the chat schema SQL file:

```bash
# Connect to your PostgreSQL database and run:
psql -U your_username -d serveease_db -f database/chat_schema.sql
```

### 3. Environment Variables

Add to your `.env` file:

```env
# Existing variables...
JWT_SECRET=your_jwt_secret_here
```

### 4. Start the Server

```bash
npm run dev
```

The server will now support both HTTP API and WebSocket connections on the same port.

## 📱 Flutter Setup

### 1. Install Dependencies

```bash
cd serveease_app
flutter pub get
```

### 2. Environment Configuration

Update your `.env` file:

```env
API_BASE_URL=http://localhost:5000
# For Android emulator: http://10.0.2.2:5000
# For iOS simulator: http://localhost:5000
# For physical device: http://YOUR_COMPUTER_IP:5000
```

### 3. Permissions (Android)

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
```

### 4. Permissions (iOS)

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take photos for chat</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to share images in chat</string>
```

## 🔧 API Endpoints

### Chat REST API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/chat/conversations` | Get user's conversations |
| POST | `/api/chat/conversations` | Create new conversation |
| GET | `/api/chat/conversations/:id` | Get conversation details |
| GET | `/api/chat/conversations/:id/messages` | Get conversation messages |
| POST | `/api/chat/conversations/:id/messages` | Send message (HTTP fallback) |
| POST | `/api/chat/upload` | Upload file for chat |
| PUT | `/api/chat/messages/:id` | Edit message |
| DELETE | `/api/chat/messages/:id` | Delete message |
| POST | `/api/chat/conversations/:id/read` | Mark messages as read |

### Socket.IO Events

#### Client to Server
- `join_conversation` - Join a conversation room
- `leave_conversation` - Leave a conversation room
- `send_message` - Send a message in real-time
- `typing_start` - Start typing indicator
- `typing_stop` - Stop typing indicator
- `mark_messages_read` - Mark messages as read

#### Server to Client
- `new_message` - Receive new message
- `user_typing` - User typing indicator
- `messages_read` - Messages read receipt
- `message_edited` - Message was edited
- `message_deleted` - Message was deleted
- `user_online` - User came online
- `user_offline` - User went offline

## 🎯 Usage Examples

### Creating a Conversation

```dart
// From a service request
final conversation = await chatProvider.createConversation(
  serviceRequestId: 'service-request-id',
  participantId: 'provider-user-id',
);

// Direct conversation
final conversation = await chatProvider.createConversation(
  participantId: 'other-user-id',
);
```

### Sending Messages

```dart
// Text message
await chatProvider.sendMessage(
  conversationId: conversationId,
  content: 'Hello, how are you?',
);

// Reply to message
await chatProvider.sendMessage(
  conversationId: conversationId,
  content: 'Thanks for your message!',
  replyToMessageId: originalMessageId,
);

// File message
await chatProvider.sendFileMessage(
  conversationId: conversationId,
  file: selectedFile,
  messageType: MessageType.image,
);
```

### Navigation

```dart
// Navigate to conversations list
Navigator.pushNamed(context, '/chat');

// Navigate to specific chat
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatScreen(conversationId: conversationId),
  ),
);
```

## 🔐 Authentication

The chat system uses JWT authentication:

1. **Backend**: Socket.IO middleware validates JWT tokens
2. **Frontend**: Tokens are automatically included in API requests and Socket.IO auth

## 📊 Database Schema

### Key Tables

- **conversations**: Chat conversations between users
- **messages**: Individual chat messages
- **message_read_receipts**: Read status tracking
- **conversation_participants**: Conversation membership
- **typing_indicators**: Real-time typing status

## 🎨 UI Components

### Main Screens
- `ConversationsScreen`: List of all conversations
- `ChatScreen`: Individual chat interface

### Widgets
- `MessageBubble`: Individual message display
- `TypingIndicator`: Animated typing dots

### Features
- **Message Actions**: Long press for reply, edit, delete, copy
- **File Sharing**: Image picker and file picker integration
- **Emoji Support**: Emoji picker for enhanced messaging
- **Image Viewing**: Full-screen image viewer with zoom

## 🚨 Troubleshooting

### Common Issues

1. **Socket Connection Failed**
   - Check if backend server is running
   - Verify API_BASE_URL in .env
   - Check network connectivity

2. **Messages Not Sending**
   - Verify JWT token is valid
   - Check Socket.IO connection status
   - Fallback to HTTP API if Socket.IO fails

3. **File Upload Issues**
   - Check file permissions
   - Verify upload directory exists: `serveease_backend/uploads/chat/`
   - Check file size limits (10MB default)

4. **Real-time Updates Not Working**
   - Ensure Socket.IO connection is established
   - Check if user joined conversation room
   - Verify event listeners are set up correctly

### Debug Tips

1. **Backend Debugging**
   ```javascript
   // Add to socketService.js
   console.log('User connected:', socket.user.name);
   console.log('Message received:', data);
   ```

2. **Flutter Debugging**
   ```dart
   // Add to ChatProvider
   print('Socket connected: ${_chatService.isConnected}');
   print('New message received: ${message.content}');
   ```

## 🔄 Integration with Existing Features

### Service Requests Integration

When a service request is created, you can automatically create a chat conversation:

```dart
// After creating service request
final conversation = await chatProvider.createConversation(
  serviceRequestId: serviceRequest.id,
  participantId: providerId,
);
```

### Navigation Integration

Add chat button to service request details:

```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversationId),
      ),
    );
  },
  icon: Icon(Icons.chat),
  label: Text('Chat with Provider'),
)
```

## 📈 Performance Considerations

1. **Message Pagination**: Messages are loaded in pages (50 per page)
2. **Image Caching**: Uses `cached_network_image` for efficient image loading
3. **Connection Management**: Automatic reconnection on network changes
4. **Memory Management**: Proper disposal of streams and controllers

## 🔒 Security Features

1. **JWT Authentication**: All Socket.IO connections require valid JWT
2. **User Verification**: Users can only access their own conversations
3. **File Validation**: File type and size validation on upload
4. **Input Sanitization**: All message content is validated

## 🚀 Deployment Notes

### Production Considerations

1. **Environment Variables**
   ```env
   # Production
   API_BASE_URL=https://your-api-domain.com
   JWT_SECRET=your-production-jwt-secret
   ```

2. **File Storage**: Consider using cloud storage (AWS S3, Google Cloud) for production file uploads

3. **Scaling**: For high traffic, consider Redis adapter for Socket.IO clustering

4. **SSL/TLS**: Ensure HTTPS/WSS for production WebSocket connections

This chat feature provides a complete real-time messaging solution that integrates seamlessly with your existing ServeEase platform!