import React, { useState, useMemo } from 'react';
import { X, Plus, Check } from 'lucide-react';
import { Product, Category } from '../types';
import { parseMoneyToPaise } from '../utils/format';

export const PRODUCT_UNITS = [
  { value: 'PIECE', label: 'Piece' },
  { value: 'KG', label: 'Kg' },
  { value: 'GRAM', label: 'Gram' },
  { value: 'LITRE', label: 'Litre' },
  { value: 'ML', label: 'Ml' },
  { value: 'BOX', label: 'Box' },
  { value: 'PACKET', label: 'Packet' },
  { value: 'DOZEN', label: 'Dozen' },
];

export const DEFAULT_CATEGORIES: Category[] = [
  { id: 'cat-grocery', name: 'Grocery', shopId: '', createdAt: 0 },
  { id: 'cat-beverages', name: 'Beverages', shopId: '', createdAt: 0 },
  { id: 'cat-snacks', name: 'Snacks', shopId: '', createdAt: 0 },
  { id: 'cat-dairy', name: 'Dairy', shopId: '', createdAt: 0 },
  { id: 'cat-personal-care', name: 'Personal Care', shopId: '', createdAt: 0 },
  { id: 'cat-household', name: 'Household', shopId: '', createdAt: 0 },
  { id: 'cat-stationery', name: 'Stationery', shopId: '', createdAt: 0 },
  { id: 'cat-fruits-veg', name: 'Fruits & Vegetables', shopId: '', createdAt: 0 },
  { id: 'cat-cosmetics', name: 'Cosmetics', shopId: '', createdAt: 0 },
  { id: 'cat-others', name: 'Others', shopId: '', createdAt: 0 },
];

interface ProductModalProps {
  product?: Product | null;
  categories: Category[];
  onSave: (data: Omit<Product, 'id' | 'shopId' | 'createdAt' | 'updatedAt'>) => Promise<void>;
  onClose: () => void;
}

export const ProductModal: React.FC<ProductModalProps> = ({ product, categories, onSave, onClose }) => {
  const [name, setName] = useState(product?.name || '');
  const [brand, setBrand] = useState(product?.brand || '');
  const [sellingPrice, setSellingPrice] = useState(product ? (product.sellingPricePaise / 100).toString() : '');
  const [buyingPrice, setBuyingPrice] = useState(product ? (product.buyingPricePaise / 100).toString() : '');
  const [quantity, setQuantity] = useState(product ? product.quantity.toString() : '10');
  const [unit, setUnit] = useState(product?.unit || 'PIECE');
  const [minStockLevel, setMinStockLevel] = useState(product ? product.minStockLevel.toString() : '5');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Custom categories added by merchant
  const [extraCategories, setExtraCategories] = useState<Category[]>([]);
  const [isAddingCategory, setIsAddingCategory] = useState(false);
  const [newCatName, setNewCatName] = useState('');

  // Merge default mobile categories, server categories, and custom added categories
  const allCategories = useMemo(() => {
    const map = new Map<string, Category>();
    DEFAULT_CATEGORIES.forEach((c) => map.set(c.id, c));
    categories.forEach((c) => map.set(c.id, c));
    extraCategories.forEach((c) => map.set(c.id, c));
    return Array.from(map.values());
  }, [categories, extraCategories]);

  const [categoryId, setCategoryId] = useState(
    product?.categoryId || (allCategories[0]?.id || 'cat-grocery')
  );

  const handleCreateCategory = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCatName.trim()) return;
    const catId = `cat-custom-${Date.now()}`;
    const newCat: Category = {
      id: catId,
      name: newCatName.trim(),
      shopId: '',
      createdAt: Date.now(),
    };
    setExtraCategories((prev) => [...prev, newCat]);
    setCategoryId(catId);
    setNewCatName('');
    setIsAddingCategory(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Product name is required');
      return;
    }
    const sp = parseFloat(sellingPrice);
    if (isNaN(sp) || sp < 0) {
      setError('Please enter a valid selling price');
      return;
    }

    const bp = parseFloat(buyingPrice) || 0;
    const qty = parseFloat(quantity) || 0;
    const minStock = parseFloat(minStockLevel) || 0;

    setIsSubmitting(true);
    setError(null);
    try {
      await onSave({
        name: name.trim(),
        brand: brand.trim() || null,
        categoryId: categoryId || 'cat-grocery',
        sellingPricePaise: parseMoneyToPaise(sp),
        buyingPricePaise: parseMoneyToPaise(bp),
        quantity: qty,
        unit: unit.toUpperCase(),
        minStockLevel: minStock,
      });
      onClose();
    } catch (err: any) {
      setError(err.message || 'Failed to save product');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '580px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '18px 24px', borderBottom: '1px solid var(--surface-border)' }}>
          <h3 style={{ fontSize: '1.2rem', fontWeight: 700 }}>
            {product ? 'Edit Product' : 'Add New Product'}
          </h3>
          <button onClick={onClose} className="btn btn-outline btn-sm btn-icon">
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ padding: '24px' }}>
          {error && (
            <div style={{ padding: '10px 14px', background: 'var(--danger-light)', color: 'var(--danger-dark)', borderRadius: 'var(--radius-md)', marginBottom: '16px', fontSize: '0.85rem' }}>
              {error}
            </div>
          )}

          <div className="form-group">
            <label className="form-label">Product Name *</label>
            <input
              type="text"
              className="form-input"
              placeholder="e.g. Basmati Rice 1kg or biscuit"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div className="form-group">
              <label className="form-label">Brand (Optional)</label>
              <input
                type="text"
                className="form-input"
                placeholder="e.g. Parle, India Gate"
                value={brand}
                onChange={(e) => setBrand(e.target.value)}
              />
            </div>

            <div className="form-group">
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '6px' }}>
                <label className="form-label" style={{ marginBottom: 0 }}>Category *</label>
                <button
                  type="button"
                  onClick={() => setIsAddingCategory(!isAddingCategory)}
                  style={{
                    background: 'none',
                    border: 'none',
                    color: 'var(--primary)',
                    fontSize: '0.78rem',
                    fontWeight: 600,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                    padding: 0
                  }}
                >
                  <Plus size={13} /> {isAddingCategory ? 'Select List' : 'Add New'}
                </button>
              </div>

              {isAddingCategory ? (
                <div style={{ display: 'flex', gap: '6px' }}>
                  <input
                    type="text"
                    className="form-input"
                    placeholder="New category..."
                    value={newCatName}
                    onChange={(e) => setNewCatName(e.target.value)}
                    autoFocus
                    style={{ flex: 1 }}
                  />
                  <button
                    type="button"
                    onClick={handleCreateCategory}
                    className="btn btn-primary btn-sm"
                    style={{ padding: '6px 10px' }}
                    title="Add Category"
                  >
                    <Check size={16} />
                  </button>
                </div>
              ) : (
                <select
                  className="form-select"
                  value={categoryId}
                  onChange={(e) => {
                    if (e.target.value === '__NEW__') {
                      setIsAddingCategory(true);
                    } else {
                      setCategoryId(e.target.value);
                    }
                  }}
                >
                  {allCategories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                  <option value="__NEW__">+ Add New Category...</option>
                </select>
              )}
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div className="form-group">
              <label className="form-label">Selling Price (₹) *</label>
              <input
                type="number"
                step="0.01"
                min="0"
                className="form-input"
                placeholder="0.00"
                value={sellingPrice}
                onChange={(e) => setSellingPrice(e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Buying / Cost Price (₹)</label>
              <input
                type="number"
                step="0.01"
                min="0"
                className="form-input"
                placeholder="0.00"
                value={buyingPrice}
                onChange={(e) => setBuyingPrice(e.target.value)}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.2fr 1fr', gap: '16px' }}>
            <div className="form-group">
              <label className="form-label">Stock Quantity</label>
              <input
                type="number"
                step="0.01"
                min="0"
                className="form-input"
                value={quantity}
                onChange={(e) => setQuantity(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Unit</label>
              <select
                className="form-select"
                value={unit.toUpperCase()}
                onChange={(e) => setUnit(e.target.value)}
              >
                {PRODUCT_UNITS.map((u) => (
                  <option key={u.value} value={u.value}>
                    {u.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Low Stock Alert</label>
              <input
                type="number"
                step="0.01"
                min="0"
                className="form-input"
                value={minStockLevel}
                onChange={(e) => setMinStockLevel(e.target.value)}
              />
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '20px' }}>
            <button type="button" onClick={onClose} className="btn btn-outline">
              Cancel
            </button>
            <button type="submit" disabled={isSubmitting} className="btn btn-primary">
              {isSubmitting ? 'Saving...' : product ? 'Update Product' : 'Add Product'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

