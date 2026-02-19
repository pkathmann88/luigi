import React, { useEffect, useState } from 'react';
import { apiService } from '../services/apiService';
import { SoundModule, ModuleSounds, SoundFile } from '../types/api';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import './Sounds.css';

export const Sounds: React.FC = () => {
  const [modules, setModules] = useState<SoundModule[]>([]);
  const [selectedModule, setSelectedModule] = useState<string>('');
  const [moduleSounds, setModuleSounds] = useState<ModuleSounds | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [playingSound, setPlayingSound] = useState<string | null>(null);

  const fetchModules = async () => {
    setLoading(true);
    setError('');
    
    const response = await apiService.getSoundModules();
    
    if (response.success && response.data) {
      setModules(response.data.modules || []);
    } else {
      setError(response.error || 'Failed to fetch sound modules');
    }
    
    setLoading(false);
  };

  const fetchModuleSounds = async (moduleName: string) => {
    setLoading(true);
    setError('');
    setSelectedModule(moduleName);
    
    const response = await apiService.getModuleSounds(moduleName);
    
    if (response.success && response.data) {
      setModuleSounds(response.data);
    } else {
      setError(response.error || 'Failed to fetch module sounds');
      setModuleSounds(null);
    }
    
    setLoading(false);
  };

  const handlePlaySound = async (fileName: string) => {
    if (!selectedModule) return;
    
    setPlayingSound(fileName);
    setError('');
    
    const response = await apiService.playSound(selectedModule, fileName);
    
    if (!response.success) {
      setError(response.error || 'Failed to play sound');
    }
    
    // Clear playing state after a short delay
    setTimeout(() => {
      setPlayingSound(null);
    }, 1000);
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getFileIcon = (extension: string): string => {
    const iconMap: Record<string, string> = {
      wav: '🔊',
      mp3: '🎵',
      ogg: '🎶',
      flac: '🎼',
    };
    return iconMap[extension] || '🔉';
  };

  useEffect(() => {
    fetchModules();
  }, []);

  return (
    <div className="sounds">
      <div className="sounds__header">
        <h1 className="sounds__title">Sound Management</h1>
        <Button onClick={fetchModules} variant="secondary" size="small">
          Refresh
        </Button>
      </div>

      <div className="sounds__container">
        <Card className="sounds__sidebar">
          <h3>Modules with Sounds</h3>
          {modules.length === 0 && !loading ? (
            <p className="sounds__empty">No modules with sound capability found</p>
          ) : (
            <ul className="sounds__list">
              {modules.map((module) => (
                <li key={module.name}>
                  <button
                    className={`sounds__item ${
                      selectedModule === module.name ? 'sounds__item--active' : ''
                    }`}
                    onClick={() => fetchModuleSounds(module.name)}
                  >
                    <div className="sounds__item-name">{module.name}</div>
                    {module.description && (
                      <div className="sounds__item-description">{module.description}</div>
                    )}
                  </button>
                </li>
              ))}
            </ul>
          )}
        </Card>

        <Card className="sounds__content">
          <div className="sounds__content-header">
            <h3>Sound Files</h3>
            {moduleSounds && moduleSounds.exists && (
              <span className="sounds__file-count">
                {moduleSounds.count} file{moduleSounds.count !== 1 ? 's' : ''}
              </span>
            )}
          </div>

          {loading ? (
            <div className="sounds__loading">Loading...</div>
          ) : error ? (
            <div className="sounds__error">{error}</div>
          ) : !selectedModule ? (
            <div className="sounds__empty">
              Select a module to view its sound files
            </div>
          ) : !moduleSounds ? (
            <div className="sounds__empty">
              No sound data available
            </div>
          ) : !moduleSounds.exists ? (
            <div className="sounds__warning">
              <p>Sound directory does not exist:</p>
              <code>{moduleSounds.sound_directory}</code>
            </div>
          ) : moduleSounds.files.length === 0 ? (
            <div className="sounds__empty">
              No sound files found in {moduleSounds.sound_directory}
            </div>
          ) : (
            <div className="sounds__files">
              <div className="sounds__directory">
                <strong>Directory:</strong> {moduleSounds.sound_directory}
              </div>
              <div className="sounds__file-list">
                {moduleSounds.files.map((file: SoundFile) => (
                  <div key={file.name} className="sounds__file">
                    <div className="sounds__file-icon">
                      {getFileIcon(file.extension)}
                    </div>
                    <div className="sounds__file-info">
                      <div className="sounds__file-name">{file.name}</div>
                      <div className="sounds__file-meta">
                        {formatFileSize(file.size)} • {formatDate(file.modified)}
                      </div>
                    </div>
                    <Button
                      size="small"
                      onClick={() => handlePlaySound(file.name)}
                      disabled={playingSound === file.name}
                      loading={playingSound === file.name}
                    >
                      {playingSound === file.name ? 'Playing...' : 'Play'}
                    </Button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </Card>
      </div>
    </div>
  );
};
