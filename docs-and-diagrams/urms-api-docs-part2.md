# URMS API Documentation - Part 2

## 5. Inventory Management

### 5.1 List Ingredients
```
GET /inventory/ingredients
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `supplier_id` | uuid | Filter by supplier |
| `low_stock` | boolean | Only items below reorder level |
| `unit_category` | string | MASS, VOLUME, COUNT |
| `search` | string | Search by name/SKU |
| `page` | int | Page number |
| `limit` | int | Items per page |

**Business Logic:**
- Apply tenant filter
- Calculate stock status (OK, LOW, CRITICAL)
- Include supplier information
- Sort by name or stock status

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Tomato Sauce",
      "sku": "INV-001",
      "unit": "L",
      "unit_category": "VOLUME",
      "current_stock": 15.5,
      "reorder_level": 20,
      "reorder_quantity": 50,
      "cost_per_unit": 3.50,
      "stock_status": "LOW",
      "stock_value": 54.25,
      "supplier": {
        "id": "uuid",
        "name": "Fresh Foods Co"
      },
      "last_restocked_at": "2024-11-28T10:00:00Z"
    }
  ]
}
```

---

### 5.2 Get Ingredient by ID
```
GET /inventory/ingredients/{id}
```

**Access:** A, M

**Business Logic:**
- Return full ingredient details
- Include stock history (last 30 days)
- Include recipes using this ingredient
- Calculate consumption rate

---

### 5.3 Create Ingredient
```
POST /inventory/ingredients
```

**Access:** A, M

**Business Logic:**
- Validate SKU uniqueness within tenant
- Validate unit_category matches unit (FR-15)
- Set initial stock to 0
- Create audit log

**Request Body:**
```json
{
  "name": "Olive Oil",
  "sku": "INV-002",
  "unit": "L",
  "unit_category": "VOLUME",
  "current_stock": 0,
  "reorder_level": 10,
  "reorder_quantity": 25,
  "cost_per_unit": 12.00,
  "supplier_id": "uuid"
}
```

---

### 5.4 Update Ingredient
```
PUT /inventory/ingredients/{id}
```

**Access:** A, M

**Business Logic:**
- Validate ingredient exists
- If cost_per_unit changed, recalculate affected recipe costs
- Create audit log

---

### 5.5 Delete Ingredient
```
DELETE /inventory/ingredients/{id}
```

**Access:** A

**Business Logic:**
- Check if used in any recipes
- If used, prevent deletion or require force
- Soft delete preferred to maintain history

---

### 5.6 Adjust Stock (Manual)
```
POST /inventory/ingredients/{id}/adjust
```

**Access:** A, M

**Business Logic:**
- Create INV_StockLog entry with action = AUDIT (FR-20)
- Update current_stock
- Log is immutable (FR-19)
- Record reason for adjustment
- Create audit log

**Request Body:**
```json
{
  "adjustment": -5.5,
  "reason": "Physical count correction",
  "notes": "Found damaged containers during inventory"
}
```

---

### 5.7 Record Waste
```
POST /inventory/ingredients/{id}/waste
```

**Access:** A, M, K

**Business Logic:**
- Create INV_StockLog entry with action = WASTE (FR-20)
- Decrement current_stock
- Record waste reason for analytics
- Trigger alert if waste exceeds threshold

**Request Body:**
```json
{
  "quantity": 2.5,
  "reason": "SPOILED",
  "notes": "Expired product found"
}
```

---

### 5.8 Get Stock Log
```
GET /inventory/ingredients/{id}/logs
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `action` | string | Filter by action type |
| `start_date` | date | Filter from date |
| `end_date` | date | Filter to date |
| `page` | int | Page number |

**Business Logic:**
- Return immutable stock movement history
- Include user who made each change
- Include order reference if DEDUCT_SALE

---

### 5.9 Bulk Stock Take
```
POST /inventory/stock-take
```

**Access:** A, M

**Business Logic:**
- Accept array of ingredient counts
- Compare physical vs system counts
- Create AUDIT log entries for discrepancies
- Update all current_stock values
- Generate discrepancy report
- Single transaction for consistency

**Request Body:**
```json
{
  "date": "2024-12-01",
  "counts": [
    { "ingredient_id": "uuid-1", "physical_count": 45.5 },
    { "ingredient_id": "uuid-2", "physical_count": 120 },
    { "ingredient_id": "uuid-3", "physical_count": 8.25 }
  ],
  "notes": "Monthly inventory count"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total_items": 3,
    "discrepancies": 2,
    "total_variance_value": -45.00,
    "details": [
      {
        "ingredient_id": "uuid-1",
        "name": "Flour",
        "system_count": 50,
        "physical_count": 45.5,
        "variance": -4.5,
        "variance_value": -9.00
      }
    ]
  }
}
```

---

### 5.10 Get Low Stock Alerts
```
GET /inventory/alerts/low-stock
```

**Access:** A, M

**Business Logic:**
- Query ingredients where current_stock < reorder_level (FR-16)
- Calculate days until stockout based on consumption rate
- Prioritize by criticality

---

### 5.11 List Suppliers
```
GET /inventory/suppliers
```

**Access:** A, M

**Business Logic:**
- Return all suppliers for tenant
- Include ingredient count per supplier
- Include last order date

---

### 5.12 Get Supplier by ID
```
GET /inventory/suppliers/{id}
```

**Access:** A, M

---

### 5.13 Create Supplier
```
POST /inventory/suppliers
```

**Access:** A, M

**Request Body:**
```json
{
  "name": "Fresh Foods Co",
  "contact_name": "John Smith",
  "contact_email": "john@freshfoods.com",
  "contact_phone": "+1234567890",
  "address": "123 Supply Lane, Food City, FC 12345",
  "payment_terms": "NET30",
  "notes": "Delivers on Tuesdays and Fridays"
}
```

---

### 5.14 Update Supplier
```
PUT /inventory/suppliers/{id}
```

**Access:** A, M

---

### 5.15 Delete Supplier
```
DELETE /inventory/suppliers/{id}
```

**Access:** A

**Business Logic:**
- Check for linked ingredients
- Set ingredient.supplier_id to NULL if deleted
- Soft delete preferred

---

### 5.16 List Purchase Orders
```
GET /inventory/purchase-orders
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `status` | string | DRAFT, SENT, PARTIAL, RECEIVED, CANCELLED |
| `supplier_id` | uuid | Filter by supplier |
| `start_date` | date | Filter from date |
| `end_date` | date | Filter to date |

---

### 5.17 Get Purchase Order by ID
```
GET /inventory/purchase-orders/{id}
```

**Access:** A, M

**Business Logic:**
- Return PO with all line items
- Include receiving history
- Include supplier details

---

### 5.18 Create Purchase Order
```
POST /inventory/purchase-orders
```

**Access:** A, M

**Business Logic:**
- Generate unique PO number (PO-YYYY-XXXX)
- Calculate total amount
- Set status = DRAFT
- Create audit log

**Request Body:**
```json
{
  "supplier_id": "uuid",
  "expected_delivery": "2024-12-05T10:00:00Z",
  "notes": "Rush order for weekend prep",
  "items": [
    { "ingredient_id": "uuid-1", "quantity_ordered": 50, "unit_cost": 3.50 },
    { "ingredient_id": "uuid-2", "quantity_ordered": 25, "unit_cost": 12.00 }
  ]
}
```

---

### 5.19 Update Purchase Order
```
PUT /inventory/purchase-orders/{id}
```

**Access:** A, M

**Business Logic:**
- Only allow updates if status = DRAFT
- Recalculate totals

---

### 5.20 Send Purchase Order
```
POST /inventory/purchase-orders/{id}/send
```

**Access:** A, M

**Business Logic:**
- Validate PO has items
- Update status = SENT
- Generate PDF document
- Email to supplier via SendGrid
- Create audit log

---

### 5.21 Receive Purchase Order
```
POST /inventory/purchase-orders/{id}/receive
```

**Access:** A, M

**Business Logic:**
- Record received quantities for each item
- Create RESTOCK entries in INV_StockLog (FR-20)
- Update ingredient.current_stock
- Update ingredient.last_restocked_at
- Update ingredient.cost_per_unit if changed
- Calculate and update recipe theoretical costs (FR-17)
- If all items received, status = RECEIVED
- If partial, status = PARTIAL
- Create audit log

**Request Body:**
```json
{
  "received_date": "2024-12-05",
  "items": [
    { "ingredient_id": "uuid-1", "quantity_received": 48, "unit_cost": 3.50 },
    { "ingredient_id": "uuid-2", "quantity_received": 25, "unit_cost": 12.50 }
  ],
  "notes": "2 units of flour damaged in transit"
}
```

---

### 5.22 Cancel Purchase Order
```
POST /inventory/purchase-orders/{id}/cancel
```

**Access:** A, M

**Business Logic:**
- Only allow if status in (DRAFT, SENT)
- Set status = CANCELLED
- Optionally notify supplier
- Create audit log

---

### 5.23 List Recipes
```
GET /inventory/recipes
```

**Access:** A, M

**Business Logic:**
- Return recipes with menu item info
- Include theoretical cost
- Include food cost percentage

---

### 5.24 Get Recipe by ID
```
GET /inventory/recipes/{id}
```

**Access:** A, M

**Business Logic:**
- Return recipe with all ingredients
- Calculate current theoretical cost (FR-17)
- Show cost breakdown per ingredient

---

### 5.25 Get Recipe by Menu Item
```
GET /menu/items/{itemId}/recipe
```

**Access:** A, M

---

### 5.26 Create/Update Recipe
```
PUT /menu/items/{itemId}/recipe
```

**Access:** A, M

**Business Logic:**
- Create or update recipe for menu item
- Validate all ingredient IDs exist
- Validate unit compatibility (FR-15)
- Calculate theoretical cost (FR-17)
- Update menu item cost_price

**Request Body:**
```json
{
  "instruction_text": "1. Grill patty to desired temp\n2. Toast bun\n3. Assemble with toppings",
  "yield_quantity": 1,
  "items": [
    { "ingredient_id": "uuid-beef", "quantity_needed": 0.2, "unit": "kg" },
    { "ingredient_id": "uuid-bun", "quantity_needed": 1, "unit": "pcs" },
    { "ingredient_id": "uuid-cheese", "quantity_needed": 0.05, "unit": "kg" },
    { "ingredient_id": "uuid-lettuce", "quantity_needed": 0.03, "unit": "kg" }
  ]
}
```

---

### 5.27 Delete Recipe
```
DELETE /menu/items/{itemId}/recipe
```

**Access:** A, M

---

### 5.28 Calculate Recipe Cost
```
GET /inventory/recipes/{id}/cost
```

**Access:** A, M

**Business Logic:**
- Calculate theoretical cost (FR-17)
- Σ (RecipeItem.quantity_needed × Ingredient.cost_per_unit)
- Compare to selling price
- Return food cost percentage

**Response:**
```json
{
  "success": true,
  "data": {
    "recipe_id": "uuid",
    "menu_item": "Classic Cheeseburger",
    "selling_price": 14.99,
    "theoretical_cost": 4.52,
    "food_cost_percent": 30.15,
    "margin": 10.47,
    "breakdown": [
      { "ingredient": "Beef Patty", "quantity": 0.2, "unit": "kg", "unit_cost": 15.00, "line_cost": 3.00 },
      { "ingredient": "Burger Bun", "quantity": 1, "unit": "pcs", "unit_cost": 0.50, "line_cost": 0.50 },
      { "ingredient": "Cheddar", "quantity": 0.05, "unit": "kg", "unit_cost": 12.00, "line_cost": 0.60 },
      { "ingredient": "Lettuce", "quantity": 0.03, "unit": "kg", "unit_cost": 4.00, "line_cost": 0.12 }
    ]
  }
}
```

---

## 6. Order Management

### 6.1 List Orders
```
GET /orders
```

**Access:** A, M, W, K

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `status` | string | Filter by order status |
| `order_type` | string | DINE_IN, TAKEOUT, DELIVERY |
| `table_id` | uuid | Filter by table |
| `staff_id` | uuid | Filter by staff who created |
| `customer_id` | uuid | Filter by customer |
| `date` | date | Filter by date |
| `start_date` | date | Range start |
| `end_date` | date | Range end |
| `page` | int | Page number |
| `limit` | int | Items per page |

**Business Logic:**
- Apply role-based filtering:
  - Kitchen: Only KITCHEN, READY status
  - Waiter: Own orders or unassigned
  - Manager/Admin: All orders
- Default sort: created_at DESC

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "order_number": "ORD-20241201-0042",
      "status": "KITCHEN",
      "order_type": "DINE_IN",
      "table": { "id": "uuid", "table_number": "T5" },
      "staff": { "id": "uuid", "name": "John D." },
      "customer": null,
      "item_count": 4,
      "subtotal": 45.96,
      "tax_amount": 3.79,
      "discount_amount": 0,
      "total_amount": 49.75,
      "created_at": "2024-12-01T18:30:00Z",
      "updated_at": "2024-12-01T18:32:00Z"
    }
  ]
}
```

---

### 6.2 Get Order by ID
```
GET /orders/{id}
```

**Access:** A, M, W, K

**Business Logic:**
- Return full order details
- Include all order items with modifiers
- Include transaction history
- Include timeline of status changes

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "order_number": "ORD-20241201-0042",
    "status": "KITCHEN",
    "order_type": "DINE_IN",
    "table": { "id": "uuid", "table_number": "T5", "floor": "Main Hall" },
    "staff": { "id": "uuid", "name": "John Doe" },
    "customer": null,
    "guests_count": 2,
    "items": [
      {
        "id": "uuid",
        "menu_item_id": "uuid",
        "item_name_snapshot": "Classic Cheeseburger",
        "quantity": 2,
        "unit_price": 14.99,
        "modifiers_price": 2.50,
        "line_total": 34.98,
        "status": "COOKING",
        "special_instructions": "No onions on one",
        "active_modifiers": [
          { "name": "Medium", "price": 0 },
          { "name": "Extra Cheese", "price": 1.50 },
          { "name": "Bacon", "price": 2.50 }
        ],
        "sent_to_kitchen_at": "2024-12-01T18:31:00Z"
      }
    ],
    "discounts": [],
    "transactions": [],
    "subtotal": 45.96,
    "tax_amount": 3.79,
    "discount_amount": 0,
    "total_amount": 49.75,
    "notes": "Anniversary dinner",
    "timeline": [
      { "status": "DRAFT", "at": "2024-12-01T18:30:00Z", "by": "John Doe" },
      { "status": "CONFIRMED", "at": "2024-12-01T18:31:00Z", "by": "John Doe" },
      { "status": "KITCHEN", "at": "2024-12-01T18:31:00Z", "by": "System" }
    ],
    "created_at": "2024-12-01T18:30:00Z"
  }
}
```

---

### 6.3 Create Order
```
POST /orders
```

**Access:** A, M, W

**Business Logic:**
- Generate order_number (ORD-YYYYMMDD-XXXX)
- Set status = DRAFT
- Link to table if provided (DINE_IN)
- Link to customer if provided
- Validate table is not already occupied (unless adding to existing)
- Create audit log

**Request Body:**
```json
{
  "order_type": "DINE_IN",
  "table_id": "uuid",
  "customer_id": "uuid",
  "guests_count": 4,
  "notes": "Birthday celebration"
}
```

---

### 6.4 Add Item to Order
```
POST /orders/{id}/items
```

**Access:** A, M, W

**Business Logic:**
- Validate order status = DRAFT or CONFIRMED
- Validate menu item is available (FR-08)
- Validate modifier selections meet constraints (FR-11)
- Snapshot item name and price (FR-09, FR-23)
- Snapshot modifier names and prices (FR-23)
- Calculate line_total
- Recalculate order totals
- If order already CONFIRMED, send new item to kitchen

**Request Body:**
```json
{
  "menu_item_id": "uuid",
  "quantity": 2,
  "modifiers": [
    { "modifier_id": "uuid-medium" },
    { "modifier_id": "uuid-extra-cheese" },
    { "modifier_id": "uuid-bacon" }
  ],
  "special_instructions": "No onions on one burger"
}
```

---

### 6.5 Update Order Item
```
PUT /orders/{orderId}/items/{itemId}
```

**Access:** A, M, W

**Business Logic:**
- Only allow if item status = QUEUED
- If already COOKING, reject change
- Update quantity, modifiers, instructions
- Recalculate line_total and order totals

---

### 6.6 Remove Order Item
```
DELETE /orders/{orderId}/items/{itemId}
```

**Access:** A, M, W

**Business Logic:**
- Only allow if item status = QUEUED
- If COOKING or DONE, require manager approval to void
- Recalculate order totals
- If voiding, record reason

---

### 6.7 Void Order Item
```
POST /orders/{orderId}/items/{itemId}/void
```

**Access:** A, M

**Business Logic:**
- Set voided_at timestamp
- Record void_reason
- Do NOT delete (for analytics)
- Recalculate order totals
- Reverse inventory deduction if already deducted

**Request Body:**
```json
{
  "reason": "Customer changed mind"
}
```

---

### 6.8 Confirm Order (Submit to Kitchen)
```
POST /orders/{id}/confirm
```

**Access:** A, M, W

**Business Logic (FR-18, FR-21):**
1. Validate order has at least one item
2. Validate all required modifiers selected
3. Begin transaction:
   - Update status: DRAFT → CONFIRMED
   - For each item:
     - Lookup recipe
     - Calculate ingredients needed
     - Create DEDUCT_SALE entries in INV_StockLog
     - Decrement INV_Ingredient.current_stock
     - Check for low stock alerts (FR-16)
   - Update status: CONFIRMED → KITCHEN
   - Set items status = QUEUED
   - Set sent_to_kitchen_at
4. Commit transaction
5. Send to KDS via WebSocket
6. Create audit log

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "order_number": "ORD-20241201-0042",
    "status": "KITCHEN",
    "inventory_deductions": [
      { "ingredient": "Beef Patty", "quantity": 0.4, "remaining": 12.6 }
    ],
    "low_stock_alerts": [
      { "ingredient": "Burger Buns", "current": 8, "reorder_level": 20 }
    ]
  }
}
```

---

### 6.9 Update Order Item Status (KDS)
```
PATCH /orders/{orderId}/items/{itemId}/status
```

**Access:** A, M, K

**Business Logic:**
- Validate status transition:
  - QUEUED → COOKING
  - COOKING → DONE
- Update timestamp (cooking_started_at, completed_at)
- Broadcast via WebSocket to POS/Waiter
- If all items DONE, auto-update order to READY

**Request Body:**
```json
{
  "status": "COOKING"
}
```

---

### 6.10 Mark Order Ready
```
POST /orders/{id}/ready
```

**Access:** A, M, K

**Business Logic:**
- Validate all items status = DONE
- Update order status = READY (FR-21)
- Notify waiter via push notification
- Broadcast via WebSocket

---

### 6.11 Mark Order Served
```
POST /orders/{id}/serve
```

**Access:** A, M, W

**Business Logic:**
- Validate status = READY
- Update status = SERVED (FR-21)
- Record served timestamp

---

### 6.12 Apply Discount to Order
```
POST /orders/{id}/discounts
```

**Access:** A, M

**Business Logic:**
- Validate order not yet PAID
- Validate discount code if promo
- Calculate discount amount
- Update discount_amount and total_amount
- Create discount record

**Request Body:**
```json
{
  "discount_type": "PERCENTAGE",
  "value": 10,
  "code": "SUMMER10",
  "description": "Summer promotion"
}
```

---

### 6.13 Remove Discount from Order
```
DELETE /orders/{orderId}/discounts/{discountId}
```

**Access:** A, M

---

### 6.14 Cancel Order
```
POST /orders/{id}/cancel
```

**Access:** A, M

**Business Logic:**
- Validate status not COMPLETED
- If inventory already deducted, reverse (create AUDIT log)
- Update status = CANCELLED
- Record cancellation reason
- Notify relevant parties
- If payment already made, initiate refund

**Request Body:**
```json
{
  "reason": "Customer left without ordering"
}
```

---

### 6.15 Get Order for KDS
```
GET /kds/orders
```

**Access:** K

**Business Logic:**
- Return orders with status IN (KITCHEN, READY)
- Group by order for display
- Include item-level status
- Real-time updates via WebSocket

---

### 6.16 Get Active Orders for Table
```
GET /tables/{tableId}/orders/active
```

**Access:** A, M, W

**Business Logic:**
- Return orders not in (PAID, COMPLETED, CANCELLED)
- Used to check table occupancy (FR-29)

---

### 6.17 Transfer Order to Another Table
```
POST /orders/{id}/transfer
```

**Access:** A, M, W

**Business Logic:**
- Validate new table is available
- Update table_id
- Create audit log

**Request Body:**
```json
{
  "new_table_id": "uuid"
}
```

---

### 6.18 Merge Orders
```
POST /orders/merge
```

**Access:** A, M

**Business Logic:**
- Move all items from source orders to target order
- Recalculate totals
- Mark source orders as merged/cancelled
- Useful when groups want single bill

**Request Body:**
```json
{
  "target_order_id": "uuid",
  "source_order_ids": ["uuid-1", "uuid-2"]
}
```

---

### 6.19 Split Order
```
POST /orders/{id}/split
```

**Access:** A, M, W

**Business Logic:**
- Create new order with selected items
- Remove items from original
- Recalculate both orders
- Both orders share same table

**Request Body:**
```json
{
  "items_to_split": [
    { "order_item_id": "uuid", "quantity": 1 }
  ]
}
```

---

### 6.20 Get Order History for Customer
```
GET /customers/{customerId}/orders
```

**Access:** A, M, C (own orders)

**Business Logic:**
- Return paginated order history
- Include summary statistics
