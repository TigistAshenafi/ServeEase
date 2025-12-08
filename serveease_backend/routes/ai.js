import express from 'express';
import { body } from 'express-validator';
import {
  chatWithAI,
  getServiceRecommendations,
  getProviderRecommendations,
  analyzeQuery,
  getPlatformInsights
} from '../controllers/aiController.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// Validation rules
const chatValidation = [
  body('message')
    .trim()
    .isLength({ min: 1, max: 1000 })
    .withMessage('Message must be between 1 and 1000 characters'),
  body('conversationHistory')
    .optional()
    .isArray()
    .withMessage('Conversation history must be an array')
];

const queryValidation = [
  body('query')
    .trim()
    .isLength({ min: 1, max: 500 })
    .withMessage('Query must be between 1 and 500 characters')
];

// Public routes (no authentication required)
router.get('/insights', getPlatformInsights);

// Authenticated routes
router.post('/chat', authenticateToken, chatValidation, chatWithAI);
router.post('/analyze', authenticateToken, queryValidation, analyzeQuery);
router.get('/recommendations/services', authenticateToken, getServiceRecommendations);
router.get('/recommendations/providers', authenticateToken, getProviderRecommendations);

export default router;
