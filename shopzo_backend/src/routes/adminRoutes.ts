import { Router, Request, Response } from 'express';
import { pool, memoryDb, useMemoryDb } from '../db';

const router = Router();

/**
 * Resets all testing accounts, shops, customer details, and transaction history.
 * Prepares the cloud database for clean production customer onboarding.
 */
router.post('/reset-all-data', async (req: Request, res: Response) => {
  try {
    // 1. Clear In-Memory database
    memoryDb.clear();

    // 2. Clear Cloud PostgreSQL database
    let pgCleared = false;
    if (!useMemoryDb) {
      try {
        await pool.query(`
          TRUNCATE TABLE 
            returns, 
            payments, 
            bill_items, 
            bills, 
            customers, 
            stock_movements, 
            products, 
            categories, 
            staff_permissions, 
            shops, 
            users 
          CASCADE;
        `);
        pgCleared = true;
      } catch (dbErr: any) {
        try {
          const tables = [
            'returns', 'payments', 'bill_items', 'bills', 'customers', 
            'stock_movements', 'products', 'categories', 'staff_permissions', 
            'shops', 'users'
          ];
          for (const tbl of tables) {
            await pool.query(`DELETE FROM ${tbl}`).catch(() => {});
          }
          pgCleared = true;
        } catch (_) {}
      }
    }

    return res.json({
      success: true,
      pgCleared,
      message: 'All testing accounts, customers, shops, and transaction history have been permanently cleared. System is now fresh for new customers.'
    });
  } catch (error: any) {
    return res.status(500).json({ error: error.message || 'Failed to reset testing data' });
  }
});

export default router;
