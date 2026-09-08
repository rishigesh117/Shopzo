import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth';
import { ShopRepository } from '../repositories/shopRepository';

export class ShopController {
  static async createShop(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.userId;
      const { name } = req.body;

      if (!userId) {
        return res.status(401).json({ success: false, error: 'Unauthorized' });
      }

      if (!name || typeof name !== 'string' || name.trim().length === 0) {
        return res.status(400).json({ success: false, error: 'Shop name is required' });
      }

      const shop = await ShopRepository.createShop(name.trim(), userId);

      return res.status(201).json({
        success: true,
        data: shop
      });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message || 'Failed to create shop' });
    }
  }

  static async getMyShops(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        return res.status(401).json({ success: false, error: 'Unauthorized' });
      }

      const shops = await ShopRepository.findUserShops(userId);
      return res.json({
        success: true,
        data: shops
      });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  static async getByCode(req: AuthenticatedRequest, res: Response) {
    try {
      const { code } = req.params;
      if (!code) {
        return res.status(400).json({ success: false, error: 'Shop code required' });
      }

      const shop = await ShopRepository.findByCode(code.trim().toUpperCase());
      if (!shop) {
        return res.status(404).json({ success: false, error: 'Shop not found with provided code' });
      }

      return res.json({
        success: true,
        data: {
          id: shop.id,
          name: shop.name,
          shop_code: shop.shop_code
        }
      });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}
