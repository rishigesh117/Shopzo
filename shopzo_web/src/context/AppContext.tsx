import React, { createContext, useContext, useState, useEffect, ReactNode, useCallback } from 'react';
import { Product, Category, Customer, Bill, BillItem, Payment, Staff, SyncOperation } from '../types';
import { api } from '../api/client';
import { useAuth } from './AuthContext';
import { uuid, generateBillNumber } from '../utils/format';

import { DEFAULT_CATEGORIES } from '../components/ProductModal';

interface Toast {
  id: string;
  message: string;
  type: 'success' | 'error' | 'info' | 'warning';
}

interface AppContextType {
  products: Product[];
  categories: Category[];
  customers: Customer[];
  bills: Bill[];
  payments: Payment[];
  staffList: Staff[];
  isLoading: boolean;
  isSyncing: boolean;
  lastSyncedAt: number | null;
  toasts: Toast[];
  showToast: (message: string, type?: 'success' | 'error' | 'info' | 'warning') => void;
  refreshData: () => Promise<void>;
  syncData: () => Promise<void>;
  createProduct: (productData: Omit<Product, 'id' | 'shopId' | 'createdAt' | 'updatedAt'>) => Promise<Product>;
  updateProduct: (id: string, productData: Partial<Product>) => Promise<Product>;
  deleteProduct: (id: string) => Promise<void>;
  updateStock: (productId: string, type: 'RESTOCK' | 'ADJUSTMENT' | 'SALE' | 'RETURN', quantity: number, reason?: string) => Promise<void>;
  createCustomer: (name: string, mobileNumber: string, address?: string) => Promise<Customer>;
  createBill: (
    customerInfo: { id?: string; name: string; mobileNumber: string },
    items: { product: Product; quantity: number }[],
    paymentInfo: { method: 'CASH' | 'UPI' | 'CARD' | 'CREDIT'; paidAmountPaise: number; receivedAmountPaise?: number; changeReturnedPaise?: number }
  ) => Promise<Bill>;
  recordCustomerPayment: (customerId: string, amountPaise: number, paymentMethod: 'CASH' | 'UPI' | 'CARD') => Promise<void>;
  addStaff: (name: string, mobileNumber: string, password: string, permissions: string[]) => Promise<void>;
  addStaffMember: (data: { name: string; mobileNumber: string; password: string; permissions: string[] }) => Promise<void>;
  deleteStaff: (staffId: string) => Promise<void>;
  removeStaffMember: (staffId: string) => Promise<void>;
  updateStaffRolePermissions: (staffId: string, permissions: string[]) => Promise<void>;
  resetAllTestingData: () => Promise<void>;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const { currentShop, token } = useAuth();

  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>(DEFAULT_CATEGORIES);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [bills, setBills] = useState<Bill[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [staffList, setStaffList] = useState<Staff[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [isSyncing, setIsSyncing] = useState<boolean>(false);
  const [lastSyncedAt, setLastSyncedAt] = useState<number | null>(Date.now());
  const [toasts, setToasts] = useState<Toast[]>([]);

  const showToast = useCallback((message: string, type: 'success' | 'error' | 'info' | 'warning' = 'info') => {
    const id = uuid();
    setToasts((prev) => [...prev, { id, message, type }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 4000);
  }, []);

  const refreshData = useCallback(async () => {
    if (!currentShop || !token) return;
    try {
      // 1. Pull core data from cloud sync
      const syncData = await api.pullData(currentShop.id, 0);

      // Group bill items by billId
      const itemsByBill = new Map<string, BillItem[]>();
      (syncData.billItems || []).forEach((item) => {
        const arr = itemsByBill.get(item.billId) || [];
        arr.push(item);
        itemsByBill.set(item.billId, arr);
      });

      const populatedBills = (syncData.bills || []).map((b) => ({
        ...b,
        items: itemsByBill.get(b.id) || [],
      }));

      setProducts(syncData.products || []);

      // Merge server categories with mobile default categories
      const catMap = new Map<string, Category>();
      DEFAULT_CATEGORIES.forEach((c) => catMap.set(c.id, c));
      (syncData.categories || []).forEach((c) => catMap.set(c.id, c));
      setCategories(Array.from(catMap.values()));

      setCustomers(syncData.customers || []);
      setBills(populatedBills.sort((a, b) => b.createdAt - a.createdAt));
      setPayments(syncData.payments || []);

      // 2. Fetch staff if owner
      try {
        const staffRes = await api.getStaff(currentShop.id);
        setStaffList(staffRes.staff || []);
      } catch (_) {}

      setLastSyncedAt(Date.now());
    } catch (err: any) {
      // Background poll silently fails on network jitter; explicit sync displays error
    } finally {
      setIsLoading(false);
    }
  }, [currentShop, token]);

  useEffect(() => {
    if (currentShop && token) {
      setIsLoading(true);
      refreshData();

      // Automatically sync every 5 seconds so changes on mobile immediately appear on web
      const interval = setInterval(() => {
        refreshData();
      }, 5000);

      return () => clearInterval(interval);
    } else {
      setProducts([]);
      setCategories(DEFAULT_CATEGORIES);
      setCustomers([]);
      setBills([]);
      setPayments([]);
      setStaffList([]);
    }
  }, [currentShop, token, refreshData]);

  // --- Product Operations ---
  const createProduct = async (productData: Omit<Product, 'id' | 'shopId' | 'createdAt' | 'updatedAt'>): Promise<Product> => {
    if (!currentShop) throw new Error('No active shop selected');
    setIsSyncing(true);
    try {
      const res = await api.createProduct(currentShop.id, productData);
      setProducts((prev) => [res.product, ...prev]);
      showToast(`Product "${res.product.name}" added successfully.`, 'success');
      return res.product;
    } catch (err: any) {
      showToast(err.message || 'Failed to add product', 'error');
      throw err;
    } finally {
      setIsSyncing(false);
    }
  };

  const updateProduct = async (id: string, productData: Partial<Product>): Promise<Product> => {
    if (!currentShop) throw new Error('No active shop selected');
    setIsSyncing(true);
    try {
      const res = await api.updateProduct(currentShop.id, id, productData);
      setProducts((prev) => prev.map((p) => (p.id === id ? res.product : p)));
      showToast(`Product updated successfully.`, 'success');
      return res.product;
    } catch (err: any) {
      showToast(err.message || 'Failed to update product', 'error');
      throw err;
    } finally {
      setIsSyncing(false);
    }
  };

  const deleteProduct = async (id: string): Promise<void> => {
    if (!currentShop) throw new Error('No active shop selected');
    setIsSyncing(true);
    try {
      await api.deleteProduct(currentShop.id, id);
      setProducts((prev) => prev.filter((p) => p.id !== id));
      showToast('Product deleted.', 'info');
    } catch (err: any) {
      showToast(err.message || 'Failed to delete product', 'error');
      throw err;
    } finally {
      setIsSyncing(false);
    }
  };

  const updateStock = async (
    productId: string,
    type: 'RESTOCK' | 'ADJUSTMENT' | 'SALE' | 'RETURN',
    quantity: number,
    reason?: string
  ): Promise<void> => {
    if (!currentShop) throw new Error('No active shop selected');
    setIsSyncing(true);
    try {
      const res = await api.updateStock(currentShop.id, productId, { type, quantity, reason });
      setProducts((prev) => prev.map((p) => (p.id === productId ? res.product : p)));
      showToast(`Stock updated: ${type} of ${quantity}`, 'success');
    } catch (err: any) {
      showToast(err.message || 'Failed to update stock', 'error');
      throw err;
    } finally {
      setIsSyncing(false);
    }
  };

  // --- Customer Operations ---
  const createCustomer = async (name: string, mobileNumber: string, address?: string): Promise<Customer> => {
    if (!currentShop) throw new Error('No active shop selected');
    const customerId = uuid();
    const now = Date.now();

    const newCustomer: Customer = {
      id: customerId,
      shopId: currentShop.id,
      name: name.trim(),
      mobileNumber: mobileNumber.trim(),
      address: address?.trim() || null,
      totalPurchasePaise: 0,
      outstandingDuePaise: 0,
      createdAt: now,
      updatedAt: now,
    };

    const op: SyncOperation = {
      id: uuid(),
      entityType: 'CUSTOMER',
      entityId: customerId,
      operationType: 'CREATE',
      payload: JSON.stringify(newCustomer),
      shopId: currentShop.id,
      createdAt: now,
    };

    setIsSyncing(true);
    try {
      await api.pushSync(currentShop.id, [op]);
      setCustomers((prev) => [newCustomer, ...prev]);
      showToast(`Customer "${newCustomer.name}" created.`, 'success');
      return newCustomer;
    } catch (err: any) {
      showToast(err.message || 'Failed to create customer', 'error');
      throw err;
    } finally {
      setIsSyncing(false);
    }
  };

  // --- POS Billing ---
  const createBill = async (
    customerInfo: { id?: string; name: string; mobileNumber: string },
    items: { product: Product; quantity: number }[],
    paymentInfo: { method: 'CASH' | 'UPI' | 'CARD' | 'CREDIT'; paidAmountPaise: number; receivedAmountPaise?: number; changeReturnedPaise?: number }
  ): Promise<Bill> => {
    if (!currentShop) throw new Error('No active shop selected');
    if (items.length === 0) throw new Error('Cannot create empty bill');

    const billId = uuid();
    const now = Date.now();
    // Unique Bill Number (#1001, #1002, ...) identical to mobile app
    const billNumber = generateBillNumber(bills);

    let subtotalPaise = 0;
    const billItems: BillItem[] = items.map((item) => {
      const lineSubtotal = Math.round(item.product.sellingPricePaise * item.quantity);
      subtotalPaise += lineSubtotal;
      return {
        id: uuid(),
        shopId: currentShop.id,
        billId: billId,
        productId: item.product.id,
        productNameSnapshot: item.product.name,
        quantity: item.quantity,
        unit: item.product.unit,
        sellingPricePaise: item.product.sellingPricePaise,
        buyingPricePaise: item.product.buyingPricePaise,
        subtotalPaise: lineSubtotal,
      };
    });

    const grandTotalPaise = subtotalPaise;
    const paidAmount = Math.min(paymentInfo.paidAmountPaise, grandTotalPaise);
    const receivedAmount = paymentInfo.receivedAmountPaise !== undefined ? paymentInfo.receivedAmountPaise : paidAmount;
    const changeReturned = paymentInfo.changeReturnedPaise !== undefined ? paymentInfo.changeReturnedPaise : Math.max(0, receivedAmount - grandTotalPaise);
    const pendingAmount = grandTotalPaise - paidAmount;

    let paymentStatus: 'PAID' | 'PARTIALLY_PAID' | 'PENDING' = 'PAID';
    if (pendingAmount > 0 && paidAmount > 0) {
      paymentStatus = 'PARTIALLY_PAID';
    } else if (pendingAmount === grandTotalPaise) {
      paymentStatus = 'PENDING';
    }

    const newBill: Bill = {
      id: billId,
      shopId: currentShop.id,
      billNumber,
      customerId: customerInfo.id || null,
      customerNameSnapshot: customerInfo.name || 'Walk-in Customer',
      customerMobileSnapshot: customerInfo.mobileNumber || '',
      subtotalPaise,
      grandTotalPaise,
      paidAmountPaise: paidAmount,
      receivedAmountPaise: receivedAmount,
      changeReturnedPaise: changeReturned,
      pendingAmountPaise: pendingAmount,
      paymentMethod: paymentInfo.method,
      paymentStatus,
      items: billItems,
      createdAt: now,
      updatedAt: now,
    };

    const operations: SyncOperation[] = [];

    // 1. Bill operation
    operations.push({
      id: uuid(),
      entityType: 'BILL',
      entityId: billId,
      operationType: 'CREATE',
      payload: JSON.stringify(newBill),
      shopId: currentShop.id,
      createdAt: now,
    });

    // 2. Bill Items operations
    billItems.forEach((bi) => {
      operations.push({
        id: uuid(),
        entityType: 'BILL_ITEM',
        entityId: bi.id,
        operationType: 'CREATE',
        payload: JSON.stringify(bi),
        shopId: currentShop.id,
        createdAt: now,
      });
    });

    // 3. Payment record if paid amount > 0
    if (paidAmount > 0) {
      const paymentRecord: Payment = {
        id: uuid(),
        shopId: currentShop.id,
        billId: billId,
        customerId: customerInfo.id || null,
        amountPaise: paidAmount,
        paymentMethod: paymentInfo.method,
        createdAt: now,
      };
      operations.push({
        id: uuid(),
        entityType: 'PAYMENT',
        entityId: paymentRecord.id,
        operationType: 'CREATE',
        payload: JSON.stringify(paymentRecord),
        shopId: currentShop.id,
        createdAt: now,
      });
      setPayments((prev) => [paymentRecord, ...prev]);
    }

    // 4. Update customer due if customer exists and has pending balance or purchase
    if (customerInfo.id) {
      const matchedCustomer = customers.find((c) => c.id === customerInfo.id);
      if (matchedCustomer) {
        const updatedCustomer: Customer = {
          ...matchedCustomer,
          totalPurchasePaise: matchedCustomer.totalPurchasePaise + grandTotalPaise,
          outstandingDuePaise: matchedCustomer.outstandingDuePaise + pendingAmount,
          updatedAt: now,
        };
        operations.push({
          id: uuid(),
          entityType: 'CUSTOMER',
          entityId: matchedCustomer.id,
          operationType: 'UPDATE',
          payload: JSON.stringify(updatedCustomer),
          shopId: currentShop.id,
          createdAt: now,
        });
        setCustomers((prev) => prev.map((c) => (c.id === customerInfo.id ? updatedCustomer : c)));
      }
    }

    setIsSyncing(true);
    try {
      await api.pushSync(currentShop.id, operations);
      setBills((prev) => [newBill, ...prev]);

      // Deduct sold quantities from local state
      setProducts((prev) =>
        prev.map((p) => {
          const item = items.find((i) => i.product.id === p.id);
          if (item) {
            return { ...p, quantity: Math.max(0, p.quantity - item.quantity) };
          }
          return p;
        })
      );

      showToast(`Bill #${billNumber} generated successfully!`, 'success');
      return newBill;
    } catch (err: any) {
      showToast(err.message || 'Failed to save bill', 'error');
      throw err;
    } finally {
      setIsSyncing(false);
    }
  };

  // --- Record Payment / Clear Customer Due ---
  const recordCustomerPayment = async (customerId: string, amountPaise: number, paymentMethod: 'CASH' | 'UPI' | 'CARD') => {
    if (!currentShop) throw new Error('No active shop selected');
    const customer = customers.find((c) => c.id === customerId);
    if (!customer) throw new Error('Customer not found');

    const paymentId = uuid();
    const now = Date.now();

    const paymentRecord: Payment = {
      id: paymentId,
      shopId: currentShop.id,
      customerId,
      amountPaise,
      paymentMethod,
      createdAt: now,
    };

    const updatedDue = Math.max(0, customer.outstandingDuePaise - amountPaise);
    const updatedCustomer: Customer = {
      ...customer,
      outstandingDuePaise: updatedDue,
      updatedAt: now,
    };

    const operations: SyncOperation[] = [
      {
        id: uuid(),
        entityType: 'PAYMENT',
        entityId: paymentId,
        operationType: 'CREATE',
        payload: JSON.stringify(paymentRecord),
        shopId: currentShop.id,
        createdAt: now,
      },
      {
        id: uuid(),
        entityType: 'CUSTOMER',
        entityId: customerId,
        operationType: 'UPDATE',
        payload: JSON.stringify(updatedCustomer),
        shopId: currentShop.id,
        createdAt: now,
      },
    ];

    setIsSyncing(true);
    try {
      await api.pushSync(currentShop.id, operations);
      setPayments((prev) => [paymentRecord, ...prev]);
      setCustomers((prev) => prev.map((c) => (c.id === customerId ? updatedCustomer : c)));
      showToast('Payment recorded successfully.', 'success');
    } catch (err: any) {
      showToast(err.message || 'Failed to record payment', 'error');
      throw err;
    } finally {
      setIsSyncing(false);
    }
  };

  // --- Staff Operations ---
  const addStaff = async (name: string, mobileNumber: string, password: string, permissions: string[]) => {
    if (!currentShop) throw new Error('No active shop selected');
    setIsSyncing(true);
    try {
      const res = await api.addStaff(currentShop.id, { name, mobileNumber, password, permissions });
      setStaffList((prev) => [...prev, res.staff]);
      showToast(`Staff member "${name}" added.`, 'success');
    } catch (err: any) {
      showToast(err.message || 'Failed to add staff', 'error');
      throw err;
    } finally {
      setIsSyncing(false);
    }
  };

  const deleteStaff = async (staffId: string) => {
    if (!currentShop) throw new Error('No active shop selected');
    setIsSyncing(true);
    try {
      await api.deleteStaff(currentShop.id, staffId);
      setStaffList((prev) => prev.filter((s) => s.staffId !== staffId));
      showToast('Staff member removed.', 'info');
    } catch (err: any) {
      showToast(err.message || 'Failed to remove staff', 'error');
      throw err;
    } finally {
      setIsSyncing(false);
    }
  };

  const addStaffMember = async (data: { name: string; mobileNumber: string; password: string; permissions: string[] }) => {
    return addStaff(data.name, data.mobileNumber, data.password, data.permissions);
  };

  const removeStaffMember = async (staffId: string) => {
    return deleteStaff(staffId);
  };

  const updateStaffRolePermissions = async (staffId: string, permissions: string[]) => {
    if (!currentShop) throw new Error('No active shop selected');
    setIsSyncing(true);
    try {
      await api.updateStaffPermissions(currentShop.id, staffId, permissions);
      setStaffList((prev) =>
        prev.map((s) => (s.staffId === staffId ? { ...s, permissions } : s))
      );
      showToast('Staff permissions updated.', 'success');
    } catch (err: any) {
      showToast(err.message || 'Failed to update permissions', 'error');
      throw err;
    } finally {
      setIsSyncing(false);
    }
  };

  // --- Reset All Testing Data ---
  const resetAllTestingData = async () => {
    setIsSyncing(true);
    try {
      await api.resetAllData();
      setProducts([]);
      setCategories([]);
      setCustomers([]);
      setBills([]);
      setPayments([]);
      setStaffList([]);
      showToast('All testing data permanently deleted from database.', 'success');
    } catch (err: any) {
      showToast(err.message || 'Failed to reset testing data', 'error');
      throw err;
    } finally {
      setIsSyncing(false);
    }
  };

  return (
    <AppContext.Provider
      value={{
        products,
        categories,
        customers,
        bills,
        payments,
        staffList,
        isLoading,
        isSyncing,
        lastSyncedAt,
        toasts,
        showToast,
        refreshData,
        syncData: refreshData,
        createProduct,
        updateProduct,
        deleteProduct,
        updateStock,
        createCustomer,
        createBill,
        recordCustomerPayment,
        addStaff,
        addStaffMember,
        deleteStaff,
        removeStaffMember,
        updateStaffRolePermissions,
        resetAllTestingData,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
