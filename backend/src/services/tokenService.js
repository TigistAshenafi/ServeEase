import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import crypto from 'crypto';

export const signAccessToken = (payload) => {
  if (!process.env.JWT_ACCESS_TOKEN_SECRET) {
    throw new Error('JWT_ACCESS_TOKEN_SECRET is not defined');
  }
  return jwt.sign(payload, process.env.JWT_ACCESS_TOKEN_SECRET, { 
    expiresIn: '15m',
    issuer: 'serve-ease',
    audience: 'serve-ease-users'
  });
};

export const signRefreshToken = (payload) => {
  if (!process.env.JWT_REFRESH_TOKEN_SECRET) {
    throw new Error('JWT_REFRESH_TOKEN_SECRET is not defined');
  }
  return jwt.sign(payload, process.env.JWT_REFRESH_TOKEN_SECRET, { 
    expiresIn: '7d',
    issuer: 'serve-ease',
    audience: 'serve-ease-users'
  });
};

export const verifyAccessToken = (token) => {
  return jwt.verify(token, process.env.JWT_ACCESS_TOKEN_SECRET);
};

export const verifyRefreshToken = (token) => {
  return jwt.verify(token, process.env.JWT_REFRESH_TOKEN_SECRET);
};

// Use crypto for token hashing instead of bcrypt for performance
export const hashToken = (token) => {
  return crypto.createHash('sha256').update(token).digest('hex');
};

export const compareTokenHash = (token, hash) => {
  const hashedToken = crypto.createHash('sha256').update(token).digest('hex');
  return crypto.timingSafeEqual(Buffer.from(hashedToken), Buffer.from(hash));
};