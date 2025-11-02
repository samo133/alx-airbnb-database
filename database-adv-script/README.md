# 🏠 ALX Airbnb Database Module – Advanced SQL
## Task: Subqueries (Correlated & Non-Correlated)

### 📘 Objective
Implement both **non-correlated** and **correlated** subqueries on an Airbnb-style schema.

- **Non-correlated subquery:** Find properties with **average rating > 4.0**.  
- **Correlated subquery:** Find users who have made **more than 3 bookings**.

---

## 🗃️ Schema Context (assumed)
- **users**(`user_id`, `first_name`, `last_name`, …)
- **properties**(`property_id`, `property_name`, `location`, `host_id`, …)
- **reviews**(`review_id`, `property_id`, `user_id`, `rating`, `comment`, …)
- **bookings**(`booking_id`, `user_id`, `property_id`, `start_date`, `end_date`, `total_price`, …)

---

## 🔧 Files
- `subqueries.sql` — contains both required queries (with comments).
- `README.md` — this explanation file.

Repo structure:
```

alx-airbnb-database/
└── database-adv-script/
├── subqueries.sql
└── README.md

````

---

## ✅ Implemented Queries

### 1) Non-Correlated Subquery — Properties with Avg Rating > 4.0
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
````

**Why non-correlated?**
The inner query does **not** reference columns from the outer query (`properties`). It independently returns the set of `property_id` values whose average rating exceeds 4.0; the outer query filters using `IN`.

**Alternate form (derived table join):**

```sql
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
```

---

### 2) Correlated Subquery — Users with > 3 Bookings

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

**Why correlated?**
The inner query references `u.user_id` from the outer query (`users`). For each user row, it counts that user’s bookings, enabling row-by-row filtering.

---

## 📈 Performance Tips (optional but recommended)

* Inspect plans:

  ```sql
  EXPLAIN SELECT ...;         -- MySQL
  EXPLAIN ANALYZE SELECT ...; -- PostgreSQL
  ```
* Helpful indexes for these patterns:

  ```sql
  CREATE INDEX idx_reviews_property_id_rating ON reviews(property_id, rating);
  CREATE INDEX idx_bookings_user_id ON bookings(user_id);
  ```
* If the `reviews` table is large, the derived-table join version can be easier for the optimizer to handle than `IN (subquery)` in some engines.

---

## 🧠 Key Learnings

* **Non-correlated subqueries** run independently of the outer query (great for “IN/HAVING” filters).
* **Correlated subqueries** depend on the current row of the outer query (useful for per-row checks like “count per user”).
* Always **verify with EXPLAIN** and add **supporting indexes** to keep these patterns fast at scale.

