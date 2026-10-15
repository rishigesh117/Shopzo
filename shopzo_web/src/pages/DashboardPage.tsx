import React from 'react';
import {
  IndianRupee,
  ShoppingBag,
  Package,
  AlertTriangle,
  Users,
  Plus,
  ArrowUpRight,
  TrendingUp,
  Receipt
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { useAuth } from '../context/AuthContext';
import { formatMoney, formatDateOnly } from '../utils/format';
import { Bill } from '../types';

interface DashboardPageProps {
  onNavigate: (tab: string) => void;
  onOpenAddProduct: () => void;
  onOpenAddCustomer: () => void;
  onViewBill: (bill: Bill) => void;
}

export const DashboardPage: React.FC<DashboardPageProps> = ({
  onNavigate,
  onOpenAddProduct,
  onOpenAddCustomer,
  onViewBill,
}) => {
  const { currentShop, user } = useAuth();
  const { products, bills, customers } = useApp();

  // Metrics calculations
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  const todayStartMs = todayStart.getTime();

  const todayBills = bills.filter((b) => b.createdAt >= todayStartMs);
  const todayRevenuePaise = todayBills.reduce((acc, b) => acc + b.grandTotalPaise, 0);

  const lowStockProducts = products.filter((p) => p.quantity <= p.minStockLevel);
  const totalDuePaise = customers.reduce((acc, c) => acc + c.outstandingDuePaise, 0);

  const recentBills = bills.slice(0, 6);

  return (
    <div className="page-container">
      {/* Welcome Banner */}
      <div
        style={{
          background: 'linear-gradient(135deg, #1e3a8a, #2563eb)',
          borderRadius: 'var(--radius-xl)',
          padding: '28px 32px',
          color: 'white',
          marginBottom: '28px',
          boxShadow: '0 10px 25px rgba(37, 99, 235, 0.25)',
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '20px',
        }}
      >
        <div>
          <span
            style={{
              background: 'rgba(255, 255, 255, 0.2)',
              padding: '4px 12px',
              borderRadius: 'var(--radius-full)',
              fontSize: '0.75rem',
              fontWeight: 700,
              textTransform: 'uppercase',
              letterSpacing: '0.05em',
            }}
          >
            Store Overview
          </span>
          <h1 style={{ color: 'white', fontSize: '1.85rem', marginTop: '10px' }}>
            Welcome back, {user?.name || currentShop?.ownerName || 'Store Owner'}! 👋
          </h1>
          <p style={{ color: 'rgba(255, 255, 255, 0.85)', marginTop: '4px', fontSize: '0.95rem' }}>
            Store: <strong>{currentShop?.name}</strong> &bull; Shop Code: <strong>{currentShop?.shopCode}</strong>
          </p>
        </div>

        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
          <button
            onClick={() => onNavigate('billing')}
            className="btn btn-lg"
            style={{
              background: '#ffffff',
              color: '#1d4ed8',
              fontWeight: 800,
              boxShadow: '0 4px 14px rgba(0,0,0,0.15)',
            }}
          >
            <Plus size={20} /> New Sale (POS)
          </button>
        </div>
      </div>

      {/* 4 Stats Cards */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
          gap: '20px',
          marginBottom: '32px',
        }}
      >
        {/* Today's Revenue */}
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#eff6ff', color: '#2563eb' }}>
            <IndianRupee size={28} />
          </div>
          <div>
            <div className="stat-val">{formatMoney(todayRevenuePaise)}</div>
            <div className="stat-label">Today's Sales Revenue</div>
          </div>
        </div>

        {/* Today's Orders */}
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#ecfdf5', color: '#059669' }}>
            <ShoppingBag size={28} />
          </div>
          <div>
            <div className="stat-val">{todayBills.length}</div>
            <div className="stat-label">Today's Completed Orders</div>
          </div>
        </div>

        {/* Low Stock Alerts */}
        <div
          className="stat-card"
          onClick={() => onNavigate('products')}
          style={{ cursor: 'pointer', transition: 'all 150ms ease' }}
        >
          <div
            className="stat-icon"
            style={{
              background: lowStockProducts.length > 0 ? '#fef2f2' : '#f0fdf4',
              color: lowStockProducts.length > 0 ? '#ef4444' : '#10b981',
            }}
          >
            <AlertTriangle size={28} />
          </div>
          <div>
            <div
              className="stat-val"
              style={{ color: lowStockProducts.length > 0 ? '#ef4444' : 'inherit' }}
            >
              {lowStockProducts.length}
            </div>
            <div className="stat-label">
              {lowStockProducts.length > 0 ? 'Low Stock Alerts!' : 'Inventory Healthy'}
            </div>
          </div>
        </div>

        {/* Khata Dues */}
        <div
          className="stat-card"
          onClick={() => onNavigate('customers')}
          style={{ cursor: 'pointer' }}
        >
          <div className="stat-icon" style={{ background: '#fffbeb', color: '#d97706' }}>
            <Users size={28} />
          </div>
          <div>
            <div className="stat-val" style={{ color: totalDuePaise > 0 ? '#b45309' : 'inherit' }}>
              {formatMoney(totalDuePaise)}
            </div>
            <div className="stat-label">Total Customer Dues (Khata)</div>
          </div>
        </div>
      </div>

      {/* Quick Action Grid */}
      <div style={{ marginBottom: '32px' }}>
        <h3 style={{ marginBottom: '14px', fontSize: '1.15rem' }}>Quick Actions</h3>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
            gap: '14px',
          }}
        >
          <button
            onClick={() => onNavigate('billing')}
            className="card"
            style={{
              textAlign: 'left',
              display: 'flex',
              alignItems: 'center',
              gap: '14px',
              padding: '16px',
              borderLeft: '4px solid #2563eb',
            }}
          >
            <div style={{ background: '#eff6ff', padding: '10px', borderRadius: '10px', color: '#2563eb' }}>
              <Plus size={20} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.95rem' }}>Create Bill</div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>Open POS Terminal</div>
            </div>
          </button>

          <button
            onClick={onOpenAddProduct}
            className="card"
            style={{
              textAlign: 'left',
              display: 'flex',
              alignItems: 'center',
              gap: '14px',
              padding: '16px',
              borderLeft: '4px solid #0d9488',
            }}
          >
            <div style={{ background: '#f0fdfa', padding: '10px', borderRadius: '10px', color: '#0d9488' }}>
              <Package size={20} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.95rem' }}>Add Product</div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>Stock in inventory</div>
            </div>
          </button>

          <button
            onClick={onOpenAddCustomer}
            className="card"
            style={{
              textAlign: 'left',
              display: 'flex',
              alignItems: 'center',
              gap: '14px',
              padding: '16px',
              borderLeft: '4px solid #f59e0b',
            }}
          >
            <div style={{ background: '#fffbeb', padding: '10px', borderRadius: '10px', color: '#f59e0b' }}>
              <Users size={20} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.95rem' }}>Add Customer</div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>Khata credit ledger</div>
            </div>
          </button>

          <button
            onClick={() => onNavigate('reports')}
            className="card"
            style={{
              textAlign: 'left',
              display: 'flex',
              alignItems: 'center',
              gap: '14px',
              padding: '16px',
              borderLeft: '4px solid #6366f1',
            }}
          >
            <div style={{ background: '#eef2ff', padding: '10px', borderRadius: '10px', color: '#6366f1' }}>
              <TrendingUp size={20} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.95rem' }}>Sales Analytics</div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>Profit & reports</div>
            </div>
          </button>
        </div>
      </div>

      {/* Two Column Section: Recent Sales & Low Stock List */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '24px' }}>
        {/* Recent Invoices */}
        <div className="card">
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: '16px',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Receipt size={20} color="var(--primary)" />
              <h3 style={{ fontSize: '1.1rem' }}>Recent Invoices</h3>
            </div>
            <button
              onClick={() => onNavigate('bills')}
              style={{
                fontSize: '0.82rem',
                color: 'var(--primary)',
                fontWeight: 700,
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
              }}
            >
              View All <ArrowUpRight size={14} />
            </button>
          </div>

          {recentBills.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '36px 0', color: 'var(--text-muted)' }}>
              No bills created yet. Click "New Sale" to begin billing!
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {recentBills.map((b) => (
                <div
                  key={b.id}
                  onClick={() => onViewBill(b)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '12px 14px',
                    borderRadius: 'var(--radius-md)',
                    background: 'var(--surface-raised)',
                    cursor: 'pointer',
                    transition: 'all 150ms ease',
                  }}
                >
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{b.billNumber}</div>
                    <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                      {b.customerNameSnapshot} &bull; {formatDateOnly(b.createdAt)}
                    </div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontWeight: 800, fontSize: '0.95rem', color: 'var(--primary)' }}>
                      {formatMoney(b.grandTotalPaise)}
                    </div>
                    <span
                      className={`badge ${
                        b.paymentStatus === 'PAID'
                          ? 'badge-success'
                          : b.paymentStatus === 'PARTIALLY_PAID'
                          ? 'badge-warning'
                          : 'badge-danger'
                      }`}
                      style={{ fontSize: '0.68rem', padding: '2px 8px' }}
                    >
                      {b.paymentStatus}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Low Stock Alerts Card */}
        <div className="card">
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: '16px',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <AlertTriangle size={20} color="#ef4444" />
              <h3 style={{ fontSize: '1.1rem' }}>Low Stock Inventory</h3>
            </div>
            <button
              onClick={() => onNavigate('products')}
              style={{
                fontSize: '0.82rem',
                color: 'var(--primary)',
                fontWeight: 700,
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
              }}
            >
              Manage <ArrowUpRight size={14} />
            </button>
          </div>

          {lowStockProducts.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '36px 0', color: 'var(--success-dark)' }}>
              All inventory levels are above minimum threshold.
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {lowStockProducts.slice(0, 6).map((p) => (
                <div
                  key={p.id}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '12px 14px',
                    borderRadius: 'var(--radius-md)',
                    background: '#fef2f2',
                    border: '1px solid #fee2e2',
                  }}
                >
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.9rem', color: '#991b1b' }}>{p.name}</div>
                    <div style={{ fontSize: '0.78rem', color: '#b91c1c' }}>
                      Price: {formatMoney(p.sellingPricePaise)} / {p.unit}
                    </div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontWeight: 800, color: '#dc2626', fontSize: '0.95rem' }}>
                      {p.quantity} {p.unit}
                    </div>
                    <span style={{ fontSize: '0.72rem', color: '#991b1b' }}>
                      Min: {p.minStockLevel} {p.unit}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
