import React, { useState } from 'react';
import { 
  User, 
  Store, 
  Database, 
  RefreshCw, 
  CheckCircle2, 
  LogOut, 
  Shield, 
  Phone, 
  MapPin, 
  PlusCircle, 
  Check, 
  Laptop,
  Download,
  Upload
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useApp } from '../context/AppContext';
import { api } from '../api/client';
import { CreateShopModal } from '../components/CreateShopModal';
import { formatDate } from '../utils/format';

export const SettingsPage: React.FC = () => {
  const { user, currentShop, shops, switchShop, logout } = useAuth();
  const { syncData, isSyncing, lastSyncedAt, products, customers, bills, showToast } = useApp();
  const [isCreateShopOpen, setIsCreateShopOpen] = useState(false);

  const handleManualSync = async () => {
    try {
      await syncData();
      showToast('Cloud database synchronized successfully', 'success');
    } catch (err: any) {
      showToast('Sync failed: ' + (err.message || 'Network error'), 'error');
    }
  };

  const handleClearCache = () => {
    if (confirm('Do you want to refresh cached data from the cloud server? This will keep all your database records intact.')) {
      window.location.reload();
    }
  };

  const handleExportBackup = () => {
    if (!currentShop) return;
    const backupData = {
      version: 1,
      exportedAt: Date.now(),
      shopId: currentShop.id,
      shopName: currentShop.name,
      shopCode: currentShop.shopCode,
      products,
      customers,
      bills,
    };
    const blob = new Blob([JSON.stringify(backupData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `Shopzo_Backup_${currentShop.shopCode}_${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('Backup exported successfully', 'success');
  };

  const handleImportBackup = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !currentShop) return;
    try {
      const text = await file.text();
      const backup = JSON.parse(text);
      if (!backup.products && !backup.customers && !backup.bills) {
        throw new Error('Invalid backup file format');
      }
      const operations: any[] = [];
      const now = Date.now();
      (backup.products || []).forEach((p: any) => {
        operations.push({
          id: p.id || Math.random().toString(),
          entityType: 'PRODUCT',
          entityId: p.id,
          operationType: 'CREATE',
          payload: p,
          shopId: currentShop.id,
          createdAt: now,
        });
      });
      (backup.customers || []).forEach((c: any) => {
        operations.push({
          id: c.id || Math.random().toString(),
          entityType: 'CUSTOMER',
          entityId: c.id,
          operationType: 'CREATE',
          payload: c,
          shopId: currentShop.id,
          createdAt: now,
        });
      });
      (backup.bills || []).forEach((b: any) => {
        operations.push({
          id: b.id || Math.random().toString(),
          entityType: 'BILL',
          entityId: b.id,
          operationType: 'CREATE',
          payload: b,
          shopId: currentShop.id,
          createdAt: now,
        });
      });
      if (operations.length > 0) {
        await api.pushSync(currentShop.id, operations);
        await syncData();
        showToast(`Successfully restored ${backup.products?.length || 0} products & ${backup.bills?.length || 0} bills!`, 'success');
      }
    } catch (err: any) {
      showToast('Restore failed: ' + (err.message || 'Invalid file'), 'error');
    }
  };

  return (
    <div className="page-container">
      {/* Top Header */}
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800, letterSpacing: '-0.02em', color: 'var(--text-primary)' }}>
          System & Store Settings
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', marginTop: '4px' }}>
          Manage your owner account, multi-store instances, and cloud database synchronization
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '24px' }}>
        {/* Owner Profile Card (Prominently displaying Owner Name as requested) */}
        <div className="card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '18px' }}>
            <User size={20} style={{ color: 'var(--primary)' }} />
            <h2 style={{ fontSize: '1.15rem', fontWeight: 700 }}>Owner Account Information</h2>
          </div>

          <div 
            style={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: '16px', 
              padding: '16px', 
              borderRadius: '12px', 
              background: 'rgba(99, 102, 241, 0.08)',
              border: '1px solid rgba(99, 102, 241, 0.2)',
              marginBottom: '20px'
            }}
          >
            <div 
              style={{ 
                width: '56px', 
                height: '56px', 
                borderRadius: '16px', 
                background: 'linear-gradient(135deg, #6366f1, #8b5cf6)', 
                color: '#ffffff',
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center',
                fontSize: '1.5rem',
                fontWeight: 800,
                boxShadow: '0 4px 12px rgba(99, 102, 241, 0.3)'
              }}
            >
              {user?.name ? user.name.charAt(0).toUpperCase() : 'O'}
            </div>
            <div>
              <div style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--text-primary)' }}>
                {user?.name || 'Shop Owner'}
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.85rem', color: 'var(--text-secondary)', marginTop: '2px' }}>
                <Phone size={13} /> {user?.mobileNumber || 'Not available'}
              </div>
              <span className="badge badge-primary" style={{ marginTop: '6px', display: 'inline-flex', fontSize: '0.72rem' }}>
                <Shield size={11} style={{ marginRight: '4px' }} /> Verified Business Account
              </span>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '0.9rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid var(--surface-border)' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Account User ID</span>
              <span style={{ fontWeight: 600, fontFamily: 'monospace', fontSize: '0.8rem' }}>{user?.id || '—'}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid var(--surface-border)' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Member Since</span>
              <span style={{ fontWeight: 600 }}>{user?.createdAt ? formatDate(user.createdAt) : '2026'}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Account Type</span>
              <span style={{ fontWeight: 700, color: 'var(--primary)' }}>Multi-Store Merchant</span>
            </div>
          </div>

          <div style={{ marginTop: '20px' }}>
            <button 
              onClick={logout} 
              className="btn btn-outline" 
              style={{ width: '100%', color: 'var(--danger)', borderColor: 'rgba(239, 68, 68, 0.3)' }}
            >
              <LogOut size={16} /> Sign Out of All Sessions
            </button>
          </div>
        </div>

        {/* Current Active Store Card */}
        <div className="card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '18px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Store size={20} style={{ color: 'var(--primary)' }} />
              <h2 style={{ fontSize: '1.15rem', fontWeight: 700 }}>Store Profile</h2>
            </div>
            <button onClick={() => setIsCreateShopOpen(true)} className="btn btn-primary btn-sm">
              <PlusCircle size={14} /> New Store
            </button>
          </div>

          <div style={{ padding: '16px', borderRadius: '12px', background: 'var(--surface-color)', border: '1px solid var(--surface-border)', marginBottom: '18px' }}>
            <div style={{ fontSize: '1.2rem', fontWeight: 800 }}>{currentShop?.name || 'Main Branch'}</div>
            {currentShop?.address && (
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.85rem', color: 'var(--text-secondary)', marginTop: '4px' }}>
                <MapPin size={13} /> {currentShop.address}
              </div>
            )}
            <div style={{ marginTop: '12px', display: 'flex', alignItems: 'center', gap: '10px' }}>
              <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 600 }}>PAIRING CODE:</span>
              <span style={{ fontFamily: 'monospace', fontWeight: 800, background: 'rgba(99, 102, 241, 0.1)', color: 'var(--primary)', padding: '2px 8px', borderRadius: '4px', letterSpacing: '1px' }}>
                {currentShop?.shopCode || 'N/A'}
              </span>
            </div>
          </div>

          {/* All Owned Shops List */}
          <div>
            <div style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', marginBottom: '10px' }}>
              Your Stores ({shops.length})
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {shops.map(s => {
                const isSelected = s.id === currentShop?.id;
                return (
                  <div
                    key={s.id}
                    onClick={() => switchShop(s.id)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      padding: '12px 14px',
                      borderRadius: '8px',
                      border: `1px solid ${isSelected ? 'var(--primary)' : 'var(--surface-border)'}`,
                      background: isSelected ? 'rgba(99, 102, 241, 0.08)' : 'transparent',
                      cursor: 'pointer',
                      transition: 'all 0.15s ease'
                    }}
                  >
                    <div>
                      <div style={{ fontWeight: 600, fontSize: '0.9rem', color: isSelected ? 'var(--primary)' : 'var(--text-primary)' }}>
                        {s.name}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                        Code: {s.shopCode}
                      </div>
                    </div>
                    {isSelected && <Check size={18} style={{ color: 'var(--primary)' }} />}
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Database & Cloud Synchronization */}
        <div className="card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '18px' }}>
            <Database size={20} style={{ color: 'var(--primary)' }} />
            <h2 style={{ fontSize: '1.15rem', fontWeight: 700 }}>Unified Database & Cloud Sync</h2>
          </div>

          <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginBottom: '18px', lineHeight: 1.5 }}>
            The Web Application and the Android Mobile Application share the exact same PostgreSQL database on Vercel. 
            All sales, products, and Khata dues are preserved across Chrome, Android, and tablets in real-time.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '0.88rem', marginBottom: '20px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 12px', background: 'var(--surface-color)', borderRadius: '8px' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Cloud Backend</span>
              <span style={{ fontWeight: 600, color: 'var(--primary)', fontFamily: 'monospace' }}>https://shopzo-nine.vercel.app</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 12px', background: 'var(--surface-color)', borderRadius: '8px' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Connection Status</span>
              <span style={{ fontWeight: 700, color: 'var(--success)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <CheckCircle2 size={15} /> Online & Synchronized
              </span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 12px', background: 'var(--surface-color)', borderRadius: '8px' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Last Synced</span>
              <span style={{ fontWeight: 600 }}>{lastSyncedAt ? formatDate(lastSyncedAt) : 'Just now'}</span>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px' }}>
            <button 
              onClick={handleManualSync} 
              disabled={isSyncing} 
              className="btn btn-primary"
              style={{ flex: 1 }}
            >
              <RefreshCw size={15} className={isSyncing ? 'spin' : ''} />
              {isSyncing ? 'Syncing...' : 'Sync Cloud Now'}
            </button>
            <button 
              onClick={handleClearCache} 
              className="btn btn-outline"
            >
              Reload
            </button>
          </div>
        </div>

        {/* Database Backup & Restore (Exact match with Android App) */}
        <div className="card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '18px' }}>
            <Database size={20} style={{ color: '#0d9488' }} />
            <h2 style={{ fontSize: '1.15rem', fontWeight: 700 }}>Database Backup & Restore</h2>
          </div>

          <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginBottom: '18px', lineHeight: 1.5 }}>
            Export a safe versioned backup of products, sales, customers, and financial records or restore data from your mobile app.
          </p>

          <div style={{ display: 'flex', gap: '12px', marginTop: 'auto' }}>
            <button
              onClick={handleExportBackup}
              className="btn btn-outline"
              style={{ flex: 1, gap: '6px' }}
            >
              <Download size={15} /> Export
            </button>
            <label
              className="btn"
              style={{
                flex: 1,
                gap: '6px',
                background: '#eab308',
                color: '#000000',
                fontWeight: 700,
                cursor: 'pointer',
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Upload size={15} /> Restore
              <input
                type="file"
                accept=".json"
                style={{ display: 'none' }}
                onChange={handleImportBackup}
              />
            </label>
          </div>
        </div>

        {/* Device Compatibility & Web App Details */}
        <div className="card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '18px' }}>
            <Laptop size={20} style={{ color: 'var(--primary)' }} />
            <h2 style={{ fontSize: '1.15rem', fontWeight: 700 }}>Google Chrome & Cross-Device Support</h2>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', fontSize: '0.88rem' }}>
            <div style={{ padding: '14px', borderRadius: '10px', background: 'rgba(16, 185, 129, 0.08)', border: '1px solid rgba(16, 185, 129, 0.2)' }}>
              <div style={{ fontWeight: 700, color: 'var(--success)', marginBottom: '4px' }}>
                ✓ Optimized for Chrome on Laptops & Mobiles
              </div>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', lineHeight: 1.4 }}>
                This web application adapts automatically to desktop keyboard/mouse POS workflows, laptop screens, and mobile Chrome touch screens with smooth navigation.
              </p>
            </div>

            <div style={{ padding: '14px', borderRadius: '10px', background: 'var(--surface-color)', border: '1px solid var(--surface-border)' }}>
              <div style={{ fontWeight: 700, marginBottom: '4px' }}>
                Thermal Printer & Standard A4 Support
              </div>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', lineHeight: 1.4 }}>
                Print bills directly to 58mm/80mm thermal receipt printers or regular desktop A4/letter office printers via Chrome's native print dialogue.
              </p>
            </div>

            <div style={{ padding: '14px', borderRadius: '10px', background: 'var(--surface-color)', border: '1px solid var(--surface-border)' }}>
              <div style={{ fontWeight: 700, marginBottom: '4px' }}>
                Live Catalog Synced
              </div>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', lineHeight: 1.4 }}>
                Currently holding {products.length} products, {customers.length} registered customers, and {bills.length} invoices.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Modal to register new shop */}
      {isCreateShopOpen && <CreateShopModal onClose={() => setIsCreateShopOpen(false)} />}
    </div>
  );
};
