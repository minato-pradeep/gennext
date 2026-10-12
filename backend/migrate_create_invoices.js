const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

const sql = `
CREATE TABLE IF NOT EXISTS invoices (
  id SERIAL PRIMARY KEY,
  receipt_no VARCHAR(100) UNIQUE NOT NULL,
  invoice_no VARCHAR(100) UNIQUE NOT NULL,
  bill_id INT REFERENCES bills(id) ON DELETE SET NULL,
  user_id INT REFERENCES users(id) ON DELETE SET NULL,
  payee_name VARCHAR(200),
  apartment VARCHAR(100),
  amount DECIMAL(12,2) NOT NULL,
  payment_method VARCHAR(100),
  bank VARCHAR(200),
  reference_no VARCHAR(200),
  invoice_date TIMESTAMP DEFAULT NOW(),
  organization_name VARCHAR(200) DEFAULT 'gennext',
  org_address TEXT DEFAULT 'Erode',
  org_pincode VARCHAR(20) DEFAULT '638001',
  raw_payload JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);
`;

pool.query(sql)
  .then(() => {
    console.log('✅ invoices table ensured');
    return pool.end();
  })
  .catch((err) => {
    console.error('❌ migration failed', err);
    pool.end();
    process.exit(1);
  });
