import { query, memoryDb } from '../db/pool';
import { generateUuid, generateShopCode } from '../utils/codeGenerator';

export interface Shop {
  id: string;
  name: string;
  shop_code: string;
  owner_id: string;
  created_at: string;
  updated_at: string;
}

export class ShopRepository {
  static async createShop(name: string, ownerId: string): Promise<Shop> {
    const id = generateUuid();
    let shopCode = generateShopCode();
    const now = new Date().toISOString();

    // Ensure shopCode is unique
    let isUnique = false;
    let attempts = 0;
    while (!isUnique && attempts < 10) {
      const existing = await this.findByCode(shopCode);
      if (!existing) {
        isUnique = true;
      } else {
        shopCode = generateShopCode();
        attempts++;
      }
    }

    const shop: Shop = { id, name, shop_code: shopCode, owner_id: ownerId, created_at: now, updated_at: now };

    try {
      await query(
        'INSERT INTO shops (id, name, shop_code, owner_id, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6)',
        [id, name, shopCode, ownerId, now, now]
      );

      // Create owner membership
      const memberId = generateUuid();
      await query(
        'INSERT INTO shop_members (id, shop_id, user_id, role, status, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7)',
        [memberId, id, ownerId, 'OWNER', 'ACTIVE', now, now]
      );

      // Create full permissions for owner
      const permId = generateUuid();
      await query(
        `INSERT INTO permissions (
          id, shop_id, user_id, is_full_access,
          can_create_bills, can_view_bills, can_add_products, can_edit_products,
          can_delete_products, can_update_stock, can_view_customers, can_manage_customers,
          can_view_payments, can_manage_payments, can_process_returns, can_view_reports,
          can_view_profit, can_manage_members, can_manage_shop_settings,
          created_at, updated_at
        ) VALUES (
          $1, $2, $3, TRUE,
          TRUE, TRUE, TRUE, TRUE,
          TRUE, TRUE, TRUE, TRUE,
          TRUE, TRUE, TRUE, TRUE,
          TRUE, TRUE, TRUE,
          $4, $5
        )`,
        [permId, id, ownerId, now, now]
      );
    } catch (e) {
      // Memory fallback
    }

    memoryDb.tables.shops.push(shop);
    memoryDb.tables.shop_members.push({
      id: generateUuid(),
      shop_id: id,
      user_id: ownerId,
      role: 'OWNER',
      status: 'ACTIVE',
      created_at: now,
      updated_at: now
    });
    memoryDb.tables.permissions.push({
      id: generateUuid(),
      shop_id: id,
      user_id: ownerId,
      is_full_access: true,
      can_create_bills: true,
      can_view_bills: true,
      can_add_products: true,
      can_edit_products: true,
      can_delete_products: true,
      can_update_stock: true,
      can_view_customers: true,
      can_manage_customers: true,
      can_view_payments: true,
      can_manage_payments: true,
      can_process_returns: true,
      can_view_reports: true,
      can_view_profit: true,
      can_manage_members: true,
      can_manage_shop_settings: true,
      created_at: now,
      updated_at: now
    });

    return shop;
  }

  static async findByCode(shopCode: string): Promise<Shop | null> {
    try {
      const res = await query('SELECT * FROM shops WHERE shop_code = $1', [shopCode]);
      if (res.rows.length > 0) return res.rows[0];
    } catch (e) {}
    const s = memoryDb.tables.shops.find(shop => shop.shop_code === shopCode);
    if (s) return s;
    return null;
  }

  static async findById(id: string): Promise<Shop | null> {
    try {
      const res = await query('SELECT * FROM shops WHERE id = $1', [id]);
      if (res.rows.length > 0) return res.rows[0];
    } catch (e) {}
    const s = memoryDb.tables.shops.find(shop => shop.id === id);
    if (s) return s;
    return null;
  }

  static async findUserShops(userId: string): Promise<any[]> {
    try {
      const res = await query(
        `SELECT s.*, sm.role, sm.status as member_status
         FROM shops s
         JOIN shop_members sm ON s.id = sm.shop_id
         WHERE sm.user_id = $1 AND sm.status = 'ACTIVE'`,
        [userId]
      );
      if (res.rows.length > 0) return res.rows;
    } catch (e) {}
    const userMemberships = memoryDb.tables.shop_members.filter(
      sm => sm.user_id === userId && sm.status === 'ACTIVE'
    );
    return userMemberships.map(sm => {
      const s = memoryDb.tables.shops.find(shop => shop.id === sm.shop_id);
      return s ? { ...s, role: sm.role, member_status: sm.status } : null;
    }).filter(Boolean);
  }
}
