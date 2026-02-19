import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { apiService } from '../services/apiService';
import { ModuleSounds as ModuleSoundsData, SoundFile } from '../types/api';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import './ModuleSounds.css';

export const ModuleSounds: React.FC = () => {
  const { moduleName } = useParams<{ moduleName: string }>();
  const navigate = useNavigate();
  const [moduleSounds, setModuleSounds] = useState<ModuleSoundsData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [playingSound, setPlayingSound] = useState<string | null>(null);

  const fetchModuleSounds = async () => {
    if (!moduleName) return;
    
    setLoading(true);
    setError('');
    
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
    if (!moduleName) return;
    
    setPlayingSound(fileName);
    setError('');
    
    const response = await apiService.playSound(moduleName, fileName);
    
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
    fetchModuleSounds();
  }, [moduleName]);

  return (
    <div className="module-sounds">
      <div className="module-sounds__header">
        <div className="module-sounds__header-left">
          <Button 
            variant="secondary" 
            size="small"
            onClick={() => navigate(`/modules/${moduleName}`)}
          >
            ← Back to Module
          </Button>
          <h1 className="module-sounds__title">Sounds - {moduleName}</h1>
        </div>
        <Button onClick={fetchModuleSounds} variant="secondary" size="small">
          Refresh
        </Button>
      </div>

      {error && (
        <div className="module-sounds__error-banner">
          {error}
        </div>
      )}

      <Card className="module-sounds__content">
        {loading ? (
          <div className="module-sounds__loading">Loading...</div>
        ) : !moduleSounds ? (
          <div className="module-sounds__empty">
            No sound data available
          </div>
        ) : !moduleSounds.exists ? (
          <div className="module-sounds__warning">
            <p>Sound directory does not exist:</p>
            <code>{moduleSounds.sound_directory}</code>
          </div>
        ) : moduleSounds.files.length === 0 ? (
          <div className="module-sounds__empty">
            No sound files found in {moduleSounds.sound_directory}
          </div>
        ) : (
          <div className="module-sounds__files">
            <div className="module-sounds__directory">
              <strong>Directory:</strong> {moduleSounds.sound_directory}
            </div>
            <div className="module-sounds__info">
              {moduleSounds.count} sound file{moduleSounds.count !== 1 ? 's' : ''}
            </div>
            <div className="module-sounds__file-list">
              {moduleSounds.files.map((file: SoundFile) => (
                <div key={file.name} className="module-sounds__file">
                  <div className="module-sounds__file-icon">
                    {getFileIcon(file.extension)}
                  </div>
                  <div className="module-sounds__file-info">
                    <div className="module-sounds__file-name">{file.name}</div>
                    <div className="module-sounds__file-meta">
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
  );
};
