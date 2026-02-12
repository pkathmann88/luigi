import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { apiService } from '../services/apiService';
import { Module } from '../types/api';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import './ModuleDetail.css';

export const ModuleDetail: React.FC = () => {
  const { moduleName } = useParams<{ moduleName: string }>();
  const navigate = useNavigate();
  const [module, setModule] = useState<Module | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const fetchModule = async () => {
    if (!moduleName) return;
    
    setLoading(true);
    setError('');
    
    const response = await apiService.getModule(moduleName);
    
    if (response.success && response.data) {
      setModule(response.data);
    } else {
      setError(response.error || 'Failed to fetch module');
    }
    
    setLoading(false);
  };

  useEffect(() => {
    fetchModule();
  }, [moduleName]);

  const handleAction = async (
    action: 'start' | 'stop' | 'restart'
  ) => {
    if (!moduleName) return;
    
    setActionLoading(action);
    
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
      // Refresh module data after action
      await fetchModule();
    } else {
      setError(response.error || `Failed to ${action} module`);
    }
    
    setActionLoading(null);
  };

  const getStatusBadge = (status?: string) => {
    const statusMap: Record<string, { label: string; className: string }> = {
      active: { label: 'Active', className: 'module-detail__status--active' },
      inactive: { label: 'Inactive', className: 'module-detail__status--inactive' },
      failed: { label: 'Failed', className: 'module-detail__status--failed' },
      installed: { label: 'Installed', className: 'module-detail__status--installed' },
      unknown: { label: 'Unknown', className: 'module-detail__status--unknown' },
    };

    const statusInfo = statusMap[status || 'unknown'] || statusMap.unknown;

    return (
      <span className={`module-detail__status ${statusInfo.className}`}>
        {statusInfo.label}
      </span>
    );
  };

  const getCapabilityBadge = (capability: string) => {
    const capabilityClasses: Record<string, string> = {
      service: 'module-detail__capability-badge--service',
      hardware: 'module-detail__capability-badge--hardware',
      sensor: 'module-detail__capability-badge--sensor',
      api: 'module-detail__capability-badge--api',
      integration: 'module-detail__capability-badge--integration',
    };

    const className = capabilityClasses[capability] || '';

    return (
      <span
        key={capability}
        className={`module-detail__capability-badge ${className}`}
      >
        {capability}
      </span>
    );
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const hasServiceCapability = (module: Module) => {
    const registryCaps = module.registry?.capabilities;
    const metadataCaps = module.metadata?.capabilities;
    
    return registryCaps?.includes('service') || 
           (Array.isArray(metadataCaps) && metadataCaps.includes('service'));
  };

  const extractModuleName = (dependencyPath: string): string => {
    // Extract module name from path (e.g., "iot/ha-mqtt" -> "ha-mqtt")
    const parts = dependencyPath.split('/');
    return parts[parts.length - 1];
  };

  const handleDependencyClick = (dependencyPath: string) => {
    const moduleName = extractModuleName(dependencyPath);
    navigate(`/modules/${moduleName}`);
  };

  if (loading) {
    return (
      <div className="module-detail">
        <div className="module-detail__loading">Loading module details...</div>
      </div>
    );
  }

  if (error || !module) {
    return (
      <div className="module-detail">
        <Card>
          <div className="module-detail__error">
            <p>{error || 'Module not found'}</p>
            <Button onClick={() => navigate('/modules')}>Back to Modules</Button>
          </div>
        </Card>
      </div>
    );
  }

  const registry = module.registry;
  const capabilities = registry?.capabilities || [];
  const hasService = hasServiceCapability(module);

  return (
    <div className="module-detail">
      <div className="module-detail__header">
        <div className="module-detail__header-left">
          <Button 
            variant="secondary" 
            size="small"
            onClick={() => navigate('/modules')}
          >
            ← Back to Modules
          </Button>
          <h1 className="module-detail__title">{module.name}</h1>
          {getStatusBadge(module.status)}
        </div>
        <Button onClick={fetchModule} variant="secondary" size="small">
          Refresh
        </Button>
      </div>

      {error && (
        <div className="module-detail__error-banner">
          {error}
        </div>
      )}

      <div className="module-detail__content">
        {/* Main Information Card */}
        <Card className="module-detail__card">
          <h2 className="module-detail__section-title">Module Information</h2>
          
          {registry?.description && (
            <div className="module-detail__description">
              {registry.description}
            </div>
          )}

          <div className="module-detail__info-grid">
            <div className="module-detail__info-item">
              <span className="module-detail__info-label">Name:</span>
              <span className="module-detail__info-value">{module.name}</span>
            </div>

            {module.category && (
              <div className="module-detail__info-item">
                <span className="module-detail__info-label">Category:</span>
                <span className="module-detail__info-value">{module.category}</span>
              </div>
            )}

            {registry?.version && (
              <div className="module-detail__info-item">
                <span className="module-detail__info-label">Version:</span>
                <span className="module-detail__info-value">v{registry.version}</span>
              </div>
            )}

            {registry?.author && (
              <div className="module-detail__info-item">
                <span className="module-detail__info-label">Author:</span>
                <span className="module-detail__info-value">{registry.author}</span>
              </div>
            )}

            <div className="module-detail__info-item">
              <span className="module-detail__info-label">Path:</span>
              <span className="module-detail__info-value module-detail__info-value--code">{module.path}</span>
            </div>

            {registry?.service_name && (
              <div className="module-detail__info-item">
                <span className="module-detail__info-label">Service Name:</span>
                <span className="module-detail__info-value module-detail__info-value--code">{registry.service_name}</span>
              </div>
            )}
          </div>

          {/* Capabilities */}
          {capabilities.length > 0 && (
            <div className="module-detail__capabilities">
              <div className="module-detail__capabilities-label">Capabilities:</div>
              <div className="module-detail__capabilities-list">
                {capabilities.map((cap) => getCapabilityBadge(cap))}
              </div>
            </div>
          )}
        </Card>

        {/* Runtime Status Card - Only for service modules */}
        {hasService && (
          <Card className="module-detail__card">
            <h2 className="module-detail__section-title">Runtime Status</h2>
            
            <div className="module-detail__info-grid">
              <div className="module-detail__info-item">
                <span className="module-detail__info-label">Status:</span>
                {getStatusBadge(module.status)}
              </div>

              {module.pid && (
                <div className="module-detail__info-item">
                  <span className="module-detail__info-label">Process ID:</span>
                  <span className="module-detail__info-value">{module.pid}</span>
                </div>
              )}

              {module.uptime !== undefined && module.uptime !== null && (
                <div className="module-detail__info-item">
                  <span className="module-detail__info-label">Uptime:</span>
                  <span className="module-detail__info-value">
                    {Math.floor(module.uptime / 3600)}h {Math.floor((module.uptime % 3600) / 60)}m
                  </span>
                </div>
              )}

              {module.memory !== undefined && module.memory !== null && (
                <div className="module-detail__info-item">
                  <span className="module-detail__info-label">Memory:</span>
                  <span className="module-detail__info-value">
                    {(module.memory / 1024).toFixed(1)} MB
                  </span>
                </div>
              )}
            </div>

            {/* Service Controls */}
            <div className="module-detail__actions">
              <Button
                variant="success"
                onClick={() => handleAction('start')}
                disabled={
                  module.status === 'active' ||
                  actionLoading === 'start'
                }
                loading={actionLoading === 'start'}
              >
                Start Service
              </Button>
              <Button
                variant="secondary"
                onClick={() => handleAction('restart')}
                disabled={
                  module.status !== 'active' ||
                  actionLoading === 'restart'
                }
                loading={actionLoading === 'restart'}
              >
                Restart Service
              </Button>
              <Button
                variant="danger"
                onClick={() => handleAction('stop')}
                disabled={
                  module.status !== 'active' ||
                  actionLoading === 'stop'
                }
                loading={actionLoading === 'stop'}
              >
                Stop Service
              </Button>
            </div>
          </Card>
        )}

        {/* Dependencies Card */}
        {registry?.dependencies && registry.dependencies.length > 0 && (
          <Card className="module-detail__card">
            <h2 className="module-detail__section-title">Dependencies</h2>
            <div className="module-detail__dependency-list">
              {registry.dependencies.map((dep) => (
                <div 
                  key={dep} 
                  className="module-detail__dependency-item module-detail__dependency-item--clickable"
                  onClick={() => handleDependencyClick(dep)}
                >
                  → {dep}
                </div>
              ))}
            </div>
          </Card>
        )}

        {/* APT Packages Card */}
        {registry?.apt_packages && registry.apt_packages.length > 0 && (
          <Card className="module-detail__card">
            <h2 className="module-detail__section-title">System Packages</h2>
            <div className="module-detail__package-list">
              {registry.apt_packages.map((pkg) => (
                <div key={pkg} className="module-detail__package-item">
                  {pkg}
                </div>
              ))}
            </div>
          </Card>
        )}

        {/* Hardware Card */}
        {registry?.hardware && (
          <Card className="module-detail__card">
            <h2 className="module-detail__section-title">Hardware Configuration</h2>
            
            {registry.hardware.gpio_pins && registry.hardware.gpio_pins.length > 0 && (
              <div className="module-detail__hardware-section">
                <div className="module-detail__hardware-label">GPIO Pins:</div>
                <div className="module-detail__gpio-list">
                  {registry.hardware.gpio_pins.map((pin) => (
                    <span key={pin} className="module-detail__gpio-pin">
                      GPIO {pin}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {registry.hardware.sensors && registry.hardware.sensors.length > 0 && (
              <div className="module-detail__hardware-section">
                <div className="module-detail__hardware-label">Sensors:</div>
                <div className="module-detail__sensor-list">
                  {registry.hardware.sensors.map((sensor) => (
                    <div key={sensor} className="module-detail__sensor-item">
                      {sensor}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </Card>
        )}

        {/* File Paths Card */}
        <Card className="module-detail__card">
          <h2 className="module-detail__section-title">File Paths</h2>
          
          <div className="module-detail__info-grid">
            {registry?.config_path && (
              <div className="module-detail__info-item">
                <span className="module-detail__info-label">Configuration:</span>
                <span className="module-detail__info-value module-detail__info-value--code">
                  {registry.config_path}
                </span>
              </div>
            )}

            {registry?.log_path && (
              <div className="module-detail__info-item">
                <span className="module-detail__info-label">Logs:</span>
                <span className="module-detail__info-value module-detail__info-value--code">
                  {registry.log_path}
                </span>
              </div>
            )}
          </div>
        </Card>

        {/* Installation Info Card */}
        {registry && (
          <Card className="module-detail__card">
            <h2 className="module-detail__section-title">Installation Information</h2>
            
            <div className="module-detail__info-grid">
              <div className="module-detail__info-item">
                <span className="module-detail__info-label">Installed:</span>
                <span className="module-detail__info-value">{formatDate(registry.installed_at)}</span>
              </div>

              {registry.updated_at !== registry.installed_at && (
                <div className="module-detail__info-item">
                  <span className="module-detail__info-label">Updated:</span>
                  <span className="module-detail__info-value">{formatDate(registry.updated_at)}</span>
                </div>
              )}

              <div className="module-detail__info-item">
                <span className="module-detail__info-label">Installed By:</span>
                <span className="module-detail__info-value">{registry.installed_by}</span>
              </div>

              <div className="module-detail__info-item">
                <span className="module-detail__info-label">Install Method:</span>
                <span className="module-detail__info-value">{registry.install_method}</span>
              </div>
            </div>
          </Card>
        )}
      </div>
    </div>
  );
};
