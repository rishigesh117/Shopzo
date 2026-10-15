import React, { useState } from 'react';
import { X, Store } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

interface CreateShopModalProps {
  onClose: () => void;
}

export const CreateShopModal: React.FC<CreateShopModalProps> = ({ onClose }) => {
  const { createShop } = useAuth();
  const [name, setName] = useState('');
  const [address, setAddress] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Shop name is required');
      return;
    }

    setIsSubmitting(true);
    setError(null);
    try {
      await createShop(name.trim(), address.trim() || undefined);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Failed to create shop');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '440px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '18px 24px', borderBottom: '1px solid var(--surface-border)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Store size={20} color="var(--primary)" />
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700 }}>Create Store</h3>
          </div>
          <button onClick={onClose} className="btn btn-outline btn-sm btn-icon">
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ padding: '24px' }}>
          {error && (
            <div style={{ padding: '10px 14px', background: 'var(--danger-light)', color: 'var(--danger-dark)', borderRadius: 'var(--radius-md)', marginBottom: '16px', fontSize: '0.85rem' }}>
              {error}
            </div>
          )}

          <div className="form-group">
            <label className="form-label">Shop / Store Name *</label>
            <input
              type="text"
              className="form-input"
              placeholder="e.g. Shopzo Supermarket"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Store Address (Optional)</label>
            <textarea
              rows={2}
              className="form-textarea"
              placeholder="Shop No., Street, City, Pincode"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '24px' }}>
            <button type="button" onClick={onClose} className="btn btn-outline">
              Cancel
            </button>
            <button type="submit" disabled={isSubmitting} className="btn btn-primary">
              {isSubmitting ? 'Creating...' : 'Create Shop'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
