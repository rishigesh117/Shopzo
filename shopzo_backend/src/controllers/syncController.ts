import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth';
import { SyncRepository, SyncOperation } from '../repositories/syncRepository';

export class SyncController {
  static async push(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.userId;
      const shopId = req.shopMember?.shopId;
      const { operations } = req.body;

      if (!userId || !shopId) {
        return res.status(400).json({ success: false, error: 'User and Shop context required' });
      }

      if (!Array.isArray(operations)) {
        return res.status(400).json({ success: false, error: 'Operations must be an array' });
      }

      const result = await SyncRepository.pushOperations(shopId, userId, operations as SyncOperation[]);

      return res.json({
        success: true,
        data: {
          processedCount: result.processedCount,
          failedCount: result.failedOperations.length,
          failedOperations: result.failedOperations,
          serverTimestamp: new Date().toISOString()
        }
      });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message || 'Push sync failed' });
    }
  }

  static async pull(req: AuthenticatedRequest, res: Response) {
    try {
      const shopId = req.shopMember?.shopId;
      const lastSyncedAt = (req.query.lastSyncedAt || req.query.last_synced_at) as string | undefined;

      if (!shopId) {
        return res.status(400).json({ success: false, error: 'Shop context required' });
      }

      const result = await SyncRepository.pullChanges(shopId, lastSyncedAt);

      return res.json({
        success: true,
        data: result
      });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message || 'Pull sync failed' });
    }
  }
}
