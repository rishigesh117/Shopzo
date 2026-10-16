import React, { useState, useMemo } from 'react';
import {
  Search,
  ShoppingCart,
  Trash2,
  Plus,
  Minus,
  UserPlus,
  Printer
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Product, CartItem, Bill } from '../types';
import { formatMoney } from '../utils/format';

interface BillingPageProps {
  onOpenAddCustomer: () => void;
  onBillGenerated: (bill: Bill) => void;
}

export const BillingPage: React.FC<BillingPageProps> = ({ onOpenAddCustomer, onBillGenerated }) => {
  const { products, categories, customers, createBill } = useApp();

  const [search, setSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');
  const [cart, setCart] = useState<CartItem[]>([]);

  // Customer selection
  const [selectedCustomerId, setSelectedCustomerId] = useState<string>('');
  const [walkInName, setWalkInName] = useState<string>('Walk-in Customer');
  const [walkInMobile, setWalkInMobile] = useState<string>('');

  // Payment configuration
  const [paymentMethod, setPaymentMethod] = useState<'CASH' | 'UPI' | 'CARD' | 'CREDIT'>('CASH');
  const [customPaidAmount, setCustomPaidAmount] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Filter products
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchSearch =
        p.name.toLowerCase().includes(search.toLowerCase()) ||
        (p.brand && p.brand.toLowerCase().includes(search.toLowerCase()));
      const matchCategory = selectedCategory === 'ALL' || p.categoryId === selectedCategory;
      return matchSearch && matchCategory && !p.deleted;
    });
  }, [products, search, selectedCategory]);

  // Cart operations
  const addToCart = (product: Product) => {
    setCart((prev) => {
      const existing = prev.find((item) => item.product.id === product.id);
      if (existing) {
        if (existing.quantity >= product.quantity) {
          alert(`Cannot add more than available stock (${product.quantity} ${product.unit})`);
          return prev;
        }
        return prev.map((item) =>
          item.product.id === product.id
            ? {
                ...item,
                quantity: item.quantity + 1,
                subtotalPaise: Math.round((item.quantity + 1) * item.unitPricePaise),
              }
            : item
        );
      } else {
        if (product.quantity <= 0) {
          alert('This product is out of stock!');
          return prev;
        }
        return [
          ...prev,
          {
            product,
            quantity: 1,
            unitPricePaise: product.sellingPricePaise,
            subtotalPaise: product.sellingPricePaise,
          },
        ];
      }
    });
  };

  const updateQuantity = (productId: string, delta: number) => {
    setCart((prev) =>
      prev
        .map((item) => {
          if (item.product.id === productId) {
            const newQty = item.quantity + delta;
            if (newQty <= 0) return null;
            if (newQty > item.product.quantity) {
              alert(`Maximum available stock is ${item.product.quantity} ${item.product.unit}`);
              return item;
            }
            return {
              ...item,
              quantity: newQty,
              subtotalPaise: Math.round(newQty * item.unitPricePaise),
            };
          }
          return item;
        })
        .filter(Boolean) as CartItem[]
    );
  };

  const removeFromCart = (productId: string) => {
    setCart((prev) => prev.filter((i) => i.product.id !== productId));
  };

  const clearCart = () => {
    setCart([]);
    setCustomPaidAmount('');
  };

  // Calculations
  const grandTotalPaise = useMemo(() => {
    return cart.reduce((acc, item) => acc + item.subtotalPaise, 0);
  }, [cart]);

  const receivedAmountPaise = useMemo(() => {
    if (paymentMethod === 'CREDIT') return 0;
    if (customPaidAmount !== '') {
      const val = parseFloat(customPaidAmount);
      if (!isNaN(val)) return Math.max(0, Math.round(val * 100));
    }
    return grandTotalPaise;
  }, [customPaidAmount, grandTotalPaise, paymentMethod]);

  const paidAmountPaise = useMemo(() => {
    if (paymentMethod === 'CREDIT') return 0;
    return Math.min(receivedAmountPaise, grandTotalPaise);
  }, [receivedAmountPaise, grandTotalPaise, paymentMethod]);

  const changeReturnPaise = useMemo(() => {
    if (paymentMethod === 'CREDIT') return 0;
    return Math.max(0, receivedAmountPaise - grandTotalPaise);
  }, [receivedAmountPaise, grandTotalPaise, paymentMethod]);

  const pendingDuePaise = useMemo(() => {
    return Math.max(0, grandTotalPaise - paidAmountPaise);
  }, [grandTotalPaise, paidAmountPaise]);

  const handleCheckout = async () => {
    if (cart.length === 0) {
      alert('Cart is empty. Please add items to checkout.');
      return;
    }

    let custName = walkInName;
    let custMobile = walkInMobile;
    let custId: string | undefined = undefined;

    if (selectedCustomerId) {
      const matched = customers.find((c) => c.id === selectedCustomerId);
      if (matched) {
        custName = matched.name;
        custMobile = matched.mobileNumber;
        custId = matched.id;
      }
    } else if (paymentMethod === 'CREDIT' && !selectedCustomerId) {
      alert('Credit/Khata billing requires selecting or creating a registered customer.');
      return;
    }

    setIsSubmitting(true);
    try {
      const bill = await createBill(
        { id: custId, name: custName, mobileNumber: custMobile },
        cart.map((i) => ({ product: i.product, quantity: i.quantity })),
        {
          method: paymentMethod,
          paidAmountPaise,
          receivedAmountPaise,
          changeReturnedPaise: changeReturnPaise,
        }
      );
      clearCart();
      onBillGenerated(bill);
    } catch (_) {
      // handled in context
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="page-container" style={{ maxWidth: '1600px' }}>
      <div className="pos-container">
        {/* Left Column: Product Catalog & Search */}
        <div style={{ display: 'flex', flexDirection: 'column', height: '100%', minWidth: 0 }}>
          {/* Top Search & Category Filter */}
          <div style={{ marginBottom: '16px', display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
            <div style={{ position: 'relative', flex: 1, minWidth: '220px' }}>
              <Search
                size={18}
                style={{ position: 'absolute', left: '12px', top: '12px', color: 'var(--text-subtle)' }}
              />
              <input
                type="text"
                className="form-input"
                style={{ paddingLeft: '38px', height: '42px' }}
                placeholder="Search products by name or brand..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>

            <div style={{ display: 'flex', gap: '6px', overflowX: 'auto', paddingBottom: '4px' }}>
              <button
                onClick={() => setSelectedCategory('ALL')}
                className={`btn btn-sm ${selectedCategory === 'ALL' ? 'btn-primary' : 'btn-outline'}`}
              >
                All
              </button>
              {categories.map((c) => (
                <button
                  key={c.id}
                  onClick={() => setSelectedCategory(c.id)}
                  className={`btn btn-sm ${selectedCategory === c.id ? 'btn-primary' : 'btn-outline'}`}
                >
                  {c.name}
                </button>
              ))}
            </div>
          </div>

          {/* Product Grid */}
          <div
            style={{
              flex: 1,
              overflowY: 'auto',
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))',
              gap: '14px',
              paddingRight: '6px',
            }}
          >
            {filteredProducts.map((p) => {
              const inCart = cart.find((i) => i.product.id === p.id);
              const isOut = p.quantity <= 0;
              return (
                <div
                  key={p.id}
                  onClick={() => !isOut && addToCart(p)}
                  className="card"
                  style={{
                    padding: '14px',
                    cursor: isOut ? 'not-allowed' : 'pointer',
                    opacity: isOut ? 0.6 : 1,
                    border: inCart ? '2px solid var(--primary)' : '1px solid var(--surface-border)',
                    position: 'relative',
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'space-between',
                    minHeight: '135px',
                  }}
                >
                  <div>
                    <div style={{ fontSize: '0.92rem', fontWeight: 700, color: 'var(--text-main)', lineHeight: 1.3 }}>
                      {p.name}
                    </div>
                    {p.brand && (
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                        {p.brand}
                      </div>
                    )}
                  </div>

                  <div style={{ marginTop: '12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                      <div style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--primary)' }}>
                        {formatMoney(p.sellingPricePaise)}
                      </div>
                      <div style={{ fontSize: '0.72rem', color: isOut ? 'var(--danger)' : 'var(--text-muted)' }}>
                        {isOut ? 'Out of Stock' : `Stock: ${p.quantity} ${p.unit}`}
                      </div>
                    </div>
                    {inCart && (
                      <span
                        style={{
                          background: 'var(--primary)',
                          color: 'white',
                          borderRadius: 'var(--radius-full)',
                          width: '24px',
                          height: '24px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontSize: '0.75rem',
                          fontWeight: 700,
                        }}
                      >
                        {inCart.quantity}
                      </span>
                    )}
                  </div>
                </div>
              );
            })}
            {filteredProducts.length === 0 && (
              <div style={{ gridColumn: '1/-1', textAlign: 'center', padding: '60px 0', color: 'var(--text-muted)' }}>
                No products found matching "{search}".
              </div>
            )}
          </div>
        </div>

        {/* Right Column: Cart & Checkout Panel */}
        <div
          className="card"
          style={{
            display: 'flex',
            flexDirection: 'column',
            padding: '18px',
            height: '100%',
            overflow: 'hidden',
          }}
        >
          {/* Cart Header */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid var(--surface-border)', paddingBottom: '12px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <ShoppingCart size={20} color="var(--primary)" />
              <h3 style={{ fontSize: '1.1rem', fontWeight: 800 }}>Order Cart</h3>
              <span className="badge badge-primary">{cart.length} items</span>
            </div>
            {cart.length > 0 && (
              <button onClick={clearCart} style={{ fontSize: '0.78rem', color: 'var(--danger)', fontWeight: 600 }}>
                Clear All
              </button>
            )}
          </div>

          {/* Customer Selection Row */}
          <div style={{ padding: '12px 0', borderBottom: '1px solid var(--surface-border)' }}>
            <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
              <select
                className="form-select"
                style={{ padding: '8px 10px', fontSize: '0.85rem' }}
                value={selectedCustomerId}
                onChange={(e) => {
                  setSelectedCustomerId(e.target.value);
                }}
              >
                <option value="">Walk-in Customer</option>
                {customers.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name} ({c.mobileNumber}) {c.outstandingDuePaise > 0 ? `• Due: ${formatMoney(c.outstandingDuePaise)}` : ''}
                  </option>
                ))}
              </select>
              <button
                type="button"
                onClick={onOpenAddCustomer}
                className="btn btn-outline btn-sm"
                title="Add New Customer"
                style={{ padding: '8px 10px' }}
              >
                <UserPlus size={16} />
              </button>
            </div>

            {!selectedCustomerId && (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', marginTop: '8px' }}>
                <input
                  type="text"
                  className="form-input"
                  style={{ padding: '6px 10px', fontSize: '0.8rem' }}
                  placeholder="Customer Name"
                  value={walkInName}
                  onChange={(e) => setWalkInName(e.target.value)}
                />
                <input
                  type="tel"
                  maxLength={10}
                  className="form-input"
                  style={{ padding: '6px 10px', fontSize: '0.8rem' }}
                  placeholder="Mobile (Optional)"
                  value={walkInMobile}
                  onChange={(e) => setWalkInMobile(e.target.value)}
                />
              </div>
            )}
          </div>

          {/* Cart Items List */}
          <div style={{ flex: 1, overflowY: 'auto', padding: '10px 0' }}>
            {cart.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px 10px', color: 'var(--text-muted)' }}>
                <ShoppingCart size={36} color="var(--surface-border)" style={{ margin: '0 auto 10px' }} />
                <p style={{ fontSize: '0.9rem' }}>Cart is empty.</p>
                <span style={{ fontSize: '0.78rem' }}>Click products from catalog to start billing.</span>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {cart.map((item) => (
                  <div
                    key={item.product.id}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      padding: '8px 10px',
                      borderRadius: 'var(--radius-md)',
                      background: 'var(--surface-raised)',
                    }}
                  >
                    <div style={{ minWidth: 0, flex: 1, marginRight: '8px' }}>
                      <div style={{ fontWeight: 600, fontSize: '0.85rem', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {item.product.name}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                        {formatMoney(item.unitPricePaise)} / {item.product.unit}
                      </div>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', border: '1px solid var(--surface-border)', borderRadius: 'var(--radius-sm)', background: 'var(--surface)' }}>
                        <button
                          onClick={() => updateQuantity(item.product.id, -1)}
                          style={{ padding: '4px 6px', color: 'var(--text-main)' }}
                        >
                          <Minus size={13} />
                        </button>
                        <span style={{ padding: '0 6px', fontSize: '0.82rem', fontWeight: 700 }}>
                          {item.quantity}
                        </span>
                        <button
                          onClick={() => updateQuantity(item.product.id, 1)}
                          style={{ padding: '4px 6px', color: 'var(--text-main)' }}
                        >
                          <Plus size={13} />
                        </button>
                      </div>

                      <div style={{ fontWeight: 800, fontSize: '0.9rem', minWidth: '60px', textAlign: 'right' }}>
                        {formatMoney(item.subtotalPaise)}
                      </div>

                      <button
                        onClick={() => removeFromCart(item.product.id)}
                        style={{ color: 'var(--danger)', padding: '2px' }}
                      >
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Payment & Totals Footer */}
          <div style={{ borderTop: '1px solid var(--surface-border)', paddingTop: '12px' }}>
            {/* Grand Total */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: '12px' }}>
              <span style={{ fontSize: '0.95rem', fontWeight: 700 }}>Total Amount:</span>
              <span style={{ fontSize: '1.6rem', fontWeight: 900, color: 'var(--primary)', letterSpacing: '-0.02em' }}>
                {formatMoney(grandTotalPaise)}
              </span>
            </div>

            {/* Payment Method Selector */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '6px', marginBottom: '10px' }}>
              {(['CASH', 'UPI', 'CARD', 'CREDIT'] as const).map((m) => (
                <button
                  key={m}
                  type="button"
                  onClick={() => setPaymentMethod(m)}
                  style={{
                    padding: '8px 4px',
                    borderRadius: 'var(--radius-sm)',
                    border: `1px solid ${paymentMethod === m ? 'var(--primary)' : 'var(--surface-border)'}`,
                    background: paymentMethod === m ? 'var(--primary-light)' : 'var(--surface)',
                    color: paymentMethod === m ? 'var(--primary)' : 'var(--text-muted)',
                    fontWeight: 700,
                    fontSize: '0.75rem',
                    textAlign: 'center',
                  }}
                >
                  {m}
                </button>
              ))}
            </div>

            {paymentMethod !== 'CREDIT' && (
              <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginBottom: '10px' }}>
                <input
                  type="number"
                  step="0.01"
                  className="form-input"
                  style={{ padding: '6px 10px', fontSize: '0.88rem', height: '38px', fontWeight: 700 }}
                  placeholder={`Received: ₹${(grandTotalPaise / 100).toFixed(2)}`}
                  value={customPaidAmount}
                  onChange={(e) => setCustomPaidAmount(e.target.value)}
                />
                <button
                  type="button"
                  onClick={() => setCustomPaidAmount('')}
                  className="btn btn-outline btn-sm"
                  style={{ height: '38px', fontSize: '0.78rem' }}
                >
                  Full
                </button>
              </div>
            )}

            {/* Change to Return / Give Back (Matching Mobile App) */}
            {changeReturnPaise > 0 && (
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  padding: '10px 14px',
                  background: 'rgba(13, 148, 136, 0.12)',
                  border: '1.5px solid #0d9488',
                  borderRadius: 'var(--radius-md)',
                  marginBottom: '10px',
                }}
              >
                <div>
                  <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#0f766e', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                    Change to Give Customer
                  </div>
                  <div style={{ fontSize: '1.35rem', fontWeight: 900, color: '#0f766e' }}>
                    {formatMoney(changeReturnPaise)}
                  </div>
                </div>
                <div style={{ textAlign: 'right', fontSize: '0.78rem', color: '#134e4a' }}>
                  <div>Received: <strong>{formatMoney(receivedAmountPaise)}</strong></div>
                  <div>Bill: <strong>{formatMoney(grandTotalPaise)}</strong></div>
                </div>
              </div>
            )}

            {pendingDuePaise > 0 && (
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  padding: '6px 10px',
                  background: 'var(--danger-light)',
                  color: 'var(--danger-dark)',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: '0.78rem',
                  fontWeight: 700,
                  marginBottom: '10px',
                }}
              >
                <span>Balance Added to Khata:</span>
                <span>{formatMoney(pendingDuePaise)}</span>
              </div>
            )}

            <button
              onClick={handleCheckout}
              disabled={cart.length === 0 || isSubmitting}
              className="btn btn-primary btn-lg"
              style={{ width: '100%', gap: '8px', fontWeight: 800 }}
            >
              <Printer size={18} />
              {isSubmitting ? 'Generating...' : `Complete Sale (${formatMoney(paidAmountPaise)})`}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
