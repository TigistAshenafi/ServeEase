import pool from '../config/db.js';
import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import crypto from 'crypto';
import {
  signAccessToken,
  signRefreshToken,
  hashToken,
  verifyRefreshToken,
  compareTokenHash
} from '../services/tokenService.js';
import { sendPasswordResetEmail, sendVerificationEmail } from '../services/mailService.js';
import dotenv from 'dotenv';
dotenv.config();

const COOKIE_NAME = 'refreshToken';

// secure 6-digit OTP
function generateVerificationCode() {
  return crypto.randomInt(100000, 1000000).toString();
}

// helper to set refresh cookie
function setRefreshCookie(res, token, expiresInDays = 7) {
  const maxAge = 1000 * 60 * 60 * 24 * parseInt(process.env.REFRESH_TOKEN_EXPIRES_IN_DAYS || expiresInDays);
  res.cookie(COOKIE_NAME, token, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    maxAge,
    domain: process.env.COOKIE_DOMAIN || undefined
  });
}

// ===== REGISTER =====
export const register = async (req, res, next) => {
  let client;
  try {
    const { name, email, password, role } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required' });
    }

    // no providerProfile validation here — provider fills profile after verification
    // check if email exists
    const { rows } = await pool.query('SELECT id FROM users WHERE email=$1', [email]);
    if (rows.length) return res.status(409).json({ message: 'Email already used' });

    const storedRole = role || 'seeker'; // respect user's chosen role
    const userId = uuidv4();
    const password_hash = await bcrypt.hash(password, 10);
    const code = generateVerificationCode();
    const expires = new Date(Date.now() + 1000 * 60 * 60 * 24); // 24h

    client = await pool.connect();
    await client.query('BEGIN');

    // insert user (is_verified defaults to false)
    const userRes = await client.query(
      'INSERT INTO users(id, name, email, password_hash, role) VALUES($1,$2,$3,$4,$5) RETURNING id,email,role',
      [userId, name, email, password_hash, storedRole]
    );
    const user = userRes.rows[0];

    // insert email verification
    await client.query(
      'INSERT INTO email_verifications(user_id, code, expires_at) VALUES($1,$2,$3)',
      [user.id, code, expires]
    );

    await client.query('COMMIT');

    // send verification email (async)
    await sendVerificationEmail(user.email, code);

    // Return userId and role to frontend so it can drive next step
    res.status(201).json({
      message: 'Verification code sent',
      userId: user.id,
      role: user.role
    });
  } catch (err) {
    if (client) {
      try { await client.query('ROLLBACK'); } catch (_) {}
      client.release();
      client = null;
    }
    next(err);
  } finally {
    if (client) client.release();
  }
};

// ===== VERIFY EMAIL =====
export const verifyEmail = async (req, res, next) => {
  try {
    const { email, code } = req.body;
    if (!email || !code)
      return res.status(400).json({ message: 'Missing email or code' });

    const userRes = await pool.query(
      'SELECT id, role, password_hash FROM users WHERE email=$1',
      [email]
    );
    if (!userRes.rows.length)
      return res.status(404).json({ message: 'User not found' });
    const user = userRes.rows[0];

    const evRes = await pool.query(
      'SELECT * FROM email_verifications WHERE user_id=$1 AND code=$2 AND expires_at > now()',
      [user.id, code]
    );
    if (!evRes.rows.length)
      return res.status(400).json({ message: 'Invalid or expired code' });

    // mark verified
    await pool.query('UPDATE users SET is_verified=true WHERE id=$1', [user.id]);
    await pool.query('DELETE FROM email_verifications WHERE id=$1', [evRes.rows[0].id]);

    // generate token for provider immediately
    let accessToken = null;
    if (user.role === 'provider') {
      const payload = { userId: user.id, role: user.role };
      accessToken = signAccessToken(payload);
    }

    res.json({
      message: 'Email verified',
      userId: user.id,
      role: user.role,
      accessToken, // <-- send token to frontend
    });
  } catch (err) {
    next(err);
  }
};


// ===== LOGIN =====
export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ message: 'Missing email or password' });

    const userRes = await pool.query('SELECT id, password_hash, is_verified, name, role FROM users WHERE email=$1', [email]);
    if (!userRes.rows.length) return res.status(401).json({ message: 'Invalid credentials' });

    const user = userRes.rows[0];
    if (!(await bcrypt.compare(password, user.password_hash))) return res.status(401).json({ message: 'Invalid credentials' });
    if (!user.is_verified) return res.status(403).json({ message: 'Email not verified' });

    const providerRes = await pool.query('SELECT id, status FROM providers WHERE user_id=$1', [user.id]);
    const providerStatus = providerRes.rows.length ? providerRes.rows[0].status : null;

    const payload = { userId: user.id, role: user.role };
    const accessToken = signAccessToken(payload);
    const refreshToken = signRefreshToken(payload);

    // store hashed refresh token
    const tokenHash = await hashToken(refreshToken);
    const expires_at = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7d
    await pool.query(
      'INSERT INTO refresh_tokens(id, user_id, token_hash, expires_at, user_agent, ip) VALUES($1,$2,$3,$4,$5,$6)',
      [uuidv4(), user.id, tokenHash, expires_at, req.headers['user-agent'] || null, req.ip]
    );

    setRefreshCookie(res, refreshToken);

    res.json({ accessToken, user: { id: user.id, name: user.name, role: user.role, providerStatus } });
  } catch (err) {
    next(err);
  }
};

// ===== REFRESH TOKEN =====
export const refreshToken = async (req, res, next) => {
  try {
    const token = req.cookies[COOKIE_NAME];
    if (!token) return res.status(401).json({ message: 'No token' });
    const payload = verifyRefreshToken(token);

    const rows = (await pool.query(
      'SELECT id, token_hash, user_id, expires_at FROM refresh_tokens WHERE user_id=$1 AND expires_at > now()',
      [payload.userId]
    )).rows;

    if (!rows.length) return res.status(401).json({ message: 'Invalid token' });

    let matchRow = null;
    for (const r of rows) {
      if (await compareTokenHash(token, r.token_hash)) {
        matchRow = r;
        break;
      }
    }
    if (!matchRow) return res.status(401).json({ message: 'Invalid token' });

    const accessToken = signAccessToken({ userId: payload.userId, role: payload.role });
    res.json({ accessToken });
  } catch (err) {
    next(err);
  }
};

// ===== LOGOUT =====
export const logout = async (req, res, next) => {
  try {
    const token = req.cookies[COOKIE_NAME];
    if (token) {
      try {
        const payload = verifyRefreshToken(token);
        await pool.query('DELETE FROM refresh_tokens WHERE user_id=$1', [payload.userId]);
      } catch {}
    }
    res.clearCookie(COOKIE_NAME, { httpOnly: true, sameSite: 'lax', secure: process.env.NODE_ENV === 'production' });
    res.json({ message: 'Logged out' });
  } catch (err) {
    next(err);
  }
};

// ===== PASSWORD RESET =====
export const requestPasswordReset = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Missing email' });

    const userRes = await pool.query('SELECT id FROM users WHERE email=$1', [email]);
    if (!userRes.rows.length) {
      return res.status(200).json({ message: 'If account exists we sent instructions' });
    }

    const userId = userRes.rows[0].id;
    const resetCode = generateVerificationCode();
    const codeHash = await hashToken(resetCode);
    const expires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    await pool.query(
      'INSERT INTO password_resets(id, user_id, token_hash, expires_at) VALUES($1,$2,$3,$4)',
      [uuidv4(), userId, codeHash, expires]
    );

    await sendPasswordResetEmail(email, resetCode);
    res.status(200).json({ message: 'The reset code is sent.' });
  } catch (err) {
    next(err);
  }
};

export const resetPassword = async (req, res, next) => {
  try {
    const { email, code, newPassword } = req.body;
    if (!email || !code || !newPassword) return res.status(400).json({ message: 'Missing fields' });

    const userRes = await pool.query('SELECT id FROM users WHERE email=$1', [email]);
    if (!userRes.rows.length) return res.status(400).json({ message: 'Invalid request' });

    const userId = userRes.rows[0].id;
    const rows = (await pool.query('SELECT id, token_hash FROM password_resets WHERE user_id=$1 AND expires_at > now()', [userId])).rows;
    if (!rows.length) return res.status(400).json({ message: 'Invalid or expired code' });

    let matched = null;
    for (const r of rows) {
      if (await compareTokenHash(code, r.token_hash)) {
        matched = r;
        break;
      }
    }
    if (!matched) return res.status(400).json({ message: 'Invalid code' });

    const newHash = await bcrypt.hash(newPassword, 10);
    await pool.query('UPDATE users SET password_hash=$1 WHERE id=$2', [newHash, userId]);
    await pool.query('DELETE FROM password_resets WHERE id=$1', [matched.id]);
    await pool.query('DELETE FROM refresh_tokens WHERE user_id=$1', [userId]); // invalidate active sessions

    res.json({ message: 'Password changed successfully' });
  } catch (err) {
    next(err);
  }
};
