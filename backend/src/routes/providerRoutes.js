import express from 'express';
import { 
  createProviderProfile, 
  getProviderProfile, 
  getAllProviders, 
  updateProviderStatus 
} from '../controllers/providerController.js';

import authMiddleware from '../middlewares/authMiddleware.js';
import adminMiddleware from '../middlewares/adminMiddleware.js';

const router = express.Router();

router.post('/', authMiddleware, createProviderProfile);
router.get('/profile', authMiddleware, getProviderProfile);

// Admin only routes
router.get('/', authMiddleware, adminMiddleware, getAllProviders);
router.patch('/:id/status', authMiddleware, adminMiddleware, updateProviderStatus);

export default router;
