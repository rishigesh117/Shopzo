import React, { useState } from 'react';
import { Store, ShieldCheck, ArrowRight, Lock, Phone, User, KeyRound } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const AuthPage: React.FC = () => {
  const { login, register, resetPassword } = useAuth();
  const [tab, setTab] = useState<'login' | 'register' | 'forgot'>('login');

  const [name, setName] = useState('');
  const [mobileNumber, setMobileNumber] = useState('');
  const [password, setPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    const cleanMobile = mobileNumber.replace(/\D/g, '');
    if (cleanMobile.length < 10) {
      setError('Please enter a valid 10-digit mobile number');
      return;
    }

    setIsLoading(true);
    try {
      if (tab === 'login') {
        if (!password) {
          setError('Password is required');
          setIsLoading(false);
          return;
        }
        await login(cleanMobile, password);
      } else if (tab === 'register') {
        if (!name.trim()) {
          setError('Full name is required');
          setIsLoading(false);
          return;
        }
        if (!password || password.length < 4) {
          setError('Password must be at least 4 characters');
          setIsLoading(false);
          return;
        }
        await register(name.trim(), cleanMobile, password);
      } else if (tab === 'forgot') {
        if (!newPassword || newPassword.length < 4) {
          setError('New password must be at least 4 characters');
          setIsLoading(false);
          return;
        }
        await resetPassword(cleanMobile, newPassword);
        setSuccess('Password updated successfully! Please sign in with your new password.');
        setTab('login');
        setPassword(newPassword);
      }
    } catch (err: any) {
      setError(err.message || 'Operation failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'radial-gradient(ellipse at top, #1e3a8a, #0f172a)',
      padding: '20px'
    }}>
      <div style={{
        maxWidth: '440px',
        width: '100%',
        background: '#ffffff',
        borderRadius: '24px',
        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.4)',
        overflow: 'hidden'
      }}>
        {/* Top Brand Banner */}
        <div style={{
          background: 'linear-gradient(135deg, #2563eb, #1d4ed8)',
          padding: '32px 28px 24px',
          color: 'white',
          textAlign: 'center'
        }}>
          <div style={{
            width: '56px',
            height: '56px',
            borderRadius: '16px',
            background: 'rgba(255, 255, 255, 0.2)',
            backdropFilter: 'blur(8px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            margin: '0 auto 14px'
          }}>
            <Store size={30} color="#ffffff" />
          </div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: 'white', letterSpacing: '-0.03em' }}>SHOPZO</h1>
          <p style={{ color: 'rgba(255, 255, 255, 0.85)', fontSize: '0.88rem', marginTop: '4px' }}>
            Cloud Retail POS & Store Management
          </p>
        </div>

        {/* Tab Selector */}
        <div style={{ display: 'flex', borderBottom: '1px solid var(--surface-border)' }}>
          <button
            type="button"
            onClick={() => { setTab('login'); setError(null); }}
            style={{
              flex: 1,
              padding: '14px',
              fontWeight: 700,
              fontSize: '0.88rem',
              color: tab === 'login' ? 'var(--primary)' : 'var(--text-muted)',
              borderBottom: tab === 'login' ? '2px solid var(--primary)' : 'none',
              background: tab === 'login' ? 'var(--surface)' : 'var(--surface-raised)'
            }}
          >
            Sign In
          </button>
          <button
            type="button"
            onClick={() => { setTab('register'); setError(null); }}
            style={{
              flex: 1,
              padding: '14px',
              fontWeight: 700,
              fontSize: '0.88rem',
              color: tab === 'register' ? 'var(--primary)' : 'var(--text-muted)',
              borderBottom: tab === 'register' ? '2px solid var(--primary)' : 'none',
              background: tab === 'register' ? 'var(--surface)' : 'var(--surface-raised)'
            }}
          >
            Register
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} style={{ padding: '28px' }}>
          {error && (
            <div style={{
              padding: '12px 14px',
              background: 'var(--danger-light)',
              color: 'var(--danger-dark)',
              borderRadius: 'var(--radius-md)',
              marginBottom: '18px',
              fontSize: '0.85rem',
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}>
              <span>{error}</span>
            </div>
          )}

          {success && (
            <div style={{
              padding: '12px 14px',
              background: 'var(--success-light)',
              color: 'var(--success-dark)',
              borderRadius: 'var(--radius-md)',
              marginBottom: '18px',
              fontSize: '0.85rem'
            }}>
              {success}
            </div>
          )}

          {tab === 'register' && (
            <div className="form-group">
              <label className="form-label">Full Name</label>
              <div style={{ position: 'relative' }}>
                <User size={18} style={{ position: 'absolute', left: '12px', top: '13px', color: 'var(--text-subtle)' }} />
                <input
                  type="text"
                  className="form-input"
                  style={{ paddingLeft: '38px' }}
                  placeholder="e.g. Anand Sharma"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                />
              </div>
            </div>
          )}

          <div className="form-group">
            <label className="form-label">Mobile Number</label>
            <div style={{ position: 'relative' }}>
              <Phone size={18} style={{ position: 'absolute', left: '12px', top: '13px', color: 'var(--text-subtle)' }} />
              <input
                type="tel"
                maxLength={10}
                className="form-input"
                style={{ paddingLeft: '38px' }}
                placeholder="10-digit mobile number"
                value={mobileNumber}
                onChange={(e) => setMobileNumber(e.target.value)}
                required
              />
            </div>
          </div>

          {tab !== 'forgot' && (
            <div className="form-group">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <label className="form-label" style={{ margin: 0 }}>Password</label>
                {tab === 'login' && (
                  <button
                    type="button"
                    onClick={() => { setTab('forgot'); setError(null); }}
                    style={{ fontSize: '0.78rem', color: 'var(--primary)', fontWeight: 600 }}
                  >
                    Forgot Password?
                  </button>
                )}
              </div>
              <div style={{ position: 'relative' }}>
                <Lock size={18} style={{ position: 'absolute', left: '12px', top: '13px', color: 'var(--text-subtle)' }} />
                <input
                  type="password"
                  className="form-input"
                  style={{ paddingLeft: '38px' }}
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
              </div>
            </div>
          )}

          {tab === 'forgot' && (
            <div className="form-group">
              <label className="form-label">New Password</label>
              <div style={{ position: 'relative' }}>
                <KeyRound size={18} style={{ position: 'absolute', left: '12px', top: '13px', color: 'var(--text-subtle)' }} />
                <input
                  type="password"
                  className="form-input"
                  style={{ paddingLeft: '38px' }}
                  placeholder="At least 4 characters"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  required
                />
              </div>
            </div>
          )}

          <button
            type="submit"
            disabled={isLoading}
            className="btn btn-primary btn-lg"
            style={{ width: '100%', marginTop: '12px' }}
          >
            {isLoading ? (
              'Processing...'
            ) : tab === 'login' ? (
              <>Sign In to Store <ArrowRight size={18} /></>
            ) : tab === 'register' ? (
              <>Create Account <ArrowRight size={18} /></>
            ) : (
              'Reset Password'
            )}
          </button>

          {tab === 'forgot' && (
            <div style={{ textAlign: 'center', marginTop: '14px' }}>
              <button
                type="button"
                onClick={() => setTab('login')}
                style={{ fontSize: '0.85rem', color: 'var(--primary)', fontWeight: 600 }}
              >
                Back to Sign In
              </button>
            </div>
          )}

          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '6px',
            marginTop: '24px',
            paddingTop: '16px',
            borderTop: '1px solid var(--surface-border)',
            fontSize: '0.78rem',
            color: 'var(--text-muted)'
          }}>
            <ShieldCheck size={14} color="#10b981" />
            <span>Multi-Tenant PostgreSQL Cloud Protection</span>
          </div>
        </form>
      </div>
    </div>
  );
};
