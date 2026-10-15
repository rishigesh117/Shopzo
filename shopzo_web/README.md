# Shopzo Web Application 🌐

Modern, high-performance web application for **Shopzo** designed to run seamlessly on **Google Chrome across laptops, desktops, and mobile devices**.

It connects directly to the **same PostgreSQL database and backend** (`https://shopzo-nine.vercel.app`) as the Shopzo Android application, ensuring all data (products, sales, Khata credit dues, staff, and reports) stays synchronized in real-time.

---

## 🚀 Features

- **Point of Sale (POS) Terminal**:
  - Live product catalog search with category filtering.
  - Keyboard and touch-friendly cart with quantity controls.
  - Multi-payment support: **Cash**, **UPI**, **Card**, and **Khata / Store Credit**.
  - Instant thermal receipt printing (58mm/80mm) and standard A4 invoice generation via browser print dialogue.
- **Unified Inventory & Stock Management**:
  - Real-time stock counts, re-order alerts, and low stock indicators.
  - Profit margin calculation per product.
  - One-click restock dialog and catalog editing.
- **Khata / Customer Credit Ledger**:
  - Customer directory with total lifetime purchase tracking.
  - Outstanding dues ledger with quick "Record Payment" modal.
- **Sales & Invoices History**:
  - Full transaction archive with search by invoice number, customer name, or phone.
  - Filter by payment method and payment status (Paid, Partial, Unpaid).
  - One-click CSV export and receipt reprint.
- **Staff & Permission Management**:
  - Invite team cashiers/managers with individual login credentials.
  - Granular permission control: Billing, Inventory Edit, Reports, Team Management.
- **Financial Analytics & Reports**:
  - Date filtering: Today, This Week, This Month, All Time.
  - Revenue, Gross Profit, and Margin % breakdowns.
  - Payment method share comparison (Cash vs. UPI vs. Card vs. Khata).
  - Inventory valuation: Cost basis vs. Retail value vs. Unrealized profit.
- **Store & Account Settings**:
  - Prominently displays the verified **Store Owner Name** and Mobile Number.
  - Multi-store switching and creation of new store branches.
  - Live database sync status and diagnostics with `https://shopzo-nine.vercel.app`.

---

## 🛠️ Tech Stack

- **Framework**: React 18 + Vite 5 + TypeScript
- **Styling**: Tailored Vanilla CSS design system with custom CSS variables (dark slate modern aesthetic, fully responsive across laptops and mobile devices)
- **Icons**: Lucide React
- **Cloud Backend**: Node.js + Express + PostgreSQL on Vercel (`https://shopzo-nine.vercel.app`)

---

## 💻 Running Locally

To start the web application on your local machine:

```bash
cd shopzo_web
npm install
npm run dev
```

Then open **`http://localhost:5173`** in Google Chrome on your laptop or mobile phone.

---

## 📦 Building for Production

To create an optimized production build:

```bash
cd shopzo_web
npm run build
```

The output will be placed in the `dist/` directory, ready to deploy to Vercel, Netlify, Cloudflare Pages, or Firebase Hosting.
