import { Router } from 'express';
import { ShopController } from '../controllers/shopController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

router.use(authenticateToken);

router.post('/create', ShopController.createShop);
router.get('/my-shops', ShopController.getMyShops);
router.get('/by-code/:code', ShopController.getByCode);

export default router;
