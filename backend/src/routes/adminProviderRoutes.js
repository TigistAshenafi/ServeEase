import express from "express";
import {
  getAllProviders,
  approveProvider,
  rejectProvider,
  suspendProvider,
} from "../controllers/adminProviderController.js";
import authMiddleware from "../middlewares/authMiddleware.js";
import adminMiddleware from '../middlewares/adminMiddleware.js';

const router = express.Router();

router.get("/", authMiddleware, adminMiddleware, getAllProviders);
router.patch("/:id/approve", authMiddleware, adminMiddleware, approveProvider);
router.patch("/:id/reject", authMiddleware, adminMiddleware, rejectProvider);
router.patch("/:id/suspend", authMiddleware, adminMiddleware, suspendProvider);

export default router;
