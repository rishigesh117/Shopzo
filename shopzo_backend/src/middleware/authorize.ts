import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth';
import { query, memoryDb } from '../db/pool';

export interface PermissionRequirements {
  permission?: string;
  requireOwner?: boolean;
}

export const authorizeShopAccess = (options: PermissionRequirements = {}) => {
  return async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'User context missing' });
    }

    const shopId = (req.headers['x-shop-id'] || req.params.shopId || req.body.shopId || req.query.shopId) as string;
    if (!shopId) {
      return res.status(400).json({ success: false, error: 'Shop ID required in header x-shop-id or request' });
    }

    try {
      // Fetch shop membership
      let memberRecord: any = null;
      let permRecord: any = null;

      try {
        const memberRes = await query(
          'SELECT * FROM shop_members WHERE shop_id = $1 AND user_id = $2 AND status = \'ACTIVE\'',
          [shopId, userId]
        );
        if (memberRes.rows.length > 0) {
          memberRecord = memberRes.rows[0];
          const permRes = await query(
            'SELECT * FROM permissions WHERE shop_id = $1 AND user_id = $2',
            [shopId, userId]
          );
          if (permRes.rows.length > 0) {
            permRecord = permRes.rows[0];
          }
        }
      } catch (err) {
        // Fallback to memory store if PostgreSQL connection isn't available
      }

      if (!memberRecord) {
        memberRecord = memoryDb.tables.shop_members.find(
          m => m.shop_id === shopId && m.user_id === userId && m.status === 'ACTIVE'
        );
        if (memberRecord) {
          permRecord = memoryDb.tables.permissions.find(
            p => p.shop_id === shopId && p.user_id === userId
          );
        }
      }

      if (!memberRecord) {
        return res.status(403).json({ success: false, error: 'Access denied: Not an active member of this shop' });
      }

      const isOwner = memberRecord.role === 'OWNER';

      if (options.requireOwner && !isOwner) {
        return res.status(403).json({ success: false, error: 'Access denied: Owner privilege required' });
      }

      // If user is owner, they have full access
      if (!isOwner && options.permission) {
        const isFullAccess = permRecord?.is_full_access === true;
        const hasPermission = isFullAccess || permRecord?.[options.permission] === true;

        if (!hasPermission) {
          return res.status(403).json({
            success: false,
            error: `Access denied: Missing required permission '${options.permission}'`
          });
        }
      }

      req.shopMember = {
        shopId,
        role: memberRecord.role,
        permissions: permRecord || {}
      };

      next();
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message || 'Authorization check failed' });
    }
  };
};
