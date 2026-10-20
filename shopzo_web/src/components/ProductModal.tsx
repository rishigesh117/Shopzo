import React, { useState, useMemo } from 'react';
import { X, Plus, Check, Trash2, Layers, Sparkles } from 'lucide-react';
import { Product, Category, PriceTier } from '../types';
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

interface FormTier {
  id: string;
  name: string;
  quantity: string;
  unit: string;
  price: string;
  buyingPrice: string;
}

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
  const [unit, setUnit] = useState(product?.unit || 'KG');
  const [minStockLevel, setMinStockLevel] = useState(product ? product.minStockLevel.toString() : '5');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // --- Tier Pricing State ---
  const initialTiers: FormTier[] = useMemo(() => {
    if (product?.priceTiers && product.priceTiers.length > 0) {
      return product.priceTiers.map((t, idx) => ({
        id: t.id || `tier-${idx}-${Date.now()}`,
        name: t.name || `${t.quantity} ${t.unit}`,
        quantity: t.quantity.toString(),
        unit: t.unit || 'GRAM',
        price: (t.pricePaise / 100).toString(),
        buyingPrice: t.buyingPricePaise ? (t.buyingPricePaise / 100).toString() : '',
      }));
    }
    return [];
  }, [product]);

  const [hasTiers, setHasTiers] = useState(initialTiers.length > 0);
  const [tiers, setTiers] = useState<FormTier[]>(initialTiers);

  // Custom categories added by merchant
  const [extraCategories, setExtraCategories] = useState<Category[]>([]);
  const [isAddingCategory, setIsAddingCategory] = useState(false);
  const [newCatName, setNewCatName] = useState('');

  // Merge default categories, server categories, and custom added categories
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

  // Quick preset suggestions based on current base unit
  const presetSuggestions = useMemo(() => {
    const upper = unit.toUpperCase();
    if (upper === 'KG' || upper === 'GRAM') {
      return [
        { label: '100 Gram', name: '100g', quantity: '100', unit: 'GRAM' },
        { label: '250 Gram', name: '250g', quantity: '250', unit: 'GRAM' },
        { label: '500 Gram', name: '500g', quantity: '500', unit: 'GRAM' },
        { label: '1 Kg', name: '1 Kg', quantity: '1', unit: 'KG' },
        { label: '2 Kg', name: '2 Kg', quantity: '2', unit: 'KG' },
        { label: '5 Kg', name: '5 Kg', quantity: '5', unit: 'KG' },
      ];
    }
    if (upper === 'LITRE' || upper === 'ML') {
      return [
        { label: '100 Ml', name: '100ml', quantity: '100', unit: 'ML' },
        { label: '250 Ml', name: '250ml', quantity: '250', unit: 'ML' },
        { label: '500 Ml', name: '500ml', quantity: '500', unit: 'ML' },
        { label: '1 Litre', name: '1 L', quantity: '1', unit: 'LITRE' },
        { label: '5 Litre', name: '5 L', quantity: '5', unit: 'LITRE' },
      ];
    }
    return [
      { label: '1 Pc', name: '1 Pc', quantity: '1', unit: 'PIECE' },
      { label: '6 Pcs (Half Dozen)', name: 'Half Dozen', quantity: '6', unit: 'PIECE' },
      { label: '12 Pcs (Dozen)', name: '1 Dozen', quantity: '12', unit: 'PIECE' },
      { label: '10 Pcs (Pack)', name: 'Pack of 10', quantity: '10', unit: 'PIECE' },
      { label: '50 Pcs (Box)', name: 'Box of 50', quantity: '50', unit: 'PIECE' },
    ];
  }, [unit]);

  const calculateDefaultTierPrice = (tierQtyStr: string, tierUnitStr: string): string => {
    const sp = parseFloat(sellingPrice) || 0;
    if (sp <= 0) return '';
    const tQty = parseFloat(tierQtyStr) || 1;
    const baseU = unit.toUpperCase();
    const tierU = tierUnitStr.toUpperCase();

    if (baseU === 'KG' && tierU === 'GRAM') {
      return Math.max(1, Math.round((sp / 1000) * tQty)).toString();
    }
    if (baseU === 'LITRE' && tierU === 'ML') {
      return Math.max(1, Math.round((sp / 1000) * tQty)).toString();
    }
    if (baseU === tierU) {
      return Math.max(1, Math.round(sp * tQty)).toString();
    }
    return Math.max(1, Math.round(sp)).toString();
  };

  const addPresetTier = (preset: { name: string; quantity: string; unit: string }) => {
    setHasTiers(true);
    // Don't add duplicate if name already exists
    if (tiers.some((t) => t.name.toLowerCase() === preset.name.toLowerCase())) {
      return;
    }
    const estimatedPrice = calculateDefaultTierPrice(preset.quantity, preset.unit);
    setTiers((prev) => [
      ...prev,
      {
        id: `tier-${Date.now()}-${Math.random()}`,
        name: preset.name,
        quantity: preset.quantity,
        unit: preset.unit,
        price: estimatedPrice,
        buyingPrice: '',
      },
    ]);
  };

  const addCustomTier = () => {
    setHasTiers(true);
    const defaultUnit = unit.toUpperCase() === 'KG' ? 'GRAM' : unit.toUpperCase() === 'LITRE' ? 'ML' : 'PIECE';
    const defaultQty = defaultUnit === 'GRAM' ? '100' : defaultUnit === 'ML' ? '100' : '1';
    const estimatedPrice = calculateDefaultTierPrice(defaultQty, defaultUnit);
    setTiers((prev) => [
      ...prev,
      {
        id: `tier-${Date.now()}-${Math.random()}`,
        name: `${defaultQty} ${defaultUnit}`,
        quantity: defaultQty,
        unit: defaultUnit,
        price: estimatedPrice,
        buyingPrice: '',
      },
    ]);
  };

  const updateTier = (id: string, field: keyof FormTier, val: string) => {
    setTiers((prev) => prev.map((t) => (t.id === id ? { ...t, [field]: val } : t)));
  };

  const removeTier = (id: string) => {
    setTiers((prev) => prev.filter((t) => t.id !== id));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Product name is required');
      return;
    }
    const sp = parseFloat(sellingPrice);
    if (isNaN(sp) || sp < 0) {
      setError('Please enter a valid base selling price');
      return;
    }

    const bp = parseFloat(buyingPrice) || 0;
    const qty = parseFloat(quantity) || 0;
    const minStock = parseFloat(minStockLevel) || 0;

    // Validate tiers if enabled
    let validatedTiers: PriceTier[] = [];
    if (hasTiers && tiers.length > 0) {
      for (const t of tiers) {
        if (!t.price.trim() || isNaN(parseFloat(t.price)) || parseFloat(t.price) < 0) {
          setError(`Please enter a valid price for tier "${t.name || 'Tier'}"`);
          return;
        }
        if (!t.quantity.trim() || isNaN(parseFloat(t.quantity)) || parseFloat(t.quantity) <= 0) {
          setError(`Please enter a valid quantity for tier "${t.name || 'Tier'}"`);
          return;
        }
        validatedTiers.push({
          id: t.id,
          name: t.name.trim() || `${t.quantity} ${t.unit}`,
          quantity: parseFloat(t.quantity),
          unit: t.unit.toUpperCase(),
          pricePaise: parseMoneyToPaise(parseFloat(t.price)),
          buyingPricePaise: t.buyingPrice.trim() ? parseMoneyToPaise(parseFloat(t.buyingPrice)) : undefined,
        });
      }
    }

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
        priceTiers: hasTiers ? validatedTiers : [],
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
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '640px', maxHeight: '90vh', display: 'flex', flexDirection: 'column' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '18px 24px', borderBottom: '1px solid var(--surface-border)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div style={{ width: '32px', height: '32px', borderRadius: 'var(--radius-md)', background: 'var(--primary-glow)', color: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Layers size={18} />
            </div>
            <div>
              <h3 style={{ fontSize: '1.2rem', fontWeight: 700, margin: 0 }}>
                {product ? 'Edit Product' : 'Add New Product'}
              </h3>
              <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                Configure base pricing, stock units, and custom quantity tier pricing
              </span>
            </div>
          </div>
          <button onClick={onClose} className="btn btn-outline btn-sm btn-icon">
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ padding: '24px', overflowY: 'auto', flex: 1 }}>
          {error && (
            <div style={{ padding: '10px 14px', background: 'var(--danger-light)', color: 'var(--danger-dark)', borderRadius: 'var(--radius-md)', marginBottom: '16px', fontSize: '0.85rem' }}>
              {error}
            </div>
          )}

          {/* Product Name */}
          <div className="form-group">
            <label className="form-label">Product Name *</label>
            <input
              type="text"
              className="form-input"
              placeholder="e.g. Basmati Rice, Toor Dal, Sugar, Chilli Powder"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>

          {/* Brand & Category */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div className="form-group">
              <label className="form-label">Brand (Optional)</label>
              <input
                type="text"
                className="form-input"
                placeholder="e.g. India Gate, Aashirvaad"
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

          {/* Pricing & Units Row */}
          <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr 1fr', gap: '16px' }}>
            <div className="form-group">
              <label className="form-label">Base Selling Price (₹) *</label>
              <input
                type="number"
                step="0.01"
                min="0"
                className="form-input"
                placeholder="e.g. 140.00"
                value={sellingPrice}
                onChange={(e) => setSellingPrice(e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Primary Unit</label>
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
              <label className="form-label">Cost Price (₹) (Opt.)</label>
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

          {/* Stock & Alert Row */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div className="form-group">
              <label className="form-label">Total Stock Quantity (Optional)</label>
              <input
                type="number"
                step="0.01"
                min="0"
                className="form-input"
                placeholder="e.g. 50"
                value={quantity}
                onChange={(e) => setQuantity(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Low Stock Alert Level</label>
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

          {/* ======================================================== */}
          {/* TIER PRODUCT / MULTI-UNIT PRICING SECTION               */}
          {/* ======================================================== */}
          <div
            style={{
              marginTop: '20px',
              border: '1px solid var(--surface-border)',
              borderRadius: 'var(--radius-lg)',
              background: 'var(--surface-raised)',
              padding: '16px',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Sparkles size={16} color="var(--primary)" />
                <div>
                  <div style={{ fontWeight: 700, fontSize: '0.92rem', color: 'var(--text-main)' }}>
                    Tier Product / Multi-Unit Slabs (Kg & Gram Pricing)
                  </div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                    Sell the same product in multiple units (e.g. 1 Kg = ₹140, 100g = ₹15, 250g = ₹38)
                  </div>
                </div>
              </div>

              <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '0.82rem', fontWeight: 600 }}>
                <input
                  type="checkbox"
                  checked={hasTiers}
                  onChange={(e) => {
                    const checked = e.target.checked;
                    setHasTiers(checked);
                    if (checked && tiers.length === 0) {
                      // Add initial tier based on base unit
                      if (unit.toUpperCase() === 'KG') {
                        setTiers([
                          { id: `t1-${Date.now()}`, name: '100g', quantity: '100', unit: 'GRAM', price: '15', buyingPrice: '' },
                          { id: `t2-${Date.now()}`, name: '250g', quantity: '250', unit: 'GRAM', price: '38', buyingPrice: '' },
                          { id: `t3-${Date.now()}`, name: '500g', quantity: '500', unit: 'GRAM', price: '72', buyingPrice: '' },
                          { id: `t4-${Date.now()}`, name: '1 Kg', quantity: '1', unit: 'KG', price: sellingPrice || '140', buyingPrice: '' },
                        ]);
                      } else {
                        addCustomTier();
                      }
                    }
                  }}
                  style={{ width: '16px', height: '16px', accentColor: 'var(--primary)' }}
                />
                <span>Enable Tiers</span>
              </label>
            </div>

            {hasTiers && (
              <div style={{ marginTop: '14px' }}>
                {/* Quick Presets */}
                <div style={{ marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '6px', flexWrap: 'wrap' }}>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>
                    Quick Add Presets:
                  </span>
                  {presetSuggestions.map((p) => {
                    const alreadyExists = tiers.some((t) => t.name.toLowerCase() === p.name.toLowerCase());
                    return (
                      <button
                        key={p.name}
                        type="button"
                        disabled={alreadyExists}
                        onClick={() => addPresetTier(p)}
                        style={{
                          background: alreadyExists ? 'var(--surface)' : 'rgba(99, 102, 241, 0.08)',
                          border: `1px solid ${alreadyExists ? 'var(--surface-border)' : 'rgba(99, 102, 241, 0.25)'}`,
                          color: alreadyExists ? 'var(--text-muted)' : 'var(--primary)',
                          borderRadius: 'var(--radius-sm)',
                          padding: '3px 8px',
                          fontSize: '0.75rem',
                          fontWeight: 600,
                          cursor: alreadyExists ? 'default' : 'pointer',
                        }}
                      >
                        + {p.name}
                      </button>
                    );
                  })}
                </div>

                {/* Tiers List */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  {tiers.map((t) => (
                    <div
                      key={t.id}
                      style={{
                        display: 'grid',
                        gridTemplateColumns: '1.2fr 1fr 1fr 1.1fr 36px',
                        gap: '8px',
                        alignItems: 'center',
                        background: 'var(--surface)',
                        padding: '8px 10px',
                        borderRadius: 'var(--radius-md)',
                        border: '1px solid var(--surface-border)',
                      }}
                    >
                      {/* Tier Name / Label */}
                      <div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', fontWeight: 600, display: 'block', marginBottom: '2px' }}>
                          Label
                        </span>
                        <input
                          type="text"
                          className="form-input"
                          style={{ padding: '6px 8px', fontSize: '0.82rem' }}
                          placeholder="e.g. 100g, 1 Kg"
                          value={t.name}
                          onChange={(e) => updateTier(t.id, 'name', e.target.value)}
                        />
                      </div>

                      {/* Quantity & Unit */}
                      <div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', fontWeight: 600, display: 'block', marginBottom: '2px' }}>
                          Quantity
                        </span>
                        <input
                          type="number"
                          step="0.01"
                          min="0.01"
                          className="form-input"
                          style={{ padding: '6px 8px', fontSize: '0.82rem' }}
                          placeholder="e.g. 100"
                          value={t.quantity}
                          onChange={(e) => updateTier(t.id, 'quantity', e.target.value)}
                        />
                      </div>

                      <div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', fontWeight: 600, display: 'block', marginBottom: '2px' }}>
                          Unit
                        </span>
                        <select
                          className="form-select"
                          style={{ padding: '6px 8px', fontSize: '0.82rem' }}
                          value={t.unit.toUpperCase()}
                          onChange={(e) => updateTier(t.id, 'unit', e.target.value)}
                        >
                          {PRODUCT_UNITS.map((u) => (
                            <option key={u.value} value={u.value}>
                              {u.label}
                            </option>
                          ))}
                        </select>
                      </div>

                      {/* Selling Price */}
                      <div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--primary)', fontWeight: 700, display: 'block', marginBottom: '2px' }}>
                          Price (₹) *
                        </span>
                        <input
                          type="number"
                          step="0.01"
                          min="0"
                          className="form-input"
                          style={{ padding: '6px 8px', fontSize: '0.82rem', borderColor: 'var(--primary)', fontWeight: 700 }}
                          placeholder="e.g. 15.00"
                          value={t.price}
                          onChange={(e) => updateTier(t.id, 'price', e.target.value)}
                          required
                        />
                      </div>

                      {/* Delete Action */}
                      <button
                        type="button"
                        onClick={() => removeTier(t.id)}
                        className="btn btn-outline btn-sm btn-icon"
                        style={{ color: 'var(--danger)', height: '32px', width: '32px', marginTop: '14px' }}
                        title="Delete Tier"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  ))}
                </div>

                {/* Add Tier Action */}
                <div style={{ marginTop: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <button
                    type="button"
                    onClick={addCustomTier}
                    className="btn btn-outline btn-sm"
                    style={{ fontSize: '0.8rem', padding: '6px 12px' }}
                  >
                    <Plus size={14} /> Add Custom Tier Slab
                  </button>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                    {tiers.length} tier{tiers.length === 1 ? '' : 's'} configured
                  </span>
                </div>
              </div>
            )}
          </div>

          {/* Error Banner in Footer */}
          {error && (
            <div style={{ padding: '8px 12px', background: 'var(--danger-light)', color: 'var(--danger-dark)', borderRadius: 'var(--radius-md)', marginTop: '16px', fontSize: '0.85rem', fontWeight: 600 }}>
              ⚠️ {error}
            </div>
          )}

          {/* Modal Actions */}
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '16px' }}>
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
