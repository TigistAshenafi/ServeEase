import express from "express";
import {
  createService,
  getMyServices,
  deleteService,
} from "../controllers/serviceController.js";
import authMiddleware from "../middlewares/authMiddleware.js";

const router = express.Router();

router.post("/", authMiddleware, createService);
router.get("/", authMiddleware, getMyServices);
router.delete("/:id", authMiddleware, deleteService);

export default router;
