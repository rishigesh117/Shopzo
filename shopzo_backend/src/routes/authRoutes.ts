import { Router } from 'express';
import { register, login, getMe, resetPassword } from '../controllers/authController';
import { authenticateUser } from '../middleware/authMiddleware';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.post('/reset-password', resetPassword);
router.get('/me', authenticateUser, getMe);

export default router;
