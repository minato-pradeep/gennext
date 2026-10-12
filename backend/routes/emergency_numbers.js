const express = require('express');
const router = express.Router();
const pool = require('../db');

// Auto-create table if not exists
pool.query(`
  CREATE TABLE IF NOT EXISTS emergency_numbers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    category VARCHAR(50) DEFAULT 'custom',
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
  )
`).then(() => {
  // Insert default numbers if table is empty
  return pool.query('SELECT COUNT(*) FROM emergency_numbers WHERE is_default = true');
}).then(result => {
  if (parseInt(result.rows[0].count) === 0) {
    return pool.query(`
      INSERT INTO emergency_numbers (name, phone, category, is_default) VALUES
      ('Police', '100', 'police', true),
      ('Ambulance', '102', 'ambulance', true),
      ('Fire', '101', 'fire', true),
      ('Women Helpline', '1091', 'helpline', true),
      ('Disaster Management', '108', 'disaster', true)
    `);
  }
}).catch(err => console.error('Emergency numbers table error:', err));

// GET /api/emergency-numbers — get all
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM emergency_numbers ORDER BY is_default DESC, id ASC'
    );
    res.json({ success: true, numbers: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/emergency-numbers — add custom number
router.post('/', async (req, res) => {
  const { name, phone, category } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO emergency_numbers (name, phone, category, is_default) VALUES ($1, $2, $3, false) RETURNING *',
      [name, phone, category || 'custom']
    );
    res.json({ success: true, number: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/emergency-numbers/:id — delete custom only
router.delete('/:id', async (req, res) => {
  try {
    await pool.query(
      'DELETE FROM emergency_numbers WHERE id = $1 AND is_default = false',
      [req.params.id]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
