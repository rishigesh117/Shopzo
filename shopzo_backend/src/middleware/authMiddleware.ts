import { Request, Response, NextFunction } from 'express';
import { verifyToken, TokenPayload } from '../utils/auth';
import { memoryDb, pool, useMemoryDb } from '../db';

export interface AuthenticatedRequest extends Request {
  user?: TokenPayload;
  shopRole?: 'OWNER' | 'STAFF';
  permissions?: string[];
  shopId?: string;
}

/**
 * Middleware 1: Authenticate User via JWT
 */
export function authenticateUser(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized: Missing or invalid token' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = verifyToken(token);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Unauthorized: Invalid or expired token' });
  }
}

/**
 * Middleware 2: Authorize Shop Access
 * Ensures user belongs to requested shopId (either as OWNER or STAFF)
 */
export async function authorizeShopAccess(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  if (!req.user) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const shopId = (req.params.shopId || req.headers['x-shop-id'] || req.body.shopId) as string;
  if (!shopId) {
    return res.status(400).json({ error: 'Bad Request: Missing shopId' });
  }

  req.shopId = shopId;

  let shop = memoryDb.shops.get(shopId);

  // If not found by direct ID, resolve by shopCode or user ownership
  if (!shop) {
    for (const s of memoryDb.shops.values()) {
      if (s.id === shopId || s.shopCode === shopId || s.ownerId === req.user.userId) {
        shop = s;
        // Register alias for future fast lookups
        memoryDb.shops.set(shopId, s);
        break;
      }
    }
  }

  if (shop) {
    req.shopId = shop.id; // normalize to canonical shop.id
    if (shop.ownerId === req.user.userId) {
      req.shopRole = 'OWNER';
      req.permissions = ['ALL'];
      return next();
    }

    const perm = memoryDb.staffPermissions.get(`${shop.id}:${req.user.userId}`) || memoryDb.staffPermissions.get(`${shopId}:${req.user.userId}`);
    if (perm) {
      req.shopRole = perm.role || 'STAFF';
      req.permissions = perm.permissions || [];
      return next();
    }
  }

  try {
    // Database lookup
    const shopRes = await pool.query('SELECT * FROM shops WHERE id = $1 OR shop_code = $1 OR owner_id = $2', [shopId, req.user.userId]);
    if (shopRes.rows.length > 0) {
      const dbShop = shopRes.rows[0];
      req.shopId = dbShop.id;
      if (dbShop.owner_id === req.user.userId) {
        req.shopRole = 'OWNER';
        req.permissions = ['ALL'];
        return next();
      }

      const permRes = await pool.query('SELECT * FROM staff_permissions WHERE shop_id = $1 AND user_id = $2', [dbShop.id, req.user.userId]);
      if (permRes.rows.length > 0) {
        const perm = permRes.rows[0];
        req.shopRole = perm.role || 'STAFF';
        req.permissions = typeof perm.permissions === 'string' ? JSON.parse(perm.permissions) : perm.permissions || [];
        return next();
      }
    }
  } catch (err) {
    // Database unreachable, rely on memory store resolution above
  }

  if (!shop) {
    return res.status(404).json({ error: 'Shop not found' });
  }

  return res.status(403).json({ error: 'Forbidden: You do not have access to this shop' });
}

/**
 * Middleware 3: Enforce Granular Staff Permission
 */
export function requirePermission(requiredPermission: string) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Owner always has full access
    if (req.shopRole === 'OWNER') {
      return next();
    }

    const perms = req.permissions || [];
    if (perms.includes('ALL') || perms.includes(requiredPermission)) {
      return next();
    }

    return res.status(403).json({ error: `Forbidden: Missing required permission '${requiredPermission}'` });
  };
}
