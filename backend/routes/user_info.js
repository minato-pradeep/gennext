const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET user_info by user_id
router.get('/:userId', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM user_info WHERE user_id=$1', [req.params.userId]);
    if (result.rows.length === 0) return res.json({ success: true, user_info: null });
    res.json({ success: true, user_info: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST or PUT (upsert) user_info
router.post('/:userId', async (req, res) => {
  const { name, phone, flat_number, apartment, address, aadhar, pan, vehicle_number, profile_image } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO user_info (user_id, name, phone, flat_number, apartment, address, aadhar, pan, vehicle_number, profile_image, updated_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,NOW())
       ON CONFLICT (user_id) DO UPDATE SET
         name=$2, phone=$3, flat_number=$4, apartment=$5,
         address=$6, aadhar=$7, pan=$8, vehicle_number=$9, profile_image=$10, updated_at=NOW()
       RETURNING *`,
      [req.params.userId, name, phone, flat_number, apartment, address, aadhar, pan, vehicle_number, profile_image]
    );
    res.json({ success: true, user_info: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
