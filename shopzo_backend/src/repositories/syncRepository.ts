import { query, memoryDb } from '../db/pool';
import { generateUuid } from '../utils/codeGenerator';

export interface SyncOperation {
  id: string;
  tableName: string;
  recordId: string;
  action: 'INSERT' | 'UPDATE' | 'DELETE';
  payloadJson: string;
  createdAt: string;
}

export class SyncRepository {
  static async pushOperations(shopId: string, userId: string, operations: SyncOperation[]): Promise<{
    processedCount: number;
    failedOperations: Array<{ id: string; error: string }>;
  }> {
    let processedCount = 0;
    const failedOperations: Array<{ id: string; error: string }> = [];

    for (const op of operations) {
      try {
        const payload = JSON.parse(op.payloadJson);
        const tableName = op.tableName.toLowerCase();

        switch (tableName) {
          case 'categories':
            await this.upsertCategory(shopId, payload);
            break;
          case 'products':
            await this.upsertProduct(shopId, payload);
            break;
          case 'stock_movements':
            await this.insertStockMovement(shopId, payload);
            break;
          case 'customers':
            await this.upsertCustomer(shopId, payload);
            break;
          case 'bills':
            await this.insertBill(shopId, payload);
            break;
          case 'payments':
            await this.insertPayment(shopId, payload);
            break;
          case 'returns':
            await this.insertReturn(shopId, payload);
            break;
          default:
            console.warn(`[Sync] Unknown table name: ${op.tableName}`);
        }

        await this.logAudit(shopId, userId, op.tableName, op.recordId, op.action);
        processedCount++;
      } catch (err: any) {
        console.error(`[Sync Op Error] ${op.tableName} ${op.recordId}:`, err);
        failedOperations.push({ id: op.id, error: err.message || 'Operation processing failed' });
      }
    }

    return { processedCount, failedOperations };
  }

  private static async upsertCategory(shopId: string, payload: any) {
    const { id, name, is_default, created_at, updated_at } = payload;
    const isDefault = is_default === 1 || is_default === true;
    const now = new Date().toISOString();

    try {
      await query(
        `INSERT INTO categories (id, shop_id, name, is_default, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (id) DO UPDATE SET name = $3, is_default = $4, updated_at = $6`,
        [id, shopId, name, isDefault, created_at || now, updated_at || now]
      );
    } catch (e) {
      const idx = memoryDb.tables.categories.findIndex(c => c.id === id);
      const record = { id, shop_id: shopId, name, is_default: isDefault, created_at: created_at || now, updated_at: updated_at || now };
      if (idx >= 0) memoryDb.tables.categories[idx] = record;
      else memoryDb.tables.categories.push(record);
    }
  }

  private static async upsertProduct(shopId: string, payload: any) {
    const {
      id, name, category_id, category_name, brand, buying_price_paise, selling_price_paise,
      quantity, unit, min_stock_level, is_active, created_at, updated_at
    } = payload;
    const isActive = is_active === 1 || is_active === true;
    const now = new Date().toISOString();

    try {
      await query(
        `INSERT INTO products (
          id, shop_id, name, category_id, category_name, brand, buying_price_paise,
          selling_price_paise, quantity, unit, min_stock_level, is_active, created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
        ) ON CONFLICT (id) DO UPDATE SET
          name = $3, category_id = $4, category_name = $5, brand = $6, buying_price_paise = $7,
          selling_price_paise = $8, quantity = $9, unit = $10, min_stock_level = $11, is_active = $12, updated_at = $14`,
        [
          id, shopId, name, category_id, category_name, brand || null, buying_price_paise,
          selling_price_paise, quantity, unit, min_stock_level, isActive, created_at || now, updated_at || now
        ]
      );
    } catch (e) {
      const idx = memoryDb.tables.products.findIndex(p => p.id === id);
      const record = {
        id, shop_id: shopId, name, category_id, category_name, brand, buying_price_paise,
        selling_price_paise, quantity, unit, min_stock_level, is_active: isActive, created_at: created_at || now, updated_at: updated_at || now
      };
      if (idx >= 0) memoryDb.tables.products[idx] = record;
      else memoryDb.tables.products.push(record);
    }
  }

  private static async insertStockMovement(shopId: string, payload: any) {
    const {
      id, product_id, product_name, previous_quantity, quantity_change, new_quantity,
      purchase_price_paise, movement_type, reason, supplier, notes, created_at
    } = payload;
    const now = new Date().toISOString();

    try {
      // Check if stock movement already processed (Idempotency)
      const existing = await query('SELECT id FROM stock_movements WHERE id = $1', [id]);
      if (existing.rows.length > 0) return;

      await query(
        `INSERT INTO stock_movements (
          id, shop_id, product_id, product_name, previous_quantity, quantity_change, new_quantity,
          purchase_price_paise, movement_type, reason, supplier, notes, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
        [
          id, shopId, product_id, product_name, previous_quantity, quantity_change, new_quantity,
          purchase_price_paise || 0, movement_type, reason || null, supplier || null, notes || null, created_at || now
        ]
      );

      // Update product quantity safely
      await query(
        'UPDATE products SET quantity = quantity + $1, updated_at = $2 WHERE id = $3 AND shop_id = $4',
        [quantity_change, now, product_id, shopId]
      );
    } catch (e) {
      const existing = memoryDb.tables.stock_movements.find(sm => sm.id === id);
      if (!existing) {
        memoryDb.tables.stock_movements.push({
          id, shop_id: shopId, product_id, product_name, previous_quantity, quantity_change, new_quantity,
          purchase_price_paise: purchase_price_paise || 0, movement_type, reason, supplier, notes, created_at: created_at || now
        });
        const p = memoryDb.tables.products.find(prod => prod.id === product_id);
        if (p) {
          p.quantity = (Number(p.quantity) || 0) + Number(quantity_change);
          p.updated_at = now;
        }
      }
    }
  }

  private static async upsertCustomer(shopId: string, payload: any) {
    const { id, name, phone, address, is_deleted, created_at, updated_at } = payload;
    const isDeleted = is_deleted === 1 || is_deleted === true;
    const now = new Date().toISOString();

    try {
      await query(
        `INSERT INTO customers (id, shop_id, name, phone, address, is_deleted, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (id) DO UPDATE SET name = $3, phone = $4, address = $5, is_deleted = $6, updated_at = $8`,
        [id, shopId, name, phone, address || null, isDeleted, created_at || now, updated_at || now]
      );
    } catch (e) {
      const idx = memoryDb.tables.customers.findIndex(c => c.id === id);
      const record = { id, shop_id: shopId, name, phone, address, is_deleted: isDeleted, created_at: created_at || now, updated_at: updated_at || now };
      if (idx >= 0) memoryDb.tables.customers[idx] = record;
      else memoryDb.tables.customers.push(record);
    }
  }

  private static async insertBill(shopId: string, payload: any) {
    const {
      id, bill_number, customer_id, customer_name_snapshot, customer_phone_snapshot,
      subtotal_paise, total_amount_paise, amount_received_paise, change_amount_paise,
      pending_amount_paise, payment_status, is_cancelled, created_at, updated_at, items
    } = payload;
    const isCancelled = is_cancelled === 1 || is_cancelled === true;
    const now = new Date().toISOString();

    try {
      const existing = await query('SELECT id FROM bills WHERE id = $1', [id]);
      if (existing.rows.length === 0) {
        await query(
          `INSERT INTO bills (
            id, shop_id, bill_number, customer_id, customer_name_snapshot, customer_phone_snapshot,
            subtotal_paise, total_amount_paise, amount_received_paise, change_amount_paise,
            pending_amount_paise, payment_status, is_cancelled, created_at, updated_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`,
          [
            id, shopId, bill_number, customer_id || null, customer_name_snapshot || null, customer_phone_snapshot || null,
            subtotal_paise, total_amount_paise, amount_received_paise, change_amount_paise,
            pending_amount_paise, payment_status, isCancelled, created_at || now, updated_at || now
          ]
        );

        if (Array.isArray(items)) {
          for (const item of items) {
            const itemId = item.id || generateUuid();
            await query(
              `INSERT INTO bill_items (
                id, shop_id, bill_id, product_id, product_name_snapshot, quantity, unit,
                selling_price_paise, buying_price_paise, line_total_paise, profit_paise
              ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
              [
                itemId, shopId, id, item.product_id, item.product_name_snapshot || item.product_name || '', item.quantity,
                item.unit || '', item.selling_price_paise, item.buying_price_paise, item.line_total_paise, item.profit_paise
              ]
            );
          }
        }
      }
    } catch (e) {
      const existing = memoryDb.tables.bills.find(b => b.id === id);
      if (!existing) {
        memoryDb.tables.bills.push({
          id, shop_id: shopId, bill_number, customer_id, customer_name_snapshot, customer_phone_snapshot,
          subtotal_paise, total_amount_paise, amount_received_paise, change_amount_paise,
          pending_amount_paise, payment_status, is_cancelled: isCancelled, created_at: created_at || now, updated_at: updated_at || now
        });
        if (Array.isArray(items)) {
          items.forEach(item => {
            memoryDb.tables.bill_items.push({
              id: item.id || generateUuid(), shop_id: shopId, bill_id: id, product_id: item.product_id,
              product_name_snapshot: item.product_name_snapshot || item.product_name || '', quantity: item.quantity,
              unit: item.unit, selling_price_paise: item.selling_price_paise, buying_price_paise: item.buying_price_paise,
              line_total_paise: item.line_total_paise, profit_paise: item.profit_paise
            });
          });
        }
      }
    }
  }

  private static async insertPayment(shopId: string, payload: any) {
    const { id, customer_id, bill_id, amount_paise, payment_method, notes, created_at } = payload;
    const now = new Date().toISOString();

    try {
      const existing = await query('SELECT id FROM payments WHERE id = $1', [id]);
      if (existing.rows.length === 0) {
        await query(
          `INSERT INTO payments (id, shop_id, customer_id, bill_id, amount_paise, payment_method, notes, created_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [id, shopId, customer_id || null, bill_id || null, amount_paise, payment_method, notes || null, created_at || now]
        );
      }
    } catch (e) {
      const existing = memoryDb.tables.payments.find(p => p.id === id);
      if (!existing) {
        memoryDb.tables.payments.push({ id, shop_id: shopId, customer_id, bill_id, amount_paise, payment_method, notes, created_at: created_at || now });
      }
    }
  }

  private static async insertReturn(shopId: string, payload: any) {
    const {
      id, bill_id, customer_id, product_id, product_name_snapshot, quantity, unit,
      refund_amount_paise, reason, status, stock_action, created_at
    } = payload;
    const now = new Date().toISOString();

    try {
      const existing = await query('SELECT id FROM returns WHERE id = $1', [id]);
      if (existing.rows.length === 0) {
        await query(
          `INSERT INTO returns (
            id, shop_id, bill_id, customer_id, product_id, product_name_snapshot, quantity, unit,
            refund_amount_paise, reason, status, stock_action, created_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
          [
            id, shopId, bill_id, customer_id || null, product_id, product_name_snapshot, quantity, unit,
            refund_amount_paise, reason, status, stock_action, created_at || now
          ]
        );

        if (stock_action === 'RESTOCK' || stock_action === 'restock') {
          await query(
            'UPDATE products SET quantity = quantity + $1, updated_at = $2 WHERE id = $3 AND shop_id = $4',
            [quantity, now, product_id, shopId]
          );
        }
      }
    } catch (e) {
      const existing = memoryDb.tables.returns.find(r => r.id === id);
      if (!existing) {
        memoryDb.tables.returns.push({
          id, shop_id: shopId, bill_id, customer_id, product_id, product_name_snapshot, quantity, unit,
          refund_amount_paise, reason, status, stock_action, created_at: created_at || now
        });
        if (stock_action === 'RESTOCK' || stock_action === 'restock') {
          const p = memoryDb.tables.products.find(prod => prod.id === product_id);
          if (p) p.quantity = (Number(p.quantity) || 0) + Number(quantity);
        }
      }
    }
  }

  private static async logAudit(shopId: string, userId: string, tableName: string, recordId: string, action: string) {
    const id = generateUuid();
    try {
      await query(
        'INSERT INTO sync_audit (id, shop_id, user_id, table_name, record_id, action) VALUES ($1, $2, $3, $4, $5, $6)',
        [id, shopId, userId, tableName, recordId, action]
      );
    } catch (e) {
      memoryDb.tables.sync_audit.push({ id, shop_id: shopId, user_id: userId, table_name: tableName, record_id: recordId, action, processed_at: new Date().toISOString() });
    }
  }

  static async pullChanges(shopId: string, lastSyncedAt?: string) {
    const serverTimestamp = new Date().toISOString();

    let categories: any[] = [];
    let products: any[] = [];
    let stockMovements: any[] = [];
    let customers: any[] = [];
    let bills: any[] = [];
    let billItems: any[] = [];
    let payments: any[] = [];
    let returns: any[] = [];

    try {
      const catRes = lastSyncedAt
        ? await query('SELECT * FROM categories WHERE shop_id = $1 AND updated_at > $2', [shopId, lastSyncedAt])
        : await query('SELECT * FROM categories WHERE shop_id = $1', [shopId]);
      categories = catRes.rows;

      const prodRes = lastSyncedAt
        ? await query('SELECT * FROM products WHERE shop_id = $1 AND updated_at > $2', [shopId, lastSyncedAt])
        : await query('SELECT * FROM products WHERE shop_id = $1', [shopId]);
      products = prodRes.rows;

      const smRes = lastSyncedAt
        ? await query('SELECT * FROM stock_movements WHERE shop_id = $1 AND created_at > $2', [shopId, lastSyncedAt])
        : await query('SELECT * FROM stock_movements WHERE shop_id = $1', [shopId]);
      stockMovements = smRes.rows;

      const custRes = lastSyncedAt
        ? await query('SELECT * FROM customers WHERE shop_id = $1 AND updated_at > $2', [shopId, lastSyncedAt])
        : await query('SELECT * FROM customers WHERE shop_id = $1', [shopId]);
      customers = custRes.rows;

      const billRes = lastSyncedAt
        ? await query('SELECT * FROM bills WHERE shop_id = $1 AND updated_at > $2', [shopId, lastSyncedAt])
        : await query('SELECT * FROM bills WHERE shop_id = $1', [shopId]);
      bills = billRes.rows;

      const biRes = await query('SELECT * FROM bill_items WHERE shop_id = $1', [shopId]);
      billItems = biRes.rows;

      const payRes = lastSyncedAt
        ? await query('SELECT * FROM payments WHERE shop_id = $1 AND created_at > $2', [shopId, lastSyncedAt])
        : await query('SELECT * FROM payments WHERE shop_id = $1', [shopId]);
      payments = payRes.rows;

      const retRes = lastSyncedAt
        ? await query('SELECT * FROM returns WHERE shop_id = $1 AND created_at > $2', [shopId, lastSyncedAt])
        : await query('SELECT * FROM returns WHERE shop_id = $1', [shopId]);
      returns = retRes.rows;
    } catch (e) {
      categories = memoryDb.tables.categories.filter(c => c.shop_id === shopId);
      products = memoryDb.tables.products.filter(p => p.shop_id === shopId);
      stockMovements = memoryDb.tables.stock_movements.filter(sm => sm.shop_id === shopId);
      customers = memoryDb.tables.customers.filter(c => c.shop_id === shopId);
      bills = memoryDb.tables.bills.filter(b => b.shop_id === shopId);
      billItems = memoryDb.tables.bill_items.filter(bi => bi.shop_id === shopId);
      payments = memoryDb.tables.payments.filter(p => p.shop_id === shopId);
      returns = memoryDb.tables.returns.filter(r => r.shop_id === shopId);
    }

    return {
      serverTimestamp,
      data: {
        categories,
        products,
        stockMovements,
        customers,
        bills,
        billItems,
        payments,
        returns
      }
    };
  }
}
