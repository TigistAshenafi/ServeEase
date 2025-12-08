import express from 'express';
import { body } from 'express-validator';
import {
  createOrUpdateProfile,
  getProfile,
  getAllProviders,
  approveProvider,
  rejectProvider
} from '../controllers/providerController.js';
import {
  authenticateToken,
  requireProvider,
  requireAdmin
} from '../middleware/auth.js';

const router = express.Router();

// Validation rules
const profileValidation = [
  body('businessName')
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage('Business name must be between 2 and 255 characters'),
  body('description')
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('Description must be between 10 and 1000 characters'),
  body('category')
    .trim()
    .notEmpty()
    .withMessage('Category is required'),
  body('location')
    .trim()
    .notEmpty()
    .withMessage('Location is required'),
  body('phone')
    .trim()
    .matches(/^[\+]?[1-9][\d]{0,15}$/)
    .withMessage('Please provide a valid phone number')
];

// Provider routes
router.post('/profile', authenticateToken, requireProvider, profileValidation, createOrUpdateProfile);
router.get('/profile', authenticateToken, requireProvider, getProfile);

// Admin routes
router.get('/admin/providers', authenticateToken, requireAdmin, getAllProviders);
router.put('/admin/providers/:providerId/approve', authenticateToken, requireAdmin, approveProvider);
router.put('/admin/providers/:providerId/reject', authenticateToken, requireAdmin, rejectProvider);

export default router;
