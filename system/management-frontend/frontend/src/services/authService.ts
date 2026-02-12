import { Credentials } from '../types/api';

const CREDENTIALS_STORAGE_KEY = 'luigi_credentials';

/**
 * Authentication Service
 * Handles login/logout and credential storage
 * 
 * SECURITY WARNINGS:
 * - This is a SIMPLE authentication system for local network use ONLY
 * - Credentials are stored in localStorage (vulnerable to XSS attacks)
 * - Credentials are validated ONLY on the backend (frontend just stores them)
 * - In production, use proper authentication:
 *   - Server-side session management
 *   - httpOnly cookies
 *   - OAuth/OIDC providers
 *   - JWT tokens with refresh mechanism
 * - Always use HTTPS to protect credentials in transit
 */
class AuthService {
  private credentials: Credentials | null = null;

  constructor() {
    this.loadStoredCredentials();
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
   * Store credentials after successful backend authentication
   * This method should only be called after backend validates credentials
   */
  login(username: string, password: string): void {
    this.credentials = { username, password };
    localStorage.setItem(CREDENTIALS_STORAGE_KEY, JSON.stringify(this.credentials));
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
