import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { User, Shop } from '../types';
import { api } from '../api/client';

interface AuthContextType {
  user: User | null;
  shops: Shop[];
  currentShop: Shop | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (mobileNumber: string, password: string) => Promise<void>;
  register: (name: string, mobileNumber: string, password: string) => Promise<void>;
  resetPassword: (mobileNumber: string, newPassword: string) => Promise<void>;
  createShop: (name: string, address?: string) => Promise<Shop>;
  selectShop: (shop: Shop) => void;
  switchShop: (shopId: string) => void;
  refreshShops: () => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(() => {
    try {
      const saved = localStorage.getItem('shopzo_user');
      return saved ? JSON.parse(saved) : null;
    } catch {
      return null;
    }
  });

  const [shops, setShops] = useState<Shop[]>(() => {
    try {
      const saved = localStorage.getItem('shopzo_shops');
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });

  const [currentShop, setCurrentShop] = useState<Shop | null>(() => {
    try {
      const saved = localStorage.getItem('shopzo_shops');
      const list: Shop[] = saved ? JSON.parse(saved) : [];
      const savedId = localStorage.getItem('shopzo_shop_id');
      return list.find((s) => s.id === savedId) || list[0] || null;
    } catch {
      return null;
    }
  });

  const [token, setToken] = useState<string | null>(localStorage.getItem('shopzo_token'));
  const [isLoading, setIsLoading] = useState<boolean>(!user && !!token);

  // Initialize and validate session from token in background
  useEffect(() => {
    async function initSession() {
      const savedToken = localStorage.getItem('shopzo_token');
      if (!savedToken) {
        setIsLoading(false);
        return;
      }

      try {
        const { user } = await api.getMe();
        setUser(user);
        localStorage.setItem('shopzo_user', JSON.stringify(user));

        const { shops } = await api.getMyShops();
        setShops(shops);
        localStorage.setItem('shopzo_shops', JSON.stringify(shops));

        const savedShopId = localStorage.getItem('shopzo_shop_id');
        const matched = shops.find((s) => s.id === savedShopId) || shops[0] || null;
        if (matched) {
          setCurrentShop(matched);
          localStorage.setItem('shopzo_shop_id', matched.id);
        }
      } catch (err) {
        console.warn('Session expired or invalid, clearing local session.');
        localStorage.removeItem('shopzo_token');
        localStorage.removeItem('shopzo_shop_id');
        localStorage.removeItem('shopzo_user');
        localStorage.removeItem('shopzo_shops');
        localStorage.removeItem('shopzo_active_tab');
        setToken(null);
        setUser(null);
        setCurrentShop(null);
        setShops([]);
      } finally {
        setIsLoading(false);
      }
    }

    initSession();
  }, []);

  const login = async (mobileNumber: string, password: string) => {
    setIsLoading(true);
    try {
      const res = await api.login(mobileNumber, password);
      localStorage.setItem('shopzo_token', res.token);
      localStorage.setItem('shopzo_user', JSON.stringify(res.user));
      localStorage.setItem('shopzo_shops', JSON.stringify(res.shops));
      setToken(res.token);
      setUser(res.user);
      setShops(res.shops);

      const targetShop = res.shops[0] || null;
      if (targetShop) {
        setCurrentShop(targetShop);
        localStorage.setItem('shopzo_shop_id', targetShop.id);
      }
    } finally {
      setIsLoading(false);
    }
  };

  const register = async (name: string, mobileNumber: string, password: string) => {
    setIsLoading(true);
    try {
      const res = await api.register(name, mobileNumber, password);
      localStorage.setItem('shopzo_token', res.token);
      localStorage.setItem('shopzo_user', JSON.stringify(res.user));
      setToken(res.token);
      setUser(res.user);
      setShops([]);
      setCurrentShop(null);
    } finally {
      setIsLoading(false);
    }
  };

  const resetPassword = async (mobileNumber: string, newPassword: string) => {
    await api.resetPassword(mobileNumber, newPassword);
  };

  const createShop = async (name: string, address?: string): Promise<Shop> => {
    setIsLoading(true);
    try {
      const res = await api.createShop(name, address);
      const newShop = res.shop;
      const updatedShops = [...shops, newShop];
      setShops(updatedShops);
      localStorage.setItem('shopzo_shops', JSON.stringify(updatedShops));
      setCurrentShop(newShop);
      localStorage.setItem('shopzo_shop_id', newShop.id);
      return newShop;
    } finally {
      setIsLoading(false);
    }
  };

  const selectShop = (shop: Shop) => {
    setCurrentShop(shop);
    localStorage.setItem('shopzo_shop_id', shop.id);
  };

  const refreshShops = async () => {
    if (!token) return;
    try {
      const { shops } = await api.getMyShops();
      setShops(shops);
      localStorage.setItem('shopzo_shops', JSON.stringify(shops));
      if (currentShop) {
        const updated = shops.find((s) => s.id === currentShop.id);
        if (updated) setCurrentShop(updated);
      }
    } catch (_) {}
  };

  const logout = () => {
    localStorage.removeItem('shopzo_token');
    localStorage.removeItem('shopzo_shop_id');
    localStorage.removeItem('shopzo_user');
    localStorage.removeItem('shopzo_shops');
    localStorage.removeItem('shopzo_active_tab');
    window.location.hash = '';
    setToken(null);
    setUser(null);
    setCurrentShop(null);
    setShops([]);
  };

  const switchShop = (shopId: string) => {
    const target = shops.find((s) => s.id === shopId);
    if (target) {
      setCurrentShop(target);
      localStorage.setItem('shopzo_shop_id', target.id);
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        shops,
        currentShop,
        token,
        isAuthenticated: !!user && !!token,
        isLoading,
        login,
        register,
        resetPassword,
        createShop,
        selectShop,
        switchShop,
        refreshShops,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
