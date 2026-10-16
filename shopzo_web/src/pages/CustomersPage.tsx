import React, { useState, useMemo } from 'react';
import { Users, UserPlus, Search, IndianRupee, Phone, CheckCircle2 } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Customer } from '../types';
import { formatMoney, formatDateOnly } from '../utils/format';

interface CustomersPageProps {
  onOpenAddCustomer: () => void;
  onRecordPayment: (customer: Customer) => void;
}

export const CustomersPage: React.FC<CustomersPageProps> = ({ onOpenAddCustomer, onRecordPayment }) => {
  const { customers } = useApp();
  const [search, setSearch] = useState('');

  const filteredCustomers = useMemo(() => {
    return customers.filter(
      (c) =>
        c.name.toLowerCase().includes(search.toLowerCase()) ||
        (c.mobileNumber && c.mobileNumber.includes(search))
    );
  }, [customers, search]);

  const totalOutstandingDue = useMemo(() => {
    return customers.reduce((acc, c) => acc + c.outstandingDuePaise, 0);
  }, [customers]);

  const totalCustomerPurchases = useMemo(() => {
    return customers.reduce((acc, c) => acc + c.totalPurchasePaise, 0);
  }, [customers]);

  return (
    <div className="page-container">
      {/* Page Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1>Customers & Khata Ledger</h1>
          <p>Track customer accounts, credit balances, and payment histories.</p>
        </div>
        <button onClick={onOpenAddCustomer} className="btn btn-primary">
          <UserPlus size={18} /> Add New Customer
        </button>
      </div>

      {/* Summary Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div style={{ background: '#eff6ff', color: 'var(--primary)', padding: '14px', borderRadius: '12px' }}>
            <Users size={26} />
          </div>
          <div>
            <div style={{ fontSize: '1.4rem', fontWeight: 800 }}>{customers.length}</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Registered Customers</div>
          </div>
        </div>

        <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div style={{ background: '#ecfdf5', color: 'var(--success)', padding: '14px', borderRadius: '12px' }}>
            <IndianRupee size={26} />
          </div>
          <div>
            <div style={{ fontSize: '1.4rem', fontWeight: 800 }}>{formatMoney(totalCustomerPurchases)}</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Lifetime Purchases</div>
          </div>
        </div>

        <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div style={{ background: '#fef2f2', color: 'var(--danger)', padding: '14px', borderRadius: '12px' }}>
            <IndianRupee size={26} />
          </div>
          <div>
            <div style={{ fontSize: '1.4rem', fontWeight: 800, color: totalOutstandingDue > 0 ? 'var(--danger)' : 'var(--text-main)' }}>
              {formatMoney(totalOutstandingDue)}
            </div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Total Outstanding Due</div>
          </div>
        </div>
      </div>

      {/* Search Input */}
      <div style={{ position: 'relative', marginBottom: '20px', maxWidth: '420px' }}>
        <Search size={18} style={{ position: 'absolute', left: '12px', top: '12px', color: 'var(--text-subtle)' }} />
        <input
          type="text"
          className="form-input"
          style={{ paddingLeft: '38px' }}
          placeholder="Search by customer name or mobile..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {/* Customers Table */}
      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Customer Name</th>
              <th>Contact Details</th>
              <th>Address</th>
              <th>Total Purchases</th>
              <th>Outstanding Balance (Khata)</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredCustomers.map((c) => {
              const hasDue = c.outstandingDuePaise > 0;
              return (
                <tr key={c.id}>
                  <td>
                    <div style={{ fontWeight: 700, fontSize: '0.95rem' }}>{c.name}</div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                      Joined: {formatDateOnly(c.createdAt)}
                    </div>
                  </td>
                  <td>
                    {c.mobileNumber ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.88rem' }}>
                        <Phone size={14} color="var(--text-subtle)" />
                        <span>{c.mobileNumber}</span>
                      </div>
                    ) : (
                      <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>—</span>
                    )}
                  </td>
                  <td>
                    <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                      {c.address || '—'}
                    </span>
                  </td>
                  <td>
                    <span style={{ fontWeight: 600 }}>{formatMoney(c.totalPurchasePaise)}</span>
                  </td>
                  <td>
                    {hasDue ? (
                      <span className="badge badge-danger" style={{ fontSize: '0.85rem' }}>
                        Due: {formatMoney(c.outstandingDuePaise)}
                      </span>
                    ) : (
                      <span className="badge badge-success" style={{ fontSize: '0.8rem' }}>
                        <CheckCircle2 size={13} /> No Dues
                      </span>
                    )}
                  </td>
                  <td>
                    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
                      {hasDue ? (
                        <button
                          onClick={() => onRecordPayment(c)}
                          className="btn btn-primary btn-sm"
                        >
                          <IndianRupee size={14} /> Clear Dues
                        </button>
                      ) : (
                        <button
                          onClick={() => onRecordPayment(c)}
                          className="btn btn-outline btn-sm"
                        >
                          Record Payment
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              );
            })}
            {filteredCustomers.length === 0 && (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-muted)' }}>
                  No customer records found. Click "Add New Customer" or create one during checkout!
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
