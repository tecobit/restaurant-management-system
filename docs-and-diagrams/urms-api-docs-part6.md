# URMS API Documentation - Part 6

## 14. CMS & Content

### 14.1 List Pages
```
GET /cms/pages
```

**Access:** A, M + Public (published only)

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `is_published` | boolean | Filter by publish status |
| `search` | string | Search by title |

---

### 14.2 Get Page by ID
```
GET /cms/pages/{id}
```

**Access:** A, M + Public (if published)

---

### 14.3 Get Page by Slug
```
GET /cms/pages/slug/{slug}
```

**Access:** Public (if published)

**Business Logic (FR-38):**
- Lookup by unique slug within tenant
- Return 404 if not found or not published
- Cache aggressively

---

### 14.4 Create Page
```
POST /cms/pages
```

**Access:** A, M

**Business Logic (FR-38, FR-39):**
- Validate slug uniqueness
- Validate slug format (lowercase, alphanumeric, hyphens)
- Validate content_blocks schema

**Request Body:**
```json
{
  "slug": "about-us",
  "title": "About Us",
  "meta_description": "Learn about our restaurant",
  "content_blocks": [
    {
      "type": "hero",
      "props": {
        "title": "Our Story",
        "subtitle": "Family owned since 1985",
        "backgroundImage": "https://..."
      }
    },
    {
      "type": "text_block",
      "props": {
        "content": "We started as a small family restaurant..."
      }
    },
    {
      "type": "image_gallery",
      "props": {
        "images": ["https://...", "https://..."]
      }
    }
  ],
  "is_published": false
}
```

---

### 14.5 Update Page
```
PUT /cms/pages/{id}
```

**Access:** A, M

---

### 14.6 Delete Page
```
DELETE /cms/pages/{id}
```

**Access:** A

---

### 14.7 Publish Page
```
POST /cms/pages/{id}/publish
```

**Access:** A, M

**Business Logic:**
- Set is_published = true
- Set published_at timestamp
- Clear cache

---

### 14.8 Unpublish Page
```
POST /cms/pages/{id}/unpublish
```

**Access:** A, M

---

### 14.9 Duplicate Page
```
POST /cms/pages/{id}/duplicate
```

**Access:** A, M

**Business Logic:**
- Create copy with new slug (append -copy)
- Set is_published = false

---

### 14.10 List Media
```
GET /cms/media
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `mime_type` | string | Filter by type (image/*, application/pdf) |
| `search` | string | Search filename |

---

### 14.11 Upload Media
```
POST /cms/media
```

**Access:** A, M

**Business Logic:**
- Validate file type and size
- Generate unique filename
- Upload to S3
- Create thumbnail for images
- Store metadata

**Request:** `multipart/form-data`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "filename": "hero-image-abc123.jpg",
    "original_filename": "restaurant-front.jpg",
    "mime_type": "image/jpeg",
    "storage_url": "https://cdn.../hero-image-abc123.jpg",
    "file_size_bytes": 245000,
    "width_px": 1920,
    "height_px": 1080
  }
}
```

---

### 14.12 Get Media by ID
```
GET /cms/media/{id}
```

**Access:** A, M

---

### 14.13 Update Media Metadata
```
PUT /cms/media/{id}
```

**Access:** A, M

**Request Body:**
```json
{
  "alt_text": "Front view of restaurant"
}
```

---

### 14.14 Delete Media
```
DELETE /cms/media/{id}
```

**Access:** A

**Business Logic:**
- Check if used in any pages
- Delete from S3
- Delete record

---

## 15. Reports & Analytics

### 15.1 Sales Summary Report
```
GET /reports/sales/summary
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `start_date` | date | Period start |
| `end_date` | date | Period end |
| `group_by` | string | day, week, month |

**Response:**
```json
{
  "success": true,
  "data": {
    "period": {
      "start": "2024-12-01",
      "end": "2024-12-07"
    },
    "summary": {
      "total_revenue": 25650.00,
      "total_orders": 342,
      "average_order_value": 75.00,
      "total_tips": 3850.00,
      "total_discounts": 1250.00,
      "total_refunds": 150.00,
      "net_revenue": 24400.00
    },
    "by_order_type": {
      "DINE_IN": { "revenue": 15000.00, "orders": 180 },
      "TAKEOUT": { "revenue": 5500.00, "orders": 92 },
      "DELIVERY": { "revenue": 5150.00, "orders": 70 }
    },
    "by_payment_method": {
      "CARD": { "amount": 20000.00, "count": 280 },
      "CASH": { "amount": 5650.00, "count": 62 }
    },
    "trend": [
      { "date": "2024-12-01", "revenue": 3500.00, "orders": 48 },
      { "date": "2024-12-02", "revenue": 3200.00, "orders": 45 }
    ]
  }
}
```

---

### 15.2 Sales by Category Report
```
GET /reports/sales/by-category
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `start_date` | date | Period start |
| `end_date` | date | Period end |

**Response:**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "category_id": "uuid",
        "category_name": "Burgers",
        "total_revenue": 8500.00,
        "total_quantity": 420,
        "percentage_of_sales": 33.1
      }
    ]
  }
}
```

---

### 15.3 Sales by Item Report
```
GET /reports/sales/by-item
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `start_date` | date | Period start |
| `end_date` | date | Period end |
| `category_id` | uuid | Filter by category |
| `sort_by` | string | revenue, quantity |
| `limit` | int | Top N items |

---

### 15.4 Hourly Sales Report
```
GET /reports/sales/hourly
```

**Access:** A, M

**Business Logic:**
- Sales aggregated by hour
- Identify peak hours
- Useful for staffing decisions

---

### 15.5 Staff Performance Report
```
GET /reports/staff/performance
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `start_date` | date | Period start |
| `end_date` | date | Period end |
| `user_id` | uuid | Specific staff member |

**Response:**
```json
{
  "success": true,
  "data": {
    "staff": [
      {
        "user_id": "uuid",
        "name": "John Doe",
        "role": "WAITER",
        "metrics": {
          "orders_processed": 156,
          "total_sales": 12500.00,
          "average_order_value": 80.13,
          "tips_received": 1875.00,
          "hours_worked": 42.5,
          "sales_per_hour": 294.12,
          "attendance": {
            "shifts_scheduled": 6,
            "shifts_completed": 6,
            "late_count": 1,
            "total_late_minutes": 12
          }
        }
      }
    ]
  }
}
```

---

### 15.6 Inventory Value Report
```
GET /reports/inventory/value
```

**Access:** A, M

**Business Logic:**
- Calculate total inventory value
- current_stock × cost_per_unit
- Group by category/supplier

---

### 15.7 Inventory Movement Report
```
GET /reports/inventory/movement
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `start_date` | date | Period start |
| `end_date` | date | Period end |
| `ingredient_id` | uuid | Specific ingredient |

**Business Logic:**
- Summarize stock movements
- Opening balance → movements → closing balance
- Highlight waste percentages

---

### 15.8 Food Cost Report
```
GET /reports/inventory/food-cost
```

**Access:** A, M

**Business Logic:**
- Calculate actual vs theoretical food cost
- Identify cost variances
- Track waste impact

**Response:**
```json
{
  "success": true,
  "data": {
    "period": {
      "start": "2024-12-01",
      "end": "2024-12-07"
    },
    "summary": {
      "total_sales": 25650.00,
      "theoretical_cost": 7695.00,
      "theoretical_cost_percent": 30.0,
      "actual_cost": 8200.00,
      "actual_cost_percent": 31.97,
      "variance": 505.00,
      "variance_percent": 1.97,
      "waste_cost": 350.00
    },
    "by_category": [
      {
        "category": "Burgers",
        "sales": 8500.00,
        "theoretical_cost": 2550.00,
        "actual_cost": 2800.00,
        "variance": 250.00
      }
    ]
  }
}
```

---

### 15.9 Waste Report
```
GET /reports/inventory/waste
```

**Access:** A, M

**Business Logic:**
- Aggregate waste entries from stock log
- Categorize by reason
- Calculate cost of waste

---

### 15.10 Reservation Report
```
GET /reports/reservations
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `start_date` | date | Period start |
| `end_date` | date | Period end |

**Response:**
```json
{
  "success": true,
  "data": {
    "summary": {
      "total_reservations": 245,
      "completed": 210,
      "no_shows": 25,
      "cancelled": 10,
      "no_show_rate": 10.2,
      "average_party_size": 3.2,
      "average_duration_minutes": 75
    },
    "by_day_of_week": {
      "monday": 28,
      "tuesday": 32,
      "friday": 55,
      "saturday": 62
    },
    "by_time_slot": {
      "17:00-18:00": 35,
      "18:00-19:00": 68,
      "19:00-20:00": 72,
      "20:00-21:00": 45
    }
  }
}
```

---

### 15.11 Delivery Performance Report
```
GET /reports/delivery/performance
```

**Access:** A, M

**Business Logic:**
- Average delivery time
- On-time percentage
- Driver performance
- Zone performance

---

### 15.12 Customer Analytics Report
```
GET /reports/customers/analytics
```

**Access:** A, M

**Response:**
```json
{
  "success": true,
  "data": {
    "summary": {
      "total_customers": 1250,
      "new_customers_period": 85,
      "returning_customers": 420,
      "retention_rate": 33.6,
      "average_lifetime_value": 285.00
    },
    "by_tier": {
      "BRONZE": 850,
      "SILVER": 280,
      "GOLD": 95,
      "PLATINUM": 25
    },
    "top_customers": [
      {
        "customer_id": "uuid",
        "name": "John D.",
        "total_spent": 2500.00,
        "visit_count": 32
      }
    ]
  }
}
```

---

### 15.13 Tax Report
```
GET /reports/tax
```

**Access:** A, M

**Business Logic:**
- Aggregate tax collected
- Group by tax type
- Export-ready format

---

### 15.14 Daily Summary Report
```
GET /reports/daily-summary
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `date` | date | Date for report |

**Business Logic:**
- Complete end-of-day summary
- Sales, orders, payments, tips
- Cash drawer reconciliation
- Ready for manager review

---

### 15.15 Export Report
```
POST /reports/export
```

**Access:** A, M

**Business Logic:**
- Generate report in specified format
- Return download URL
- Support PDF, CSV, Excel

**Request Body:**
```json
{
  "report_type": "sales_summary",
  "format": "pdf",
  "parameters": {
    "start_date": "2024-12-01",
    "end_date": "2024-12-31"
  }
}
```

---

### 15.16 Dashboard KPIs
```
GET /reports/dashboard
```

**Access:** A, M

**Business Logic:**
- Real-time key metrics
- Compared to yesterday/last week
- Cached with short TTL

**Response:**
```json
{
  "success": true,
  "data": {
    "today": {
      "revenue": 3250.00,
      "revenue_change": 12.5,
      "orders": 42,
      "orders_change": 8.3,
      "average_order": 77.38,
      "active_orders": 8,
      "tables_occupied": 12,
      "reservations_remaining": 15
    },
    "alerts": [
      { "type": "LOW_STOCK", "count": 3 },
      { "type": "PENDING_RESERVATIONS", "count": 2 }
    ]
  }
}
```

---

## 16. Notifications

### 16.1 List Notifications
```
GET /notifications
```

**Access:** All authenticated

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `is_read` | boolean | Filter by read status |
| `type` | string | Filter by type |
| `page` | int | Page number |

---

### 16.2 Get Notification by ID
```
GET /notifications/{id}
```

**Access:** Own notifications

---

### 16.3 Mark Notification as Read
```
PATCH /notifications/{id}/read
```

**Access:** Own notifications

---

### 16.4 Mark All as Read
```
POST /notifications/mark-all-read
```

**Access:** All authenticated

---

### 16.5 Delete Notification
```
DELETE /notifications/{id}
```

**Access:** Own notifications

---

### 16.6 Get Unread Count
```
GET /notifications/unread-count
```

**Access:** All authenticated

---

### 16.7 Update Notification Preferences
```
PUT /notifications/preferences
```

**Access:** All authenticated

**Request Body:**
```json
{
  "email": {
    "order_updates": true,
    "low_stock_alerts": true,
    "reservation_reminders": true
  },
  "push": {
    "order_updates": true,
    "new_orders": true
  },
  "sms": {
    "critical_alerts": true
  }
}
```

---

### 16.8 Send Test Notification
```
POST /notifications/test
```

**Access:** A

**Business Logic:**
- Send test notification to verify settings
- Supports email, push, SMS

---

## 17. System & Settings

### 17.1 Health Check
```
GET /health
```

**Access:** Public

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2024-12-01T10:00:00Z",
  "services": {
    "database": "healthy",
    "cache": "healthy",
    "queue": "healthy"
  }
}
```

---

### 17.2 Get System Info
```
GET /system/info
```

**Access:** A

**Business Logic:**
- Return system configuration
- Version info
- Feature flags

---

### 17.3 Get Audit Logs
```
GET /system/audit-logs
```

**Access:** A

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `user_id` | uuid | Filter by user |
| `entity_type` | string | Filter by entity |
| `action` | string | CREATE, UPDATE, DELETE |
| `start_date` | datetime | Range start |
| `end_date` | datetime | Range end |
| `page` | int | Page number |

---

### 17.4 Export Audit Logs
```
POST /system/audit-logs/export
```

**Access:** A

---

### 17.5 Get Feature Flags
```
GET /system/features
```

**Access:** A, M

**Business Logic:**
- Return enabled features for tenant
- Used for progressive rollout

---

### 17.6 Update Feature Flags
```
PUT /system/features
```

**Access:** A (Super Admin)

---

### 17.7 Clear Cache
```
POST /system/cache/clear
```

**Access:** A

**Business Logic:**
- Clear Redis cache
- Specify patterns to clear

**Request Body:**
```json
{
  "patterns": ["menu:*", "settings:*"]
}
```

---

### 17.8 Get API Rate Limits
```
GET /system/rate-limits
```

**Access:** A

---

### 17.9 Database Backup (Trigger)
```
POST /system/backup
```

**Access:** A (Super Admin)

**Business Logic:**
- Trigger manual backup
- Upload to S3
- Return backup reference

---

### 17.10 Get Integrations Status
```
GET /system/integrations
```

**Access:** A

**Response:**
```json
{
  "success": true,
  "data": {
    "integrations": {
      "stripe": { "status": "connected", "last_webhook": "2024-12-01T09:55:00Z" },
      "twilio": { "status": "connected", "balance": 125.50 },
      "sendgrid": { "status": "connected", "emails_sent_today": 45 }
    }
  }
}
```

---

### 17.11 Webhook Management
```
GET /system/webhooks
POST /system/webhooks
PUT /system/webhooks/{id}
DELETE /system/webhooks/{id}
```

**Access:** A

**Business Logic:**
- Configure outgoing webhooks
- Notify external systems of events

---

### 17.12 API Keys Management
```
GET /system/api-keys
POST /system/api-keys
DELETE /system/api-keys/{id}
```

**Access:** A

**Business Logic:**
- Generate API keys for integrations
- Set permissions and rate limits
- Track usage

---

## API Summary

| Module | Endpoints | Description |
|--------|-----------|-------------|
| Authentication | 8 | Login, register, password management |
| Tenant | 3 | Tenant settings and branding |
| Users | 6 | User CRUD and status management |
| Menu | 21 | Categories, items, modifiers |
| Inventory | 28 | Ingredients, recipes, stock, POs |
| Orders | 20 | Order lifecycle and management |
| Payments | 13 | Transactions, refunds, fiscal |
| Reservations | 13 | Bookings and waitlist |
| Tables | 19 | Floors, tables, status |
| Delivery | 25 | Zones, drivers, shipments |
| Customers | 17 | CRM and loyalty |
| HRM | 18 | Shifts and time-off |
| Promotions | 12 | Campaigns and loyalty program |
| CMS | 14 | Pages and media |
| Reports | 16 | Analytics and exports |
| Notifications | 8 | Alerts and preferences |
| System | 12 | Admin and maintenance |
| **Total** | **253** | |

---

*API Documentation v1.0 - URMS*
