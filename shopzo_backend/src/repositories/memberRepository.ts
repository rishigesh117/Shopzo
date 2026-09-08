import { query, memoryDb } from '../db/pool';
import { generateUuid } from '../utils/codeGenerator';

export interface ShopMember {
  id: string;
  shop_id: string;
  user_id: string;
  role: string;
  status: string;
  created_at: string;
  updated_at: string;
  user_name?: string;
  user_phone?: string;
}

export interface PermissionSet {
  id: string;
  shop_id: string;
  user_id: string;
  is_full_access: boolean;
  can_create_bills: boolean;
  can_view_bills: boolean;
  can_add_products: boolean;
  can_edit_products: boolean;
  can_delete_products: boolean;
  can_update_stock: boolean;
  can_view_customers: boolean;
  can_manage_customers: boolean;
  can_view_payments: boolean;
  can_manage_payments: boolean;
  can_process_returns: boolean;
  can_view_reports: boolean;
  can_view_profit: boolean;
  can_manage_members: boolean;
  can_manage_shop_settings: boolean;
  created_at: string;
  updated_at: string;
}

export class MemberRepository {
  static async addMember(shopId: string, userId: string, role = 'EMPLOYEE'): Promise<ShopMember> {
    const id = generateUuid();
    const now = new Date().toISOString();
    const member: ShopMember = {
      id,
      shop_id: shopId,
      user_id: userId,
      role,
      status: 'ACTIVE',
      created_at: now,
      updated_at: now
    };

    try {
      await query(
        `INSERT INTO shop_members (id, shop_id, user_id, role, status, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (shop_id, user_id) DO UPDATE SET status = 'ACTIVE', role = $4, updated_at = $7`,
        [id, shopId, userId, role, 'ACTIVE', now, now]
      );
    } catch (e) {
      // Fallback
    }

    const idx = memoryDb.tables.shop_members.findIndex(m => m.shop_id === shopId && m.user_id === userId);
    if (idx >= 0) {
      memoryDb.tables.shop_members[idx] = member;
    } else {
      memoryDb.tables.shop_members.push(member);
    }

    return member;
  }

  static async findMember(shopId: string, userId: string): Promise<ShopMember | null> {
    try {
      const res = await query(
        `SELECT sm.*, u.name as user_name, u.phone as user_phone
         FROM shop_members sm
         JOIN users u ON sm.user_id = u.id
         WHERE sm.shop_id = $1 AND sm.user_id = $2`,
        [shopId, userId]
      );
      if (res.rows.length > 0) return res.rows[0];
    } catch (e) {}
    const m = memoryDb.tables.shop_members.find(sm => sm.shop_id === shopId && sm.user_id === userId);
    if (m) {
      const u = memoryDb.tables.users.find(usr => usr.id === userId);
      return { ...m, user_name: u?.name, user_phone: u?.phone };
    }
    return null;
  }

  static async listShopMembers(shopId: string): Promise<any[]> {
    try {
      const res = await query(
        `SELECT sm.id, sm.shop_id, sm.user_id, sm.role, sm.status, sm.created_at, sm.updated_at,
                u.name as user_name, u.phone as user_phone,
                p.is_full_access, p.can_create_bills, p.can_view_bills, p.can_add_products, p.can_edit_products,
                p.can_delete_products, p.can_update_stock, p.can_view_customers, p.can_manage_customers,
                p.can_view_payments, p.can_manage_payments, p.can_process_returns, p.can_view_reports,
                p.can_view_profit, p.can_manage_members, p.can_manage_shop_settings
         FROM shop_members sm
         JOIN users u ON sm.user_id = u.id
         LEFT JOIN permissions p ON sm.shop_id = p.shop_id AND sm.user_id = p.user_id
         WHERE sm.shop_id = $1 AND sm.status = 'ACTIVE'`,
        [shopId]
      );
      if (res.rows.length > 0) return res.rows;
    } catch (e) {}
    const members = memoryDb.tables.shop_members.filter(sm => sm.shop_id === shopId && sm.status === 'ACTIVE');
    return members.map(sm => {
      const u = memoryDb.tables.users.find(usr => usr.id === sm.user_id);
      const p = memoryDb.tables.permissions.find(perm => perm.shop_id === shopId && perm.user_id === sm.user_id);
      return {
        ...sm,
        user_name: u?.name,
        user_phone: u?.phone,
        is_full_access: p?.is_full_access ?? (sm.role === 'OWNER'),
        can_create_bills: p?.can_create_bills ?? true,
        can_view_bills: p?.can_view_bills ?? true,
        can_add_products: p?.can_add_products ?? true,
        can_edit_products: p?.can_edit_products ?? true,
        can_delete_products: p?.can_delete_products ?? true,
        can_update_stock: p?.can_update_stock ?? true,
        can_view_customers: p?.can_view_customers ?? true,
        can_manage_customers: p?.can_manage_customers ?? true,
        can_view_payments: p?.can_view_payments ?? true,
        can_manage_payments: p?.can_manage_payments ?? true,
        can_process_returns: p?.can_process_returns ?? true,
        can_view_reports: p?.can_view_reports ?? true,
        can_view_profit: p?.can_view_profit ?? true,
        can_manage_members: p?.can_manage_members ?? true,
        can_manage_shop_settings: p?.can_manage_shop_settings ?? true
      };
    });
  }

  static async removeMember(shopId: string, userId: string): Promise<boolean> {
    // Check owner protection
    const member = await this.findMember(shopId, userId);
    if (member?.role === 'OWNER') {
      throw new Error('Owner cannot be removed from the shop');
    }

    const now = new Date().toISOString();
    try {
      await query(
        'UPDATE shop_members SET status = \'INACTIVE\', updated_at = $1 WHERE shop_id = $2 AND user_id = $3',
        [now, shopId, userId]
      );
    } catch (e) {
      const idx = memoryDb.tables.shop_members.findIndex(m => m.shop_id === shopId && m.user_id === userId);
      if (idx >= 0) memoryDb.tables.shop_members[idx].status = 'INACTIVE';
    }
    return true;
  }

  static async getPermissions(shopId: string, userId: string): Promise<PermissionSet | null> {
    try {
      const res = await query('SELECT * FROM permissions WHERE shop_id = $1 AND user_id = $2', [shopId, userId]);
      if (res.rows.length > 0) return res.rows[0];
    } catch (e) {}
    const p = memoryDb.tables.permissions.find(perm => perm.shop_id === shopId && perm.user_id === userId);
    if (p) return p;
    return null;
  }

  static async setPermissions(shopId: string, userId: string, permData: Partial<PermissionSet>): Promise<PermissionSet> {
    // Check if target is owner -> Owner always has full access
    const targetMember = await this.findMember(shopId, userId);
    if (targetMember?.role === 'OWNER') {
      permData.is_full_access = true;
    }

    const id = generateUuid();
    const now = new Date().toISOString();

    const isFullAccess = permData.is_full_access === true;
    const canCreateBills = isFullAccess || permData.can_create_bills === true;
    const canViewBills = isFullAccess || permData.can_view_bills === true;
    const canAddProducts = isFullAccess || permData.can_add_products === true;
    const canEditProducts = isFullAccess || permData.can_edit_products === true;
    const canDeleteProducts = isFullAccess || permData.can_delete_products === true;
    const canUpdateStock = isFullAccess || permData.can_update_stock === true;
    const canViewCustomers = isFullAccess || permData.can_view_customers === true;
    const canManageCustomers = isFullAccess || permData.can_manage_customers === true;
    const canViewPayments = isFullAccess || permData.can_view_payments === true;
    const canManagePayments = isFullAccess || permData.can_manage_payments === true;
    const canProcessReturns = isFullAccess || permData.can_process_returns === true;
    const canViewReports = isFullAccess || permData.can_view_reports === true;
    const canViewProfit = isFullAccess || permData.can_view_profit === true;
    const canManageMembers = isFullAccess || permData.can_manage_members === true;
    const canManageShopSettings = isFullAccess || permData.can_manage_shop_settings === true;

    const fullPerm: PermissionSet = {
      id,
      shop_id: shopId,
      user_id: userId,
      is_full_access: isFullAccess,
      can_create_bills: canCreateBills,
      can_view_bills: canViewBills,
      can_add_products: canAddProducts,
      can_edit_products: canEditProducts,
      can_delete_products: canDeleteProducts,
      can_update_stock: canUpdateStock,
      can_view_customers: canViewCustomers,
      can_manage_customers: canManageCustomers,
      can_view_payments: canViewPayments,
      can_manage_payments: canManagePayments,
      can_process_returns: canProcessReturns,
      can_view_reports: canViewReports,
      can_view_profit: canViewProfit,
      can_manage_members: canManageMembers,
      can_manage_shop_settings: canManageShopSettings,
      created_at: now,
      updated_at: now
    };

    try {
      await query(
        `INSERT INTO permissions (
          id, shop_id, user_id, is_full_access,
          can_create_bills, can_view_bills, can_add_products, can_edit_products,
          can_delete_products, can_update_stock, can_view_customers, can_manage_customers,
          can_view_payments, can_manage_payments, can_process_returns, can_view_reports,
          can_view_profit, can_manage_members, can_manage_shop_settings,
          created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4,
          $5, $6, $7, $8,
          $9, $10, $11, $12,
          $13, $14, $15, $16,
          $17, $18, $19,
          $20, $21
        ) ON CONFLICT (shop_id, user_id) DO UPDATE SET
          is_full_access = $4,
          can_create_bills = $5, can_view_bills = $6, can_add_products = $7, can_edit_products = $8,
          can_delete_products = $9, can_update_stock = $10, can_view_customers = $11, can_manage_customers = $12,
          can_view_payments = $13, can_manage_payments = $14, can_process_returns = $15, can_view_reports = $16,
          can_view_profit = $17, can_manage_members = $18, can_manage_shop_settings = $19,
          updated_at = $21`,
        [
          id, shopId, userId, isFullAccess,
          canCreateBills, canViewBills, canAddProducts, canEditProducts,
          canDeleteProducts, canUpdateStock, canViewCustomers, canManageCustomers,
          canViewPayments, canManagePayments, canProcessReturns, canViewReports,
          canViewProfit, canManageMembers, canManageShopSettings,
          now, now
        ]
      );
    } catch (e) {
      // Memory fallback
    }

    const idx = memoryDb.tables.permissions.findIndex(p => p.shop_id === shopId && p.user_id === userId);
    if (idx >= 0) {
      memoryDb.tables.permissions[idx] = fullPerm;
    } else {
      memoryDb.tables.permissions.push(fullPerm);
    }

    return fullPerm;
  }
}
