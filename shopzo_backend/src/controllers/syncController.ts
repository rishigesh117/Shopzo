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

/** Map DB row helpers: PostgreSQL snake_case → camelCase for Android DTOs */
function mapCategoryRow(r: any): any {
  return { id: r.id, shopId: r.shop_id ?? r.shopId, name: r.name, createdAt: r.created_at ?? r.createdAt, updatedAt: r.updated_at ?? r.updatedAt, deleted: r.deleted ?? false };
}
function mapProductRow(r: any): any {
  return { id: r.id, shopId: r.shop_id ?? r.shopId, categoryId: r.category_id ?? r.categoryId, name: r.name, brand: r.brand ?? null, buyingPricePaise: r.buying_price_paise ?? r.buyingPricePaise ?? 0, sellingPricePaise: r.selling_price_paise ?? r.sellingPricePaise ?? 0, quantity: r.quantity ?? 0, unit: r.unit ?? 'PCS', minStockLevel: r.min_stock_level ?? r.minStockLevel ?? 0, createdAt: r.created_at ?? r.createdAt, updatedAt: r.updated_at ?? r.updatedAt, deleted: r.deleted ?? false };
}
function mapStockMovementRow(r: any): any {
  return { id: r.id, shopId: r.shop_id ?? r.shopId, productId: r.product_id ?? r.productId, type: r.type, quantity: r.quantity ?? 0, reason: r.reason ?? null, createdAt: r.created_at ?? r.createdAt };
}
function mapCustomerRow(r: any): any {
  return { id: r.id, shopId: r.shop_id ?? r.shopId, name: r.name, mobileNumber: r.mobile_number ?? r.mobileNumber ?? '', address: r.address ?? null, totalPurchasePaise: r.total_purchase_paise ?? r.totalPurchasePaise ?? 0, outstandingDuePaise: r.outstanding_due_paise ?? r.outstandingDuePaise ?? 0, createdAt: r.created_at ?? r.createdAt, updatedAt: r.updated_at ?? r.updatedAt, deleted: r.deleted ?? false };
}
function mapBillRow(r: any): any {
  return { id: r.id, shopId: r.shop_id ?? r.shopId, billNumber: r.bill_number ?? r.billNumber ?? '', customerId: r.customer_id ?? r.customerId ?? null, customerNameSnapshot: r.customer_name_snapshot ?? r.customerNameSnapshot ?? '', customerMobileSnapshot: r.customer_mobile_snapshot ?? r.customerMobileSnapshot ?? '', subtotalPaise: r.subtotal_paise ?? r.subtotalPaise ?? 0, grandTotalPaise: r.grand_total_paise ?? r.grandTotalPaise ?? 0, paidAmountPaise: r.paid_amount_paise ?? r.paidAmountPaise ?? 0, pendingAmountPaise: r.pending_amount_paise ?? r.pendingAmountPaise ?? 0, paymentStatus: r.payment_status ?? r.paymentStatus ?? 'PAID', createdAt: r.created_at ?? r.createdAt, updatedAt: r.updated_at ?? r.updatedAt };
}
function mapBillItemRow(r: any): any {
  return { id: r.id, shopId: r.shop_id ?? r.shopId, billId: r.bill_id ?? r.billId, productId: r.product_id ?? r.productId, productNameSnapshot: r.product_name_snapshot ?? r.productNameSnapshot ?? '', quantity: r.quantity ?? 0, unit: r.unit ?? 'PCS', sellingPricePaise: r.selling_price_paise ?? r.sellingPricePaise ?? 0, buyingPricePaise: r.buying_price_paise ?? r.buyingPricePaise ?? 0, subtotalPaise: r.subtotal_paise ?? r.subtotalPaise ?? 0 };
}
function mapPaymentRow(r: any): any {
  return { id: r.id, shopId: r.shop_id ?? r.shopId, billId: r.bill_id ?? r.billId ?? null, customerId: r.customer_id ?? r.customerId ?? null, amountPaise: r.amount_paise ?? r.amountPaise ?? 0, paymentMethod: r.payment_method ?? r.paymentMethod ?? 'CASH', createdAt: r.created_at ?? r.createdAt };
}
function mapReturnRow(r: any): any {
  return { id: r.id, shopId: r.shop_id ?? r.shopId, billId: r.bill_id ?? r.billId, billItemId: r.bill_item_id ?? r.billItemId, productId: r.product_id ?? r.productId, quantityReturned: r.quantity_returned ?? r.quantityReturned ?? 0, refundAmountPaise: r.refund_amount_paise ?? r.refundAmountPaise ?? 0, stockRestored: r.stock_restored ?? r.stockRestored ?? true, reason: r.reason ?? null, createdAt: r.created_at ?? r.createdAt };
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
        categories: categories.rows.map(mapCategoryRow),
        products: products.rows.map(mapProductRow),
        stockMovements: stockMovements.rows.map(mapStockMovementRow),
        customers: customers.rows.map(mapCustomerRow),
        bills: bills.rows.map(mapBillRow),
        billItems: billItems.rows.map(mapBillItemRow),
        payments: payments.rows.map(mapPaymentRow),
        returns: returns.rows.map(mapReturnRow)
      }
    });
  } catch (err) {
    return res.status(500).json({ error: 'Database error during pull sync' });
  }
}

