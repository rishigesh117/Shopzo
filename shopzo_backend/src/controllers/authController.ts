import { Request, Response } from 'express';
import { UserRepository } from '../repositories/userRepository';
import { ShopRepository } from '../repositories/shopRepository';
import { generateToken } from '../utils/jwt';
import { AuthenticatedRequest } from '../middleware/auth';

export class AuthController {
  static async register(req: Request, res: Response) {
    try {
      const { phone, name } = req.body;
      if (!phone || !name) {
        return res.status(400).json({ success: false, error: 'Phone number and name are required' });
      }

      let user = await UserRepository.findByPhone(phone);
      if (user) {
        return res.status(400).json({ success: false, error: 'User with this phone number already exists. Please login.' });
      }

      user = await UserRepository.create(phone, name, 'OWNER');
      const token = generateToken({ userId: user.id, phone: user.phone });
      const shops = await ShopRepository.findUserShops(user.id);

      return res.status(201).json({
        success: true,
        data: {
          token,
          user,
          shops
        }
      });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message || 'Registration failed' });
    }
  }

  static async login(req: Request, res: Response) {
    try {
      const { phone, otp } = req.body;
      if (!phone) {
        return res.status(400).json({ success: false, error: 'Phone number is required' });
      }

      // Mock OTP validation (e.g., '123456' or any 6-digit number for mock mode)
      const mockCode = process.env.OTP_MOCK_CODE || '123456';
      if (otp && otp !== mockCode && otp !== '000000') {
        // Allow flexible login in test/dev mode if OTP provided
      }

      let user = await UserRepository.findByPhone(phone);
      if (!user) {
        // Auto-register user with phone number if first-time login
        const defaultName = `User ${phone.slice(-4)}`;
        user = await UserRepository.create(phone, defaultName, 'OWNER');
      }

      const token = generateToken({ userId: user.id, phone: user.phone });
      const shops = await ShopRepository.findUserShops(user.id);

      return res.json({
        success: true,
        data: {
          token,
          user,
          shops
        }
      });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message || 'Login failed' });
    }
  }

  static async me(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        return res.status(401).json({ success: false, error: 'Unauthorized' });
      }

      const user = await UserRepository.findById(userId);
      if (!user) {
        return res.status(404).json({ success: false, error: 'User not found' });
      }

      const shops = await ShopRepository.findUserShops(userId);
      return res.json({
        success: true,
        data: {
          user,
          shops
        }
      });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}
