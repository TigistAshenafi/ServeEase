import jwt from 'jsonwebtoken';
import { query } from '../config/database.js';
import * as tokenService from '../services/tokenService.js';

// Middleware to verify JWT token
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access token is required'
      });
    }

    let decoded;
    try {
      decoded = tokenService.verifyAccessToken(token);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ success: false, message: 'Token expired' });
      }
      return res.status(401).json({ success: false, message: 'Invalid token' });
    }

    const { userId } = decoded;

    // Get user from database
    const result = await query(
      'SELECT id, name, email, role, email_verified FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    // Attach user to request object
    req.user = result.rows[0];
    next();

  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token'
      });
    }

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired'
      });
    }

    console.error('Authentication error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Middleware to check if user has specific role
const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    next();
  };
};

// Middleware to check if user is admin
const requireAdmin = authorizeRoles('admin');

// Middleware to check if user is provider
const requireProvider = authorizeRoles('provider', 'admin');

// Middleware to check if user is seeker or provider
const requireSeekerOrProvider = authorizeRoles('seeker', 'provider', 'admin');

export {
  authenticateToken,
  authorizeRoles,
  requireAdmin,
  requireProvider,
  requireSeekerOrProvider
};
