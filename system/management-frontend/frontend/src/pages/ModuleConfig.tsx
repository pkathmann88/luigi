import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { apiService } from '../services/apiService';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import './ModuleConfig.css';

const DEFAULT_INI_SECTION = 'default';

export const ModuleConfig: React.FC = () => {
  const { moduleName } = useParams<{ moduleName: string }>();
  const navigate = useNavigate();
  const [configContent, setConfigContent] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [configPath, setConfigPath] = useState<string>('');

  const fetchConfigContent = async () => {
    if (!moduleName) return;
    
    setLoading(true);
    setError('');
    setSaveSuccess(false);
    
    const response = await apiService.getConfig(moduleName);
    
    if (response.success && response.data) {
      setConfigPath(response.data.path || moduleName);
      
      // Extract key-value pairs from parsed config data
      const parsed = response.data.parsed;
      if (parsed && typeof parsed === 'object') {
        // Flatten parsed config (handles INI sections and simple key-value)
        const flat: Record<string, string> = {};
        for (const [key, value] of Object.entries(parsed)) {
          if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
            // INI section: prefix keys with section name
            for (const [subKey, subValue] of Object.entries(value as Record<string, unknown>)) {
              const prefix = key === DEFAULT_INI_SECTION ? '' : `${key}.`;
              flat[`${prefix}${subKey}`] = String(subValue ?? '');
            }
          } else {
            flat[key] = String(value ?? '');
          }
        }
        setConfigContent(flat);
      } else {
        setConfigContent({});
      }
    } else {
      setError(response.error || 'Failed to fetch config content');
      setConfigContent({});
    }
    
    setLoading(false);
  };

  const handleSave = async () => {
    if (!moduleName) return;
    
    setLoading(true);
    setError('');
    setSaveSuccess(false);
    
    const response = await apiService.updateConfig(moduleName, configContent);
    
    if (response.success) {
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } else {
      setError(response.error || 'Failed to save config');
    }
    
    setLoading(false);
  };

  const handleChange = (key: string, value: string) => {
    setConfigContent((prev) => ({ ...prev, [key]: value }));
  };

  useEffect(() => {
    fetchConfigContent();
  }, [moduleName]);

  const handleBack = () => {
    navigate(`/modules/${moduleName}`);
  };

  return (
    <div className="module-config">
      <div className="module-config__header">
        <div className="module-config__header-left">
          <Button 
            variant="secondary" 
            size="small"
            onClick={handleBack}
          >
            ← Back to Module
          </Button>
          <h1 className="module-config__title">
            Configuration: {moduleName}
          </h1>
        </div>
        <Button onClick={fetchConfigContent} variant="secondary" size="small">
          Refresh
        </Button>
      </div>

      {error && (
        <div className="module-config__error-banner">
          {error}
        </div>
      )}

      <Card className="module-config__content">
        <div className="module-config__content-header">
          <div>
            <h2 className="module-config__section-title">Edit Configuration</h2>
            {configPath && (
              <p className="module-config__path">Path: {configPath}</p>
            )}
          </div>
          {Object.keys(configContent).length > 0 && (
            <Button
              onClick={handleSave}
              variant="primary"
              size="small"
              loading={loading}
            >
              Save Changes
            </Button>
          )}
        </div>

        {saveSuccess && (
          <div className="module-config__success">
            Configuration saved successfully!
          </div>
        )}

        {loading && Object.keys(configContent).length === 0 ? (
          <div className="module-config__loading">Loading configuration...</div>
        ) : Object.keys(configContent).length > 0 ? (
          <div className="module-config__form">
            {Object.entries(configContent).map(([key, value]) => (
              <div key={key} className="module-config__field">
                <label className="module-config__label">{key}</label>
                <input
                  type="text"
                  className="module-config__input"
                  value={value}
                  onChange={(e) => handleChange(key, e.target.value)}
                  disabled={loading}
                />
              </div>
            ))}
          </div>
        ) : (
          <div className="module-config__empty">
            {error ? 'Failed to load configuration' : 'No configuration found for this module'}
          </div>
        )}
      </Card>
    </div>
  );
};
