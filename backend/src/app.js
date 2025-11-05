import express from 'express';
import cookieParser from 'cookie-parser';
import cors from 'cors';
import dotenv from 'dotenv';
import helmet from 'helmet';
import morgan from 'morgan';
import authRoutes from './routes/authRoutes.js';

dotenv.config({ path: './env' });
const app = express();

// MIDDLEWARE
app.use(helmet()); // Adds security headers
app.use(morgan('dev')); // Logs HTTP requests
app.use(cors());
app.use(express.json({ strict: false }));
app.use(cookieParser());

// ROUTES
app.use('/api/auth', authRoutes);

// START SERVER
const PORT = process.env.PORT || 5000; // default fallback
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
