-- =====================================================
-- File: database_index.sql
-- Project: ALX Airbnb Database Module - Advanced SQL
-- Task 3: Implement Indexes for Optimization
-- DB Flavor: MySQL 8+
-- =====================================================

/*
  Assumed core tables/columns:

  users(user_id PK, email, first_name, last_name, created_at, ...)
  properties(property_id PK, host_id, property_name, location, price, created_at, ...)
  bookings(booking_id PK, user_id FK, property_id FK, start_date, end_date, total_price, created_at, ...)
*/

/* ------------------------------
   USERS: High-usage columns
   - email: lookups, uniqueness
   - last_name: search/order
   - created_at: recent users
-------------------------------*/

-- Fast lookup + enforce uniqueness for login/email flows
ALTER TABLE users
  ADD UNIQUE INDEX ux_users_email (email);

-- Support name filtering/sorting (optional; drop if low selectivity)
CREATE INDEX idx_users_last_name ON users(last_name);

-- Support time-based analytics
CREATE INDEX idx_users_created_at ON users(created_at);


/* ------------------------------
   PROPERTIES: High-usage columns
   - host_id: host’s listings
   - location: city/region filters
   - (location, price): search + sort
   - created_at: newest listings
   - FULLTEXT(property_name) for keyword search (MySQL InnoDB)
-------------------------------*/

CREATE INDEX idx_properties_host_id ON properties(host_id);

CREATE INDEX idx_properties_location ON properties(location);

-- Composite to cover WHERE location = ? ORDER BY price
CREATE INDEX idx_properties_location_price ON properties(location, price);

CREATE INDEX idx_properties_created_at ON properties(created_at);

-- Optional keyword search (MySQL InnoDB FULLTEXT)
-- CREATE FULLTEXT INDEX ftx_properties_name ON properties(property_name);


/* ------------------------------
   BOOKINGS: High-usage columns
   - user_id: joins, per-user counts
   - property_id: joins, per-listing counts
   - (property_id, start_date): listing calendar queries
   - (user_id, start_date): user history filtering
   - start_date: date-range search / reporting
-------------------------------*/

CREATE INDEX idx_bookings_user_id ON bookings(user_id);

CREATE INDEX idx_bookings_property_id ON bookings(property_id);

-- Composite to help: WHERE property_id = ? AND start_date BETWEEN ...
CREATE INDEX idx_bookings_property_start ON bookings(property_id, start_date);

-- Composite to help: WHERE user_id = ? ORDER BY start_date DESC
CREATE INDEX idx_bookings_user_start ON bookings(user_id, start_date);

-- Standalone for global date-range reports
CREATE INDEX idx_bookings_start_date ON bookings(start_date);


/* ------------------------------
   SANITY CHECKS (run manually when needed)
-------------------------------*/
-- SHOW INDEX FROM users;
-- SHOW INDEX FROM properties;
-- SHOW INDEX FROM bookings;

/* ------------------------------
   ROLLBACK HELPERS (only if needed)
-------------------------------*/
-- ALTER TABLE users DROP INDEX ux_users_email;
-- DROP INDEX idx_users_last_name ON users;
-- DROP INDEX idx_users_created_at ON users;

-- DROP INDEX idx_properties_host_id ON properties;
-- DROP INDEX idx_properties_location ON properties;
-- DROP INDEX idx_properties_location_price ON properties;
-- DROP INDEX idx_properties_created_at ON properties;
-- DROP INDEX ftx_properties_name ON properties;

-- DROP INDEX idx_bookings_user_id ON bookings;
-- DROP INDEX idx_bookings_property_id ON bookings;
-- DROP INDEX idx_bookings_property_start ON bookings;
-- DROP INDEX idx_bookings_user_start ON bookings;
-- DROP INDEX idx_bookings_start_date ON bookings;
