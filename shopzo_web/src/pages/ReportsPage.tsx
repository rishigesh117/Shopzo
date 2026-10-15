import React, { useState, useMemo } from 'react';
import { 
  TrendingUp, 
  IndianRupee, 
  Package, 
  PieChart, 
  Download, 
  Layers, 
  CreditCard, 
  Banknote, 
  Smartphone, 
  BookOpen 
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { formatMoney } from '../utils/format';

type DateRangeFilter = 'TODAY' | 'WEEK' | 'MONTH' | 'ALL';

export const ReportsPage: React.FC = () => {
  const { bills, products, categories } = useApp();
  const [rangeFilter, setRangeFilter] = useState<DateRangeFilter>('ALL');

  // Filter bills by date range
  const filteredBills = useMemo(() => {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const startOfWeek = startOfToday - 7 * 24 * 60 * 60 * 1000;
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).getTime();

    return bills.filter(b => {
      const billTime = b.createdAt;
      if (rangeFilter === 'TODAY') return billTime >= startOfToday;
      if (rangeFilter === 'WEEK') return billTime >= startOfWeek;
      if (rangeFilter === 'MONTH') return billTime >= startOfMonth;
      return true;
    });
  }, [bills, rangeFilter]);

  // Aggregate metrics
  const totalSales = useMemo(() => {
    return filteredBills.reduce((acc, b) => acc + (b.grandTotalPaise || b.totalAmount || 0), 0);
  }, [filteredBills]);

  // Estimate Profit: using product buying prices vs item selling prices
  const totalProfit = useMemo(() => {
    let profit = 0;

    filteredBills.forEach(b => {
      b.items?.forEach(item => {
        const prod = products.find(p => p.id === item.productId);
        const buyingPrice = prod ? prod.buyingPricePaise : (item.buyingPricePaise || Math.round(item.sellingPricePaise * 0.7));
        const itemCost = buyingPrice * item.quantity;
        const itemRevenue = item.subtotalPaise || (item.sellingPricePaise * item.quantity);
        profit += (itemRevenue - itemCost);
      });
    });

    return profit > 0 ? profit : 0;
  }, [filteredBills, products]);

  const profitMarginPercent = totalSales > 0 ? ((totalProfit / totalSales) * 100).toFixed(1) : '0';

  // Payment Breakdown
  const paymentBreakdown = useMemo(() => {
    const stats: Record<string, number> = { CASH: 0, UPI: 0, CARD: 0, KHATA: 0 };
    filteredBills.forEach(b => {
      const method = b.paymentMethod?.toUpperCase() || 'CASH';
      const amount = b.grandTotalPaise || b.totalAmount || 0;
      if (stats[method] !== undefined) {
        stats[method] += amount;
      } else {
        stats['CASH'] += amount;
      }
    });
    return stats;
  }, [filteredBills]);

  // Category Breakdown
  const categoryBreakdown = useMemo(() => {
    const stats: Record<string, { name: string; revenue: number; quantity: number }> = {};
    
    // Pre-populate with known categories
    categories.forEach(c => {
      stats[c.id] = { name: c.name, revenue: 0, quantity: 0 };
    });
    stats['uncategorized'] = { name: 'General', revenue: 0, quantity: 0 };

    filteredBills.forEach(b => {
      b.items?.forEach(item => {
        const prod = products.find(p => p.id === item.productId);
        const catId = prod?.categoryId || 'uncategorized';
        if (!stats[catId]) {
          stats[catId] = { name: 'General', revenue: 0, quantity: 0 };
        }
        const revenue = item.subtotalPaise || (item.sellingPricePaise * item.quantity);
        stats[catId].revenue += revenue;
        stats[catId].quantity += item.quantity;
      });
    });

    return Object.values(stats).filter(s => s.revenue > 0).sort((a, b) => b.revenue - a.revenue);
  }, [filteredBills, products, categories]);

  // Top Selling Products
  const topProducts = useMemo(() => {
    const map: Record<string, { name: string; quantity: number; revenue: number }> = {};

    filteredBills.forEach(b => {
      b.items?.forEach(item => {
        const name = item.productNameSnapshot || item.productName || 'Product';
        const revenue = item.subtotalPaise || (item.sellingPricePaise * item.quantity);
        if (!map[name]) {
          map[name] = { name, quantity: 0, revenue: 0 };
        }
        map[name].quantity += item.quantity;
        map[name].revenue += revenue;
      });
    });

    return Object.values(map).sort((a, b) => b.revenue - a.revenue).slice(0, 8);
  }, [filteredBills]);

  // Inventory Valuation Metrics
  const inventoryValuation = useMemo(() => {
    const totalUnits = products.reduce((acc, p) => acc + (p.quantity || 0), 0);
    const costValue = products.reduce((acc, p) => acc + (p.buyingPricePaise * (p.quantity || 0)), 0);
    const retailValue = products.reduce((acc, p) => acc + (p.sellingPricePaise * (p.quantity || 0)), 0);
    const potentialProfit = retailValue - costValue;

    return { totalUnits, costValue, retailValue, potentialProfit };
  }, [products]);

  return (
    <div className="page-container">
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800, letterSpacing: '-0.02em', color: 'var(--text-primary)' }}>
            Financial & Sales Reports
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', marginTop: '4px' }}>
            Track profit margins, payment method shares, category demand, and inventory valuation
          </p>
        </div>

        {/* Date Filter & Export */}
        <div style={{ display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', background: 'var(--surface-color)', padding: '4px', borderRadius: '8px', border: '1px solid var(--surface-border)' }}>
            {(['TODAY', 'WEEK', 'MONTH', 'ALL'] as DateRangeFilter[]).map(tab => (
              <button
                key={tab}
                onClick={() => setRangeFilter(tab)}
                style={{
                  padding: '6px 14px',
                  borderRadius: '6px',
                  border: 'none',
                  fontSize: '0.8rem',
                  fontWeight: 600,
                  cursor: 'pointer',
                  background: rangeFilter === tab ? 'var(--primary)' : 'transparent',
                  color: rangeFilter === tab ? '#ffffff' : 'var(--text-secondary)',
                  transition: 'all 0.15s ease'
                }}
              >
                {tab === 'TODAY' ? 'Today' : tab === 'WEEK' ? 'This Week' : tab === 'MONTH' ? 'This Month' : 'All Time'}
              </button>
            ))}
          </div>

          <button 
            onClick={() => {
              const csvContent = "data:text/csv;charset=utf-8," + 
                ["Metric,Value"]
                .concat([
                  `"Period","${rangeFilter}"`,
                  `"Total Revenue (Rs)","${(totalSales/100).toFixed(2)}"`,
                  `"Estimated Profit (Rs)","${(totalProfit/100).toFixed(2)}"`,
                  `"Profit Margin","${profitMarginPercent}%"`,
                  `"Total Invoices","${filteredBills.length}"`,
                  `"Inventory Cost Value (Rs)","${(inventoryValuation.costValue/100).toFixed(2)}"`,
                  `"Inventory Retail Value (Rs)","${(inventoryValuation.retailValue/100).toFixed(2)}"`
                ]).join("\n");
              const encodedUri = encodeURI(csvContent);
              const link = document.createElement("a");
              link.setAttribute("href", encodedUri);
              link.setAttribute("download", `Shopzo_Report_${rangeFilter}_${new Date().toISOString().split('T')[0]}.csv`);
              document.body.appendChild(link);
              link.click();
              document.body.removeChild(link);
            }}
            className="btn btn-outline"
          >
            <Download size={15} /> Export
          </button>
        </div>
      </div>

      {/* Main KPI Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        <div className="card" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '42px', height: '42px', borderRadius: '10px', background: 'rgba(99, 102, 241, 0.12)', color: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <IndianRupee size={22} />
            </div>
            <div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Total Revenue</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 800 }}>{formatMoney(totalSales)}</div>
            </div>
          </div>
          <div style={{ marginTop: '12px', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Across {filteredBills.length} completed transactions
          </div>
        </div>

        <div className="card" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '42px', height: '42px', borderRadius: '10px', background: 'rgba(16, 185, 129, 0.12)', color: 'var(--success)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <TrendingUp size={22} />
            </div>
            <div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Estimated Gross Profit</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--success)' }}>{formatMoney(totalProfit)}</div>
            </div>
          </div>
          <div style={{ marginTop: '12px', fontSize: '0.8rem', color: 'var(--success)', fontWeight: 600 }}>
            {profitMarginPercent}% average margin
          </div>
        </div>

        <div className="card" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '42px', height: '42px', borderRadius: '10px', background: 'rgba(245, 158, 11, 0.12)', color: 'var(--warning)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Package size={22} />
            </div>
            <div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Stock Retail Value</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 800 }}>{formatMoney(inventoryValuation.retailValue)}</div>
            </div>
          </div>
          <div style={{ marginTop: '12px', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            {inventoryValuation.totalUnits} items in current stock
          </div>
        </div>

        <div className="card" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '42px', height: '42px', borderRadius: '10px', background: 'rgba(139, 92, 246, 0.12)', color: '#8b5cf6', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Layers size={22} />
            </div>
            <div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Stock Cost Investment</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 800 }}>{formatMoney(inventoryValuation.costValue)}</div>
            </div>
          </div>
          <div style={{ marginTop: '12px', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Potential profit: {formatMoney(inventoryValuation.potentialProfit)}
          </div>
        </div>
      </div>

      {/* Grid: Payment Method Breakdown & Category Breakdown */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '20px', marginBottom: '24px' }}>
        {/* Payment Methods */}
        <div className="card" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <CreditCard size={18} style={{ color: 'var(--primary)' }} /> Payment Methods Distribution
          </h2>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {[
              { label: 'Cash Payment', amount: paymentBreakdown['CASH'], icon: Banknote, color: '#10b981' },
              { label: 'UPI / QR Scan', amount: paymentBreakdown['UPI'], icon: Smartphone, color: '#6366f1' },
              { label: 'Credit / Debit Card', amount: paymentBreakdown['CARD'], icon: CreditCard, color: '#06b6d4' },
              { label: 'Khata / Shop Credit', amount: paymentBreakdown['KHATA'], icon: BookOpen, color: '#f59e0b' },
            ].map(item => {
              const Icon = item.icon;
              const pct = totalSales > 0 ? ((item.amount / totalSales) * 100).toFixed(1) : '0';

              return (
                <div key={item.label}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.9rem', fontWeight: 600 }}>
                      <Icon size={16} style={{ color: item.color }} /> {item.label}
                    </div>
                    <div style={{ fontWeight: 700, fontSize: '0.92rem' }}>
                      {formatMoney(item.amount)}{' '}
                      <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 400 }}>({pct}%)</span>
                    </div>
                  </div>
                  <div style={{ height: '8px', background: 'var(--surface-color)', borderRadius: '4px', overflow: 'hidden' }}>
                    <div 
                      style={{ 
                        width: `${pct}%`, 
                        height: '100%', 
                        background: item.color,
                        borderRadius: '4px',
                        transition: 'width 0.4s ease'
                      }} 
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Category Contribution */}
        <div className="card" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <PieChart size={18} style={{ color: 'var(--primary)' }} /> Category Performance
          </h2>

          {categoryBreakdown.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '36px 0', color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
              No category sales recorded yet for this period.
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              {categoryBreakdown.slice(0, 5).map(cat => {
                const pct = totalSales > 0 ? ((cat.revenue / totalSales) * 100).toFixed(1) : '0';
                return (
                  <div key={cat.name}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                      <div style={{ fontWeight: 600, fontSize: '0.88rem' }}>
                        {cat.name}
                        <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', marginLeft: '6px' }}>
                          ({cat.quantity} sold)
                        </span>
                      </div>
                      <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>
                        {formatMoney(cat.revenue)}{' '}
                        <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 400 }}>({pct}%)</span>
                      </div>
                    </div>
                    <div style={{ height: '8px', background: 'var(--surface-color)', borderRadius: '4px', overflow: 'hidden' }}>
                      <div 
                        style={{ 
                          width: `${pct}%`, 
                          height: '100%', 
                          background: 'linear-gradient(90deg, #6366f1, #8b5cf6)',
                          borderRadius: '4px',
                          transition: 'width 0.4s ease'
                        }} 
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Top Performing Products */}
      <div className="card" style={{ padding: '24px' }}>
        <h2 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <TrendingUp size={18} style={{ color: 'var(--primary)' }} /> Top Selling Products
        </h2>

        {topProducts.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '36px 0', color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
            No sales recorded in the selected period.
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--surface-border)', color: 'var(--text-secondary)', fontSize: '0.78rem', textTransform: 'uppercase' }}>
                  <th style={{ padding: '12px 14px' }}>Rank</th>
                  <th style={{ padding: '12px 14px' }}>Product</th>
                  <th style={{ padding: '12px 14px', textAlign: 'center' }}>Units Sold</th>
                  <th style={{ padding: '12px 14px', textAlign: 'right' }}>Total Revenue</th>
                </tr>
              </thead>
              <tbody>
                {topProducts.map((p, idx) => (
                  <tr key={p.name} style={{ borderBottom: '1px solid var(--surface-border)' }}>
                    <td style={{ padding: '12px 14px', fontWeight: 800, color: idx === 0 ? '#f59e0b' : 'var(--text-secondary)' }}>
                      #{idx + 1}
                    </td>
                    <td style={{ padding: '12px 14px', fontWeight: 600 }}>{p.name}</td>
                    <td style={{ padding: '12px 14px', textAlign: 'center', fontWeight: 600 }}>{p.quantity}</td>
                    <td style={{ padding: '12px 14px', textAlign: 'right', fontWeight: 700, color: 'var(--primary)' }}>
                      {formatMoney(p.revenue)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};
