import { Credentials } from '../types/api';

const CREDENTIALS_STORAGE_KEY = 'luigi_credentials';

/**
 * Authentication Service
 * Handles login/logout and credential validation against static credentials file
 */
class AuthService {
  private credentials: Credentials | null = null;
  private staticCredentials: Map<string, string> = new Map();

  constructor() {
    this.loadStaticCredentials();
    this.loadStoredCredentials();
  }

  /**
   * Load static credentials from credentials.txt
   * In a real deployment, this would be loaded server-side
   * For demo purposes, we embed them here
   */
  private loadStaticCredentials() {
    // In production, these would be loaded from the credentials.txt file
    // via a backend endpoint that validates and returns authorized users
    // For this demo, we hardcode the default credentials
    this.staticCredentials.set('admin', 'changeme123');
  }

  /**
   * Load stored credentials from localStorage
   */
  private loadStoredCredentials() {
    try {
      const stored = localStorage.getItem(CREDENTIALS_STORAGE_KEY);
      if (stored) {
        this.credentials = JSON.parse(stored);
      }
    } catch (error) {
      console.error('Failed to load stored credentials:', error);
    }
  }

  /**
   * Validate credentials against static credentials
   */
  validateCredentials(username: string, password: string): boolean {
    const validPassword = this.staticCredentials.get(username);
    return validPassword === password;
  }

  /**
   * Login with username and password
   */
  login(username: string, password: string): boolean {
    if (this.validateCredentials(username, password)) {
      this.credentials = { username, password };
      localStorage.setItem(CREDENTIALS_STORAGE_KEY, JSON.stringify(this.credentials));
      return true;
    }
    return false;
  }

  /**
   * Logout and clear stored credentials
   */
  logout() {
    this.credentials = null;
    localStorage.removeItem(CREDENTIALS_STORAGE_KEY);
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    return this.credentials !== null;
  }

  /**
   * Get current credentials for API calls
   */
  getCredentials(): Credentials | null {
    return this.credentials;
  }

  /**
   * Get authorization header for API requests
   */
  getAuthHeader(): string {
    if (!this.credentials) {
      return '';
    }
    const encoded = btoa(`${this.credentials.username}:${this.credentials.password}`);
    return `Basic ${encoded}`;
  }
}

export const authService = new AuthService();
