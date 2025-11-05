import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import bcrypt from 'bcrypt';

dotenv.config();

export const signAccessToken = (payload) =>
  jwt.sign(payload, process.env.JWT_ACCESS_TOKEN_SECRET, { expiresIn: '15m' });
console.log('JWT_ACCESS_SECRET:', process.env.JWT_ACCESS_SECRET);

export const signRefreshToken = (payload) =>
  jwt.sign(payload, process.env.JWT_REFRESH_TOKEN_SECRET, { expiresIn: '7d' });

export const verifyRefreshToken = (token) =>
  jwt.verify(token, process.env.JWT_REFRESH_TOKEN_SECRET);

export const hashToken = (token) => bcrypt.hash(token, 10);
export const compareTokenHash = (token, hash) => bcrypt.compare(token, hash);
