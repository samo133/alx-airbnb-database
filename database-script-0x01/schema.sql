-- Airbnb Clone — Database Schema (PostgreSQL)
-- Repo: alx-airbnb-database
-- Dir : database-script-0x01
-- File: schema.sql

-- =========
-- Extensions
-- =========
-- UUID generation & advanced constraints
CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS btree_gist;    -- for EXCLUDE (overlap) with ranges

-- =========
-- Enum Types
-- =========
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status') THEN
    CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'cancelled');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
    CREATE TYPE payment_status AS ENUM ('initiated', 'succeeded', 'failed', 'refunded');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('guest', 'host', 'admin');
  END IF;
END$$;

-- =========
-- Tables
-- =========

-- Users
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username      TEXT NOT NULL UNIQUE,
  email         CITEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role          user_role NOT NULL DEFAULT 'guest',
  date_joined   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Properties
CREATE TABLE IF NOT EXISTS properties (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title            TEXT NOT NULL,
  description      TEXT,
  -- Normalized address (3NF-friendly)
  address_line     TEXT,
  city             TEXT,
  region           TEXT,
  country_code     CHAR(2),
  postal_code      TEXT,
  price_per_night  NUMERIC(12,2) NOT NULL CHECK (price_per_night >= 0),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Amenities master
CREATE TABLE IF NOT EXISTS amenities (
  id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name  TEXT NOT NULL UNIQUE
);

-- Property ↔ Amenity (junction)
CREATE TABLE IF NOT EXISTS property_amenities (
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  amenity_id  UUID NOT NULL REFERENCES amenities(id) ON DELETE CASCADE,
  PRIMARY KEY (property_id, amenity_id)
);

-- Property images
CREATE TABLE IF NOT EXISTS property_images (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  url         TEXT NOT NULL,
  sort_order  INT  NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Bookings
CREATE TABLE IF NOT EXISTS bookings (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,      -- guest
  property_id    UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  check_in_date  DATE NOT NULL,
  check_out_date DATE NOT NULL,
  status         booking_status NOT NULL DEFAULT 'pending',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (check_in_date < check_out_date)
);

-- Optional: snapshot prices at booking time (keeps core tables in 3NF)
CREATE TABLE IF NOT EXISTS booking_prices (
  booking_id            UUID PRIMARY KEY REFERENCES bookings(id) ON DELETE CASCADE,
  nightly_price         NUMERIC(12,2) NOT NULL CHECK (nightly_price >= 0),
  currency              CHAR(3) NOT NULL,
  tax_rate              NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (tax_rate >= 0),
  discount              NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
  total_amount_snapshot NUMERIC(12,2) NOT NULL CHECK (total_amount_snapshot >= 0)
);

-- Prevent overlapping bookings per property (inclusive daterange)
-- EXCLUDE: same property_id cannot have overlapping date ranges
ALTER TABLE bookings
  ADD CONSTRAINT bookings_no_overlap
  EXCLUDE USING gist (
    property_id WITH =,
    daterange(check_in_date, check_out_date, '[]') WITH &&
  );

-- Payments (allow multiple attempts/retries per booking)
CREATE TABLE IF NOT EXISTS payments (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,  -- payer
  amount       NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  currency     CHAR(3) NOT NULL,
  status       payment_status NOT NULL DEFAULT 'initiated',
  provider_ref TEXT,                         -- gateway reference id
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Reviews (per-booking for strict “review-per-stay” integrity)
CREATE TABLE IF NOT EXISTS reviews (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  booking_id   UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  rating       INT  NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment      TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, booking_id)              -- one review per user per booking
);

-- =========
-- Indexes
-- =========

-- FKs / lookups
CREATE INDEX IF NOT EXISTS idx_properties_owner_id       ON properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id          ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_property_id      ON bookings(property_id);
CREATE INDEX IF NOT EXISTS idx_payments_booking_id       ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id          ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_property_id       ON reviews(property_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id           ON reviews(user_id);

-- Search / ranges
CREATE INDEX IF NOT EXISTS idx_bookings_property_dates
  ON bookings(property_id, check_in_date, check_out_date);

-- Properties geo/text (basic starters)
CREATE INDEX IF NOT EXISTS idx_properties_city           ON properties(city);
CREATE INDEX IF NOT EXISTS idx_properties_country        ON properties(country_code);

-- Images ordering
CREATE INDEX IF NOT EXISTS idx_property_images_pid_order ON property_images(property_id, sort_order);
