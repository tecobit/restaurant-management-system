# URMS API Documentation - Part 4

## 8. Reservation Management (continued)

### 8.5 Update Reservation
```
PUT /reservations/{id}
```

**Access:** A, M, W

**Business Logic:**
- Validate no new conflicts if time/table changed
- Update allowed fields
- Send update notification to guest
- Create audit log

---

### 8.6 Confirm Reservation
```
POST /reservations/{id}/confirm
```

**Access:** A, M, W

**Business Logic:**
- Update status = CONFIRMED
- Send confirmation to guest

---

### 8.7 Seat Reservation
```
POST /reservations/{id}/seat
```

**Access:** A, M, W

**Business Logic:**
- Validate status = CONFIRMED
- Update status = SEATED
- Optionally create new order for table
- Record seated timestamp

**Request Body:**
```json
{
  "create_order": true,
  "notes": "Seated at T5"
}
```

---

### 8.8 Mark No-Show
```
POST /reservations/{id}/no-show
```

**Access:** A, M

**Business Logic (FR-31):**
- Update status = NO_SHOW
- Free up the table
- Update customer no_show_count
- Optionally blacklist repeat offenders
- Create audit log

---

### 8.9 Cancel Reservation
```
POST /reservations/{id}/cancel
```

**Access:** A, M, W, C (own reservations)

**Business Logic:**
- Update status = CANCELLED
- Free up the table slot
- Send cancellation confirmation
- Create audit log

**Request Body:**
```json
{
  "reason": "Change of plans",
  "notify_guest": true
}
```

---

### 8.10 Complete Reservation
```
POST /reservations/{id}/complete
```

**Access:** A, M, W

**Business Logic:**
- Update status = COMPLETED
- Record actual duration
- Update customer visit stats

---

### 8.11 Get Today's Reservations Timeline
```
GET /reservations/timeline
```

**Access:** A, M, W

**Business Logic:**
- Return all reservations for date
- Grouped by table
- Formatted for timeline view

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `date` | date | Date to view (default: today) |
| `floor_id` | uuid | Filter by floor |

---

### 8.12 Send Reservation Reminder
```
POST /reservations/{id}/remind
```

**Access:** A, M

**Business Logic:**
- Send SMS/email reminder
- Update reminded_at timestamp

---

### 8.13 Lookup Reservation by Code
```
GET /reservations/lookup/{code}
```

**Access:** Public

**Business Logic:**
- Find reservation by confirmation code
- Return limited public details
- Used for customer self-service

---

## 9. Table & Floor Management

### 9.1 List Floor Plans
```
GET /floors
```

**Access:** A, M, W

**Business Logic:**
- Return all floor plans
- Include table count per floor
- Sort by sort_order

---

### 9.2 Get Floor Plan by ID
```
GET /floors/{id}
```

**Access:** A, M, W

**Business Logic:**
- Return floor with all tables
- Include table positions for canvas rendering

---

### 9.3 Create Floor Plan
```
POST /floors
```

**Access:** A, M

**Request Body:**
```json
{
  "name": "Patio",
  "width_px": 800,
  "height_px": 600,
  "background_image_url": "https://...",
  "is_active": true
}
```

---

### 9.4 Update Floor Plan
```
PUT /floors/{id}
```

**Access:** A, M

---

### 9.5 Delete Floor Plan
```
DELETE /floors/{id}
```

**Access:** A

**Business Logic:**
- Check for tables on floor
- If tables exist, require force or reassignment
- Cascade delete tables if forced

---

### 9.6 List Tables
```
GET /tables
```

**Access:** A, M, W

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `floor_id` | uuid | Filter by floor |
| `is_active` | boolean | Filter by status |
| `min_capacity` | int | Minimum seats |
| `status` | string | FREE, OCCUPIED, RESERVED |

**Business Logic:**
- Include computed occupancy status (FR-29)
- Include current order if occupied
- Include upcoming reservation

---

### 9.7 Get Table by ID
```
GET /tables/{id}
```

**Access:** A, M, W

**Business Logic (FR-29):**
- Return table details
- Compute occupancy status dynamically:
  - Check for open orders linked to table
  - If exists and not PAID/COMPLETED/CANCELLED → OCCUPIED
  - Else → FREE
- Include current order details if occupied

---

### 9.8 Create Table
```
POST /tables
```

**Access:** A, M

**Request Body:**
```json
{
  "floor_id": "uuid",
  "table_number": "T15",
  "seat_capacity": 6,
  "min_capacity": 2,
  "x_coord": 350,
  "y_coord": 200,
  "shape": "RECTANGLE",
  "width_px": 80,
  "height_px": 60,
  "is_active": true
}
```

---

### 9.9 Update Table
```
PUT /tables/{id}
```

**Access:** A, M

---

### 9.10 Delete Table
```
DELETE /tables/{id}
```

**Access:** A

**Business Logic:**
- Check for active orders
- Check for future reservations
- Soft delete or hard delete based on history

---

### 9.11 Update Table Position
```
PATCH /tables/{id}/position
```

**Access:** A, M

**Business Logic:**
- Update x_coord, y_coord (FR-28)
- Used by drag-and-drop floor editor

**Request Body:**
```json
{
  "x_coord": 400,
  "y_coord": 250
}
```

---

### 9.12 Bulk Update Table Positions
```
PUT /tables/positions
```

**Access:** A, M

**Business Logic:**
- Update multiple tables in single transaction
- Used after floor rearrangement

**Request Body:**
```json
{
  "tables": [
    { "id": "uuid-1", "x_coord": 100, "y_coord": 100 },
    { "id": "uuid-2", "x_coord": 200, "y_coord": 100 }
  ]
}
```

---

### 9.13 Get Table Status Overview
```
GET /tables/status
```

**Access:** A, M, W

**Business Logic:**
- Real-time status of all tables
- Aggregated counts by status
- Used for host stand view

**Response:**
```json
{
  "success": true,
  "data": {
    "summary": {
      "total": 25,
      "free": 12,
      "occupied": 10,
      "reserved": 3
    },
    "tables": [
      {
        "id": "uuid",
        "table_number": "T1",
        "floor": "Main Hall",
        "status": "OCCUPIED",
        "capacity": 4,
        "current_order": {
          "id": "uuid",
          "order_number": "ORD-xxx",
          "status": "SERVED",
          "duration_minutes": 45
        },
        "next_reservation": null
      }
    ]
  }
}
```

---

### 9.14 List Waitlist
```
GET /waitlist
```

**Access:** A, M, W

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `status` | string | WAITING, NOTIFIED, SEATED, LEFT |
| `date` | date | Filter by date |

---

### 9.15 Add to Waitlist
```
POST /waitlist
```

**Access:** A, M, W

**Request Body:**
```json
{
  "customer_id": "uuid",
  "guest_name": "Jane Doe",
  "guest_phone": "+1234567890",
  "party_size": 3,
  "notes": "Prefers booth"
}
```

**Business Logic:**
- Calculate estimated wait based on current turnover
- Add to queue
- Send confirmation SMS

---

### 9.16 Update Waitlist Entry
```
PUT /waitlist/{id}
```

**Access:** A, M, W

---

### 9.17 Notify Waitlist Guest
```
POST /waitlist/{id}/notify
```

**Access:** A, M, W

**Business Logic:**
- Send "table ready" SMS
- Update status = NOTIFIED
- Start grace period timer

---

### 9.18 Seat Waitlist Guest
```
POST /waitlist/{id}/seat
```

**Access:** A, M, W

**Request Body:**
```json
{
  "table_id": "uuid",
  "create_order": true
}
```

**Business Logic:**
- Update status = SEATED
- Create order if requested
- Link customer to order

---

### 9.19 Remove from Waitlist
```
DELETE /waitlist/{id}
```

**Access:** A, M, W

**Business Logic:**
- Update status = LEFT
- Record reason

---

## 10. Delivery & Logistics

### 10.1 List Delivery Zones
```
GET /delivery/zones
```

**Access:** A, M

**Business Logic:**
- Return all zones for tenant
- Include GeoJSON polygons
- Include fee and ETA info

---

### 10.2 Get Delivery Zone by ID
```
GET /delivery/zones/{id}
```

**Access:** A, M

---

### 10.3 Create Delivery Zone
```
POST /delivery/zones
```

**Access:** A, M

**Business Logic (FR-32):**
- Validate GeoJSON polygon format
- Calculate and store area_sqkm (FR-33)
- Check for overlaps (allowed but flagged)

**Request Body:**
```json
{
  "name": "Downtown",
  "polygon": {
    "type": "Polygon",
    "coordinates": [[[lng1, lat1], [lng2, lat2], [lng3, lat3], [lng1, lat1]]]
  },
  "delivery_fee": 3.99,
  "min_order_amount": 15.00,
  "estimated_minutes": 25,
  "is_active": true
}
```

---

### 10.4 Update Delivery Zone
```
PUT /delivery/zones/{id}
```

**Access:** A, M

---

### 10.5 Delete Delivery Zone
```
DELETE /delivery/zones/{id}
```

**Access:** A

---

### 10.6 Validate Delivery Address
```
POST /delivery/validate-address
```

**Access:** A, M, W, C

**Business Logic (FR-33):**
1. Geocode address to coordinates
2. Query zones using ST_Contains(polygon, point)
3. If multiple matches, select smallest area
4. Return zone, fee, and ETA

**Request Body:**
```json
{
  "address": "123 Main St, City, State 12345"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "is_deliverable": true,
    "coordinates": {
      "lat": 40.7128,
      "lng": -74.0060
    },
    "zone": {
      "id": "uuid",
      "name": "Downtown",
      "delivery_fee": 3.99,
      "estimated_minutes": 25,
      "min_order_amount": 15.00
    }
  }
}
```

---

### 10.7 List Drivers
```
GET /delivery/drivers
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `status` | string | OFFLINE, IDLE, ON_JOB |
| `available` | boolean | Only assignable drivers |

---

### 10.8 Get Driver by ID
```
GET /delivery/drivers/{id}
```

**Access:** A, M

**Business Logic:**
- Return driver details
- Include current location
- Include active deliveries
- Include performance stats

---

### 10.9 Create Driver Profile
```
POST /delivery/drivers
```

**Access:** A, M

**Business Logic:**
- Link to existing user with DRIVER role
- Set initial status = OFFLINE

**Request Body:**
```json
{
  "user_id": "uuid",
  "vehicle_type": "SCOOTER",
  "license_plate": "ABC123"
}
```

---

### 10.10 Update Driver Profile
```
PUT /delivery/drivers/{id}
```

**Access:** A, M

---

### 10.11 Update Driver Status
```
PATCH /delivery/drivers/{id}/status
```

**Access:** A, M, D (own status)

**Business Logic (FR-34):**
- Validate status transitions
- OFFLINE: Cannot receive orders
- IDLE: Can receive orders
- ON_JOB: Only if multi_order_dispatch enabled

**Request Body:**
```json
{
  "status": "IDLE"
}
```

---

### 10.12 Update Driver Location
```
POST /delivery/drivers/{id}/location
```

**Access:** D (own location)

**Business Logic:**
- Update current_lat, current_lng
- Create LOG_DriverLocation record
- Update last_location_update timestamp
- Broadcast to tracking subscribers

**Request Body:**
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "accuracy_meters": 10.5
}
```

---

### 10.13 List Shipments
```
GET /delivery/shipments
```

**Access:** A, M, D

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `status` | string | Filter by status |
| `driver_id` | uuid | Filter by driver |
| `date` | date | Filter by date |
| `page` | int | Page number |

---

### 10.14 Get Shipment by ID
```
GET /delivery/shipments/{id}
```

**Access:** A, M, D

---

### 10.15 Create Shipment
```
POST /delivery/shipments
```

**Access:** A, M, W

**Business Logic:**
- Generate tracking code
- Validate delivery address in zone
- Link to order
- Set status = PENDING

**Request Body:**
```json
{
  "order_id": "uuid",
  "delivery_address": "123 Main St, City, State 12345",
  "delivery_lat": 40.7128,
  "delivery_lng": -74.0060,
  "recipient_name": "John Doe",
  "recipient_phone": "+1234567890",
  "delivery_instructions": "Ring doorbell twice",
  "zone_id": "uuid"
}
```

---

### 10.16 Assign Driver to Shipment
```
POST /delivery/shipments/{id}/assign
```

**Access:** A, M

**Business Logic (FR-34):**
- Validate driver is available
- Check multi_order_dispatch setting
- Update shipment driver_id
- Update shipment status = ASSIGNED
- Increment driver active_order_count
- Send push notification to driver

**Request Body:**
```json
{
  "driver_id": "uuid"
}
```

---

### 10.17 Auto-Assign Driver
```
POST /delivery/shipments/{id}/auto-assign
```

**Access:** A, M

**Business Logic:**
- Find optimal driver based on:
  - Current location (closest)
  - Current load (least busy)
  - Rating (highest)
- Assign driver
- Notify driver

---

### 10.18 Driver Accept Shipment
```
POST /delivery/shipments/{id}/accept
```

**Access:** D

**Business Logic:**
- Confirm driver acceptance
- Start tracking

---

### 10.19 Mark Shipment Picked Up
```
POST /delivery/shipments/{id}/pickup
```

**Access:** D

**Business Logic:**
- Update status = PICKED_UP
- Record picked_up_at timestamp
- Notify customer
- Start active tracking

---

### 10.20 Update Shipment Status
```
PATCH /delivery/shipments/{id}/status
```

**Access:** A, M, D

**Business Logic:**
- Validate status transitions:
  - PENDING → ASSIGNED → PICKED_UP → IN_TRANSIT → DELIVERED/FAILED
- Update timestamps

---

### 10.21 Mark Shipment Delivered
```
POST /delivery/shipments/{id}/deliver
```

**Access:** D

**Business Logic (FR-35):**
- Require proof_photo_url
- Validate photo metadata:
  - Timestamp within 5 minutes
  - GPS within 100m of delivery address
- Update status = DELIVERED
- Record delivered_at
- Decrement driver active_order_count
- Increment driver total_deliveries
- Update order status
- Send delivery confirmation to customer

**Request Body:**
```json
{
  "proof_photo_url": "https://s3.../proof.jpg",
  "notes": "Left at front door"
}
```

---

### 10.22 Mark Shipment Failed
```
POST /delivery/shipments/{id}/fail
```

**Access:** D, A, M

**Business Logic:**
- Update status = FAILED
- Record failure_reason
- Notify customer and restaurant
- Decrement driver active_order_count
- Trigger rescheduling workflow

**Request Body:**
```json
{
  "reason": "Customer not available",
  "notes": "Tried calling 3 times"
}
```

---

### 10.23 Get Shipment Tracking
```
GET /delivery/shipments/{tracking_code}/track
```

**Access:** Public (with tracking code)

**Business Logic:**
- Return limited public tracking info
- Include driver location if IN_TRANSIT
- Include ETA

**Response:**
```json
{
  "success": true,
  "data": {
    "tracking_code": "TRK-ABC123",
    "status": "IN_TRANSIT",
    "driver": {
      "name": "Mike D.",
      "phone": "+1234567890",
      "vehicle": "Blue Scooter",
      "current_location": {
        "lat": 40.7150,
        "lng": -74.0080
      }
    },
    "destination": {
      "lat": 40.7128,
      "lng": -74.0060
    },
    "eta_minutes": 8,
    "timeline": [
      { "status": "CONFIRMED", "at": "2024-12-01T18:00:00Z" },
      { "status": "PREPARING", "at": "2024-12-01T18:05:00Z" },
      { "status": "PICKED_UP", "at": "2024-12-01T18:25:00Z" },
      { "status": "IN_TRANSIT", "at": "2024-12-01T18:26:00Z" }
    ]
  }
}
```

---

### 10.24 Get Driver Location History
```
GET /delivery/drivers/{id}/locations
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `shipment_id` | uuid | Filter by shipment |
| `start_time` | datetime | Range start |
| `end_time` | datetime | Range end |

---

### 10.25 Get Delivery Analytics
```
GET /delivery/analytics
```

**Access:** A, M

**Business Logic:**
- Average delivery time
- Deliveries per driver
- Success/failure rates
- Zone performance
