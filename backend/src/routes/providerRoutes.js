import express from "express";
import { registerProvider, getMyProviderStatus } from "../controllers/providerController.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";

const router = express.Router();

router.post("/register", authMiddleware, registerProvider);
router.get("/status", authMiddleware, getMyProviderStatus);

export default router;
