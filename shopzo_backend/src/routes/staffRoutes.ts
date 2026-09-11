import { Router } from 'express';
import { getStaffList, addStaff, updateStaffPermissions, deleteStaff } from '../controllers/staffController';
import { authenticateUser, authorizeShopAccess, requirePermission } from '../middleware/authMiddleware';

const router = Router({ mergeParams: true });

router.use(authenticateUser);
router.use(authorizeShopAccess);

router.get('/', requirePermission('TEAM_MANAGE'), getStaffList);
router.post('/', requirePermission('TEAM_MANAGE'), addStaff);
router.put('/:staffId/permissions', requirePermission('TEAM_EDIT_PERMISSIONS'), updateStaffPermissions);
router.delete('/:staffId', requirePermission('TEAM_MANAGE'), deleteStaff);

export default router;
