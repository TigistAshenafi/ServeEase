import express from 'express';
import { body, param } from 'express-validator';
import {
  getEmployees,
  addEmployee,
  updateEmployee,
  removeEmployee,
  getAvailableEmployees
} from '../controllers/employeeController.js';
import { authenticateToken, requireProvider } from '../middleware/auth.js';

const router = express.Router();

// Validation rules
const addEmployeeValidation = [
  body('employeeName')
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage('Employee name must be between 2 and 255 characters'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('role')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Role must be between 2 and 100 characters'),
  body('phone')
    .optional()
    .matches(/^[\+]?[1-9][\d]{0,15}$/)
    .withMessage('Please provide a valid phone number'),
  body('hireDate')
    .optional()
    .isISO8601()
    .withMessage('Invalid hire date format')
];

const updateEmployeeValidation = [
  param('employeeId')
    .isUUID()
    .withMessage('Valid employee ID is required'),
  body('employeeName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage('Employee name must be between 2 and 255 characters'),
  body('email')
    .optional()
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('role')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Role must be between 2 and 100 characters'),
  body('phone')
    .optional()
    .matches(/^[\+]?[1-9][\d]{0,15}$/)
    .withMessage('Please provide a valid phone number'),
  body('hireDate')
    .optional()
    .isISO8601()
    .withMessage('Invalid hire date format'),
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('isActive must be a boolean')
];

// Routes
router.get('/', authenticateToken, requireProvider, getEmployees);
router.post('/', authenticateToken, requireProvider, addEmployeeValidation, addEmployee);
router.put('/:employeeId', authenticateToken, requireProvider, updateEmployeeValidation, updateEmployee);
router.delete('/:employeeId', authenticateToken, requireProvider, removeEmployee);
router.get('/available/:serviceId', authenticateToken, requireProvider, getAvailableEmployees);

export default router;
