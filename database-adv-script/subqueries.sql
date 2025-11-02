-- =====================================================
-- File: subqueries.sql
-- Project: ALX Airbnb Database Module - Advanced SQL
-- Task: Subqueries (correlated & non-correlated)
-- Author: [Your Name]
-- DB Flavor: MySQL-compatible
-- =====================================================

/*
-------------------------------------------------------
1) NON-CORRELATED SUBQUERY
Objective: Find all properties where the average rating > 4.0
Approach: Use a non-correlated subquery that returns property_ids
         meeting the condition; outer query filters on IN (...)
-------------------------------------------------------
*/
SELECT 
    p.property_id,
    p.property_name,
    p.location
FROM properties AS p
WHERE p.property_id IN (
    SELECT r.property_id
    FROM reviews AS r
    GROUP BY r.property_id
    HAVING AVG(r.rating) > 4.0
)
ORDER BY p.property_id;

/*
-- Alternative (derived table join), also non-correlated:

SELECT 
    p.property_id,
    p.property_name,
    p.location,
    x.avg_rating
FROM properties AS p
JOIN (
    SELECT property_id, AVG(rating) AS avg_rating
    FROM reviews
    GROUP BY property_id
    HAVING AVG(rating) > 4.0
) AS x
  ON x.property_id = p.property_id
ORDER BY p.property_id;
*/

/*
-------------------------------------------------------
2) CORRELATED SUBQUERY
Objective: Find users who have made more than 3 bookings
Approach: For each user row, run a subquery that counts
          that user's bookings (correlated via user_id)
-------------------------------------------------------
*/
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    (
        SELECT COUNT(*)
        FROM bookings AS b
        WHERE b.user_id = u.user_id
    ) AS booking_count
FROM users AS u
WHERE (
    SELECT COUNT(*)
    FROM bookings AS b
    WHERE b.user_id = u.user_id
) > 3
ORDER BY booking_count DESC, u.user_id;

/*
-- Optional performance notes (run as needed):
-- EXPLAIN the queries to inspect access paths:
-- EXPLAIN SELECT ... (paste either query above);

-- Helpful indexes for these patterns:
-- CREATE INDEX idx_reviews_property_id_rating ON reviews(property_id, rating);
-- CREATE INDEX idx_bookings_user_id ON bookings(user_id);
*/
