import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/apiService';
import { ModuleListItem } from '../types/api';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import './Modules.css';

export const Modules: React.FC = () => {
  const navigate = useNavigate();
  const [modules, setModules] = useState<ModuleListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

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

  const handleModuleClick = (moduleName: string) => {
    navigate(`/modules/${moduleName}`);
  };

  const getStatusBadge = (status?: string) => {
    const statusMap: Record<string, { label: string; className: string }> = {
      active: { label: 'Active', className: 'modules__status--active' },
      inactive: { label: 'Inactive', className: 'modules__status--inactive' },
      failed: { label: 'Failed', className: 'modules__status--failed' },
      installed: { label: 'Installed', className: 'modules__status--installed' },
      unknown: { label: 'Unknown', className: 'modules__status--unknown' },
    };

    const statusInfo = statusMap[status || 'unknown'] || statusMap.unknown;

    return (
      <span className={`modules__status ${statusInfo.className}`}>
        {statusInfo.label}
      </span>
    );
  };

  const getCapabilityBadge = (capability: string) => {
    const capabilityClasses: Record<string, string> = {
      service: 'modules__capability-badge--service',
      hardware: 'modules__capability-badge--hardware',
      sensor: 'modules__capability-badge--sensor',
      api: 'modules__capability-badge--api',
      integration: 'modules__capability-badge--integration',
    };

    const className = capabilityClasses[capability] || '';

    return (
      <span
        key={capability}
        className={`modules__capability-badge ${className}`}
      >
        {capability}
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
        {modules.map((module) => {
          const capabilities = module.capabilities || [];

          return (
            <Card 
              key={module.name} 
              className="modules__card modules__card--clickable"
              onClick={() => handleModuleClick(module.name)}
            >
              <div className="modules__card-header">
                <h3 className="modules__module-name">{module.name}</h3>
                {getStatusBadge(module.status)}
              </div>

              {/* Version */}
              {module.version && (
                <div className="modules__version">
                  Version: v{module.version}
                </div>
              )}

              {/* Capabilities */}
              {capabilities.length > 0 && (
                <div className="modules__capabilities">
                  {capabilities.map((cap) => getCapabilityBadge(cap))}
                </div>
              )}

              <div className="modules__click-hint">
                Click for details →
              </div>
            </Card>
          );
        })}
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
