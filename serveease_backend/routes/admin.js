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
  getServiceStats,
  getAllDocuments,
  deleteDocument,
  getAppSettings,
  updateAppSetting,
  getAdminPreferences,
  updateAdminPreferences,
  updateAdminProfile,
  changeAdminPassword,
  getSystemInfo
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

// Document management routes
router.get('/documents', getAllDocuments);
router.delete('/documents/:documentId', 
  param('documentId').notEmpty().withMessage('Valid document ID is required'),
  deleteDocument
);

// Settings management routes
router.get('/settings', getAppSettings);
router.put('/settings/:key', 
  param('key').notEmpty().withMessage('Setting key is required'),
  body('value').notEmpty().withMessage('Setting value is required'),
  updateAppSetting
);

// Admin preferences routes
router.get('/preferences', getAdminPreferences);
router.put('/preferences', 
  body('preferences').isObject().withMessage('Preferences must be an object'),
  updateAdminPreferences
);

// Admin profile routes
router.put('/profile', 
  body('name').optional().trim().isLength({ min: 1, max: 255 }).withMessage('Name must be between 1 and 255 characters'),
  body('email').optional().isEmail().withMessage('Valid email is required'),
  updateAdminProfile
);

router.put('/password', 
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters'),
  changeAdminPassword
);

// System information route
router.get('/system', getSystemInfo);

export default router;