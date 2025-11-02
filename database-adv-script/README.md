# 🏠 ALX Airbnb Database Module – Advanced SQL

### Tasks 1 & 2  •  Subqueries  |  Aggregations and Window Functions

---

## 📘 Project Overview

These tasks form part of the **Advanced SQL** module in the ALX Airbnb Database project.
They strengthen your ability to analyze data, build efficient SQL queries, and use analytical SQL features found in enterprise-scale systems.

The database simulates an Airbnb-like environment with tables:

| Table        | Purpose                           | Key Columns                                                                     |
| ------------ | --------------------------------- | ------------------------------------------------------------------------------- |
| `users`      | Stores guest and host information | `user_id`, `first_name`, `last_name`, `email`                                   |
| `properties` | Listings and their details        | `property_id`, `property_name`, `location`, `host_id`                           |
| `bookings`   | Reservation records               | `booking_id`, `user_id`, `property_id`, `start_date`, `end_date`, `total_price` |
| `reviews`    | User feedback on properties       | `review_id`, `user_id`, `property_id`, `rating`, `comment`                      |

---

## 📁 Repository Structure

```
alx-airbnb-database/
└── database-adv-script/
    ├── subqueries.sql
    ├── aggregations_and_window_functions.sql
    └── README.md   ← this file
```

---

## 🧩 Task 1 – Subqueries (Correlated & Non-Correlated)

**Objective:** Write both correlated and non-correlated subqueries.

### 1️⃣ Non-Correlated Subquery — Properties with Avg Rating > 4.0

```sql
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
```

**Explanation**

* The subquery independently calculates each property’s average rating.
* The outer query filters `properties` whose IDs appear in that result set.
* Ideal when the inner query doesn’t depend on outer columns.

**Alternative (Derived Table Join):**

```sql
SELECT p.property_id, p.property_name, p.location, x.avg_rating
FROM properties AS p
JOIN (
    SELECT property_id, AVG(rating) AS avg_rating
    FROM reviews
    GROUP BY property_id
    HAVING AVG(rating) > 4.0
) AS x
  ON x.property_id = p.property_id;
```

---

### 2️⃣ Correlated Subquery — Users with > 3 Bookings

```sql
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
```

**Explanation**

* The inner subquery references `u.user_id`, so it executes **once per user**.
* Returns only those users having more than three bookings.
* Useful for per-row checks or thresholds.

**Performance Indexes**

```sql
CREATE INDEX idx_reviews_property_id_rating ON reviews(property_id, rating);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
```

---

### 🧠 Task 1 Key Takeaways

| Concept                     | Meaning                                        | Example                       |
| --------------------------- | ---------------------------------------------- | ----------------------------- |
| **Non-correlated subquery** | Executes independently                         | `IN (SELECT ...)`             |
| **Correlated subquery**     | Runs once per row in outer query               | `WHERE b.user_id = u.user_id` |
| **Optimization**            | Add indexes and use `EXPLAIN` to inspect plans | `EXPLAIN SELECT …`            |

---

## 🧮 Task 2 – Aggregations & Window Functions

**Objective:** Use SQL aggregations and window functions to analyze data.

---

### 1️⃣ Aggregation Query — Total Bookings per User

```sql
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS user_full_name,
    COUNT(b.booking_id) AS total_bookings
FROM users AS u
LEFT JOIN bookings AS b
    ON u.user_id = b.user_id
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY total_bookings DESC;
```

**Explanation**

* `COUNT()` counts each user’s bookings.
* `LEFT JOIN` ensures users with zero bookings appear.
* `GROUP BY` aggregates per user.

**Performance Tip**

```sql
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
```

---

### 2️⃣ Window Function Query — Rank Properties by Bookings

```sql
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
```

**Explanation**

* The CTE computes booking counts per property.
* `RANK()` assigns rank numbers based on booking totals (ties share the same rank).
* Replace with `ROW_NUMBER()` for strict sequential ranking.

**Performance Tip**

```sql
CREATE INDEX idx_bookings_property_id ON bookings(property_id);
```

---

### 🧠 Task 2 Key Takeaways

| Concept        | Description                                 |
| -------------- | ------------------------------------------- |
| `COUNT()`      | Aggregates total records per group          |
| `GROUP BY`     | Groups rows for aggregation                 |
| `RANK()`       | Assigns ranking numbers with ties           |
| `ROW_NUMBER()` | Sequential ranking without ties             |
| `CTE (WITH)`   | Improves readability of multi-stage queries |

---

### 📊 Sample Outputs (illustrative)

**Bookings per User**

| user_id | user_full_name | total_bookings |
| ------- | -------------- | -------------- |
| 5       | Sarah Lopez    | 12             |
| 3       | David Kim      | 9              |
| 7       | Amina Khan     | 0              |

**Property Rankings**

| property_id | property_name    | total_bookings | booking_rank |
| ----------- | ---------------- | -------------- | ------------ |
| 10          | Cozy Loft Berlin | 18             | 1            |
| 8           | Beachfront Villa | 14             | 2            |
| 5           | City Apartment   | 14             | 2            |
| 4           | Rural Cottage    | 6              | 4            |

---

## 🧩 Combined Learning Outcomes

After completing Tasks 1 and 2, you can:

* Build multi-stage SQL queries with subqueries, CTEs, and aggregations.
* Differentiate **correlated vs non-correlated** subqueries.
* Use **COUNT**, **GROUP BY**, and **HAVING** to summarize data.
* Apply **RANK()** and **ROW_NUMBER()** window functions for analytics.
* Add indexes and verify performance using `EXPLAIN` or `ANALYZE`.

---


