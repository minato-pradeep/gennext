const pool = require('./db');

pool.query(`
  CREATE TABLE IF NOT EXISTS rental_listings (
    id SERIAL PRIMARY KEY,
    owner_id INT REFERENCES users(id) ON DELETE SET NULL,
    owner_name VARCHAR(100),
    owner_phone VARCHAR(20),
    owner_apartment VARCHAR(50),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    location VARCHAR(200),
    rent_amount VARCHAR(50) NOT NULL,
    advance_amount VARCHAR(50),
    bhk_type VARCHAR(20),
    furnishing VARCHAR(30) DEFAULT 'unfurnished',
    images TEXT[],
    status VARCHAR(20) DEFAULT 'available',
    created_at TIMESTAMP DEFAULT NOW()
  )
`).then(() => {
  console.log('✅ rental_listings table created');
  process.exit(0);
}).catch(e => {
  console.error('❌', e.message);
  process.exit(1);
});
