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

  if (useMemoryDb) {
    const shop = memoryDb.shops.get(shopId);
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    if (shop.ownerId === req.user.userId) {
      req.shopRole = 'OWNER';
      req.permissions = ['ALL'];
      return next();
    }

    const perm = memoryDb.staffPermissions.get(`${shopId}:${req.user.userId}`);
    if (!perm) {
      return res.status(403).json({ error: 'Forbidden: You do not have access to this shop' });
    }

    req.shopRole = perm.role || 'STAFF';
    req.permissions = perm.permissions || [];
    return next();
  }

  try {
    // Database lookup
    const shopRes = await pool.query('SELECT * FROM shops WHERE id = $1', [shopId]);
    if (shopRes.rows.length === 0) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    const shop = shopRes.rows[0];
    if (shop.owner_id === req.user.userId) {
      req.shopRole = 'OWNER';
      req.permissions = ['ALL'];
      return next();
    }

    const permRes = await pool.query('SELECT * FROM staff_permissions WHERE shop_id = $1 AND user_id = $2', [shopId, req.user.userId]);
    if (permRes.rows.length === 0) {
      return res.status(403).json({ error: 'Forbidden: You do not have access to this shop' });
    }

    const perm = permRes.rows[0];
    req.shopRole = perm.role || 'STAFF';
    req.permissions = typeof perm.permissions === 'string' ? JSON.parse(perm.permissions) : perm.permissions || [];
    return next();
  } catch (err) {
    return res.status(500).json({ error: 'Internal Server Error' });
  }
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
