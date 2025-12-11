# URMS API Complete Index

## Quick Reference - All 253 Endpoints

### Authentication & Authorization (8 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| POST | `/auth/register` | Register new user | Public/A |
| POST | `/auth/login` | User login | Public |
| POST | `/auth/refresh` | Refresh token | Auth |
| POST | `/auth/logout` | Logout user | Auth |
| POST | `/auth/forgot-password` | Request password reset | Public |
| POST | `/auth/reset-password` | Reset password with token | Public |
| PUT | `/auth/change-password` | Change password | Auth |
| GET | `/auth/me` | Get current user profile | Auth |

### Tenant Management (3 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/tenant` | Get tenant details | A, M |
| PUT | `/tenant/settings` | Update tenant settings | A |
| POST | `/tenant/logo` | Upload tenant logo | A |

### User Management (6 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/users` | List all users | A, M |
| GET | `/users/{id}` | Get user by ID | A, M |
| POST | `/users` | Create new user | A |
| PUT | `/users/{id}` | Update user | A |
| DELETE | `/menu/modifier-groups/{id}` | Delete modifier group | A, M |
| POST | `/menu/items/{itemId}/modifier-groups` | Link modifier to item | A, M |
| DELETE | `/menu/items/{itemId}/modifier-groups/{groupId}` | Unlink modifier | A, M |

### Inventory - Ingredients (9 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/inventory/ingredients` | List ingredients | A, M |
| GET | `/inventory/ingredients/{id}` | Get ingredient | A, M |
| POST | `/inventory/ingredients` | Create ingredient | A, M |
| PUT | `/inventory/ingredients/{id}` | Update ingredient | A, M |
| DELETE | `/inventory/ingredients/{id}` | Delete ingredient | A |
| POST | `/inventory/ingredients/{id}/adjust` | Manual stock adjust | A, M |
| POST | `/inventory/ingredients/{id}/waste` | Record waste | A, M, K |
| GET | `/inventory/ingredients/{id}/logs` | Get stock log | A, M |
| POST | `/inventory/stock-take` | Bulk stock take | A, M |

### Inventory - Suppliers (5 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/inventory/suppliers` | List suppliers | A, M |
| GET | `/inventory/suppliers/{id}` | Get supplier | A, M |
| POST | `/inventory/suppliers` | Create supplier | A, M |
| PUT | `/inventory/suppliers/{id}` | Update supplier | A, M |
| DELETE | `/inventory/suppliers/{id}` | Delete supplier | A |

### Inventory - Purchase Orders (7 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/inventory/purchase-orders` | List POs | A, M |
| GET | `/inventory/purchase-orders/{id}` | Get PO | A, M |
| POST | `/inventory/purchase-orders` | Create PO | A, M |
| PUT | `/inventory/purchase-orders/{id}` | Update PO | A, M |
| POST | `/inventory/purchase-orders/{id}/send` | Send to supplier | A, M |
| POST | `/inventory/purchase-orders/{id}/receive` | Receive stock | A, M |
| POST | `/inventory/purchase-orders/{id}/cancel` | Cancel PO | A, M |

### Inventory - Recipes (5 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/inventory/recipes` | List recipes | A, M |
| GET | `/inventory/recipes/{id}` | Get recipe | A, M |
| PUT | `/menu/items/{itemId}/recipe` | Create/update recipe | A, M |
| DELETE | `/menu/items/{itemId}/recipe` | Delete recipe | A, M |
| GET | `/inventory/recipes/{id}/cost` | Calculate cost | A, M |

### Inventory - Alerts (2 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/inventory/alerts/low-stock` | Get low stock alerts | A, M |

### Orders (20 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/orders` | List orders | A, M, W, K |
| GET | `/orders/{id}` | Get order by ID | A, M, W, K |
| POST | `/orders` | Create order | A, M, W |
| POST | `/orders/{id}/items` | Add item to order | A, M, W |
| PUT | `/orders/{orderId}/items/{itemId}` | Update order item | A, M, W |
| DELETE | `/orders/{orderId}/items/{itemId}` | Remove order item | A, M, W |
| POST | `/orders/{orderId}/items/{itemId}/void` | Void order item | A, M |
| POST | `/orders/{id}/confirm` | Confirm/send to kitchen | A, M, W |
| PATCH | `/orders/{orderId}/items/{itemId}/status` | Update item status (KDS) | A, M, K |
| POST | `/orders/{id}/ready` | Mark order ready | A, M, K |
| POST | `/orders/{id}/serve` | Mark order served | A, M, W |
| POST | `/orders/{id}/discounts` | Apply discount | A, M |
| DELETE | `/orders/{orderId}/discounts/{discountId}` | Remove discount | A, M |
| POST | `/orders/{id}/cancel` | Cancel order | A, M |
| GET | `/kds/orders` | Get KDS orders | K |
| GET | `/tables/{tableId}/orders/active` | Get active orders for table | A, M, W |
| POST | `/orders/{id}/transfer` | Transfer to another table | A, M, W |
| POST | `/orders/merge` | Merge orders | A, M |
| POST | `/orders/{id}/split` | Split order | A, M, W |
| GET | `/customers/{customerId}/orders` | Customer order history | A, M, C |

### Payments & Transactions (13 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/orders/{id}/payment-summary` | Get payment summary | A, M, W |
| POST | `/payments/intent` | Create payment intent | A, M, W |
| POST | `/orders/{id}/transactions` | Process payment | A, M, W |
| POST | `/orders/{id}/transactions/cash` | Process cash payment | A, M, W |
| POST | `/orders/{id}/transactions/split` | Split bill payment | A, M, W |
| GET | `/transactions/{id}` | Get transaction | A, M |
| GET | `/transactions` | List transactions | A, M |
| POST | `/transactions/{id}/refund` | Process refund | A, M |
| GET | `/transactions/{id}/fiscal-receipt` | Get fiscal receipt | A, M |
| POST | `/transactions/{id}/fiscal-receipt` | Generate fiscal receipt | A, M |
| GET | `/fiscal-receipts/verify` | Verify receipt chain | A |
| GET | `/transactions/cash-summary` | Daily cash summary | A, M |
| POST | `/transactions/drawer-count` | Record drawer count | A, M |

### Reservations (13 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/reservations` | List reservations | A, M, W |
| GET | `/reservations/{id}` | Get reservation | A, M, W |
| GET | `/reservations/availability` | Check availability | A, M, W, C |
| POST | `/reservations` | Create reservation | A, M, W, C |
| PUT | `/reservations/{id}` | Update reservation | A, M, W |
| POST | `/reservations/{id}/confirm` | Confirm reservation | A, M, W |
| POST | `/reservations/{id}/seat` | Seat guest | A, M, W |
| POST | `/reservations/{id}/no-show` | Mark no-show | A, M |
| POST | `/reservations/{id}/cancel` | Cancel reservation | A, M, W, C |
| POST | `/reservations/{id}/complete` | Complete reservation | A, M, W |
| GET | `/reservations/timeline` | Get timeline view | A, M, W |
| POST | `/reservations/{id}/remind` | Send reminder | A, M |
| GET | `/reservations/lookup/{code}` | Lookup by code | Public |

### Tables & Floors (19 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/floors` | List floor plans | A, M, W |
| GET | `/floors/{id}` | Get floor plan | A, M, W |
| POST | `/floors` | Create floor plan | A, M |
| PUT | `/floors/{id}` | Update floor plan | A, M |
| DELETE | `/floors/{id}` | Delete floor plan | A |
| GET | `/tables` | List tables | A, M, W |
| GET | `/tables/{id}` | Get table | A, M, W |
| POST | `/tables` | Create table | A, M |
| PUT | `/tables/{id}` | Update table | A, M |
| DELETE | `/tables/{id}` | Delete table | A |
| PATCH | `/tables/{id}/position` | Update position | A, M |
| PUT | `/tables/positions` | Bulk update positions | A, M |
| GET | `/tables/status` | Get status overview | A, M, W |
| GET | `/waitlist` | List waitlist | A, M, W |
| POST | `/waitlist` | Add to waitlist | A, M, W |
| PUT | `/waitlist/{id}` | Update waitlist entry | A, M, W |
| POST | `/waitlist/{id}/notify` | Notify guest | A, M, W |
| POST | `/waitlist/{id}/seat` | Seat guest | A, M, W |
| DELETE | `/waitlist/{id}` | Remove from waitlist | A, M, W |

### Delivery & Logistics (25 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/delivery/zones` | List delivery zones | A, M |
| GET | `/delivery/zones/{id}` | Get zone | A, M |
| POST | `/delivery/zones` | Create zone | A, M |
| PUT | `/delivery/zones/{id}` | Update zone | A, M |
| DELETE | `/delivery/zones/{id}` | Delete zone | A |
| POST | `/delivery/validate-address` | Validate delivery address | A, M, W, C |
| GET | `/delivery/drivers` | List drivers | A, M |
| GET | `/delivery/drivers/{id}` | Get driver | A, M |
| POST | `/delivery/drivers` | Create driver profile | A, M |
| PUT | `/delivery/drivers/{id}` | Update driver | A, M |
| PATCH | `/delivery/drivers/{id}/status` | Update driver status | A, M, D |
| POST | `/delivery/drivers/{id}/location` | Update location | D |
| GET | `/delivery/shipments` | List shipments | A, M, D |
| GET | `/delivery/shipments/{id}` | Get shipment | A, M, D |
| POST | `/delivery/shipments` | Create shipment | A, M, W |
| POST | `/delivery/shipments/{id}/assign` | Assign driver | A, M |
| POST | `/delivery/shipments/{id}/auto-assign` | Auto-assign driver | A, M |
| POST | `/delivery/shipments/{id}/accept` | Accept shipment | D |
| POST | `/delivery/shipments/{id}/pickup` | Mark picked up | D |
| PATCH | `/delivery/shipments/{id}/status` | Update status | A, M, D |
| POST | `/delivery/shipments/{id}/deliver` | Mark delivered | D |
| POST | `/delivery/shipments/{id}/fail` | Mark failed | D, A, M |
| GET | `/delivery/shipments/{tracking_code}/track` | Track shipment | Public |
| GET | `/delivery/drivers/{id}/locations` | Location history | A, M |
| GET | `/delivery/analytics` | Delivery analytics | A, M |

### Customers / CRM (17 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/customers` | List customers | A, M |
| GET | `/customers/{id}` | Get customer | A, M, C |
| POST | `/customers` | Create customer | A, M, W, Public |
| PUT | `/customers/{id}` | Update customer | A, M, C |
| DELETE | `/customers/{id}` | Delete customer (GDPR) | A |
| GET | `/customers/search` | Search customers | A, M, W |
| GET | `/customers/{id}/addresses` | Get addresses | A, M, C |
| POST | `/customers/{id}/addresses` | Add address | A, M, C |
| PUT | `/customers/{cid}/addresses/{aid}` | Update address | A, M, C |
| DELETE | `/customers/{cid}/addresses/{aid}` | Delete address | A, M, C |
| GET | `/customers/{id}/orders` | Order history | A, M, C |
| GET | `/customers/{id}/loyalty` | Get loyalty points | A, M, C |
| GET | `/customers/{id}/loyalty/history` | Loyalty history | A, M, C |
| POST | `/customers/{id}/loyalty/adjust` | Adjust points | A, M |
| GET | `/customers/{id}/preferences` | Get preferences | A, M, C |
| PUT | `/customers/{id}/preferences` | Update preferences | A, M, C |
| POST | `/customers/merge` | Merge profiles | A |

### HRM & Staff (18 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/hrm/shifts` | List shifts | A, M |
| GET | `/hrm/shifts/{id}` | Get shift | A, M, Own |
| GET | `/hrm/shifts/me` | Get my shifts | Auth |
| POST | `/hrm/shifts` | Create shift | A, M |
| PUT | `/hrm/shifts/{id}` | Update shift | A, M |
| DELETE | `/hrm/shifts/{id}` | Delete shift | A, M |
| POST | `/hrm/shifts/{id}/clock-in` | Clock in | A, M, Own |
| POST | `/hrm/shifts/{id}/clock-out` | Clock out | A, M, Own |
| GET | `/hrm/timesheet` | Get timesheet | A, M |
| POST | `/hrm/shifts/bulk` | Bulk create shifts | A, M |
| POST | `/hrm/shifts/copy` | Copy schedule | A, M |
| GET | `/hrm/time-off` | List time-off requests | A, M |
| GET | `/hrm/time-off/me` | My time-off requests | Auth |
| POST | `/hrm/time-off` | Create request | Auth |
| POST | `/hrm/time-off/{id}/approve` | Approve request | A, M |
| POST | `/hrm/time-off/{id}/deny` | Deny request | A, M |
| POST | `/hrm/time-off/{id}/cancel` | Cancel request | Own, A, M |
| GET | `/hrm/performance/{userId}` | Staff performance | A, M |

### Promotions & Loyalty (12 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/promotions/campaigns` | List campaigns | A, M |
| GET | `/promotions/campaigns/{id}` | Get campaign | A, M |
| POST | `/promotions/campaigns` | Create campaign | A, M |
| PUT | `/promotions/campaigns/{id}` | Update campaign | A, M |
| DELETE | `/promotions/campaigns/{id}` | Delete campaign | A |
| PATCH | `/promotions/campaigns/{id}/status` | Toggle active | A, M |
| POST | `/promotions/validate` | Validate promo code | All + Public |
| GET | `/promotions/active` | Get active promos | Public |
| GET | `/loyalty/settings` | Get loyalty settings | A, M, C |
| PUT | `/loyalty/settings` | Update loyalty settings | A |
| POST | `/loyalty/calculate` | Calculate points | A, M, W |
| POST | `/loyalty/redeem` | Redeem points | A, M, W, C |

### CMS & Content (14 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/cms/pages` | List pages | A, M + Public |
| GET | `/cms/pages/{id}` | Get page by ID | A, M + Public |
| GET | `/cms/pages/slug/{slug}` | Get page by slug | Public |
| POST | `/cms/pages` | Create page | A, M |
| PUT | `/cms/pages/{id}` | Update page | A, M |
| DELETE | `/cms/pages/{id}` | Delete page | A |
| POST | `/cms/pages/{id}/publish` | Publish page | A, M |
| POST | `/cms/pages/{id}/unpublish` | Unpublish page | A, M |
| POST | `/cms/pages/{id}/duplicate` | Duplicate page | A, M |
| GET | `/cms/media` | List media | A, M |
| POST | `/cms/media` | Upload media | A, M |
| GET | `/cms/media/{id}` | Get media | A, M |
| PUT | `/cms/media/{id}` | Update media | A, M |
| DELETE | `/cms/media/{id}` | Delete media | A |

### Reports & Analytics (16 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/reports/sales/summary` | Sales summary | A, M |
| GET | `/reports/sales/by-category` | Sales by category | A, M |
| GET | `/reports/sales/by-item` | Sales by item | A, M |
| GET | `/reports/sales/hourly` | Hourly sales | A, M |
| GET | `/reports/staff/performance` | Staff performance | A, M |
| GET | `/reports/inventory/value` | Inventory value | A, M |
| GET | `/reports/inventory/movement` | Stock movement | A, M |
| GET | `/reports/inventory/food-cost` | Food cost analysis | A, M |
| GET | `/reports/inventory/waste` | Waste report | A, M |
| GET | `/reports/reservations` | Reservation report | A, M |
| GET | `/reports/delivery/performance` | Delivery performance | A, M |
| GET | `/reports/customers/analytics` | Customer analytics | A, M |
| GET | `/reports/tax` | Tax report | A, M |
| GET | `/reports/daily-summary` | Daily summary | A, M |
| POST | `/reports/export` | Export report | A, M |
| GET | `/reports/dashboard` | Dashboard KPIs | A, M |

### Notifications (8 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/notifications` | List notifications | Auth |
| GET | `/notifications/{id}` | Get notification | Own |
| PATCH | `/notifications/{id}/read` | Mark as read | Own |
| POST | `/notifications/mark-all-read` | Mark all read | Auth |
| DELETE | `/notifications/{id}` | Delete notification | Own |
| GET | `/notifications/unread-count` | Get unread count | Auth |
| PUT | `/notifications/preferences` | Update preferences | Auth |
| POST | `/notifications/test` | Send test notification | A |

### System & Settings (12 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/health` | Health check | Public |
| GET | `/system/info` | System info | A |
| GET | `/system/audit-logs` | Get audit logs | A |
| POST | `/system/audit-logs/export` | Export audit logs | A |
| GET | `/system/features` | Get feature flags | A, M |
| PUT | `/system/features` | Update feature flags | A |
| POST | `/system/cache/clear` | Clear cache | A |
| GET | `/system/rate-limits` | Get rate limits | A |
| POST | `/system/backup` | Trigger backup | A |
| GET | `/system/integrations` | Integration status | A |
| GET/POST/PUT/DELETE | `/system/webhooks` | Webhook management | A |
| GET/POST/DELETE | `/system/api-keys` | API key management | A |

---

## Summary by Module

| Module | Count | Key Features |
|--------|-------|--------------|
| Auth | 8 | JWT, password reset, MFA ready |
| Tenant | 3 | Multi-tenant settings |
| Users | 6 | RBAC, soft delete |
| Menu | 21 | Categories, items, modifiers, 86'd |
| Inventory | 28 | Stock, recipes, POs, waste tracking |
| Orders | 20 | Full lifecycle, KDS, split/merge |
| Payments | 13 | Split bills, tips, fiscal receipts |
| Reservations | 13 | Availability, no-show handling |
| Tables | 19 | Floor plans, waitlist, status |
| Delivery | 25 | Zones, drivers, tracking, POD |
| CRM | 17 | Customers, addresses, loyalty |
| HRM | 18 | Shifts, clock in/out, time-off |
| Promotions | 12 | Campaigns, promo codes, loyalty |
| CMS | 14 | Pages, media, SEO |
| Reports | 16 | Sales, inventory, performance |
| Notifications | 8 | Multi-channel alerts |
| System | 12 | Admin, audit, integrations |
| **TOTAL** | **253** | |

---

## Role Access Legend

| Code | Role | Description |
|------|------|-------------|
| A | Admin | Full system access |
| M | Manager | Operations + reports |
| W | Waiter | Orders + tables |
| K | Kitchen | KDS + order status |
| D | Driver | Delivery operations |
| C | Customer | Own data only |
| Auth | Authenticated | Any logged-in user |
| Public | Public | No auth required |
| Own | Own | Only own resources |users/{id}` | Soft delete user | A |
| PATCH | `/users/{id}/status` | Activate/deactivate user | A |

### Menu - Categories (6 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/menu/categories` | List categories | All + Public |
| GET | `/menu/categories/{id}` | Get category by ID | All + Public |
| POST | `/menu/categories` | Create category | A, M |
| PUT | `/menu/categories/{id}` | Update category | A, M |
| DELETE | `/menu/categories/{id}` | Delete category | A, M |
| PUT | `/menu/categories/reorder` | Reorder categories | A, M |

### Menu - Items (9 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/menu/items` | List menu items | All + Public |
| GET | `/menu/items/{id}` | Get item by ID | All + Public |
| POST | `/menu/items` | Create menu item | A, M |
| PUT | `/menu/items/{id}` | Update menu item | A, M |
| DELETE | `/menu/items/{id}` | Soft delete item | A, M |
| PATCH | `/menu/items/{id}/availability` | Toggle 86'd status | A, M, W |
| PATCH | `/menu/items/availability` | Bulk update availability | A, M |
| GET | `/menu` | Get full public menu | Public |
| GET | `/menu/items/{id}/recipe` | Get item recipe | A, M |

### Menu - Modifiers (6 endpoints)
| Method | Path | Description | Access |
|--------|------|-------------|--------|
| GET | `/menu/modifier-groups` | List modifier groups | A, M |
| GET | `/menu/modifier-groups/{id}` | Get modifier group | A, M |
| POST | `/menu/modifier-groups` | Create modifier group | A, M |
| PUT | `/menu/modifier-groups/{id}` | Update modifier group | A, M |
| DELETE | `/