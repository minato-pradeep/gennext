-- Run: psql -U postgres -d plotvista_company -f schema.sql

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(100) NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'owner',
  apartment VARCHAR(50),
  phone VARCHAR(20),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS events (
  id SERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  date_time TIMESTAMP NOT NULL,
  posted_by VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS hall_bookings (
  id SERIAL PRIMARY KEY,
  hall_name VARCHAR(50) NOT NULL CHECK (hall_name IN ('Hall A', 'Hall B', 'Hall C', 'Hall D')),
  booked_by INT REFERENCES users(id) ON DELETE SET NULL,
  booked_by_name VARCHAR(100) NOT NULL,
  booking_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  payment_status VARCHAR(20) NOT NULL DEFAULT 'paid',
  event_title VARCHAR(200) NOT NULL,
  event_description TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  CHECK (end_time > start_time)
);

CREATE UNIQUE INDEX IF NOT EXISTS hall_bookings_no_overlap
ON hall_bookings (hall_name, booking_date, start_time, end_time);

ALTER TABLE notices ADD COLUMN IF NOT EXISTS recipient_user_id INT REFERENCES users(id) ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS complaints (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE SET NULL,
  user_name VARCHAR(100),
  user_role VARCHAR(20),
  user_apartment VARCHAR(50),
  issue_type VARCHAR(100) DEFAULT 'Other',
  complaint_text TEXT NOT NULL,
  image_url TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  remarks TEXT,
  resolved_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sos_alerts (
  id SERIAL PRIMARY KEY,
  full_name VARCHAR(100),
  phone_number VARCHAR(20),
  apartment VARCHAR(50),
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  maps_link TEXT,
  is_active BOOLEAN DEFAULT true,
  triggered_at TIMESTAMP DEFAULT NOW(),
  stopped_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sos_contacts (
  id SERIAL PRIMARY KEY,
  owner_phone VARCHAR(20),
  contact_name VARCHAR(100),
  contact_phone VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS sos_partners (
  id SERIAL PRIMARY KEY,
  owner_phone VARCHAR(20) UNIQUE NOT NULL,
  partner_phone VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sos_partner_alerts (
  id SERIAL PRIMARY KEY,
  from_phone VARCHAR(20) NOT NULL,
  to_phone VARCHAR(20) NOT NULL,
  sender_name VARCHAR(100),
  sender_apartment VARCHAR(50),
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  maps_link TEXT,
  is_active BOOLEAN DEFAULT true,
  triggered_at TIMESTAMP DEFAULT NOW(),
  stopped_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS emergency_numbers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  category VARCHAR(50) DEFAULT 'custom',
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notices (
  id SERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  content TEXT,
  type VARCHAR(50) DEFAULT 'general',
  posted_by VARCHAR(100),
  created_by VARCHAR(100),
  priority VARCHAR(20) DEFAULT 'normal',
  expiry_date DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE notices ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE notices ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE notices ADD COLUMN IF NOT EXISTS type VARCHAR(50) DEFAULT 'general';
ALTER TABLE notices ADD COLUMN IF NOT EXISTS posted_by VARCHAR(100);
ALTER TABLE notices ADD COLUMN IF NOT EXISTS created_by VARCHAR(100);
ALTER TABLE notices ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'normal';
ALTER TABLE notices ADD COLUMN IF NOT EXISTS expiry_date DATE;

CREATE TABLE IF NOT EXISTS payments (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE SET NULL,
  title VARCHAR(200) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  type VARCHAR(50),
  status VARCHAR(20) DEFAULT 'pending',
  due_date DATE,
  paid_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoices (
  id SERIAL PRIMARY KEY,
  receipt_no VARCHAR(100) UNIQUE NOT NULL,
  invoice_no VARCHAR(100) UNIQUE NOT NULL,
  bill_id INT REFERENCES bills(id) ON DELETE SET NULL,
  user_id INT REFERENCES users(id) ON DELETE SET NULL,
  payee_name VARCHAR(200),
  apartment VARCHAR(100),
  amount DECIMAL(12,2) NOT NULL,
  payment_method VARCHAR(100),
  bank VARCHAR(200),
  reference_no VARCHAR(200),
  invoice_date TIMESTAMP DEFAULT NOW(),
  organization_name VARCHAR(200) DEFAULT 'gennext',
  org_address TEXT DEFAULT 'Erode',
  org_pincode VARCHAR(20) DEFAULT '638001',
  raw_payload JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS visitors (
  id SERIAL PRIMARY KEY,
  host_user_id INT REFERENCES users(id) ON DELETE SET NULL,
  visitor_name VARCHAR(100) NOT NULL,
  visitor_phone VARCHAR(20),
  purpose TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  check_in TIMESTAMP,
  check_out TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS buy_sell_items (
  id SERIAL PRIMARY KEY,
  item_name VARCHAR(200) NOT NULL,
  price VARCHAR(50) NOT NULL,
  price_type VARCHAR(20) DEFAULT 'fixed',
  description TEXT,
  image_url TEXT,
  seller_id INT REFERENCES users(id) ON DELETE SET NULL,
  seller_name VARCHAR(100),
  seller_phone VARCHAR(20),
  seller_apartment VARCHAR(50),
  category VARCHAR(50) DEFAULT 'Other',
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW()
);
