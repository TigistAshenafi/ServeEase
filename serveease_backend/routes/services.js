import express from 'express';
import { body, param } from 'express-validator';
import {
    createService,
    deleteService,
    getAllServices,
    getProviderServices,
    getServiceCategories,
    getServiceDetails,
    getServicesByCategory,
    updateService
} from '../controllers/serviceController.js';
import { authenticateToken, requireProvider } from '../middleware/auth.js';

const router = express.Router();

// Validation rules
const createServiceValidation = [
  body('title')
    .trim()
    .isLength({ min: 3, max: 255 })
    .withMessage('Title must be between 3 and 255 characters'),
  body('description')
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('Description must be between 10 and 1000 characters'),
  body('categoryId')
    .isUUID()
    .withMessage('Valid category ID is required'),
  body('price')
    .isFloat({ min: 0 })
    .withMessage('Price must be a positive number'),
  body('durationHours')
    .isInt({ min: 1, max: 24 })
    .withMessage('Duration must be between 1 and 24 hours')
];

const updateServiceValidation = [
  param('serviceId')
    .isUUID()
    .withMessage('Valid service ID is required'),
  body('title')
    .optional()
    .trim()
    .isLength({ min: 3, max: 255 })
    .withMessage('Title must be between 3 and 255 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('Description must be between 10 and 1000 characters'),
  body('categoryId')
    .optional()
    .isUUID()
    .withMessage('Valid category ID is required'),
  body('price')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Price must be a positive number'),
  body('durationHours')
    .optional()
    .isInt({ min: 1, max: 24 })
    .withMessage('Duration must be between 1 and 24 hours'),
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('isActive must be a boolean')
];

// Public routes (no authentication required for browsing)
router.get('/categories', getServiceCategories);
router.get('/all', getAllServices);
router.get('/details/:serviceId', getServiceDetails);
router.get('/category/:categoryId', getServicesByCategory);

// Provider routes (require authentication)
router.get('/', authenticateToken, getProviderServices);
router.post('/', authenticateToken, requireProvider, createServiceValidation, createService);
router.put('/:serviceId', authenticateToken, requireProvider, updateServiceValidation, updateService);
router.delete('/:serviceId', authenticateToken, requireProvider, deleteService);

export default router;
