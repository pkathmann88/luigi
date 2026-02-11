import { Credentials } from '../types/api';

const CREDENTIALS_STORAGE_KEY = 'luigi_credentials';

/**
 * Authentication Service
 * Handles login/logout and credential validation against static credentials file
 * 
 * SECURITY WARNINGS:
 * - This is a SIMPLE authentication system for local network use ONLY
 * - Credentials are stored in localStorage (vulnerable to XSS attacks)
 * - Credentials are hardcoded in client code (visible to anyone)
 * - In production, use proper authentication:
 *   - Server-side session management
 *   - httpOnly cookies
 *   - OAuth/OIDC providers
 *   - JWT tokens with refresh mechanism
 * - Always use HTTPS to protect credentials in transit
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
   * 
   * WARNING: In production, this should be loaded server-side and validated
   * via an authentication endpoint. The current implementation hardcodes
   * credentials in the client, making them visible to anyone with browser access.
   * 
   * IMPORTANT: These credentials MUST match the backend credentials in:
   *   /.env.example (template file)
   *   /etc/luigi/system/management-api/.env (deployed config)
   * If you change credentials here, you must also update the .env file and vice versa.
   * 
   * TODO: Implement proper server-side authentication endpoint
   */
  private loadStaticCredentials() {
    // SECURITY WARNING: These credentials are hardcoded and visible to anyone
    // In production, validate credentials server-side via an /auth endpoint
    // 
    // SYNC WITH: /.env.example and /etc/luigi/system/management-api/.env
    this.staticCredentials.set('admin', 'changeme123');
  }

  /**
   * Load stored credentials from localStorage
   * 
   * WARNING: localStorage is vulnerable to XSS attacks. In production,
   * use httpOnly cookies or proper session management instead.
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
