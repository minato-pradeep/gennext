const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = 15;
    const offset = (page - 1) * limit;
    const status = req.query.status;

    const where = status && status !== 'all' ? 'WHERE status = $1' : '';
    const params = status && status !== 'all' ? [status] : [];

    const countResult = await pool.query(`SELECT COUNT(*) as total FROM complaints ${where}`, params);
    const total = parseInt(countResult.rows[0].total);
    const rows = await pool.query(
      `SELECT * FROM complaints ${where} ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      [...params, limit, offset]
    );

    res.json({ success: true, complaints: rows.rows, total, page, totalPages: Math.ceil(total / limit) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/', async (req, res) => {
  const { user_id, user_name, user_role, user_apartment, issue_type, complaint_text, image_url } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO complaints (user_id,user_name,user_role,user_apartment,issue_type,complaint_text,image_url) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *',
      [user_id || null, user_name, user_role, user_apartment, issue_type, complaint_text, image_url || '']
    );
    res.json({ success: true, complaint: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/:id', async (req, res) => {
  const { status, remarks } = req.body;
  try {
    const resolvedDate = status === 'resolved' ? new Date() : null;
    await pool.query(
      'UPDATE complaints SET status=$1, remarks=$2, resolved_date=$3 WHERE id=$4',
      [status, remarks || null, resolvedDate, req.params.id]
    );
    const result = await pool.query('SELECT * FROM complaints WHERE id=$1', [req.params.id]);
    res.json({ success: true, complaint: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
