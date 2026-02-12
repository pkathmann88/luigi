import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { authService } from '../services/authService';
import { Button } from '../components/Button';
import './Layout.css';

interface LayoutProps {
  children: React.ReactNode;
}

export const Layout: React.FC<LayoutProps> = ({ children }) => {
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    authService.logout();
    navigate('/login');
  };

  const navItems = [
    { path: '/dashboard', label: 'Dashboard', icon: '📊' },
    { path: '/modules', label: 'Modules', icon: '🔌' },
    { path: '/logs', label: 'Logs', icon: '📄' },
    { path: '/config', label: 'Config', icon: '⚙️' },
  ];

  return (
    <div className="layout">
      <nav className="layout__nav">
        <div className="layout__nav-header">
          <h1 className="layout__logo">Luigi</h1>
        </div>

        <ul className="layout__nav-list">
          {navItems.map((item) => (
            <li key={item.path}>
              <button
                className={`layout__nav-item ${
                  location.pathname === item.path ? 'layout__nav-item--active' : ''
                }`}
                onClick={() => navigate(item.path)}
              >
                <span className="layout__nav-icon">{item.icon}</span>
                <span className="layout__nav-label">{item.label}</span>
              </button>
            </li>
          ))}
        </ul>

        <div className="layout__nav-footer">
          <Button variant="ghost" onClick={handleLogout} fullWidth>
            Logout
          </Button>
        </div>
      </nav>

      <main className="layout__main">
        <div className="layout__content">{children}</div>
      </main>
    </div>
  );
};
