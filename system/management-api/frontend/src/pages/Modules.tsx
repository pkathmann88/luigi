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

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const hasServiceCapability = (module: Module) => {
    const registryCaps = module.registry?.capabilities;
    const metadataCaps = module.metadata?.capabilities;
    
    return registryCaps?.includes('service') || 
           (Array.isArray(metadataCaps) && metadataCaps.includes('service'));
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
          const registry = module.registry;
          const capabilities = registry?.capabilities || [];
          const hasService = hasServiceCapability(module);

          return (
            <Card key={module.name} className="modules__card">
              <div className="modules__card-header">
                <h3 className="modules__module-name">{module.name}</h3>
                {getStatusBadge(module.status)}
              </div>

              {/* Description */}
              {registry?.description && (
                <div className="modules__description">
                  {registry.description}
                </div>
              )}

              {/* Capabilities */}
              {capabilities.length > 0 && (
                <div className="modules__capabilities">
                  {capabilities.map((cap) => getCapabilityBadge(cap))}
                </div>
              )}

              <div className="modules__card-info">
                {/* Category */}
                {module.category && (
                  <div className="modules__info-item">
                    <span className="modules__info-label">Category:</span>
                    <span className="modules__info-value">{module.category}</span>
                  </div>
                )}
                
                {/* Version */}
                {registry?.version && (
                  <div className="modules__info-item">
                    <span className="modules__info-label">Version:</span>
                    <span className="modules__info-value">v{registry.version}</span>
                  </div>
                )}

                {/* PID */}
                {module.pid && (
                  <div className="modules__info-item">
                    <span className="modules__info-label">PID:</span>
                    <span className="modules__info-value">{module.pid}</span>
                  </div>
                )}

                {/* Dependencies */}
                {registry?.dependencies && registry.dependencies.length > 0 && (
                  <div className="modules__dependencies">
                    <div className="modules__dependencies-title">Dependencies:</div>
                    <div className="modules__dependency-list">
                      {registry.dependencies.map((dep) => (
                        <div key={dep}>→ {dep}</div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Registry Info */}
              {registry ? (
                <div className="modules__registry-info">
                  Installed {formatDate(registry.installed_at)}
                  {registry.updated_at !== registry.installed_at && 
                    ` • Updated ${formatDate(registry.updated_at)}`
                  }
                </div>
              ) : (
                <div className="modules__not-registered">
                  Not registered in module registry
                </div>
              )}

              {/* Actions - Only show for service modules */}
              {hasService && (
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
              )}
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
