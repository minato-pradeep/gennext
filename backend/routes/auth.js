const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../db');

router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  try {
    const result = await pool.query('SELECT * FROM users WHERE username = $1 AND is_active = true', [username]);
    if (result.rows.length === 0)
      return res.status(401).json({ success: false, message: 'Invalid credentials' });

    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password);
    if (!valid)
      return res.status(401).json({ success: false, message: 'Invalid credentials' });

    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({
      success: true, token,
      user: { id: user.id, username: user.username, name: user.name, role: user.role, apartment: user.apartment, phone: user.phone, permissions: user.permissions || {}, flat_number: user.flat_number, address: user.address, aadhar: user.aadhar, pan: user.pan, vehicle_number: user.vehicle_number }
    });
  } catch (err) {
    console.error('LOGIN ERROR:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/register', async (req, res) => {
  const { username, password, name, role, apartment, phone } = req.body;
  try {
    const hashed = await bcrypt.hash(password, 10);
    const result = await pool.query(
      'INSERT INTO users (username,password,name,role,apartment,phone) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id',
      [username, hashed, name, role || 'owner', apartment, phone]
    );
    res.json({ success: true, user: { id: result.rows[0].id, username, name, role } });
  } catch (err) {
    if (err.code === '23505') return res.status(400).json({ success: false, message: 'Username already exists' });
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
