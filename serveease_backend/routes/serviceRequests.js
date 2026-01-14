import express from 'express';
import { body, param } from 'express-validator';
import {
    acceptServiceRequest,
    addRatingAndReview,
    assignEmployee,
    cancelServiceRequest,
    completeServiceRequest,
    createServiceRequest,
    getServiceRequestDetails,
    getServiceRequests,
    rejectServiceRequest,
    startServiceRequest,
    updateServiceRequestStatus
} from '../controllers/serviceRequestController.js';
import { authenticateToken, requireProvider, requireSeekerOrProvider } from '../middleware/auth.js';

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

const acceptRejectValidation = [
  param('requestId')
    .isUUID()
    .withMessage('Valid request ID is required'),
  body('scheduledDate')
    .optional()
    .isISO8601()
    .withMessage('Invalid scheduled date format'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be less than 500 characters'),
  body('reason')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Reason must be less than 500 characters')
];

const startCompleteValidation = [
  param('requestId')
    .isUUID()
    .withMessage('Valid request ID is required'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be less than 500 characters'),
  body('completionDate')
    .optional()
    .isISO8601()
    .withMessage('Invalid completion date format')
];

const cancelValidation = [
  param('requestId')
    .isUUID()
    .withMessage('Valid request ID is required'),
  body('reason')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Reason must be less than 500 characters')
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
router.get('/:requestId', authenticateToken, getServiceRequestDetails);

// Provider actions
router.put('/:requestId/accept', authenticateToken, requireProvider, acceptRejectValidation, acceptServiceRequest);
router.put('/:requestId/reject', authenticateToken, requireProvider, acceptRejectValidation, rejectServiceRequest);
router.put('/:requestId/start', authenticateToken, requireProvider, startCompleteValidation, startServiceRequest);
router.put('/:requestId/complete', authenticateToken, requireProvider, startCompleteValidation, completeServiceRequest);

// Both seeker and provider actions
router.put('/:requestId/cancel', authenticateToken, requireSeekerOrProvider, cancelValidation, cancelServiceRequest);

// Organization actions
router.put('/:requestId/assign-employee', authenticateToken, requireProvider, assignEmployeeValidation, assignEmployee);

// General status update (fallback)
router.put('/:requestId/status', authenticateToken, requireSeekerOrProvider, updateStatusValidation, updateServiceRequestStatus);

// Rating and review
router.post('/:requestId/rating', authenticateToken, requireSeekerOrProvider, ratingValidation, addRatingAndReview);

export default router;
