import React, { useEffect, useState } from 'react';
import { apiService } from '../services/apiService';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import './Config.css';

export const Config: React.FC = () => {
  const [configs, setConfigs] = useState<string[]>([]);
  const [selectedConfig, setSelectedConfig] = useState<string>('');
  const [configContent, setConfigContent] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [saveSuccess, setSaveSuccess] = useState(false);

  const fetchConfigs = async () => {
    setLoading(true);
    setError('');
    
    const response = await apiService.getConfigs();
    
    if (response.success && response.data) {
      setConfigs(response.data.configs || []);
    } else {
      setError(response.error || 'Failed to fetch configs');
    }
    
    setLoading(false);
  };

  const fetchConfigContent = async (configName: string) => {
    setLoading(true);
    setError('');
    setSaveSuccess(false);
    setSelectedConfig(configName);
    
    const response = await apiService.getConfig(configName);
    
    if (response.success && response.data) {
      setConfigContent(response.data);
    } else {
      setError(response.error || 'Failed to fetch config content');
      setConfigContent({});
    }
    
    setLoading(false);
  };

  const handleSave = async () => {
    if (!selectedConfig) return;
    
    setLoading(true);
    setError('');
    setSaveSuccess(false);
    
    const response = await apiService.updateConfig(selectedConfig, configContent);
    
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
    fetchConfigs();
  }, []);

  return (
    <div className="config">
      <div className="config__header">
        <h1 className="config__title">Configuration Management</h1>
        <Button onClick={fetchConfigs} variant="secondary" size="small">
          Refresh
        </Button>
      </div>

      <div className="config__container">
        <Card className="config__sidebar">
          <h3>Config Files</h3>
          {configs.length === 0 && !loading ? (
            <p className="config__empty">No config files found</p>
          ) : (
            <ul className="config__list">
              {configs.map((config) => (
                <li key={config}>
                  <button
                    className={`config__item ${
                      selectedConfig === config ? 'config__item--active' : ''
                    }`}
                    onClick={() => fetchConfigContent(config)}
                  >
                    {config}
                  </button>
                </li>
              ))}
            </ul>
          )}
        </Card>

        <Card className="config__content">
          <div className="config__content-header">
            <h3>Configuration</h3>
            {selectedConfig && (
              <Button
                onClick={handleSave}
                variant="primary"
                size="small"
                loading={loading}
                disabled={Object.keys(configContent).length === 0}
              >
                Save Changes
              </Button>
            )}
          </div>

          {saveSuccess && (
            <div className="config__success">
              Configuration saved successfully!
            </div>
          )}

          {error && <div className="config__error">{error}</div>}

          {loading && !Object.keys(configContent).length ? (
            <div className="config__loading">Loading...</div>
          ) : Object.keys(configContent).length > 0 ? (
            <div className="config__form">
              {Object.entries(configContent).map(([key, value]) => (
                <div key={key} className="config__field">
                  <label className="config__label">{key}</label>
                  <input
                    type="text"
                    className="config__input"
                    value={value}
                    onChange={(e) => handleChange(key, e.target.value)}
                  />
                </div>
              ))}
            </div>
          ) : (
            <div className="config__empty">
              Select a config file to edit
            </div>
          )}
        </Card>
      </div>
    </div>
  );
};
