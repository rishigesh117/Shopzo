import { Router } from 'express';
import { createShop, getMyShops, getShopById } from '../controllers/shopController';
import { authenticateUser, authorizeShopAccess } from '../middleware/authMiddleware';

const router = Router();

router.use(authenticateUser);

router.post('/', createShop);
router.get('/my-shops', getMyShops);
router.get('/:shopId', authorizeShopAccess, getShopById);

export default router;
