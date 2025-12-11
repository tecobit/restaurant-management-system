# Functional Requirements Document (FRD)

## Project: Unified Restaurant Management System (URMS)

| Document Info | Details |
|---------------|---------|
| **Version** | 1.0 |
| **Status** | Approved for Development |
| **Last Updated** | December 2024 |
| **Document Owner** | Engineering Team |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Core & Auth Module](#2-core--auth-module)
3. [Menu Module](#3-menu-module)
4. [Inventory Module](#4-inventory-module)
5. [POS & Order Module](#5-pos--order-module)
6. [Bookings & Tables Module](#6-bookings--tables-module)
7. [Logistics Module](#7-logistics-module)
8. [HRM Module](#8-hrm-module)
9. [CMS Module](#9-cms-module)
10. [Appendix](#10-appendix)

---

## 1. Introduction

### 1.1 Purpose

This document defines the functional requirements for all database entities within the Unified Restaurant Management System (URMS). It serves as the authoritative source for development, testing, and validation of system behavior.

### 1.2 Scope

URMS is a multi-tenant SaaS platform providing end-to-end restaurant operations management including point-of-sale, inventory tracking, reservations, delivery logistics, staff management, and content management.

### 1.3 Definitions & Acronyms

| Term | Definition |
|------|------------|
| **Tenant** | A single restaurant business or franchise location |
| **POS** | Point of Sale |
| **KDS** | Kitchen Display System |
| **RBAC** | Role-Based Access Control |
| **86'd** | Industry term for an unavailable menu item |

### 1.4 Requirement Priority Levels

| Priority | Description |
|----------|-------------|
| **P0** | Critical - System cannot function without this |
| **P1** | High - Core business functionality |
| **P2** | Medium - Important but not blocking |
| **P3** | Low - Nice to have |

---

## 2. Core & Auth Module

The foundation for multi-tenancy, security, and user management.

### 2.1 Entity: CORE_Tenant

Represents a single restaurant business or franchise location.

#### FR-01: Multi-Tenancy Enforcement

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Security |

**Requirement:** The system MUST treat the `id` field of this table as the "Root Scope." All subsequent database queries for orders, inventory, and users MUST be filtered by this ID to ensure complete data isolation between tenants.

**Acceptance Criteria:**
- [ ] Every API endpoint includes tenant_id validation middleware
- [ ] Database queries are automatically scoped via ORM interceptors
- [ ] Cross-tenant data access attempts return `403 Forbidden`
- [ ] Audit logs capture any tenant boundary violation attempts

#### FR-02: Dynamic Settings

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Configuration |

**Requirement:** The `settings` JSON field MUST store configuration values that can be updated by the Admin without requiring database migrations.

**Required Settings Schema:**
```json
{
  "currency_symbol": "string",
  "currency_code": "string (ISO 4217)",
  "tax_rate": "decimal",
  "time_zone": "string (IANA)",
  "grace_period_minutes": "integer",
  "multi_order_dispatch": "boolean"
}
```

**Acceptance Criteria:**
- [ ] Settings are validated against JSON schema before persistence
- [ ] Invalid settings return descriptive validation errors
- [ ] Settings changes are logged in audit trail
- [ ] Default values are applied for missing optional settings

#### FR-03: Domain Routing

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Infrastructure |

**Requirement:** The `domain` field MUST be unique across all tenants. The middleware layer MUST use this domain to resolve the Tenant ID before processing any HTTP request.

**Acceptance Criteria:**
- [ ] Database enforces unique constraint on `domain` field
- [ ] Middleware extracts domain from `Host` header
- [ ] Unrecognized domains return `404 Not Found`
- [ ] Domain resolution is cached with TTL of 5 minutes
- [ ] Domain changes propagate within cache TTL window

---

### 2.2 Entity: CORE_User

Represents any staff member interacting with the system.

#### FR-04: Role-Based Access Control

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Security |

**Requirement:** The `role` field MUST restrict API access according to the following permission matrix:

| Role | Orders | Inventory | Reports | KDS | Global Settings |
|------|--------|-----------|---------|-----|-----------------|
| **Admin** | Full | Full | Full | Full | Full |
| **Manager** | Full | Read/Write | Read/Write | Full | None |
| **Waiter** | Create/Edit | None | None | None | None |
| **Kitchen** | Read | None | None | Read | None |

**Acceptance Criteria:**
- [ ] Role validation occurs at API gateway level
- [ ] Unauthorized access attempts return `403 Forbidden`
- [ ] Role changes require Admin privileges
- [ ] Failed authorization attempts are logged with user context

#### FR-05: Tenant Scoping

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Security |

**Requirement:** Users MUST be strictly linked to a `tenant_id`. A user from Tenant A CANNOT authenticate or access data belonging to Tenant B under any circumstances.

**Acceptance Criteria:**
- [ ] Authentication tokens include tenant_id claim
- [ ] Token validation verifies tenant_id matches request context
- [ ] Cross-tenant authentication attempts are blocked and logged
- [ ] User creation requires valid tenant_id foreign key

---

## 3. Menu Module

The central catalog of products sold by the restaurant.

### 3.1 Entity: MENU_Category

Grouping for menu items (e.g., "Starters", "Beverages").

#### FR-06: Display Order

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | User Experience |

**Requirement:** The API MUST always return categories sorted by the `sort_order` integer field in ascending order, NOT by creation date or ID.

**Acceptance Criteria:**
- [ ] Default API response sorts by `sort_order ASC`
- [ ] Null `sort_order` values are treated as `MAX_INT` (appear last)
- [ ] Admin UI provides drag-and-drop reordering
- [ ] Reordering updates `sort_order` values atomically

#### FR-07: Deletion Constraint

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Data Integrity |

**Requirement:** The system MUST prevent deletion of a Category if it contains active `MENU_Item` records. The user MUST be prompted to reassign items first.

**Acceptance Criteria:**
- [ ] DELETE request returns `409 Conflict` if active items exist
- [ ] Error response includes count of blocking items
- [ ] API provides endpoint to bulk reassign items
- [ ] Soft-deleted items do not block category deletion

---

### 3.2 Entity: MENU_Item

A sellable product (e.g., "Cheeseburger").

#### FR-08: Availability Override

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Operations |

**Requirement:** The `is_available` boolean acts as a manual "86'd" switch. When set to `False`, the item MUST be hidden from POS and Online Ordering interfaces immediately, regardless of inventory levels.

**Acceptance Criteria:**
- [ ] Setting `is_available = false` triggers real-time UI update
- [ ] Unavailable items excluded from menu API responses
- [ ] POS search does not return unavailable items
- [ ] Manager+ roles can toggle availability
- [ ] Availability changes logged with timestamp and user

#### FR-09: Price Stability

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Financial Integrity |

**Requirement:** Changes to the `price` field MUST NOT retroactively affect historical `POS_Order` records. Historical financial data MUST remain immutable.

**Acceptance Criteria:**
- [ ] Order items store `unit_price` at time of sale
- [ ] Price changes do not trigger order recalculations
- [ ] Historical reports reflect original transaction prices
- [ ] Price change history maintained in audit log

#### FR-10: Soft Deletes

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Data Integrity |

**Requirement:** Items MUST NEVER be hard-deleted from the database to preserve historical analytics. Use a `deleted_at` timestamp instead.

**Acceptance Criteria:**
- [ ] DELETE endpoint sets `deleted_at` timestamp
- [ ] Default queries exclude soft-deleted records
- [ ] Admin can view/restore soft-deleted items
- [ ] Soft-deleted items visible in historical reports

---

### 3.3 Entity: MENU_ModifierGroup & MENU_Modifier

Customizations (e.g., "Steak Temperature", "Extra Toppings").

#### FR-11: Selection Constraints

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | User Experience |

**Requirement:** The POS UI MUST enforce the `min_selection` and `max_selection` rules defined in `MENU_ModifierGroup`.

**Constraint Rules:**

| Scenario | Behavior |
|----------|----------|
| `min_selection = 1` | "Add to Cart" button disabled until selection made |
| `max_selection = 2` | Selecting 3rd option auto-deselects 1st OR blocks action |
| `min_selection = max_selection` | Exact number required |

**Acceptance Criteria:**
- [ ] UI validates constraints before allowing cart addition
- [ ] API validates constraints on order submission
- [ ] Clear error messaging for constraint violations
- [ ] Constraints displayed to user during selection

---

### 3.4 Entity: MENU_Item_ModifierGroup_Link

Association table linking Items to Modifier Groups.

#### FR-12: Many-to-Many Reusability

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Data Architecture |

**Requirement:** This entity MUST allow a single Modifier Group to be attached to multiple distinct Menu Items.

**Example:** "Standard Pizza Toppings" group attached to: Margherita, Pepperoni, Hawaiian pizzas.

**Acceptance Criteria:**
- [ ] No unique constraint on `modifier_group_id`
- [ ] Unique constraint on (`item_id`, `modifier_group_id`) pair
- [ ] Deleting modifier group cascades to remove links
- [ ] UI displays shared modifier groups appropriately

#### FR-13: Override Capability

| Attribute | Value |
|-----------|-------|
| **Priority** | P2 |
| **Category** | Pricing Flexibility |

**Requirement:** This link MAY store an `override_price` if a specific modifier costs differently on a specific item.

**Example:** "Extra Cheese" costs $1.00 on Small Pizza but $1.50 on Large Pizza.

**Acceptance Criteria:**
- [ ] `override_price` field is nullable
- [ ] NULL value defaults to modifier's base price
- [ ] Override price used in cost calculations
- [ ] UI indicates when override pricing is active

---

## 4. Inventory Module

The engine for stock tracking and recipe management.

### 4.1 Entity: INV_Supplier

External vendors who provide raw ingredients.

#### FR-14: Restocking Workflow

| Attribute | Value |
|-----------|-------|
| **Priority** | P2 |
| **Category** | Operations |

**Requirement:** The system MUST store `contact_info` (email/phone) to facilitate auto-generation of Purchase Orders when stock runs low.

**Acceptance Criteria:**
- [ ] Contact info validated for email/phone format
- [ ] Purchase Order PDF template includes supplier details
- [ ] One-click email sending from low stock alerts
- [ ] Supplier contact history tracked

---

### 4.2 Entity: INV_Ingredient

Raw stock items (e.g., "Flour", "Tomato Sauce").

#### FR-15: Unit Management

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Data Integrity |

**Requirement:** The `unit` field defines the "Base Unit." All recipes MUST convert to this unit. The system MUST reject transactions attempting incompatible unit operations.

**Supported Units:**

| Category | Units |
|----------|-------|
| **Mass** | kg, g, lb, oz |
| **Volume** | L, mL, gal, fl_oz |
| **Count** | pcs, dozen |

**Acceptance Criteria:**
- [ ] System maintains unit conversion factors
- [ ] Incompatible operations return `422 Unprocessable Entity`
- [ ] Error message specifies incompatible units
- [ ] Recipe items auto-convert to ingredient base unit

#### FR-16: Low Stock Triggers

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Operations |

**Requirement:** A background worker MUST run periodically. When `current_stock < reorder_level`, an alert MUST be generated in the `CORE_Notification` system.

**Acceptance Criteria:**
- [ ] Worker runs every 15 minutes (configurable)
- [ ] Single alert per ingredient per threshold breach
- [ ] Alert cleared when stock replenished
- [ ] Notification includes suggested reorder quantity
- [ ] Manager+ roles receive notifications

---

### 4.3 Entity: INV_Recipe & INV_RecipeItem

Formula linking Menu Items to Ingredients.

#### FR-17: Cost Calculation

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Financial |

**Requirement:** The system MUST support "Theoretical Food Cost" calculation.

**Formula:**
```
Theoretical Cost = Σ (RecipeItem.quantity_needed × Ingredient.cost_per_unit)
```

**Acceptance Criteria:**
- [ ] Cost calculated in real-time for menu item detail view
- [ ] Batch cost calculation available for full menu
- [ ] Cost updates when ingredient prices change
- [ ] Cost comparison report: Theoretical vs Actual

#### FR-18: Deduction Logic

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Inventory Management |

**Requirement:** When a `POS_Order` is marked as `CONFIRMED`, the system MUST execute the following sequence:

```
1. FOR EACH Menu Item in Order:
   a. Lookup Recipe for Menu Item
   b. FOR EACH RecipeItem in Recipe:
      i.  Calculate: required_qty = RecipeItem.quantity_needed × order_qty
      ii. Create INV_StockLog record (action: DEDUCT_SALE)
      iii. Decrement INV_Ingredient.current_stock by required_qty
2. Commit transaction atomically
```

**Acceptance Criteria:**
- [ ] Deduction occurs within database transaction
- [ ] Failed deduction rolls back entire order confirmation
- [ ] Insufficient stock returns clear error message
- [ ] Stock log references source order_id

---

### 4.4 Entity: INV_StockLog

Immutable audit trail of every stock movement.

#### FR-19: Immutability

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Audit & Compliance |

**Requirement:** Records in this table are "Write Once, Read Many." NO `UPDATE` or `DELETE` operations are permitted under any circumstances.

**Acceptance Criteria:**
- [ ] Database triggers prevent UPDATE/DELETE
- [ ] ORM model disables update/delete methods
- [ ] API provides no endpoints for modification
- [ ] Corrections made via new AUDIT entries only

#### FR-20: Action Classification

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Data Integrity |

**Requirement:** The `action` field MUST strictly adhere to the following enum:

| Action | Description | Stock Effect |
|--------|-------------|--------------|
| `RESTOCK` | Stock arriving from supplier | + (Increase) |
| `DEDUCT_SALE` | Stock consumed by customer orders | - (Decrease) |
| `WASTE` | Stock spoiled, dropped, or discarded | - (Decrease) |
| `AUDIT` | Corrections after manual stock take | +/- (Either) |

**Acceptance Criteria:**
- [ ] Database enforces enum constraint
- [ ] Invalid action values rejected at API level
- [ ] Each action type has distinct audit trail
- [ ] Reports can filter by action type

---

## 5. POS & Order Module

The transaction processing engine.

### 5.1 Entity: POS_Order

Container for a customer's request.

#### FR-21: State Machine

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Business Logic |

**Requirement:** The `status` field MUST follow strict state transitions.

**State Diagram:**
```
DRAFT → CONFIRMED → KITCHEN → READY → SERVED → PAID → COMPLETED
         ↓
       CANCELLED
```

**Transition Rules:**

| From | To | Condition |
|------|----|-----------|
| DRAFT | CONFIRMED | At least one order item exists |
| CONFIRMED | KITCHEN | Automatic after confirmation |
| KITCHEN | READY | All order items status = DONE |
| READY | SERVED | Manual trigger by waiter |
| SERVED | PAID | Transaction total ≥ Order total |
| PAID | COMPLETED | Manual or auto after timeout |
| Any (except COMPLETED) | CANCELLED | Manager+ authorization required |

**Acceptance Criteria:**
- [ ] Invalid transitions return `422 Unprocessable Entity`
- [ ] State changes logged with timestamp and user
- [ ] Webhooks fired on state transitions
- [ ] UI reflects current state in real-time

#### FR-22: Guest Support

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | User Experience |

**Requirement:** The `customer_id` field MUST be nullable to support "Guest Checkout" or anonymous walk-in customers.

**Acceptance Criteria:**
- [ ] Orders created without customer_id are valid
- [ ] Guest orders excluded from loyalty calculations
- [ ] Optional customer linking after order creation
- [ ] Analytics differentiate guest vs registered orders

---

### 5.2 Entity: POS_OrderItem

Individual lines on a ticket.

#### FR-23: Modifier Snapshotting

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Financial Integrity |

**Requirement:** The `active_modifiers` JSON field MUST store a complete copy of modifier names and prices at the time of sale.

**Schema:**
```json
{
  "modifiers": [
    {
      "id": "uuid",
      "name": "Extra Cheese",
      "price": 1.00,
      "group_name": "Toppings"
    }
  ],
  "snapshot_at": "ISO8601 timestamp"
}
```

**Rationale:** If "Extra Cheese" price changes from $1.00 to $1.50 next week, historical orders MUST still display $1.00.

**Acceptance Criteria:**
- [ ] Snapshot created at order item creation
- [ ] Snapshot includes all selected modifiers
- [ ] Receipts render from snapshot, not live data
- [ ] Snapshot immutable after creation

#### FR-24: Kitchen Status

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Operations |

**Requirement:** Each order item tracks its own `status` independently, enabling granular Kitchen Display System (KDS) updates.

**Item States:**

| Status | Description |
|--------|-------------|
| `QUEUED` | Sent to kitchen, awaiting preparation |
| `COOKING` | Currently being prepared |
| `DONE` | Ready for service |

**Acceptance Criteria:**
- [ ] KDS displays items grouped by status
- [ ] Individual item status updates in real-time
- [ ] Order status = READY when ALL items = DONE
- [ ] Cooking time tracked per item

---

### 5.3 Entity: POS_Transaction

Financial record of payment.

#### FR-25: Partial Payments

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Payment Processing |

**Requirement:** The system MUST allow multiple Transaction records for a single `POS_Order` to support split bills.

**Example:**
```
Order Total: $100.00
Transaction 1: $60.00 (Credit Card) - Customer A
Transaction 2: $40.00 (Cash) - Customer B
```

**Acceptance Criteria:**
- [ ] No limit on transactions per order
- [ ] Running balance displayed during payment
- [ ] Each transaction has independent payment method
- [ ] Partial refunds supported per transaction

#### FR-26: Overpayment Handling

| Attribute | Value |
|-----------|-------|
| **Priority** | P2 |
| **Category** | Payment Processing |

**Requirement:** If the sum of transactions exceeds the Order Total, the difference MUST be recorded as a "Tip."

**Acceptance Criteria:**
- [ ] Tip calculated: `Tip = Σ(Transactions) - Order Total`
- [ ] Tip amount stored in dedicated field
- [ ] Tips reported separately in end-of-day
- [ ] Staff tip attribution supported

---

### 5.4 Entity: POS_FiscalReceipt

Legal compliance record for jurisdictions requiring fiscalization.

#### FR-27: Fiscalization

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 (where legally required) |
| **Category** | Compliance |

**Requirement:** Upon successful payment, this entity is created with cryptographic integrity verification.

**Hash Chain Implementation:**
```
Receipt[N].hash = SHA-256(
  Receipt[N].transaction_data +
  Receipt[N-1].hash +
  Receipt[N].timestamp
)
```

**Acceptance Criteria:**
- [ ] Hash generated using SHA-256 algorithm
- [ ] Previous receipt hash included in calculation
- [ ] First receipt uses genesis hash constant
- [ ] Hash verification endpoint available
- [ ] Tampering detection alerts generated

---

## 6. Bookings & Tables Module

Physical space management.

### 6.1 Entity: RES_FloorPlan & RES_Table

#### FR-28: Canvas Rendering

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | User Interface |

**Requirement:** The `x_coord` and `y_coord` fields MUST correspond to pixel or grid coordinates compatible with the Frontend Canvas API.

**Coordinate System:**
- Origin (0,0) at top-left corner
- X increases rightward
- Y increases downward
- Values in pixels relative to floor plan dimensions

**Acceptance Criteria:**
- [ ] Coordinates validated within floor plan bounds
- [ ] Drag-and-drop updates coordinates atomically
- [ ] Table shapes support: circle, square, rectangle
- [ ] Zoom and pan maintain coordinate accuracy

#### FR-29: Occupancy Status

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Real-Time Status |

**Requirement:** A table's occupancy status is DERIVED dynamically—not stored as a static field.

**Derivation Logic:**
```sql
status = CASE
  WHEN EXISTS (
    SELECT 1 FROM POS_Order
    WHERE table_id = RES_Table.id
    AND status NOT IN ('PAID', 'COMPLETED', 'CANCELLED')
  ) THEN 'OCCUPIED'
  ELSE 'FREE'
END
```

**Acceptance Criteria:**
- [ ] No `status` column on RES_Table
- [ ] Status computed on each query
- [ ] Caching allowed with 30-second TTL max
- [ ] Real-time updates via WebSocket

---

### 6.2 Entity: RES_Reservation

#### FR-30: Double Booking Prevention

| Attribute | Value |
|-----------|-------|
| **Priority** | P0 |
| **Category** | Data Integrity |

**Requirement:** The system MUST reject reservation creation requests that would cause a time conflict.

**Conflict Detection Formula:**
```
CONFLICT EXISTS IF:
  (NewStart < ExistingEnd) AND
  (NewEnd > ExistingStart) AND
  (NewTableID == ExistingTableID) AND
  (ExistingStatus NOT IN ('CANCELLED', 'NO_SHOW'))
```

**Acceptance Criteria:**
- [ ] Conflict check runs before INSERT
- [ ] Conflicting reservation returns `409 Conflict`
- [ ] Error includes details of blocking reservation
- [ ] Buffer time configurable between reservations

#### FR-31: Auto-Release

| Attribute | Value |
|-----------|-------|
| **Priority** | P2 |
| **Category** | Operations |

**Requirement:** If a reservation is not marked as `SEATED` within X minutes of `start_time`, the system SHOULD automatically flag it as `NO_SHOW` and free the table.

**Configuration:**
- Default grace period: 15 minutes
- Configurable per tenant in settings
- Range: 5-60 minutes

**Acceptance Criteria:**
- [ ] Background job runs every 5 minutes
- [ ] NO_SHOW status applied after grace period
- [ ] Notification sent to staff before auto-release
- [ ] Customer notification (if contact info available)

---

## 7. Logistics Module

Delivery and driver management.

### 7.1 Entity: LOG_DeliveryZone

#### FR-32: Geospatial Querying

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Infrastructure |

**Requirement:** The `polygon` field MUST store valid GeoJSON Polygon geometry.

**GeoJSON Schema:**
```json
{
  "type": "Polygon",
  "coordinates": [
    [[lng1, lat1], [lng2, lat2], [lng3, lat3], [lng1, lat1]]
  ]
}
```

**Acceptance Criteria:**
- [ ] GeoJSON validated on save
- [ ] PostGIS or equivalent spatial extension required
- [ ] Polygon must be closed (first point = last point)
- [ ] Visual zone editor in admin UI

#### FR-33: Fee Calculation

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Business Logic |

**Requirement:** When calculating delivery fee, the system performs Point-in-Polygon search. If address falls in multiple overlapping zones, the zone with smallest area takes precedence.

**Algorithm:**
```
1. Convert address to coordinates (geocoding)
2. Find all zones containing point (ST_Contains)
3. Sort matching zones by area ascending
4. Return first zone's delivery_fee
5. If no zones match, return "Outside Delivery Area" error
```

**Acceptance Criteria:**
- [ ] Geocoding integration functional
- [ ] Smallest area zone selected for overlaps
- [ ] Fee displayed before order confirmation
- [ ] Zone boundaries visible on customer map

---

### 7.2 Entity: LOG_Driver & LOG_Shipment

#### FR-34: Driver Availability

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Operations |

**Requirement:** Driver assignment eligibility based on status.

**Status Rules:**

| Status | Can Receive Orders? | Condition |
|--------|---------------------|-----------|
| `IDLE` | Yes | Always |
| `ON_JOB` | Conditional | Only if `multi_order_dispatch = true` |
| `OFFLINE` | No | Never |

**Acceptance Criteria:**
- [ ] Assignment algorithm respects status rules
- [ ] Multi-order setting checked per tenant
- [ ] Driver location updates every 30 seconds
- [ ] Auto-OFFLINE after 8 hours idle

#### FR-35: Proof of Delivery

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Compliance |

**Requirement:** The `proof_photo_url` MUST be signed and verified before a Shipment can transition to `DELIVERED` status.

**Verification Requirements:**
- Photo timestamp within 5 minutes of submission
- GPS coordinates within 100m of delivery address
- Image hash stored for tampering detection

**Acceptance Criteria:**
- [ ] Photo upload required for DELIVERED transition
- [ ] Metadata validation automated
- [ ] Manual override with manager approval
- [ ] Photos retained per data retention policy

---

## 8. HRM Module

Staff scheduling and time tracking.

### 8.1 Entity: HRM_Shift

#### FR-36: Time Clock Validation

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Data Integrity |

**Requirement:** The `actual_clock_in` timestamp CANNOT be in the future.

**Acceptance Criteria:**
- [ ] Server-side validation against current time
- [ ] Client clock not trusted for timestamp
- [ ] Maximum backdating: 15 minutes (configurable)
- [ ] Manager override for exceptions

#### FR-37: Lateness Flagging

| Attribute | Value |
|-----------|-------|
| **Priority** | P2 |
| **Category** | Payroll |

**Requirement:** If `actual_clock_in > scheduled_start + grace_period`, the system MUST flag the shift as "LATE."

**Grace Period:**
- Default: 15 minutes
- Configurable per tenant
- Range: 0-60 minutes

**Acceptance Criteria:**
- [ ] LATE flag set automatically on clock-in
- [ ] Late minutes calculated and stored
- [ ] Payroll report includes lateness summary
- [ ] Notification to manager for excessive lateness

---

## 9. CMS Module

Website builder and content management.

### 9.1 Entity: CMS_Page

#### FR-38: Slug Uniqueness

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Data Integrity |

**Requirement:** The `slug` (URL path) MUST be unique per Tenant.

**Slug Rules:**
- Lowercase alphanumeric and hyphens only
- No leading/trailing hyphens
- Maximum length: 100 characters
- Reserved slugs: `admin`, `api`, `static`, `assets`

**Acceptance Criteria:**
- [ ] Unique constraint on (`tenant_id`, `slug`)
- [ ] Auto-generation from page title
- [ ] Collision handling with numeric suffix
- [ ] Slug validation regex enforced

#### FR-39: Component Mapping

| Attribute | Value |
|-----------|-------|
| **Priority** | P1 |
| **Category** | Rendering |

**Requirement:** The `content_blocks` JSON is an ordered array of component definitions.

**Schema:**
```json
{
  "content_blocks": [
    {
      "type": "hero",
      "props": {
        "title": "string",
        "subtitle": "string",
        "backgroundImage": "url"
      }
    },
    {
      "type": "menu_grid",
      "props": {
        "categoryId": "uuid",
        "columns": 3
      }
    }
  ]
}
```

**Supported Components:**

| Type | Description |
|------|-------------|
| `hero` | Full-width banner with CTA |
| `menu_grid` | Product grid from category |
| `text_block` | Rich text content |
| `image_gallery` | Image carousel |
| `contact_form` | Contact submission form |
| `map` | Embedded location map |

**Acceptance Criteria:**
- [ ] Frontend dynamically imports components
- [ ] Unknown types render fallback placeholder
- [ ] Props validated against component schema
- [ ] Drag-and-drop block reordering in editor

---

## 10. Appendix

### 10.1 Requirement Traceability Matrix

| Module | Requirements | P0 | P1 | P2 |
|--------|--------------|----|----|-----|
| Core & Auth | FR-01 to FR-05 | 3 | 1 | 1 |
| Menu | FR-06 to FR-13 | 3 | 4 | 1 |
| Inventory | FR-14 to FR-20 | 4 | 2 | 1 |
| POS & Order | FR-21 to FR-27 | 4 | 3 | 1 |
| Bookings | FR-28 to FR-31 | 2 | 1 | 1 |
| Logistics | FR-32 to FR-35 | 0 | 4 | 0 |
| HRM | FR-36 to FR-37 | 0 | 1 | 1 |
| CMS | FR-38 to FR-39 | 0 | 2 | 0 |
| **Total** | **39** | **16** | **18** | **6** |

### 10.2 Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 2024 | Engineering Team | Initial release |

### 10.3 Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | | | |
| Tech Lead | | | |
| QA Lead | | | |
| Security Lead | | | |

---

*Document generated for URMS v1.0 — Confidential*
