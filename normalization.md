# Normalization to 3NF

**Repo:** `alx-airbnb-database`  
**File:** `normalization.md`  

This document explains how the Airbnb Clone database schema is normalized to **Third Normal Form (3NF)**.  
Entities in scope: **Users, Properties, Bookings, Reviews, Payments** (+ supporting lookup tables).

---

## 0) Current Functional Intuition (FKs)
- A **User** can own many **Properties** and make many **Bookings**.
- A **Property** can have many **Bookings** and **Reviews**.
- A **Booking** can have many **Payments** (retries/partial payments).
- A **Review** is written by a **User** for a **Property** (optionally tied to a specific booking).

---

## 1) First Normal Form (1NF)
**Rule:** Atomic values, no repeating groups, unique rows.

**Adjustments**
- Split `properties.location` string into **atomic address fields**:
  - `properties.address_line`, `properties.city`, `properties.region`, `properties.country_code`, `properties.postal_code`  
  *(Optional advanced: move to an `addresses` table if multiple entities share addresses.)*
- Move repeating lists to junction tables:
  - `property_amenities(property_id, amenity_id)` with `amenities(id, name)`
  - `property_images(id, property_id, url, sort_order)`
- Remove derived fields:
  - Do **not** store `bookings.nights` or `bookings.total_amount_raw`; compute from dates and pricing rules.

**Status:** All attributes are atomic; repeating groups are factored out.

---

## 2) Second Normal Form (2NF)
**Rule:** No partial dependency on part of a composite key (applies to tables with composite PKs).

**Adjustments**
- Junction tables use full composite PKs:
  - `PRIMARY KEY(property_id, amenity_id)` for `property_amenities`
- All non-key columns in composite-key tables (e.g., `property_images`) depend on the **whole** key (`(id)` or `(property_id, url)`), not a subset.

**Status:** No partial dependencies remain.

---

## 3) Third Normal Form (3NF)
**Rule:** No transitive dependencies: non-key attributes must depend **only** on the key, the whole key, and nothing but the key.

**Checks & Fixes**
- **Users**
  - Keep: `username`, `email` (unique), `password_hash`, `role` (enum/lookup), `date_joined`.
  - ⚠️ No attributes like `user_type_description` that derive from `role`.
  - Optional: `roles(id, code, description)` and `users.role_id` if you want soft-configurable roles.

- **Properties**
  - Attributes depend only on `properties.id`.
  - **Pricing:** Keep `price_per_night` as the current base price. Do **not** store computed totals here.
  - **Address:** All address fields describe the property (no transitive dependency).
  - **Amenities/Images:** already moved out, preventing multivalued and transitive dependencies.

- **Bookings**
  - Keep: `user_id`, `property_id`, `check_in_date`, `check_out_date`, `status`.
  - **Do not store** redundant totals like `nights` or `amount`; compute or snapshot elsewhere.
  - If you need to **snapshot price at booking time**, add a separate table:
    - `booking_prices(booking_id PK/FK, nightly_price, currency, tax_rate, discount, total_amount_snapshot)`  
      This isolates pricing snapshot (depends on booking_id only).

- **Payments**
  - Keep payment data tied to **payment id** only: `booking_id`, `user_id` (payer), `amount`, `currency`, `status`, `provider_ref`, `created_at`.
  - Do **not** copy booking fields (dates, property) into payments.

- **Reviews**
  - Keep: `user_id`, `property_id`, `rating`, `comment`, `created_at`.
  - To ensure review-per-stay, use **booking linkage**:
    - Add `booking_id` (FK) and enforce unique `(user_id, booking_id)`  
      This prevents transitive “user→property through booking” confusion and strengthens integrity.

- **Lookups (optional but 3NF-friendly)**
  - `payment_statuses`, `booking_statuses`, `currencies`, `countries` as code tables if you want data-driven enums.

**Status:** No attribute depends on another non-key attribute; derived/snapshot data is isolated.

---

## Final 3NF Schema (concise)

### USERS
- `id (PK)`, `username (UQ)`, `email (UQ)`, `password_hash`, `role`, `date_joined`

### PROPERTIES
- `id (PK)`, `owner_id (FK users.id)`, `title`, `description`
- `address_line`, `city`, `region`, `country_code`, `postal_code`
- `price_per_night`, `created_at`

### PROPERTY_AMENITIES (Junction)
- `property_id (FK properties.id)`, `amenity_id (FK amenities.id)`
- `PRIMARY KEY(property_id, amenity_id)`

### AMENITIES
- `id (PK)`, `name (UQ)`

### PROPERTY_IMAGES
- `id (PK)`, `property_id (FK)`, `url`, `sort_order`

### BOOKINGS
- `id (PK)`, `user_id (FK users.id)`, `property_id (FK properties.id)`
- `check_in_date`, `check_out_date`, `status`

### BOOKING_PRICES (Snapshot – optional)
- `booking_id (PK/FK bookings.id)`, `nightly_price`, `currency`, `tax_rate`, `discount`, `total_amount_snapshot`

### PAYMENTS
- `id (PK)`, `booking_id (FK bookings.id)`, `user_id (FK users.id)`
- `amount`, `currency`, `status`, `provider_ref`, `created_at`

### REVIEWS
- **Option A (per property):**  
  - `id (PK)`, `user_id (FK)`, `property_id (FK)`, `rating`, `comment`, `created_at`
  - `UNIQUE(user_id, property_id)` (optional)
- **Option B (per booking):**  
  - `id (PK)`, `user_id (FK)`, `property_id (FK)`, `booking_id (FK)`, `rating`, `comment`, `created_at`
  - `UNIQUE(user_id, booking_id)`

---

## Integrity, Indexes, Constraints

- **Uniqueness:** `users.email`, `users.username`, `amenities.name`
- **FK Indexes:** `properties.owner_id`, `bookings.user_id`, `bookings.property_id`, `payments.booking_id`
- **Search/Range:** `bookings(property_id, check_in_date, check_out_date)`
- **Checks:** `reviews.rating BETWEEN 1 AND 5`, non-negative monetary fields
- **Date Logic:** ensure `check_in_date < check_out_date` via application + DB constraint (if supported)

---

## Summary of Normalization Steps
1. **1NF:** Split composite fields (location), extract repeating groups (amenities/images), remove derived fields.  
2. **2NF:** Ensure all composite-key tables’ columns depend on the full key (junction PKs).  
3. **3NF:** Eliminate transitive dependencies (pricing snapshots isolated; payments don’t duplicate booking data; reviews optionally tied to bookings).

**Result:** Schema is in 3NF with optional, clearly bounded snapshot/lookup tables where needed.

