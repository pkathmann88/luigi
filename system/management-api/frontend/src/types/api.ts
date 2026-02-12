export interface ModuleRegistry {
  module_path: string;
  name: string;
  version: string;
  category: string;
  description?: string;
  installed_at: string;
  updated_at: string;
  installed_by: string;
  install_method: string;
  status: 'active' | 'installed' | 'failed' | 'removed';
  capabilities?: string[];
  dependencies?: string[];
  apt_packages?: string[];
  author?: string;
  hardware?: {
    gpio_pins?: number[];
    sensors?: string[];
  };
  provides?: string[];
  service_name?: string | null;
  config_path?: string | null;
  log_path?: string | null;
  _registryFile?: string;
}

export interface Module {
  name: string;
  path: string;
  category: string;
  fullPath: string;
  metadata?: Record<string, unknown> | null;
  status?: 'active' | 'inactive' | 'failed' | 'unknown';
  enabled?: boolean;
  pid?: number;
  uptime?: number;
  memory?: number;
  registry?: ModuleRegistry | null;
}

export interface LogFile {
  name: string;
  path: string;
  fullPath: string;
  size: number;
  modified: string;
}

export interface ConfigFile {
  name: string;
  path: string;
  fullPath: string;
  size: number;
  modified: string;
}

export interface ConfigContent {
  file: string;
  path: string;
  content: string;
  parsed: Record<string, unknown> | null;
  format: string;
}

export interface SystemStatus {
  uptime: number;
  cpu: {
    usage: number;
    temperature?: number;
  };
  memory: {
    total: number;
    used: number;
    free: number;
    percent: number;
  };
  disk: {
    total: number;
    used: number;
    free: number;
    percent: number;
  };
  timestamp: string;
}

export interface LogEntry {
  timestamp: string;
  level: string;
  message: string;
}

export interface ConfigEntry {
  key: string;
  value: string;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface Credentials {
  username: string;
  password: string;
}
