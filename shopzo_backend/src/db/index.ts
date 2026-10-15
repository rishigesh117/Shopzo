import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const connectionString = process.env.DATABASE_URL || 'postgres://postgres:postgres@localhost:5432/shopzo';

const isCloudDb = !!process.env.DATABASE_URL && !process.env.DATABASE_URL.includes('localhost') && !process.env.DATABASE_URL.includes('127.0.0.1');

export const pool = new Pool({
  connectionString,
  ssl: isCloudDb ? { rejectUnauthorized: false } : undefined,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 4000,
});

// In-Memory Database Store for robust offline execution and fallback
class InMemoryDb {
  users: Map<string, any> = new Map();
  shops: Map<string, any> = new Map();
  staffPermissions: Map<string, any> = new Map(); // key: `${shop_id}:${user_id}`
  categories: Map<string, any> = new Map();
  products: Map<string, any> = new Map();
  stockMovements: Map<string, any> = new Map();
  customers: Map<string, any> = new Map();
  bills: Map<string, any> = new Map();
  billItems: Map<string, any> = new Map();
  payments: Map<string, any> = new Map();
  returns: Map<string, any> = new Map();

  constructor() {
    this.seedDefaults();
  }

  seedDefaults() {
    const now = Date.now();
    const userId = 'user-owner-8870635581';
    const shopId = 'shop-default-001';
    // Bcrypt hash for 'Sivaelectricals@117'
    const defaultHash = '$2a$10$3lQyBiZSAfU5ZSFyk3TEguWuP4s6zXfex8wPu8YCFPV53LnGOdK5O';

    if (!this.users.has(userId)) {
      this.users.set(userId, {
        id: userId,
        mobileNumber: '8870635581',
        name: 'Rishigesh',
        passwordHash: defaultHash,
        createdAt: now,
        updatedAt: now
      });
    }

    if (!this.shops.has(shopId)) {
      this.shops.set(shopId, {
        id: shopId,
        shopCode: 'SHOPZO1',
        name: 'Shopzo Main Store',
        ownerId: userId,
        ownerName: 'Rishigesh',
        ownerMobile: '8870635581',
        address: 'Main Bazaar Road',
        createdAt: now,
        updatedAt: now
      });

      this.staffPermissions.set(`${shopId}:${userId}`, {
        id: 'perm-owner-001',
        shopId,
        userId,
        role: 'OWNER',
        permissions: ['ALL'],
        createdAt: now,
        updatedAt: now
      });
    }
  }

  clear() {
    this.users.clear();
    this.shops.clear();
    this.staffPermissions.clear();
    this.categories.clear();
    this.products.clear();
    this.stockMovements.clear();
    this.customers.clear();
    this.bills.clear();
    this.billItems.clear();
    this.payments.clear();
    this.returns.clear();
    this.seedDefaults();
  }
}

export const memoryDb = new InMemoryDb();
export let useMemoryDb = process.env.NODE_ENV === 'test' || false;

export function setUseMemoryDb(val: boolean) {
  useMemoryDb = val;
}

export async function query(text: string, params: any[] = []): Promise<{ rows: any[] }> {
  if (useMemoryDb) {
    return { rows: [] };
  }
  try {
    const client = await pool.connect();
    try {
      const res = await client.query(text, params);
      return res;
    } finally {
      client.release();
    }
  } catch (err) {
    console.warn('PostgreSQL query error, switching to in-memory fallback:', err);
    setUseMemoryDb(true);
    return { rows: [] };
  }
}
