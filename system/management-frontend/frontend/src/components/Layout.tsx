import React from 'react';
import { useNavigate } from 'react-router-dom';
import { authService } from '../services/authService';
import { Button } from '../components/Button';
import './Layout.css';

interface LayoutProps {
  children: React.ReactNode;
}

export const Layout: React.FC<LayoutProps> = ({ children }) => {
  const navigate = useNavigate();

  const handleLogout = () => {
    authService.logout();
    navigate('/login');
  };

  return (
    <div className="layout">
      <header className="layout__header">
        <div className="layout__header-left">
          <h1 className="layout__logo" onClick={() => navigate('/dashboard')}>Luigi</h1>
        </div>
        <div className="layout__header-right">
          <Button variant="ghost" onClick={handleLogout} size="small">
            Logout
          </Button>
        </div>
      </header>

      <main className="layout__main">
        <div className="layout__content">{children}</div>
      </main>
    </div>
  );
};
