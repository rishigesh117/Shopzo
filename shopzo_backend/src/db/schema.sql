-- SHOPZO PostgreSQL Database Schema
-- Multi-Tenant Architecture with shop_id isolation

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    mobile_number VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS shops (
    id VARCHAR(64) PRIMARY KEY,
    shop_code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    owner_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    address VARCHAR(255),
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS staff_permissions (
    id VARCHAR(64) PRIMARY KEY,
    shop_id VARCHAR(64) NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'STAFF', -- OWNER, STAFF
    permissions JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_shop_user UNIQUE (shop_id, user_id)
);

CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(64) PRIMARY KEY,
    shop_id VARCHAR(64) NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(64) PRIMARY KEY,
    shop_id VARCHAR(64) NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    category_id VARCHAR(64) NOT NULL,
    name VARCHAR(100) NOT NULL,
    brand VARCHAR(100),
    buying_price_paise BIGINT NOT NULL DEFAULT 0,
    selling_price_paise BIGINT NOT NULL DEFAULT 0,
    quantity NUMERIC(12, 3) NOT NULL DEFAULT 0,
    unit VARCHAR(20) NOT NULL DEFAULT 'PCS',
    min_stock_level NUMERIC(12, 3) NOT NULL DEFAULT 0,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS stock_movements (
    id VARCHAR(64) PRIMARY KEY,
    shop_id VARCHAR(64) NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    product_id VARCHAR(64) NOT NULL,
    type VARCHAR(20) NOT NULL, -- RESTOCK, ADJUSTMENT, SALE, RETURN
    quantity NUMERIC(12, 3) NOT NULL,
    reason VARCHAR(255),
    created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS customers (
    id VARCHAR(64) PRIMARY KEY,
    shop_id VARCHAR(64) NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    mobile_number VARCHAR(20) NOT NULL,
    address VARCHAR(255),
    total_purchase_paise BIGINT NOT NULL DEFAULT 0,
    outstanding_due_paise BIGINT NOT NULL DEFAULT 0,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS bills (
    id VARCHAR(64) PRIMARY KEY,
    shop_id VARCHAR(64) NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    bill_number VARCHAR(50) NOT NULL,
    customer_id VARCHAR(64),
    customer_name_snapshot VARCHAR(100) NOT NULL DEFAULT 'Walk-in Customer',
    customer_mobile_snapshot VARCHAR(20) NOT NULL DEFAULT '',
    subtotal_paise BIGINT NOT NULL DEFAULT 0,
    grand_total_paise BIGINT NOT NULL DEFAULT 0,
    paid_amount_paise BIGINT NOT NULL DEFAULT 0,
    pending_amount_paise BIGINT NOT NULL DEFAULT 0,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PAID', -- PAID, PARTIALLY_PAID, PENDING
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uk_shop_bill_number UNIQUE (shop_id, bill_number)
);

CREATE TABLE IF NOT EXISTS bill_items (
    id VARCHAR(64) PRIMARY KEY,
    shop_id VARCHAR(64) NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    bill_id VARCHAR(64) NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    product_id VARCHAR(64) NOT NULL,
    product_name_snapshot VARCHAR(100) NOT NULL,
    quantity NUMERIC(12, 3) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    selling_price_paise BIGINT NOT NULL,
    buying_price_paise BIGINT NOT NULL,
    subtotal_paise BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS payments (
    id VARCHAR(64) PRIMARY KEY,
    shop_id VARCHAR(64) NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    bill_id VARCHAR(64),
    customer_id VARCHAR(64),
    amount_paise BIGINT NOT NULL,
    payment_method VARCHAR(20) NOT NULL DEFAULT 'CASH', -- CASH, UPI, CARD, CREDIT
    created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS returns (
    id VARCHAR(64) PRIMARY KEY,
    shop_id VARCHAR(64) NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    bill_id VARCHAR(64) NOT NULL,
    bill_item_id VARCHAR(64) NOT NULL,
    product_id VARCHAR(64) NOT NULL,
    quantity_returned NUMERIC(12, 3) NOT NULL,
    refund_amount_paise BIGINT NOT NULL,
    stock_restored BOOLEAN NOT NULL DEFAULT TRUE,
    reason VARCHAR(255),
    created_at BIGINT NOT NULL
);

-- Indexes for performance and multi-tenant scoping
CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile_number);
CREATE INDEX IF NOT EXISTS idx_shops_owner ON shops(owner_id);
CREATE INDEX IF NOT EXISTS idx_staff_permissions_shop ON staff_permissions(shop_id);
CREATE INDEX IF NOT EXISTS idx_staff_permissions_user ON staff_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_shop ON categories(shop_id);
CREATE INDEX IF NOT EXISTS idx_products_shop ON products(shop_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_shop ON stock_movements(shop_id);
CREATE INDEX IF NOT EXISTS idx_customers_shop ON customers(shop_id);
CREATE INDEX IF NOT EXISTS idx_bills_shop ON bills(shop_id);
CREATE INDEX IF NOT EXISTS idx_bill_items_bill ON bill_items(bill_id);
CREATE INDEX IF NOT EXISTS idx_payments_shop ON payments(shop_id);
CREATE INDEX IF NOT EXISTS idx_returns_shop ON returns(shop_id);
