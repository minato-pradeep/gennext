const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET /api/rentals — all available listings
router.get('/', async (req, res) => {
  try {
    const { bhk_type, furnishing } = req.query;
    let query = `SELECT * FROM rental_listings WHERE status = 'available'`;
    const params = [];
    if (bhk_type && bhk_type !== 'All') {
      params.push(bhk_type);
      query += ` AND bhk_type = $${params.length}`;
    }
    if (furnishing && furnishing !== 'All') {
      params.push(furnishing);
      query += ` AND furnishing = $${params.length}`;
    }
    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, params);
    res.json({ success: true, listings: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/rentals/my-listings/:ownerId
router.get('/my-listings/:ownerId', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM rental_listings WHERE owner_id = $1 ORDER BY created_at DESC',
      [req.params.ownerId]
    );
    res.json({ success: true, listings: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/rentals — post a new listing
router.post('/', async (req, res) => {
  const {
    owner_id, owner_name, owner_phone, owner_apartment,
    title, description, location,
    rent_amount, advance_amount,
    bhk_type, furnishing, images
  } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO rental_listings
        (owner_id, owner_name, owner_phone, owner_apartment,
         title, description, location,
         rent_amount, advance_amount,
         bhk_type, furnishing, images, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,'available')
       RETURNING *`,
      [
        owner_id || null, owner_name, owner_phone, owner_apartment,
        title, description || '', location || '',
        rent_amount, advance_amount || null,
        bhk_type || null, furnishing || 'unfurnished',
        images && images.length ? images : null
      ]
    );
    res.json({ success: true, listing: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/rentals/:id/rented — mark as rented
router.patch('/:id/rented', async (req, res) => {
  try {
    await pool.query(
      "UPDATE rental_listings SET status='rented' WHERE id=$1",
      [req.params.id]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/rentals/:id
router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM rental_listings WHERE id=$1', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
