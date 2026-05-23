const bcrypt = require('bcrypt');
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

async function updatePassword() {
  const email = 'admin@purepulse.com';
  const password = 'admin123';
  
  try {
    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);
    console.log('Generated hash:', hashedPassword);
    
    // Update the user
    const result = await pool.query(
      'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE email = $2 RETURNING id, email, role',
      [hashedPassword, email]
    );
    
    if (result.rows.length > 0) {
      console.log('✅ Password updated successfully for:', result.rows[0]);
    } else {
      console.log('❌ User not found with email:', email);
    }
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

updatePassword();