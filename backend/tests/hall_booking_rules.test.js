const test = require('node:test');
const assert = require('node:assert/strict');
const { hasTimeConflict } = require('../utils/hall_booking_rules');

test('blocks overlap when the same hall is booked at the same time', () => {
  const bookings = [
    { hall_name: 'Hall A', booking_date: '2026-09-07', start_time: '10:00', end_time: '12:00' },
  ];

  assert.equal(
    hasTimeConflict(bookings, 'Hall A', '2026-09-07', '11:00', '13:00'),
    true,
  );
});

test('allows different halls to be booked at the same time', () => {
  const bookings = [
    { hall_name: 'Hall A', booking_date: '2026-09-07', start_time: '10:00', end_time: '12:00' },
  ];

  assert.equal(
    hasTimeConflict(bookings, 'Hall D', '2026-09-07', '11:00', '13:00'),
    false,
  );
});
