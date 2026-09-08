import { query, memoryDb } from '../db/pool';
import { generateUuid } from '../utils/codeGenerator';

export interface ShopInvitation {
  id: string;
  shop_id: string;
  phone: string;
  invited_by_user_id: string;
  permissions_json?: string;
  status: 'PENDING' | 'ACCEPTED' | 'DECLINED' | 'CANCELLED';
  created_at: string;
  updated_at: string;
  shop_name?: string;
  shop_code?: string;
  invited_by_name?: string;
}

export class InvitationRepository {
  static async createInvitation(
    shopId: string,
    phone: string,
    invitedByUserId: string,
    permissionsJson?: string
  ): Promise<ShopInvitation> {
    const existing = await this.findPendingInvitation(shopId, phone);
    if (existing) {
      return existing;
    }

    const id = generateUuid();
    const now = new Date().toISOString();
    const inv: ShopInvitation = {
      id,
      shop_id: shopId,
      phone,
      invited_by_user_id: invitedByUserId,
      permissions_json: permissionsJson,
      status: 'PENDING',
      created_at: now,
      updated_at: now
    };

    try {
      await query(
        `INSERT INTO shop_invitations (id, shop_id, phone, invited_by_user_id, permissions_json, status, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, 'PENDING', $6, $7)`,
        [id, shopId, phone, invitedByUserId, permissionsJson || null, now, now]
      );
    } catch (e) {
      // Memory fallback
    }

    memoryDb.tables.shop_invitations.push(inv);
    return inv;
  }

  static async findPendingInvitation(shopId: string, phone: string): Promise<ShopInvitation | null> {
    try {
      const res = await query(
        `SELECT * FROM shop_invitations WHERE shop_id = $1 AND phone = $2 AND status = 'PENDING'`,
        [shopId, phone]
      );
      if (res.rows.length > 0) return res.rows[0];
    } catch (e) {}
    const inv = memoryDb.tables.shop_invitations.find(
      i => i.shop_id === shopId && i.phone === phone && i.status === 'PENDING'
    );
    if (inv) return inv;
    return null;
  }

  static async findById(id: string): Promise<ShopInvitation | null> {
    try {
      const res = await query('SELECT * FROM shop_invitations WHERE id = $1', [id]);
      if (res.rows.length > 0) return res.rows[0];
    } catch (e) {}
    const inv = memoryDb.tables.shop_invitations.find(i => i.id === id);
    if (inv) return inv;
    return null;
  }

  static async listUserInvitations(phone: string): Promise<any[]> {
    try {
      const res = await query(
        `SELECT si.*, s.name as shop_name, s.shop_code, u.name as invited_by_name
         FROM shop_invitations si
         JOIN shops s ON si.shop_id = s.id
         JOIN users u ON si.invited_by_user_id = u.id
         WHERE si.phone = $1 AND si.status = 'PENDING'
         ORDER BY si.created_at DESC`,
        [phone]
      );
      if (res.rows.length > 0) return res.rows;
    } catch (e) {}
    const list = memoryDb.tables.shop_invitations.filter(i => i.phone === phone && i.status === 'PENDING');
    return list.map(inv => {
      const s = memoryDb.tables.shops.find(shp => shp.id === inv.shop_id);
      const u = memoryDb.tables.users.find(usr => usr.id === inv.invited_by_user_id);
      return { ...inv, shop_name: s?.name, shop_code: s?.shop_code, invited_by_name: u?.name };
    });
  }

  static async listShopInvitations(shopId: string): Promise<any[]> {
    try {
      const res = await query(
        `SELECT si.*, u.name as invited_by_name
         FROM shop_invitations si
         JOIN users u ON si.invited_by_user_id = u.id
         WHERE si.shop_id = $1
         ORDER BY si.created_at DESC`,
        [shopId]
      );
      if (res.rows.length > 0) return res.rows;
    } catch (e) {}
    const list = memoryDb.tables.shop_invitations.filter(i => i.shop_id === shopId);
    return list.map(inv => {
      const u = memoryDb.tables.users.find(usr => usr.id === inv.invited_by_user_id);
      return { ...inv, invited_by_name: u?.name };
    });
  }

  static async updateStatus(id: string, status: 'ACCEPTED' | 'DECLINED' | 'CANCELLED'): Promise<ShopInvitation | null> {
    const now = new Date().toISOString();
    try {
      await query(
        'UPDATE shop_invitations SET status = $1, updated_at = $2 WHERE id = $3',
        [status, now, id]
      );
    } catch (e) {
      const idx = memoryDb.tables.shop_invitations.findIndex(i => i.id === id);
      if (idx >= 0) {
        memoryDb.tables.shop_invitations[idx].status = status;
        memoryDb.tables.shop_invitations[idx].updated_at = now;
      }
    }
    return this.findById(id);
  }
}
