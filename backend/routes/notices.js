const express = require('express');
const router = express.Router();
const pool = require('../db');

async function getNoticeColumnMap() {
  try {
    const result = await pool.query(`
      SELECT column_name
      FROM information_schema.columns
      WHERE table_name = 'notices'
    `);
    const cols = new Set(result.rows.map((row) => row.column_name));
    return {
      hasDescription: cols.has('description'),
      hasContent: cols.has('content'),
      hasCreatedBy: cols.has('created_by'),
      hasPostedBy: cols.has('posted_by'),
      hasPriority: cols.has('priority'),
      hasType: cols.has('type'),
      hasExpiryDate: cols.has('expiry_date'),
    };
  } catch (err) {
    return {
      hasDescription: false,
      hasContent: false,
      hasCreatedBy: false,
      hasPostedBy: false,
      hasPriority: false,
      hasType: false,
      hasExpiryDate: false,
    };
  }
}

function normalizeNoticeRow(row) {
  const safeRow = { ...row };
  const description = safeRow.description ?? safeRow.content ?? '';
  const createdBy = safeRow.created_by ?? safeRow.posted_by ?? '';
  const priority = safeRow.priority ?? safeRow.type ?? 'normal';
  const expiryDate = safeRow.expiry_date ?? null;

  safeRow.description = description;
  safeRow.created_by = createdBy;
  safeRow.priority = priority;
  safeRow.expiry_date = expiryDate;
  return safeRow;
}

// GET all notices
router.get('/', async (req, res) => {
  try {
    const cols = await getNoticeColumnMap();
    const descField = cols.hasDescription ? 'description' : 'content';
    const createdByField = cols.hasCreatedBy ? 'created_by' : 'posted_by';
    const priorityField = cols.hasPriority ? 'priority' : (cols.hasType ? 'type' : `'normal'`);

    const userId = Number.parseInt(req.query.user_id, 10);
    const recipientFilter = Number.isInteger(userId)
      ? `WHERE recipient_user_id IS NULL OR recipient_user_id = ${userId}`
      : '';
    const result = await pool.query(`
      SELECT
        id,
        title,
        ${descField} AS description,
        ${createdByField} AS created_by,
        ${priorityField} AS priority,
        expiry_date,
        created_at,
        recipient_user_id
      FROM notices
      ${recipientFilter}
      ORDER BY created_at DESC
    `);

    res.json({
      success: true,
      notices: result.rows.map(normalizeNoticeRow),
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST create notice
router.post('/', async (req, res) => {
  const { title, description, content, created_by, posted_by, priority, expiry_date } = req.body;
  const noticeText = description ?? content ?? '';
  const createdBy = created_by ?? posted_by ?? 'System';

  try {
    const cols = await getNoticeColumnMap();
    const fields = ['title'];
    const values = [title];

    if (cols.hasDescription) {
      fields.push('description');
      values.push(noticeText);
    }

    if (cols.hasContent) {
      fields.push('content');
      values.push(noticeText);
    }

    if (cols.hasCreatedBy) {
      fields.push('created_by');
      values.push(createdBy);
    }

    if (cols.hasPostedBy) {
      fields.push('posted_by');
      values.push(createdBy);
    }

    if (cols.hasPriority) {
      fields.push('priority');
      values.push(priority || 'normal');
    } else if (cols.hasType) {
      fields.push('type');
      values.push(priority || 'normal');
    }

    if (cols.hasExpiryDate) {
      fields.push('expiry_date');
      values.push(expiry_date || null);
    }

    const placeholders = values.map((_, index) => `$${index + 1}`).join(', ');
    const result = await pool.query(
      `INSERT INTO notices (${fields.join(', ')}) VALUES (${placeholders}) RETURNING *`,
      values
    );

    res.json({ success: true, notice: normalizeNoticeRow(result.rows[0]) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT update notice
router.put('/:id', async (req, res) => {
  const { title, description, content, priority, expiry_date } = req.body;
  const noticeText = description ?? content ?? '';

  try {
    const cols = await getNoticeColumnMap();
    const fields = [];
    const values = [];

    if (title) {
      fields.push('title');
      values.push(title);
    }

    if (cols.hasDescription) {
      fields.push('description');
      values.push(noticeText);
    }

    if (cols.hasContent) {
      fields.push('content');
      values.push(noticeText);
    }

    if (cols.hasPriority) {
      fields.push('priority');
      values.push(priority || 'normal');
    } else if (cols.hasType) {
      fields.push('type');
      values.push(priority || 'normal');
    }

    if (cols.hasExpiryDate) {
      fields.push('expiry_date');
      values.push(expiry_date || null);
    }

    if (fields.length === 0) {
      return res.json({ success: true, notice: null });
    }

    const assignments = fields.map((field, index) => `${field}=$${index + 1}`).join(', ');
    values.push(req.params.id);
    const result = await pool.query(
      `UPDATE notices SET ${assignments} WHERE id=$${values.length} RETURNING *`,
      values
    );

    res.json({ success: true, notice: normalizeNoticeRow(result.rows[0]) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE notice
router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM notices WHERE id=$1', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
