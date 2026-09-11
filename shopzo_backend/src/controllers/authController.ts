import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import { hashPassword, comparePassword, generateToken } from '../utils/auth';
import { pool, memoryDb, useMemoryDb } from '../db';

export async function register(req: AuthenticatedRequest, res: Response) {
  const { mobileNumber, password, name } = req.body;
  if (!mobileNumber || !password || !name) {
    return res.status(400).json({ error: 'Mobile number, password, and name are required' });
  }

  const cleanMobile = mobileNumber.trim();
  const userId = uuidv4();
  const passwordHash = await hashPassword(password);
  const now = Date.now();

  if (useMemoryDb) {
    // Check duplicate
    for (const u of memoryDb.users.values()) {
      if (u.mobileNumber === cleanMobile) {
        return res.status(409).json({ error: 'User with this mobile number already exists' });
      }
    }
    const user = { id: userId, mobileNumber: cleanMobile, passwordHash, name, createdAt: now, updatedAt: now };
    memoryDb.users.set(userId, user);
    const token = generateToken({ userId, mobileNumber: cleanMobile, name });
    return res.status(201).json({ token, user: { id: userId, mobileNumber: cleanMobile, name } });
  }

  try {
    const existing = await pool.query('SELECT * FROM users WHERE mobile_number = $1', [cleanMobile]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'User with this mobile number already exists' });
    }

    await pool.query(
      'INSERT INTO users (id, mobile_number, password_hash, name, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6)',
      [userId, cleanMobile, passwordHash, name, now, now]
    );

    const token = generateToken({ userId, mobileNumber: cleanMobile, name });
    return res.status(201).json({ token, user: { id: userId, mobileNumber: cleanMobile, name } });
  } catch (err) {
    return res.status(500).json({ error: 'Database error during registration' });
  }
}

export async function login(req: AuthenticatedRequest, res: Response) {
  const { mobileNumber, password } = req.body;
  if (!mobileNumber || !password) {
    return res.status(400).json({ error: 'Mobile number and password are required' });
  }

  const cleanMobile = mobileNumber.trim();

  if (useMemoryDb) {
    let targetUser: any = null;
    for (const u of memoryDb.users.values()) {
      if (u.mobileNumber === cleanMobile) {
        targetUser = u;
        break;
      }
    }
    if (!targetUser) {
      return res.status(401).json({ error: 'Incorrect mobile number or password' });
    }

    const match = await comparePassword(password, targetUser.passwordHash);
    if (!match) {
      return res.status(401).json({ error: 'Incorrect mobile number or password' });
    }

    const token = generateToken({ userId: targetUser.id, mobileNumber: targetUser.mobileNumber, name: targetUser.name });
    
    // Find shops
    const userShops: any[] = [];
    for (const shop of memoryDb.shops.values()) {
      if (shop.ownerId === targetUser.id) {
        userShops.push({ ...shop, role: 'OWNER' });
      }
    }
    for (const perm of memoryDb.staffPermissions.values()) {
      if (perm.userId === targetUser.id) {
        const shop = memoryDb.shops.get(perm.shopId);
        if (shop && !userShops.some(s => s.id === shop.id)) {
          userShops.push({ ...shop, role: perm.role || 'STAFF', permissions: perm.permissions });
        }
      }
    }

    return res.json({ token, user: { id: targetUser.id, mobileNumber: targetUser.mobileNumber, name: targetUser.name }, shops: userShops });
  }

  try {
    const userRes = await pool.query('SELECT * FROM users WHERE mobile_number = $1', [cleanMobile]);
    if (userRes.rows.length === 0) {
      return res.status(401).json({ error: 'Incorrect mobile number or password' });
    }

    const user = userRes.rows[0];
    const match = await comparePassword(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ error: 'Incorrect mobile number or password' });
    }

    const token = generateToken({ userId: user.id, mobileNumber: user.mobile_number, name: user.name });

    // Fetch shops for this user
    const shopsRes = await pool.query(
      `SELECT s.*, 'OWNER' as role FROM shops s WHERE s.owner_id = $1
       UNION
       SELECT s.*, sp.role FROM shops s JOIN staff_permissions sp ON s.id = sp.shop_id WHERE sp.user_id = $1`,
      [user.id]
    );

    return res.json({
      token,
      user: { id: user.id, mobileNumber: user.mobile_number, name: user.name },
      shops: shopsRes.rows
    });
  } catch (err) {
    return res.status(500).json({ error: 'Database error during login' });
  }
}

export async function getMe(req: AuthenticatedRequest, res: Response) {
  if (!req.user) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  return res.json({ user: req.user });
}
