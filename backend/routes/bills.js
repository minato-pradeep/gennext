const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET /api/bills?user_id=1 — get bills for a user with their payment status
router.get('/', async (req, res) => {
  const { user_id } = req.query;
  try {
    if (user_id) {
      const result = await pool.query(`
        SELECT b.*, ub.status as pay_status, ub.paid_at, ub.transaction_id, ub.payment_method
        FROM bills b
        LEFT JOIN user_bills ub ON b.id = ub.bill_id AND ub.user_id = $1
        WHERE ub.user_id = $1 OR ub.user_id IS NULL
        ORDER BY b.created_at DESC
      `, [user_id]);
      // Only return bills assigned to this user
      const assigned = await pool.query(`
        SELECT b.*, ub.status as pay_status, ub.paid_at, ub.transaction_id, ub.payment_method
        FROM bills b
        JOIN user_bills ub ON b.id = ub.bill_id
        WHERE ub.user_id = $1
        ORDER BY b.created_at DESC
      `, [user_id]);
      return res.json({ success: true, bills: assigned.rows });
    }
    // Admin: get all bills
    const result = await pool.query('SELECT * FROM bills ORDER BY created_at DESC');
    res.json({ success: true, bills: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/bills — create bill and assign to users
router.post('/', async (req, res) => {
  const { title, description, amount, bill_type, due_date, created_by, user_ids } = req.body;
  try {
    const billResult = await pool.query(
      'INSERT INTO bills (title, description, amount, bill_type, due_date, created_by) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *',
      [title, description, amount, bill_type, due_date, created_by]
    );
    const bill = billResult.rows[0];
    // Assign to users
    if (user_ids && user_ids.length > 0) {
      for (const uid of user_ids) {
        await pool.query(
          'INSERT INTO user_bills (bill_id, user_id, status) VALUES ($1,$2,$3) ON CONFLICT DO NOTHING',
          [bill.id, uid, 'pending']
        );
      }
    }
    res.json({ success: true, bill });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/bills/:billId/pay — mark as paid for a user
router.put('/:billId/pay', async (req, res) => {
  const { user_id, transaction_id, payment_method } = req.body;
  try {
    // Support advance payments: months (default 1)
    const months = parseInt(req.body.months) || 1;

    await pool.query(
      'UPDATE user_bills SET status=$1, paid_at=NOW(), transaction_id=$2, payment_method=$3 WHERE bill_id=$4 AND user_id=$5',
      ['paid', transaction_id, payment_method, req.params.billId, user_id]
    );
    // Retrieve bill and user info to create invoice
    const billRes = await pool.query('SELECT * FROM bills WHERE id=$1', [req.params.billId]);
    const userRes = await pool.query('SELECT * FROM users WHERE id=$1', [user_id]);
    const bill = billRes.rows[0];
    const user = userRes.rows[0] || {};

    // Generate unique invoice and receipt identifiers
    const nowTs = Date.now();
    const invoiceNo = `INV${nowTs}`;
    const receiptNo = `REC${nowTs}`;

    // Create invoices for each month paid (one invoice per month)
    const invoices = [];
    for (let i = 0; i < months; i++) {
      const inv = await pool.query(
        `INSERT INTO invoices (receipt_no, invoice_no, bill_id, user_id, payee_name, apartment, amount, payment_method, bank, reference_no, invoice_date, organization_name, org_address, org_pincode, raw_payload)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,NOW(),'gennext','Erode','638001',$11) RETURNING *`,
        [
          `${receiptNo}_${i + 1}`,
          `${invoiceNo}_${i + 1}`,
          req.params.billId,
          user_id,
          user.name || req.body.payee_name || 'Unknown',
          user.apartment || req.body.apartment || '',
          bill.amount || req.body.amount || 0,
          payment_method || req.body.payment_method || '',
          req.body.bank || '',
          req.body.reference_no || transaction_id || '',
          JSON.stringify({ transaction_id, payment_method, user, bill, month_index: i + 1 })
        ]
      );
      invoices.push(inv.rows[0]);
    }

    res.json({ success: true, invoices });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/bills/all-users — for payment management (admin view)
router.get('/all-users', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT u.id as user_id, u.name, u.apartment, u.phone,
             b.id as bill_id, b.title, b.amount, b.bill_type, b.due_date, b.created_at,
             ub.status as pay_status, ub.paid_at, ub.transaction_id
      FROM users u
      JOIN user_bills ub ON u.id = ub.user_id
      JOIN bills b ON b.id = ub.bill_id
      WHERE u.role = 'owner' AND u.is_active = true
      ORDER BY u.name, b.created_at DESC
    `);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
