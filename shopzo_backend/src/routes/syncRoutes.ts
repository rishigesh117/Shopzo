import { Router } from 'express';
import { SyncController } from '../controllers/syncController';
import { authenticateToken } from '../middleware/auth';
import { authorizeShopAccess } from '../middleware/authorize';

const router = Router();

router.use(authenticateToken);
router.use(authorizeShopAccess());

router.post('/push', SyncController.push);
router.get('/pull', SyncController.pull);

export default router;
