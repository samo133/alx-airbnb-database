# Seed Data — Airbnb Clone

This folder contains **realistic sample data** for the Airbnb Clone schema.

## Files
- `seed.sql` — Inserts users, amenities, properties, images, property_amenities, bookings (non-overlapping), booking price snapshots, payments (multiple attempts), and reviews (per booking).

## Prerequisites
- Run the schema first:
  - `database-script-0x01/schema.sql` (ensures tables, enums, extensions)
- PostgreSQL 13+ (14+ recommended)

## How to Load
```bash
# Ensure DB exists and schema is applied
psql -d airbnb_clone -f ../database-script-0x01/schema.sql

# Seed the data
psql -d airbnb_clone -f seed.sql
