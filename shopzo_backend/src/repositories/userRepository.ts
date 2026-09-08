import { query, memoryDb } from '../db/pool';
import { generateUuid } from '../utils/codeGenerator';

export interface User {
  id: string;
  phone: string;
  name: string;
  role: string;
  created_at: string;
  updated_at: string;
}

export class UserRepository {
  static async findByPhone(phone: string): Promise<User | null> {
    try {
      const res = await query('SELECT * FROM users WHERE phone = $1', [phone]);
      if (res.rows.length > 0) return res.rows[0];
    } catch (e) {
      const u = memoryDb.tables.users.find(user => user.phone === phone);
      if (u) return u;
    }
    return null;
  }

  static async findById(id: string): Promise<User | null> {
    try {
      const res = await query('SELECT * FROM users WHERE id = $1', [id]);
      if (res.rows.length > 0) return res.rows[0];
    } catch (e) {
      const u = memoryDb.tables.users.find(user => user.id === id);
      if (u) return u;
    }
    return null;
  }

  static async create(phone: string, name: string, role = 'OWNER'): Promise<User> {
    const id = generateUuid();
    const now = new Date().toISOString();
    const user: User = { id, phone, name, role, created_at: now, updated_at: now };

    try {
      await query(
        'INSERT INTO users (id, phone, name, role, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6)',
        [id, phone, name, role, now, now]
      );
    } catch (e) {
      // Memory fallback
    }

    memoryDb.tables.users.push(user);
    return user;
  }
}
