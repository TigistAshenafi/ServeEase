import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import aiRoutes from './routes/ai.js';
import authRoutes from './routes/auth.js';
import employeeRoutes from './routes/employees.js';
import providerRoutes from './routes/provider.js';
import serviceRequestRoutes from './routes/serviceRequests.js';
import serviceRoutes from './routes/services.js';
// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/provider', providerRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/service-requests', serviceRequestRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/ai', aiRoutes);

// Basic route
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to ServeEase API',
    version: '1.0.0'
  });
});

// Health check route
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
  console.log(`ServeEase API server running on port ${PORT}`);
});

export default app;