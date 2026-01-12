import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { i18nMiddleware } from './middleware/i18n.js';
import authRoutes from './routes/auth.js';
import providerRoutes from './routes/provider.js';
import serviceRoutes from './routes/services.js';
import serviceRequestRoutes from './routes/serviceRequests.js';
import employeeRoutes from './routes/employees.js';
import aiRoutes from './routes/ai.js';
// Load environment variables
dotenv.config();

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Add i18n middleware
app.use(i18nMiddleware);

// Initialize Socket.IO
initializeSocket(io);

// Make io available to routes
app.set('io', io);

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/provider', providerRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/service-requests', serviceRequestRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/chat', chatRoutes);

// Basic route
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to ServeEase API',
    version: '1.0.0',
    features: ['REST API', 'Real-time Chat', 'File Upload']
  });
});

// Health check route
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Start server
server.listen(PORT, () => {
  console.log(`ServeEase API server running on port ${PORT}`);
  console.log(`Socket.IO server initialized`);
});

export default app;