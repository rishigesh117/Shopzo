import { query, memoryDb } from '../db/pool';
import { generateUuid } from '../utils/codeGenerator';

export interface MembershipRequest {
  id: string;
  shop_id: string;
  user_id: string;
  status: 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'CANCELLED';
  created_at: string;
  updated_at: string;
  user_name?: string;
  user_phone?: string;
  shop_name?: string;
  shop_code?: string;
}

export class RequestRepository {
  static async createRequest(shopId: string, userId: string): Promise<MembershipRequest> {
    const existing = await this.findPendingRequest(shopId, userId);
    if (existing) {
      return existing;
    }

    const id = generateUuid();
    const now = new Date().toISOString();
    const req: MembershipRequest = {
      id,
      shop_id: shopId,
      user_id: userId,
      status: 'PENDING',
      created_at: now,
      updated_at: now
    };

    try {
      await query(
        `INSERT INTO membership_requests (id, shop_id, user_id, status, created_at, updated_at)
         VALUES ($1, $2, $3, 'PENDING', $4, $5)`,
        [id, shopId, userId, now, now]
      );
    } catch (e) {
      // Memory fallback
    }

    memoryDb.tables.membership_requests.push(req);
    return req;
  }

  static async findPendingRequest(shopId: string, userId: string): Promise<MembershipRequest | null> {
    try {
      const res = await query(
        `SELECT * FROM membership_requests WHERE shop_id = $1 AND user_id = $2 AND status = 'PENDING'`,
        [shopId, userId]
      );
      if (res.rows.length > 0) return res.rows[0];
    } catch (e) {}
    const r = memoryDb.tables.membership_requests.find(
      mr => mr.shop_id === shopId && mr.user_id === userId && mr.status === 'PENDING'
    );
    if (r) return r;
    return null;
  }

  static async findById(id: string): Promise<MembershipRequest | null> {
    try {
      const res = await query('SELECT * FROM membership_requests WHERE id = $1', [id]);
      if (res.rows.length > 0) return res.rows[0];
    } catch (e) {}
    const r = memoryDb.tables.membership_requests.find(mr => mr.id === id);
    if (r) return r;
    return null;
  }

  static async listShopRequests(shopId: string): Promise<any[]> {
    try {
      const res = await query(
        `SELECT mr.*, u.name as user_name, u.phone as user_phone
         FROM membership_requests mr
         JOIN users u ON mr.user_id = u.id
         WHERE mr.shop_id = $1
         ORDER BY mr.created_at DESC`,
        [shopId]
      );
      if (res.rows.length > 0) return res.rows;
    } catch (e) {}
    const list = memoryDb.tables.membership_requests.filter(mr => mr.shop_id === shopId);
    return list.map(mr => {
      const u = memoryDb.tables.users.find(usr => usr.id === mr.user_id);
      return { ...mr, user_name: u?.name, user_phone: u?.phone };
    });
  }

  static async listUserRequests(userId: string): Promise<any[]> {
    try {
      const res = await query(
        `SELECT mr.*, s.name as shop_name, s.shop_code
         FROM membership_requests mr
         JOIN shops s ON mr.shop_id = s.id
         WHERE mr.user_id = $1
         ORDER BY mr.created_at DESC`,
        [userId]
      );
      if (res.rows.length > 0) return res.rows;
    } catch (e) {}
    const list = memoryDb.tables.membership_requests.filter(mr => mr.user_id === userId);
    return list.map(mr => {
      const s = memoryDb.tables.shops.find(shp => shp.id === mr.shop_id);
      return { ...mr, shop_name: s?.name, shop_code: s?.shop_code };
    });
  }

  static async updateStatus(id: string, status: 'ACCEPTED' | 'REJECTED' | 'CANCELLED'): Promise<MembershipRequest | null> {
    const now = new Date().toISOString();
    try {
      await query(
        'UPDATE membership_requests SET status = $1, updated_at = $2 WHERE id = $3',
        [status, now, id]
      );
    } catch (e) {
      const idx = memoryDb.tables.membership_requests.findIndex(mr => mr.id === id);
      if (idx >= 0) {
        memoryDb.tables.membership_requests[idx].status = status;
        memoryDb.tables.membership_requests[idx].updated_at = now;
      }
    }
    return this.findById(id);
  }
}
