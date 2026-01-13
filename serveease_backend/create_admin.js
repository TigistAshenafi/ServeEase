// Create admin user with proper password
import bcrypt from 'bcryptjs';
import { query } from './config/database.js';

async function createAdmin() {
  try {
    const password = 'admin123';
    const hashedPassword = await bcrypt.hash(password, 10);
    
    console.log('Creating admin user...');
    console.log('Password:', password);
    console.log('Hashed:', hashedPassword);
    
    // Update existing admin user
    const result = await query(
      `UPDATE users 
       SET password_hash = $1, email_verified = true 
       WHERE email = 'admin@serveease.com'
       RETURNING id, name, email, role`,
      [hashedPassword]
    );
    
    if (result.rows.length > 0) {
      console.log('Admin user updated successfully:', result.rows[0]);
    } else {
      // Create new admin user
      const createResult = await query(
        `INSERT INTO users (name, email, password_hash, role, email_verified)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, name, email, role`,
        ['Admin User', 'admin@serveease.com', hashedPassword, 'admin', true]
      );
      console.log('Admin user created successfully:', createResult.rows[0]);
    }
    
    process.exit(0);
    
  } catch (error) {
    console.error('Error creating admin:', error);
    process.exit(1);
  }
}

createAdmin();