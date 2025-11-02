-- =====================================================
-- File: aggregations_and_window_functions.sql
-- Project: ALX Airbnb Database Module - Advanced SQL
-- Task 2: Apply Aggregations and Window Functions
-- Author: [Your Name]
-- =====================================================

/*
-------------------------------------------------------
1️⃣ Aggregation Query
Objective: Find the total number of bookings made by each user
Approach: Use COUNT() and GROUP BY user_id
-------------------------------------------------------
*/

SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS user_full_name,
    COUNT(b.booking_id) AS total_bookings
FROM users AS u
LEFT JOIN bookings AS b
    ON u.user_id = b.user_id
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY total_bookings DESC;

/*
-- Optional performance tip:
-- Add index to speed up join/aggregation:
-- CREATE INDEX idx_bookings_user_id ON bookings(user_id);
*/

/*
-------------------------------------------------------
2️⃣ Window Function Query
Objective: Rank properties based on total number of bookings
Approach: Aggregate bookings per property, then use RANK()
-------------------------------------------------------
*/

-- Using a Common Table Expression (CTE) for clarity
WITH property_booking_counts AS (
    SELECT
        p.property_id,
        p.property_name,
        COUNT(b.booking_id) AS total_bookings
    FROM properties AS p
    LEFT JOIN bookings AS b
        ON p.property_id = b.property_id
    GROUP BY p.property_id, p.property_name
)
SELECT 
    property_id,
    property_name,
    total_bookings,
    RANK() OVER (ORDER BY total_bookings DESC) AS booking_rank
FROM property_booking_counts
ORDER BY booking_rank;

/*
-- Alternative Window Functions:
-- Use ROW_NUMBER() instead of RANK() to break ties:
-- ROW_NUMBER() OVER (ORDER BY total_bookings DESC) AS booking_rownum

-- Add index for property join:
-- CREATE INDEX idx_bookings_property_id ON bookings(property_id);
*/

/*
-------------------------------------------------------
🧠 Summary:
- COUNT() + GROUP BY → aggregate analysis per entity
- RANK() / ROW_NUMBER() → analytical ranking via window functions
-------------------------------------------------------
*/
