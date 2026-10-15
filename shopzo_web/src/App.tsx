import React, { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { AppProvider, useApp } from './context/AppContext';
import { Sidebar } from './components/Sidebar';
import { MobileNav } from './components/MobileNav';
import { Header } from './components/Header';
import { ToastContainer } from './components/ToastContainer';
import { ProductModal } from './components/ProductModal';
import { CustomerModal } from './components/CustomerModal';
import { PaymentModal } from './components/PaymentModal';
import { CreateShopModal } from './components/CreateShopModal';
import { ReceiptModal } from './components/ReceiptModal';

import { AuthPage } from './pages/AuthPage';
import { DashboardPage } from './pages/DashboardPage';
import { BillingPage } from './pages/BillingPage';
import { ProductsPage } from './pages/ProductsPage';
import { CustomersPage } from './pages/CustomersPage';
import { BillsPage } from './pages/BillsPage';
import { StaffPage } from './pages/StaffPage';
import { ReportsPage } from './pages/ReportsPage';
import { SettingsPage } from './pages/SettingsPage';

import { 
  FileText, 
  UserCheck, 
  BarChart3, 
  Settings, 
  LogOut, 
  X, 
  Store, 
  PlusCircle 
} from 'lucide-react';
import { Bill, Product, Customer } from './types';

const MainLayout: React.FC = () => {
  const { isAuthenticated, currentShop, shops, logout, user } = useAuth();
  const { categories, createProduct, updateProduct, createCustomer, recordCustomerPayment } = useApp();

  const [currentTab, setCurrentTab] = useState<string>('dashboard');
  const [isMobileMoreOpen, setIsMobileMoreOpen] = useState<boolean>(false);
  const [isCreateShopOpen, setIsCreateShopOpen] = useState<boolean>(false);
  const [isAddProductOpen, setIsAddProductOpen] = useState<boolean>(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [isAddCustomerOpen, setIsAddCustomerOpen] = useState<boolean>(false);
  const [payingCustomer, setPayingCustomer] = useState<Customer | null>(null);
  const [viewingBill, setViewingBill] = useState<Bill | null>(null);

  // If user is not authenticated, render login/signup flow
  if (!isAuthenticated) {
    return <AuthPage />;
  }

  // If user has no registered shop yet, render quick setup screen
  if (!currentShop && shops.length === 0) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px', background: 'var(--bg-color)' }}>
        <div className="card" style={{ maxWidth: '480px', width: '100%', padding: '36px', textAlign: 'center' }}>
          <div style={{ width: '64px', height: '64px', borderRadius: '18px', background: 'rgba(99, 102, 241, 0.12)', color: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px' }}>
            <Store size={32} />
          </div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800, marginBottom: '8px' }}>Welcome to Shopzo</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', marginBottom: '24px' }}>
            Hello, <strong>{user?.name || 'Store Owner'}</strong>! To start billing and managing products, please create your first shop profile.
          </p>
          <button 
            onClick={() => setIsCreateShopOpen(true)}
            className="btn btn-primary btn-lg" 
            style={{ width: '100%', justifyContent: 'center' }}
          >
            <PlusCircle size={20} /> Register New Shop
          </button>
          {isCreateShopOpen && <CreateShopModal onClose={() => setIsCreateShopOpen(false)} />}
        </div>
      </div>
    );
  }

  const getPageTitle = (tab: string) => {
    switch (tab) {
      case 'dashboard': return 'Dashboard Overview';
      case 'billing': return 'Point of Sale Terminal';
      case 'products': return 'Product Catalog & Inventory';
      case 'customers': return 'Khata & Customer Accounts';
      case 'bills': return 'Past Invoices & Receipts';
      case 'staff': return 'Staff & Access Management';
      case 'reports': return 'Financial Analytics & Reports';
      case 'settings': return 'Store & Account Settings';
      default: return 'Shopzo';
    }
  };

  return (
    <div className="app-layout">
      {/* Desktop Sidebar */}
      <Sidebar 
        currentTab={currentTab} 
        onSelectTab={(tab) => {
          setCurrentTab(tab);
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }}
        onOpenCreateShop={() => setIsCreateShopOpen(true)}
      />

      {/* Main Content Area */}
      <div className="main-content">
        <Header title={getPageTitle(currentTab)} />

        <main style={{ paddingBottom: '80px' }}>
          {currentTab === 'dashboard' && (
            <DashboardPage
              onNavigate={(tab) => {
                setCurrentTab(tab);
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
              onOpenAddProduct={() => {
                setEditingProduct(null);
                setIsAddProductOpen(true);
              }}
              onOpenAddCustomer={() => setIsAddCustomerOpen(true)}
              onViewBill={(bill) => setViewingBill(bill)}
            />
          )}

          {currentTab === 'billing' && (
            <BillingPage 
              onOpenAddCustomer={() => setIsAddCustomerOpen(true)}
              onBillGenerated={(bill) => setViewingBill(bill)}
            />
          )}

          {currentTab === 'products' && (
            <ProductsPage 
              onOpenAddProduct={() => {
                setEditingProduct(null);
                setIsAddProductOpen(true);
              }}
              onEditProduct={(p) => {
                setEditingProduct(p);
                setIsAddProductOpen(true);
              }}
            />
          )}

          {currentTab === 'customers' && (
            <CustomersPage 
              onOpenAddCustomer={() => setIsAddCustomerOpen(true)}
              onRecordPayment={(customer) => setPayingCustomer(customer)}
            />
          )}

          {currentTab === 'bills' && <BillsPage />}
          {currentTab === 'staff' && <StaffPage />}
          {currentTab === 'reports' && <ReportsPage />}
          {currentTab === 'settings' && <SettingsPage />}
        </main>
      </div>

      {/* Mobile Bottom Navigation Bar */}
      <MobileNav 
        currentTab={currentTab} 
        onSelectTab={(tab) => {
          setCurrentTab(tab);
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }}
        onOpenMore={() => setIsMobileMoreOpen(true)}
      />

      {/* Mobile More Drawer Modal */}
      {isMobileMoreOpen && (
        <div className="modal-overlay" onClick={() => setIsMobileMoreOpen(false)} style={{ alignItems: 'flex-end', padding: 0 }}>
          <div 
            className="modal-content" 
            onClick={(e) => e.stopPropagation()} 
            style={{ 
              maxWidth: '100%', 
              width: '100%', 
              borderBottomLeftRadius: 0, 
              borderBottomRightRadius: 0,
              padding: '20px 20px 36px',
              animation: 'slideUp 0.25s ease'
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
              <div style={{ fontSize: '1.1rem', fontWeight: 800 }}>Store Navigation</div>
              <button onClick={() => setIsMobileMoreOpen(false)} className="btn btn-outline btn-sm btn-icon">
                <X size={18} />
              </button>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '12px', marginBottom: '20px' }}>
              <button 
                onClick={() => { setCurrentTab('bills'); setIsMobileMoreOpen(false); }}
                className="btn btn-outline"
                style={{ height: '54px', justifyContent: 'flex-start', gap: '10px' }}
              >
                <FileText size={18} style={{ color: 'var(--primary)' }} /> Past Invoices
              </button>

              <button 
                onClick={() => { setCurrentTab('staff'); setIsMobileMoreOpen(false); }}
                className="btn btn-outline"
                style={{ height: '54px', justifyContent: 'flex-start', gap: '10px' }}
              >
                <UserCheck size={18} style={{ color: '#06b6d4' }} /> Staff Team
              </button>

              <button 
                onClick={() => { setCurrentTab('reports'); setIsMobileMoreOpen(false); }}
                className="btn btn-outline"
                style={{ height: '54px', justifyContent: 'flex-start', gap: '10px' }}
              >
                <BarChart3 size={18} style={{ color: '#10b981' }} /> Reports
              </button>

              <button 
                onClick={() => { setCurrentTab('settings'); setIsMobileMoreOpen(false); }}
                className="btn btn-outline"
                style={{ height: '54px', justifyContent: 'flex-start', gap: '10px' }}
              >
                <Settings size={18} style={{ color: '#f59e0b' }} /> Settings
              </button>
            </div>

            <button 
              onClick={() => { logout(); setIsMobileMoreOpen(false); }}
              className="btn btn-outline"
              style={{ width: '100%', color: 'var(--danger)', borderColor: 'rgba(239, 68, 68, 0.3)', justifyContent: 'center' }}
            >
              <LogOut size={16} /> Sign Out
            </button>
          </div>
        </div>
      )}

      {/* Global Modals */}
      {isCreateShopOpen && <CreateShopModal onClose={() => setIsCreateShopOpen(false)} />}
      
      {isAddProductOpen && (
        <ProductModal 
          product={editingProduct}
          categories={categories}
          onSave={async (data) => {
            if (editingProduct) {
              await updateProduct(editingProduct.id, data);
            } else {
              await createProduct(data);
            }
            setIsAddProductOpen(false);
            setEditingProduct(null);
          }}
          onClose={() => {
            setIsAddProductOpen(false);
            setEditingProduct(null);
          }}
        />
      )}

      {isAddCustomerOpen && (
        <CustomerModal 
          onSave={async (name, mobile, address) => {
            await createCustomer(name, mobile, address);
            setIsAddCustomerOpen(false);
          }}
          onClose={() => setIsAddCustomerOpen(false)}
        />
      )}

      {payingCustomer && (
        <PaymentModal 
          customer={payingCustomer}
          onSave={async (amountPaise, method) => {
            await recordCustomerPayment(payingCustomer.id, amountPaise, method);
            setPayingCustomer(null);
          }}
          onClose={() => setPayingCustomer(null)}
        />
      )}

      {viewingBill && (
        <ReceiptModal 
          bill={viewingBill}
          onClose={() => setViewingBill(null)}
        />
      )}

      {/* Floating System Notifications */}
      <ToastContainer />
    </div>
  );
};

export function App() {
  return (
    <AuthProvider>
      <AppProvider>
        <MainLayout />
      </AppProvider>
    </AuthProvider>
  );
}

export default App;
