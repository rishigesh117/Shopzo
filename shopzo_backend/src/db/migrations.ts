import { pool } from './pool';

export const runMigrations = async (): Promise<void> => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Users table
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY,
        phone VARCHAR(20) UNIQUE NOT NULL,
        name VARCHAR(100) NOT NULL,
        role VARCHAR(20) NOT NULL DEFAULT 'OWNER',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 2. Shops table
    await client.query(`
      CREATE TABLE IF NOT EXISTS shops (
        id UUID PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        shop_code VARCHAR(20) UNIQUE NOT NULL,
        owner_id UUID REFERENCES users(id),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 3. Shop Members table
    await client.query(`
      CREATE TABLE IF NOT EXISTS shop_members (
        id UUID PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        role VARCHAR(20) NOT NULL,
        status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE(shop_id, user_id)
      );
    `);

    // 4. Permissions table
    await client.query(`
      CREATE TABLE IF NOT EXISTS permissions (
        id UUID PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        is_full_access BOOLEAN NOT NULL DEFAULT FALSE,
        can_create_bills BOOLEAN DEFAULT FALSE,
        can_view_bills BOOLEAN DEFAULT FALSE,
        can_add_products BOOLEAN DEFAULT FALSE,
        can_edit_products BOOLEAN DEFAULT FALSE,
        can_delete_products BOOLEAN DEFAULT FALSE,
        can_update_stock BOOLEAN DEFAULT FALSE,
        can_view_customers BOOLEAN DEFAULT FALSE,
        can_manage_customers BOOLEAN DEFAULT FALSE,
        can_view_payments BOOLEAN DEFAULT FALSE,
        can_manage_payments BOOLEAN DEFAULT FALSE,
        can_process_returns BOOLEAN DEFAULT FALSE,
        can_view_reports BOOLEAN DEFAULT FALSE,
        can_view_profit BOOLEAN DEFAULT FALSE,
        can_manage_members BOOLEAN DEFAULT FALSE,
        can_manage_shop_settings BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE(shop_id, user_id)
      );
    `);

    // 5. Membership Requests table (Employee -> Owner)
    await client.query(`
      CREATE TABLE IF NOT EXISTS membership_requests (
        id UUID PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 6. Shop Invitations table (Owner -> Employee)
    await client.query(`
      CREATE TABLE IF NOT EXISTS shop_invitations (
        id UUID PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        phone VARCHAR(20) NOT NULL,
        invited_by_user_id UUID REFERENCES users(id),
        permissions_json TEXT,
        status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 7. Categories table
    await client.query(`
      CREATE TABLE IF NOT EXISTS categories (
        id VARCHAR(100) PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        name VARCHAR(100) NOT NULL,
        is_default BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 8. Products table
    await client.query(`
      CREATE TABLE IF NOT EXISTS products (
        id VARCHAR(100) PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        name VARCHAR(150) NOT NULL,
        category_id VARCHAR(100) NOT NULL,
        category_name VARCHAR(100) NOT NULL,
        brand VARCHAR(100),
        buying_price_paise BIGINT NOT NULL,
        selling_price_paise BIGINT NOT NULL,
        quantity NUMERIC NOT NULL,
        unit VARCHAR(50) NOT NULL,
        min_stock_level NUMERIC NOT NULL,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 9. Stock Movements table
    await client.query(`
      CREATE TABLE IF NOT EXISTS stock_movements (
        id VARCHAR(100) PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        product_id VARCHAR(100) NOT NULL,
        product_name VARCHAR(150) NOT NULL,
        previous_quantity NUMERIC NOT NULL,
        quantity_change NUMERIC NOT NULL,
        new_quantity NUMERIC NOT NULL,
        purchase_price_paise BIGINT NOT NULL DEFAULT 0,
        movement_type VARCHAR(50) NOT NULL,
        reason TEXT,
        supplier VARCHAR(100),
        notes TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 10. Customers table
    await client.query(`
      CREATE TABLE IF NOT EXISTS customers (
        id VARCHAR(100) PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        name VARCHAR(100) NOT NULL,
        phone VARCHAR(20) NOT NULL,
        address TEXT,
        is_deleted BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 11. Bills table
    await client.query(`
      CREATE TABLE IF NOT EXISTS bills (
        id VARCHAR(100) PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        bill_number VARCHAR(100) NOT NULL,
        customer_id VARCHAR(100),
        customer_name_snapshot VARCHAR(100),
        customer_phone_snapshot VARCHAR(20),
        subtotal_paise BIGINT NOT NULL,
        total_amount_paise BIGINT NOT NULL,
        amount_received_paise BIGINT NOT NULL,
        change_amount_paise BIGINT NOT NULL,
        pending_amount_paise BIGINT NOT NULL,
        payment_status VARCHAR(50) NOT NULL,
        is_cancelled BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE(shop_id, bill_number)
      );
    `);

    // 12. Bill Items table
    await client.query(`
      CREATE TABLE IF NOT EXISTS bill_items (
        id VARCHAR(100) PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        bill_id VARCHAR(100) REFERENCES bills(id) ON DELETE CASCADE,
        product_id VARCHAR(100) NOT NULL,
        product_name_snapshot VARCHAR(150) NOT NULL,
        quantity NUMERIC NOT NULL,
        unit VARCHAR(50) NOT NULL,
        selling_price_paise BIGINT NOT NULL,
        buying_price_paise BIGINT NOT NULL,
        line_total_paise BIGINT NOT NULL,
        profit_paise BIGINT NOT NULL
      );
    `);

    // 13. Payments table
    await client.query(`
      CREATE TABLE IF NOT EXISTS payments (
        id VARCHAR(100) PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        customer_id VARCHAR(100),
        bill_id VARCHAR(100),
        amount_paise BIGINT NOT NULL,
        payment_method VARCHAR(50) NOT NULL,
        notes TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 14. Returns table
    await client.query(`
      CREATE TABLE IF NOT EXISTS returns (
        id VARCHAR(100) PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        bill_id VARCHAR(100) NOT NULL,
        customer_id VARCHAR(100),
        product_id VARCHAR(100) NOT NULL,
        product_name_snapshot VARCHAR(150) NOT NULL,
        quantity NUMERIC NOT NULL,
        unit VARCHAR(50) NOT NULL,
        refund_amount_paise BIGINT NOT NULL,
        reason TEXT NOT NULL,
        status VARCHAR(50) NOT NULL,
        stock_action VARCHAR(50) NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // 15. Sync Audit table
    await client.query(`
      CREATE TABLE IF NOT EXISTS sync_audit (
        id UUID PRIMARY KEY,
        shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(id),
        table_name VARCHAR(100) NOT NULL,
        record_id VARCHAR(100) NOT NULL,
        action VARCHAR(20) NOT NULL,
        processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // Indexes
    await client.query(`CREATE INDEX IF NOT EXISTS idx_products_shop ON products(shop_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_bills_shop ON bills(shop_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_customers_shop ON customers(shop_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_payments_shop ON payments(shop_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_returns_shop ON returns(shop_id);`);

    await client.query('COMMIT');
    console.log('[PostgreSQL Migration] All migrations executed successfully.');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[PostgreSQL Migration Error]', error);
    throw error;
  } finally {
    client.release();
  }
};
