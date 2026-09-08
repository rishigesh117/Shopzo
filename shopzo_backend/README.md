# SHOPZO Backend API & Sync Server (Phase 4)

Node.js + TypeScript + Express + PostgreSQL backend providing central cloud synchronization, phone authentication, multi-tenant shop management, and granular permission controls for the **SHOPZO** Supermarket POS application.

---

## 🚀 Architecture & Core Features

- **Phone Authentication & JWT Session**: Secure login/registration with phone verification & JWT bearer tokens.
- **Shop Management & Unique Shop Code Generator**: Owners create shops with auto-generated unique codes (`SHOP-XXXXXX`).
- **Member System & Invitations**: Employees request to join via shop code or owners invite via phone number.
- **Server-Side Authorization**: Enforces role isolation (`OWNER`, `EMPLOYEE`) and granular feature permissions (`can_create_bills`, `can_add_products`, `can_view_reports`, `is_full_access`).
- **Owner Protection Guardrails**: Prevents demoting, removing, or modifying permissions of the shop owner.
- **Two-Way Synchronization Engine**:
  - `POST /api/sync/push`: Idempotent batch upload of local SQLite `sync_queue` operations.
  - `GET /api/sync/pull`: Incremental delta download of cloud changes since last timestamp.
  - **Conflict Resolution**: Last-Write-Wins (LWW) for products & customers; Idempotent Audit Append for financial bills, stock movements, payments, and returns.

---

## 🛠️ Setup & Installation

### 1. Requirements
- Node.js (v18+)
- PostgreSQL (v14+) or Docker

### 2. Environment Configuration
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Update configuration parameters:
```env
PORT=3000
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/shopzo_db
JWT_SECRET=your_secure_jwt_secret
```

### 3. Install Dependencies
```bash
npm install
```

### 4. Build & Run Tests
```bash
# Run TypeScript compilation check
npx tsc --noEmit

# Run Jest integration test suite (13 tests)
npm test
```

### 5. Start Development Server
```bash
npm run dev
```

---

## 📚 API Endpoints Summary

| Category | Endpoint | Method | Description |
|---|---|---|---|
| **Auth** | `/api/auth/register` | `POST` | User registration with phone & name |
| **Auth** | `/api/auth/login` | `POST` | Phone OTP login & JWT issuance |
| **Auth** | `/api/auth/me` | `GET` | Get authenticated user profile |
| **Shops** | `/api/shops/create` | `POST` | Create shop & generate Shop Code |
| **Shops** | `/api/shops/my-shops` | `GET` | Get user's shops & membership roles |
| **Members**| `/api/members/request-join`| `POST` | Employee join request via Shop Code |
| **Members**| `/api/members/invite` | `POST` | Owner invite employee by phone |
| **Members**| `/api/members/requests` | `GET` | View pending join requests for shop |
| **Members**| `/api/members/requests/:id/accept` | `POST` | Owner approve employee request |
| **Members**| `/api/members/requests/:id/reject` | `POST` | Owner reject employee request |
| **Members**| `/api/members/invitations` | `GET` | User's pending shop invitations |
| **Members**| `/api/members/:userId` | `DELETE` | Owner remove member (protected) |
| **Sync** | `/api/sync/push` | `POST` | Idempotent local-to-cloud data upload |
| **Sync** | `/api/sync/pull` | `POST`/`GET` | Incremental cloud-to-local data delta |

---

## 🛡️ License
Copyright © 2026 SHOPZO. Proprietary & Confidential.
