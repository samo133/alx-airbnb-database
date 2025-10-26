# ERD Requirements

**Repository:** `alx-airbnb-database`  
**Directory:** `ERD/`  
**File:** `requirements.md`  

## Scope
Design an Entity–Relationship Diagram (ERD) for the Airbnb Clone backend covering **Users, Properties, Bookings, Reviews, and Payments**. The diagram must show entities, attributes (key ones), and relationships with correct cardinalities.

---

## Entities & Attributes (Core)

### 1) Users
- `id` (PK, UUID)
- `username` (unique)
- `email` (unique)
- `password_hash`
- `role` (enum: guest, host, admin)
- `date_joined` (datetime)

### 2) Properties
- `id` (PK, UUID)
- `owner_id` (FK → Users.id)
- `title`
- `description`
- `location` (city/region/country or geo)
- `price_per_night` (decimal)
- `created_at` (datetime)

### 3) Bookings
- `id` (PK, UUID)
- `user_id` (FK → Users.id)  // guest
- `property_id` (FK → Properties.id)
- `check_in_date` (date)
- `check_out_date` (date)
- `status` (enum: pending, confirmed, cancelled)

### 4) Reviews
- `id` (PK, UUID)
- `user_id` (FK → Users.id)
- `property_id` (FK → Properties.id)
- `rating` (int 1–5)
- `comment`
- `created_at` (datetime)
> **Constraint:** Optional uniqueness (`user_id`, `property_id`) to limit one review per user per property (or per booking if tied).

### 5) Payments
- `id` (PK, UUID)
- `booking_id` (FK → Bookings.id)
- `user_id` (FK → Users.id)  // payer
- `amount` (decimal)
- `currency` (ISO code)
- `status` (enum: initiated, succeeded, failed, refunded)
- `provider_ref` (gateway token/id)
- `created_at` (datetime)

---

## Relationships (Cardinalities)

- **User 1 ──< Property** (a host can own many properties)  
- **User 1 ──< Booking** (a guest can make many bookings)  
- **Property 1 ──< Booking** (a property can be booked many times)  
- **User 1 ──< Review** (a user can write many reviews)  
- **Property 1 ──< Review** (a property can have many reviews)  
- **Booking 1 ──< Payment** (allow multiple payments/attempts per booking)

---

## ER Diagram 

```mermaid
erDiagram

  USERS ||--o{ PROPERTIES : "owns"
  USERS ||--o{ BOOKINGS : "makes"
  PROPERTIES ||--o{ BOOKINGS : "is booked in"
  USERS ||--o{ REVIEWS : "writes"
  PROPERTIES ||--o{ REVIEWS : "receives"
  BOOKINGS ||--o{ PAYMENTS : "paid by"

  USERS {
    UUID id PK
    string username
    string email
    string password_hash
    string role
    datetime date_joined
  }

  PROPERTIES {
    UUID id PK
    UUID owner_id FK
    string title
    string description
    string location
    decimal price_per_night
    datetime created_at
  }

  BOOKINGS {
    UUID id PK
    UUID user_id FK
    UUID property_id FK
    date check_in_date
    date check_out_date
    string status
  }

  REVIEWS {
    UUID id PK
    UUID user_id FK
    UUID property_id FK
    int rating
    string comment
    datetime created_at
  }

  PAYMENTS {
    UUID id PK
    UUID booking_id FK
    UUID user_id FK
    decimal amount
    string currency
    string status
    string provider_ref
    datetime created_at
  }
````

---

## Indexing & Constraints (Recommended)

* `USERS(email)`, `USERS(username)` unique indexes
* `PROPERTIES(owner_id)` index
* `BOOKINGS(property_id, check_in_date, check_out_date)` composite index
* `REVIEWS(property_id)` index; optional unique `(user_id, property_id)`
* `PAYMENTS(booking_id)`, `PAYMENTS(user_id)` indexes







