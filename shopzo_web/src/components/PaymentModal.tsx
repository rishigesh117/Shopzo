import React, { useState } from 'react';
import { X, CreditCard, Banknote, QrCode } from 'lucide-react';
import { Customer } from '../types';
import { formatMoney, parseMoneyToPaise } from '../utils/format';

interface PaymentModalProps {
  customer: Customer;
  onSave: (amountPaise: number, method: 'CASH' | 'UPI' | 'CARD') => Promise<void>;
  onClose: () => void;
}

export const PaymentModal: React.FC<PaymentModalProps> = ({ customer, onSave, onClose }) => {
  const [amount, setAmount] = useState((customer.outstandingDuePaise / 100).toString());
  const [method, setMethod] = useState<'CASH' | 'UPI' | 'CARD'>('CASH');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const parsed = parseFloat(amount);
    if (isNaN(parsed) || parsed <= 0) {
      setError('Please enter a valid payment amount greater than zero');
      return;
    }

    setIsSubmitting(true);
    setError(null);
    try {
      await onSave(parseMoneyToPaise(parsed), method);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Failed to record payment');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '440px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '18px 24px', borderBottom: '1px solid var(--surface-border)' }}>
          <div>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700 }}>Record Payment</h3>
            <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Customer: {customer.name}</p>
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

          {/* Due Info Card */}
          <div style={{ padding: '14px', background: 'var(--surface-raised)', borderRadius: 'var(--radius-md)', marginBottom: '18px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Current Due:</span>
            <span style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--danger)' }}>
              {formatMoney(customer.outstandingDuePaise)}
            </span>
          </div>

          <div className="form-group">
            <label className="form-label">Payment Amount (₹) *</label>
            <input
              type="number"
              step="0.01"
              min="0.01"
              className="form-input"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Payment Mode</label>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '8px' }}>
              <button
                type="button"
                onClick={() => setMethod('CASH')}
                style={{
                  padding: '10px 8px',
                  borderRadius: 'var(--radius-md)',
                  border: `2px solid ${method === 'CASH' ? 'var(--primary)' : 'var(--surface-border)'}`,
                  background: method === 'CASH' ? 'var(--primary-light)' : 'var(--surface)',
                  color: method === 'CASH' ? 'var(--primary)' : 'var(--text-main)',
                  fontWeight: 600,
                  fontSize: '0.82rem',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: '4px',
                }}
              >
                <Banknote size={18} />
                Cash
              </button>

              <button
                type="button"
                onClick={() => setMethod('UPI')}
                style={{
                  padding: '10px 8px',
                  borderRadius: 'var(--radius-md)',
                  border: `2px solid ${method === 'UPI' ? 'var(--primary)' : 'var(--surface-border)'}`,
                  background: method === 'UPI' ? 'var(--primary-light)' : 'var(--surface)',
                  color: method === 'UPI' ? 'var(--primary)' : 'var(--text-main)',
                  fontWeight: 600,
                  fontSize: '0.82rem',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: '4px',
                }}
              >
                <QrCode size={18} />
                UPI
              </button>

              <button
                type="button"
                onClick={() => setMethod('CARD')}
                style={{
                  padding: '10px 8px',
                  borderRadius: 'var(--radius-md)',
                  border: `2px solid ${method === 'CARD' ? 'var(--primary)' : 'var(--surface-border)'}`,
                  background: method === 'CARD' ? 'var(--primary-light)' : 'var(--surface)',
                  color: method === 'CARD' ? 'var(--primary)' : 'var(--text-main)',
                  fontWeight: 600,
                  fontSize: '0.82rem',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: '4px',
                }}
              >
                <CreditCard size={18} />
                Card
              </button>
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '24px' }}>
            <button type="button" onClick={onClose} className="btn btn-outline">
              Cancel
            </button>
            <button type="submit" disabled={isSubmitting} className="btn btn-primary">
              {isSubmitting ? 'Recording...' : 'Confirm Payment'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
