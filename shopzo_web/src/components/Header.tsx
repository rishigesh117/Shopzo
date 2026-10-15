import React from 'react';
import { RefreshCw, Store } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useApp } from '../context/AppContext';

interface HeaderProps {
  title: string;
}

export const Header: React.FC<HeaderProps> = ({ title }) => {
  const { currentShop, user } = useAuth();
  const { refreshData, isSyncing, isLoading } = useApp();

  const handleSync = async () => {
    await refreshData();
  };

  return (
    <header className="top-header">
      <div>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>{title}</h2>
        <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
          {currentShop ? (
            <span>
              {currentShop.name} &bull; Code: <strong>{currentShop.shopCode}</strong>
            </span>
          ) : (
            'SHOPZO Cloud Management'
          )}
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        {/* Sync Button */}
        <button
          onClick={handleSync}
          disabled={isLoading || isSyncing}
          className="btn btn-outline btn-sm"
          title="Sync with cloud database"
          style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
        >
          <RefreshCw
            size={15}
            style={{
              animation: isSyncing || isLoading ? 'spin 1s linear infinite' : 'none',
            }}
          />
          <span style={{ display: window.innerWidth < 640 ? 'none' : 'inline' }}>
            {isSyncing ? 'Syncing...' : 'Sync Cloud'}
          </span>
        </button>

        {/* Shop Badge */}
        {currentShop && (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '6px 12px',
              background: 'var(--primary-light)',
              borderRadius: 'var(--radius-full)',
              color: 'var(--primary)',
              fontSize: '0.8rem',
              fontWeight: 700,
            }}
          >
            <Store size={14} />
            <span>{currentShop.shopCode}</span>
          </div>
        )}

        {/* User initials circle */}
        <div
          style={{
            width: '36px',
            height: '36px',
            borderRadius: 'var(--radius-full)',
            background: 'var(--sidebar-bg)',
            color: 'white',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: 700,
            fontSize: '0.85rem',
          }}
          title={user?.name || 'Owner'}
        >
          {user?.name ? user.name.charAt(0).toUpperCase() : 'U'}
        </div>
      </div>
      <style>{`
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      `}</style>
    </header>
  );
};
