# SHOPZO Application Architecture

## 1. System Overview

**SHOPZO** is an offline-first Supermarket POS and inventory management application designed with a hybrid SQLite local storage + Cloud PostgreSQL synchronization architecture.

```text
                  +-----------------------------------+
                  |          SHOPZO FLUTTER APP       |
                  |  (UI, Providers, Connectivity)    |
                  +-----------------+-----------------+
                                    |
                    +---------------+---------------+
                    |                               |
                    v                               v
       +-------------------------+     +-------------------------+
       |   SQLite Local DB       |     |   ApiService Client     |
       |  - products, categories |     |   - Bearer JWT Auth     |
       |  - bills, bill_items    |     |   - HTTP Push/Pull      |
       |  - customers, payments  |     +------------+------------+
       |  - returns, movements   |                  |
       |  - sync_queue           |                  | REST API / JSON
       +-------------------------+                  v
                                       +-------------------------+
                                       |  SHOPZO BACKEND API     |
                                       |  (Node.js + Express)    |
                                       +------------+------------+
                                                    |
                                                    v
                                       +-------------------------+
                                       |   PostgreSQL Cloud DB   |
                                       |  - Tenant Isolation     |
                                       |  - Member Management    |
                                       |  - Centralized Audit    |
                                       +-------------------------+
```

---

## 2. Key Architecture Components

### 2.1 Offline-First Local Database (SQLite)
- All daily operations (billing, stock adjustments, payments, returns) write directly to the local SQLite database inside atomic transactions.
- Offline operations automatically enqueue pending changes into `sync_queue`.
- App requires 0 network latency for checkout operations.

### 2.2 Flutter Network & Sync Engine
- **`ConnectivityService`**: Continuously monitors online/offline connection state.
- **`SyncService`**: Triggers auto-synchronization upon internet reconnection.
  - **Push Engine (`POST /api/sync/push`)**: Uploads queued operations in chronological order.
  - **Pull Engine (`GET /api/sync/pull`)**: Downloads delta updates from cloud PostgreSQL based on `last_synced_at` timestamp.
- **`SyncProvider`**: Drives UI state (`Synced`, `Syncing`, `Offline Mode`, `Sync Error`).

### 2.3 Cloud Backend Server (`shopzo_backend`)
- **Technology Stack**: Node.js, TypeScript, Express, PostgreSQL (`pg`), JWT, bcryptjs.
- **Phone Auth & Session**: Secures API access via JWT bearer token.
- **Multi-Tenant Shop Isolation**: All resources (`products`, `bills`, `members`) are scoped to `shop_id`.
- **Member Management & Granular Permissions**:
  - `OWNER` & `EMPLOYEE` roles.
  - Custom permissions: `can_create_bills`, `can_add_products`, `can_view_reports`, `is_full_access`.
  - **Owner Protection**: Hardened guards prevent demotion or removal of shop owner.
- **Conflict Resolution**:
  - **Last-Write-Wins (LWW)**: Applied to master data (`products`, `categories`, `customers`).
  - **Idempotent Audit Append**: Applied to transaction data (`bills`, `payments`, `returns`, `stock_movements`).

---

## 3. Data Flow Example: Offline Checkout to Cloud Sync

1. Cashier creates a bill in offline mode.
2. `BillRepository` saves bill, bill items, decreases product stock, logs stock movement, and creates payment record inside an atomic SQLite transaction.
3. `BillRepository` calls `SyncService.instance.enqueueChange()`, inserting an `INSERT` payload into `sync_queue`.
4. When internet returns, `ConnectivityService` detects network connection and notifies `SyncService`.
5. `SyncService` batches pending `sync_queue` items and calls `POST /api/sync/push`.
6. Cloud backend validates shop membership, verifies permissions, and ingests bill idempotently into PostgreSQL.
7. Local SQLite marks `sync_queue` item as completed and removes it. UI updates `SyncStatusBadge` to `Synced`.
