import bcrypt from 'bcryptjs';
import nodemailer from 'nodemailer';
import { query } from '../config/database.js';
import * as tokenService from '../services/tokenService.js';

// Email transporter
const transporter = nodemailer.createTransport({

  service : "gmail",
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// Generate JWT token

const generateVerificationCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit number as string
};

// Send verification email
const sendVerificationEmail = async (email, code) => {
  const mailOptions = {
    from: process.env.EMAIL_FROM,
    to: email,
    subject: 'Verify your ServeEase account',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>Welcome to ServeEase!</h2>
        <p>Your email verification code is:</p>
        <h3 style="color: #4CAF50;">${code}</h3>
        <p>This code will expire in 10 minutes.</p>
        <p>Best regards,<br>The ServeEase Team</p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
};

// Register user
const register = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password || !role) {
      return res.status(400).json({ success: false, message: 'All fields are required' });
    }

    if (!['seeker', 'provider'].includes(role)) {
      return res.status(400).json({ success: false, message: 'Role must be either seeker or provider' });
    }

    const existingUser = await query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ success: false, message: 'User with this email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const verificationCode = generateVerificationCode();
    const verificationExpires = new Date(Date.now() + 20 * 60 * 1000); // 20 min

    const result = await query(
      `INSERT INTO users (name, email, password_hash, role, email_verification_code, email_verification_expires)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, name, email, role, email_verified`,
      [name, email, passwordHash, role, verificationCode, verificationExpires]
    );

    const user = result.rows[0];

    try {
      await sendVerificationEmail(email, verificationCode);
    } catch (err) {
      console.error('Email sending failed:', err);
    }

    res.status(201).json({
      success: true,
      message: 'User registered. Check your email for the verification code.',
      user: { id: user.id, name: user.name, email: user.email, role: user.role, emailVerified: user.email_verified }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// Verify email
// const verifyEmail = async (req, res) => {
//   try {
//     const { email, code } = req.query;

//     if (!code) {
//       return res.status(400).json({
//         success: false,
//         message: 'Verification code is required'
//       });
//     }

//     // Find user with valid token
//     const result = await query(
//       `UPDATE users
//        SET email_verified = true, email_verification_code = null, email_verification_expires = null
//        WHERE email_verification_code = $1 AND email_verification_expires > NOW()
//        RETURNING id, name, email, role`,
//       [email, code]
//     );

//     if (result.rows.length === 0) {
//       return res.status(400).json({
//         success: false,
//         message: 'Invalid or expired verification token'
//       });
//     }

//     const user = result.rows[0];

//     res.json({
//       success: true,
//       message: 'Email verified successfully',
//       user: {
//         id: user.id,
//         name: user.name,
//         email: user.email,
//         role: user.role,
//         emailVerified: true
//       }
//     });

//   } catch (error) {
//     console.error('Email verification error:', error);
//     res.status(500).json({
//       success: false,
//       message: 'Internal server error'
//     });
//   }
// };

const verifyEmail = async (req, res) => {
  try {
    const { email, code } = req.query;

    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Verification code is required'
      });
    }

    const result = await query(
      `UPDATE users
       SET email_verified = true,
           email_verification_code = null,
           email_verification_expires = null
       WHERE email_verification_code = $1
       AND email = $2
       AND email_verification_expires > NOW()
       RETURNING id, name, email, role`,
      [code, email] // MUST BE THIS ORDER
    );

    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired verification token'
      });
    }

    const user = result.rows[0];

    res.json({
      success: true,
      message: 'Email verified successfully',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        emailVerified: true
      }
    });

  } catch (error) {
    console.error('Email verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

//
// Add this function for resending verification code
const resendVerificationCode = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    // Check if user exists
    const userResult = await query(
      'SELECT id, email_verified FROM users WHERE email = $1',
      [email]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const user = userResult.rows[0];

    // Check if email is already verified
    if (user.email_verified) {
      return res.status(400).json({
        success: false,
        message: 'Email is already verified'
      });
    }

    // Generate new verification code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes from now

    // Update user with new verification code
    await query(
      `UPDATE users
       SET email_verification_code = $1,
           email_verification_expires = $2
       WHERE email = $3`,
      [verificationCode, expiresAt, email]
    );

    // Send new verification email
    await sendVerificationEmail(email, verificationCode);

    res.json({
      success: true,
      message: 'Verification code resent successfully'
    });

  } catch (error) {
    console.error('Resend verification code error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Add this route to your Express routes
// app.post('/api/auth/resend-verification', resendVerificationCode);

// Login user
const login = async (req, res) => {
  try {
    const { email, password, loginAs } = req.body; // loginAs: 'provider' or 'seeker'

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    // Find user
    const result = await query(
      'SELECT id, name, email, password_hash, role, email_verified FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const user = result.rows[0];

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check if email is verified (skip for admin users)
    if (!user.email_verified && user.role !== 'admin') {
      return res.status(401).json({
        success: false,
        message: 'Please verify your email before logging in'
      });
    }

    // Handle provider role choice
    let effectiveRole = user.role; // default role
    if (user.role === 'provider') {
      if (!loginAs || !['provider', 'seeker'].includes(loginAs)) {
        return res.status(400).json({
          success: false,
          message: 'Please choose whether to login as provider or seeker'
        });
      }
      effectiveRole = loginAs;
    }

    const payload = { userId: user.id, role: effectiveRole };
    const accessToken = tokenService.signAccessToken(payload);
    const refreshToken = tokenService.signRefreshToken(payload);

    const hashedRefreshToken = tokenService.hashToken(refreshToken);
    await query('UPDATE users SET refresh_token = $1 WHERE id = $2', [hashedRefreshToken, user.id]);

    res.cookie('refreshToken', refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    res.json({
      success: true,
      message: 'Login successful',
      accessToken,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: effectiveRole,
        emailVerified: user.email_verified
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// ================== Send Password Reset Code ==================
const sendPasswordResetCode = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ success: false, message: 'Email is required' });

    // Check if user exists
    const result = await query('SELECT id FROM users WHERE email = $1', [email]);
    if (!result.rows.length) return res.status(404).json({ success: false, message: 'User not found' });

    const resetCode = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit
    const resetExpires = new Date(Date.now() + 20 * 60 * 1000); // 20 minutes

    // Save reset code and expiry in DB
    await query(
      'UPDATE users SET password_reset_code = $1, password_reset_expires = $2 WHERE email = $3',
      [resetCode, resetExpires, email]
    );

    // Send reset code via email
    const mailOptions = {
      from: process.env.EMAIL_FROM,
      to: email,
      subject: 'Reset your ServeEase password',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Password Reset Request</h2>
          <p>Your password reset code is:</p>
          <h3 style="color: #f44336;">${resetCode}</h3>
          <p>This code will expire in 20 minutes.</p>
          <p>If you did not request this, please ignore this email.</p>
        </div>
      `,
    };
    await transporter.sendMail(mailOptions);

    res.json({ success: true, message: 'Password reset code sent to email' });

  } catch (error) {
    console.error('Send reset code error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// ================== Reset Password ==================
const resetPassword = async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
      return res.status(400).json({ success: false, message: 'Email, code, and new password are required' });
    }

    // Find user with valid reset code
    const result = await query(
      `SELECT id FROM users
       WHERE email = $1 AND password_reset_code = $2 AND password_reset_expires > NOW()`,
      [email, code]
    );

    if (!result.rows.length) return res.status(400).json({ success: false, message: 'Invalid or expired reset code' });

    const userId = result.rows[0].id;
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password and clear reset code
    await query(
      `UPDATE users
       SET password_hash = $1, password_reset_code = NULL, password_reset_expires = NULL
       WHERE id = $2`,
      [hashedPassword, userId]
    );

    res.json({ success: true, message: 'Password reset successfully' });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const refreshTokenHandler = async (req, res) => {
  try {
    const token = req.cookies.refreshToken;
    if (!token) return res.status(401).json({ success: false, message: 'No refresh token provided' });

    let decoded;
    try {
      decoded = tokenService.verifyRefreshToken(token);
    } catch (err) {
      return res.status(403).json({ success: false, message: 'Invalid refresh token' });
    }

    const { userId, role } = decoded;
    const result = await query('SELECT refresh_token FROM users WHERE id = $1', [userId]);
    if (!result.rows[0]) return res.status(403).json({ success: false, message: 'Invalid refresh token' });

    const valid = tokenService.compareTokenHash(token, result.rows[0].refresh_token);
    if (!valid) return res.status(403).json({ success: false, message: 'Invalid refresh token' });

    const newAccessToken = tokenService.signAccessToken({ userId, role });
    res.json({ success: true, accessToken: newAccessToken });

  } catch (err) {
    console.error('Refresh token error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};
// Get current user profile
const getProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      'SELECT id, name, email, role, email_verified, created_at FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const user = result.rows[0];

    res.json({
      success: true,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        emailVerified: user.email_verified,
        createdAt: user.created_at
      }
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

const logout = async (req, res) => {
  try {
    const userId = req.user.id;
    await query('UPDATE users SET refresh_token = null WHERE id = $1', [userId]);
    res.clearCookie('refreshToken', { httpOnly: true, sameSite: 'strict', secure: process.env.NODE_ENV === 'production' });
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};


export {
    getProfile, login, logout, refreshTokenHandler, register, resetPassword, sendPasswordResetCode, verifyEmail,resendVerificationCode
};

