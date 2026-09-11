import { Router } from 'express';
import { pushSync, pullSync } from '../controllers/syncController';
import { authenticateUser, authorizeShopAccess } from '../middleware/authMiddleware';

const router = Router();

router.use(authenticateUser);
router.use(authorizeShopAccess);

router.post('/push', pushSync);
router.get('/pull', pullSync);

export default router;
