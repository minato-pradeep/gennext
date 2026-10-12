const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET all polls with options and vote counts
router.get('/', async (req, res) => {
  try {
    const polls = await pool.query('SELECT * FROM polls ORDER BY created_at DESC');
    const result = [];
    for (const poll of polls.rows) {
      const options = await pool.query('SELECT * FROM poll_options WHERE poll_id=$1 ORDER BY id', [poll.id]);
      const totalVotes = options.rows.reduce((s, o) => s + parseInt(o.votes), 0);
      result.push({ ...poll, options: options.rows, total_votes: totalVotes });
    }
    res.json({ success: true, polls: result });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST create poll
router.post('/', async (req, res) => {
  const { question, options, created_by, created_by_apartment } = req.body;
  try {
    const poll = await pool.query(
      'INSERT INTO polls (question, created_by, created_by_apartment) VALUES ($1,$2,$3) RETURNING *',
      [question, created_by, created_by_apartment]
    );
    for (const opt of options) {
      await pool.query('INSERT INTO poll_options (poll_id, option_text) VALUES ($1,$2)', [poll.rows[0].id, opt]);
    }
    res.json({ success: true, poll: poll.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST vote
router.post('/:pollId/vote', async (req, res) => {
  const { option_id, user_id } = req.body;
  try {
    // Check already voted
    const existing = await pool.query('SELECT id FROM poll_votes WHERE poll_id=$1 AND user_id=$2', [req.params.pollId, user_id]);
    if (existing.rows.length > 0) return res.json({ success: false, message: 'Already voted' });
    // Record vote
    await pool.query('INSERT INTO poll_votes (poll_id, option_id, user_id) VALUES ($1,$2,$3)', [req.params.pollId, option_id, user_id]);
    await pool.query('UPDATE poll_options SET votes=votes+1 WHERE id=$1', [option_id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET check if user voted
router.get('/:pollId/voted/:userId', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT option_id FROM poll_votes WHERE poll_id=$1 AND user_id=$2',
      [req.params.pollId, req.params.userId]
    );
    res.json({ success: true, voted: result.rows.length > 0, option_id: result.rows[0]?.option_id || null });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE poll
router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM polls WHERE id=$1', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
