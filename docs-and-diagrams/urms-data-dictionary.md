# Data Dictionary

## Unified Restaurant Management System (URMS)

| Document Info | Details |
|---------------|---------|
| **Version** | 1.0 |
| **Database** | PostgreSQL 15+ |
| **Last Updated** | December 2024 |

---

## Table of Contents

1. [Schema Overview](#1-schema-overview)
2. [Enumerated Types](#2-enumerated-types)
3. [Core & Auth Module](#3-core--auth-module)
4. [CRM Module](#4-crm-module)
5. [Menu Module](#5-menu-module)
6. [Inventory Module](#6-inventory-module)
7. [Bookings & Tables Module](#7-bookings--tables-module)
8. [POS & Order Module](#8-pos--order-module)
9. [Logistics Module](#9-logistics-module)
10. [HRM Module](#10-hrm-module)
11. [CMS Module](#11-cms-module)
12. [Promotions & Loyalty Module](#12-promotions--loyalty-module)
13. [Database Constraints](#13-database-constraints)
14. [Indexes](#14-indexes)
15. [Triggers & Functions](#15-triggers--functions)

---

## 1. Schema Overview

### 1.1 Entity Count by Module

| Module | Tables | Primary Purpose |
|--------|--------|-----------------|
| Core & Auth | 4 | Multi-tenancy, users, notifications, auditing |
| CRM | 2 | Customer management and addresses |
| Menu | 5 | Product catalog and modifiers |
| Inventory | 6 | Stock tracking, recipes, purchasing |
| Bookings & Tables | 4 | Floor plans, tables, reservations |
| POS & Order | 6 | Transactions, payments, fiscal compliance |
| Logistics | 4 | Delivery zones, drivers, shipments |
| HRM | 2 | Shifts and time-off requests |
| CMS | 2 | Website pages and media |
| Promotions | 3 | Campaigns and loyalty points |
| **Total** | **38** | |

### 1.2 Required Extensions

| Extension | Purpose |
|-----------|---------|
| `uuid-ossp` | UUID generation |
| `postgis` | Geospatial queries for delivery zones |
| `pgcrypto` | Cryptographic functions for fiscal receipts |

---

## 2. Enumerated Types

### 2.1 User & Tenant Enums

| Type | Values | Description |
|------|--------|-------------|
| `user_role` | ADMIN, MANAGER, WAITER, KITCHEN, DRIVER | Staff role for RBAC |
| `tenant_status` | ACTIVE, SUSPENDED, TRIAL | Tenant subscription state |

### 2.2 Order & Payment Enums

| Type | Values | Description |
|------|--------|-------------|
| `order_status` | DRAFT, CONFIRMED, KITCHEN, READY, SERVED, PAID, COMPLETED, CANCELLED | Order state machine (FR-21) |
| `order_type` | DINE_IN, TAKEOUT, DELIVERY | Order fulfillment method |
| `order_item_status` | QUEUED, COOKING, DONE | Kitchen item progress (FR-24) |
| `payment_method` | CASH, CARD, QR, VOUCHER, SPLIT | Payment type |
| `transaction_status` | PENDING, COMPLETED, REFUNDED, FAILED | Payment state |

### 2.3 Inventory Enums

| Type | Values | Description |
|------|--------|-------------|
| `stock_action` | RESTOCK, DEDUCT_SALE, WASTE, AUDIT, TRANSFER | Stock log action (FR-20) |
| `unit_category` | MASS, VOLUME, COUNT | Ingredient unit type (FR-15) |
| `po_status` | DRAFT, SENT, PARTIAL, RECEIVED, CANCELLED | Purchase order state |

### 2.4 Reservation & Table Enums

| Type | Values | Description |
|------|--------|-------------|
| `reservation_status` | PENDING, CONFIRMED, SEATED, COMPLETED, NO_SHOW, CANCELLED | Booking state |
| `waitlist_status` | WAITING, NOTIFIED, SEATED, LEFT | Walk-in queue state |
| `table_shape` | CIRCLE, SQUARE, RECTANGLE | Canvas rendering shape (FR-28) |

### 2.5 Logistics Enums

| Type | Values | Description |
|------|--------|-------------|
| `driver_status` | OFFLINE, IDLE, ON_JOB | Driver availability (FR-34) |
| `shipment_status` | PENDING, ASSIGNED, PICKED_UP, IN_TRANSIT, DELIVERED, FAILED | Delivery state |

### 2.6 HRM Enums

| Type | Values | Description |
|------|--------|-------------|
| `shift_status` | SCHEDULED, CLOCKED_IN, COMPLETED, MISSED | Shift state |
| `time_off_type` | VACATION, SICK, PERSONAL | Leave request type |
| `approval_status` | PENDING, APPROVED, DENIED | Request approval state |

### 2.7 Promotions Enums

| Type | Values | Description |
|------|--------|-------------|
| `discount_type` | PERCENTAGE, FIXED, PROMO | Order discount type |
| `promo_type` | PERCENTAGE, FIXED, BOGO, FREE_ITEM | Campaign type |
| `loyalty_action` | EARN, REDEEM, EXPIRE, ADJUST | Points transaction type |

### 2.8 Other Enums

| Type | Values | Description |
|------|--------|-------------|
| `notification_type` | LOW_STOCK, RESERVATION, ORDER, SHIFT, SYSTEM | Alert category |

---

## 3. Core & Auth Module

### 3.1 core_tenant

Root entity for multi-tenancy. All business data is scoped to a tenant.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `name` | VARCHAR(255) | NO | - | Business name |
| `domain` | VARCHAR(255) | NO | - | Unique subdomain (FR-03) |
| `status` | tenant_status | NO | 'TRIAL' | Subscription state |
| `settings` | JSONB | NO | See DDL | Dynamic configuration (FR-02) |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |

**Settings JSON Schema:**
```json
{
  "currency_code": "USD",
  "currency_symbol": "$",
  "tax_rate": 0.0825,
  "timezone": "America/New_York",
  "grace_period_minutes": 15,
  "multi_order_dispatch": false,
  "reservation_buffer_minutes": 30,
  "auto_release_minutes": 15
}
```

**Constraints:**
- `uq_tenant_domain`: Unique domain per tenant

---

### 3.2 core_user

Staff members who interact with the system.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `name` | VARCHAR(255) | NO | - | Supplier name |
| `contact_name` | VARCHAR(255) | YES | - | Primary contact |
| `contact_email` | VARCHAR(255) | YES | - | Email address |
| `contact_phone` | VARCHAR(50) | YES | - | Phone number |
| `address` | TEXT | YES | - | Business address |
| `payment_terms` | VARCHAR(100) | YES | - | NET30, etc. |
| `notes` | TEXT | YES | - | Internal notes |
| `is_active` | BOOLEAN | NO | TRUE | Active status |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |

---

### 6.2 inv_ingredient

Raw stock items.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `supplier_id` | UUID | YES | - | FK to inv_supplier |
| `name` | VARCHAR(255) | NO | - | Ingredient name |
| `sku` | VARCHAR(100) | YES | - | Stock keeping unit |
| `unit` | VARCHAR(20) | NO | - | Base unit (FR-15) |
| `unit_category` | unit_category | NO | - | MASS/VOLUME/COUNT |
| `current_stock` | DECIMAL(12,4) | NO | 0 | Current quantity |
| `reorder_level` | DECIMAL(12,4) | NO | 0 | Alert threshold (FR-16) |
| `reorder_quantity` | DECIMAL(12,4) | YES | - | Suggested order qty |
| `cost_per_unit` | DECIMAL(10,4) | NO | 0 | Unit cost |
| `last_restocked_at` | TIMESTAMPTZ | YES | - | Last restock date |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |

**Constraints:**
- `uq_ingredient_sku_tenant`: Unique SKU per tenant
- `chk_ingredient_stock_positive`: current_stock >= 0

---

### 6.3 inv_recipe

Links menu items to ingredients.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `menu_item_id` | UUID | NO | - | FK to menu_item |
| `instruction_text` | TEXT | YES | - | Prep instructions |
| `yield_quantity` | INTEGER | NO | 1 | Portions per batch |
| `theoretical_cost` | DECIMAL(10,2) | YES | - | Calculated cost (FR-17) |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |

**Constraints:**
- `uq_recipe_menu_item`: One recipe per menu item

---

### 6.4 inv_recipe_item

Ingredient requirements per recipe.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `recipe_id` | UUID | NO | - | FK to inv_recipe |
| `ingredient_id` | UUID | NO | - | FK to inv_ingredient |
| `quantity_needed` | DECIMAL(12,4) | NO | - | Required amount |
| `unit` | VARCHAR(20) | NO | - | Unit for this recipe |

**Constraints:**
- `uq_recipe_ingredient`: Unique ingredient per recipe
- `chk_recipe_quantity_positive`: quantity_needed > 0

---

### 6.5 inv_stock_log

**IMMUTABLE** audit trail of stock movements (FR-19).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `ingredient_id` | UUID | NO | - | FK to inv_ingredient |
| `order_id` | UUID | YES | - | Source order (if sale) |
| `user_id` | UUID | YES | - | Actor |
| `action` | stock_action | NO | - | Action type (FR-20) |
| `quantity_change` | DECIMAL(12,4) | NO | - | +/- amount |
| `balance_after` | DECIMAL(12,4) | NO | - | Running balance |
| `unit_cost` | DECIMAL(10,4) | YES | - | Cost at time |
| `notes` | TEXT | YES | - | Reason/notes |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Event timestamp |

⚠️ **TRIGGER PROTECTED**: UPDATE and DELETE operations are blocked by database trigger.

---

### 6.6 inv_purchase_order

Orders to suppliers.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `supplier_id` | UUID | NO | - | FK to inv_supplier |
| `created_by` | UUID | NO | - | FK to core_user |
| `po_number` | VARCHAR(50) | NO | - | PO reference |
| `status` | po_status | NO | 'DRAFT' | Order state |
| `total_amount` | DECIMAL(12,2) | NO | 0 | Order total |
| `notes` | TEXT | YES | - | Instructions |
| `expected_delivery` | TIMESTAMPTZ | YES | - | ETA |
| `received_at` | TIMESTAMPTZ | YES | - | Actual receipt |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |

---

### 6.7 inv_purchase_order_item

Line items on purchase orders.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `purchase_order_id` | UUID | NO | - | FK to inv_purchase_order |
| `ingredient_id` | UUID | NO | - | FK to inv_ingredient |
| `quantity_ordered` | DECIMAL(12,4) | NO | - | Requested amount |
| `quantity_received` | DECIMAL(12,4) | YES | 0 | Actual received |
| `unit_cost` | DECIMAL(10,4) | NO | - | Agreed price |

---

## 7. Bookings & Tables Module

### 7.1 res_floor_plan

Restaurant floor layouts.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `name` | VARCHAR(255) | NO | - | Floor name |
| `width_px` | INTEGER | NO | 800 | Canvas width |
| `height_px` | INTEGER | NO | 600 | Canvas height |
| `background_image_url` | TEXT | YES | - | Floor plan image |
| `is_active` | BOOLEAN | NO | TRUE | Active status |
| `sort_order` | INTEGER | NO | 0 | Display order |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |

---

### 7.2 res_table

Physical tables.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `floor_id` | UUID | NO | - | FK to res_floor_plan |
| `table_number` | VARCHAR(20) | NO | - | Display number |
| `seat_capacity` | INTEGER | NO | 4 | Maximum seats |
| `min_capacity` | INTEGER | NO | 1 | Minimum party |
| `x_coord` | INTEGER | NO | 0 | Canvas X (FR-28) |
| `y_coord` | INTEGER | NO | 0 | Canvas Y (FR-28) |
| `shape` | table_shape | NO | 'SQUARE' | Render shape |
| `width_px` | INTEGER | NO | 60 | Table width |
| `height_px` | INTEGER | NO | 60 | Table height |
| `is_active` | BOOLEAN | NO | TRUE | Active status |

**Note**: Occupancy status is DERIVED, not stored (FR-29).

---

### 7.3 res_reservation

Table bookings.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `table_id` | UUID | NO | - | FK to res_table |
| `customer_id` | UUID | YES | - | FK to crm_customer |
| `confirmation_code` | VARCHAR(20) | NO | - | Booking reference |
| `guest_name` | VARCHAR(255) | YES | - | Non-member name |
| `guest_phone` | VARCHAR(50) | YES | - | Contact number |
| `guest_email` | VARCHAR(255) | YES | - | Contact email |
| `start_time` | TIMESTAMPTZ | NO | - | Reservation start |
| `end_time` | TIMESTAMPTZ | NO | - | Reservation end |
| `party_size` | INTEGER | NO | 2 | Guest count |
| `status` | reservation_status | NO | 'PENDING' | Booking state |
| `special_requests` | TEXT | YES | - | Guest notes |
| `source` | VARCHAR(50) | YES | 'PHONE' | Booking channel |
| `reminded_at` | TIMESTAMPTZ | YES | - | Reminder sent |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |

⚠️ **TRIGGER PROTECTED**: Double booking prevented by database trigger (FR-30).

---

### 7.4 res_waitlist

Walk-in queue management.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `customer_id` | UUID | YES | - | FK to crm_customer |
| `guest_name` | VARCHAR(255) | YES | - | Walk-in name |
| `guest_phone` | VARCHAR(50) | YES | - | Contact for SMS |
| `party_size` | INTEGER | NO | 2 | Guest count |
| `estimated_wait_minutes` | INTEGER | YES | - | Quoted wait |
| `status` | waitlist_status | NO | 'WAITING' | Queue state |
| `notes` | TEXT | YES | - | Special requests |
| `joined_at` | TIMESTAMPTZ | NO | NOW() | Queue entry |
| `notified_at` | TIMESTAMPTZ | YES | - | Table ready SMS |
| `seated_at` | TIMESTAMPTZ | YES | - | When seated |

---

## 8. POS & Order Module

### 8.1 pos_order

Customer order container.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `table_id` | UUID | YES | - | FK to res_table |
| `staff_id` | UUID | NO | - | FK to core_user |
| `customer_id` | UUID | YES | - | FK (nullable, FR-22) |
| `order_number` | VARCHAR(50) | NO | - | Human-readable ID |
| `status` | order_status | NO | 'DRAFT' | State machine (FR-21) |
| `order_type` | order_type | NO | 'DINE_IN' | Fulfillment type |
| `subtotal` | DECIMAL(12,2) | NO | 0 | Pre-tax total |
| `tax_amount` | DECIMAL(12,2) | NO | 0 | Tax total |
| `discount_amount` | DECIMAL(12,2) | NO | 0 | Discount total |
| `total_amount` | DECIMAL(12,2) | NO | 0 | Final total |
| `notes` | TEXT | YES | - | Order notes |
| `guests_count` | INTEGER | YES | 1 | Party size |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Order created |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modified |
| `completed_at` | TIMESTAMPTZ | YES | - | Order closed |

---

### 8.2 pos_order_item

Individual line items.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `order_id` | UUID | NO | - | FK to pos_order |
| `menu_item_id` | UUID | NO | - | FK to menu_item |
| `item_name_snapshot` | VARCHAR(255) | NO | - | Name at sale (FR-09) |
| `quantity` | INTEGER | NO | 1 | Quantity ordered |
| `unit_price` | DECIMAL(10,2) | NO | - | Price at sale (FR-09) |
| `modifiers_price` | DECIMAL(10,2) | NO | 0 | Modifier total |
| `line_total` | DECIMAL(10,2) | NO | - | qty × (unit + mods) |
| `active_modifiers` | JSONB | YES | '[]' | Snapshot (FR-23) |
| `status` | order_item_status | NO | 'QUEUED' | Kitchen state (FR-24) |
| `special_instructions` | TEXT | YES | - | Customer notes |
| `sent_to_kitchen_at` | TIMESTAMPTZ | YES | - | KDS sent time |
| `cooking_started_at` | TIMESTAMPTZ | YES | - | Prep started |
| `completed_at` | TIMESTAMPTZ | YES | - | Item ready |
| `voided_at` | TIMESTAMPTZ | YES | - | If voided |
| `void_reason` | TEXT | YES | - | Void explanation |

**active_modifiers JSON Schema:**
```json
[
  {
    "id": "uuid",
    "name": "Extra Cheese",
    "price": 1.50,
    "group_name": "Toppings"
  }
]
```

---

### 8.3 pos_order_discount

Discounts applied to orders.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `order_id` | UUID | NO | - | FK to pos_order |
| `discount_type` | discount_type | NO | - | Discount category |
| `code` | VARCHAR(50) | YES | - | Promo code used |
| `description` | VARCHAR(255) | YES | - | Discount name |
| `value` | DECIMAL(10,2) | NO | - | Percentage or amount |
| `amount_applied` | DECIMAL(10,2) | NO | - | Actual discount |
| `applied_by` | UUID | YES | - | FK to core_user |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Applied timestamp |

---

### 8.4 pos_transaction

Payment records.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `order_id` | UUID | NO | - | FK to pos_order |
| `processed_by` | UUID | NO | - | FK to core_user |
| `amount` | DECIMAL(12,2) | NO | - | Payment amount |
| `tip_amount` | DECIMAL(10,2) | NO | 0 | Tip (FR-26) |
| `method` | payment_method | NO | - | Payment type |
| `status` | transaction_status | NO | 'PENDING' | Payment state |
| `gateway_ref` | VARCHAR(255) | YES | - | External reference |
| `gateway_response` | JSONB | YES | - | Gateway data |
| `card_last_four` | VARCHAR(4) | YES | - | Card identifier |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Payment time |

**Note**: Multiple transactions per order allowed (FR-25 split bills).

---

### 8.5 pos_refund

Refund records.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `transaction_id` | UUID | NO | - | FK to pos_transaction |
| `approved_by` | UUID | NO | - | FK to core_user |
| `amount` | DECIMAL(12,2) | NO | - | Refund amount |
| `reason` | TEXT | NO | - | Refund reason |
| `gateway_ref` | VARCHAR(255) | YES | - | Gateway reference |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Refund time |

---

### 8.6 pos_fiscal_receipt

Legal compliance records (FR-27).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `transaction_id` | UUID | NO | - | FK to pos_transaction |
| `receipt_number` | VARCHAR(50) | NO | - | Sequential number |
| `fiscal_signature` | VARCHAR(64) | NO | - | SHA-256 hash |
| `previous_hash` | VARCHAR(64) | YES | - | Chain link |
| `raw_data_snapshot` | JSONB | NO | - | Complete receipt data |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Generation time |

**Hash Chain Formula:**
```
hash[N] = SHA256(transaction_data + hash[N-1] + timestamp)
```

---

## 9. Logistics Module

### 9.1 log_delivery_zone

Geographic delivery areas (FR-32).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `name` | VARCHAR(255) | NO | - | Zone name |
| `polygon` | GEOMETRY(POLYGON) | NO | - | GeoJSON boundary |
| `area_sqkm` | DECIMAL(10,4) | YES | - | For precedence (FR-33) |
| `delivery_fee` | DECIMAL(10,2) | NO | 0 | Zone fee |
| `min_order_amount` | DECIMAL(10,2) | YES | 0 | Minimum order |
| `estimated_minutes` | INTEGER | YES | - | Delivery ETA |
| `is_active` | BOOLEAN | NO | TRUE | Zone status |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |

---

### 9.2 log_driver

Delivery personnel.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `user_id` | UUID | NO | - | FK to core_user |
| `vehicle_type` | VARCHAR(50) | YES | - | BIKE/SCOOTER/CAR |
| `license_plate` | VARCHAR(50) | YES | - | Vehicle ID |
| `current_lat` | DECIMAL(10,8) | YES | - | GPS latitude |
| `current_lng` | DECIMAL(11,8) | YES | - | GPS longitude |
| `status` | driver_status | NO | 'OFFLINE' | Availability (FR-34) |
| `active_order_count` | INTEGER | NO | 0 | Current assignments |
| `rating_avg` | DECIMAL(3,2) | YES | - | Customer rating |
| `total_deliveries` | INTEGER | NO | 0 | Lifetime count |
| `last_location_update` | TIMESTAMPTZ | YES | - | GPS timestamp |

---

### 9.3 log_shipment

Delivery assignments.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `order_id` | UUID | NO | - | FK to pos_order |
| `driver_id` | UUID | YES | - | FK to log_driver |
| `zone_id` | UUID | YES | - | FK to log_delivery_zone |
| `tracking_code` | VARCHAR(50) | NO | - | Customer tracking |
| `delivery_address` | TEXT | NO | - | Destination |
| `delivery_lat` | DECIMAL(10,8) | YES | - | Destination lat |
| `delivery_lng` | DECIMAL(11,8) | YES | - | Destination lng |
| `delivery_fee` | DECIMAL(10,2) | NO | 0 | Charged fee |
| `status` | shipment_status | NO | 'PENDING' | Delivery state |
| `delivery_instructions` | TEXT | YES | - | Customer notes |
| `recipient_name` | VARCHAR(255) | YES | - | Recipient |
| `recipient_phone` | VARCHAR(50) | YES | - | Contact number |
| `assigned_at` | TIMESTAMPTZ | YES | - | Driver assigned |
| `picked_up_at` | TIMESTAMPTZ | YES | - | Left restaurant |
| `delivered_at` | TIMESTAMPTZ | YES | - | Delivery complete |
| `proof_photo_url` | TEXT | YES | - | POD image (FR-35) |
| `failure_reason` | TEXT | YES | - | If failed |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |

---

### 9.4 log_driver_location

GPS tracking history.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `driver_id` | UUID | NO | - | FK to log_driver |
| `shipment_id` | UUID | YES | - | Associated delivery |
| `latitude` | DECIMAL(10,8) | NO | - | GPS lat |
| `longitude` | DECIMAL(11,8) | NO | - | GPS lng |
| `accuracy_meters` | DECIMAL(8,2) | YES | - | GPS accuracy |
| `recorded_at` | TIMESTAMPTZ | NO | NOW() | Timestamp |

---

## 10. HRM Module

### 10.1 hrm_shift

Staff scheduling and time tracking.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `user_id` | UUID | NO | - | FK to core_user |
| `scheduled_start` | TIMESTAMPTZ | NO | - | Planned start |
| `scheduled_end` | TIMESTAMPTZ | NO | - | Planned end |
| `actual_clock_in` | TIMESTAMPTZ | YES | - | Actual start (FR-36) |
| `actual_clock_out` | TIMESTAMPTZ | YES | - | Actual end |
| `status` | shift_status | NO | 'SCHEDULED' | Shift state |
| `is_late` | BOOLEAN | NO | FALSE | Lateness flag (FR-37) |
| `late_minutes` | INTEGER | YES | 0 | Minutes late |
| `break_minutes` | INTEGER | YES | 0 | Break duration |
| `notes` | TEXT | YES | - | Shift notes |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |

⚠️ **TRIGGER PROTECTED**: Lateness auto-calculated on clock-in (FR-37).

---

### 10.2 hrm_time_off_request

Leave requests.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `user_id` | UUID | NO | - | FK to core_user |
| `approved_by` | UUID | YES | - | FK to core_user |
| `type` | time_off_type | NO | - | Leave type |
| `start_date` | DATE | NO | - | First day off |
| `end_date` | DATE | NO | - | Last day off |
| `status` | approval_status | NO | 'PENDING' | Request state |
| `reason` | TEXT | YES | - | Request reason |
| `response_notes` | TEXT | YES | - | Manager notes |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Request submitted |
| `responded_at` | TIMESTAMPTZ | YES | - | Decision timestamp |

---

## 11. CMS Module

### 11.1 cms_page

Website pages.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `slug` | VARCHAR(100) | NO | - | URL path (FR-38) |
| `title` | VARCHAR(255) | NO | - | Page title |
| `meta_description` | TEXT | YES | - | SEO description |
| `content_blocks` | JSONB | NO | '[]' | Components (FR-39) |
| `is_published` | BOOLEAN | NO | FALSE | Visibility |
| `published_at` | TIMESTAMPTZ | YES | - | Publish timestamp |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |

**Constraints:**
- `uq_page_slug_tenant`: Unique slug per tenant
- `chk_page_slug_format`: Lowercase alphanumeric + hyphens

---

### 11.2 cms_media

Uploaded files.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `filename` | VARCHAR(255) | NO | - | Storage filename |
| `original_filename` | VARCHAR(255) | YES | - | Upload filename |
| `mime_type` | VARCHAR(100) | NO | - | Content type |
| `storage_url` | TEXT | NO | - | CDN/S3 URL |
| `file_size_bytes` | INTEGER | YES | - | File size |
| `width_px` | INTEGER | YES | - | Image width |
| `height_px` | INTEGER | YES | - | Image height |
| `alt_text` | VARCHAR(255) | YES | - | Accessibility text |
| `uploaded_by` | UUID | YES | - | FK to core_user |
| `uploaded_at` | TIMESTAMPTZ | NO | NOW() | Upload timestamp |

---

## 12. Promotions & Loyalty Module

### 12.1 promo_campaign

Promotional campaigns.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `name` | VARCHAR(255) | NO | - | Campaign name |
| `code` | VARCHAR(50) | YES | - | Promo code |
| `description` | TEXT | YES | - | Public description |
| `type` | promo_type | NO | - | Discount type |
| `value` | DECIMAL(10,2) | NO | - | Discount value |
| `min_order_amount` | DECIMAL(10,2) | YES | 0 | Minimum spend |
| `max_discount_amount` | DECIMAL(10,2) | YES | - | Cap on discount |
| `max_uses` | INTEGER | YES | - | Total redemptions |
| `max_uses_per_customer` | INTEGER | YES | - | Per-customer limit |
| `current_uses` | INTEGER | NO | 0 | Redemption count |
| `valid_from` | TIMESTAMPTZ | NO | - | Start date |
| `valid_until` | TIMESTAMPTZ | YES | - | End date |
| `is_active` | BOOLEAN | NO | TRUE | Active status |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |

---

### 12.2 promo_campaign_item

Campaign targeting (items/categories).

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `campaign_id` | UUID | NO | - | FK to promo_campaign |
| `menu_item_id` | UUID | YES | - | FK to menu_item |
| `category_id` | UUID | YES | - | FK to menu_category |

**Note**: NULL for both = applies to entire menu.

---

### 12.3 loyalty_transaction

Points ledger.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `customer_id` | UUID | NO | - | FK to crm_customer |
| `order_id` | UUID | YES | - | FK to pos_order |
| `type` | loyalty_action | NO | - | Transaction type |
| `points` | INTEGER | NO | - | +/- points |
| `balance_after` | INTEGER | NO | - | Running balance |
| `description` | VARCHAR(255) | YES | - | Transaction note |
| `expires_at` | TIMESTAMPTZ | YES | - | Expiration date |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Transaction time |

---

## 13. Database Constraints

### 13.1 Check Constraints

| Table | Constraint | Rule |
|-------|------------|------|
| `menu_item` | `chk_item_price_positive` | price >= 0 |
| `menu_item` | `chk_item_cost_positive` | cost_price >= 0 OR NULL |
| `menu_modifier_group` | `chk_modifier_selection` | min <= max |
| `inv_ingredient` | `chk_ingredient_stock_positive` | current_stock >= 0 |
| `inv_recipe_item` | `chk_recipe_quantity_positive` | quantity > 0 |
| `res_table` | `chk_table_capacity` | min <= max capacity |
| `res_reservation` | `chk_reservation_time` | end > start |
| `pos_order` | `chk_order_amounts_positive` | all amounts >= 0 |
| `pos_order_item` | `chk_order_item_quantity` | quantity >= 1 |
| `pos_transaction` | `chk_transaction_amount_positive` | amount > 0 |
| `hrm_shift` | `chk_shift_time` | end > start |
| `hrm_shift` | `chk_shift_clock_in_not_future` | clock_in <= NOW() |
| `cms_page` | `chk_page_slug_format` | lowercase + hyphens only |

### 13.2 Unique Constraints

| Table | Constraint | Columns |
|-------|------------|---------|
| `core_tenant` | `uq_tenant_domain` | domain |
| `core_user` | `uq_user_email_tenant` | (tenant_id, email) |
| `menu_item_modifier_group_link` | `uq_item_modifier_group` | (item_id, group_id) |
| `inv_ingredient` | `uq_ingredient_sku_tenant` | (tenant_id, sku) |
| `inv_recipe` | `uq_recipe_menu_item` | menu_item_id |
| `inv_purchase_order` | `uq_po_number_tenant` | (tenant_id, po_number) |
| `res_table` | `uq_table_number_floor` | (floor_id, table_number) |
| `res_reservation` | `uq_reservation_code_tenant` | (tenant_id, confirmation_code) |
| `pos_order` | `uq_order_number_tenant` | (tenant_id, order_number) |
| `pos_fiscal_receipt` | `uq_fiscal_receipt_number` | receipt_number |
| `log_shipment` | `uq_shipment_tracking` | tracking_code |
| `cms_page` | `uq_page_slug_tenant` | (tenant_id, slug) |
| `promo_campaign` | `uq_promo_code_tenant` | (tenant_id, code) |

---

## 14. Indexes

### 14.1 Performance Indexes

| Table | Index | Columns | Condition |
|-------|-------|---------|-----------|
| `core_user` | `idx_user_tenant` | tenant_id | deleted_at IS NULL |
| `menu_category` | `idx_category_tenant_active` | (tenant_id, sort_order) | active & not deleted |
| `menu_item` | `idx_item_tenant_available` | (tenant_id, is_available) | not deleted |
| `inv_ingredient` | `idx_ingredient_low_stock` | tenant_id | stock < reorder |
| `pos_order` | `idx_order_tenant_status` | (tenant_id, status) | - |
| `pos_order` | `idx_order_table` | table_id | open orders only |
| `pos_order_item` | `idx_order_item_status` | status | not DONE |
| `res_reservation` | `idx_reservation_table_time` | (table_id, times) | active only |
| `log_delivery_zone` | `idx_delivery_zone_geo` | polygon (GIST) | - |
| `log_driver` | `idx_driver_tenant_status` | (tenant_id, status) | - |

---

## 15. Triggers & Functions

### 15.1 Automatic Triggers

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `trg_*_updated_at` | Multiple | UPDATE | Auto-update timestamp |
| `trg_stock_log_immutable_*` | inv_stock_log | UPDATE/DELETE | Block modifications (FR-19) |
| `trg_reservation_conflict_check` | res_reservation | INSERT/UPDATE | Prevent double booking (FR-30) |
| `trg_shift_lateness_check` | hrm_shift | UPDATE | Auto-flag late shifts (FR-37) |

### 15.2 Utility Functions

| Function | Purpose |
|----------|---------|
| `update_updated_at_column()` | Set updated_at to NOW() |
| `prevent_stock_log_modification()` | Raise exception on stock log changes |
| `check_reservation_conflict()` | Validate no time overlap |
| `check_shift_lateness()` | Calculate late_minutes |
| `generate_order_number(tenant_id)` | Create sequential order number |
| `calculate_recipe_cost(recipe_id)` | Sum ingredient costs (FR-17) |

---

## Appendix A: JSON Schema Reference

### A.1 Tenant Settings
```json
{
  "currency_code": "string (ISO 4217)",
  "currency_symbol": "string",
  "tax_rate": "decimal",
  "timezone": "string (IANA)",
  "grace_period_minutes": "integer",
  "multi_order_dispatch": "boolean"
}
```

### A.2 Active Modifiers Snapshot
```json
[
  {
    "id": "uuid",
    "name": "string",
    "price": "decimal",
    "group_name": "string"
  }
]
```

### A.3 CMS Content Blocks
```json
[
  {
    "type": "hero|menu_grid|text_block",
    "props": { }
  }
]
```

---

*Document generated for URMS v1.0* | - | FK to core_tenant |
| `email` | VARCHAR(255) | NO | - | Login email |
| `password_hash` | VARCHAR(255) | NO | - | Bcrypt hash |
| `first_name` | VARCHAR(100) | YES | - | Given name |
| `last_name` | VARCHAR(100) | YES | - | Family name |
| `phone` | VARCHAR(50) | YES | - | Contact number |
| `role` | user_role | NO | 'WAITER' | RBAC role (FR-04) |
| `is_active` | BOOLEAN | NO | TRUE | Account status |
| `last_login_at` | TIMESTAMPTZ | YES | - | Last authentication |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |
| `deleted_at` | TIMESTAMPTZ | YES | - | Soft delete (FR-10) |

**Constraints:**
- `uq_user_email_tenant`: Unique email per tenant
- FK to `core_tenant` with CASCADE delete

---

### 3.3 core_notification

System alerts and notifications.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `user_id` | UUID | YES | - | Target user (null = broadcast) |
| `type` | notification_type | NO | - | Alert category |
| `title` | VARCHAR(255) | NO | - | Notification headline |
| `message` | TEXT | YES | - | Detailed message |
| `metadata` | JSONB | YES | '{}' | Additional context |
| `is_read` | BOOLEAN | NO | FALSE | Read status |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |

---

### 3.4 core_audit_log

Immutable audit trail for compliance.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `user_id` | UUID | YES | - | Actor (null = system) |
| `entity_type` | VARCHAR(100) | NO | - | Table name |
| `entity_id` | UUID | NO | - | Record ID |
| `action` | VARCHAR(50) | NO | - | CREATE/UPDATE/DELETE |
| `old_values` | JSONB | YES | - | Previous state |
| `new_values` | JSONB | YES | - | New state |
| `ip_address` | INET | YES | - | Client IP |
| `user_agent` | TEXT | YES | - | Browser/client info |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Event timestamp |

---

## 4. CRM Module

### 4.1 crm_customer

Customer records for loyalty and marketing.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `first_name` | VARCHAR(100) | YES | - | Given name |
| `last_name` | VARCHAR(100) | YES | - | Family name |
| `email` | VARCHAR(255) | YES | - | Contact email |
| `phone` | VARCHAR(50) | YES | - | Contact number |
| `default_address` | TEXT | YES | - | Primary address |
| `preferences` | JSONB | YES | See below | Allergies, favorites |
| `loyalty_points` | INTEGER | NO | 0 | Current point balance |
| `total_spent` | DECIMAL(12,2) | NO | 0.00 | Lifetime value |
| `visit_count` | INTEGER | NO | 0 | Total visits |
| `first_visit` | TIMESTAMPTZ | YES | - | First order date |
| `last_visit` | TIMESTAMPTZ | YES | - | Most recent order |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |

**Preferences JSON Schema:**
```json
{
  "allergies": ["peanuts", "shellfish"],
  "favorites": ["uuid-item-1", "uuid-item-2"],
  "dietary": "vegetarian",
  "notes": "Birthday: March 15"
}
```

---

### 4.2 crm_customer_address

Multiple delivery addresses per customer.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `customer_id` | UUID | NO | - | FK to crm_customer |
| `label` | VARCHAR(50) | NO | 'Home' | Address nickname |
| `address_line1` | TEXT | NO | - | Street address |
| `address_line2` | TEXT | YES | - | Apt, suite, etc. |
| `city` | VARCHAR(100) | YES | - | City |
| `state` | VARCHAR(100) | YES | - | State/province |
| `postal_code` | VARCHAR(20) | YES | - | ZIP/postal code |
| `country` | VARCHAR(100) | YES | 'USA' | Country |
| `latitude` | DECIMAL(10,8) | YES | - | Geocoded lat |
| `longitude` | DECIMAL(11,8) | YES | - | Geocoded lng |
| `is_default` | BOOLEAN | NO | FALSE | Primary address flag |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |

---

## 5. Menu Module

### 5.1 menu_category

Grouping for menu items.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `name` | VARCHAR(255) | NO | - | Category name |
| `description` | TEXT | YES | - | Category description |
| `image_url` | TEXT | YES | - | Category image |
| `sort_order` | INTEGER | NO | 0 | Display order (FR-06) |
| `is_active` | BOOLEAN | NO | TRUE | Visibility flag |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |
| `deleted_at` | TIMESTAMPTZ | YES | - | Soft delete |

---

### 5.2 menu_item

Sellable products.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `category_id` | UUID | NO | - | FK to menu_category |
| `name` | VARCHAR(255) | NO | - | Item name |
| `description` | TEXT | YES | - | Item description |
| `image_url` | TEXT | YES | - | Product image |
| `price` | DECIMAL(10,2) | NO | - | Selling price |
| `cost_price` | DECIMAL(10,2) | YES | - | Cost for margin calc |
| `is_available` | BOOLEAN | NO | TRUE | 86'd switch (FR-08) |
| `taxes` | JSONB | YES | '[]' | Applicable tax rules |
| `allergens` | JSONB | YES | '[]' | Allergen warnings |
| `nutritional_info` | JSONB | YES | - | Calories, macros |
| `prep_time_minutes` | INTEGER | YES | - | Estimated prep time |
| `sort_order` | INTEGER | NO | 0 | Display order |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NO | NOW() | Last modification |
| `deleted_at` | TIMESTAMPTZ | YES | - | Soft delete (FR-10) |

**Constraints:**
- `chk_item_price_positive`: price >= 0
- `chk_item_cost_positive`: cost_price >= 0 OR NULL
- FK to category with RESTRICT delete (FR-07)

---

### 5.3 menu_modifier_group

Customization groups (e.g., "Steak Temperature").

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO | - | FK to core_tenant |
| `name` | VARCHAR(255) | NO | - | Group name |
| `description` | TEXT | YES | - | Instructions |
| `min_selection` | INTEGER | NO | 0 | Minimum choices (FR-11) |
| `max_selection` | INTEGER | NO | 1 | Maximum choices (FR-11) |
| `is_required` | BOOLEAN | NO | FALSE | Must select flag |
| `sort_order` | INTEGER | NO | 0 | Display order |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |

**Constraints:**
- `chk_modifier_selection`: min_selection <= max_selection
- `chk_modifier_min_positive`: min_selection >= 0

---

### 5.4 menu_modifier

Individual modifier options.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `group_id` | UUID | NO | - | FK to menu_modifier_group |
| `name` | VARCHAR(255) | NO | - | Option name |
| `price_adjustment` | DECIMAL(10,2) | NO | 0.00 | Price add/subtract |
| `is_available` | BOOLEAN | NO | TRUE | Availability flag |
| `sort_order` | INTEGER | NO | 0 | Display order |
| `created_at` | TIMESTAMPTZ | NO | NOW() | Record creation |

---

### 5.5 menu_item_modifier_group_link

Many-to-many: Items ↔ Modifier Groups.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `item_id` | UUID | NO | - | FK to menu_item |
| `group_id` | UUID | NO | - | FK to menu_modifier_group |
| `override_price` | DECIMAL(10,2) | YES | - | Item-specific price (FR-13) |
| `sort_order` | INTEGER | NO | 0 | Display order |

**Constraints:**
- `uq_item_modifier_group`: Unique (item_id, group_id)

---

## 6. Inventory Module

### 6.1 inv_supplier

External vendors.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NO | uuid_generate_v4() | Primary key |
| `tenant_id` | UUID | NO