-- =====================================================
-- File: joins_queries.sql
-- Project: ALX Airbnb Database Module - Advanced SQL
-- Task 0: Write Complex Queries with Joins
-- Author: [Your Name]
-- =====================================================

-- ===============================
-- 1️⃣ INNER JOIN
-- Objective: Retrieve all bookings and the respective users who made those bookings
-- ===============================
SELECT 
    b.booking_id,
    b.property_id,
    b.user_id,
    u.first_name,
    u.last_name,
    b.start_date,
    b.end_date,
    b.total_price
FROM bookings AS b
INNER JOIN users AS u
    ON b.user_id = u.user_id
ORDER BY b.start_date;

-- ===============================
-- 2️⃣ LEFT JOIN
-- Objective: Retrieve all properties and their reviews, 
-- including properties that have no reviews.
-- ===============================
SELECT 
    p.property_id,
    p.property_name,
    p.location,
    r.review_id,
    r.user_id AS reviewer_id,
    r.rating,
    r.comment
FROM properties AS p
LEFT JOIN reviews AS r
    ON p.property_id = r.property_id
ORDER BY p.property_id;

-- ===============================
-- 3️⃣ FULL OUTER JOIN
-- Objective: Retrieve all users and all bookings, 
-- even if the user has no booking or a booking is not linked to a user.
-- ⚠️ Note: MySQL doesn’t support FULL OUTER JOIN directly.
-- We use UNION of LEFT and RIGHT joins to simulate it.
-- ===============================
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    b.booking_id,
    b.property_id,
    b.start_date,
    b.end_date
FROM users AS u
LEFT JOIN bookings AS b
    ON u.user_id = b.user_id

UNION

SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    b.booking_id,
    b.property_id,
    b.start_date,
    b.end_date
FROM users AS u
RIGHT JOIN bookings AS b
    ON u.user_id = b.user_id
ORDER BY user_id;
