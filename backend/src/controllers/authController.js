import pool from '../config/db.js';
import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import { signAccessToken, signRefreshToken, hashToken, verifyRefreshToken, compareTokenHash } from '../services/tokenService.js';
import { sendPasswordResetEmail, sendVerificationEmail } from '../services/mailService.js';
import dotenv from 'dotenv';
dotenv.config();

const COOKIE_NAME = 'refreshToken';

function generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit code
}

// helper to set refresh cookie
function setRefreshCookie(res, token, expiresInDays = 7) {
  const maxAge = 1000 * 60 * 60 * 24 * parseInt(process.env.REFRESH_TOKEN_EXPIRES_IN_DAYS || (expiresInDays));
  res.cookie(COOKIE_NAME, token, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    maxAge,
    domain: process.env.COOKIE_DOMAIN || undefined
  });
}

export const register = async (req, res, next) => {
  try {
    const { name, email, password, role } = req.body;
    if (!email || !password) return res.status(400).json({ message: 'Missing fields' });

    // check existing
    const { rows } = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (rows.length) return res.status(409).json({ message: 'Email already used' });

    const userId = uuidv4();
    const password_hash = await bcrypt.hash(password, 10);
    const userRes = await pool.query(
      'INSERT INTO users(id, name, email, password_hash, role) VALUES($1,$2,$3,$4,$5) RETURNING id,email',
      [userId, name || null, email, password_hash, role || 'seeker']
    );
    const user = userRes.rows[0];

    // Create verification code (simple random uuid here)
    const code = generateVerificationCode();
    const expires = new Date(Date.now() + 1000 * 60 * 60 * 24); // 24h
    await pool.query('INSERT INTO email_verifications(user_id, code, expires_at) VALUES($1,$2,$3)', [user.id, code, expires]);

    // send email
    await sendVerificationEmail(user.email, code);

    res.status(201).json({ message: 'Registered. Check email for verification.' });
  } catch (err) { next(err); }
};

export const verifyEmail = async (req, res, next) => {
  try {
    const { email, code } = req.body;
    if (!email || !code) return res.status(400).json({ message: 'Missing' });

    const userRes = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (!userRes.rows.length) return res.status(404).json({ message: 'User not found' });
    const userId = userRes.rows[0].id;

    const ev = await pool.query('SELECT * FROM email_verifications WHERE user_id=$1 AND code=$2 AND expires_at > now()', [userId, code]);
    if (!ev.rows.length) return res.status(400).json({ message: 'Invalid or expired code' });

    await pool.query('UPDATE users SET is_verified=true WHERE id=$1', [userId]);
    await pool.query('DELETE FROM email_verifications WHERE id=$1', [ev.rows[0].id]);

    res.json({ message: 'Email verified' });
  } catch (err) { next(err); }
};

export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ message: 'Missing' });

    const userRes = await pool.query('SELECT id, password_hash, is_verified, name, role FROM users WHERE email=$1', [email]);
    if (!userRes.rows.length) return res.status(401).json({ message: 'Invalid credentials' });

    const user = userRes.rows[0];
    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) return res.status(401).json({ message: 'Invalid credentials' });

    if (!user.is_verified) return res.status(403).json({ message: 'Email not verified' });

    const payload = { userId: user.id, role: user.role };
    const accessToken = signAccessToken(payload);
    const refreshToken = signRefreshToken(payload);

    // store hashed refresh token
    const tokenHash = await hashToken(refreshToken);
    const expires_at = new Date(Date.now() + (7 * 24 * 60 * 60 * 1000)); // 7d
    const refreshTokenId = uuidv4();
    await pool.query('INSERT INTO refresh_tokens(id, user_id, token_hash, expires_at, user_agent, ip) VALUES($1,$2,$3,$4,$5,$6)', 
      [refreshTokenId, user.id, tokenHash, expires_at, req.headers['user-agent'] || null, req.ip]);

    setRefreshCookie(res, refreshToken);

    res.json({ accessToken, user: { id: user.id, name: user.name, role: user.role } });
  } catch (err) { next(err); }
};

export const refreshToken = async (req, res, next) => {
  try {
    const token = req.cookies[COOKIE_NAME];
    if (!token) return res.status(401).json({ message: 'No token' });
    const payload = verifyRefreshToken(token);

    // find hashed token in DB
    const rows = (await pool.query('SELECT id, token_hash, user_id, expires_at FROM refresh_tokens WHERE user_id=$1 AND expires_at > now()', [payload.userId])).rows;
    if (!rows.length) return res.status(401).json({ message: 'Invalid token' });

    // compare against any entry
    let matchRow = null;
    for (const r of rows) {
      const match = await compareTokenHash(token, r.token_hash);
      if (match) { matchRow = r; break; }
    }
    if (!matchRow) return res.status(401).json({ message: 'Invalid token' });

    // issue new access token
    const accessToken = signAccessToken({ userId: payload.userId, role: payload.role });
    res.json({ accessToken });
  } catch (err) { next(err); }
};

export const logout = async (req, res, next) => {
  try {
    const token = req.cookies[COOKIE_NAME];
    if (token) {
      // try to verify to get userId then delete entries for user & token
      try {
        const payload = verifyRefreshToken(token);
        await pool.query('DELETE FROM refresh_tokens WHERE user_id=$1', [payload.userId]);
      } catch (e) { /* ignore */ }
    }
    res.clearCookie(COOKIE_NAME, { httpOnly: true, sameSite: 'lax', secure: process.env.NODE_ENV === 'production' });
    res.json({ message: 'Logged out' });
  } catch (err) { next(err); }
};

// Minimal password reset flows (request + reset) — omitted for brevity but included in repo
export const requestPasswordReset = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Missing email' });

    // Check if user exists
    const userRes = await pool.query('SELECT id FROM users WHERE email=$1', [email]);
    if (!userRes.rows.length) {
      // Return generic message (avoid leaking user existence)
      return res.status(200).json({ message: 'If account exists we sent instructions' });
    }

    const userId = userRes.rows[0].id;

    // Generate unique ID for this password reset entry
    const resetId = uuidv4(); 
    // const rawToken = uuidv4(); // actual token to send to user
    // const tokenHash = await hashToken(rawToken);
    const reserCode = generateVerificationCode();
    const codeHash = await hashToken(reserCode);
    const expires = new Date(Date.now() + 1000 * 60 * 60); // expires in 1 hour

    // Save to DB (use resetId as the row id)
    await pool.query(
      `INSERT INTO password_resets(id, user_id, token_hash, expires_at)
       VALUES($1, $2, $3, $4)`,
      [resetId, userId, codeHash, expires]
    );

    // Send email
    await sendPasswordResetEmail(email, resetCode);

    // Respond success
    res.status(200).json({ message: 'The reset cose is sent.' });
  } catch (err) {
    console.error('Password reset error:', err);
    next(err);
  }
};

export const resetPassword = async (req, res, next) => {
  try {
    const { email, code, newPassword } = req.body;
    if (!email || !code || !newPassword) return res.status(400).json({ message: 'Missing' });
    const userRes = await pool.query('SELECT id FROM users WHERE email=$1', [email]);
    if (!userRes.rows.length) return res.status(400).json({ message: 'Invalid' });

    const userId = userRes.rows[0].id;
    const rows = (await pool.query('SELECT id, token_hash FROM password_resets WHERE user_id=$1 AND expires_at > now()', [userId])).rows;
    if (!rows.length) return res.status(400).json({ message: 'Invalid or expired' });

    let matched = null;
    for (const r of rows) {
      const ok = await compareTokenHash(code, r.token_hash);
      if (ok) { matched = r; break; }
    }
    if (!matched) return res.status(400).json({ message: 'Invalid code' });

    const newHash = await bcrypt.hash(newPassword, 10);
    await pool.query('UPDATE users SET password_hash=$1 WHERE id=$2', [newHash, userId]);
    await pool.query('DELETE FROM password_resets WHERE id=$1', [matched.id]);
    res.json({ message: 'Password changed' });
  } catch (err) { next(err);
    
   }
};
