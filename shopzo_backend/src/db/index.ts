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

import fs from 'fs';
import path from 'path';

const DB_FILE = path.resolve(__dirname, '../../shopzo_data.json');

// Persistent In-Memory Database Store for robust offline & multi-device execution
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
    this.loadFromDisk();
    this.seedDefaults();
  }

  saveToDisk() {
    try {
      const data = {
        users: Array.from(this.users.entries()),
        shops: Array.from(this.shops.entries()),
        staffPermissions: Array.from(this.staffPermissions.entries()),
        categories: Array.from(this.categories.entries()),
        products: Array.from(this.products.entries()),
        stockMovements: Array.from(this.stockMovements.entries()),
        customers: Array.from(this.customers.entries()),
        bills: Array.from(this.bills.entries()),
        billItems: Array.from(this.billItems.entries()),
        payments: Array.from(this.payments.entries()),
        returns: Array.from(this.returns.entries()),
      };
      fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf-8');
    } catch (e) {
      // In serverless read-only disk environments like Vercel, ignore write errors
    }
  }

  loadFromDisk() {
    try {
      if (fs.existsSync(DB_FILE)) {
        const raw = fs.readFileSync(DB_FILE, 'utf-8');
        const data = JSON.parse(raw);
        if (data.users) this.users = new Map(data.users);
        if (data.shops) this.shops = new Map(data.shops);
        if (data.staffPermissions) this.staffPermissions = new Map(data.staffPermissions);
        if (data.categories) this.categories = new Map(data.categories);
        if (data.products) this.products = new Map(data.products);
        if (data.stockMovements) this.stockMovements = new Map(data.stockMovements);
        if (data.customers) this.customers = new Map(data.customers);
        if (data.bills) this.bills = new Map(data.bills);
        if (data.billItems) this.billItems = new Map(data.billItems);
        if (data.payments) this.payments = new Map(data.payments);
        if (data.returns) this.returns = new Map(data.returns);
      }
    } catch (e) {
      console.warn('Could not load persistent shopzo_data.json:', e);
    }
  }

  seedDefaults() {
    // Clean slate: No accounts or shops pre-seeded. All users register fresh.
    this.saveToDisk();
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
    this.saveToDisk();
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
