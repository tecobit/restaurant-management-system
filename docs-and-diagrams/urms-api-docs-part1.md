# URMS API Documentation

## Unified Restaurant Management System - Complete API Reference

| Info | Details |
|------|---------|
| **Version** | 1.0.0 |
| **Base URL** | `https://api.{tenant}.urms.com/v1` |
| **Auth** | Bearer JWT Token |
| **Content-Type** | application/json |

---

## Table of Contents

1. [Authentication & Authorization](#1-authentication--authorization)
2. [Tenant Management](#2-tenant-management)
3. [User Management](#3-user-management)
4. [Menu Management](#4-menu-management)
5. [Inventory Management](#5-inventory-management)
6. [Order Management](#6-order-management)
7. [Payment & Transactions](#7-payment--transactions)
8. [Reservation Management](#8-reservation-management)
9. [Table & Floor Management](#9-table--floor-management)
10. [Delivery & Logistics](#10-delivery--logistics)
11. [Customer (CRM)](#11-customer-crm)
12. [HRM & Staff](#12-hrm--staff)
13. [Promotions & Loyalty](#13-promotions--loyalty)
14. [CMS & Content](#14-cms--content)
15. [Reports & Analytics](#15-reports--analytics)
16. [Notifications](#16-notifications)
17. [System & Settings](#17-system--settings)

---

## API Conventions

### Authentication Header
```
Authorization: Bearer <jwt_token>
```

### Response Format
```json
{
  "success": true,
  "data": { },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}
```

### Error Format
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      { "field": "email", "message": "Invalid email format" }
    ]
  }
}
```

### Role Abbreviations
- **A** = Admin
- **M** = Manager
- **W** = Waiter
- **K** = Kitchen
- **D** = Driver
- **C** = Customer (Public)

---

## 1. Authentication & Authorization

### 1.1 Register New User
```
POST /auth/register
```

**Access:** Public (Tenant Admin Only for Staff)

**Business Logic:**
- Validate email uniqueness within tenant
- Hash password using bcrypt (12 rounds)
- Assign default role based on registration type
- Send verification email
- Create audit log entry

**Request Body:**
```json
{
  "email": "john@restaurant.com",
  "password": "SecurePass123!",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890",
  "role": "WAITER"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "john@restaurant.com",
    "role": "WAITER",
    "is_active": true,
    "created_at": "2024-12-01T10:00:00Z"
  }
}
```

---

### 1.2 User Login
```
POST /auth/login
```

**Access:** Public

**Business Logic:**
- Validate credentials against stored hash
- Check if user is_active = true
- Check if tenant is ACTIVE (not SUSPENDED)
- Generate JWT with claims: user_id, tenant_id, role
- Update last_login_at timestamp
- Log login event for security audit

**Request Body:**
```json
{
  "email": "john@restaurant.com",
  "password": "SecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJSUzI1NiIs...",
    "expires_in": 3600,
    "token_type": "Bearer",
    "user": {
      "id": "uuid",
      "email": "john@restaurant.com",
      "role": "WAITER",
      "tenant_id": "uuid"
    }
  }
}
```

---

### 1.3 Refresh Token
```
POST /auth/refresh
```

**Access:** Authenticated

**Business Logic:**
- Validate refresh token signature and expiry
- Check if user still active
- Issue new access token
- Optionally rotate refresh token

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOiJSUzI1NiIs..."
}
```

---

### 1.4 Logout
```
POST /auth/logout
```

**Access:** Authenticated

**Business Logic:**
- Invalidate current refresh token
- Add access token to blacklist (Redis)
- Clear session data
- Log logout event

---

### 1.5 Forgot Password
```
POST /auth/forgot-password
```

**Access:** Public

**Business Logic:**
- Generate secure reset token (expires in 1 hour)
- Store hashed token in database
- Send password reset email via SendGrid
- Rate limit: 3 requests per hour per email

**Request Body:**
```json
{
  "email": "john@restaurant.com"
}
```

---

### 1.6 Reset Password
```
POST /auth/reset-password
```

**Access:** Public (with valid token)

**Business Logic:**
- Validate reset token exists and not expired
- Hash new password
- Update user password
- Invalidate all existing sessions
- Delete reset token
- Send confirmation email

**Request Body:**
```json
{
  "token": "reset_token_here",
  "password": "NewSecurePass123!",
  "password_confirmation": "NewSecurePass123!"
}
```

---

### 1.7 Change Password
```
PUT /auth/change-password
```

**Access:** Authenticated

**Business Logic:**
- Verify current password
- Validate new password meets requirements
- Hash and update password
- Optionally invalidate other sessions

**Request Body:**
```json
{
  "current_password": "OldPass123!",
  "new_password": "NewPass456!",
  "new_password_confirmation": "NewPass456!"
}
```

---

### 1.8 Get Current User Profile
```
GET /auth/me
```

**Access:** Authenticated

**Business Logic:**
- Return current user details from JWT claims
- Include role permissions
- Include tenant information

---

## 2. Tenant Management

### 2.1 Get Tenant Details
```
GET /tenant
```

**Access:** A, M

**Business Logic:**
- Return current tenant information
- Include settings, branding, configuration
- Mask sensitive data for non-admin roles

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Joe's Diner",
    "domain": "joes-diner",
    "status": "ACTIVE",
    "settings": {
      "currency_code": "USD",
      "currency_symbol": "$",
      "tax_rate": 0.0825,
      "timezone": "America/New_York",
      "grace_period_minutes": 15,
      "multi_order_dispatch": false
    },
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

---

### 2.2 Update Tenant Settings
```
PUT /tenant/settings
```

**Access:** A

**Business Logic:**
- Validate settings against JSON schema
- Update tenant settings JSONB field
- Clear cached settings in Redis
- Create audit log entry
- Broadcast settings change event

**Request Body:**
```json
{
  "currency_code": "USD",
  "tax_rate": 0.0875,
  "timezone": "America/Los_Angeles",
  "grace_period_minutes": 20,
  "multi_order_dispatch": true,
  "reservation_buffer_minutes": 30,
  "auto_release_minutes": 15
}
```

---

### 2.3 Upload Tenant Logo
```
POST /tenant/logo
```

**Access:** A

**Business Logic:**
- Validate file type (PNG, JPG, SVG)
- Validate file size (max 2MB)
- Resize to multiple dimensions (favicon, header, full)
- Upload to S3 with tenant prefix
- Update tenant settings with URLs
- Invalidate CDN cache

**Request:** `multipart/form-data`

---

## 3. User Management

### 3.1 List Users
```
GET /users
```

**Access:** A, M

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `page` | int | Page number (default: 1) |
| `limit` | int | Items per page (default: 20, max: 100) |
| `role` | string | Filter by role |
| `is_active` | boolean | Filter by status |
| `search` | string | Search by name/email |
| `sort` | string | Sort field (created_at, name, email) |
| `order` | string | Sort order (asc, desc) |

**Business Logic:**
- Apply tenant_id filter automatically (RLS)
- Exclude soft-deleted users (deleted_at IS NULL)
- Apply role-based visibility (Manager can't see Admin)
- Paginate results

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "role": "WAITER",
      "is_active": true,
      "last_login_at": "2024-12-01T10:00:00Z",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "total_pages": 3
  }
}
```

---

### 3.2 Get User by ID
```
GET /users/{id}
```

**Access:** A, M

**Business Logic:**
- Validate user belongs to same tenant
- Return full user profile
- Include related data (shifts, orders created)

---

### 3.3 Create User
```
POST /users
```

**Access:** A

**Business Logic:**
- Validate email uniqueness within tenant
- Generate temporary password or send invite
- Assign role (validate admin can't create super-admin)
- Create user record
- Send welcome email with credentials/invite link
- Create audit log

**Request Body:**
```json
{
  "email": "jane@restaurant.com",
  "first_name": "Jane",
  "last_name": "Smith",
  "phone": "+1234567890",
  "role": "MANAGER",
  "send_invite": true
}
```

---

### 3.4 Update User
```
PUT /users/{id}
```

**Access:** A

**Business Logic:**
- Validate user exists in tenant
- Prevent self-demotion from admin
- Update allowed fields only
- Create audit log with old/new values
- If role changed, invalidate user sessions

**Request Body:**
```json
{
  "first_name": "Jane",
  "last_name": "Smith",
  "phone": "+1234567891",
  "role": "WAITER",
  "is_active": true
}
```

---

### 3.5 Delete User (Soft)
```
DELETE /users/{id}
```

**Access:** A

**Business Logic:**
- Prevent deletion of own account
- Set deleted_at timestamp (soft delete)
- Deactivate user (is_active = false)
- Invalidate all user sessions
- Reassign pending tasks/orders if needed
- Create audit log

---

### 3.6 Activate/Deactivate User
```
PATCH /users/{id}/status
```

**Access:** A

**Business Logic:**
- Toggle is_active status
- If deactivating, invalidate sessions
- Send notification to user
- Create audit log

**Request Body:**
```json
{
  "is_active": false,
  "reason": "Extended leave"
}
```

---

## 4. Menu Management

### 4.1 List Categories
```
GET /menu/categories
```

**Access:** All Roles + Public

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `is_active` | boolean | Filter by status |
| `include_items` | boolean | Include menu items |
| `include_counts` | boolean | Include item counts |

**Business Logic:**
- Return categories sorted by sort_order ASC (FR-06)
- Exclude soft-deleted categories
- For public access, only return is_active = true
- Optionally include nested items

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Appetizers",
      "description": "Start your meal right",
      "image_url": "https://cdn.../appetizers.jpg",
      "sort_order": 1,
      "is_active": true,
      "item_count": 12,
      "items": []
    }
  ]
}
```

---

### 4.2 Get Category by ID
```
GET /menu/categories/{id}
```

**Access:** All Roles + Public

**Business Logic:**
- Return category with full details
- Include all items in category
- Include modifier groups for items

---

### 4.3 Create Category
```
POST /menu/categories
```

**Access:** A, M

**Business Logic:**
- Validate name uniqueness within tenant
- Auto-assign sort_order (max + 1) if not provided
- Process and upload image if provided
- Create audit log

**Request Body:**
```json
{
  "name": "Desserts",
  "description": "Sweet endings",
  "image_url": "https://...",
  "sort_order": 5,
  "is_active": true
}
```

---

### 4.4 Update Category
```
PUT /menu/categories/{id}
```

**Access:** A, M

**Business Logic:**
- Validate category exists
- Update fields
- If image changed, delete old from S3
- Clear menu cache
- Create audit log

---

### 4.5 Delete Category
```
DELETE /menu/categories/{id}
```

**Access:** A, M

**Business Logic:**
- Check for active items in category (FR-07)
- If items exist, return 409 Conflict with count
- Soft delete (set deleted_at)
- Create audit log

**Error Response (409):**
```json
{
  "success": false,
  "error": {
    "code": "CATEGORY_HAS_ITEMS",
    "message": "Cannot delete category with active items",
    "details": {
      "active_item_count": 8
    }
  }
}
```

---

### 4.6 Reorder Categories
```
PUT /menu/categories/reorder
```

**Access:** A, M

**Business Logic:**
- Accept array of category IDs in desired order
- Update sort_order for each in single transaction
- Clear menu cache

**Request Body:**
```json
{
  "category_ids": ["uuid-1", "uuid-3", "uuid-2", "uuid-4"]
}
```

---

### 4.7 List Menu Items
```
GET /menu/items
```

**Access:** All Roles + Public

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `category_id` | uuid | Filter by category |
| `is_available` | boolean | Filter by availability |
| `search` | string | Search by name |
| `min_price` | decimal | Minimum price |
| `max_price` | decimal | Maximum price |
| `allergens` | string[] | Filter by allergens |
| `page` | int | Page number |
| `limit` | int | Items per page |

**Business Logic:**
- Apply tenant filter via RLS
- Exclude soft-deleted items
- For public, only show is_available = true
- Support full-text search via OpenSearch
- Sort by category.sort_order, then item.sort_order

---

### 4.8 Get Menu Item by ID
```
GET /menu/items/{id}
```

**Access:** All Roles + Public

**Business Logic:**
- Return item with full details
- Include category info
- Include all modifier groups and modifiers
- Include recipe cost (for A, M only)
- Include allergen information

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Classic Cheeseburger",
    "description": "Angus beef patty with cheddar",
    "price": 14.99,
    "cost_price": 4.50,
    "margin_percent": 70.0,
    "is_available": true,
    "image_url": "https://...",
    "allergens": ["gluten", "dairy"],
    "prep_time_minutes": 15,
    "category": {
      "id": "uuid",
      "name": "Burgers"
    },
    "modifier_groups": [
      {
        "id": "uuid",
        "name": "Doneness",
        "min_selection": 1,
        "max_selection": 1,
        "is_required": true,
        "modifiers": [
          { "id": "uuid", "name": "Medium Rare", "price_adjustment": 0 },
          { "id": "uuid", "name": "Medium", "price_adjustment": 0 },
          { "id": "uuid", "name": "Well Done", "price_adjustment": 0 }
        ]
      },
      {
        "id": "uuid",
        "name": "Add-ons",
        "min_selection": 0,
        "max_selection": 5,
        "is_required": false,
        "modifiers": [
          { "id": "uuid", "name": "Bacon", "price_adjustment": 2.50 },
          { "id": "uuid", "name": "Extra Cheese", "price_adjustment": 1.50 }
        ]
      }
    ]
  }
}
```

---

### 4.9 Create Menu Item
```
POST /menu/items
```

**Access:** A, M

**Business Logic:**
- Validate category exists and is active
- Validate price >= 0
- Process and upload image
- Create item record
- Link modifier groups if provided
- Index in OpenSearch for search
- Clear menu cache
- Create audit log

**Request Body:**
```json
{
  "category_id": "uuid",
  "name": "Truffle Fries",
  "description": "Crispy fries with truffle oil and parmesan",
  "price": 9.99,
  "cost_price": 2.50,
  "is_available": true,
  "allergens": ["gluten", "dairy"],
  "prep_time_minutes": 10,
  "taxes": [
    { "name": "Sales Tax", "rate": 0.0825 }
  ],
  "modifier_group_ids": ["uuid-1", "uuid-2"]
}
```

---

### 4.10 Update Menu Item
```
PUT /menu/items/{id}
```

**Access:** A, M

**Business Logic:**
- Validate item exists
- If price changed, note that historical orders unaffected (FR-09)
- Update OpenSearch index
- Clear menu cache
- Create audit log with price change tracking

---

### 4.11 Delete Menu Item
```
DELETE /menu/items/{id}
```

**Access:** A, M

**Business Logic:**
- Soft delete (set deleted_at) - FR-10
- Keep for historical analytics
- Remove from active menu
- Update OpenSearch index
- Create audit log

---

### 4.12 Toggle Item Availability (86'd)
```
PATCH /menu/items/{id}/availability
```

**Access:** A, M, W

**Business Logic:**
- Toggle is_available flag (FR-08)
- Immediately hide from POS and online ordering
- Broadcast real-time update via WebSocket
- Log who 86'd the item and when
- Optionally notify manager

**Request Body:**
```json
{
  "is_available": false,
  "reason": "Out of buns"
}
```

---

### 4.13 Bulk Update Item Availability
```
PATCH /menu/items/availability
```

**Access:** A, M

**Business Logic:**
- Update multiple items at once
- Useful for end-of-day 86'ing
- Single transaction for consistency

**Request Body:**
```json
{
  "items": [
    { "id": "uuid-1", "is_available": false },
    { "id": "uuid-2", "is_available": false }
  ]
}
```

---

### 4.14 List Modifier Groups
```
GET /menu/modifier-groups
```

**Access:** A, M

**Business Logic:**
- Return all modifier groups for tenant
- Include modifier count
- Include linked item count

---

### 4.15 Get Modifier Group by ID
```
GET /menu/modifier-groups/{id}
```

**Access:** A, M

**Business Logic:**
- Return group with all modifiers
- Include items using this group

---

### 4.16 Create Modifier Group
```
POST /menu/modifier-groups
```

**Access:** A, M

**Business Logic:**
- Validate min_selection <= max_selection (FR-11)
- Create group
- Create modifiers if provided
- Create audit log

**Request Body:**
```json
{
  "name": "Steak Temperature",
  "description": "How would you like it cooked?",
  "min_selection": 1,
  "max_selection": 1,
  "is_required": true,
  "modifiers": [
    { "name": "Rare", "price_adjustment": 0, "sort_order": 1 },
    { "name": "Medium Rare", "price_adjustment": 0, "sort_order": 2 },
    { "name": "Medium", "price_adjustment": 0, "sort_order": 3 },
    { "name": "Medium Well", "price_adjustment": 0, "sort_order": 4 },
    { "name": "Well Done", "price_adjustment": 0, "sort_order": 5 }
  ]
}
```

---

### 4.17 Update Modifier Group
```
PUT /menu/modifier-groups/{id}
```

**Access:** A, M

---

### 4.18 Delete Modifier Group
```
DELETE /menu/modifier-groups/{id}
```

**Access:** A, M

**Business Logic:**
- Check if linked to any items
- If linked, require force=true or return error
- Cascade delete modifiers
- Remove links from items

---

### 4.19 Link Modifier Group to Item
```
POST /menu/items/{itemId}/modifier-groups
```

**Access:** A, M

**Business Logic:**
- Create link record
- Optionally set override_price (FR-13)

**Request Body:**
```json
{
  "modifier_group_id": "uuid",
  "override_price": 2.00,
  "sort_order": 1
}
```

---

### 4.20 Unlink Modifier Group from Item
```
DELETE /menu/items/{itemId}/modifier-groups/{groupId}
```

**Access:** A, M

---

### 4.21 Get Full Menu (Public)
```
GET /menu
```

**Access:** Public

**Business Logic:**
- Return complete menu structure
- Only active categories and available items
- Cached aggressively (5 min TTL)
- Include all modifiers

**Response:**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": "uuid",
        "name": "Appetizers",
        "items": [
          {
            "id": "uuid",
            "name": "Wings",
            "price": 12.99,
            "modifier_groups": [...]
          }
        ]
      }
    ]
  },
  "meta": {
    "cached_at": "2024-12-01T10:00:00Z",
    "cache_ttl": 300
  }
}
```
