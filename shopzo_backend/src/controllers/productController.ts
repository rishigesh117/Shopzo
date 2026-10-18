import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import { pool, memoryDb, useMemoryDb } from '../db';

export async function getProducts(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;
  const clientShopId = (req.headers['x-shop-id'] as string) || shopId;

  const getFromMemory = () => {
    const list: any[] = [];
    for (const p of memoryDb.products.values()) {
      if ((p.shopId === shopId || p.shopId === clientShopId || p.shopId === 'shop-default-001') && !p.deleted) {
        list.push({ ...p, shopId: clientShopId });
      }
    }
    return list;
  };

  if (useMemoryDb) {
    return res.json({ products: getFromMemory() });
  }

  try {
    const resProducts = await pool.query(
      'SELECT * FROM products WHERE (shop_id = $1 OR shop_id = $2 OR shop_id = \'shop-default-001\') AND deleted = FALSE',
      [shopId, clientShopId]
    );
    // Map DB snake_case columns to camelCase and return
    const dbProducts = resProducts.rows.map(r => ({
      id: r.id,
      shopId: clientShopId,
      categoryId: r.category_id ?? r.categoryId,
      name: r.name,
      brand: r.brand ?? null,
      buyingPricePaise: r.buying_price_paise ?? r.buyingPricePaise ?? 0,
      sellingPricePaise: r.selling_price_paise ?? r.sellingPricePaise ?? 0,
      quantity: r.quantity ?? 0,
      unit: r.unit ?? 'PCS',
      minStockLevel: r.min_stock_level ?? r.minStockLevel ?? 0,
      createdAt: r.created_at ?? r.createdAt,
      updatedAt: r.updated_at ?? r.updatedAt,
      deleted: r.deleted ?? false
    }));
    // Merge with memory products that might not be in DB yet (e.g. serverless cold start)
    const dbIds = new Set(dbProducts.map(p => p.id));
    const memProducts = getFromMemory().filter(p => !dbIds.has(p.id));
    return res.json({ products: [...dbProducts, ...memProducts] });
  } catch (err) {
    console.warn('DB error fetching products, using memory fallback:', err);
    return res.json({ products: getFromMemory() });
  }
}

export async function createProduct(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;
  const clientShopId = (req.headers['x-shop-id'] as string) || shopId;
  const { name, categoryId, brand, buyingPricePaise, sellingPricePaise, quantity, unit, minStockLevel } = req.body;

  if (!name || !categoryId) {
    return res.status(400).json({ error: 'Product name and categoryId are required' });
  }

  const productId = req.body.id || uuidv4();
  const now = Date.now();

  // Use the canonical shopId for storage
  const storageShopId = shopId;

  const product = {
    id: productId,
    shopId: storageShopId,
    categoryId,
    name: name.trim(),
    brand: brand ? brand.trim() : null,
    buyingPricePaise: buyingPricePaise != null ? buyingPricePaise : 0,
    sellingPricePaise: sellingPricePaise != null ? sellingPricePaise : 0,
    quantity: quantity != null ? quantity : 0,
    unit: unit || 'PCS',
    minStockLevel: minStockLevel != null ? minStockLevel : 0,
    createdAt: now,
    updatedAt: now,
    deleted: false
  };

  // Always store in memory first for immediate availability in sync pull
  memoryDb.products.set(productId, product);

  if (useMemoryDb) {
    memoryDb.saveToDisk();
    // Return product with client's shopId for consistency
    return res.status(201).json({ product: { ...product, shopId: clientShopId } });
  }

  try {
    // Ensure shop exists in DB so foreign key constraint doesn't reject product insert
    try {
      await pool.query(
        `INSERT INTO shops (id, shop_code, name, owner_id, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (id) DO NOTHING`,
        [storageShopId, 'SZ-' + (storageShopId.length >= 6 ? storageShopId.slice(-6).toUpperCase() : 'STORE1'), 'Store', req.user?.userId || 'user-default', now, now]
      );
    } catch (_) {}

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
         updated_at = EXCLUDED.updated_at`,
      [
        productId,
        storageShopId,
        categoryId,
        name.trim(),
        brand ? brand.trim() : null,
        buyingPricePaise != null ? buyingPricePaise : 0,
        sellingPricePaise != null ? sellingPricePaise : 0,
        quantity != null ? quantity : 0,
        unit || 'PCS',
        minStockLevel != null ? minStockLevel : 0,
        now,
        now,
        false
      ]
    );

    memoryDb.saveToDisk();
    return res.status(201).json({ product: { ...product, shopId: clientShopId } });
  } catch (err) {
    console.warn('DB error creating product, using memory fallback:', err);
    memoryDb.saveToDisk();
    return res.status(201).json({ product: { ...product, shopId: clientShopId } });
  }
}

export async function updateProduct(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;
  const productId = req.params.productId;
  const { name, categoryId, brand, buyingPricePaise, sellingPricePaise, quantity, unit, minStockLevel } = req.body;

  const now = Date.now();

  if (useMemoryDb) {
    const existing = memoryDb.products.get(productId);
    if (!existing || existing.shopId !== shopId) {
      return res.status(404).json({ error: 'Product not found' });
    }

    const updated = {
      ...existing,
      name: name !== undefined ? name.trim() : existing.name,
      categoryId: categoryId !== undefined ? categoryId : existing.categoryId,
      brand: brand !== undefined ? brand : existing.brand,
      buyingPricePaise: buyingPricePaise !== undefined ? buyingPricePaise : existing.buyingPricePaise,
      sellingPricePaise: sellingPricePaise !== undefined ? sellingPricePaise : existing.sellingPricePaise,
      quantity: quantity !== undefined ? quantity : existing.quantity,
      unit: unit !== undefined ? unit : existing.unit,
      minStockLevel: minStockLevel !== undefined ? minStockLevel : existing.minStockLevel,
      updatedAt: now
    };
    memoryDb.products.set(productId, updated);
    memoryDb.saveToDisk();

    return res.json({ product: updated });
  }

  try {
    const checkRes = await pool.query('SELECT * FROM products WHERE id = $1 AND shop_id = $2', [productId, shopId]);
    if (checkRes.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    await pool.query(
      `UPDATE products SET
         name = COALESCE($1, name),
         category_id = COALESCE($2, category_id),
         brand = COALESCE($3, brand),
         buying_price_paise = COALESCE($4, buying_price_paise),
         selling_price_paise = COALESCE($5, selling_price_paise),
         quantity = COALESCE($6, quantity),
         unit = COALESCE($7, unit),
         min_stock_level = COALESCE($8, min_stock_level),
         updated_at = $9
       WHERE id = $10 AND shop_id = $11`,
      [name, categoryId, brand, buyingPricePaise, sellingPricePaise, quantity, unit, minStockLevel, now, productId, shopId]
    );

    const existing = memoryDb.products.get(productId) || {};
    memoryDb.products.set(productId, { ...existing, ...req.body, updatedAt: now });
    memoryDb.saveToDisk();
    return res.json({ message: 'Product updated successfully' });
  } catch (err) {
    const existing = memoryDb.products.get(productId) || { id: productId, shopId };
    const updated = { ...existing, ...req.body, updatedAt: now };
    memoryDb.products.set(productId, updated);
    memoryDb.saveToDisk();
    return res.json({ product: updated });
  }
}

export async function deleteProduct(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;
  const productId = req.params.productId;
  const now = Date.now();

  if (useMemoryDb) {
    const existing = memoryDb.products.get(productId);
    if (!existing || existing.shopId !== shopId) {
      return res.status(404).json({ error: 'Product not found' });
    }
    existing.deleted = true;
    existing.updatedAt = now;
    memoryDb.products.set(productId, existing);
    memoryDb.saveToDisk();
    return res.json({ message: 'Product deleted successfully' });
  }

  try {
    await pool.query('UPDATE products SET deleted = TRUE, updated_at = $1 WHERE id = $2 AND shop_id = $3', [now, productId, shopId]);
  } catch (err) {
    console.warn('DB error deleting product, using memory fallback');
  }

  const existing = memoryDb.products.get(productId);
  if (existing) {
    existing.deleted = true;
    existing.updatedAt = now;
    memoryDb.products.set(productId, existing);
    memoryDb.saveToDisk();
  }
  return res.json({ message: 'Product deleted successfully' });
}
