import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const connectionString = process.env.DATABASE_URL || 'postgres://postgres:postgres@localhost:5432/shopzo_cloud';

// Create PostgreSQL connection pool
export const pool = new Pool({
  connectionString,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// Helper query function
export const query = async (text: string, params?: any[]) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    return res;
  } catch (error) {
    throw error;
  }
};

// Memory fallback store for standalone testing when PG is offline/unreachable
class MemoryDB {
  public tables: Record<string, any[]> = {
    users: [],
    shops: [],
    shop_members: [],
    permissions: [],
    membership_requests: [],
    shop_invitations: [],
    categories: [],
    products: [],
    stock_movements: [],
    customers: [],
    bills: [],
    bill_items: [],
    payments: [],
    returns: [],
    sync_audit: []
  };

  public isMemoryMode = false;
}

export const memoryDb = new MemoryDB();
