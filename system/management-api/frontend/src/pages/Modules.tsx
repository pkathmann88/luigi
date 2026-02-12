import React, { useEffect, useState } from 'react';
import { apiService } from '../services/apiService';
import { Module } from '../types/api';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import './Modules.css';

export const Modules: React.FC = () => {
  const [modules, setModules] = useState<Module[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const fetchModules = async () => {
    setLoading(true);
    setError('');
    
    const response = await apiService.getModules();
    
    if (response.success && response.data) {
      setModules(response.data.modules || []);
    } else {
      setError(response.error || 'Failed to fetch modules');
    }
    
    setLoading(false);
  };

  useEffect(() => {
    fetchModules();
  }, []);

  const handleAction = async (
    moduleName: string,
    action: 'start' | 'stop' | 'restart'
  ) => {
    setActionLoading(`${moduleName}-${action}`);
    
    let response;
    switch (action) {
      case 'start':
        response = await apiService.startModule(moduleName);
        break;
      case 'stop':
        response = await apiService.stopModule(moduleName);
        break;
      case 'restart':
        response = await apiService.restartModule(moduleName);
        break;
    }
    
    if (response.success) {
      // Refresh modules list after action
      await fetchModules();
    } else {
      setError(response.error || `Failed to ${action} module`);
    }
    
    setActionLoading(null);
  };

  const getStatusBadge = (status?: string) => {
    const statusMap: Record<string, { label: string; className: string }> = {
      active: { label: 'Active', className: 'modules__status--active' },
      inactive: { label: 'Inactive', className: 'modules__status--inactive' },
      failed: { label: 'Failed', className: 'modules__status--failed' },
      unknown: { label: 'Unknown', className: 'modules__status--unknown' },
    };

    const statusInfo = statusMap[status || 'unknown'] || statusMap.unknown;

    return (
      <span className={`modules__status ${statusInfo.className}`}>
        {statusInfo.label}
      </span>
    );
  };

  if (loading && modules.length === 0) {
    return (
      <div className="modules">
        <div className="modules__loading">Loading modules...</div>
      </div>
    );
  }

  if (error && modules.length === 0) {
    return (
      <div className="modules">
        <Card>
          <div className="modules__error">
            <p>{error}</p>
            <Button onClick={fetchModules}>Retry</Button>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="modules">
      <div className="modules__header">
        <h1 className="modules__title">Module Management</h1>
        <Button onClick={fetchModules} variant="secondary" size="small">
          Refresh
        </Button>
      </div>

      {error && (
        <div className="modules__error-banner">
          {error}
        </div>
      )}

      <div className="modules__grid">
        {modules.map((module) => (
          <Card key={module.name} className="modules__card">
            <div className="modules__card-header">
              <h3 className="modules__module-name">{module.name}</h3>
              {getStatusBadge(module.status)}
            </div>

            <div className="modules__card-info">
              {module.category && (
                <div className="modules__info-item">
                  <span className="modules__info-label">Category:</span>
                  <span className="modules__info-value">{module.category}</span>
                </div>
              )}
              {module.pid && (
                <div className="modules__info-item">
                  <span className="modules__info-label">PID:</span>
                  <span className="modules__info-value">{module.pid}</span>
                </div>
              )}
              {module.uptime !== undefined && (
                <div className="modules__info-item">
                  <span className="modules__info-label">Uptime:</span>
                  <span className="modules__info-value">
                    {Math.floor(module.uptime / 60)}m
                  </span>
                </div>
              )}
              {module.memory !== undefined && (
                <div className="modules__info-item">
                  <span className="modules__info-label">Memory:</span>
                  <span className="modules__info-value">
                    {(module.memory / 1024 / 1024).toFixed(1)} MB
                  </span>
                </div>
              )}
            </div>

            <div className="modules__card-actions">
              <Button
                size="small"
                variant="success"
                onClick={() => handleAction(module.name, 'start')}
                disabled={
                  module.status === 'active' ||
                  actionLoading === `${module.name}-start`
                }
                loading={actionLoading === `${module.name}-start`}
              >
                Start
              </Button>
              <Button
                size="small"
                variant="secondary"
                onClick={() => handleAction(module.name, 'restart')}
                disabled={
                  module.status !== 'active' ||
                  actionLoading === `${module.name}-restart`
                }
                loading={actionLoading === `${module.name}-restart`}
              >
                Restart
              </Button>
              <Button
                size="small"
                variant="danger"
                onClick={() => handleAction(module.name, 'stop')}
                disabled={
                  module.status !== 'active' ||
                  actionLoading === `${module.name}-stop`
                }
                loading={actionLoading === `${module.name}-stop`}
              >
                Stop
              </Button>
            </div>
          </Card>
        ))}
      </div>

      {modules.length === 0 && (
        <Card>
          <div className="modules__empty">
            <p>No modules found</p>
          </div>
        </Card>
      )}
    </div>
  );
};
