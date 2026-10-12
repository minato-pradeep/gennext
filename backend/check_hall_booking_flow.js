const { Client } = require('pg');

const base = 'http://localhost:4000';
const future = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
const date = future.toISOString().slice(0, 10);

const payloadA = {
  hall_name: 'Hall A',
  booked_by: 1,
  booked_by_name: 'Test User',
  booking_date: date,
  start_time: '10:00',
  end_time: '12:00',
  amount: 500,
  payment_status: 'pending',
  event_title: 'Hall A check',
  event_description: 'Conflict check',
  invited_user_ids: []
};

const payloadB = {
  hall_name: 'Hall D',
  booked_by: 1,
  booked_by_name: 'Test User',
  booking_date: date,
  start_time: '10:00',
  end_time: '12:00',
  amount: 500,
  payment_status: 'pending',
  event_title: 'Hall D check',
  event_description: 'Conflict check',
  invited_user_ids: []
};

(async () => {
  const res1 = await fetch(`${base}/api/events/halls/book`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payloadA)
  });
  console.log('bookA', res1.status, await res1.text());

  const res2 = await fetch(`${base}/api/events/halls/book`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payloadA)
  });
  console.log('samehall', res2.status, await res2.text());

  const res3 = await fetch(`${base}/api/events/halls/book`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payloadB)
  });
  console.log('diffhall', res3.status, await res3.text());

  const res4 = await fetch(`${base}/api/events`);
  console.log('events', await res4.text());

  const client = new Client({
    host: 'localhost',
    port: 5432,
    database: 'plotvista_company',
    user: 'postgres',
    password: 'root'
  });

  await client.connect();
  const rows = await client.query('SELECT id, hall_name, booking_date, start_time, end_time, amount, payment_status, event_title FROM hall_bookings ORDER BY id DESC LIMIT 10');
  console.log('dbRows', JSON.stringify(rows.rows));
  await client.end();
})();
