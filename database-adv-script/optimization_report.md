# 🚀 Task 4 — Optimize Complex Queries
**Repo:** `alx-airbnb-database/database-adv-script`  
**Files:**  
- `perfomance.sql` — initial and refactored queries  
- `optimization_report.md` — this analysis & evidence

---

## 🎯 Objective
Refactor a complex “bookings + user + property + payment details” query to **reduce execution time** and **avoid row explosion**, then document the **EXPLAIN** improvements.

---

## 1) Initial (Baseline) Query
Located in `perfomance.sql` (Section 1).

**Characteristics**
- `SELECT *` across 4 tables (`bookings`, `users`, `properties`, `payments`)
- Plain `LEFT JOIN payments` causes **row multiplication** when a booking has multiple payments (partial payments, retries, refunds)
- Wide rows (many columns) ➜ more I/O
- Sorting by `b.created_at` can trigger filesort if not backed by an index

**How to Measure (Before)**
```sql
EXPLAIN
SELECT *
FROM bookings b
JOIN users u      ON u.user_id = b.user_id
JOIN properties p ON p.property_id = b.property_id
LEFT JOIN payments pay ON pay.booking_id = b.booking_id
ORDER BY b.created_at DESC;
````

**Typical Inefficiencies to Expect**

* `type = ALL` or large `rows` estimates on `payments`
* `Using temporary; Using filesort` on the final ORDER BY
* Many duplicated booking rows due to multiple `payments`

---

## 2) Refactoring Strategy

1. **Eliminate row explosion**

   * Join only the **latest payment per booking** using a window function (`ROW_NUMBER()`) or a two-step aggregate (`MAX(paid_at)` then re-join).
2. **Project only needed columns**

   * Replace `SELECT *` with explicit column list to reduce I/O.
3. **Leverage supporting indexes**

   * Ensure indexes match join keys and sort keys.

---

## 3) Refactored Queries

Both versions are included in `perfomance.sql`.

### A) Window Function Version (MySQL 8+)

* CTE `latest_payment` keeps only `rn = 1` (most recent by `paid_at`).
* Left-join to that reduced set.

Run:

```sql
EXPLAIN
WITH latest_payment AS (
  SELECT booking_id, payment_id, amount, status, paid_at,
         ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
  FROM payments
)
SELECT ...
FROM bookings b
JOIN users u      ON u.user_id = b.user_id
JOIN properties p ON p.property_id = b.property_id
LEFT JOIN latest_payment lp
       ON lp.booking_id = b.booking_id
      AND lp.rn = 1
ORDER BY b.created_at DESC;
```

### B) Aggregate + Re-Join Version

* CTE `last_paid` finds `MAX(paid_at)` per booking; re-join to `payments` once.

Run:

```sql
EXPLAIN
WITH last_paid AS (
  SELECT booking_id, MAX(paid_at) AS last_paid_at
  FROM payments
  GROUP BY booking_id
)
SELECT ...
FROM bookings b
JOIN users u      ON u.user_id = b.user_id
JOIN properties p ON p.property_id = b.property_id
LEFT JOIN last_paid lp
       ON lp.booking_id = b.booking_id
LEFT JOIN payments pay
       ON pay.booking_id = lp.booking_id
      AND pay.paid_at    = lp.last_paid_at
ORDER BY b.created_at DESC;
```

---

## 4) Index Recommendations (DDL)

Ensure these exist (some were defined in Task 3):

```sql
-- Joins
CREATE INDEX idx_bookings_user_id     ON bookings(user_id);
CREATE INDEX idx_bookings_property_id ON bookings(property_id);

-- Sort / time filters
CREATE INDEX idx_bookings_created_at  ON bookings(created_at);

-- Payments: latest-by-time per booking
CREATE INDEX idx_payments_booking_paid ON payments(booking_id, paid_at);

-- Optional filter for payment states (if filtered often)
-- CREATE INDEX idx_payments_booking_status ON payments(booking_id, status);
```

**Why these help**

* Join keys become `ref` lookups instead of scans.
* `(booking_id, paid_at)` supports both the window-partition ordering and the `MAX(paid_at)` re-join pattern.
* `bookings(created_at)` helps the final `ORDER BY` avoid filesort (engine-dependent).

---

## 5) Expected EXPLAIN Improvements

| Aspect          | Before                   | After                                                     |
| --------------- | ------------------------ | --------------------------------------------------------- |
| Payments access | `ALL` (scan, duplicates) | Reduced set (CTE) or `ref` on `(booking_id, paid_at)`     |
| Rows examined   | High                     | Much lower (one payment per booking)                      |
| Filesort        | Often `Using filesort`   | Decreased likelihood if `idx_bookings_created_at` present |
| Output width    | Wide (`SELECT *`)        | Narrow (explicit columns)                                 |
| Overall time    | Higher                   | Lower / more stable                                       |

---

## 6) Evidence Template (Fill with your actual outputs)

### A) Baseline

```
EXPLAIN <baseline query>
-- key=NULL, type=ALL on payments, rows=3,200,000
-- Extra: Using temporary; Using filesort
```

### B) Refactored (Window)

```
EXPLAIN <refactored window query>
-- payments accessed via derived/CTE
-- bookings: key=idx_bookings_created_at, type=index (ordered scan)
-- Extra: Using where
```

### C) Refactored (Aggregate + Re-Join)

```
EXPLAIN <refactored aggregate query>
-- payments: key=idx_payments_booking_paid, type=ref
-- rows significantly lower
```

If available, also capture:

```sql
EXPLAIN ANALYZE <query>;
```


```

If you want, I can add a **one-shot driver script** that runs `EXPLAIN` before/after automatically so you can paste results straight into the report.
```
