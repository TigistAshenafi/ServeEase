import { validationResult } from 'express-validator';
import fs from 'fs';
import path from 'path';
import { query } from '../config/database.js';

// Get user's conversations
export const getConversations = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const result = await query(
      `SELECT 
        c.*,
        sr.id as service_request_id,
        s.title as service_title,
        seeker.name as seeker_name,
        seeker.email as seeker_email,
        provider.name as provider_name,
        provider.email as provider_email,
        last_msg.content as last_message_content,
        last_msg.message_type as last_message_type,
        last_msg.created_at as last_message_time,
        last_msg.sender_id as last_message_sender_id,
        sender.name as last_message_sender_name,
        (SELECT COUNT(*) FROM messages m 
         WHERE m.conversation_id = c.id 
         AND m.sender_id != $1 
         AND NOT EXISTS (
           SELECT 1 FROM message_read_receipts mrr 
           WHERE mrr.message_id = m.id AND mrr.user_id = $1
         )) as unread_count
       FROM conversations c
       LEFT JOIN service_requests sr ON c.service_request_id = sr.id
       LEFT JOIN services s ON sr.service_id = s.id
       LEFT JOIN users seeker ON c.seeker_id = seeker.id
       LEFT JOIN users provider ON c.provider_id = provider.id
       LEFT JOIN messages last_msg ON last_msg.id = (
         SELECT id FROM messages 
         WHERE conversation_id = c.id 
         ORDER BY created_at DESC 
         LIMIT 1
       )
       LEFT JOIN users sender ON last_msg.sender_id = sender.id
       WHERE (c.seeker_id = $1 OR c.provider_id = $1)
       AND c.status = 'active'
       ORDER BY c.last_message_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    // Get total count
    const countResult = await query(
      `SELECT COUNT(*) as total FROM conversations c
       WHERE (c.seeker_id = $1 OR c.provider_id = $1) AND c.status = 'active'`,
      [userId]
    );

    const total = parseInt(countResult.rows[0].total);

    const conversations = result.rows.map(row => ({
      id: row.id,
      serviceRequestId: row.service_request_id,
      serviceTitle: row.service_title,
      status: row.status,
      lastMessageAt: row.last_message_at,
      createdAt: row.created_at,
      participants: {
        seeker: {
          id: row.seeker_id,
          name: row.seeker_name,
          email: row.seeker_email
        },
        provider: {
          id: row.provider_id,
          name: row.provider_name,
          email: row.provider_email
        }
      },
      otherParticipant: userId === row.seeker_id ? {
        id: row.provider_id,
        name: row.provider_name,
        email: row.provider_email,
        role: 'provider'
      } : {
        id: row.seeker_id,
        name: row.seeker_name,
        email: row.seeker_email,
        role: 'seeker'
      },
      lastMessage: row.last_message_content ? {
        content: row.last_message_content,
        messageType: row.last_message_type,
        createdAt: row.last_message_time,
        senderId: row.last_message_sender_id,
        senderName: row.last_message_sender_name,
        isFromMe: row.last_message_sender_id === userId
      } : null,
      unreadCount: parseInt(row.unread_count)
    }));

    res.json({
      success: true,
      conversations,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get specific conversation
export const getConversation = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const userId = req.user.id;
    const { conversationId } = req.params;

    const result = await query(
      `SELECT 
        c.*,
        sr.id as service_request_id,
        s.title as service_title,
        seeker.name as seeker_name,
        seeker.email as seeker_email,
        provider.name as provider_name,
        provider.email as provider_email
       FROM conversations c
       LEFT JOIN service_requests sr ON c.service_request_id = sr.id
       LEFT JOIN services s ON sr.service_id = s.id
       LEFT JOIN users seeker ON c.seeker_id = seeker.id
       LEFT JOIN users provider ON c.provider_id = provider.id
       WHERE c.id = $1 AND (c.seeker_id = $2 OR c.provider_id = $2)`,
      [conversationId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found'
      });
    }

    const row = result.rows[0];
    const conversation = {
      id: row.id,
      serviceRequestId: row.service_request_id,
      serviceTitle: row.service_title,
      status: row.status,
      lastMessageAt: row.last_message_at,
      createdAt: row.created_at,
      participants: {
        seeker: {
          id: row.seeker_id,
          name: row.seeker_name,
          email: row.seeker_email
        },
        provider: {
          id: row.provider_id,
          name: row.provider_name,
          email: row.provider_email
        }
      },
      otherParticipant: userId === row.seeker_id ? {
        id: row.provider_id,
        name: row.provider_name,
        email: row.provider_email,
        role: 'provider'
      } : {
        id: row.seeker_id,
        name: row.seeker_name,
        email: row.seeker_email,
        role: 'seeker'
      }
    };

    res.json({
      success: true,
      conversation
    });

  } catch (error) {
    console.error('Get conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Create new conversation
export const createConversation = async (req, res) => {
  try {
    console.log('Chat: Received createConversation request');
    console.log('Chat: Request body:', req.body);
    console.log('Chat: User ID:', req.user?.id);
    console.log('Chat: Headers:', req.headers);
    
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('Chat: Validation errors:', errors.array());
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const userId = req.user.id;
    const { serviceRequestId, participantId } = req.body;

    // Check if conversation already exists
    let existingConversation = null;
    
    if (serviceRequestId) {
      const existingResult = await query(
        'SELECT * FROM conversations WHERE service_request_id = $1',
        [serviceRequestId]
      );
      existingConversation = existingResult.rows[0];
    } else {
      // For direct conversations without service request
      const existingResult = await query(
        `SELECT * FROM conversations 
         WHERE service_request_id IS NULL 
         AND ((seeker_id = $1 AND provider_id = $2) OR (seeker_id = $2 AND provider_id = $1))`,
        [userId, participantId]
      );
      existingConversation = existingResult.rows[0];
    }

    if (existingConversation) {
      return res.json({
        success: true,
        conversation: { id: existingConversation.id },
        message: 'Conversation already exists'
      });
    }

    // Determine seeker and provider roles
    let seekerId, providerId;
    
    if (serviceRequestId) {
      // Get service request details with provider user ID
      const serviceRequestResult = await query(
        `SELECT sr.seeker_id, pp.user_id as provider_user_id 
         FROM service_requests sr
         JOIN provider_profiles pp ON sr.provider_id = pp.id
         WHERE sr.id = $1`,
        [serviceRequestId]
      );
      
      if (serviceRequestResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Service request not found'
        });
      }
      
      seekerId = serviceRequestResult.rows[0].seeker_id;
      providerId = serviceRequestResult.rows[0].provider_user_id;
      
      console.log('Chat: Service request participants:', { seekerId, providerId, currentUserId: userId });
      
      // Verify user is part of this service request
      if (userId !== seekerId && userId !== providerId) {
        console.log('Chat: User not authorized for this service request');
        return res.status(403).json({
          success: false,
          message: 'Not authorized to create conversation for this service request'
        });
      }
    } else {
      // For direct conversations, determine roles based on user types
      const userResult = await query('SELECT role FROM users WHERE id = $1', [userId]);
      const participantResult = await query('SELECT role FROM users WHERE id = $1', [participantId]);
      
      if (userResult.rows.length === 0 || participantResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }
      
      const userRole = userResult.rows[0].role;
      const participantRole = participantResult.rows[0].role;
      
      if (userRole === 'seeker') {
        seekerId = userId;
        providerId = participantId;
      } else {
        seekerId = participantId;
        providerId = userId;
      }
    }

    // Create conversation
    const conversationResult = await query(
      `INSERT INTO conversations (service_request_id, seeker_id, provider_id)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [serviceRequestId, seekerId, providerId]
    );

    const conversation = conversationResult.rows[0];

    // Add participants
    await query(
      `INSERT INTO conversation_participants (conversation_id, user_id, role)
       VALUES ($1, $2, 'member'), ($1, $3, 'member')`,
      [conversation.id, seekerId, providerId]
    );

    res.status(201).json({
      success: true,
      conversation: {
        id: conversation.id,
        serviceRequestId: conversation.service_request_id,
        status: conversation.status,
        createdAt: conversation.created_at
      },
      message: 'Conversation created successfully'
    });

  } catch (error) {
    console.error('Create conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get messages in a conversation
export const getMessages = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const userId = req.user.id;
    const { conversationId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    // Verify user is participant in this conversation
    const participantCheck = await query(
      `SELECT cp.* FROM conversation_participants cp 
       WHERE cp.conversation_id = $1 AND cp.user_id = $2 AND cp.left_at IS NULL`,
      [conversationId, userId]
    );

    if (participantCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view messages in this conversation'
      });
    }

    const result = await query(
      `SELECT 
        m.*,
        sender.name as sender_name,
        sender.email as sender_email,
        reply_msg.content as reply_content,
        reply_sender.name as reply_sender_name,
        (SELECT COUNT(*) FROM message_read_receipts mrr WHERE mrr.message_id = m.id) as read_count
       FROM messages m
       JOIN users sender ON m.sender_id = sender.id
       LEFT JOIN messages reply_msg ON m.reply_to_message_id = reply_msg.id
       LEFT JOIN users reply_sender ON reply_msg.sender_id = reply_sender.id
       WHERE m.conversation_id = $1
       ORDER BY m.created_at DESC
       LIMIT $2 OFFSET $3`,
      [conversationId, limit, offset]
    );

    // Get total count
    const countResult = await query(
      'SELECT COUNT(*) as total FROM messages WHERE conversation_id = $1',
      [conversationId]
    );

    const total = parseInt(countResult.rows[0].total);

    const messages = result.rows.map(row => ({
      id: row.id,
      conversationId: row.conversation_id,
      senderId: row.sender_id,
      messageType: row.message_type,
      content: row.content,
      fileUrl: row.file_url,
      fileName: row.file_name,
      fileSize: row.file_size,
      isRead: row.is_read,
      isEdited: row.is_edited,
      editedAt: row.edited_at,
      createdAt: row.created_at,
      sender: {
        id: row.sender_id,
        name: row.sender_name,
        email: row.sender_email
      },
      replyTo: row.reply_to_message_id ? {
        id: row.reply_to_message_id,
        content: row.reply_content,
        senderName: row.reply_sender_name
      } : null,
      readCount: parseInt(row.read_count),
      isFromMe: row.sender_id === userId
    }));

    res.json({
      success: true,
      messages: messages.reverse(), // Reverse to show oldest first
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Send message (HTTP endpoint, real-time handled by Socket.IO)
export const sendMessage = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const userId = req.user.id;
    const { conversationId } = req.params;
    const { content, messageType = 'text', replyToMessageId } = req.body;

    // Verify user is participant in this conversation
    const participantCheck = await query(
      `SELECT cp.* FROM conversation_participants cp 
       WHERE cp.conversation_id = $1 AND cp.user_id = $2 AND cp.left_at IS NULL`,
      [conversationId, userId]
    );

    if (participantCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to send messages in this conversation'
      });
    }

    // Insert message
    const messageResult = await query(
      `INSERT INTO messages (conversation_id, sender_id, message_type, content, reply_to_message_id)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [conversationId, userId, messageType, content, replyToMessageId]
    );

    const message = messageResult.rows[0];

    // Get sender info
    const senderResult = await query(
      'SELECT name, email FROM users WHERE id = $1',
      [userId]
    );
    const sender = senderResult.rows[0];

    const messageData = {
      id: message.id,
      conversationId: message.conversation_id,
      senderId: message.sender_id,
      messageType: message.message_type,
      content: message.content,
      createdAt: message.created_at,
      sender: {
        id: userId,
        name: sender.name,
        email: sender.email
      },
      isFromMe: true
    };

    // Emit to Socket.IO if available
    const io = req.app.get('io');
    if (io) {
      io.to(`conversation_${conversationId}`).emit('new_message', messageData);
    }

    res.status(201).json({
      success: true,
      message: messageData
    });

  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Mark messages as read
export const markMessagesAsRead = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const userId = req.user.id;
    const { conversationId } = req.params;
    const { messageIds } = req.body;

    // Verify user is participant in this conversation
    const participantCheck = await query(
      `SELECT cp.* FROM conversation_participants cp 
       WHERE cp.conversation_id = $1 AND cp.user_id = $2 AND cp.left_at IS NULL`,
      [conversationId, userId]
    );

    if (participantCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to mark messages as read in this conversation'
      });
    }

    if (messageIds && messageIds.length > 0) {
      // Mark specific messages as read
      for (const messageId of messageIds) {
        await query(
          `INSERT INTO message_read_receipts (message_id, user_id)
           VALUES ($1, $2)
           ON CONFLICT (message_id, user_id) DO NOTHING`,
          [messageId, userId]
        );
      }
    } else {
      // Mark all unread messages in conversation as read
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
    }

    res.json({
      success: true,
      message: 'Messages marked as read'
    });

  } catch (error) {
    console.error('Mark messages as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Edit message
export const editMessage = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const userId = req.user.id;
    const { messageId } = req.params;
    const { content } = req.body;

    // Verify user owns this message
    const messageResult = await query(
      'SELECT * FROM messages WHERE id = $1 AND sender_id = $2',
      [messageId, userId]
    );

    if (messageResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Message not found or not authorized to edit'
      });
    }

    // Update message
    const updatedResult = await query(
      `UPDATE messages 
       SET content = $1, is_edited = true, edited_at = NOW(), updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [content, messageId]
    );

    const updatedMessage = updatedResult.rows[0];

    // Emit to Socket.IO if available
    const io = req.app.get('io');
    if (io) {
      io.to(`conversation_${updatedMessage.conversation_id}`).emit('message_edited', {
        messageId: updatedMessage.id,
        content: updatedMessage.content,
        editedAt: updatedMessage.edited_at
      });
    }

    res.json({
      success: true,
      message: 'Message updated successfully'
    });

  } catch (error) {
    console.error('Edit message error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Delete message
export const deleteMessage = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const userId = req.user.id;
    const { messageId } = req.params;

    // Verify user owns this message
    const messageResult = await query(
      'SELECT * FROM messages WHERE id = $1 AND sender_id = $2',
      [messageId, userId]
    );

    if (messageResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Message not found or not authorized to delete'
      });
    }

    const message = messageResult.rows[0];

    // Delete associated file if exists
    if (message.file_url) {
      try {
        const filePath = path.join(process.cwd(), message.file_url);
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      } catch (fileError) {
        console.error('Error deleting file:', fileError);
      }
    }

    // Delete message
    await query('DELETE FROM messages WHERE id = $1', [messageId]);

    // Emit to Socket.IO if available
    const io = req.app.get('io');
    if (io) {
      io.to(`conversation_${message.conversation_id}`).emit('message_deleted', {
        messageId: message.id,
        conversationId: message.conversation_id
      });
    }

    res.json({
      success: true,
      message: 'Message deleted successfully'
    });

  } catch (error) {
    console.error('Delete message error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Upload chat file
export const uploadChatFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const fileUrl = `/uploads/chat/${req.file.filename}`;
    const fileInfo = {
      url: fileUrl,
      name: req.file.originalname,
      size: req.file.size,
      type: req.file.mimetype
    };

    res.json({
      success: true,
      file: fileInfo,
      message: 'File uploaded successfully'
    });

  } catch (error) {
    console.error('Upload file error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get conversation participants
export const getConversationParticipants = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const userId = req.user.id;
    const { conversationId } = req.params;

    // Verify user is participant in this conversation
    const participantCheck = await query(
      `SELECT cp.* FROM conversation_participants cp 
       WHERE cp.conversation_id = $1 AND cp.user_id = $2 AND cp.left_at IS NULL`,
      [conversationId, userId]
    );

    if (participantCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view participants in this conversation'
      });
    }

    const result = await query(
      `SELECT cp.*, u.name, u.email, u.role
       FROM conversation_participants cp
       JOIN users u ON cp.user_id = u.id
       WHERE cp.conversation_id = $1 AND cp.left_at IS NULL`,
      [conversationId]
    );

    const participants = result.rows.map(row => ({
      id: row.user_id,
      name: row.name,
      email: row.email,
      role: row.role,
      joinedAt: row.joined_at,
      isMuted: row.is_muted
    }));

    res.json({
      success: true,
      participants
    });

  } catch (error) {
    console.error('Get conversation participants error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Archive conversation
export const archiveConversation = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const userId = req.user.id;
    const { conversationId } = req.params;

    // Verify user is participant in this conversation
    const participantCheck = await query(
      `SELECT cp.* FROM conversation_participants cp 
       WHERE cp.conversation_id = $1 AND cp.user_id = $2 AND cp.left_at IS NULL`,
      [conversationId, userId]
    );

    if (participantCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to archive this conversation'
      });
    }

    await query(
      `UPDATE conversations SET status = 'archived', updated_at = NOW() WHERE id = $1`,
      [conversationId]
    );

    res.json({
      success: true,
      message: 'Conversation archived successfully'
    });

  } catch (error) {
    console.error('Archive conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Block conversation
export const blockConversation = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const userId = req.user.id;
    const { conversationId } = req.params;

    // Verify user is participant in this conversation
    const participantCheck = await query(
      `SELECT cp.* FROM conversation_participants cp 
       WHERE cp.conversation_id = $1 AND cp.user_id = $2 AND cp.left_at IS NULL`,
      [conversationId, userId]
    );

    if (participantCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to block this conversation'
      });
    }

    await query(
      `UPDATE conversations SET status = 'blocked', updated_at = NOW() WHERE id = $1`,
      [conversationId]
    );

    res.json({
      success: true,
      message: 'Conversation blocked successfully'
    });

  } catch (error) {
    console.error('Block conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};