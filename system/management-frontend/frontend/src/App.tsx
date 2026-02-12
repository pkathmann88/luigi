import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { authService } from './services/authService';
import { Layout } from './components/Layout';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { ModuleDetail } from './pages/ModuleDetail';
import { ModuleConfig } from './pages/ModuleConfig';
import { ModuleLogs } from './pages/ModuleLogs';
import './styles/globals.css';

interface PrivateRouteProps {
  children: React.ReactNode;
}

const PrivateRoute: React.FC<PrivateRouteProps> = ({ children }) => {
  return authService.isAuthenticated() ? (
    <Layout>{children}</Layout>
  ) : (
    <Navigate to="/login" replace />
  );
};

export const App: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route
          path="/dashboard"
          element={
            <PrivateRoute>
              <Dashboard />
            </PrivateRoute>
          }
        />
        <Route
          path="/modules/:moduleName"
          element={
            <PrivateRoute>
              <ModuleDetail />
            </PrivateRoute>
          }
        />
        <Route
          path="/modules/:moduleName/config"
          element={
            <PrivateRoute>
              <ModuleConfig />
            </PrivateRoute>
          }
        />
        <Route
          path="/modules/:moduleName/logs"
          element={
            <PrivateRoute>
              <ModuleLogs />
            </PrivateRoute>
          }
        />
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  );
};
