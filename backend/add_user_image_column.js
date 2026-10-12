const pool = require('./db');

async function addUserImageColumn() {
  try {
    await pool.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS user_image BYTEA;
    `);
    console.log('✅ user_image column added successfully');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error adding column:', err.message);
    process.exit(1);
  }
}

addUserImageColumn();