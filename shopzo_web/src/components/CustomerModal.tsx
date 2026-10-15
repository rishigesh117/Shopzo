import React, { useState } from 'react';
import { X, UserPlus } from 'lucide-react';

interface CustomerModalProps {
  onSave: (name: string, mobileNumber: string, address?: string) => Promise<any>;
  onClose: () => void;
}

export const CustomerModal: React.FC<CustomerModalProps> = ({ onSave, onClose }) => {
  const [name, setName] = useState('');
  const [mobileNumber, setMobileNumber] = useState('');
  const [address, setAddress] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Customer name is required');
      return;
    }
    const cleanMobile = mobileNumber.replace(/\D/g, '');
    if (cleanMobile.length < 10) {
      setError('Please enter a valid 10-digit mobile number');
      return;
    }

    setIsSubmitting(true);
    setError(null);
    try {
      await onSave(name.trim(), cleanMobile, address.trim() || undefined);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Failed to create customer');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '440px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '18px 24px', borderBottom: '1px solid var(--surface-border)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <UserPlus size={20} color="var(--primary)" />
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700 }}>Add Customer</h3>
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
            <label className="form-label">Customer Name *</label>
            <input
              type="text"
              className="form-input"
              placeholder="e.g. Ramesh Kumar"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Mobile Number *</label>
            <input
              type="tel"
              maxLength={10}
              className="form-input"
              placeholder="e.g. 9876543210"
              value={mobileNumber}
              onChange={(e) => setMobileNumber(e.target.value)}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Address (Optional)</label>
            <textarea
              rows={2}
              className="form-textarea"
              placeholder="Street, City, Area"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '20px' }}>
            <button type="button" onClick={onClose} className="btn btn-outline">
              Cancel
            </button>
            <button type="submit" disabled={isSubmitting} className="btn btn-primary">
              {isSubmitting ? 'Saving...' : 'Add Customer'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
