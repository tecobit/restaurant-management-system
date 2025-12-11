# URMS API Documentation - Part 3

## 7. Payment & Transactions

### 7.1 Get Order Payment Summary
```
GET /orders/{id}/payment-summary
```

**Access:** A, M, W

**Business Logic:**
- Calculate order totals
- Show existing payments
- Calculate remaining balance
- Show applicable tips

**Response:**
```json
{
  "success": true,
  "data": {
    "order_id": "uuid",
    "subtotal": 85.00,
    "tax_amount": 7.01,
    "discount_amount": 8.50,
    "total_amount": 83.51,
    "payments_received": 50.00,
    "balance_due": 33.51,
    "transactions": [
      {
        "id": "uuid",
        "amount": 50.00,
        "tip_amount": 0,
        "method": "CARD",
        "status": "COMPLETED",
        "created_at": "2024-12-01T19:00:00Z"
      }
    ]
  }
}
```

---

### 7.2 Create Payment Intent
```
POST /payments/intent
```

**Access:** A, M, W

**Business Logic:**
- Create Stripe PaymentIntent
- Store intent ID for tracking
- Return client_secret for frontend

**Request Body:**
```json
{
  "order_id": "uuid",
  "amount": 83.51,
  "currency": "usd"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "payment_intent_id": "pi_xxx",
    "client_secret": "pi_xxx_secret_xxx",
    "amount": 83.51,
    "currency": "usd"
  }
}
```

---

### 7.3 Process Payment
```
POST /orders/{id}/transactions
```

**Access:** A, M, W

**Business Logic (FR-25, FR-26):**
1. Validate order status allows payment
2. Validate amount > 0
3. For CARD: Verify Stripe payment succeeded
4. Create POS_Transaction record
5. Calculate tip if amount > balance due (FR-26)
6. Check if order fully paid:
   - Sum(transactions) >= order total
   - Update status = PAID (FR-21)
7. Generate fiscal receipt (FR-27)
8. Update customer loyalty points
9. Send receipt via email/SMS

**Request Body:**
```json
{
  "amount": 50.00,
  "tip_amount": 10.00,
  "method": "CARD",
  "gateway_ref": "pi_xxx_completed",
  "card_last_four": "4242"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transaction_id": "uuid",
    "amount": 50.00,
    "tip_amount": 10.00,
    "method": "CARD",
    "status": "COMPLETED",
    "order_status": "SERVED",
    "balance_due": 33.51,
    "receipt_url": "https://..."
  }
}
```

---

### 7.4 Process Cash Payment
```
POST /orders/{id}/transactions/cash
```

**Access:** A, M, W

**Business Logic:**
- Record cash payment
- Calculate change if overpaid
- Handle tip separately

**Request Body:**
```json
{
  "amount_tendered": 100.00,
  "tip_amount": 15.00
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transaction_id": "uuid",
    "amount": 83.51,
    "tip_amount": 15.00,
    "amount_tendered": 100.00,
    "change_due": 1.49,
    "order_status": "PAID"
  }
}
```

---

### 7.5 Split Bill Payment
```
POST /orders/{id}/transactions/split
```

**Access:** A, M, W

**Business Logic (FR-25):**
- Accept multiple payment records
- Process each payment
- Track partial payments
- Handle mixed methods (card + cash)

**Request Body:**
```json
{
  "payments": [
    { "amount": 30.00, "method": "CARD", "gateway_ref": "pi_xxx" },
    { "amount": 30.00, "method": "CARD", "gateway_ref": "pi_yyy" },
    { "amount": 23.51, "method": "CASH", "tip_amount": 5.00 }
  ]
}
```

---

### 7.6 Get Transaction by ID
```
GET /transactions/{id}
```

**Access:** A, M

**Business Logic:**
- Return full transaction details
- Include fiscal receipt if generated
- Include refund history

---

### 7.7 List Transactions
```
GET /transactions
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `order_id` | uuid | Filter by order |
| `method` | string | Filter by payment method |
| `status` | string | Filter by status |
| `start_date` | date | Range start |
| `end_date` | date | Range end |
| `page` | int | Page number |

---

### 7.8 Process Refund
```
POST /transactions/{id}/refund
```

**Access:** A, M

**Business Logic:**
- Validate refund amount <= original amount
- For CARD: Process via Stripe
- Create POS_Refund record
- Update transaction status
- Generate refund receipt
- Reverse loyalty points if applicable
- Create audit log

**Request Body:**
```json
{
  "amount": 25.00,
  "reason": "Item not as described"
}
```

---

### 7.9 Get Fiscal Receipt
```
GET /transactions/{id}/fiscal-receipt
```

**Access:** A, M

**Business Logic:**
- Return fiscal receipt details
- Include hash chain verification
- Include printable format

---

### 7.10 Generate Fiscal Receipt (Manual)
```
POST /transactions/{id}/fiscal-receipt
```

**Access:** A, M

**Business Logic (FR-27):**
1. Get previous receipt hash
2. Build receipt data snapshot
3. Calculate SHA-256 hash:
   - hash = SHA256(data + prev_hash + timestamp)
4. Generate sequential receipt number
5. Create POS_FiscalReceipt record
6. Return printable receipt

---

### 7.11 Verify Receipt Chain
```
GET /fiscal-receipts/verify
```

**Access:** A

**Business Logic:**
- Verify hash chain integrity
- Detect any tampering
- Return verification report

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `start_date` | date | Range start |
| `end_date` | date | Range end |

---

### 7.12 Get Daily Cash Summary
```
GET /transactions/cash-summary
```

**Access:** A, M

**Business Logic:**
- Sum all cash transactions for the day
- Calculate expected drawer amount
- Compare to opening balance

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `date` | date | Date to summarize |

---

### 7.13 Record Cash Drawer Count
```
POST /transactions/drawer-count
```

**Access:** A, M

**Business Logic:**
- Record physical cash count
- Compare to expected
- Flag discrepancies
- Required for shift close

**Request Body:**
```json
{
  "count_type": "CLOSE",
  "bills": {
    "100": 2,
    "50": 5,
    "20": 15,
    "10": 10,
    "5": 8,
    "1": 25
  },
  "coins": {
    "quarters": 40,
    "dimes": 30,
    "nickels": 20,
    "pennies": 50
  },
  "notes": "All correct"
}
```

---

## 8. Reservation Management

### 8.1 List Reservations
```
GET /reservations
```

**Access:** A, M, W

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `date` | date | Filter by date |
| `status` | string | Filter by status |
| `table_id` | uuid | Filter by table |
| `customer_id` | uuid | Filter by customer |
| `page` | int | Page number |

**Business Logic:**
- Default to today's reservations
- Sort by start_time ASC
- Include table and customer details

---

### 8.2 Get Reservation by ID
```
GET /reservations/{id}
```

**Access:** A, M, W

---

### 8.3 Check Availability
```
GET /reservations/availability
```

**Access:** A, M, W, C

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `date` | date | Date to check |
| `time` | time | Preferred time |
| `party_size` | int | Number of guests |
| `duration_minutes` | int | Expected duration (default: 90) |

**Business Logic:**
- Find tables with capacity >= party_size
- Check for conflicting reservations (FR-30)
- Consider buffer time between reservations
- Return available time slots

**Response:**
```json
{
  "success": true,
  "data": {
    "date": "2024-12-15",
    "party_size": 4,
    "available_slots": [
      {
        "time": "17:00",
        "tables": [
          { "id": "uuid", "table_number": "T5", "capacity": 4 },
          { "id": "uuid", "table_number": "T8", "capacity": 6 }
        ]
      },
      {
        "time": "17:30",
        "tables": [
          { "id": "uuid", "table_number": "T5", "capacity": 4 }
        ]
      }
    ]
  }
}
```

---

### 8.4 Create Reservation
```
POST /reservations
```

**Access:** A, M, W, C

**Business Logic (FR-30):**
1. Validate table exists and is active
2. Check for conflicts:
   - (NewStart < ExistingEnd) AND (NewEnd > ExistingStart)
   - Same table_id
   - Status not CANCELLED or NO_SHOW
3. If conflict, return 409
4. Generate confirmation code
5. Create reservation with status = PENDING or CONFIRMED
6. Send confirmation SMS/email
7. Create audit log

**Request Body:**
```json
{
  "table_id": "uuid",
  "customer_id": "uuid",
  "start_time": "2024-12-15T18:00:00Z",
  "end_time": "2024-12-15T20:00:00Z",
  "party_size": 4,
  "guest_name": "John Smith",
  "guest_phone": "+1234567890",
  "guest_email": "john@example.com",
  "special_requests": "Window table preferred, anniversary dinner",
  "source": "WEBSITE"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "confirmation_code": "RES-ABC123",
    "table": {