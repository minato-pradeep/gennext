const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const pool = require('../db');

// GET all users with permissions
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT id,username,name,role,apartment,phone,is_active,permissions,flat_number,address,aadhar,pan,vehicle_number,created_at FROM users ORDER BY id');
    res.json({ success: true, users: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET single user by ID
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id,username,name,role,apartment,phone,is_active,flat_number,address,aadhar,pan,vehicle_number,created_at FROM users WHERE id=$1',
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, user: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT update user info
router.put('/:id', async (req, res) => {
  const { name, apartment, phone, role, is_active, flat_number, address, aadhar, pan, vehicle_number } = req.body;
  try {
    await pool.query('UPDATE users SET name=$1,apartment=$2,phone=$3,role=$4,is_active=$5,flat_number=$6,address=$7,aadhar=$8,pan=$9,vehicle_number=$10 WHERE id=$11',
      [name, apartment, phone, role, is_active, flat_number, address, aadhar, pan, vehicle_number, req.params.id]);
    const result = await pool.query('SELECT id,username,name,role,is_active,permissions,apartment,phone,flat_number,address,aadhar,pan,vehicle_number FROM users WHERE id=$1', [req.params.id]);
    res.json({ success: true, user: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT update permissions
router.put('/:id/permissions', async (req, res) => {
  const { permissions } = req.body;
  try {
    await pool.query('UPDATE users SET permissions=$1 WHERE id=$2', [JSON.stringify(permissions), req.params.id]);
    res.json({ success: true, message: 'Permissions updated' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT update password
router.put('/:id/password', async (req, res) => {
  const { password } = req.body;
  try {
    const hashed = await bcrypt.hash(password, 10);
    await pool.query('UPDATE users SET password=$1 WHERE id=$2', [hashed, req.params.id]);
    res.json({ success: true, message: 'Password updated' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE user
router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM users WHERE id=$1', [req.params.id]);
    res.json({ success: true, message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
