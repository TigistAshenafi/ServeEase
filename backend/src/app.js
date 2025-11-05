import express from 'express';
import cookieParser from 'cookie-parser';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/authRoutes.js';

dotenv.config({path: './env'});
const app = express();

app.use(cors());
app.use(express.json({ strict: false}));
app.use(cookieParser());

//ROUTES
app.use('/api/auth', authRoutes);

const PORT = process.env.PORT;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
