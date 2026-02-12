import React, { useEffect, useState } from 'react';
import { apiService } from '../services/apiService';
import { LogFile } from '../types/api';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import './Logs.css';

export const Logs: React.FC = () => {
  const [logs, setLogs] = useState<LogFile[]>([]);
  const [selectedLog, setSelectedLog] = useState<string>('');
  const [logContent, setLogContent] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const fetchLogs = async () => {
    setLoading(true);
    setError('');
    
    const response = await apiService.getLogs();
    
    if (response.success && response.data) {
      setLogs(response.data.files || []);
    } else {
      setError(response.error || 'Failed to fetch logs');
    }
    
    setLoading(false);
  };

  const fetchLogContent = async (logName: string) => {
    setLoading(true);
    setError('');
    setSelectedLog(logName);
    
    const response = await apiService.getModuleLogs(logName, 100);
    
    if (response.success && response.data) {
      setLogContent(response.data.lines || []);
    } else {
      setError(response.error || 'Failed to fetch log content');
      setLogContent([]);
    }
    
    setLoading(false);
  };

  useEffect(() => {
    fetchLogs();
  }, []);

  return (
    <div className="logs">
      <div className="logs__header">
        <h1 className="logs__title">System Logs</h1>
        <Button onClick={fetchLogs} variant="secondary" size="small">
          Refresh
        </Button>
      </div>

      <div className="logs__container">
        <Card className="logs__sidebar">
          <h3>Log Files</h3>
          {logs.length === 0 && !loading ? (
            <p className="logs__empty">No log files found</p>
          ) : (
            <ul className="logs__list">
              {logs.map((log) => (
                <li key={log.path}>
                  <button
                    className={`logs__item ${
                      selectedLog === log.name ? 'logs__item--active' : ''
                    }`}
                    onClick={() => fetchLogContent(log.name)}
                  >
                    {log.name}
                  </button>
                </li>
              ))}
            </ul>
          )}
        </Card>

        <Card className="logs__content">
          <h3>Log Content</h3>
          {loading ? (
            <div className="logs__loading">Loading...</div>
          ) : error ? (
            <div className="logs__error">{error}</div>
          ) : logContent.length > 0 ? (
            <pre className="logs__pre">{logContent.join('\n')}</pre>
          ) : (
            <div className="logs__empty">
              Select a log file to view its content
            </div>
          )}
        </Card>
      </div>
    </div>
  );
};
