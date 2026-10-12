const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const pool = require('./db');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

async function seedDefaultUsers() {
  const defaultUsers = [
    {
      username: 'master',
      password: 'master',
      name: 'Master',
      role: 'master',
      apartment: 'Admin',
      phone: '+91 99999 99999',
    },
    {
      username: 'macs',
      password: 'macs',
      name: 'Macs',
      role: 'owner',
      apartment: 'B12',
      phone: '+91 98765 43210',
    },
  ];

  for (const user of defaultUsers) {
    const hashed = await bcrypt.hash(user.password, 10);
    const existing = await pool.query('SELECT id FROM users WHERE username = $1', [user.username]);
    if (existing.rows.length === 0) {
      await pool.query(
        'INSERT INTO users (username, password, name, role, apartment, phone, is_active) VALUES ($1, $2, $3, $4, $5, $6, true)',
        [user.username, hashed, user.name, user.role, user.apartment, user.phone],
      );
      console.log(`✅ Created default user: ${user.username}`);
    } else {
      await pool.query('UPDATE users SET password = $1 WHERE username = $2', [hashed, user.username]);
      console.log(`✅ Reset password for default user: ${user.username}`);
    }
  }
}

async function ensureHallBookingTables() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS maid_servants (
      id          SERIAL PRIMARY KEY,
      name        VARCHAR(100) NOT NULL,
      age         INT,
      image_url   TEXT DEFAULT '',
      id_number   VARCHAR(100) NOT NULL,
      address     TEXT NOT NULL,
      flats_served TEXT DEFAULT '[]',
      is_active   BOOLEAN DEFAULT true,
      created_at  TIMESTAMP DEFAULT NOW()
    )
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS hall_bookings (
      id SERIAL PRIMARY KEY,
      hall_name VARCHAR(50) NOT NULL CHECK (hall_name IN ('Hall A', 'Hall B', 'Hall C', 'Hall D')),
      booked_by INT REFERENCES users(id) ON DELETE SET NULL,
      booked_by_name VARCHAR(100) NOT NULL,
      booking_date DATE NOT NULL,
      start_time TIME NOT NULL,
      end_time TIME NOT NULL,
      amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
      payment_status VARCHAR(20) NOT NULL DEFAULT 'paid',
      event_title VARCHAR(200) NOT NULL,
      event_description TEXT,
      created_at TIMESTAMP DEFAULT NOW(),
      CHECK (end_time > start_time)
    )
  `);
  await pool.query(`
    CREATE UNIQUE INDEX IF NOT EXISTS hall_bookings_no_overlap
    ON hall_bookings (hall_name, booking_date, start_time, end_time)
  `);
  await pool.query(`
    ALTER TABLE notices
    ADD COLUMN IF NOT EXISTS recipient_user_id INT REFERENCES users(id) ON DELETE CASCADE
  `);
}

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/events', require('./routes/events'));
app.use('/api/complaints', require('./routes/complaints'));
app.use('/api/emergency-numbers', require('./routes/emergency_numbers'));
app.use('/api/buy-sell', require('./routes/buy_sell'));
app.use('/api/bills', require('./routes/bills'));
app.use('/api/visitors', require('./routes/visitors'));
app.use('/api/polls', require('./routes/polls'));
app.use('/api/notices', require('./routes/notices'));
app.use('/api/users', require('./routes/users'));
app.use('/api/user-info', require('./routes/user_info'));
app.use('/api/invoices', require('./routes/invoices'));
app.use('/api/layout-customers', require('./routes/layout_customers'));
app.use('/api/company-payments', require('./routes/company_payments'));
app.use('/api/rentals', require('./routes/rentals'));
app.use('/api/maid-servants', require('./routes/maid_servants'));

// Health check
app.get('/', (req, res) => {
  res.json({ message: '✅ GenNext API running' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('❌ Unhandled error:', err.message);
  res.status(500).json({ success: false, message: err.message });
});

const PORT = process.env.PORT || 4000;
const HOST = process.env.HOST || '0.0.0.0';

ensureHallBookingTables()
  .then(() => seedDefaultUsers())
  .then(() => {
    app.listen(PORT, HOST, () => {
      console.log(`🚀 Server is live!`);
      console.log(`   Local:   http://localhost:${PORT}`);
      console.log(`   Network: http://${HOST}:${PORT}`);
    });
  })
  .catch(err => {
    console.error('❌ Failed to seed default users:', err);
    process.exit(1);
  });
