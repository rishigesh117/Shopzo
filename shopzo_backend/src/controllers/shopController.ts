import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import { generateShopCode } from '../utils/auth';
import { pool, memoryDb, useMemoryDb } from '../db';

export async function createShop(req: AuthenticatedRequest, res: Response) {
  if (!req.user) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const { name, address } = req.body;
  if (!name || name.trim().length === 0) {
    return res.status(400).json({ error: 'Shop name is required' });
  }

  const shopId = uuidv4();
  const shopCode = generateShopCode();
  const now = Date.now();

  if (useMemoryDb) {
    const shop = {
      id: shopId,
      shopCode,
      name: name.trim(),
      address: address ? address.trim() : null,
      ownerId: req.user.userId,
      createdAt: now,
      updatedAt: now
    };
    memoryDb.shops.set(shopId, shop);

    // Also add owner entry to staffPermissions
    const permId = uuidv4();
    memoryDb.staffPermissions.set(`${shopId}:${req.user.userId}`, {
      id: permId,
      shopId,
      userId: req.user.userId,
      role: 'OWNER',
      permissions: ['ALL'],
      createdAt: now,
      updatedAt: now
    });

    return res.status(201).json({ shop });
  }

  try {
    await pool.query(
      'INSERT INTO shops (id, shop_code, name, owner_id, address, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7)',
      [shopId, shopCode, name.trim(), req.user.userId, address ? address.trim() : null, now, now]
    );

    const permId = uuidv4();
    await pool.query(
      'INSERT INTO staff_permissions (id, shop_id, user_id, role, permissions, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7)',
      [permId, shopId, req.user.userId, 'OWNER', JSON.stringify(['ALL']), now, now]
    );

    return res.status(201).json({
      shop: { id: shopId, shopCode, name: name.trim(), address, ownerId: req.user.userId, createdAt: now, updatedAt: now }
    });
  } catch (err) {
    return res.status(500).json({ error: 'Database error creating shop' });
  }
}

export async function getMyShops(req: AuthenticatedRequest, res: Response) {
  if (!req.user) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  if (useMemoryDb) {
    const userShops: any[] = [];
    for (const shop of memoryDb.shops.values()) {
      if (shop.ownerId === req.user.userId) {
        userShops.push({ ...shop, role: 'OWNER' });
      }
    }
    for (const perm of memoryDb.staffPermissions.values()) {
      if (perm.userId === req.user.userId) {
        const shop = memoryDb.shops.get(perm.shopId);
        if (shop && !userShops.some(s => s.id === shop.id)) {
          userShops.push({ ...shop, role: perm.role || 'STAFF', permissions: perm.permissions });
        }
      }
    }
    return res.json({ shops: userShops });
  }

  try {
    const resShops = await pool.query(
      `SELECT s.*, 'OWNER' as role FROM shops s WHERE s.owner_id = $1
       UNION
       SELECT s.*, sp.role FROM shops s JOIN staff_permissions sp ON s.id = sp.shop_id WHERE sp.user_id = $1`,
      [req.user.userId]
    );
    return res.json({ shops: resShops.rows });
  } catch (err) {
    return res.status(500).json({ error: 'Database error fetching shops' });
  }
}

export async function getShopById(req: AuthenticatedRequest, res: Response) {
  const shopId = req.params.shopId;
  if (!shopId) {
    return res.status(400).json({ error: 'Missing shopId' });
  }

  if (useMemoryDb) {
    const shop = memoryDb.shops.get(shopId);
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }
    return res.json({ shop });
  }

  try {
    const resShop = await pool.query('SELECT * FROM shops WHERE id = $1', [shopId]);
    if (resShop.rows.length === 0) {
      return res.status(404).json({ error: 'Shop not found' });
    }
    return res.json({ shop: resShop.rows[0] });
  } catch (err) {
    return res.status(500).json({ error: 'Database error fetching shop' });
  }
}
