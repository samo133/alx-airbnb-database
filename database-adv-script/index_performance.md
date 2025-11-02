# 🏎️ Task 3 — Implement Indexes for Optimization
**Repo:** `alx-airbnb-database/database-adv-script`  
**Files:**  
- `database_index.sql` — DDL to create indexes  
- `index_performance.md` — this performance guide & evidence template

---

## 🎯 Objective
Identify high-usage columns on **Users**, **Properties**, and **Bookings**, create indexes, and measure query performance **before vs. after** using `EXPLAIN` / `EXPLAIN ANALYZE`.

---

## 🔍 High-Usage Columns & Rationale

| Table | Columns | Why |
|------|---------|-----|
| `users` | `email (UNIQUE)` | Fast login/lookup; enforce uniqueness |
|  | `last_name` | Search/filter/sort by name |
|  | `created_at` | Recent users analytics |
| `properties` | `host_id` | Host dashboards (listings by host) |
|  | `location` | City/region filtering |
|  | `(location, price)` | Search by city then sort by price |
|  | `created_at` | Newest listings |
| `bookings` | `user_id` | Joins, per-user counts/history |
|  | `property_id` | Joins, per-property stats |
|  | `(property_id, start_date)` | Calendar/range queries per listing |
|  | `(user_id, start_date)` | User history ordered by date |
|  | `start_date` | Global date-range reporting |

All corresponding `CREATE INDEX` statements are in **`database_index.sql`**.

---

## 🧪 How to Measure (Before vs After)

> Use **MySQL 8+**. From your SQL client, run each query **before** creating indexes, capture the `EXPLAIN` plan, then **apply indexes** and run again.

### 1) Per-User Booking Counts (Task 2 query)
```sql
EXPLAIN
SELECT u.user_id, COUNT(b.booking_id) AS total_bookings
FROM users u
LEFT JOIN bookings b ON b.user_id = u.user_id
GROUP BY u.user_id
ORDER BY total_bookings DESC;
````

**Expected improvements after `idx_bookings_user_id`:**

* `bookings` access type changes from `ALL` (full scan) ➜ `ref`
* `rows` estimate for `bookings` drops significantly
* `possible_keys/key`: shows `idx_bookings_user_id`

---

### 2) Per-Property Booking Counts + Rank (Task 2 query)

```sql
EXPLAIN
WITH property_booking_counts AS (
  SELECT p.property_id, COUNT(b.booking_id) AS total_bookings
  FROM properties p
  LEFT JOIN bookings b ON b.property_id = p.property_id
  GROUP BY p.property_id
)
SELECT property_id, total_bookings
FROM property_booking_counts
ORDER BY total_bookings DESC;
```

**Expected improvements after `idx_bookings_property_id`:**

* Join on `bookings.property_id` uses `ref`
* Fewer examined rows; lower cost

---

### 3) Listing Search by City Sorted by Price

```sql
EXPLAIN
SELECT property_id, property_name, price
FROM properties
WHERE location = 'Berlin'
ORDER BY price;
```

**Expected improvements after `idx_properties_location_price`:**

* Uses the composite index to satisfy **WHERE + ORDER BY** without extra sort
* `Using index` / `Using filesort: NO` (depending on version/data)

---

### 4) Date-Range Queries per Property (calendar)

```sql
EXPLAIN
SELECT booking_id, start_date, end_date
FROM bookings
WHERE property_id = 123
  AND start_date BETWEEN '2025-01-01' AND '2025-01-31'
ORDER BY start_date;
```

**Expected improvements after `idx_bookings_property_start`:**

* Range scan on composite index (prefix `property_id`, then `start_date`)
* Efficient order-by using the same index

---

### 5) User Trip History (recent first)

```sql
EXPLAIN
SELECT booking_id, property_id, start_date
FROM bookings
WHERE user_id = 42
ORDER BY start_date DESC
LIMIT 20;
```

**Expected improvements after `idx_bookings_user_start`:**

* Index-backed range/ordered scan
* Minimal extra sorting

---

## 🧾 Using `EXPLAIN ANALYZE` (Optional)

If available (MySQL 8.0.18+):

```sql
EXPLAIN ANALYZE
SELECT ...;
```

This runs the query and shows **actual timing/rows**, making the “before vs after” comparison more concrete.

---

## ✅ What Good Looks Like (Checklist)

* [ ] `EXPLAIN` shows `type` at least `ref` (or `range`) instead of `ALL`
* [ ] `possible_keys` includes your new index; `key` shows it’s **used**
* [ ] `rows` (estimated) or `analyze` timing decreases
* [ ] “Using filesort” disappears where composite index matches `WHERE + ORDER BY`
* [ ] No redundant/overlapping indexes (e.g., both `(location)` and `(location, price)` are OK because they serve different patterns)

---

## ⚠️ Common Pitfalls

* **Wrong column order** in composite indexes. Put the **most selective / equality** columns first, then range/sort columns.

  * Example: `(property_id, start_date)` supports `WHERE property_id = ? AND start_date BETWEEN ...`.
* **Over-indexing** slows writes. Only keep indexes that benefit real queries.
* **Low-selectivity columns** (`is_active`, booleans) rarely help alone unless combined.

---

## 📉 Rollback (if needed)

Use the DROP statements at the bottom of `database_index.sql`.

---

## 📚 Evidence Template (for manual QA)

Paste your **before/after** `EXPLAIN` outputs here.

### Query: Per-User Booking Counts

* **Before (plan excerpt):** `type=ALL, key=NULL, rows=1,200,000`
* **After (plan excerpt):** `type=ref, key=idx_bookings_user_id, rows=12,000`

### Query: City Search Sorted by Price

* **Before:** `Using filesort: YES`
* **After:** `Using filesort: NO`, `key=idx_properties_location_price`



