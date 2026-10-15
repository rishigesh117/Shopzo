import React from 'react';
import { LayoutDashboard, ShoppingCart, Package, Users, MoreHorizontal } from 'lucide-react';

interface MobileNavProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
  onOpenMore: () => void;
}

export const MobileNav: React.FC<MobileNavProps> = ({ currentTab, onSelectTab, onOpenMore }) => {
  return (
    <nav className="mobile-nav">
      <button
        className={`mobile-nav-item ${currentTab === 'dashboard' ? 'active' : ''}`}
        onClick={() => onSelectTab('dashboard')}
      >
        <LayoutDashboard size={20} />
        <span>Home</span>
      </button>

      <button
        className={`mobile-nav-item ${currentTab === 'billing' ? 'active' : ''}`}
        onClick={() => onSelectTab('billing')}
      >
        <ShoppingCart size={20} />
        <span>Billing</span>
      </button>

      <button
        className={`mobile-nav-item ${currentTab === 'products' ? 'active' : ''}`}
        onClick={() => onSelectTab('products')}
      >
        <Package size={20} />
        <span>Products</span>
      </button>

      <button
        className={`mobile-nav-item ${currentTab === 'customers' ? 'active' : ''}`}
        onClick={() => onSelectTab('customers')}
      >
        <Users size={20} />
        <span>Khata</span>
      </button>

      <button
        className={`mobile-nav-item ${['bills', 'staff', 'reports', 'settings'].includes(currentTab) ? 'active' : ''}`}
        onClick={onOpenMore}
      >
        <MoreHorizontal size={20} />
        <span>More</span>
      </button>
    </nav>
  );
};
