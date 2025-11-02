-- =====================================================
-- File: perfomance.sql
-- Project: ALX Airbnb Database Module - Advanced SQL
-- Task 4: Optimize Complex Queries
-- DB Flavor: MySQL 8+
-- =====================================================

/*
Assumed schema (keys abbreviated):
  users(user_id PK, first_name, last_name, email, ...)
  properties(property_id PK, property_name, location, host_id, price, ...)
  bookings(booking_id PK, user_id FK, property_id FK, start_date, end_date, total_price, created_at, ...)
  payments(payment_id PK, booking_id FK, amount, status, paid_at, method, ...)

Indexes recommended from prior tasks:
  bookings:  (user_id), (property_id), (property_id, start_date), (user_id, start_date)
  properties:(location), (location, price)
  users:     UNIQUE(email)
  payments:  (booking_id, paid_at), (booking_id, status)  -- see report for rationale
*/


/* -----------------------------------------------------
  1) INITIAL (NAÏVE) QUERY
     - Retrieves *all* bookings with user, property, and payment details
     - Uses SELECT * and a plain LEFT JOIN to payments (may duplicate rows
       when a booking has multiple payment records: retries, partials, refunds)
------------------------------------------------------*/

-- (Run an EXPLAIN on this in your client to capture baseline)
SELECT
  *
FROM bookings AS b
JOIN users      AS u ON u.user_id      = b.user_id
JOIN properties AS p ON p.property_id  = b.property_id
LEFT JOIN payments  AS pay ON pay.booking_id = b.booking_id
ORDER BY b.created_at DESC;


/* -----------------------------------------------------
  2) REFACTORED QUERY (WINDOW FUNCTION TO PICK LATEST PAYMENT)
     Goals:
       - Avoid row multiplication from multiple payments/booking
       - Project only needed columns (no SELECT *)
       - Preserve OUTER join semantics for bookings that may not be paid yet
       - Keep an ORDER BY that can leverage indexes

     Strategy:
       - Build a CTE latest_payment: for each booking_id, choose the
         most recent payment by paid_at (rn = 1)
       - Join to that reduced set instead of the whole payments table
------------------------------------------------------*/

WITH latest_payment AS (
  SELECT
    booking_id,
    payment_id,
    amount,
    status,
    paid_at,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
  FROM payments
)
SELECT
  b.booking_id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.total_price,
  b.created_at,

  u.first_name,
  u.last_name,
  u.email,

  p.property_name,
  p.location,
  p.price,

  lp.payment_id,
  lp.amount         AS last_payment_amount,
  lp.status         AS last_payment_status,
  lp.paid_at        AS last_paid_at
FROM bookings AS b
JOIN users      AS u  ON u.user_id     = b.user_id
JOIN properties AS p  ON p.property_id = b.property_id
LEFT JOIN latest_payment AS lp
       ON lp.booking_id = b.booking_id
      AND lp.rn = 1
ORDER BY b.created_at DESC;


/* -----------------------------------------------------
  3) VARIANT: PRE-AGGREGATE PAYMENTS (NO WINDOW)
     If your MySQL version/plan prefers simpler aggregates, you can
     pre-aggregate to the last paid_at per booking, then re-join once.
------------------------------------------------------*/

WITH last_paid AS (
  SELECT booking_id, MAX(paid_at) AS last_paid_at
  FROM payments
  GROUP BY booking_id
)
SELECT
  b.booking_id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.total_price,
  b.created_at,

  u.first_name,
  u.last_name,
  u.email,

  p.property_name,
  p.location,
  p.price,

  pay.payment_id,
  pay.amount        AS last_payment_amount,
  pay.status        AS last_payment_status,
  pay.paid_at       AS last_paid_at
FROM bookings AS b
JOIN users      AS u   ON u.user_id     = b.user_id
JOIN properties AS p   ON p.property_id = b.property_id
LEFT JOIN last_paid AS lp
       ON lp.booking_id = b.booking_id
LEFT JOIN payments AS pay
       ON pay.booking_id = lp.booking_id
      AND pay.paid_at    = lp.last_paid_at
ORDER BY b.created_at DESC;


/* -----------------------------------------------------
  4) OPTIONAL: COVERING-INDEX-FRIENDLY PROJECTION
     - Select the minimal set of columns
     - Helps the optimizer use "Using index" (covering) where possible
------------------------------------------------------*/

SELECT
  b.booking_id, b.user_id, b.property_id, b.created_at,
  u.first_name, u.last_name,
  p.property_name,
  COALESCE(lp.amount, 0) AS last_payment_amount
FROM bookings AS b
JOIN users      AS u  ON u.user_id     = b.user_id
JOIN properties AS p  ON p.property_id = b.property_id
LEFT JOIN (
  SELECT booking_id, amount, paid_at,
         ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
  FROM payments
) AS lp
  ON lp.booking_id = b.booking_id AND lp.rn = 1
ORDER BY b.created_at DESC;


/* -----------------------------------------------------
  5) NOTES:
     - Capture EXPLAIN/EXPLAIN ANALYZE for the initial query
       and for either refactored version (#2 or #3).
     - Ensure supporting indexes exist (see optimization_report.md).
------------------------------------------------------*/
