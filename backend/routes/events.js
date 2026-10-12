const express = require('express');
const router = express.Router();
const pool = require('../db');
const { hasTimeConflict } = require('../utils/hall_booking_rules');

router.get('/', async (req, res) => {
  try {
    const [events, hallBookings] = await Promise.all([
      pool.query(
        `SELECT id, title, description, posted_by,
                TO_CHAR(date_time AT TIME ZONE 'Asia/Calcutta', 'YYYY-MM-DD HH24:MI:SS') AS date_time,
                created_at, 'event' AS source, NULL AS hall_name,
                NULL AS booking_id, NULL::numeric AS amount,
                NULL AS payment_status
         FROM events`
      ),
      pool.query(
        `SELECT id, event_title AS title, event_description AS description,
                booked_by_name AS posted_by, booked_by,
                TO_CHAR((booking_date + start_time), 'YYYY-MM-DD HH24:MI:SS') AS date_time,
                created_at, 'hall_booking' AS source, hall_name,
                id AS booking_id, amount, payment_status
         FROM hall_bookings`
      )
    ]);

    // Sort by treating the datetime strings as local (IST) — avoid JS Date UTC mis-parse
    // by comparing the strings directly (lexicographic = chronological for YYYY-MM-DD HH:MM:SS)
    const merged = [...events.rows, ...hallBookings.rows]
      .sort((a, b) => b.date_time.localeCompare(a.date_time));

    res.json({ success: true, events: merged });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/halls/bookings', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, hall_name, booked_by, booked_by_name, booking_date,
              start_time, end_time, amount, payment_status, event_title
       FROM hall_bookings
      WHERE booking_date + start_time >= date_trunc('minute', LOCALTIMESTAMP)
       ORDER BY booking_date, start_time, hall_name`
    );
    res.json({ success: true, bookings: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/halls/book', async (req, res) => {
  const {
    hall_name, booked_by, booked_by_name, booking_date, start_time, end_time,
    amount = 0, payment_status = 'pending', event_title, event_description, invited_user_ids = []
  } = req.body;
  if (!['Hall A', 'Hall B', 'Hall C', 'Hall D'].includes(hall_name) ||
      !booked_by_name || !booking_date || !start_time || !end_time ||
      !event_title) {
    return res.status(400).json({ success: false, message: 'Complete hall, event and time details are required.' });
  }
  const bookingWindow = await pool.query(
    `SELECT ($1::date + $2::time) >= date_trunc('minute', LOCALTIMESTAMP)
            AND ($1::date + $3::time) > ($1::date + $2::time) AS valid`,
    [booking_date, start_time, end_time]
  );
  if (!bookingWindow.rows[0].valid) {
    return res.status(400).json({ success: false, message: 'Choose a future time and make sure the end is after the start.' });
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(`SELECT pg_advisory_xact_lock(hashtext($1))`, [
      `${hall_name}:${booking_date}`
    ]);

    const existingBookings = await client.query(
      `SELECT hall_name, booking_date, start_time, end_time
       FROM hall_bookings
       WHERE hall_name = $1 AND booking_date = $2::date
       FOR UPDATE`,
      [hall_name, booking_date]
    );

    if (hasTimeConflict(existingBookings.rows, hall_name, booking_date, start_time, end_time)) {
      await client.query('ROLLBACK');
      return res.status(409).json({ success: false, message: 'This hall is already booked for that time.' });
    }

    const normalizedAmount = Number(amount) || 0;
    const normalizedStatus = ['paid', 'pending'].includes(payment_status) ? payment_status : 'pending';

    const booking = await client.query(
      `INSERT INTO hall_bookings
       (hall_name, booked_by, booked_by_name, booking_date, start_time, end_time,
        amount, payment_status, event_title, event_description)
         VALUES ($1, $2, $3, $4::date, $5::time, $6::time, $7, $8, $9, $10)
       RETURNING *`,
        [hall_name, booked_by || null, booked_by_name, booking_date, start_time,
          end_time, normalizedAmount, normalizedStatus, event_title, event_description || null]
    );

    const ids = [...new Set(invited_user_ids.map(Number).filter(Number.isInteger))];
    if (ids.length > 0) {
      const noticeText = `${hall_name} booked for ${event_title} on ${booking_date} from ${start_time} to ${end_time}.`;
      for (const userId of ids) {
        await client.query(
          `INSERT INTO notices
           (title, description, content, type, posted_by, created_by, priority, recipient_user_id)
           VALUES ($1, $2, $2, 'event', $3, $3, 'normal', $4)`,
          [`Invitation: ${event_title}`, noticeText, booked_by_name, userId]
        );
      }
    }
    await client.query('COMMIT');
    res.json({ success: true, booking: booking.rows[0], invited_count: ids.length });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ success: false, message: err.message });
  } finally {
    client.release();
  }
});

router.post('/', async (req, res) => {
  const { title, description, date_time, posted_by } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO events (title, description, date_time, posted_by)
       VALUES ($1, $2, $3::timestamp, $4)
       RETURNING id, title, description, posted_by, TO_CHAR(date_time, 'YYYY-MM-DD HH24:MI:SS') AS date_time, created_at`,
      [title, description, date_time, posted_by]
    );
    res.json({ success: true, event: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM events WHERE id=$1', [req.params.id]);
    res.json({ success: true, message: 'Event deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/halls/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM hall_bookings WHERE id=$1 RETURNING id', [req.params.id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Hall booking not found' });
    }
    res.json({ success: true, message: 'Hall booking deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
