import React from 'react';
import {
  LayoutDashboard,
  ShoppingCart,
  Package,
  Users,
  FileText,
  UserCheck,
  BarChart3,
  Settings,
  LogOut,
  Store,
  ChevronDown,
  Cloud
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

interface SidebarProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
  onOpenCreateShop: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ currentTab, onSelectTab, onOpenCreateShop }) => {
  const { user, currentShop, shops, selectShop, logout } = useAuth();
  const [shopMenuOpen, setShopMenuOpen] = React.useState(false);

  const navItems = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'billing', label: 'POS Billing', icon: ShoppingCart },
    { id: 'products', label: 'Inventory', icon: Package },
    { id: 'customers', label: 'Customers', icon: Users },
    { id: 'bills', label: 'Past Bills', icon: FileText },
    { id: 'staff', label: 'Staff Management', icon: UserCheck },
    { id: 'reports', label: 'Reports', icon: BarChart3 },
    { id: 'settings', label: 'Shop Settings', icon: Settings },
  ];

  return (
    <aside className="sidebar">
      {/* Brand Header */}
      <div style={{ padding: '20px 20px 16px', borderBottom: '1px solid rgba(255, 255, 255, 0.08)' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{
              width: '36px',
              height: '36px',
              borderRadius: '10px',
              background: 'linear-gradient(135deg, #2563eb, #6366f1)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(37, 99, 235, 0.4)'
            }}>
              <Store size={20} color="#ffffff" />
            </div>
            <div>
              <span style={{ fontSize: '1.25rem', fontWeight: 800, letterSpacing: '-0.03em', color: '#ffffff' }}>SHOPZO</span>
              <span style={{ display: 'block', fontSize: '0.68rem', color: '#94a3b8', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Web POS</span>
            </div>
          </div>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
            background: 'rgba(16, 185, 129, 0.15)',
            padding: '3px 8px',
            borderRadius: '9999px',
            fontSize: '0.7rem',
            color: '#34d399',
            fontWeight: 600
          }}>
            <Cloud size={12} /> Live
          </div>
        </div>

        {/* Shop Switcher Button */}
        <div style={{ position: 'relative' }}>
          <button
            onClick={() => setShopMenuOpen(!shopMenuOpen)}
            style={{
              width: '100%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '10px 12px',
              background: 'rgba(255, 255, 255, 0.06)',
              borderRadius: '10px',
              color: '#ffffff',
              border: '1px solid rgba(255, 255, 255, 0.1)',
              transition: 'all 150ms ease'
            }}
          >
            <div style={{ textAlign: 'left', minWidth: 0 }}>
              <div style={{ fontSize: '0.85rem', fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {currentShop ? currentShop.name : 'Select Shop'}
              </div>
              <div style={{ fontSize: '0.72rem', color: '#94a3b8' }}>
                {currentShop ? currentShop.shopCode : 'No shop'}
              </div>
            </div>
            <ChevronDown size={16} color="#94a3b8" />
          </button>

          {shopMenuOpen && (
            <div style={{
              position: 'absolute',
              top: '100%',
              left: 0,
              right: 0,
              marginTop: '6px',
              background: '#1e293b',
              border: '1px solid rgba(255, 255, 255, 0.12)',
              borderRadius: '10px',
              boxShadow: '0 10px 25px rgba(0, 0, 0, 0.4)',
              zIndex: 100,
              overflow: 'hidden'
            }}>
              {shops.map((s) => (
                <button
                  key={s.id}
                  onClick={() => {
                    selectShop(s);
                    setShopMenuOpen(false);
                  }}
                  style={{
                    width: '100%',
                    padding: '10px 14px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    textAlign: 'left',
                    color: s.id === currentShop?.id ? '#60a5fa' : '#e2e8f0',
                    background: s.id === currentShop?.id ? 'rgba(37, 99, 235, 0.2)' : 'transparent',
                    borderBottom: '1px solid rgba(255, 255, 255, 0.05)'
                  }}
                >
                  <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>{s.name}</span>
                  <span style={{ fontSize: '0.7rem', color: '#94a3b8' }}>{s.shopCode}</span>
                </button>
              ))}
              <button
                onClick={() => {
                  setShopMenuOpen(false);
                  onOpenCreateShop();
                }}
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  color: '#38bdf8',
                  fontSize: '0.82rem',
                  fontWeight: 600,
                  textAlign: 'left',
                  background: 'rgba(56, 189, 248, 0.08)'
                }}
              >
                + Create New Shop
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Nav List */}
      <nav style={{ flex: 1, padding: '16px 12px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '4px' }}>
        {navItems.map((item) => {
          const IconComponent = item.icon;
          const isActive = currentTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onSelectTab(item.id)}
              style={{
                width: '100%',
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                padding: '11px 14px',
                borderRadius: '10px',
                color: isActive ? '#60a5fa' : '#94a3b8',
                background: isActive ? 'rgba(37, 99, 235, 0.18)' : 'transparent',
                fontWeight: isActive ? 700 : 500,
                fontSize: '0.9rem',
                transition: 'all 150ms ease'
              }}
            >
              <IconComponent size={19} color={isActive ? '#60a5fa' : '#94a3b8'} />
              <span>{item.label}</span>
            </button>
          );
        })}
      </nav>

      {/* User Profile Card & Logout */}
      <div style={{
        padding: '16px 16px',
        borderTop: '1px solid rgba(255, 255, 255, 0.08)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        background: 'rgba(0, 0, 0, 0.2)'
      }}>
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: '0.88rem', fontWeight: 700, color: '#f8fafc', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {user?.name || 'Store Owner'}
          </div>
          <div style={{ fontSize: '0.72rem', color: '#94a3b8' }}>
            {user?.mobileNumber} ({currentShop?.role || 'OWNER'})
          </div>
        </div>
        <button
          onClick={logout}
          title="Sign Out"
          style={{
            padding: '8px',
            borderRadius: '8px',
            color: '#f87171',
            background: 'rgba(239, 68, 68, 0.1)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}
        >
          <LogOut size={16} />
        </button>
      </div>
    </aside>
  );
};
