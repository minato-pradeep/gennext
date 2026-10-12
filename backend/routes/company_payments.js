const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  try {
    let query = `SELECT id, company_id, company_name, project_id, plot_id, plot_name, payment_amount, payment_method, payment_company_id, payment_company_name, notes, created_at, updated_at, projects_mapping_id, payment_type, paid_status AS payment_status FROM company_payments`;
    const values = [];
    const conditions = [];

    if (req.query.plot_id) {
      values.push(req.query.plot_id);
      conditions.push(`plot_id = $${values.length}`);
    }
    if (req.query.plot_name) {
      values.push(req.query.plot_name);
      conditions.push(`plot_name = $${values.length}`);
    }
    if (req.query.company_id) {
      values.push(req.query.company_id);
      conditions.push(`company_id = $${values.length}`);
    }
    if (req.query.company_name) {
      values.push(req.query.company_name);
      conditions.push(`company_name = $${values.length}`);
    }
    if (req.query.payment_type) {
      values.push(req.query.payment_type.toLowerCase());
      conditions.push(`LOWER(payment_type) = $${values.length}`);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, values);
    return res.json({ success: true, payments: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/:id/pay', async (req, res) => {
  try {
    const { payment_method, transaction_id } = req.body;
    if (!payment_method || payment_method.toString().trim().length === 0) {
      return res.status(400).json({ success: false, message: 'payment_method is required' });
    }

    const values = [payment_method, req.params.id];
    let query = `UPDATE company_payments SET payment_method = $1, paid_status = 'paid', updated_at = NOW()`;

    if (transaction_id) {
      values.push(` Transaction ID: ${transaction_id}`);
      query += `, notes = COALESCE(notes, '') || $${values.length}`;
    }

    query += ` WHERE id = $${values.length + 1} RETURNING id, company_id, company_name, project_id, plot_id, plot_name, payment_amount, payment_method, payment_company_id, payment_company_name, notes, created_at, updated_at, projects_mapping_id, payment_type, paid_status AS payment_status`;
    values.push(req.params.id);

    const result = await pool.query(query, values);
    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Payment record not found' });
    }

    return res.json({ success: true, payment: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
