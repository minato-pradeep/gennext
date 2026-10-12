const pool = require('./db');

async function run() {
  try {
    await pool.query(`
      ALTER TABLE company_payments
      ADD COLUMN IF NOT EXISTS payment_type VARCHAR(50) NOT NULL DEFAULT 'maintenance'
    `);
    console.log('✅ payment_type column added (default: maintenance)');
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
  } finally {
    await pool.end();
  }
}

run();
