const express = require('express');
const router = express.Router();
const pool = require('../db');

(async function ensurePaymentStatusColumn() {
  try {
    await pool.query(
      "ALTER TABLE layout_customers ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'pending'"
    );
    console.log('✅ layout_customers.payment_status column ensured');
  } catch (err) {
    console.error('❌ Failed to ensure layout_customers.payment_status:', err.message);
  }
})();

router.get('/', async (req, res) => {
  const { phone, apartment } = req.query;
  try {
    let query = 'SELECT *, COALESCE(payment_status, \'pending\') AS payment_status FROM layout_customers';
    const values = [];

    if (phone) {
      query += ' WHERE customer_mobile = $1';
      values.push(phone);
    } else if (apartment) {
      query += ' WHERE door_no = $1 OR plot_number = $1 OR plot_id = $1';
      values.push(apartment);
    }

    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, values);
    return res.json({ success: true, customers: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/:id/pay', async (req, res) => {
  try {
    const result = await pool.query(
      "UPDATE layout_customers SET payment_status='paid' WHERE id=$1 RETURNING *, COALESCE(payment_status, 'pending') AS payment_status",
      [req.params.id]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Customer record not found' });
    }
    return res.json({ success: true, customer: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
