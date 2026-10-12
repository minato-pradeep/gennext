const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET /api/visitors — all visitors (for approval page)
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT v.*, u.name as host_name, u.apartment, u.phone as host_phone
      FROM visitors v
      LEFT JOIN users u ON v.host_user_id = u.id
      ORDER BY v.created_at DESC
    `);
    res.json({ success: true, visitors: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/visitors — register a visitor
router.post('/', async (req, res) => {
  const { host_user_id, visitor_name, visitor_phone, purpose, vehicle_number, visitor_image } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO visitors (host_user_id, visitor_name, visitor_phone, purpose, status, vehicle_number, visitor_image) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *',
      [host_user_id || null, visitor_name, visitor_phone, purpose || '', 'pending', vehicle_number || null, visitor_image || null]
    );
    res.json({ success: true, visitor: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/visitors/:id/checkin — set check_in time
router.put('/:id/checkin', async (req, res) => {
  try {
    const result = await pool.query(
      'UPDATE visitors SET check_in=NOW(), status=$1 WHERE id=$2 RETURNING *',
      ['checked_in', req.params.id]
    );
    res.json({ success: true, visitor: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/visitors/:id/checkout — set check_out time
router.put('/:id/checkout', async (req, res) => {
  try {
    const result = await pool.query(
      'UPDATE visitors SET check_out=NOW(), status=$1 WHERE id=$2 RETURNING *',
      ['checked_out', req.params.id]
    );
    res.json({ success: true, visitor: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/visitors/:id/status — approve or reject
router.put('/:id/status', async (req, res) => {
  const { status } = req.body;
  try {
    const result = await pool.query(
      'UPDATE visitors SET status=$1 WHERE id=$2 RETURNING *',
      [status, req.params.id]
    );
    res.json({ success: true, visitor: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
