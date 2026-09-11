import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import { hashPassword } from '../utils/auth';
import { pool, memoryDb, useMemoryDb } from '../db';

export async function getStaffList(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;

  if (useMemoryDb) {
    const list: any[] = [];
    for (const perm of memoryDb.staffPermissions.values()) {
      if (perm.shopId === shopId) {
        const user = memoryDb.users.get(perm.userId);
        list.push({
          staffId: perm.id,
          userId: perm.userId,
          name: user ? user.name : 'Staff',
          mobileNumber: user ? user.mobileNumber : '',
          role: perm.role,
          permissions: perm.permissions
        });
      }
    }
    return res.json({ staff: list });
  }

  try {
    const resStaff = await pool.query(
      `SELECT sp.id as staff_id, u.id as user_id, u.name, u.mobile_number, sp.role, sp.permissions
       FROM staff_permissions sp
       JOIN users u ON sp.user_id = u.id
       WHERE sp.shop_id = $1`,
      [shopId]
    );

    const formatted = resStaff.rows.map(r => ({
      staffId: r.staff_id,
      userId: r.user_id,
      name: r.name,
      mobileNumber: r.mobile_number,
      role: r.role,
      permissions: typeof r.permissions === 'string' ? JSON.parse(r.permissions) : r.permissions
    }));

    return res.json({ staff: formatted });
  } catch (err) {
    return res.status(500).json({ error: 'Database error fetching staff list' });
  }
}

export async function addStaff(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;
  const { name, mobileNumber, password, permissions } = req.body;

  if (!name || !mobileNumber || !password) {
    return res.status(400).json({ error: 'Name, mobile number, and password are required for staff creation' });
  }

  const cleanMobile = mobileNumber.trim();
  const now = Date.now();
  const permList = Array.isArray(permissions) ? permissions : [];

  if (useMemoryDb) {
    let user: any = null;
    for (const u of memoryDb.users.values()) {
      if (u.mobileNumber === cleanMobile) {
        user = u;
        break;
      }
    }

    if (!user) {
      const userId = uuidv4();
      const passwordHash = await hashPassword(password);
      user = { id: userId, mobileNumber: cleanMobile, passwordHash, name: name.trim(), createdAt: now, updatedAt: now };
      memoryDb.users.set(userId, user);
    }

    const permKey = `${shopId}:${user.id}`;
    if (memoryDb.staffPermissions.has(permKey)) {
      return res.status(409).json({ error: 'Staff member already added to this shop' });
    }

    const permId = uuidv4();
    const permRecord = {
      id: permId,
      shopId,
      userId: user.id,
      role: 'STAFF',
      permissions: permList,
      createdAt: now,
      updatedAt: now
    };
    memoryDb.staffPermissions.set(permKey, permRecord);

    return res.status(201).json({
      staff: {
        staffId: permId,
        userId: user.id,
        name: user.name,
        mobileNumber: user.mobileNumber,
        role: 'STAFF',
        permissions: permList
      }
    });
  }

  try {
    let userId: string;
    const userRes = await pool.query('SELECT * FROM users WHERE mobile_number = $1', [cleanMobile]);
    if (userRes.rows.length === 0) {
      userId = uuidv4();
      const passwordHash = await hashPassword(password);
      await pool.query(
        'INSERT INTO users (id, mobile_number, password_hash, name, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6)',
        [userId, cleanMobile, passwordHash, name.trim(), now, now]
      );
    } else {
      userId = userRes.rows[0].id;
    }

    const checkPerm = await pool.query('SELECT * FROM staff_permissions WHERE shop_id = $1 AND user_id = $2', [shopId, userId]);
    if (checkPerm.rows.length > 0) {
      return res.status(409).json({ error: 'Staff member already added to this shop' });
    }

    const permId = uuidv4();
    await pool.query(
      'INSERT INTO staff_permissions (id, shop_id, user_id, role, permissions, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7)',
      [permId, shopId, userId, 'STAFF', JSON.stringify(permList), now, now]
    );

    return res.status(201).json({
      staff: {
        staffId: permId,
        userId,
        name: name.trim(),
        mobileNumber: cleanMobile,
        role: 'STAFF',
        permissions: permList
      }
    });
  } catch (err) {
    return res.status(500).json({ error: 'Database error adding staff' });
  }
}

export async function updateStaffPermissions(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;
  const staffId = req.params.staffId;
  const { permissions } = req.body;

  if (!Array.isArray(permissions)) {
    return res.status(400).json({ error: 'Permissions must be an array' });
  }

  const now = Date.now();

  if (useMemoryDb) {
    let targetPerm: any = null;
    let targetKey: string = '';
    for (const [key, perm] of memoryDb.staffPermissions.entries()) {
      if (perm.id === staffId && perm.shopId === shopId) {
        targetPerm = perm;
        targetKey = key;
        break;
      }
    }

    if (!targetPerm) {
      return res.status(404).json({ error: 'Staff record not found' });
    }

    // Owner protection
    if (targetPerm.role === 'OWNER') {
      return res.status(403).json({ error: 'Cannot modify permissions for shop owner' });
    }

    targetPerm.permissions = permissions;
    targetPerm.updatedAt = now;
    memoryDb.staffPermissions.set(targetKey, targetPerm);

    return res.json({ message: 'Permissions updated successfully', permissions });
  }

  try {
    const permRes = await pool.query('SELECT * FROM staff_permissions WHERE id = $1 AND shop_id = $2', [staffId, shopId]);
    if (permRes.rows.length === 0) {
      return res.status(404).json({ error: 'Staff record not found' });
    }

    if (permRes.rows[0].role === 'OWNER') {
      return res.status(403).json({ error: 'Cannot modify permissions for shop owner' });
    }

    await pool.query('UPDATE staff_permissions SET permissions = $1, updated_at = $2 WHERE id = $3', [
      JSON.stringify(permissions),
      now,
      staffId
    ]);

    return res.json({ message: 'Permissions updated successfully', permissions });
  } catch (err) {
    return res.status(500).json({ error: 'Database error updating permissions' });
  }
}

export async function deleteStaff(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;
  const staffId = req.params.staffId;

  if (useMemoryDb) {
    let targetKey: string = '';
    let targetPerm: any = null;
    for (const [key, perm] of memoryDb.staffPermissions.entries()) {
      if (perm.id === staffId && perm.shopId === shopId) {
        targetKey = key;
        targetPerm = perm;
        break;
      }
    }

    if (!targetPerm) {
      return res.status(404).json({ error: 'Staff record not found' });
    }

    if (targetPerm.role === 'OWNER') {
      return res.status(403).json({ error: 'Cannot remove shop owner from shop' });
    }

    memoryDb.staffPermissions.delete(targetKey);
    return res.json({ message: 'Staff removed successfully' });
  }

  try {
    const permRes = await pool.query('SELECT * FROM staff_permissions WHERE id = $1 AND shop_id = $2', [staffId, shopId]);
    if (permRes.rows.length === 0) {
      return res.status(404).json({ error: 'Staff record not found' });
    }

    if (permRes.rows[0].role === 'OWNER') {
      return res.status(403).json({ error: 'Cannot remove shop owner from shop' });
    }

    await pool.query('DELETE FROM staff_permissions WHERE id = $1', [staffId]);
    return res.json({ message: 'Staff removed successfully' });
  } catch (err) {
    return res.status(500).json({ error: 'Database error removing staff' });
  }
}
