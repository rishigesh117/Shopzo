export interface User {
  id: string;
  mobileNumber: string;
  name: string;
  role?: string;
  shopId?: string;
  createdAt?: number;
}

export interface Shop {
  id: string;
  shopCode: string;
  name: string;
  ownerId: string;
  ownerName?: string;
  ownerMobile?: string;
  address?: string | null;
  role?: 'OWNER' | 'STAFF' | string;
  createdAt?: number;
  updatedAt?: number;
}

export interface Category {
  id: string;
  shopId: string;
  name: string;
  createdAt: number;
  updatedAt?: number;
  deleted?: boolean;
}

export interface Product {
  id: string;
  shopId: string;
  categoryId: string;
  name: string;
  brand?: string | null;
  buyingPricePaise: number;
  sellingPricePaise: number;
  quantity: number;
  unit: string;
  minStockLevel: number;
  createdAt: number;
  updatedAt?: number;
  deleted?: boolean;
}

export interface Customer {
  id: string;
  shopId: string;
  name: string;
  mobileNumber: string;
  address?: string | null;
  totalPurchasePaise: number;
  outstandingDuePaise: number;
  createdAt: number;
  updatedAt?: number;
  deleted?: boolean;
}

export interface BillItem {
  id: string;
  shopId: string;
  billId: string;
  productId: string;
  productNameSnapshot: string;
  productName?: string;
  quantity: number;
  unit: string;
  sellingPricePaise: number;
  unitPrice?: number;
  buyingPricePaise: number;
  subtotalPaise: number;
  total?: number;
}

export interface Bill {
  id: string;
  shopId: string;
  billNumber: string;
  customerId?: string | null;
  customerNameSnapshot: string;
  customerName?: string;
  customerMobileSnapshot: string;
  customerPhone?: string;
  subtotalPaise: number;
  grandTotalPaise: number;
  totalAmount?: number;
  paidAmountPaise: number;
  paidAmount?: number;
  pendingAmountPaise: number;
  paymentMethod?: string;
  paymentStatus: 'PAID' | 'PARTIALLY_PAID' | 'PENDING';
  items?: BillItem[];
  createdAt: number;
  updatedAt?: number;
}

export interface Payment {
  id: string;
  shopId: string;
  billId?: string | null;
  customerId?: string | null;
  amountPaise: number;
  paymentMethod: 'CASH' | 'UPI' | 'CARD' | 'CREDIT';
  createdAt: number;
}

export interface Staff {
  staffId: string;
  userId: string;
  name: string;
  mobileNumber: string;
  role: 'OWNER' | 'STAFF';
  permissions: string[];
}

export interface SyncOperation {
  id: string;
  entityType: 'PRODUCT' | 'CATEGORY' | 'CUSTOMER' | 'BILL' | 'PAYMENT' | 'RETURN';
  entityId: string;
  operationType: 'CREATE' | 'UPDATE' | 'DELETE';
  payload: string;
  shopId: string;
  createdAt: number;
}

export interface CartItem {
  product: Product;
  quantity: number;
  unitPricePaise: number;
  subtotalPaise: number;
}
