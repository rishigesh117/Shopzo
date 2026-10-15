import React, { useState } from 'react';
import { 
  UserPlus, 
  ShieldCheck, 
  Key, 
  Trash2, 
  Phone, 
  X
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useApp } from '../context/AppContext';
import { Staff } from '../types';

const AVAILABLE_PERMISSIONS = [
  { id: 'BILLING_CREATE', label: 'POS Billing', desc: 'Can process sales and issue invoices' },
  { id: 'INVENTORY_ADD', label: 'Add Products', desc: 'Can add new catalog items & inventory' },
  { id: 'INVENTORY_EDIT', label: 'Edit Products & Stock', desc: 'Can update prices, names, and stock levels' },
  { id: 'INVENTORY_DELETE', label: 'Delete Products', desc: 'Can remove products from store catalog' },
  { id: 'REPORTS_VIEW', label: 'View Reports & Analytics', desc: 'Can inspect revenue, margins, and sales stats' },
  { id: 'TEAM_MANAGE', label: 'Manage Staff Members', desc: 'Can invite or remove other staff members' },
];

export const StaffPage: React.FC = () => {
  const { user } = useAuth();
  const { staffList, addStaffMember, removeStaffMember, updateStaffRolePermissions, showToast } = useApp();

  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingStaff, setEditingStaff] = useState<Staff | null>(null);

  // Form State
  const [name, setName] = useState('');
  const [mobileNumber, setMobileNumber] = useState('');
  const [password, setPassword] = useState('');
  const [selectedPermissions, setSelectedPermissions] = useState<string[]>([
    'BILLING_CREATE',
    'INVENTORY_ADD',
    'INVENTORY_EDIT'
  ]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleOpenAdd = () => {
    setName('');
    setMobileNumber('');
    setPassword('');
    setSelectedPermissions(['BILLING_CREATE', 'INVENTORY_ADD', 'INVENTORY_EDIT']);
    setIsAddModalOpen(true);
  };

  const togglePermission = (permId: string) => {
    setSelectedPermissions(prev => 
      prev.includes(permId) ? prev.filter(p => p !== permId) : [...prev, permId]
    );
  };

  const handleSaveStaff = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !mobileNumber.trim() || !password) {
      showToast('Name, mobile number, and password are required', 'warning');
      return;
    }

    setIsSubmitting(true);
    try {
      await addStaffMember({
        name: name.trim(),
        mobileNumber: mobileNumber.trim(),
        password,
        permissions: selectedPermissions,
      });
      setIsAddModalOpen(false);
    } catch (err: any) {
      // Toast already shown in context
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSavePermissions = async () => {
    if (!editingStaff) return;
    setIsSubmitting(true);
    try {
      await updateStaffRolePermissions(editingStaff.staffId, selectedPermissions);
      setEditingStaff(null);
    } catch (err: any) {
      // Toast shown in context
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleOpenEdit = (staff: Staff) => {
    setEditingStaff(staff);
    setSelectedPermissions(staff.permissions || []);
  };

  const handleDeleteStaff = async (staffId: string, staffName: string) => {
    if (confirm(`Are you sure you want to remove ${staffName} from this shop?`)) {
      await removeStaffMember(staffId);
    }
  };

  return (
    <div className="page-container">
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800, letterSpacing: '-0.02em', color: 'var(--text-primary)' }}>
            Staff & Team Members
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', marginTop: '4px' }}>
            Control team access, assign cashier or manager roles, and enforce permissions
          </p>
        </div>
        <button onClick={handleOpenAdd} className="btn btn-primary">
          <UserPlus size={16} /> Add Team Member
        </button>
      </div>

      {/* Staff Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '20px' }}>
        {staffList.map((member) => {
          const isOwner = member.role === 'OWNER';
          const isSelf = member.userId === user?.id;

          return (
            <div key={member.staffId || member.userId} className="card" style={{ padding: '24px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '14px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div 
                      style={{ 
                        width: '46px', 
                        height: '46px', 
                        borderRadius: '12px', 
                        background: isOwner ? 'linear-gradient(135deg, #6366f1, #8b5cf6)' : 'rgba(99, 102, 241, 0.1)', 
                        color: isOwner ? '#ffffff' : 'var(--primary)',
                        display: 'flex', 
                        alignItems: 'center', 
                        justifyContent: 'center',
                        fontSize: '1.2rem',
                        fontWeight: 800
                      }}
                    >
                      {member.name.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '1.05rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
                        {member.name}
                        {isSelf && (
                          <span style={{ fontSize: '0.7rem', background: 'rgba(255,255,255,0.1)', padding: '2px 6px', borderRadius: '4px', color: 'var(--text-secondary)' }}>
                            You
                          </span>
                        )}
                      </div>
                      <div style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '2px' }}>
                        <Phone size={12} /> {member.mobileNumber}
                      </div>
                    </div>
                  </div>

                  <span className={`badge ${isOwner ? 'badge-primary' : 'badge-info'}`} style={{ fontSize: '0.72rem' }}>
                    {isOwner ? 'SHOP OWNER' : 'STAFF'}
                  </span>
                </div>

                {/* Permissions Breakdown */}
                <div style={{ margin: '16px 0', borderTop: '1px solid var(--surface-border)', paddingTop: '14px' }}>
                  <div style={{ fontSize: '0.78rem', fontWeight: 600, color: 'var(--text-secondary)', marginBottom: '8px', textTransform: 'uppercase' }}>
                    Assigned Permissions
                  </div>
                  {isOwner ? (
                    <div style={{ fontSize: '0.85rem', color: 'var(--primary)', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <ShieldCheck size={16} /> Full Shop Administrator Access
                    </div>
                  ) : member.permissions && member.permissions.length > 0 ? (
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                      {member.permissions.map(perm => {
                        const info = AVAILABLE_PERMISSIONS.find(p => p.id === perm);
                        return (
                          <span 
                            key={perm} 
                            className="badge badge-neutral" 
                            style={{ fontSize: '0.7rem', padding: '3px 8px' }}
                          >
                            {info?.label || perm}
                          </span>
                        );
                      })}
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', fontStyle: 'italic' }}>
                      No permissions granted yet
                    </div>
                  )}
                </div>
              </div>

              {/* Actions Footer */}
              {!isOwner && (
                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', borderTop: '1px solid var(--surface-border)', paddingTop: '14px', marginTop: '12px' }}>
                  <button 
                    onClick={() => handleOpenEdit(member)} 
                    className="btn btn-outline btn-sm"
                  >
                    <Key size={14} /> Permissions
                  </button>
                  <button 
                    onClick={() => handleDeleteStaff(member.staffId, member.name)} 
                    className="btn btn-outline btn-sm"
                    style={{ color: 'var(--danger)', borderColor: 'rgba(239, 68, 68, 0.3)' }}
                  >
                    <Trash2 size={14} /> Remove
                  </button>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Add Staff Modal */}
      {isAddModalOpen && (
        <div className="modal-overlay" onClick={() => setIsAddModalOpen(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '520px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 20px', borderBottom: '1px solid var(--surface-border)' }}>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Add Team Member</h3>
              <button onClick={() => setIsAddModalOpen(false)} className="btn btn-outline btn-sm btn-icon">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSaveStaff} style={{ padding: '20px' }}>
              <div className="form-group">
                <label className="form-label">Full Name *</label>
                <input 
                  type="text" 
                  className="form-control"
                  placeholder="e.g. Ramesh Kumar" 
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Mobile Number (Login ID) *</label>
                <input 
                  type="tel" 
                  className="form-control"
                  placeholder="10-digit mobile number" 
                  value={mobileNumber}
                  onChange={(e) => setMobileNumber(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Password *</label>
                <input 
                  type="password" 
                  className="form-control"
                  placeholder="Create a secure login password" 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
              </div>

              {/* Permissions Checklist */}
              <div className="form-group">
                <label className="form-label" style={{ marginBottom: '10px' }}>
                  Granular Permissions
                </label>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  {AVAILABLE_PERMISSIONS.map(perm => {
                    const isChecked = selectedPermissions.includes(perm.id);
                    return (
                      <div 
                        key={perm.id}
                        onClick={() => togglePermission(perm.id)}
                        style={{
                          display: 'flex',
                          alignItems: 'flex-start',
                          gap: '12px',
                          padding: '10px 14px',
                          borderRadius: '8px',
                          border: `1px solid ${isChecked ? 'var(--primary)' : 'var(--surface-border)'}`,
                          background: isChecked ? 'rgba(99, 102, 241, 0.06)' : 'var(--surface-color)',
                          cursor: 'pointer',
                          transition: 'all 0.15s ease'
                        }}
                      >
                        <input 
                          type="checkbox"
                          checked={isChecked}
                          onChange={() => {}} // handled by div click
                          style={{ marginTop: '3px', cursor: 'pointer' }}
                        />
                        <div>
                          <div style={{ fontWeight: 600, fontSize: '0.88rem' }}>{perm.label}</div>
                          <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>{perm.desc}</div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '24px' }}>
                <button type="button" onClick={() => setIsAddModalOpen(false)} className="btn btn-outline">
                  Cancel
                </button>
                <button type="submit" disabled={isSubmitting} className="btn btn-primary">
                  {isSubmitting ? 'Saving...' : 'Create Staff Member'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Permissions Modal */}
      {editingStaff && (
        <div className="modal-overlay" onClick={() => setEditingStaff(null)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '500px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 20px', borderBottom: '1px solid var(--surface-border)' }}>
              <div>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Edit Permissions</h3>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>{editingStaff.name} ({editingStaff.mobileNumber})</p>
              </div>
              <button onClick={() => setEditingStaff(null)} className="btn btn-outline btn-sm btn-icon">
                <X size={18} />
              </button>
            </div>

            <div style={{ padding: '20px' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '20px' }}>
                {AVAILABLE_PERMISSIONS.map(perm => {
                  const isChecked = selectedPermissions.includes(perm.id);
                  return (
                    <div 
                      key={perm.id}
                      onClick={() => togglePermission(perm.id)}
                      style={{
                        display: 'flex',
                        alignItems: 'flex-start',
                        gap: '12px',
                        padding: '10px 14px',
                        borderRadius: '8px',
                        border: `1px solid ${isChecked ? 'var(--primary)' : 'var(--surface-border)'}`,
                        background: isChecked ? 'rgba(99, 102, 241, 0.06)' : 'var(--surface-color)',
                        cursor: 'pointer',
                        transition: 'all 0.15s ease'
                      }}
                    >
                      <input 
                        type="checkbox"
                        checked={isChecked}
                        onChange={() => {}}
                        style={{ marginTop: '3px', cursor: 'pointer' }}
                      />
                      <div>
                        <div style={{ fontWeight: 600, fontSize: '0.88rem' }}>{perm.label}</div>
                        <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>{perm.desc}</div>
                      </div>
                    </div>
                  );
                })}
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                <button type="button" onClick={() => setEditingStaff(null)} className="btn btn-outline">
                  Cancel
                </button>
                <button type="button" onClick={handleSavePermissions} disabled={isSubmitting} className="btn btn-primary">
                  {isSubmitting ? 'Updating...' : 'Save Permissions'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
