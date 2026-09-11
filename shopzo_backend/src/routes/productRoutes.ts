import { Router } from 'express';
import { getProducts, createProduct, updateProduct, deleteProduct } from '../controllers/productController';
import { authenticateUser, authorizeShopAccess, requirePermission } from '../middleware/authMiddleware';

const router = Router({ mergeParams: true });

router.use(authenticateUser);
router.use(authorizeShopAccess);

router.get('/', getProducts);
router.post('/', requirePermission('INVENTORY_ADD'), createProduct);
router.put('/:productId', requirePermission('INVENTORY_EDIT'), updateProduct);
router.delete('/:productId', requirePermission('INVENTORY_DELETE'), deleteProduct);

export default router;
