import jwt from 'jsonwebtoken';
import { query } from '../config/database.js';

const connectedUsers = new Map(); // userId -> socketId
const userSockets = new Map(); // socketId -> userId

export const initializeSocket = (io) => {
  // Authentication middleware for Socket.IO
  io.use(async (socket, next) => {
    try {
      console.log('Socket: Authentication attempt');
      const token = socket.handshake.auth.token;
      
      if (!token) {
        console.log('Socket: No token provided');
        return next(new Error('Authentication error: No token provided'));
      }

      console.log('Socket: Token received:', token.substring(0, 20) + '...');
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const userId = decoded.userId;
      console.log('Socket: Decoded user ID:', userId);

      // Verify user exists and is active
      const userResult = await query(
        'SELECT id, name, email, role, is_active FROM users WHERE id = $1',
        [userId]
      );

      if (userResult.rows.length === 0 || !userResult.rows[0].is_active) {
        console.log('Socket: User not found or inactive');
        return next(new Error('User not found or inactive'));
      }

      socket.userId = userId;
      socket.user = userResult.rows[0];
      console.log('Socket: Authentication successful for user:', socket.user.name);
      next();
    } catch (error) {
      console.error('Socket authentication error:', error);
      next(new Error('Authentication error: ' + error.message));
    }
  });

  io.on('connection', (socket) => {
    console.log(`Socket: User ${socket.user.name} (ID: ${socket.userId}) connected with socket ID: ${socket.id}`);
    
    // Store user connection
    connectedUsers.set(socket.userId, socket.id);
    userSockets.set(socket.id, socket.userId);

    // Join user to their personal room
    socket.join(`user_${socket.userId}`);
    console.log(`Socket: User ${socket.userId} joined personal room: user_${socket.userId}`);

    // Emit online status to contacts
    socket.broadcast.emit('user_online', {
      userId: socket.userId,
      name: socket.user.name
    });

    // Handle joining conversation rooms
    socket.on('join_conversation', async (data) => {
      try {
        const { conversationId } = data;
        console.log('Socket: User', socket.userId, 'attempting to join conversation:', conversationId);
        
        // Verify user is participant in this conversation
        const participantCheck = await query(
          `SELECT cp.* FROM conversation_participants cp 
           WHERE cp.conversation_id = $1 AND cp.user_id = $2 AND cp.left_at IS NULL`,
          [conversationId, socket.userId]
        );

        if (participantCheck.rows.length > 0) {
          socket.join(`conversation_${conversationId}`);
          console.log(`Socket: User ${socket.userId} successfully joined conversation ${conversationId}`);
          
          // Mark messages as read
          await markMessagesAsRead(conversationId, socket.userId);
          
          // Emit read receipts to other participants
          socket.to(`conversation_${conversationId}`).emit('messages_read', {
            conversationId,
            userId: socket.userId,
            readAt: new Date().toISOString()
          });
        } else {
          console.log('Socket: User', socket.userId, 'not authorized for conversation:', conversationId);
          socket.emit('error', { message: 'Not authorized to join this conversation' });
        }
      } catch (error) {
        console.error('Socket: Error joining conversation:', error);
        socket.emit('error', { message: 'Failed to join conversation' });
      }
    });

    // Handle leaving conversation rooms
    socket.on('leave_conversation', (data) => {
      const { conversationId } = data;
      socket.leave(`conversation_${conversationId}`);
      console.log(`User ${socket.userId} left conversation ${conversationId}`);
    });

    // Handle sending messages
    socket.on('send_message', async (data) => {
      try {
        console.log('Socket: Received send_message event from user:', socket.userId);
        console.log('Socket: Message data:', data);
        
        const {
          conversationId,
          content,
          messageType = 'text',
          fileUrl,
          fileName,
          fileSize,
          replyToMessageId
        } = data;

        // Verify user is participant in this conversation
        const participantCheck = await query(
          `SELECT cp.* FROM conversation_participants cp 
           WHERE cp.conversation_id = $1 AND cp.user_id = $2 AND cp.left_at IS NULL`,
          [conversationId, socket.userId]
        );

        if (participantCheck.rows.length === 0) {
          console.log('Socket: User not authorized for conversation:', conversationId);
          socket.emit('error', { message: 'Not authorized to send messages in this conversation' });
          return;
        }

        console.log('Socket: User authorized, inserting message into database');

        // Insert message into database
        const messageResult = await query(
          `INSERT INTO messages (conversation_id, sender_id, message_type, content, file_url, file_name, file_size, reply_to_message_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
           RETURNING *`,
          [conversationId, socket.userId, messageType, content, fileUrl, fileName, fileSize, replyToMessageId]
        );

        const message = messageResult.rows[0];
        console.log('Socket: Message inserted with ID:', message.id);

        // Get sender info
        const senderInfo = {
          id: socket.user.id,
          name: socket.user.name,
          email: socket.user.email
        };

        // Prepare message data for broadcast
        const messageData = {
          id: message.id,
          conversationId: message.conversation_id,
          senderId: message.sender_id,
          messageType: message.message_type,
          content: message.content,
          fileUrl: message.file_url,
          fileName: message.file_name,
          fileSize: message.file_size,
          replyToMessageId: message.reply_to_message_id,
          isRead: false,
          createdAt: message.created_at,
          sender: senderInfo
        };

        console.log('Socket: Broadcasting message to conversation room:', `conversation_${conversationId}`);
        console.log('Socket: Message data to broadcast:', messageData);

        // Broadcast message to all participants in the conversation
        io.to(`conversation_${conversationId}`).emit('new_message', messageData);

        // Send push notification to offline users (implement as needed)
        await sendPushNotificationToOfflineUsers(conversationId, socket.userId, messageData);

      } catch (error) {
        console.error('Socket: Error sending message:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // Handle typing indicators
    socket.on('typing_start', async (data) => {
      try {
        const { conversationId } = data;
        
        // Update typing indicator in database
        await query(
          `INSERT INTO typing_indicators (conversation_id, user_id, is_typing, updated_at)
           VALUES ($1, $2, true, NOW())
           ON CONFLICT (conversation_id, user_id)
           DO UPDATE SET is_typing = true, updated_at = NOW()`,
          [conversationId, socket.userId]
        );

        // Broadcast typing indicator to other participants
        socket.to(`conversation_${conversationId}`).emit('user_typing', {
          conversationId,
          userId: socket.userId,
          userName: socket.user.name,
          isTyping: true
        });
      } catch (error) {
        console.error('Error handling typing start:', error);
      }
    });

    socket.on('typing_stop', async (data) => {
      try {
        const { conversationId } = data;
        
        // Update typing indicator in database
        await query(
          `UPDATE typing_indicators 
           SET is_typing = false, updated_at = NOW()
           WHERE conversation_id = $1 AND user_id = $2`,
          [conversationId, socket.userId]
        );

        // Broadcast typing stop to other participants
        socket.to(`conversation_${conversationId}`).emit('user_typing', {
          conversationId,
          userId: socket.userId,
          userName: socket.user.name,
          isTyping: false
        });
      } catch (error) {
        console.error('Error handling typing stop:', error);
      }
    });

    // Handle message read receipts
    socket.on('mark_messages_read', async (data) => {
      try {
        const { conversationId, messageIds } = data;
        
        if (messageIds && messageIds.length > 0) {
          // Mark specific messages as read
          for (const messageId of messageIds) {
            await query(
              `INSERT INTO message_read_receipts (message_id, user_id)
               VALUES ($1, $2)
               ON CONFLICT (message_id, user_id) DO NOTHING`,
              [messageId, socket.userId]
            );
          }
        } else {
          // Mark all unread messages in conversation as read
          await markMessagesAsRead(conversationId, socket.userId);
        }

        // Broadcast read receipts to other participants
        socket.to(`conversation_${conversationId}`).emit('messages_read', {
          conversationId,
          userId: socket.userId,
          messageIds,
          readAt: new Date().toISOString()
        });
      } catch (error) {
        console.error('Error marking messages as read:', error);
      }
    });

    // Handle disconnect
    socket.on('disconnect', async () => {
      console.log(`User ${socket.user.name} disconnected: ${socket.id}`);
      
      // Remove user from connected users
      connectedUsers.delete(socket.userId);
      userSockets.delete(socket.id);

      // Clean up typing indicators
      await query(
        'DELETE FROM typing_indicators WHERE user_id = $1',
        [socket.userId]
      );

      // Emit offline status to contacts
      socket.broadcast.emit('user_offline', {
        userId: socket.userId,
        name: socket.user.name
      });
    });
  });

  // Clean up typing indicators periodically
  setInterval(async () => {
    try {
      await query('SELECT cleanup_typing_indicators()');
    } catch (error) {
      console.error('Error cleaning up typing indicators:', error);
    }
  }, 30000); // Every 30 seconds
};

// Helper function to mark messages as read
async function markMessagesAsRead(conversationId, userId) {
  try {
    await query(
      `INSERT INTO message_read_receipts (message_id, user_id)
       SELECT m.id, $2
       FROM messages m
       WHERE m.conversation_id = $1 
         AND m.sender_id != $2
         AND NOT EXISTS (
           SELECT 1 FROM message_read_receipts mrr 
           WHERE mrr.message_id = m.id AND mrr.user_id = $2
         )`,
      [conversationId, userId]
    );
  } catch (error) {
    console.error('Error marking messages as read:', error);
  }
}

// Helper function to send push notifications (implement as needed)
async function sendPushNotificationToOfflineUsers(conversationId, senderId, messageData) {
  try {
    // Get all participants except sender
    const participantsResult = await query(
      `SELECT cp.user_id, u.name, u.email
       FROM conversation_participants cp
       JOIN users u ON cp.user_id = u.id
       WHERE cp.conversation_id = $1 AND cp.user_id != $2 AND cp.left_at IS NULL`,
      [conversationId, senderId]
    );

    for (const participant of participantsResult.rows) {
      // Check if user is online
      if (!connectedUsers.has(participant.user_id)) {
        // User is offline, send push notification
        // Implement your push notification service here
        console.log(`Would send push notification to ${participant.name} for new message`);
      }
    }
  } catch (error) {
    console.error('Error sending push notifications:', error);
  }
}

// Export helper functions for use in routes
export const getConnectedUsers = () => connectedUsers;
export const getUserSockets = () => userSockets;
export const isUserOnline = (userId) => connectedUsers.has(userId);