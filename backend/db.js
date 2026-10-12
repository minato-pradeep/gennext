const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

pool.connect()
  .then(client => {
    console.log('✅ Connected to PostgreSQL:', process.env.DB_NAME);
    client.release();
  })
  .catch(err => console.error('❌ DB connection failed:', err.message));

module.exports = pool;
