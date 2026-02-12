import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/apiService';
import { SystemStatus, ModuleListItem } from '../types/api';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import './Dashboard.css';

export const Dashboard: React.FC = () => {
  const navigate = useNavigate();
  const [systemStatus, setSystemStatus] = useState<SystemStatus | null>(null);
  const [modules, setModules] = useState<ModuleListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchSystemStatus = async () => {
    const response = await apiService.getSystemStatus();
    
    if (response.success && response.data) {
      setSystemStatus(response.data);
    } else {
      setError(response.error || 'Failed to fetch system status');
    }
  };

  const fetchModules = async () => {
    const response = await apiService.getModules();
    
    if (response.success && response.data) {
      setModules(response.data.modules || []);
    } else {
      setError(response.error || 'Failed to fetch modules');
    }
  };

  const fetchData = async () => {
    setLoading(true);
    setError('');
    
    await Promise.all([fetchSystemStatus(), fetchModules()]);
    
    setLoading(false);
  };

  useEffect(() => {
    fetchData();
    
    // Auto-refresh every 10 seconds
    const interval = setInterval(fetchData, 10000);
    return () => clearInterval(interval);
  }, []);

  const handleModuleClick = (moduleName: string) => {
    navigate(`/modules/${moduleName}`);
  };

  const formatUptime = (seconds: number): string => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) {
      return `${days}d ${hours}h ${minutes}m`;
    } else if (hours > 0) {
      return `${hours}h ${minutes}m`;
    } else {
      return `${minutes}m`;
    }
  };

  const formatBytes = (bytes: number): string => {
    const gb = bytes / (1024 ** 3);
    if (gb >= 1) {
      return `${gb.toFixed(2)} GB`;
    }
    const mb = bytes / (1024 ** 2);
    return `${mb.toFixed(2)} MB`;
  };

  const getStatusColor = (percent: number): string => {
    if (percent >= 90) return 'var(--color-danger)';
    if (percent >= 75) return 'var(--color-warning)';
    return 'var(--color-success)';
  };

  const getStatusBadge = (status?: string) => {
    const statusMap: Record<string, { label: string; className: string }> = {
      active: { label: 'Active', className: 'dashboard__module-status--active' },
      inactive: { label: 'Inactive', className: 'dashboard__module-status--inactive' },
      failed: { label: 'Failed', className: 'dashboard__module-status--failed' },
      installed: { label: 'Installed', className: 'dashboard__module-status--installed' },
      unknown: { label: 'Unknown', className: 'dashboard__module-status--unknown' },
    };

    const statusInfo = statusMap[status || 'unknown'] || statusMap.unknown;

    return (
      <span className={`dashboard__module-status ${statusInfo.className}`}>
        {statusInfo.label}
      </span>
    );
  };

  const getCapabilityBadge = (capability: string) => {
    const capabilityClasses: Record<string, string> = {
      service: 'dashboard__capability-badge--service',
      hardware: 'dashboard__capability-badge--hardware',
      sensor: 'dashboard__capability-badge--sensor',
      api: 'dashboard__capability-badge--api',
      integration: 'dashboard__capability-badge--integration',
    };

    const className = capabilityClasses[capability] || '';

    return (
      <span
        key={capability}
        className={`dashboard__capability-badge ${className}`}
      >
        {capability}
      </span>
    );
  };

  if (loading && !systemStatus) {
    return (
      <div className="dashboard">
        <div className="dashboard__loading">Loading...</div>
      </div>
    );
  }

  if (error && !systemStatus) {
    return (
      <div className="dashboard">
        <Card>
          <div className="dashboard__error">
            <p>{error}</p>
            <Button onClick={fetchData}>Retry</Button>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="dashboard">
      <div className="dashboard__header">
        <h1 className="dashboard__title">Dashboard</h1>
        <Button onClick={fetchData} variant="secondary" size="small">
          Refresh
        </Button>
      </div>

      {/* System Status Section */}
      <div className="dashboard__section">
        <h2 className="dashboard__section-title">System Status</h2>
        <div className="dashboard__grid">
          {/* Uptime */}
          <Card title="System Uptime">
            <div className="dashboard__metric">
              <div className="dashboard__metric-value">
                {systemStatus ? formatUptime(systemStatus.uptime) : '—'}
              </div>
              <div className="dashboard__metric-label">
                Since boot
              </div>
            </div>
          </Card>

          {/* CPU */}
          <Card title="CPU Usage">
            <div className="dashboard__metric">
              <div className="dashboard__metric-value">
                {systemStatus ? `${systemStatus.cpu.usage.toFixed(1)}%` : '—'}
              </div>
              {systemStatus?.cpu.temperature && (
                <div className="dashboard__metric-label">
                  Temperature: {systemStatus.cpu.temperature.toFixed(1)}°C
                </div>
              )}
            </div>
            {systemStatus && (
              <div className="dashboard__progress">
                <div
                  className="dashboard__progress-bar"
                  style={{
                    width: `${systemStatus.cpu.usage}%`,
                    backgroundColor: getStatusColor(systemStatus.cpu.usage),
                  }}
                />
              </div>
            )}
          </Card>

          {/* Memory */}
          <Card title="Memory Usage">
            <div className="dashboard__metric">
              <div className="dashboard__metric-value">
                {systemStatus ? `${systemStatus.memory.percent.toFixed(1)}%` : '—'}
              </div>
              {systemStatus && (
                <div className="dashboard__metric-label">
                  {formatBytes(systemStatus.memory.used)} / {formatBytes(systemStatus.memory.total)}
                </div>
              )}
            </div>
            {systemStatus && (
              <div className="dashboard__progress">
                <div
                  className="dashboard__progress-bar"
                  style={{
                    width: `${systemStatus.memory.percent}%`,
                    backgroundColor: getStatusColor(systemStatus.memory.percent),
                  }}
                />
              </div>
            )}
          </Card>

          {/* Disk */}
          <Card title="Disk Usage">
            <div className="dashboard__metric">
              <div className="dashboard__metric-value">
                {systemStatus ? `${systemStatus.disk.percent.toFixed(1)}%` : '—'}
              </div>
              {systemStatus && (
                <div className="dashboard__metric-label">
                  {formatBytes(systemStatus.disk.used)} / {formatBytes(systemStatus.disk.total)}
                </div>
              )}
            </div>
            {systemStatus && (
              <div className="dashboard__progress">
                <div
                  className="dashboard__progress-bar"
                  style={{
                    width: `${systemStatus.disk.percent}%`,
                    backgroundColor: getStatusColor(systemStatus.disk.percent),
                  }}
                />
              </div>
            )}
          </Card>
        </div>
      </div>

      {/* Modules Section */}
      <div className="dashboard__section">
        <h2 className="dashboard__section-title">Modules</h2>
        {error && (
          <div className="dashboard__error-banner">
            {error}
          </div>
        )}
        <div className="dashboard__modules-grid">
          {modules.map((module) => {
            const capabilities = module.capabilities || [];

            return (
              <Card 
                key={module.name} 
                className="dashboard__module-card dashboard__module-card--clickable"
                onClick={() => handleModuleClick(module.name)}
              >
                <div className="dashboard__module-header">
                  <h3 className="dashboard__module-name">{module.name}</h3>
                  {getStatusBadge(module.status)}
                </div>

                {/* Version */}
                {module.version && (
                  <div className="dashboard__module-version">
                    Version: v{module.version}
                  </div>
                )}

                {/* Capabilities */}
                {capabilities.length > 0 && (
                  <div className="dashboard__module-capabilities">
                    {capabilities.map((cap) => getCapabilityBadge(cap))}
                  </div>
                )}

                <div className="dashboard__module-click-hint">
                  Click for details →
                </div>
              </Card>
            );
          })}
        </div>

        {modules.length === 0 && !loading && (
          <Card>
            <div className="dashboard__empty">
              <p>No modules found</p>
            </div>
          </Card>
        )}
      </div>
    </div>
  );
};
