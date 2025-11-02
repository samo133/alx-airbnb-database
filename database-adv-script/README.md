### ⚙️ Database Context
The database simulates the Airbnb schema, with key tables such as:
- **users** – stores user profile data (`user_id`, `first_name`, `last_name`, `email`, etc.)
- **properties** – stores property details (`property_id`, `property_name`, `location`, `host_id`, etc.)
- **bookings** – records each booking (`booking_id`, `user_id`, `property_id`, `start_date`, `end_date`, `total_price`)
- **reviews** – stores reviews made by users (`review_id`, `user_id`, `property_id`, `rating`, `comment`)

---

### 🧩 Queries Implemented

#### 1️⃣ INNER JOIN — Users with Their Bookings
```sql
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
    ON b.user_id = u.user_id;
```

Explanation:

Retrieves only users who have made bookings.

Excludes users without bookings or orphaned bookings.

#### 2️⃣ LEFT JOIN — Properties with Reviews
```sql
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
    ON p.property_id = r.property_id;
```

Explanation:

Returns all properties, including those with no reviews.

If no review exists, the review_id and rating columns will return NULL.

#### 3️⃣ FULL OUTER JOIN — All Users and All Bookings
```sql
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
    ON u.user_id = b.user_id;
```

Explanation:

Combines the results of both LEFT JOIN and RIGHT JOIN using UNION.

Ensures that:

Users with no bookings are included.

Bookings with no valid user are also shown.

Useful for identifying data mismatches or orphaned records.

#### 🧠 Learning Takeaways

INNER JOIN: returns only matching records.

LEFT JOIN: preserves all rows from the left table.

FULL OUTER JOIN: merges both sides, including non-matching records.

UNION-based FULL JOIN: practical workaround in MySQL.

Joins enable complex data relationships and analytical insights in real-world relational models.

#### 🧩 Repository Structure
alx-airbnb-database/
└── database-adv-script/
    ├── joins_queries.sql
    └── README.md
