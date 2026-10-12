const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST /api/invoices — save an invoice record
router.post('/', async (req, res) => {
  try {
    const {
      receipt_no,
      invoice_no,
      bill_id,
      user_id,
      payee_name,
      apartment,
      amount,
      payment_method,
      bank,
      reference_no,
      invoice_date,
      organization_name,
      org_address,
      org_pincode,
      raw_payload
    } = req.body;

    const insert = await pool.query(
      `INSERT INTO invoices (receipt_no, invoice_no, bill_id, user_id, payee_name, apartment, amount, payment_method, bank, reference_no, invoice_date, organization_name, org_address, org_pincode, raw_payload)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,COALESCE($11,NOW()),COALESCE($12,'gennext'),COALESCE($13,'Erode'),COALESCE($14,'638001'),$15)
       RETURNING *`,
      [receipt_no, invoice_no, bill_id, user_id, payee_name, apartment, amount, payment_method, bank, reference_no, invoice_date, organization_name, org_address, org_pincode, raw_payload || null]
    );

    res.json({ success: true, invoice: insert.rows[0] });
  } catch (err) {
    console.error('Error saving invoice:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/invoices/by-bill/:billId/:userId — fetch invoice for a bill and user
router.get('/by-bill/:billId/:userId', async (req, res) => {
  try {
    const { billId, userId } = req.params;
    const result = await pool.query(
      'SELECT * FROM invoices WHERE bill_id=$1 AND user_id=$2 ORDER BY id DESC LIMIT 1',
      [billId, userId]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Not found' });
    res.json({ success: true, invoice: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/invoices/:id — fetch invoice
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM invoices WHERE id=$1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Not found' });
    res.json({ success: true, invoice: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
