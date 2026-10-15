import React, { useState } from 'react';
import { X } from 'lucide-react';
import { Product, Category } from '../types';
import { parseMoneyToPaise } from '../utils/format';

interface ProductModalProps {
  product?: Product | null;
  categories: Category[];
  onSave: (data: Omit<Product, 'id' | 'shopId' | 'createdAt' | 'updatedAt'>) => Promise<void>;
  onClose: () => void;
}

export const ProductModal: React.FC<ProductModalProps> = ({ product, categories, onSave, onClose }) => {
  const [name, setName] = useState(product?.name || '');
  const [brand, setBrand] = useState(product?.brand || '');
  const [categoryId, setCategoryId] = useState(product?.categoryId || (categories[0]?.id || ''));
  const [sellingPrice, setSellingPrice] = useState(product ? (product.sellingPricePaise / 100).toString() : '');
  const [buyingPrice, setBuyingPrice] = useState(product ? (product.buyingPricePaise / 100).toString() : '');
  const [quantity, setQuantity] = useState(product ? product.quantity.toString() : '10');
  const [unit, setUnit] = useState(product?.unit || 'PCS');
  const [minStockLevel, setMinStockLevel] = useState(product ? product.minStockLevel.toString() : '5');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

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
        categoryId: categoryId || 'general',
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
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
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
              placeholder="e.g. Basmati Rice 1kg"
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
                placeholder="e.g. India Gate"
                value={brand}
                onChange={(e) => setBrand(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Category</label>
              <select
                className="form-select"
                value={categoryId}
                onChange={(e) => setCategoryId(e.target.value)}
              >
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
                {categories.length === 0 && <option value="general">General</option>}
              </select>
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

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px' }}>
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
              <select className="form-select" value={unit} onChange={(e) => setUnit(e.target.value)}>
                <option value="PCS">PCS</option>
                <option value="KG">KG</option>
                <option value="LTR">LTR</option>
                <option value="PKT">PKT</option>
                <option value="BOX">BOX</option>
                <option value="DOZ">DOZ</option>
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
