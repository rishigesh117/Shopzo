import React, { useState, useMemo } from 'react';
import {
  Plus,
  Search,
  Edit2,
  Trash2
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Product } from '../types';
import { formatMoney, getStockStatus } from '../utils/format';
import { DEFAULT_CATEGORIES, PRODUCT_UNITS } from '../components/ProductModal';

interface ProductsPageProps {
  onOpenAddProduct: () => void;
  onEditProduct: (product: Product) => void;
}

export const ProductsPage: React.FC<ProductsPageProps> = ({ onOpenAddProduct, onEditProduct }) => {
  const { products, categories, deleteProduct, updateStock } = useApp();

  const [search, setSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('ALL');

  // Restock modal state
  const [restockProduct, setRestockProduct] = useState<Product | null>(null);
  const [restockQty, setRestockQty] = useState('10');
  const [isRestocking, setIsRestocking] = useState(false);

  const allFilterCategories = useMemo(() => {
    const map = new Map<string, { id: string; name: string }>();
    DEFAULT_CATEGORIES.forEach((c) => map.set(c.id, c));
    categories.forEach((c) => map.set(c.id, c));
    return Array.from(map.values());
  }, [categories]);

  const categoryMap = useMemo(() => {
    const map = new Map<string, string>();
    DEFAULT_CATEGORIES.forEach((c) => map.set(c.id, c.name));
    categories.forEach((c) => map.set(c.id, c.name));
    return map;
  }, [categories]);

  const formatUnitDisplay = (unitStr: string) => {
    if (!unitStr) return 'Piece';
    const found = PRODUCT_UNITS.find(
      (u) => u.value.toLowerCase() === unitStr.toLowerCase() || u.label.toLowerCase() === unitStr.toLowerCase()
    );
    return found ? found.label : unitStr;
  };

  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchSearch =
        p.name.toLowerCase().includes(search.toLowerCase()) ||
        (p.brand && p.brand.toLowerCase().includes(search.toLowerCase()));
      const matchCategory = selectedCategory === 'ALL' || p.categoryId === selectedCategory;
      return matchSearch && matchCategory && !p.deleted;
    });
  }, [products, search, selectedCategory]);

  const handleRestockSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!restockProduct) return;
    const qty = parseFloat(restockQty);
    if (isNaN(qty) || qty <= 0) return;

    setIsRestocking(true);
    try {
      await updateStock(restockProduct.id, 'RESTOCK', qty, 'Inventory Restock');
      setRestockProduct(null);
    } finally {
      setIsRestocking(false);
    }
  };

  const handleDelete = async (id: string, name: string) => {
    if (confirm(`Are you sure you want to delete "${name}"?`)) {
      await deleteProduct(id);
    }
  };

  return (
    <div className="page-container">
      {/* Page Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1>Inventory & Products</h1>
          <p>Track stock levels, buying/selling prices, and catalog items.</p>
        </div>
        <button onClick={onOpenAddProduct} className="btn btn-primary">
          <Plus size={18} /> Add New Product
        </button>
      </div>

      {/* Filter Bar */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '20px', flexWrap: 'wrap' }}>
        <div style={{ position: 'relative', flex: 1, minWidth: '240px' }}>
          <Search size={18} style={{ position: 'absolute', left: '12px', top: '12px', color: 'var(--text-subtle)' }} />
          <input
            type="text"
            className="form-input"
            style={{ paddingLeft: '38px' }}
            placeholder="Search by product name or brand..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <select
          className="form-select"
          style={{ width: 'auto', minWidth: '160px' }}
          value={selectedCategory}
          onChange={(e) => setSelectedCategory(e.target.value)}
        >
          <option value="ALL">All Categories</option>
          {allFilterCategories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
      </div>

      {/* Products Table */}
      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Product Details</th>
              <th>Category</th>
              <th>Cost Price</th>
              <th>Selling Price</th>
              <th>Profit Margin</th>
              <th>Current Stock</th>
              <th>Status</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredProducts.map((p) => {
              const status = getStockStatus(p.quantity, p.minStockLevel);
              const marginPaise = p.sellingPricePaise - p.buyingPricePaise;
              const marginPct = p.buyingPricePaise > 0 ? Math.round((marginPaise / p.buyingPricePaise) * 100) : 100;

              return (
                <tr key={p.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                      <div style={{ fontWeight: 700, color: 'var(--text-main)' }}>{p.name}</div>
                      {p.priceTiers && p.priceTiers.length > 0 && (
                        <span className="badge badge-primary" style={{ fontSize: '0.68rem', padding: '1px 6px' }}>
                          {p.priceTiers.length} Tiers
                        </span>
                      )}
                    </div>
                    {p.brand && <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>{p.brand}</div>}
                    {p.priceTiers && p.priceTiers.length > 0 && (
                      <div style={{ fontSize: '0.72rem', color: 'var(--primary)', marginTop: '2px', fontWeight: 600 }}>
                        {p.priceTiers.map(t => `${t.quantity} ${t.unit}: ${formatMoney(t.pricePaise)}`).join(' • ')}
                      </div>
                    )}
                  </td>
                  <td>
                    <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                      {categoryMap.get(p.categoryId) || 'General'}
                    </span>
                  </td>
                  <td>{formatMoney(p.buyingPricePaise)}</td>
                  <td>
                    <strong style={{ color: 'var(--primary)', fontSize: '0.95rem' }}>
                      {formatMoney(p.sellingPricePaise)}
                    </strong>
                  </td>
                  <td>
                    <span style={{ color: marginPaise >= 0 ? 'var(--success)' : 'var(--danger)', fontWeight: 600, fontSize: '0.85rem' }}>
                      +{formatMoney(marginPaise)} ({marginPct}%)
                    </span>
                  </td>
                  <td>
                    <strong>{p.quantity}</strong> {formatUnitDisplay(p.unit)}
                  </td>
                  <td>
                    <span
                      className={`badge ${
                        status === 'IN_STOCK'
                          ? 'badge-success'
                          : status === 'LOW_STOCK'
                          ? 'badge-warning'
                          : 'badge-danger'
                      }`}
                    >
                      {status.replace(/_/g, ' ')}
                    </span>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '6px', justifyContent: 'flex-end' }}>
                      <button
                        onClick={() => { setRestockProduct(p); setRestockQty('10'); }}
                        className="btn btn-outline btn-sm"
                        title="Restock Inventory"
                        style={{ padding: '6px 8px' }}
                      >
                        <Plus size={14} /> Restock
                      </button>
                      <button
                        onClick={() => onEditProduct(p)}
                        className="btn btn-outline btn-sm btn-icon"
                        title="Edit Product"
                      >
                        <Edit2 size={14} />
                      </button>
                      <button
                        onClick={() => handleDelete(p.id, p.name)}
                        className="btn btn-outline btn-sm btn-icon"
                        style={{ color: 'var(--danger)' }}
                        title="Delete Product"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
            {filteredProducts.length === 0 && (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-muted)' }}>
                  No products found. Click "Add New Product" to start building your store catalog!
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Quick Restock Dialog */}
      {restockProduct && (
        <div className="modal-overlay" onClick={() => setRestockProduct(null)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '400px' }}>
            <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--surface-border)' }}>
              <h3 style={{ fontSize: '1.15rem' }}>Restock: {restockProduct.name}</h3>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                Current Stock: {restockProduct.quantity} {restockProduct.unit}
              </p>
            </div>
            <form onSubmit={handleRestockSubmit} style={{ padding: '24px' }}>
              <div className="form-group">
                <label className="form-label">Quantity to Add ({restockProduct.unit})</label>
                <input
                  type="number"
                  step="0.01"
                  min="0.01"
                  className="form-input"
                  value={restockQty}
                  onChange={(e) => setRestockQty(e.target.value)}
                  required
                  autoFocus
                />
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setRestockProduct(null)} className="btn btn-outline">
                  Cancel
                </button>
                <button type="submit" disabled={isRestocking} className="btn btn-primary">
                  {isRestocking ? 'Updating...' : 'Add Stock'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
