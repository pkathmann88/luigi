import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { apiService } from '../services/apiService';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import './ModuleLogs.css';

export const ModuleLogs: React.FC = () => {
  const { moduleName } = useParams<{ moduleName: string }>();
  const navigate = useNavigate();
  const [logContent, setLogContent] = useState<string[]>([]);
  const [logFile, setLogFile] = useState<string>('');
  const [lineCount, setLineCount] = useState<number>(100);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchLogContent = async () => {
    if (!moduleName) return;
    
    setLoading(true);
    setError('');
    
    const response = await apiService.getModuleLogs(
      moduleName,
      lineCount,
      searchTerm || undefined
    );
    
    if (response.success && response.data) {
      setLogContent(response.data.lines || []);
      setLogFile(response.data.file || '');
    } else {
      setError(response.error || 'Failed to fetch log content');
      setLogContent([]);
    }
    
    setLoading(false);
  };

  const handleSearch = () => {
    fetchLogContent();
  };

  const handleClearSearch = () => {
    setSearchTerm('');
    // Trigger a new fetch without search term
    setTimeout(() => fetchLogContent(), 0);
  };

  useEffect(() => {
    fetchLogContent();
  }, [moduleName, lineCount]);

  const handleBack = () => {
    navigate(`/modules/${moduleName}`);
  };

  const handleLineCountChange = (count: number) => {
    setLineCount(count);
  };

  return (
    <div className="module-logs">
      <div className="module-logs__header">
        <div className="module-logs__header-left">
          <Button 
            variant="secondary" 
            size="small"
            onClick={handleBack}
          >
            ← Back to Module
          </Button>
          <h1 className="module-logs__title">
            Logs: {moduleName}
          </h1>
        </div>
        <Button onClick={fetchLogContent} variant="secondary" size="small">
          Refresh
        </Button>
      </div>

      {error && (
        <div className="module-logs__error-banner">
          {error}
        </div>
      )}

      <Card className="module-logs__content">
        <div className="module-logs__controls">
          <div className="module-logs__controls-left">
            <div className="module-logs__info">
              {logFile && (
                <span className="module-logs__file">File: {logFile}</span>
              )}
              {logContent.length > 0 && (
                <span className="module-logs__count">
                  {logContent.length} lines
                </span>
              )}
            </div>
          </div>
          
          <div className="module-logs__controls-right">
            <div className="module-logs__line-selector">
              <label className="module-logs__label">Lines:</label>
              <select
                value={lineCount}
                onChange={(e) => handleLineCountChange(Number(e.target.value))}
                className="module-logs__select"
                disabled={loading}
              >
                <option value={50}>50</option>
                <option value={100}>100</option>
                <option value={200}>200</option>
                <option value={500}>500</option>
                <option value={1000}>1000</option>
              </select>
            </div>
          </div>
        </div>

        <div className="module-logs__search">
          <input
            type="text"
            className="module-logs__search-input"
            placeholder="Search logs..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
            disabled={loading}
          />
          <Button
            onClick={handleSearch}
            variant="primary"
            size="small"
            disabled={loading}
          >
            Search
          </Button>
          {searchTerm && (
            <Button
              onClick={handleClearSearch}
              variant="secondary"
              size="small"
              disabled={loading}
            >
              Clear
            </Button>
          )}
        </div>

        {loading ? (
          <div className="module-logs__loading">Loading logs...</div>
        ) : logContent.length > 0 ? (
          <div className="module-logs__viewer">
            <pre className="module-logs__pre">{logContent.join('\n')}</pre>
          </div>
        ) : (
          <div className="module-logs__empty">
            {error ? 'Failed to load logs' : 'No log entries found'}
          </div>
        )}
      </Card>
    </div>
  );
};
