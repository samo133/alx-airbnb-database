# Database Schema — Airbnb Clone

This folder contains the **PostgreSQL DDL** for the Airbnb Clone backend.

## Files
- `schema.sql` — Creates extensions, enums, tables, constraints, and indexes
- (Optional) add `seed.sql` later for sample data

## Requirements
- PostgreSQL 13+ (tested with 14+)
- Extensions: `pgcrypto`, `btree_gist`
  - Enabled in `schema.sql` via `CREATE EXTENSION IF NOT EXISTS ...`

## Entities Covered
- `users`, `properties`, `amenities`, `property_amenities`, `property_images`
- `bookings`, `booking_prices` (snapshot), `payments`, `reviews`

## Highlights
- **UUID** primary keys via `gen_random_uuid()`
- **ENUMs** for `booking_status`, `payment_status`, `user_role`
- **3NF-friendly**: snapshots kept in `booking_prices`
- **No overlapping bookings** per property using `EXCLUDE` constraint with range
- **Strict reviews**: one review per user per booking
- **Indexes** for FKs, ranges, and common filters

## How to Run
```bash
# 1) Create database (if needed)
createdb airbnb_clone

# 2) Apply schema
psql -d airbnb_clone -f schema.sql
