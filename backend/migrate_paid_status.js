const pool = require('./db');

async function run() {
  try {
    // Add a proper paid_status column
    await pool.query(`
      ALTER TABLE company_payments
      ADD COLUMN IF NOT EXISTS paid_status VARCHAR(20) NOT NULL DEFAULT 'pending'
    `);
    console.log('✅ paid_status column added');
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
  } finally {
    await pool.end();
  }
}

run();
