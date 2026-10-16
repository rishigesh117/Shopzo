import React from 'react';
import { Printer, X, CheckCircle, Clock, AlertCircle } from 'lucide-react';
import { Bill } from '../types';
import { useAuth } from '../context/AuthContext';
import { formatMoney, formatDate } from '../utils/format';

interface ReceiptModalProps {
  bill: Bill;
  onClose: () => void;
}

export const ReceiptModal: React.FC<ReceiptModalProps> = ({ bill, onClose }) => {
  const { currentShop } = useAuth();

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '480px' }}>
        {/* Header Actions */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px 20px', borderBottom: '1px solid var(--surface-border)' }}>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Invoice & Receipt</h3>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <button onClick={handlePrint} className="btn btn-primary btn-sm">
              <Printer size={15} /> Print Receipt
            </button>
            <button onClick={onClose} className="btn btn-outline btn-sm btn-icon">
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Printable Receipt Paper */}
        <div id="printable-receipt" style={{ padding: '24px 20px', background: '#ffffff', color: '#0f172a' }}>
          {/* Store Info */}
          <div style={{ textAlign: 'center', borderBottom: '1px dashed #cbd5e1', paddingBottom: '16px', marginBottom: '16px' }}>
            <h2 style={{ fontSize: '1.35rem', fontWeight: 800, textTransform: 'uppercase' }}>
              {currentShop?.name || 'SHOPZO STORE'}
            </h2>
            {currentShop?.address && (
              <p style={{ fontSize: '0.82rem', color: '#64748b', marginTop: '2px' }}>{currentShop.address}</p>
            )}
            <p style={{ fontSize: '0.8rem', color: '#475569', marginTop: '2px', fontWeight: 600 }}>
              Shop Code: {currentShop?.shopCode}
            </p>
          </div>

          {/* Invoice Meta */}
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.82rem', marginBottom: '14px', color: '#475569' }}>
            <div>
              <div><strong>Bill No:</strong> {bill.billNumber}</div>
              <div><strong>Date:</strong> {formatDate(bill.createdAt)}</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div><strong>Customer:</strong> {bill.customerNameSnapshot || 'Walk-in'}</div>
              {bill.customerMobileSnapshot && <div><strong>Mobile:</strong> {bill.customerMobileSnapshot}</div>}
            </div>
          </div>

          {/* Line Items Table */}
          <table style={{ width: '100%', fontSize: '0.85rem', borderCollapse: 'collapse', marginBottom: '16px' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #0f172a', textAlign: 'left' }}>
                <th style={{ padding: '6px 0', background: 'transparent', color: '#0f172a' }}>Item</th>
                <th style={{ padding: '6px 0', textAlign: 'center', background: 'transparent', color: '#0f172a' }}>Qty</th>
                <th style={{ padding: '6px 0', textAlign: 'right', background: 'transparent', color: '#0f172a' }}>Rate</th>
                <th style={{ padding: '6px 0', textAlign: 'right', background: 'transparent', color: '#0f172a' }}>Total</th>
              </tr>
            </thead>
            <tbody>
              {(bill.items || []).map((item, idx) => (
                <tr key={idx} style={{ borderBottom: '1px dashed #e2e8f0' }}>
                  <td style={{ padding: '8px 0', fontWeight: 600 }}>{item.productNameSnapshot}</td>
                  <td style={{ padding: '8px 0', textAlign: 'center' }}>
                    {item.quantity} {item.unit}
                  </td>
                  <td style={{ padding: '8px 0', textAlign: 'right' }}>{formatMoney(item.sellingPricePaise)}</td>
                  <td style={{ padding: '8px 0', textAlign: 'right', fontWeight: 700 }}>
                    {formatMoney(item.subtotalPaise)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Total Breakdown */}
          <div style={{ borderTop: '1px solid #0f172a', paddingTop: '10px', marginBottom: '16px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.88rem', padding: '3px 0' }}>
              <span>Subtotal:</span>
              <span>{formatMoney(bill.subtotalPaise)}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1.15rem', fontWeight: 800, padding: '6px 0', borderTop: '1px dashed #cbd5e1', borderBottom: '1px dashed #cbd5e1' }}>
              <span>Grand Total:</span>
              <span style={{ color: '#2563eb' }}>{formatMoney(bill.grandTotalPaise)}</span>
            </div>
            {bill.receivedAmountPaise !== undefined && bill.receivedAmountPaise > bill.paidAmountPaise && (
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.88rem', padding: '4px 0', color: '#475569' }}>
                <span>Amount Received:</span>
                <span style={{ fontWeight: 700 }}>{formatMoney(bill.receivedAmountPaise)}</span>
              </div>
            )}
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.88rem', padding: '4px 0' }}>
              <span>Amount Paid:</span>
              <span style={{ color: '#059669', fontWeight: 700 }}>{formatMoney(bill.paidAmountPaise)}</span>
            </div>
            {bill.changeReturnedPaise !== undefined && bill.changeReturnedPaise > 0 && (
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.92rem', padding: '5px 0', color: '#0f766e', fontWeight: 800, borderTop: '1px dashed #cbd5e1' }}>
                <span>Change Returned:</span>
                <span>{formatMoney(bill.changeReturnedPaise)}</span>
              </div>
            )}
            {bill.pendingAmountPaise > 0 && (
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.88rem', padding: '4px 0' }}>
                <span style={{ color: '#dc2626', fontWeight: 600 }}>Balance Due (Khata):</span>
                <span style={{ color: '#dc2626', fontWeight: 800 }}>{formatMoney(bill.pendingAmountPaise)}</span>
              </div>
            )}
          </div>

          {/* Payment Status Pill */}
          <div style={{ textAlign: 'center', marginBottom: '16px' }}>
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '4px 14px',
                borderRadius: '9999px',
                fontSize: '0.78rem',
                fontWeight: 800,
                background:
                  bill.paymentStatus === 'PAID'
                    ? '#ecfdf5'
                    : bill.paymentStatus === 'PARTIALLY_PAID'
                    ? '#fffbeb'
                    : '#fef2f2',
                color:
                  bill.paymentStatus === 'PAID'
                    ? '#065f46'
                    : bill.paymentStatus === 'PARTIALLY_PAID'
                    ? '#92400e'
                    : '#991b1b',
              }}
            >
              {bill.paymentStatus === 'PAID' && <CheckCircle size={14} />}
              {bill.paymentStatus === 'PARTIALLY_PAID' && <Clock size={14} />}
              {bill.paymentStatus === 'PENDING' && <AlertCircle size={14} />}
              PAYMENT: {bill.paymentStatus.replace('_', ' ')}
            </span>
          </div>

          {/* Footer Note */}
          <div style={{ textAlign: 'center', borderTop: '1px dashed #cbd5e1', paddingTop: '12px' }}>
            <p style={{ fontSize: '0.8rem', fontWeight: 600 }}>Thank you for shopping with us!</p>
            <p style={{ fontSize: '0.7rem', color: '#94a3b8', marginTop: '2px' }}>Powered by Shopzo Cloud POS</p>
          </div>
        </div>
      </div>
    </div>
  );
};
