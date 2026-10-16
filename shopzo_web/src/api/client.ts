import { User, Shop, Product, Category, Customer, Bill, BillItem, Payment, Staff, SyncOperation } from '../types';

const DEFAULT_API_URL = 'https://shopzo-nine.vercel.app';

export class ApiClient {
  private baseUrl: string;

  constructor() {
    let saved = localStorage.getItem('shopzo_api_url');
    // Clear legacy localhost backend override so web uses the unified cloud backend
    if (saved && (saved.includes('localhost') || saved.includes('127.0.0.1') || saved.includes(':3000'))) {
      saved = null;
      localStorage.removeItem('shopzo_api_url');
    }

    this.baseUrl = saved || import.meta.env.VITE_API_URL || DEFAULT_API_URL;
    // Strip trailing slash
    if (this.baseUrl.endsWith('/')) {
      this.baseUrl = this.baseUrl.slice(0, -1);
    }
  }

  getBaseUrl(): string {
    return this.baseUrl;
  }

  setBaseUrl(url: string) {
    let clean = url.trim();
    if (clean.endsWith('/')) clean = clean.slice(0, -1);
    this.baseUrl = clean;
    localStorage.setItem('shopzo_api_url', clean);
  }

  private getToken(): string | null {
    return localStorage.getItem('shopzo_token');
  }

  private getShopId(): string | null {
    return localStorage.getItem('shopzo_shop_id');
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const url = `${this.baseUrl}${endpoint.startsWith('/') ? endpoint : '/' + endpoint}`;
    const token = this.getToken();
    const shopId = this.getShopId();

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string> || {}),
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    if (shopId) {
      headers['X-Shop-Id'] = shopId;
    }

    const response = await fetch(url, {
      ...options,
      headers,
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      const errorMsg = data.error || data.message || `Request failed with status ${response.status}`;
      throw new Error(errorMsg);
    }

    return data as T;
  }

  // --- Auth APIs ---
  async register(name: string, mobileNumber: string, password: string): Promise<{ token: string; user: User }> {
    return this.request('/api/auth/register', {
      method: 'POST',
      body: JSON.stringify({ name, mobileNumber, password }),
    });
  }

  async login(mobileNumber: string, password: string): Promise<{ token: string; user: User; shops: Shop[] }> {
    return this.request('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ mobileNumber, password }),
    });
  }

  async resetPassword(mobileNumber: string, newPassword: string): Promise<{ message: string }> {
    return this.request('/api/auth/reset-password', {
      method: 'POST',
      body: JSON.stringify({ mobileNumber, newPassword }),
    });
  }

  async getMe(): Promise<{ user: User }> {
    return this.request('/api/auth/me');
  }

  // --- Shop APIs ---
  async createShop(name: string, address?: string): Promise<{ shop: Shop }> {
    return this.request('/api/shops', {
      method: 'POST',
      body: JSON.stringify({ name, address: address?.trim() || null }),
    });
  }

  async getMyShops(): Promise<{ shops: Shop[] }> {
    return this.request('/api/shops/my-shops');
  }

  async getShopById(shopId: string): Promise<{ shop: Shop }> {
    return this.request(`/api/shops/${shopId}`);
  }

  // --- Staff APIs ---
  async getStaff(shopId: string): Promise<{ staff: Staff[] }> {
    return this.request(`/api/shops/${shopId}/staff`);
  }

  async addStaff(shopId: string, staff: { name: string; mobileNumber: string; password: string; permissions: string[] }): Promise<{ staff: Staff }> {
    return this.request(`/api/shops/${shopId}/staff`, {
      method: 'POST',
      body: JSON.stringify(staff),
    });
  }

  async updateStaffPermissions(shopId: string, staffId: string, permissions: string[]): Promise<void> {
    await this.request(`/api/shops/${shopId}/staff/${staffId}/permissions`, {
      method: 'PUT',
      body: JSON.stringify({ permissions }),
    });
  }

  async deleteStaff(shopId: string, staffId: string): Promise<void> {
    await this.request(`/api/shops/${shopId}/staff/${staffId}`, {
      method: 'DELETE',
    });
  }

  // --- Product & Category APIs ---
  async getProducts(shopId: string): Promise<{ products: Product[]; categories: Category[] }> {
    return this.request(`/api/shops/${shopId}/products`);
  }

  async createProduct(shopId: string, product: Omit<Product, 'id' | 'shopId' | 'createdAt' | 'updatedAt'>): Promise<{ product: Product }> {
    return this.request(`/api/shops/${shopId}/products`, {
      method: 'POST',
      body: JSON.stringify(product),
    });
  }

  async updateProduct(shopId: string, productId: string, product: Partial<Product>): Promise<{ product: Product }> {
    return this.request(`/api/shops/${shopId}/products/${productId}`, {
      method: 'PUT',
      body: JSON.stringify(product),
    });
  }

  async deleteProduct(shopId: string, productId: string): Promise<void> {
    await this.request(`/api/shops/${shopId}/products/${productId}`, {
      method: 'DELETE',
    });
  }

  async updateStock(
    shopId: string,
    productId: string,
    movement: { type: 'RESTOCK' | 'ADJUSTMENT' | 'SALE' | 'RETURN'; quantity: number; reason?: string }
  ): Promise<{ product: Product }> {
    return this.request(`/api/shops/${shopId}/products/${productId}/stock`, {
      method: 'POST',
      body: JSON.stringify(movement),
    });
  }

  // --- Sync (Bills, Customers, Payments, Line items) ---
  async pullData(_shopId: string, since: number = 0): Promise<{
    serverTime: number;
    categories: Category[];
    products: Product[];
    customers: Customer[];
    bills: Bill[];
    billItems: BillItem[];
    payments: Payment[];
    returns: any[];
  }> {
    const res = await this.request<any>(`/api/sync/pull?since=${since}`);
    if (res && res.delta) {
      return {
        serverTime: res.serverTime || Date.now(),
        categories: res.delta.categories || [],
        products: res.delta.products || [],
        customers: res.delta.customers || [],
        bills: res.delta.bills || [],
        billItems: res.delta.billItems || [],
        payments: res.delta.payments || [],
        returns: res.delta.returns || [],
      };
    }
    return {
      serverTime: res?.serverTime || Date.now(),
      categories: res?.categories || [],
      products: res?.products || [],
      customers: res?.customers || [],
      bills: res?.bills || [],
      billItems: res?.billItems || [],
      payments: res?.payments || [],
      returns: res?.returns || [],
    };
  }

  async pushSync(_shopId: string, operations: SyncOperation[]): Promise<{ syncedIds: string[]; serverTime: number }> {
    return this.request('/api/sync/push', {
      method: 'POST',
      body: JSON.stringify({ shopId: _shopId, operations }),
    });
  }

  // --- Admin / Reset Testing Data ---
  async resetAllData(): Promise<{ success: boolean; message: string }> {
    return this.request('/api/admin/reset-all-data', {
      method: 'POST',
    });
  }
}

export const api = new ApiClient();
