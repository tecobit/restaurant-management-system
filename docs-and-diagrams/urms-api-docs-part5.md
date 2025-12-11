# URMS API Documentation - Part 5

## 11. Customer (CRM)

### 11.1 List Customers
```
GET /customers
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `search` | string | Search name/email/phone |
| `loyalty_tier` | string | Filter by tier |
| `min_visits` | int | Minimum visit count |
| `min_spent` | decimal | Minimum total spent |
| `page` | int | Page number |
| `limit` | int | Items per page |

---

### 11.2 Get Customer by ID
```
GET /customers/{id}
```

**Access:** A, M, C (own profile)

**Business Logic:**
- Return full customer profile
- Include order history summary
- Include loyalty points
- Include preferences

---

### 11.3 Create Customer
```
POST /customers
```

**Access:** A, M, W, Public (self-registration)

**Request Body:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "preferences": {
    "allergies": ["peanuts"],
    "dietary": "vegetarian"
  }
}
```

---

### 11.4 Update Customer
```
PUT /customers/{id}
```

**Access:** A, M, C (own profile)

---

### 11.5 Delete Customer
```
DELETE /customers/{id}
```

**Access:** A

**Business Logic:**
- GDPR compliant deletion
- Anonymize order history
- Remove personal data
- Maintain analytics data (anonymized)

---

### 11.6 Search Customers
```
GET /customers/search
```

**Access:** A, M, W

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `q` | string | Search query |
| `field` | string | phone, email, name |

**Business Logic:**
- Quick search for POS lookup
- Returns minimal data for selection

---

### 11.7 Get Customer Addresses
```
GET /customers/{id}/addresses
```

**Access:** A, M, C (own)

---

### 11.8 Add Customer Address
```
POST /customers/{id}/addresses
```

**Access:** A, M, C (own)

**Business Logic:**
- Geocode address
- Validate in delivery zone
- If is_default, unset other defaults

**Request Body:**
```json
{
  "label": "Home",
  "address_line1": "123 Main St",
  "address_line2": "Apt 4B",
  "city": "New York",
  "state": "NY",
  "postal_code": "10001",
  "is_default": true
}
```

---

### 11.9 Update Customer Address
```
PUT /customers/{customerId}/addresses/{addressId}
```

**Access:** A, M, C (own)

---

### 11.10 Delete Customer Address
```
DELETE /customers/{customerId}/addresses/{addressId}
```

**Access:** A, M, C (own)

---

### 11.11 Get Customer Order History
```
GET /customers/{id}/orders
```

**Access:** A, M, C (own)

---

### 11.12 Get Customer Loyalty Points
```
GET /customers/{id}/loyalty
```

**Access:** A, M, C (own)

**Response:**
```json
{
  "success": true,
  "data": {
    "current_points": 1250,
    "lifetime_points": 5000,
    "tier": "GOLD",
    "points_to_next_tier": 750,
    "expiring_soon": {
      "points": 200,
      "expires_at": "2024-12-31T23:59:59Z"
    }
  }
}
```

---

### 11.13 Get Customer Loyalty History
```
GET /customers/{id}/loyalty/history
```

**Access:** A, M, C (own)

---

### 11.14 Adjust Loyalty Points (Manual)
```
POST /customers/{id}/loyalty/adjust
```

**Access:** A, M

**Business Logic:**
- Create ADJUST transaction
- Update balance
- Log reason

**Request Body:**
```json
{
  "points": 100,
  "reason": "Customer service compensation"
}
```

---

### 11.15 Get Customer Preferences
```
GET /customers/{id}/preferences
```

**Access:** A, M, C (own)

---

### 11.16 Update Customer Preferences
```
PUT /customers/{id}/preferences
```

**Access:** A, M, C (own)

**Request Body:**
```json
{
  "allergies": ["peanuts", "shellfish"],
  "dietary": "vegetarian",
  "favorite_items": ["uuid-1", "uuid-2"],
  "communication": {
    "email_marketing": true,
    "sms_promotions": false
  }
}
```

---

### 11.17 Merge Customer Profiles
```
POST /customers/merge
```

**Access:** A

**Business Logic:**
- Merge duplicate customer records
- Consolidate order history
- Sum loyalty points
- Keep preferred contact info

**Request Body:**
```json
{
  "primary_customer_id": "uuid-keep",
  "secondary_customer_ids": ["uuid-merge-1", "uuid-merge-2"]
}
```

---

## 12. HRM & Staff

### 12.1 List Shifts
```
GET /hrm/shifts
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `user_id` | uuid | Filter by staff |
| `date` | date | Filter by date |
| `start_date` | date | Range start |
| `end_date` | date | Range end |
| `status` | string | SCHEDULED, CLOCKED_IN, COMPLETED, MISSED |

---

### 12.2 Get Shift by ID
```
GET /hrm/shifts/{id}
```

**Access:** A, M, Own

---

### 12.3 Get My Shifts
```
GET /hrm/shifts/me
```

**Access:** All authenticated

**Business Logic:**
- Return shifts for current user
- Default to current week
- Include upcoming and past

---

### 12.4 Create Shift
```
POST /hrm/shifts
```

**Access:** A, M

**Business Logic:**
- Validate user exists
- Check for overlapping shifts
- Calculate scheduled hours

**Request Body:**
```json
{
  "user_id": "uuid",
  "scheduled_start": "2024-12-15T09:00:00Z",
  "scheduled_end": "2024-12-15T17:00:00Z",
  "notes": "Opening shift"
}
```

---

### 12.5 Update Shift
```
PUT /hrm/shifts/{id}
```

**Access:** A, M

---

### 12.6 Delete Shift
```
DELETE /hrm/shifts/{id}
```

**Access:** A, M

**Business Logic:**
- Only allow if status = SCHEDULED
- Cannot delete past/in-progress shifts

---

### 12.7 Clock In
```
POST /hrm/shifts/{id}/clock-in
```

**Access:** A, M, Own

**Business Logic (FR-36, FR-37):**
- Validate shift exists for user
- Validate clock_in not in future (FR-36)
- Record actual_clock_in
- Calculate if late:
  - If actual_clock_in > scheduled_start + grace_period
  - Set is_late = true
  - Calculate late_minutes
- Update status = CLOCKED_IN
- Create audit log

**Request Body:**
```json
{
  "notes": "Traffic delay"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "CLOCKED_IN",
    "actual_clock_in": "2024-12-15T09:12:00Z",
    "is_late": true,
    "late_minutes": 12,
    "scheduled_start": "2024-12-15T09:00:00Z"
  }
}
```

---

### 12.8 Clock Out
```
POST /hrm/shifts/{id}/clock-out
```

**Access:** A, M, Own

**Business Logic:**
- Record actual_clock_out
- Calculate total hours worked
- Calculate break time if applicable
- Update status = COMPLETED

**Request Body:**
```json
{
  "break_minutes": 30
}
```

---

### 12.9 Get Timesheet
```
GET /hrm/timesheet
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `user_id` | uuid | Filter by user |
| `start_date` | date | Period start |
| `end_date` | date | Period end |

**Business Logic:**
- Aggregate shifts for period
- Calculate total hours
- Calculate overtime
- Flag irregularities

---

### 12.10 Bulk Create Shifts (Schedule)
```
POST /hrm/shifts/bulk
```

**Access:** A, M

**Business Logic:**
- Create multiple shifts at once
- Validate no conflicts
- Optionally copy from template

**Request Body:**
```json
{
  "shifts": [
    { "user_id": "uuid-1", "scheduled_start": "...", "scheduled_end": "..." },
    { "user_id": "uuid-2", "scheduled_start": "...", "scheduled_end": "..." }
  ]
}
```

---

### 12.11 Copy Schedule
```
POST /hrm/shifts/copy
```

**Access:** A, M

**Business Logic:**
- Copy shifts from one week to another
- Adjust dates accordingly

**Request Body:**
```json
{
  "source_start_date": "2024-12-09",
  "source_end_date": "2024-12-15",
  "target_start_date": "2024-12-16"
}
```

---

### 12.12 List Time-Off Requests
```
GET /hrm/time-off
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `user_id` | uuid | Filter by user |
| `status` | string | PENDING, APPROVED, DENIED |
| `type` | string | VACATION, SICK, PERSONAL |

---

### 12.13 Get My Time-Off Requests
```
GET /hrm/time-off/me
```

**Access:** All authenticated

---

### 12.14 Create Time-Off Request
```
POST /hrm/time-off
```

**Access:** All authenticated

**Business Logic:**
- Validate dates are in future
- Check for conflicting shifts
- Calculate days requested
- Submit for approval

**Request Body:**
```json
{
  "type": "VACATION",
  "start_date": "2024-12-23",
  "end_date": "2024-12-27",
  "reason": "Holiday travel"
}
```

---

### 12.15 Approve Time-Off Request
```
POST /hrm/time-off/{id}/approve
```

**Access:** A, M

**Business Logic:**
- Update status = APPROVED
- Record approved_by
- Notify requester
- Optionally remove conflicting shifts

**Request Body:**
```json
{
  "notes": "Approved. Enjoy your holiday!"
}
```

---

### 12.16 Deny Time-Off Request
```
POST /hrm/time-off/{id}/deny
```

**Access:** A, M

**Business Logic:**
- Update status = DENIED
- Record reason
- Notify requester

**Request Body:**
```json
{
  "notes": "Sorry, we need coverage that week."
}
```

---

### 12.17 Cancel Time-Off Request
```
POST /hrm/time-off/{id}/cancel
```

**Access:** Own, A, M

**Business Logic:**
- Only if status = PENDING or APPROVED
- Update status
- Notify manager

---

### 12.18 Get Staff Performance
```
GET /hrm/performance/{userId}
```

**Access:** A, M

**Business Logic:**
- Aggregate metrics:
  - Orders processed
  - Average order value
  - Tips received
  - Attendance record
  - Customer ratings

---

## 13. Promotions & Loyalty

### 13.1 List Campaigns
```
GET /promotions/campaigns
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `is_active` | boolean | Filter active |
| `type` | string | Campaign type |

---

### 13.2 Get Campaign by ID
```
GET /promotions/campaigns/{id}
```

**Access:** A, M

---

### 13.3 Create Campaign
```
POST /promotions/campaigns
```

**Access:** A, M

**Request Body:**
```json
{
  "name": "Summer Special",
  "code": "SUMMER20",
  "description": "20% off all orders",
  "type": "PERCENTAGE",
  "value": 20,
  "min_order_amount": 25.00,
  "max_discount_amount": 50.00,
  "max_uses": 1000,
  "max_uses_per_customer": 3,
  "valid_from": "2024-06-01T00:00:00Z",
  "valid_until": "2024-08-31T23:59:59Z",
  "is_active": true,
  "applies_to": {
    "category_ids": ["uuid-1"],
    "item_ids": []
  }
}
```

---

### 13.4 Update Campaign
```
PUT /promotions/campaigns/{id}
```

**Access:** A, M

---

### 13.5 Delete Campaign
```
DELETE /promotions/campaigns/{id}
```

**Access:** A

---

### 13.6 Activate/Deactivate Campaign
```
PATCH /promotions/campaigns/{id}/status
```

**Access:** A, M

**Request Body:**
```json
{
  "is_active": false
}
```

---

### 13.7 Validate Promo Code
```
POST /promotions/validate
```

**Access:** All + Public

**Business Logic:**
- Check code exists and is active
- Check validity dates
- Check usage limits
- Check customer eligibility
- Calculate discount amount

**Request Body:**
```json
{
  "code": "SUMMER20",
  "order_subtotal": 50.00,
  "customer_id": "uuid",
  "items": [
    { "menu_item_id": "uuid", "quantity": 2, "price": 25.00 }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "valid": true,
    "campaign": {
      "id": "uuid",
      "name": "Summer Special",
      "type": "PERCENTAGE",
      "value": 20
    },
    "discount_amount": 10.00,
    "message": "20% discount applied"
  }
}
```

---

### 13.8 Get Active Promotions (Public)
```
GET /promotions/active
```

**Access:** Public

**Business Logic:**
- Return currently active promotions
- Used for marketing display

---

### 13.9 Get Loyalty Program Settings
```
GET /loyalty/settings
```

**Access:** A, M, C

---

### 13.10 Update Loyalty Program Settings
```
PUT /loyalty/settings
```

**Access:** A

**Request Body:**
```json
{
  "points_per_dollar": 10,
  "redemption_rate": 0.01,
  "tiers": [
    { "name": "BRONZE", "min_points": 0, "multiplier": 1.0 },
    { "name": "SILVER", "min_points": 1000, "multiplier": 1.25 },
    { "name": "GOLD", "min_points": 5000, "multiplier": 1.5 },
    { "name": "PLATINUM", "min_points": 10000, "multiplier": 2.0 }
  ],
  "expiration_months": 12
}
```

---

### 13.11 Calculate Points for Order
```
POST /loyalty/calculate
```

**Access:** A, M, W

**Business Logic:**
- Calculate points to be earned
- Apply tier multiplier
- Return preview before order completion

**Request Body:**
```json
{
  "customer_id": "uuid",
  "order_total": 50.00
}
```

---

### 13.12 Redeem Points
```
POST /loyalty/redeem
```

**Access:** A, M, W, C

**Business Logic:**
- Validate customer has sufficient points
- Calculate redemption value
- Create REDEEM transaction
- Apply discount to order

**Request Body:**
```json
{
  "customer_id": "uuid",
  "points": 500,
  "order_id": "uuid"
}
```
