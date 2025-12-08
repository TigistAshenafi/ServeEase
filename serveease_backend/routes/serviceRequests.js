import express from 'express';
import { body, param } from 'express-validator';
import {
  createServiceRequest,
  getServiceRequests,
  assignEmployee,
  updateServiceRequestStatus,
  addRatingAndReview
} from '../controllers/serviceRequestController.js';
import { authenticateToken, requireSeekerOrProvider, requireProvider } from '../middleware/auth.js';

const router = express.Router();

// Validation rules
const createRequestValidation = [
  body('serviceId')
    .isUUID()
    .withMessage('Valid service ID is required'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be less than 500 characters')
];

const updateStatusValidation = [
  param('requestId')
    .isUUID()
    .withMessage('Valid request ID is required'),
  body('status')
    .isIn(['pending', 'accepted', 'assigned', 'in_progress', 'completed', 'cancelled'])
    .withMessage('Invalid status'),
  body('scheduledDate')
    .optional()
    .isISO8601()
    .withMessage('Invalid scheduled date format'),
  body('completionDate')
    .optional()
    .isISO8601()
    .withMessage('Invalid completion date format'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be less than 500 characters')
];

const assignEmployeeValidation = [
  param('requestId')
    .isUUID()
    .withMessage('Valid request ID is required'),
  body('employeeId')
    .isUUID()
    .withMessage('Valid employee ID is required')
];

const ratingValidation = [
  param('requestId')
    .isUUID()
    .withMessage('Valid request ID is required'),
  body('rating')
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5'),
  body('review')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Review must be less than 500 characters')
];

// Routes
router.post('/', authenticateToken, createRequestValidation, createServiceRequest);
router.get('/', authenticateToken, getServiceRequests);
router.put('/:requestId/assign-employee', authenticateToken, requireProvider, assignEmployeeValidation, assignEmployee);
router.put('/:requestId/status', authenticateToken, requireSeekerOrProvider, updateStatusValidation, updateServiceRequestStatus);
router.post('/:requestId/rating', authenticateToken, requireSeekerOrProvider, ratingValidation, addRatingAndReview);

export default router;
