const express = require('express');
const router = express.Router();
const pool = require('../db');

// ── GET / ─────────────────────────────────────────────────────────────────────
// Returns all maid servants, optionally filtered by active status.
// Query params: ?active=true|false
router.get('/', async (req, res) => {
  try {
    let query = 'SELECT * FROM maid_servants';
    const params = [];

    if (req.query.active !== undefined) {
      const isActive = req.query.active === 'true';
      query += ' WHERE is_active = $1';
      params.push(isActive);
    }

    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, params);
    res.json({ success: true, maids: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── POST / ────────────────────────────────────────────────────────────────────
// Insert a new maid servant record.
router.post('/', async (req, res) => {
  const { name, age, image_url, id_number, address, flats_served, is_active } = req.body;
  try {
    if (!name || !id_number || !address) {
      return res.status(400).json({
        success: false,
        message: 'name, id_number and address are required',
      });
    }

    // flats_served is stored as a JSON array in a TEXT column
    const flatsJson = JSON.stringify(Array.isArray(flats_served) ? flats_served : []);

    const result = await pool.query(
      `INSERT INTO maid_servants
         (name, age, image_url, id_number, address, flats_served, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        name,
        age || null,
        image_url || '',
        id_number,
        address,
        flatsJson,
        is_active !== undefined ? is_active : true,
      ],
    );

    res.json({ success: true, maid: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── PUT /:id/status ───────────────────────────────────────────────────────────
// Toggle active / inactive status.
router.put('/:id/status', async (req, res) => {
  const { is_active } = req.body;
  try {
    const result = await pool.query(
      'UPDATE maid_servants SET is_active = $1 WHERE id = $2 RETURNING *',
      [is_active, req.params.id],
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Maid servant not found' });
    }
    res.json({ success: true, maid: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── DELETE /:id ───────────────────────────────────────────────────────────────
router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM maid_servants WHERE id = $1 RETURNING id',
      [req.params.id],
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Maid servant not found' });
    }
    res.json({ success: true, message: 'Deleted successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
