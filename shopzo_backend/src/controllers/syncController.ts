import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import { pool, memoryDb, useMemoryDb } from '../db';

export interface SyncOperation {
  id: string; // Queue item id from Android
  entityType: 'CATEGORY' | 'PRODUCT' | 'STOCK_MOVEMENT' | 'CUSTOMER' | 'BILL' | 'BILL_ITEM' | 'PAYMENT' | 'RETURN';
  entityId: string; // Client-side UUID
  operationType: 'CREATE' | 'UPDATE' | 'DELETE';
  payload: any;
  shopId: string;
  createdAt: number;
}

export async function pushSync(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;
  const { operations } = req.body;

  if (!Array.isArray(operations)) {
    return res.status(400).json({ error: 'Operations must be an array' });
  }

  const syncedIds: string[] = [];

  for (const op of operations) {
    if (!op.entityId || !op.entityType || op.shopId !== shopId) {
      continue;
    }

    try {
      if (useMemoryDb) {
        processMemoryOperation(op, shopId);
      } else {
        await processDbOperation(op, shopId);
      }
      syncedIds.push(op.id);
    } catch (err) {
      // If error occurs on single item, continue processing others safely
      console.error(`Error processing sync item ${op.id} (${op.entityType}):`, err);
    }
  }

  return res.json({ syncedIds, serverTime: Date.now() });
}

function processMemoryOperation(op: SyncOperation, shopId: string) {
  const p = op.payload || {};
  const entityId = op.entityId;

  switch (op.entityType) {
    case 'CATEGORY':
      memoryDb.categories.set(entityId, { ...p, id: entityId, shopId, updatedAt: p.updatedAt || Date.now() });
      break;
    case 'PRODUCT':
      memoryDb.products.set(entityId, { ...p, id: entityId, shopId, updatedAt: p.updatedAt || Date.now() });
      break;
    case 'STOCK_MOVEMENT':
      if (!memoryDb.stockMovements.has(entityId)) {
        memoryDb.stockMovements.set(entityId, { ...p, id: entityId, shopId });
      }
      break;
    case 'CUSTOMER':
      memoryDb.customers.set(entityId, { ...p, id: entityId, shopId, updatedAt: p.updatedAt || Date.now() });
      break;
    case 'BILL':
      memoryDb.bills.set(entityId, { ...p, id: entityId, shopId, updatedAt: p.updatedAt || Date.now() });
      break;
    case 'BILL_ITEM':
      memoryDb.billItems.set(entityId, { ...p, id: entityId, shopId });
      break;
    case 'PAYMENT':
      if (!memoryDb.payments.has(entityId)) {
        memoryDb.payments.set(entityId, { ...p, id: entityId, shopId });
      }
      break;
    case 'RETURN':
      if (!memoryDb.returns.has(entityId)) {
        memoryDb.returns.set(entityId, { ...p, id: entityId, shopId });
      }
      break;
  }
}

async function processDbOperation(op: SyncOperation, shopId: string) {
  const p = op.payload || {};
  const entityId = op.entityId;
  const now = Date.now();

  switch (op.entityType) {
    case 'CATEGORY':
      await pool.query(
        `INSERT INTO categories (id, shop_id, name, created_at, updated_at, deleted)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, updated_at = EXCLUDED.updated_at, deleted = EXCLUDED.deleted`,
        [entityId, shopId, p.name || 'Category', p.createdAt || now, p.updatedAt || now, p.deleted || false]
      );
      break;

    case 'PRODUCT':
      await pool.query(
        `INSERT INTO products (id, shop_id, category_id, name, brand, buying_price_paise, selling_price_paise, quantity, unit, min_stock_level, created_at, updated_at, deleted)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
         ON CONFLICT (id) DO UPDATE SET
           category_id = EXCLUDED.category_id,
           name = EXCLUDED.name,
           brand = EXCLUDED.brand,
           buying_price_paise = EXCLUDED.buying_price_paise,
           selling_price_paise = EXCLUDED.selling_price_paise,
           quantity = EXCLUDED.quantity,
           unit = EXCLUDED.unit,
           min_stock_level = EXCLUDED.min_stock_level,
           updated_at = EXCLUDED.updated_at,
           deleted = EXCLUDED.deleted`,
        [
          entityId,
          shopId,
          p.categoryId || '',
          p.name || 'Product',
          p.brand || null,
          p.buyingPricePaise || 0,
          p.sellingPricePaise || 0,
          p.quantity || 0,
          p.unit || 'PCS',
          p.minStockLevel || 0,
          p.createdAt || now,
          p.updatedAt || now,
          p.deleted || false
        ]
      );
      break;

    case 'STOCK_MOVEMENT':
      await pool.query(
        `INSERT INTO stock_movements (id, shop_id, product_id, type, quantity, reason, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (id) DO NOTHING`,
        [entityId, shopId, p.productId || '', p.type || 'RESTOCK', p.quantity || 0, p.reason || null, p.createdAt || now]
      );
      break;

    case 'CUSTOMER':
      await pool.query(
        `INSERT INTO customers (id, shop_id, name, mobile_number, address, total_purchase_paise, outstanding_due_paise, created_at, updated_at, deleted)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
         ON CONFLICT (id) DO UPDATE SET
           name = EXCLUDED.name,
           mobile_number = EXCLUDED.mobile_number,
           address = EXCLUDED.address,
           total_purchase_paise = EXCLUDED.total_purchase_paise,
           outstanding_due_paise = EXCLUDED.outstanding_due_paise,
           updated_at = EXCLUDED.updated_at,
           deleted = EXCLUDED.deleted`,
        [
          entityId,
          shopId,
          p.name || 'Customer',
          p.mobileNumber || '',
          p.address || null,
          p.totalPurchasePaise || 0,
          p.outstandingDuePaise || 0,
          p.createdAt || now,
          p.updatedAt || now,
          p.deleted || false
        ]
      );
      break;

    case 'BILL':
      await pool.query(
        `INSERT INTO bills (id, shop_id, bill_number, customer_id, customer_name_snapshot, customer_mobile_snapshot, subtotal_paise, grand_total_paise, paid_amount_paise, pending_amount_paise, payment_status, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
         ON CONFLICT (id) DO UPDATE SET
           paid_amount_paise = EXCLUDED.paid_amount_paise,
           pending_amount_paise = EXCLUDED.pending_amount_paise,
           payment_status = EXCLUDED.payment_status,
           updated_at = EXCLUDED.updated_at`,
        [
          entityId,
          shopId,
          p.billNumber || '',
          p.customerId || null,
          p.customerNameSnapshot || 'Walk-in Customer',
          p.customerMobileSnapshot || '',
          p.subtotalPaise || 0,
          p.grandTotalPaise || 0,
          p.paidAmountPaise || 0,
          p.pendingAmountPaise || 0,
          p.paymentStatus || 'PAID',
          p.createdAt || now,
          p.updatedAt || now
        ]
      );
      break;

    case 'BILL_ITEM':
      await pool.query(
        `INSERT INTO bill_items (id, shop_id, bill_id, product_id, product_name_snapshot, quantity, unit, selling_price_paise, buying_price_paise, subtotal_paise)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
         ON CONFLICT (id) DO NOTHING`,
        [
          entityId,
          shopId,
          p.billId || '',
          p.productId || '',
          p.productNameSnapshot || 'Item',
          p.quantity || 0,
          p.unit || 'PCS',
          p.sellingPricePaise || 0,
          p.buyingPricePaise || 0,
          p.subtotalPaise || 0
        ]
      );
      break;

    case 'PAYMENT':
      await pool.query(
        `INSERT INTO payments (id, shop_id, bill_id, customer_id, amount_paise, payment_method, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (id) DO NOTHING`,
        [entityId, shopId, p.billId || null, p.customerId || null, p.amountPaise || 0, p.paymentMethod || 'CASH', p.createdAt || now]
      );
      break;

    case 'RETURN':
      await pool.query(
        `INSERT INTO returns (id, shop_id, bill_id, bill_item_id, product_id, quantity_returned, refund_amount_paise, stock_restored, reason, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
         ON CONFLICT (id) DO NOTHING`,
        [
          entityId,
          shopId,
          p.billId || '',
          p.billItemId || '',
          p.productId || '',
          p.quantityReturned || 0,
          p.refundAmountPaise || 0,
          p.stockRestored !== undefined ? p.stockRestored : true,
          p.reason || null,
          p.createdAt || now
        ]
      );
      break;
  }
}

export async function pullSync(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;
  const since = parseInt((req.query.since as string) || '0', 10);
  const serverTime = Date.now();

  if (useMemoryDb) {
    const filterByShopAndSince = (map: Map<string, any>, timeField = 'updatedAt') => {
      const arr: any[] = [];
      for (const v of map.values()) {
        if (v.shopId === shopId && (v[timeField] || v.createdAt || 0) >= since) {
          arr.push(v);
        }
      }
      return arr;
    };

    return res.json({
      serverTime,
      delta: {
        categories: filterByShopAndSince(memoryDb.categories),
        products: filterByShopAndSince(memoryDb.products),
        stockMovements: filterByShopAndSince(memoryDb.stockMovements, 'createdAt'),
        customers: filterByShopAndSince(memoryDb.customers),
        bills: filterByShopAndSince(memoryDb.bills),
        billItems: filterByShopAndSince(memoryDb.billItems, 'createdAt'),
        payments: filterByShopAndSince(memoryDb.payments, 'createdAt'),
        returns: filterByShopAndSince(memoryDb.returns, 'createdAt')
      }
    });
  }

  try {
    const categories = await pool.query('SELECT * FROM categories WHERE shop_id = $1 AND updated_at >= $2', [shopId, since]);
    const products = await pool.query('SELECT * FROM products WHERE shop_id = $1 AND updated_at >= $2', [shopId, since]);
    const stockMovements = await pool.query('SELECT * FROM stock_movements WHERE shop_id = $1 AND created_at >= $2', [shopId, since]);
    const customers = await pool.query('SELECT * FROM customers WHERE shop_id = $1 AND updated_at >= $2', [shopId, since]);
    const bills = await pool.query('SELECT * FROM bills WHERE shop_id = $1 AND updated_at >= $2', [shopId, since]);
    const billItems = await pool.query('SELECT bi.* FROM bill_items bi JOIN bills b ON bi.bill_id = b.id WHERE b.shop_id = $1 AND b.updated_at >= $2', [shopId, since]);
    const payments = await pool.query('SELECT * FROM payments WHERE shop_id = $1 AND created_at >= $2', [shopId, since]);
    const returns = await pool.query('SELECT * FROM returns WHERE shop_id = $1 AND created_at >= $2', [shopId, since]);

    return res.json({
      serverTime,
      delta: {
        categories: categories.rows,
        products: products.rows,
        stockMovements: stockMovements.rows,
        customers: customers.rows,
        bills: bills.rows,
        billItems: billItems.rows,
        payments: payments.rows,
        returns: returns.rows
      }
    });
  } catch (err) {
    return res.status(500).json({ error: 'Database error during pull sync' });
  }
}
