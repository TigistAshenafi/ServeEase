import express from 'express';
import { body, param, query } from 'express-validator';
import {
  getAllUsers,
  suspendUser,
  activateUser,
  deleteUser,
  getAllServices,
  approveService,
  rejectService,
  deleteService,
  getDashboardStats,
  getActivityLogs,
  getUserStats,
  getServiceStats
} from '../controllers/adminController.js';
import {
  authenticateToken,
  requireAdmin
} from '../middleware/auth.js';

const router = express.Router();

// All admin routes require authentication and admin role
router.use(authenticateToken, requireAdmin);

// User management routes
router.get('/users', getAllUsers);
router.put('/users/:userId/suspend', 
  param('userId').isUUID().withMessage('Valid user ID is required'),
  body('reason').optional().trim().isLength({ min: 1, max: 500 }).withMessage('Reason must be between 1 and 500 characters'),
  suspendUser
);
router.put('/users/:userId/activate', 
  param('userId').isUUID().withMessage('Valid user ID is required'),
  activateUser
);
router.delete('/users/:userId', 
  param('userId').isUUID().withMessage('Valid user ID is required'),
  deleteUser
);

// Service management routes
router.get('/services', getAllServices);
router.put('/services/:serviceId/approve', 
  param('serviceId').isUUID().withMessage('Valid service ID is required'),
  approveService
);
router.put('/services/:serviceId/reject', 
  param('serviceId').isUUID().withMessage('Valid service ID is required'),
  body('reason').optional().trim().isLength({ min: 1, max: 500 }).withMessage('Reason must be between 1 and 500 characters'),
  rejectService
);
router.delete('/services/:serviceId', 
  param('serviceId').isUUID().withMessage('Valid service ID is required'),
  deleteService
);

// Reports and analytics routes
router.get('/reports/dashboard', getDashboardStats);
router.get('/reports/activity', getActivityLogs);
router.get('/reports/users', 
  query('period').optional().isIn(['7d', '30d', '90d', '1y']).withMessage('Invalid period'),
  getUserStats
);
router.get('/reports/services', 
  query('period').optional().isIn(['7d', '30d', '90d', '1y']).withMessage('Invalid period'),
  getServiceStats
);

export default router;