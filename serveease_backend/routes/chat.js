import express from 'express';
import { body, param, query as queryValidator } from 'express-validator';
import multer from 'multer';
import path from 'path';
import {
    archiveConversation,
    blockConversation,
    createConversation,
    deleteMessage,
    editMessage,
    getConversation,
    getConversationParticipants,
    getConversations,
    getMessages,
    markMessagesAsRead,
    sendMessage,
    uploadChatFile
} from '../controllers/chatController.js';
import {
    authenticateToken
} from '../middleware/auth.js';

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/chat/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Allow images, documents, and audio files
    const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx|txt|mp3|wav|m4a/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Invalid file type'));
    }
  }
});

// All chat routes require authentication
router.use(authenticateToken);

// Add debugging middleware
router.use((req, res, next) => {
  console.log(`Chat Route: ${req.method} ${req.path}`);
  console.log('Chat Route Body:', req.body);
  console.log('Chat Route User:', req.user?.id);
  next();
});

// Conversation routes
router.get('/conversations', getConversations);
router.get('/conversations/:conversationId', 
  param('conversationId').isUUID().withMessage('Valid conversation ID is required'),
  getConversation
);
router.post('/conversations',
  body('serviceRequestId').optional().isUUID().withMessage('Valid service request ID is required'),
  body('participantId').optional().isUUID().withMessage('Valid participant ID is required'),
  body().custom((value) => {
    if (!value.serviceRequestId && !value.participantId) {
      throw new Error('Either serviceRequestId or participantId is required');
    }
    return true;
  }),
  createConversation
);

// Message routes
router.get('/conversations/:conversationId/messages',
  param('conversationId').isUUID().withMessage('Valid conversation ID is required'),
  queryValidator('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  queryValidator('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  getMessages
);

router.post('/conversations/:conversationId/messages',
  param('conversationId').isUUID().withMessage('Valid conversation ID is required'),
  body('content').trim().isLength({ min: 1, max: 2000 }).withMessage('Message content is required and must be less than 2000 characters'),
  body('messageType').optional().isIn(['text', 'image', 'file', 'location']).withMessage('Invalid message type'),
  body('replyToMessageId').optional().isUUID().withMessage('Valid reply message ID is required'),
  sendMessage
);

router.put('/messages/:messageId',
  param('messageId').isUUID().withMessage('Valid message ID is required'),
  body('content').trim().isLength({ min: 1, max: 2000 }).withMessage('Message content is required and must be less than 2000 characters'),
  editMessage
);

router.delete('/messages/:messageId',
  param('messageId').isUUID().withMessage('Valid message ID is required'),
  deleteMessage
);

// File upload route
router.post('/upload',
  upload.single('file'),
  uploadChatFile
);

// Message read receipts
router.post('/conversations/:conversationId/read',
  param('conversationId').isUUID().withMessage('Valid conversation ID is required'),
  body('messageIds').optional().isArray().withMessage('Message IDs must be an array'),
  markMessagesAsRead
);

// Conversation management
router.get('/conversations/:conversationId/participants',
  param('conversationId').isUUID().withMessage('Valid conversation ID is required'),
  getConversationParticipants
);

router.put('/conversations/:conversationId/archive',
  param('conversationId').isUUID().withMessage('Valid conversation ID is required'),
  archiveConversation
);

router.put('/conversations/:conversationId/block',
  param('conversationId').isUUID().withMessage('Valid conversation ID is required'),
  blockConversation
);

export default router;