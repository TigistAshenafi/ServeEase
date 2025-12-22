import express from 'express';
import { body } from 'express-validator';
import {
  register,
  verifyEmail,
  login,
  sendPasswordResetCode,
  resetPassword,
  refreshTokenHandler,
  logout,
  getProfile,
  resendVerificationCode
} from '../controllers/authController.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// Validation rules
const registerValidation = [
  body('name')
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage('Name must be between 2 and 255 characters'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('role')
    .isIn(['seeker', 'provider'])
    .withMessage('Role must be either seeker or provider')
];

const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
];

// Routes
router.post('/register', registerValidation, register);
router.get('/verify-email', verifyEmail);
router.post('/login', loginValidation, login);
router.post('/forgot-password', sendPasswordResetCode);
router.post('/reset-password', resetPassword);
router.post('/refresh-token', refreshTokenHandler);
router.post('/logout', authenticateToken, logout);
router.get('/profile', authenticateToken, getProfile);
router.post('/resend-verification-code', resendVerificationCode);

export default router;
