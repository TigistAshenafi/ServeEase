import nodemailer from 'nodemailer';
import dotenv from 'dotenv';
dotenv.config();

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT),
  secure: false, // true for 465, false for 587
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

export async function sendVerificationEmail(to, code) {
  await transporter.sendMail({
    from: process.env.EMAIL_FROM,
    to,
    subject: 'Verify your email',
    html: `<p>Your verification code is <b>${code}</b></p>`
  });
}

export async function sendPasswordResetEmail(to, resetCode) {
  await transporter.sendMail({
    from: process.env.EMAIL_FROM,
    to,
    subject: 'Reset your ServeEase password',
    html: `
      <p>Hello,</p>
      <p>You requested to reset your password for ServeEase.</p>
      <p>Your Password Reset Code is:<b>${resetCode}</b></p>
      <p>This code will expire in 1 hour.</p>
      <p>If you didn’t request this, please ignore this email.</p>
    `
  });
}

export default { sendVerificationEmail, sendPasswordResetEmail };