-- Airbnb Clone — Sample Seed Data (PostgreSQL)
-- Repo: alx-airbnb-database
-- Dir : database-script-0x02
-- File: seed.sql
-- Run AFTER applying database-script-0x01/schema.sql

BEGIN;

-- =========
-- Users
-- =========
-- Predefined UUIDs for referential clarity
-- (You can replace with gen_random_uuid() but keep references in sync)
INSERT INTO users (id, username, email, password_hash, role)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'host_amy',  'amy.host@example.com',  'hash$amy',  'host'),
  ('22222222-2222-2222-2222-222222222222', 'guest_bob', 'bob.guest@example.com', 'hash$bob',  'guest'),
  ('33333333-3333-3333-3333-333333333333', 'guest_cid', 'cid.guest@example.com', 'hash$cid',  'guest'),
  ('44444444-4444-4444-4444-444444444444', 'admin_dev', 'admin@example.com',     'hash$admin','admin')
ON CONFLICT (id) DO NOTHING;

-- =========
-- Amenities
-- =========
INSERT INTO amenities (id, name) VALUES
  ('aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'WiFi'),
  ('aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'Air Conditioning'),
  ('aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'Kitchen'),
  ('aaaaaaa4-aaaa-aaaa-aaaa-aaaaaaaaaaa4', 'Washer'),
  ('aaaaaaa5-aaaa-aaaa-aaaa-aaaaaaaaaaa5', 'Free Parking')
ON CONFLICT (id) DO NOTHING;

-- =========
-- Properties
-- =========
INSERT INTO properties (
  id, owner_id, title, description,
  address_line, city, region, country_code, postal_code,
  price_per_night
) VALUES
  (
    '55555555-5555-5555-5555-555555555555',
    '11111111-1111-1111-1111-111111111111',
    'Sunny Loft in Berlin',
    'A bright, modern loft in the heart of Berlin. Close to cafes and transport.',
    'Alexanderplatz 1', 'Berlin', 'BE', 'DE', '10178',
    120.00
  ),
  (
    '66666666-6666-6666-6666-666666666666',
    '11111111-1111-1111-1111-111111111111',
    'Cozy Lakeside Cabin',
    'Quiet cabin with great views and a fireplace. Perfect weekend escape.',
    '12 Lake Rd', 'Garmisch-Partenkirchen', 'BY', 'DE', '82467',
    95.00
  )
ON CONFLICT (id) DO NOTHING;

-- =========
-- Property Images
-- =========
INSERT INTO property_images (id, property_id, url, sort_order) VALUES
  ('bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbb1', '55555555-5555-5555-5555-555555555555', 'https://example.com/img/berlin_loft_1.jpg', 0),
  ('bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '55555555-5555-5555-5555-555555555555', 'https://example.com/img/berlin_loft_2.jpg', 1),
  ('bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '66666666-6666-6666-6666-666666666666', 'https://example.com/img/lakeside_1.jpg',     0)
ON CONFLICT (id) DO NOTHING;

-- =========
-- Property ↔ Amenities
-- =========
INSERT INTO property_amenities (property_id, amenity_id) VALUES
  ('55555555-5555-5555-5555-555555555555', 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1'), -- WiFi
  ('55555555-5555-5555-5555-555555555555', 'aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaa3'), -- Kitchen
  ('55555555-5555-5555-5555-555555555555', 'aaaaaaa4-aaaa-aaaa-aaaa-aaaaaaaaaaa4'), -- Washer
  ('66666666-6666-6666-6666-666666666666', 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1'), -- WiFi
  ('66666666-6666-6666-6666-666666666666', 'aaaaaaa5-aaaa-aaaa-aaaa-aaaaaaaaaaa5')  -- Free Parking
ON CONFLICT DO NOTHING;

-- =========
-- Bookings (non-overlapping per property)
-- =========
-- Berlin Loft: Bob books in March, then Cid books later in March
INSERT INTO bookings (id, user_id, property_id, check_in_date, check_out_date, status) VALUES
  ('77777777-7777-7777-7777-777777777777', '22222222-2222-2222-2222-222222222222',
   '55555555-5555-5555-5555-555555555555', DATE '2025-03-10', DATE '2025-03-14', 'confirmed'),
  ('88888888-8888-8888-8888-888888888888', '33333333-3333-3333-3333-333333333333',
   '55555555-5555-5555-5555-555555555555', DATE '2025-03-16', DATE '2025-03-20', 'pending'),
  -- Lakeside Cabin: Bob books in April
  ('99999999-9999-9999-9999-999999999999', '22222222-2222-2222-2222-222222222222',
   '66666666-6666-6666-6666-666666666666', DATE '2025-04-05', DATE '2025-04-08', 'confirmed')
ON CONFLICT (id) DO NOTHING;

-- =========
-- Booking Prices (snapshots)
-- =========
INSERT INTO booking_prices (booking_id, nightly_price, currency, tax_rate, discount, total_amount_snapshot) VALUES
  ('77777777-7777-7777-7777-777777777777', 120.00, 'EUR', 7.00, 0.00, 514.80), -- 4 nights * 120 + tax (example)
  ('88888888-8888-8888-8888-888888888888', 120.00, 'EUR', 7.00, 5.00, 447.60), -- pending with discount
  ('99999999-9999-9999-9999-999999999999',  95.00, 'EUR', 7.00, 0.00, 304.95)
ON CONFLICT (booking_id) DO NOTHING;

-- =========
-- Payments (multiple attempts / statuses)
-- =========
-- Booking 7777: one failed attempt, then success
INSERT INTO payments (id, booking_id, user_id, amount, currency, status, provider_ref) VALUES
  ('aaaa1111-2222-3333-4444-555566667777', '77777777-7777-7777-7777-777777777777',
   '22222222-2222-2222-2222-222222222222', 514.80, 'EUR', 'failed',    'pi_test_fail_01'),
  ('bbbb1111-2222-3333-4444-555566667777', '77777777-7777-7777-7777-777777777777',
   '22222222-2222-2222-2222-222222222222', 514.80, 'EUR', 'succeeded', 'pi_test_ok_02'),

-- Booking 8888: pending → no payment yet
  ('cccc1111-2222-3333-4444-555566667777', '88888888-8888-8888-8888-888888888888',
   '33333333-3333-3333-3333-333333333333', 447.60, 'EUR', 'initiated', 'pi_test_init_03'),

-- Booking 9999: successful once
  ('dddd1111-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999',
   '22222222-2222-2222-2222-222222222222', 304.95, 'EUR', 'succeeded', 'pi_test_ok_04')
ON CONFLICT (id) DO NOTHING;

-- =========
-- Reviews (per booking, one per user per booking)
-- =========
INSERT INTO reviews (id, user_id, property_id, booking_id, rating, comment)
VALUES
  ('eeee1111-2222-3333-4444-555566667777',
   '22222222-2222-2222-2222-222222222222',
   '55555555-5555-5555-5555-555555555555',
   '77777777-7777-7777-7777-777777777777',
   5, 'Fantastic place, very clean and central.'),
  ('ffff1111-2222-3333-4444-555566667777',
   '22222222-2222-2222-2222-222222222222',
   '66666666-6666-6666-6666-666666666666',
   '99999999-9999-9999-9999-999999999999',
   4, 'Lovely cabin, quiet stay. Fireplace was a plus.')
ON CONFLICT (id) DO NOTHING;

COMMIT;
