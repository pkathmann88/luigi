import React, { useEffect, useState } from 'react';
import { apiService } from '../services/apiService';
import { SystemStatus } from '../types/api';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import './Dashboard.css';

export const Dashboard: React.FC = () => {
  const [systemStatus, setSystemStatus] = useState<SystemStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchSystemStatus = async () => {
    setLoading(true);
    setError('');
    
    const response = await apiService.getSystemStatus();
    
    if (response.success && response.data) {
      setSystemStatus(response.data);
    } else {
      setError(response.error || 'Failed to fetch system status');
    }
    
    setLoading(false);
  };

  useEffect(() => {
    fetchSystemStatus();
    
    // Auto-refresh every 10 seconds
    const interval = setInterval(fetchSystemStatus, 10000);
    return () => clearInterval(interval);
  }, []);

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

  if (loading && !systemStatus) {
    return (
      <div className="dashboard">
        <div className="dashboard__loading">Loading system status...</div>
      </div>
    );
  }

  if (error && !systemStatus) {
    return (
      <div className="dashboard">
        <Card>
          <div className="dashboard__error">
            <p>{error}</p>
            <Button onClick={fetchSystemStatus}>Retry</Button>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="dashboard">
      <div className="dashboard__header">
        <h1 className="dashboard__title">System Dashboard</h1>
        <Button onClick={fetchSystemStatus} variant="secondary" size="small">
          Refresh
        </Button>
      </div>

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

      {/* System Actions */}
      <Card title="System Actions">
        <div className="dashboard__actions">
          <Button variant="secondary" size="small">
            Update System
          </Button>
          <Button variant="secondary" size="small">
            Clean Up
          </Button>
          <Button variant="danger" size="small">
            Reboot
          </Button>
          <Button variant="danger" size="small">
            Shutdown
          </Button>
        </div>
      </Card>
    </div>
  );
};
