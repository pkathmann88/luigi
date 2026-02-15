import { authService } from './authService';
import { Module, ModuleListItem, SystemStatus, ApiResponse, LogFile, ConfigFile, ConfigContent } from '../types/api';

const API_BASE_URL = import.meta.env.VITE_API_URL || '';

/**
 * API Service
 * Handles all communication with the Luigi Management API
 */
class ApiService {
  /**
   * Make authenticated API request
   */
  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const headers = new Headers(options.headers);
    
    // Add authentication header
    const authHeader = authService.getAuthHeader();
    if (authHeader) {
      headers.set('Authorization', authHeader);
    }
    
    // Add content type for JSON requests
    if (options.body && !headers.has('Content-Type')) {
      headers.set('Content-Type', 'application/json');
    }

    try {
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        ...options,
        headers,
      });

      // Handle authentication errors
      if (response.status === 401) {
        authService.logout();
        // Only redirect if not already on login page
        if (!window.location.pathname.includes('/login')) {
          // NOTE: Using window.location for navigation causes full page reload
          // This is intentional for authentication failures to ensure clean state
          // In a more sophisticated implementation, use React Router context
          window.location.href = '/login';
        }
        throw new Error('Authentication failed');
      }

      const data = await response.json();
      
      if (!response.ok) {
        return {
          success: false,
          error: data.error || data.message || 'Request failed',
        };
      }

      return {
        success: true,
        data,
      };
    } catch (error) {
      console.error('API request failed:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Health check
   */
  async checkHealth() {
    return this.request('/health');
  }

  // ============================================================================
  // Module Management
  // ============================================================================

  /**
   * Get all modules (minimal list data)
   */
  async getModules(): Promise<ApiResponse<{ modules: ModuleListItem[] }>> {
    return this.request('/api/modules');
  }

  /**
   * Get specific module details (comprehensive data)
   */
  async getModule(name: string): Promise<ApiResponse<Module>> {
    return this.request(`/api/modules/${name}`);
  }

  /**
   * Start a module
   */
  async startModule(name: string): Promise<ApiResponse<void>> {
    return this.request(`/api/modules/${name}/start`, {
      method: 'POST',
    });
  }

  /**
   * Stop a module
   */
  async stopModule(name: string): Promise<ApiResponse<void>> {
    return this.request(`/api/modules/${name}/stop`, {
      method: 'POST',
    });
  }

  /**
   * Restart a module
   */
  async restartModule(name: string): Promise<ApiResponse<void>> {
    return this.request(`/api/modules/${name}/restart`, {
      method: 'POST',
    });
  }

  // ============================================================================
  // System Operations
  // ============================================================================

  /**
   * Get system status
   */
  async getSystemStatus(): Promise<ApiResponse<SystemStatus>> {
    return this.request('/api/system/status');
  }

  /**
   * Reboot system
   */
  async rebootSystem(): Promise<ApiResponse<void>> {
    return this.request('/api/system/reboot', {
      method: 'POST',
      body: JSON.stringify({ confirm: true }),
    });
  }

  /**
   * Shutdown system
   */
  async shutdownSystem(): Promise<ApiResponse<void>> {
    return this.request('/api/system/shutdown', {
      method: 'POST',
      body: JSON.stringify({ confirm: true }),
    });
  }

  /**
   * Update system
   */
  async updateSystem(): Promise<ApiResponse<void>> {
    return this.request('/api/system/update', {
      method: 'POST',
    });
  }

  /**
   * Clean up system
   */
  async cleanupSystem(): Promise<ApiResponse<void>> {
    return this.request('/api/system/cleanup', {
      method: 'POST',
    });
  }

  // ============================================================================
  // Log Management
  // ============================================================================

  /**
   * List all log files
   */
  async getLogs(): Promise<ApiResponse<{ files: LogFile[] }>> {
    return this.request('/api/logs');
  }

  /**
   * Get logs for a specific module
   */
  async getModuleLogs(
    module: string,
    lines: number = 100,
    search?: string
  ): Promise<ApiResponse<{ lines: string[]; file: string; count: number }>> {
    const params = new URLSearchParams({ lines: lines.toString() });
    if (search) {
      params.append('search', search);
    }
    return this.request(`/api/logs/${module}?${params}`);
  }

  // ============================================================================
  // Configuration Management
  // ============================================================================

  /**
   * List all configurations
   */
  async getConfigs(): Promise<ApiResponse<{ configs: ConfigFile[] }>> {
    return this.request('/api/config');
  }

  /**
   * Get configuration for a module
   */
  async getConfig(module: string): Promise<ApiResponse<ConfigContent>> {
    return this.request(`/api/config/${module}`);
  }

  /**
   * Update configuration
   */
  async updateConfig(
    module: string,
    config: Record<string, string>
  ): Promise<ApiResponse<void>> {
    return this.request(`/api/config/${module}`, {
      method: 'PUT',
      body: JSON.stringify(config),
    });
  }

  // ============================================================================
  // Monitoring
  // ============================================================================

  /**
   * Get system metrics
   */
  async getMetrics(): Promise<ApiResponse<SystemStatus>> {
    return this.request('/api/monitoring/metrics');
  }

  // ============================================================================
  // Sound Management
  // ============================================================================

  /**
   * List all modules with sound capability
   */
  async getSoundModules(): Promise<ApiResponse<{ modules: import('../types/api').SoundModule[]; count: number }>> {
    return this.request('/api/sounds');
  }

  /**
   * Get sound files for a module
   */
  async getModuleSounds(moduleName: string): Promise<ApiResponse<import('../types/api').ModuleSounds>> {
    return this.request(`/api/sounds/${moduleName}`);
  }

  /**
   * Play a sound file
   */
  async playSound(moduleName: string, fileName: string): Promise<ApiResponse<{ success: boolean; message: string }>> {
    return this.request(`/api/sounds/${moduleName}/play`, {
      method: 'POST',
      body: JSON.stringify({ file: fileName }),
    });
  }
}

export const apiService = new ApiService();
