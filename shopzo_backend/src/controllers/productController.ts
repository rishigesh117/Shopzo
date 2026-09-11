import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import { pool, memoryDb, useMemoryDb } from '../db';

export async function getProducts(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;

  if (useMemoryDb) {
    const list: any[] = [];
    for (const p of memoryDb.products.values()) {
      if (p.shopId === shopId && !p.deleted) {
        list.push(p);
      }
    }
    return res.json({ products: list });
  }

  try {
    const resProducts = await pool.query('SELECT * FROM products WHERE shop_id = $1 AND deleted = FALSE', [shopId]);
    return res.json({ products: resProducts.rows });
  } catch (err) {
    return res.status(500).json({ error: 'Database error fetching products' });
  }
}

export async function createProduct(req: AuthenticatedRequest, res: Response) {
  const shopId = req.shopId!;
  const { name, categoryId, brand, buyingPricePaise, sellingPricePaise, quantity, unit, minStockLevel } = req.body;

  if (!name || !categoryId) {
    return res.status(400).json({ error: 'Product name and categoryId are required' });
  }

  const productId = req.body.id || uuidv4();
  const now = Date.now();

  const product = {
    id: productId,
    shopId,
    categoryId,
    name: name.trim(),
    brand: brand ? brand.trim() : null,
    buyingPricePaise: buyingPricePaise || 0,
    sellingPricePaise: sellingPricePaise || 0,
    quantity: quantity || 0,
    unit: unit || 'PCS',
    minStockLevel: minStockLevel || 0,
    createdAt: now,
    updatedAt: now,
    deleted: false
  };

  if (useMemoryDb) {
    memoryDb.products.set(productId, product);
    return res.status(201).json({ product });
  }

  try {
    await pool.query(
      `INSERT INTO products (id, shop_id, category_id, name, brand, buying_price_paise, selling_price_paise, quantity, unit, min_stock_level, created_at, updated_at, deleted)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
      [
        productId,
        shopId,
        categoryId,
        name.trim(),
        brand ? brand.trim() : null,
        buyingPricePaise || 0,
        sellingPricePaise || 0,
        quantity || 0,
        unit || 'PCS',
        minStockLevel || 0,
        now,
        now,
        false
      ]
    );

    return res.status(201).json({ product });
  } catch (err) {
    return res.status(500).json({ error: 'Database error creating product' });
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

    return res.json({ message: 'Product updated successfully' });
  } catch (err) {
    return res.status(500).json({ error: 'Database error updating product' });
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
    return res.json({ message: 'Product deleted successfully' });
  }

  try {
    await pool.query('UPDATE products SET deleted = TRUE, updated_at = $1 WHERE id = $2 AND shop_id = $3', [now, productId, shopId]);
    return res.json({ message: 'Product deleted successfully' });
  } catch (err) {
    return res.status(500).json({ error: 'Database error deleting product' });
  }
}
