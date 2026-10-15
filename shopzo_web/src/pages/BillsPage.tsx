import React, { useState, useMemo } from 'react';
import { 
  Receipt, 
  Search, 
  Eye, 
  Download, 
  CreditCard, 
  IndianRupee 
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Bill } from '../types';
import { formatMoney, formatDate } from '../utils/format';
import { ReceiptModal } from '../components/ReceiptModal';

export const BillsPage: React.FC = () => {
  const { bills } = useApp();
  const [searchTerm, setSearchTerm] = useState('');
  const [methodFilter, setMethodFilter] = useState<string>('ALL');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [viewingBill, setViewingBill] = useState<Bill | null>(null);

  // Filter bills
  const filteredBills = useMemo(() => {
    return bills.filter((bill) => {
      const custName = bill.customerNameSnapshot || bill.customerName || '';
      const custPhone = bill.customerMobileSnapshot || bill.customerPhone || '';
      const method = bill.paymentMethod || 'CASH';

      // Search matching
      const matchesSearch = 
        bill.billNumber.toLowerCase().includes(searchTerm.toLowerCase()) ||
        custName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        custPhone.includes(searchTerm);

      // Method matching
      const matchesMethod = 
        methodFilter === 'ALL' || 
        method.toUpperCase() === methodFilter.toUpperCase();

      // Status matching
      const matchesStatus = 
        statusFilter === 'ALL' || 
        bill.paymentStatus.toUpperCase() === statusFilter.toUpperCase();

      return matchesSearch && matchesMethod && matchesStatus;
    }).sort((a, b) => b.createdAt - a.createdAt);
  }, [bills, searchTerm, methodFilter, statusFilter]);

  // Aggregate stats
  const totalRevenue = useMemo(() => {
    return bills.reduce((acc, b) => acc + (b.grandTotalPaise || b.totalAmount || 0), 0);
  }, [bills]);

  const totalCreditDue = useMemo(() => {
    return bills.reduce((acc, b) => {
      const total = b.grandTotalPaise || b.totalAmount || 0;
      const paid = b.paidAmountPaise || b.paidAmount || 0;
      const due = total - paid;
      return acc + (due > 0 ? due : 0);
    }, 0);
  }, [bills]);

  return (
    <div className="page-container">
      {/* Top Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800, letterSpacing: '-0.02em', color: 'var(--text-primary)' }}>
            Sales & Invoices
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', marginTop: '4px' }}>
            Browse transaction history, inspect item breakdowns, and reprint receipts
          </p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <button 
            onClick={() => {
              const csvContent = "data:text/csv;charset=utf-8," + 
                ["Bill No,Date,Customer,Total (Rs),Paid (Rs),Payment Method,Status"]
                .concat(filteredBills.map(b => {
                  const cust = b.customerNameSnapshot || b.customerName || 'Walk-in';
                  const tot = ((b.grandTotalPaise || b.totalAmount || 0)/100).toFixed(2);
                  const paid = ((b.paidAmountPaise || b.paidAmount || 0)/100).toFixed(2);
                  const meth = b.paymentMethod || 'CASH';
                  return `"${b.billNumber}","${formatDate(b.createdAt)}","${cust}","${tot}","${paid}","${meth}","${b.paymentStatus}"`;
                })).join("\n");
              const encodedUri = encodeURI(csvContent);
              const link = document.createElement("a");
              link.setAttribute("href", encodedUri);
              link.setAttribute("download", `Shopzo_Bills_${new Date().toISOString().split('T')[0]}.csv`);
              document.body.appendChild(link);
              link.click();
              document.body.removeChild(link);
            }}
            className="btn btn-outline"
          >
            <Download size={16} /> Export CSV
          </button>
        </div>
      </div>

      {/* Overview Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        <div className="card" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '42px', height: '42px', borderRadius: '10px', background: 'rgba(99, 102, 241, 0.12)', color: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Receipt size={22} />
            </div>
            <div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Total Invoices</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 800 }}>{bills.length}</div>
            </div>
          </div>
        </div>

        <div className="card" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '42px', height: '42px', borderRadius: '10px', background: 'rgba(16, 185, 129, 0.12)', color: 'var(--success)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <IndianRupee size={22} />
            </div>
            <div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Total Billed</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 800 }}>{formatMoney(totalRevenue)}</div>
            </div>
          </div>
        </div>

        <div className="card" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '42px', height: '42px', borderRadius: '10px', background: 'rgba(245, 158, 11, 0.12)', color: 'var(--warning)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <CreditCard size={22} />
            </div>
            <div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Khata / Unpaid Credit</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 800, color: totalCreditDue > 0 ? 'var(--warning)' : 'inherit' }}>
                {formatMoney(totalCreditDue)}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="card" style={{ padding: '16px', marginBottom: '20px' }}>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '12px', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flex: '1', minWidth: '260px' }}>
            <div className="search-bar" style={{ width: '100%' }}>
              <Search size={18} style={{ color: 'var(--text-secondary)', marginLeft: '12px' }} />
              <input 
                type="text"
                placeholder="Search by bill #, customer name, or phone..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  background: 'transparent',
                  border: 'none',
                  color: 'var(--text-primary)',
                  fontSize: '0.9rem',
                  outline: 'none'
                }}
              />
            </div>
          </div>

          <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
            {/* Payment Method Filter */}
            <select
              value={methodFilter}
              onChange={(e) => setMethodFilter(e.target.value)}
              className="form-control"
              style={{ width: 'auto', minWidth: '130px', fontSize: '0.85rem' }}
            >
              <option value="ALL">All Payments</option>
              <option value="CASH">Cash Only</option>
              <option value="UPI">UPI Only</option>
              <option value="CARD">Card Only</option>
              <option value="KHATA">Khata / Credit</option>
              <option value="SPLIT">Split</option>
            </select>

            {/* Status Filter */}
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="form-control"
              style={{ width: 'auto', minWidth: '130px', fontSize: '0.85rem' }}
            >
              <option value="ALL">All Statuses</option>
              <option value="PAID">Fully Paid</option>
              <option value="PARTIAL">Partially Paid</option>
              <option value="UNPAID">Unpaid</option>
            </select>
          </div>
        </div>
      </div>

      {/* Invoices List / Table */}
      <div className="card" style={{ overflow: 'hidden' }}>
        {filteredBills.length === 0 ? (
          <div style={{ padding: '48px 20px', textAlign: 'center', color: 'var(--text-secondary)' }}>
            <Receipt size={48} style={{ opacity: 0.3, marginBottom: '12px' }} />
            <h3 style={{ fontSize: '1.1rem', fontWeight: 600, color: 'var(--text-primary)' }}>No invoices found</h3>
            <p style={{ fontSize: '0.85rem', marginTop: '4px' }}>
              {searchTerm || methodFilter !== 'ALL' || statusFilter !== 'ALL'
                ? 'Try adjusting your filters or search keyword'
                : 'Process your first transaction on the POS Terminal'}
            </p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--surface-border)', background: 'var(--surface-color)', color: 'var(--text-secondary)', fontSize: '0.8rem', textTransform: 'uppercase' }}>
                  <th style={{ padding: '14px 16px' }}>Invoice</th>
                  <th style={{ padding: '14px 16px' }}>Date & Time</th>
                  <th style={{ padding: '14px 16px' }}>Customer</th>
                  <th style={{ padding: '14px 16px' }}>Items</th>
                  <th style={{ padding: '14px 16px' }}>Method</th>
                  <th style={{ padding: '14px 16px' }}>Status</th>
                  <th style={{ padding: '14px 16px', textAlign: 'right' }}>Total</th>
                  <th style={{ padding: '14px 16px', textAlign: 'center' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredBills.map((bill) => {
                  const isPaid = bill.paymentStatus === 'PAID';
                  const isPartial = bill.paymentStatus === 'PARTIALLY_PAID';
                  const customerName = bill.customerNameSnapshot || bill.customerName || 'Walk-in Customer';
                  const customerPhone = bill.customerMobileSnapshot || bill.customerPhone;
                  const totalAmount = bill.grandTotalPaise || bill.totalAmount || 0;
                  const method = bill.paymentMethod || 'CASH';
                  
                  return (
                    <tr 
                      key={bill.id} 
                      style={{ borderBottom: '1px solid var(--surface-border)', transition: 'background 0.15s ease' }}
                    >
                      <td style={{ padding: '14px 16px', fontWeight: 700, fontFamily: 'monospace' }}>
                        {bill.billNumber}
                      </td>
                      <td style={{ padding: '14px 16px', fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                        {formatDate(bill.createdAt)}
                      </td>
                      <td style={{ padding: '14px 16px' }}>
                        <div style={{ fontWeight: 600 }}>{customerName}</div>
                        {customerPhone && (
                          <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{customerPhone}</div>
                        )}
                      </td>
                      <td style={{ padding: '14px 16px', fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                        {bill.items?.length || 0} item{(bill.items?.length || 0) === 1 ? '' : 's'}
                      </td>
                      <td style={{ padding: '14px 16px' }}>
                        <span className="badge badge-info" style={{ textTransform: 'uppercase', fontSize: '0.72rem' }}>
                          {method}
                        </span>
                      </td>
                      <td style={{ padding: '14px 16px' }}>
                        <span className={`badge ${isPaid ? 'badge-success' : isPartial ? 'badge-warning' : 'badge-danger'}`} style={{ fontSize: '0.72rem' }}>
                          {bill.paymentStatus}
                        </span>
                      </td>
                      <td style={{ padding: '14px 16px', textAlign: 'right', fontWeight: 700, fontSize: '0.95rem' }}>
                        {formatMoney(totalAmount)}
                      </td>
                      <td style={{ padding: '14px 16px', textAlign: 'center' }}>
                        <div style={{ display: 'flex', gap: '8px', justifyContent: 'center' }}>
                          <button
                            onClick={() => setViewingBill(bill)}
                            className="btn btn-outline btn-sm btn-icon"
                            title="View / Print Receipt"
                          >
                            <Eye size={15} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Printable Receipt Modal */}
      {viewingBill && (
        <ReceiptModal 
          bill={viewingBill} 
          onClose={() => setViewingBill(null)} 
        />
      )}
    </div>
  );
};
