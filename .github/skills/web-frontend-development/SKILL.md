---
name: web-frontend-development
description: Comprehensive guide for modern web-frontend development with state-of-the-art technologies. Covers React, Vue, vanilla JavaScript, TypeScript, responsive design, performance optimization, security, and cross-browser support (Chrome, Edge, Firefox). Use when developing web UIs, dashboards, or browser-based interfaces.
license: MIT
---

# Web-Frontend Development

This skill provides comprehensive guidance for developing **modern web-frontend applications** using state-of-the-art technologies and best practices. Emphasis on cross-browser compatibility (Chrome, Edge, Firefox), performance, security, and maintainable code architecture.

## When to Use This Skill

Use this skill when:
- Developing web-based user interfaces or dashboards
- Creating responsive, mobile-first web applications
- Building single-page applications (SPAs)
- Implementing progressive web apps (PWAs)
- Integrating frontend with backend APIs (REST, WebSocket, GraphQL)
- Optimizing web application performance
- Ensuring cross-browser compatibility
- Setting up modern build tooling and workflows
- Creating component-based architectures
- Implementing state management solutions
- Building real-time web applications
- Deploying frontend applications

## Browser Support Requirements

**MANDATORY:** All code must support:
- **Chrome/Chromium** - Latest stable + 1 previous major version
- **Edge** - Latest stable (Chromium-based)
- **Firefox** - Latest stable + 1 previous major version

**Testing Requirements:**
- Test in all three browsers before committing
- Use feature detection, not browser detection
- Provide graceful degradation for unsupported features
- Include appropriate polyfills when necessary

**Browser Features Matrix:**
```javascript
// Always check feature support
const supportsWebP = document.createElement('canvas')
  .toDataURL('image/webp').indexOf('data:image/webp') === 0;

const supportsIntersectionObserver = 'IntersectionObserver' in window;

const supportsServiceWorker = 'serviceWorker' in navigator;
```

## Technology Stack

### Core Technologies

**HTML5**
- Semantic HTML elements
- SEO-friendly structure
- Meta tags for PWAs

**CSS3**
- Modern CSS features (Grid, Flexbox, Custom Properties)
- CSS Modules or scoped styles
- CSS-in-JS when appropriate
- Responsive design with media queries
- Dark mode support

**JavaScript (ES2020+)**
- Modern syntax (async/await, destructuring, optional chaining)
- Modules (ESM)
- TypeScript for type safety (recommended)
- Strict mode enabled

### Recommended Frameworks

**React (Recommended for complex SPAs)**
- Version 18+ with hooks
- Functional components preferred
- Context API or state management libraries
- React Router for routing
- React Query for server state

**Vue (Alternative for component-based apps)**
- Version 3+ with Composition API
- Single-file components
- Vue Router for routing
- Pinia for state management

**Vanilla JavaScript (Simple interfaces)**
- Web Components for reusability
- ES Modules
- No framework overhead

### TypeScript

**HIGHLY RECOMMENDED** for all projects:
```typescript
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node"
  }
}
```

### Build Tools

**Vite (Recommended)**
- Fast development server
- Optimized production builds
- Built-in TypeScript support
- Plugin ecosystem

```javascript
// vite.config.js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    target: 'es2020',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
        },
      },
    },
  },
  server: {
    port: 3000,
    open: true,
  },
});
```

**Webpack (Alternative)**
- More configuration required
- Mature ecosystem
- Fine-grained control

**esbuild/SWC**
- Ultra-fast builds
- Used internally by Vite
- Can be used standalone

### Package Management

**npm (Default)**
```bash
npm install <package>
npm ci  # For CI/CD (faster, uses lock file exactly)
```

**pnpm (Faster alternative)**
```bash
pnpm install <package>
pnpm install  # Faster installs, saves disk space
```

**yarn (Alternative)**
```bash
yarn add <package>
yarn install
```

## Project Structure

### React Application Structure

```
src/
├── components/          # Reusable components
│   ├── common/         # Shared components (Button, Input, Card)
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.module.css
│   │   │   ├── Button.test.tsx
│   │   │   └── index.ts
│   │   └── ...
│   └── features/       # Feature-specific components
│       ├── Dashboard/
│       ├── Settings/
│       └── ...
├── hooks/              # Custom React hooks
│   ├── useApi.ts
│   ├── useLocalStorage.ts
│   └── ...
├── contexts/           # React contexts
│   ├── AuthContext.tsx
│   ├── ThemeContext.tsx
│   └── ...
├── services/           # API and external services
│   ├── api.ts
│   ├── websocket.ts
│   └── ...
├── utils/              # Utility functions
│   ├── formatters.ts
│   ├── validators.ts
│   └── ...
├── types/              # TypeScript type definitions
│   ├── api.ts
│   ├── models.ts
│   └── ...
├── styles/             # Global styles
│   ├── variables.css
│   ├── reset.css
│   └── global.css
├── assets/             # Static assets
│   ├── images/
│   ├── fonts/
│   └── icons/
├── App.tsx             # Root component
├── main.tsx            # Entry point
└── vite-env.d.ts       # Vite type definitions
```

### Vanilla JavaScript Structure

```
src/
├── js/
│   ├── components/     # Web Components or modules
│   ├── services/       # API services
│   ├── utils/          # Helper functions
│   └── main.js         # Entry point
├── css/
│   ├── components/     # Component styles
│   ├── base/           # Reset, typography
│   ├── utilities/      # Utility classes
│   └── main.css        # Main stylesheet
├── assets/
│   ├── images/
│   └── fonts/
└── index.html          # HTML entry
```

## Component Development

### React Component Pattern

```tsx
import React, { useState, useEffect, useCallback } from 'react';
import styles from './Button.module.css';

interface ButtonProps {
  /** Button text content */
  children: React.ReactNode;
  /** Button variant */
  variant?: 'primary' | 'secondary' | 'danger';
  /** Size variant */
  size?: 'small' | 'medium' | 'large';
  /** Disabled state */
  disabled?: boolean;
  /** Loading state */
  loading?: boolean;
  /** Click handler */
  onClick?: (event: React.MouseEvent<HTMLButtonElement>) => void;
  /** Additional CSS classes */
  className?: string;
}

/**
 * Button component with multiple variants.
 * 
 * @example
 * ```tsx
 * <Button variant="primary" onClick={handleClick}>
 *   Click Me
 * </Button>
 * ```
 */
export const Button: React.FC<ButtonProps> = ({
  children,
  variant = 'primary',
  size = 'medium',
  disabled = false,
  loading = false,
  onClick,
  className,
}) => {
  const handleClick = useCallback(
    (event: React.MouseEvent<HTMLButtonElement>) => {
      if (!disabled && !loading && onClick) {
        onClick(event);
      }
    },
    [disabled, loading, onClick]
  );

  const buttonClasses = [
    styles.button,
    styles[variant],
    styles[size],
    loading && styles.loading,
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <button
      type="button"
      className={buttonClasses}
      onClick={handleClick}
      disabled={disabled || loading}
    >
      {loading && <span className={styles.spinner} />}
      <span className={styles.content}>{children}</span>
    </button>
  );
};
```

### Vue Component Pattern

```vue
<template>
  <button
    :class="buttonClasses"
    :disabled="disabled || loading"
    @click="handleClick"
  >
    <span v-if="loading" class="spinner" />
    <span class="content">
      <slot />
    </span>
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue';

interface Props {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'small' | 'medium' | 'large';
  disabled?: boolean;
  loading?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'medium',
  disabled: false,
  loading: false,
});

const emit = defineEmits<{
  click: [event: MouseEvent];
}>();

const buttonClasses = computed(() => ({
  button: true,
  [props.variant]: true,
  [props.size]: true,
  loading: props.loading,
}));

const handleClick = (event: MouseEvent) => {
  if (!props.disabled && !props.loading) {
    emit('click', event);
  }
};
</script>

<style scoped>
.button {
  /* Button styles */
}
</style>
```

### Web Component Pattern

```javascript
class CustomButton extends HTMLElement {
  static get observedAttributes() {
    return ['variant', 'size', 'disabled', 'loading'];
  }

  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
  }

  connectedCallback() {
    this.render();
    this.addEventListener('click', this.handleClick);
  }

  disconnectedCallback() {
    this.removeEventListener('click', this.handleClick);
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (oldValue !== newValue) {
      this.render();
    }
  }

  handleClick = (event) => {
    if (this.disabled || this.loading) {
      event.preventDefault();
      event.stopPropagation();
      return;
    }
    
    this.dispatchEvent(
      new CustomEvent('button-click', {
        bubbles: true,
        composed: true,
        detail: { event },
      })
    );
  };

  get variant() {
    return this.getAttribute('variant') || 'primary';
  }

  get size() {
    return this.getAttribute('size') || 'medium';
  }

  get disabled() {
    return this.hasAttribute('disabled');
  }

  get loading() {
    return this.hasAttribute('loading');
  }

  render() {
    this.shadowRoot.innerHTML = `
      <style>
        :host {
          display: inline-block;
        }
        button {
          /* Button styles */
        }
      </style>
      <button
        class="${this.variant} ${this.size}"
        ${this.disabled || this.loading ? 'disabled' : ''}
      >
        ${this.loading ? '<span class="spinner"></span>' : ''}
        <slot></slot>
      </button>
    `;
  }
}

customElements.define('custom-button', CustomButton);
```

## State Management

### React Context Pattern

```tsx
import React, { createContext, useContext, useReducer, ReactNode } from 'react';

interface AppState {
  user: User | null;
  theme: 'light' | 'dark';
  isLoading: boolean;
}

type AppAction =
  | { type: 'SET_USER'; payload: User | null }
  | { type: 'SET_THEME'; payload: 'light' | 'dark' }
  | { type: 'SET_LOADING'; payload: boolean };

const initialState: AppState = {
  user: null,
  theme: 'light',
  isLoading: false,
};

const AppStateContext = createContext<AppState | undefined>(undefined);
const AppDispatchContext = createContext<React.Dispatch<AppAction> | undefined>(
  undefined
);

function appReducer(state: AppState, action: AppAction): AppState {
  switch (action.type) {
    case 'SET_USER':
      return { ...state, user: action.payload };
    case 'SET_THEME':
      return { ...state, theme: action.payload };
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    default:
      return state;
  }
}

export function AppProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(appReducer, initialState);

  return (
    <AppStateContext.Provider value={state}>
      <AppDispatchContext.Provider value={dispatch}>
        {children}
      </AppDispatchContext.Provider>
    </AppStateContext.Provider>
  );
}

export function useAppState() {
  const context = useContext(AppStateContext);
  if (context === undefined) {
    throw new Error('useAppState must be used within AppProvider');
  }
  return context;
}

export function useAppDispatch() {
  const context = useContext(AppDispatchContext);
  if (context === undefined) {
    throw new Error('useAppDispatch must be used within AppProvider');
  }
  return context;
}
```

### Zustand (Lightweight Alternative)

```typescript
import create from 'zustand';
import { persist } from 'zustand/middleware';

interface AppStore {
  user: User | null;
  theme: 'light' | 'dark';
  isLoading: boolean;
  setUser: (user: User | null) => void;
  setTheme: (theme: 'light' | 'dark') => void;
  setLoading: (loading: boolean) => void;
}

export const useStore = create<AppStore>()(
  persist(
    (set) => ({
      user: null,
      theme: 'light',
      isLoading: false,
      setUser: (user) => set({ user }),
      setTheme: (theme) => set({ theme }),
      setLoading: (isLoading) => set({ isLoading }),
    }),
    {
      name: 'app-storage',
      partialize: (state) => ({ theme: state.theme }), // Persist only theme
    }
  )
);
```

## API Integration

### Fetch API with Error Handling

```typescript
interface ApiError {
  message: string;
  status: number;
  errors?: Record<string, string[]>;
}

class HttpError extends Error {
  constructor(
    public status: number,
    message: string,
    public errors?: Record<string, string[]>
  ) {
    super(message);
    this.name = 'HttpError';
  }
}

interface FetchOptions extends RequestInit {
  timeout?: number;
}

export async function fetchWithTimeout(
  url: string,
  options: FetchOptions = {}
): Promise<Response> {
  const { timeout = 8000, ...fetchOptions } = options;

  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(url, {
      ...fetchOptions,
      signal: controller.signal,
    });
    clearTimeout(id);
    return response;
  } catch (error) {
    clearTimeout(id);
    if (error.name === 'AbortError') {
      throw new Error('Request timeout');
    }
    throw error;
  }
}

export async function apiRequest<T>(
  endpoint: string,
  options: FetchOptions = {}
): Promise<T> {
  const url = `${import.meta.env.VITE_API_URL}${endpoint}`;
  
  const defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // Add authentication token if available
  const token = localStorage.getItem('auth_token');
  if (token) {
    defaultHeaders['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetchWithTimeout(url, {
    ...options,
    headers: {
      ...defaultHeaders,
      ...options.headers,
    },
  });

  if (!response.ok) {
    const errorData: ApiError = await response.json().catch(() => ({
      message: response.statusText,
      status: response.status,
    }));

    throw new HttpError(
      response.status,
      errorData.message,
      errorData.errors
    );
  }

  return response.json();
}

// Usage examples
export const api = {
  get: <T>(endpoint: string, options?: FetchOptions) =>
    apiRequest<T>(endpoint, { ...options, method: 'GET' }),

  post: <T>(endpoint: string, data: unknown, options?: FetchOptions) =>
    apiRequest<T>(endpoint, {
      ...options,
      method: 'POST',
      body: JSON.stringify(data),
    }),

  put: <T>(endpoint: string, data: unknown, options?: FetchOptions) =>
    apiRequest<T>(endpoint, {
      ...options,
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  delete: <T>(endpoint: string, options?: FetchOptions) =>
    apiRequest<T>(endpoint, { ...options, method: 'DELETE' }),
};
```

### React Query Integration

```tsx
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from './api';

interface User {
  id: string;
  name: string;
  email: string;
}

// Custom hook for fetching users
export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => api.get<User[]>('/users'),
    staleTime: 5 * 60 * 1000, // 5 minutes
    retry: 3,
  });
}

// Custom hook for creating a user
export function useCreateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (userData: Omit<User, 'id'>) =>
      api.post<User>('/users', userData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });
}

// Component usage
function UserList() {
  const { data: users, isLoading, error } = useUsers();
  const createUser = useCreateUser();

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      {users?.map((user) => (
        <div key={user.id}>{user.name}</div>
      ))}
    </div>
  );
}
```

### WebSocket Integration

```typescript
type WebSocketMessage = {
  type: string;
  payload: unknown;
};

class WebSocketManager {
  private ws: WebSocket | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;
  private listeners = new Map<string, Set<(payload: unknown) => void>>();

  constructor(private url: string) {}

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(this.url);

      this.ws.onopen = () => {
        console.log('WebSocket connected');
        this.reconnectAttempts = 0;
        resolve();
      };

      this.ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        reject(error);
      };

      this.ws.onclose = () => {
        console.log('WebSocket disconnected');
        this.reconnect();
      };

      this.ws.onmessage = (event) => {
        try {
          const message: WebSocketMessage = JSON.parse(event.data);
          this.handleMessage(message);
        } catch (error) {
          console.error('Failed to parse WebSocket message:', error);
        }
      };
    });
  }

  private reconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('Max reconnection attempts reached');
      return;
    }

    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts);
    this.reconnectAttempts++;

    console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);
    setTimeout(() => this.connect(), delay);
  }

  private handleMessage(message: WebSocketMessage): void {
    const listeners = this.listeners.get(message.type);
    if (listeners) {
      listeners.forEach((callback) => callback(message.payload));
    }
  }

  on(type: string, callback: (payload: unknown) => void): () => void {
    if (!this.listeners.has(type)) {
      this.listeners.set(type, new Set());
    }
    this.listeners.get(type)!.add(callback);

    // Return unsubscribe function
    return () => {
      this.listeners.get(type)?.delete(callback);
    };
  }

  send(type: string, payload: unknown): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({ type, payload }));
    } else {
      console.error('WebSocket is not connected');
    }
  }

  disconnect(): void {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }
}

// React hook
export function useWebSocket(url: string) {
  const [ws] = useState(() => new WebSocketManager(url));
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    ws.connect()
      .then(() => setIsConnected(true))
      .catch(console.error);

    return () => {
      ws.disconnect();
      setIsConnected(false);
    };
  }, [url, ws]);

  return { ws, isConnected };
}
```

## Responsive Design

### Mobile-First Approach

```css
/* Base styles for mobile */
.container {
  padding: 1rem;
  max-width: 100%;
}

.grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1rem;
}

/* Tablet (≥768px) */
@media (min-width: 768px) {
  .container {
    padding: 2rem;
  }
  
  .grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Desktop (≥1024px) */
@media (min-width: 1024px) {
  .container {
    padding: 3rem;
    max-width: 1200px;
    margin: 0 auto;
  }
  
  .grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 2rem;
  }
}

/* Large desktop (≥1440px) */
@media (min-width: 1440px) {
  .grid {
    grid-template-columns: repeat(4, 1fr);
  }
}
```

### Container Queries (Modern Approach)

```css
.card-container {
  container-type: inline-size;
  container-name: card;
}

.card {
  padding: 1rem;
}

/* When container is at least 400px wide */
@container card (min-width: 400px) {
  .card {
    display: grid;
    grid-template-columns: 150px 1fr;
    gap: 1rem;
  }
}
```

### Responsive Typography

```css
:root {
  --font-size-base: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);
  --font-size-lg: clamp(1.25rem, 1.15rem + 0.5vw, 1.5rem);
  --font-size-xl: clamp(1.5rem, 1.35rem + 0.75vw, 2rem);
  --font-size-2xl: clamp(2rem, 1.7rem + 1.5vw, 3rem);
}

body {
  font-size: var(--font-size-base);
}

h1 {
  font-size: var(--font-size-2xl);
}

h2 {
  font-size: var(--font-size-xl);
}
```

## Performance Optimization

### Code Splitting

```tsx
import { lazy, Suspense } from 'react';

// Lazy load components
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

### Image Optimization

```tsx
function OptimizedImage({ src, alt, width, height }: ImageProps) {
  return (
    <picture>
      {/* WebP for modern browsers */}
      <source
        srcSet={`${src}.webp 1x, ${src}@2x.webp 2x`}
        type="image/webp"
      />
      {/* Fallback to JPEG */}
      <source
        srcSet={`${src}.jpg 1x, ${src}@2x.jpg 2x`}
        type="image/jpeg"
      />
      <img
        src={`${src}.jpg`}
        alt={alt}
        width={width}
        height={height}
        loading="lazy"
        decoding="async"
      />
    </picture>
  );
}
```

### Virtual Scrolling

```tsx
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
    overscan: 5,
  });

  return (
    <div ref={parentRef} style={{ height: '500px', overflow: 'auto' }}>
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.index}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualRow.size}px`,
              transform: `translateY(${virtualRow.start}px)`,
            }}
          >
            {items[virtualRow.index].name}
          </div>
        ))}
      </div>
    </div>
  );
}
```

### Memoization

```tsx
import { useMemo, useCallback } from 'react';

function ExpensiveComponent({ items, filter }: Props) {
  // Memoize expensive calculations
  const filteredItems = useMemo(() => {
    return items.filter(item => item.category === filter);
  }, [items, filter]);

  // Memoize callbacks
  const handleClick = useCallback((id: string) => {
    console.log('Clicked:', id);
  }, []);

  return (
    <ul>
      {filteredItems.map((item) => (
        <li key={item.id} onClick={() => handleClick(item.id)}>
          {item.name}
        </li>
      ))}
    </ul>
  );
}
```

### Debouncing and Throttling

```typescript
// Debounce: Wait until user stops typing
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  delay: number
): (...args: Parameters<T>) => void {
  let timeoutId: ReturnType<typeof setTimeout>;
  
  return (...args: Parameters<T>) => {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => func(...args), delay);
  };
}

// Throttle: Execute at most once per interval
export function throttle<T extends (...args: any[]) => any>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle: boolean;
  
  return (...args: Parameters<T>) => {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
}

// Usage in React
function SearchInput() {
  const [query, setQuery] = useState('');

  const debouncedSearch = useMemo(
    () =>
      debounce((value: string) => {
        api.search(value);
      }, 300),
    []
  );

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setQuery(value);
    debouncedSearch(value);
  };

  return <input value={query} onChange={handleChange} />;
}
```

## Security Best Practices

### XSS Prevention

```tsx
// ❌ Dangerous: Direct HTML injection
function UnsafeComponent({ userContent }: { userContent: string }) {
  return <div dangerouslySetInnerHTML={{ __html: userContent }} />;
}

// ✅ Safe: React escapes by default
function SafeComponent({ userContent }: { userContent: string }) {
  return <div>{userContent}</div>;
}

// ✅ Safe: Sanitize HTML if needed
import DOMPurify from 'dompurify';

function SafeHTMLComponent({ htmlContent }: { htmlContent: string }) {
  const sanitized = useMemo(
    () => DOMPurify.sanitize(htmlContent, { ALLOWED_TAGS: ['b', 'i', 'em', 'strong'] }),
    [htmlContent]
  );
  
  return <div dangerouslySetInnerHTML={{ __html: sanitized }} />;
}
```

### Content Security Policy

```html
<!-- index.html -->
<meta
  http-equiv="Content-Security-Policy"
  content="
    default-src 'self';
    script-src 'self' 'unsafe-inline';
    style-src 'self' 'unsafe-inline';
    img-src 'self' data: https:;
    font-src 'self';
    connect-src 'self' https://api.example.com;
    frame-ancestors 'none';
    base-uri 'self';
    form-action 'self';
  "
/>
```

### Secure Authentication

```typescript
// Store tokens securely
class AuthService {
  private static TOKEN_KEY = 'auth_token';
  private static REFRESH_TOKEN_KEY = 'refresh_token';

  static setTokens(accessToken: string, refreshToken: string): void {
    // Use sessionStorage for more security (cleared when tab closes)
    sessionStorage.setItem(this.TOKEN_KEY, accessToken);
    // Or localStorage for persistence (use with caution)
    localStorage.setItem(this.REFRESH_TOKEN_KEY, refreshToken);
  }

  static getAccessToken(): string | null {
    return sessionStorage.getItem(this.TOKEN_KEY);
  }

  static getRefreshToken(): string | null {
    return localStorage.getItem(this.REFRESH_TOKEN_KEY);
  }

  static clearTokens(): void {
    sessionStorage.removeItem(this.TOKEN_KEY);
    localStorage.removeItem(this.REFRESH_TOKEN_KEY);
  }

  static async refreshAccessToken(): Promise<string> {
    const refreshToken = this.getRefreshToken();
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }

    const response = await api.post<{ accessToken: string }>(
      '/auth/refresh',
      { refreshToken }
    );

    sessionStorage.setItem(this.TOKEN_KEY, response.accessToken);
    return response.accessToken;
  }
}
```

### Input Validation

```typescript
import { z } from 'zod';

// Define schema
const userSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain uppercase letter')
    .regex(/[a-z]/, 'Password must contain lowercase letter')
    .regex(/[0-9]/, 'Password must contain number'),
  age: z.number().int().min(18, 'Must be 18 or older'),
});

// Validate input
function validateUser(data: unknown) {
  try {
    return userSchema.parse(data);
  } catch (error) {
    if (error instanceof z.ZodError) {
      console.error('Validation errors:', error.errors);
    }
    throw error;
  }
}

// React form with validation
function SignupForm() {
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData);

    try {
      const validData = userSchema.parse(data);
      await api.post('/users', validData);
    } catch (error) {
      if (error instanceof z.ZodError) {
        const fieldErrors: Record<string, string> = {};
        error.errors.forEach((err) => {
          if (err.path[0]) {
            fieldErrors[err.path[0].toString()] = err.message;
          }
        });
        setErrors(fieldErrors);
      }
    }
  };

  return <form onSubmit={handleSubmit}>{/* Form fields */}</form>;
}
```

## Testing

### Unit Testing with Vitest

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from './Button';

describe('Button', () => {
  it('renders with children', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    
    fireEvent.click(screen.getByText('Click me'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('does not call onClick when disabled', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick} disabled>Click me</Button>);
    
    fireEvent.click(screen.getByText('Click me'));
    expect(handleClick).not.toHaveBeenCalled();
  });

  it('shows loading state', () => {
    render(<Button loading>Click me</Button>);
    expect(screen.getByRole('button')).toHaveAttribute('aria-busy', 'true');
  });
});
```

### Integration Testing

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { rest } from 'msw';
import { setupServer } from 'msw/node';
import { UserList } from './UserList';

const server = setupServer(
  rest.get('/api/users', (req, res, ctx) => {
    return res(
      ctx.json([
        { id: '1', name: 'John Doe', email: 'john@example.com' },
        { id: '2', name: 'Jane Smith', email: 'jane@example.com' },
      ])
    );
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('UserList Integration', () => {
  it('fetches and displays users', async () => {
    const queryClient = new QueryClient();
    
    render(
      <QueryClientProvider client={queryClient}>
        <UserList />
      </QueryClientProvider>
    );

    expect(screen.getByText('Loading...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
    });
  });

  it('handles error states', async () => {
    server.use(
      rest.get('/api/users', (req, res, ctx) => {
        return res(ctx.status(500));
      })
    );

    const queryClient = new QueryClient();
    
    render(
      <QueryClientProvider client={queryClient}>
        <UserList />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });
});
```

### E2E Testing with Playwright

```typescript
import { test, expect } from '@playwright/test';

test.describe('User Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000');
    await page.fill('input[name="email"]', 'test@example.com');
    await page.fill('input[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    await page.waitForURL('**/dashboard');
  });

  test('displays user information', async ({ page }) => {
    await expect(page.locator('h1')).toContainText('Dashboard');
    await expect(page.locator('[data-testid="user-name"]')).toBeVisible();
  });

  test('navigates to settings page', async ({ page }) => {
    await page.click('a[href="/settings"]');
    await page.waitForURL('**/settings');
    await expect(page.locator('h1')).toContainText('Settings');
  });

  test('updates user profile', async ({ page }) => {
    await page.click('a[href="/settings"]');
    await page.fill('input[name="name"]', 'New Name');
    await page.click('button[type="submit"]');
    await expect(page.locator('.success-message')).toBeVisible();
  });
});

// Browser compatibility tests
test.describe('Cross-browser compatibility', () => {
  test('works in Chrome', async ({ page, browserName }) => {
    test.skip(browserName !== 'chromium');
    // Chrome-specific tests
  });

  test('works in Firefox', async ({ page, browserName }) => {
    test.skip(browserName !== 'firefox');
    // Firefox-specific tests
  });

  test('works in Edge', async ({ page, browserName }) => {
    test.skip(browserName !== 'chromium' || !process.env.EDGE_TEST);
    // Edge-specific tests
  });
});
```

## Build and Deployment

### Environment Variables

```typescript
// .env.example
VITE_API_URL=http://localhost:8080
VITE_WS_URL=ws://localhost:8080
VITE_ENV=development

// .env.production
VITE_API_URL=https://api.production.com
VITE_WS_URL=wss://api.production.com
VITE_ENV=production
```

```typescript
// config.ts
interface Config {
  apiUrl: string;
  wsUrl: string;
  env: string;
}

export const config: Config = {
  apiUrl: import.meta.env.VITE_API_URL || 'http://localhost:8080',
  wsUrl: import.meta.env.VITE_WS_URL || 'ws://localhost:8080',
  env: import.meta.env.VITE_ENV || 'development',
};

// Type-safe environment variables
declare global {
  interface ImportMetaEnv {
    readonly VITE_API_URL: string;
    readonly VITE_WS_URL: string;
    readonly VITE_ENV: string;
  }
}
```

### Build Configuration

```javascript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig({
  plugins: [
    react(),
    visualizer({
      filename: 'dist/stats.html',
      open: false,
    }),
  ],
  build: {
    target: 'es2020',
    sourcemap: true,
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
      },
    },
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
          utils: ['date-fns', 'lodash-es'],
        },
      },
    },
    chunkSizeWarningLimit: 1000,
  },
  server: {
    port: 3000,
    open: true,
    cors: true,
  },
  preview: {
    port: 4173,
  },
});
```

### Progressive Web App

```typescript
// vite-plugin-pwa configuration
import { VitePWA } from 'vite-plugin-pwa';

VitePWA({
  registerType: 'autoUpdate',
  includeAssets: ['favicon.ico', 'apple-touch-icon.png', 'masked-icon.svg'],
  manifest: {
    name: 'My Application',
    short_name: 'App',
    description: 'My awesome Progressive Web App',
    theme_color: '#ffffff',
    background_color: '#ffffff',
    display: 'standalone',
    icons: [
      {
        src: 'pwa-192x192.png',
        sizes: '192x192',
        type: 'image/png',
      },
      {
        src: 'pwa-512x512.png',
        sizes: '512x512',
        type: 'image/png',
      },
    ],
  },
  workbox: {
    runtimeCaching: [
      {
        urlPattern: /^https:\/\/api\.example\.com\/.*$/,
        handler: 'NetworkFirst',
        options: {
          cacheName: 'api-cache',
          expiration: {
            maxEntries: 50,
            maxAgeSeconds: 300,
          },
        },
      },
    ],
  },
})
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Build application
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built files
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

```nginx
# nginx.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
}
```

## Common Patterns and Best Practices

### Error Boundaries

```tsx
import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    console.error('Error caught by boundary:', error, errorInfo);
    // Log to error reporting service
    // logErrorToService(error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback || (
          <div role="alert">
            <h1>Something went wrong</h1>
            <p>{this.state.error?.message}</p>
          </div>
        )
      );
    }

    return this.props.children;
  }
}
```

### Custom Hooks

```typescript
// useLocalStorage hook
export function useLocalStorage<T>(
  key: string,
  initialValue: T
): [T, (value: T | ((val: T) => T)) => void] {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(error);
      return initialValue;
    }
  });

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore =
        value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      window.localStorage.setItem(key, JSON.stringify(valueToStore));
    } catch (error) {
      console.error(error);
    }
  };

  return [storedValue, setValue];
}

// useMediaQuery hook
export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(
    () => window.matchMedia(query).matches
  );

  useEffect(() => {
    const mediaQuery = window.matchMedia(query);
    const handler = (event: MediaQueryListEvent) => setMatches(event.matches);

    mediaQuery.addEventListener('change', handler);
    return () => mediaQuery.removeEventListener('change', handler);
  }, [query]);

  return matches;
}

// useDebounce hook
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

// useIntersectionObserver hook
export function useIntersectionObserver(
  ref: RefObject<Element>,
  options?: IntersectionObserverInit
): boolean {
  const [isIntersecting, setIsIntersecting] = useState(false);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    const observer = new IntersectionObserver(([entry]) => {
      setIsIntersecting(entry.isIntersecting);
    }, options);

    observer.observe(element);

    return () => {
      observer.unobserve(element);
    };
  }, [ref, options]);

  return isIntersecting;
}
```

### Dark Mode Support

```css
/* CSS Variables for theming */
:root {
  --color-bg: #ffffff;
  --color-text: #1a1a1a;
  --color-border: #e0e0e0;
  --color-primary: #0066cc;
}

[data-theme='dark'] {
  --color-bg: #1a1a1a;
  --color-text: #ffffff;
  --color-border: #333333;
  --color-primary: #4d94ff;
}

/* Respect system preference */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) {
    --color-bg: #1a1a1a;
    --color-text: #ffffff;
    --color-border: #333333;
    --color-primary: #4d94ff;
  }
}
```

```typescript
// Theme context and hook
type Theme = 'light' | 'dark' | 'system';

export function useTheme() {
  const [theme, setTheme] = useLocalStorage<Theme>('theme', 'system');

  useEffect(() => {
    const root = document.documentElement;
    
    if (theme === 'system') {
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)');
      root.setAttribute('data-theme', prefersDark.matches ? 'dark' : 'light');
      
      const handler = (e: MediaQueryListEvent) => {
        root.setAttribute('data-theme', e.matches ? 'dark' : 'light');
      };
      
      prefersDark.addEventListener('change', handler);
      return () => prefersDark.removeEventListener('change', handler);
    } else {
      root.setAttribute('data-theme', theme);
    }
  }, [theme]);

  return { theme, setTheme };
}
```

### Form Handling

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const formSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  rememberMe: z.boolean().optional(),
});

type FormData = z.infer<typeof formSchema>;

function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(formSchema),
  });

  const onSubmit = async (data: FormData) => {
    try {
      await api.post('/auth/login', data);
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          {...register('email')}
          aria-invalid={errors.email ? 'true' : 'false'}
        />
        {errors.email && (
          <span role="alert">{errors.email.message}</span>
        )}
      </div>

      <div>
        <label htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          {...register('password')}
          aria-invalid={errors.password ? 'true' : 'false'}
        />
        {errors.password && (
          <span role="alert">{errors.password.message}</span>
        )}
      </div>

      <div>
        <label>
          <input type="checkbox" {...register('rememberMe')} />
          Remember me
        </label>
      </div>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Logging in...' : 'Login'}
      </button>
    </form>
  );
}
```

## Troubleshooting

### Common Issues

**Build Errors**
```bash
# Clear cache and reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Clear Vite cache
rm -rf node_modules/.vite
npm run dev
```

**TypeScript Errors**
```bash
# Check TypeScript version compatibility
npm list typescript

# Regenerate type definitions
npm run build

# Check for conflicting types
npm ls @types/react
```

**Browser Compatibility**
```javascript
// Check feature support in browser console
console.log({
  fetch: 'fetch' in window,
  promises: 'Promise' in window,
  asyncAwait: true, // Always true in modern browsers
  modules: 'noModule' in document.createElement('script'),
  intersectionObserver: 'IntersectionObserver' in window,
  resizeObserver: 'ResizeObserver' in window,
  webP: document.createElement('canvas')
    .toDataURL('image/webp')
    .indexOf('data:image/webp') === 0,
});
```

**Memory Leaks**
```typescript
// Common causes and solutions
useEffect(() => {
  // ✅ Always cleanup event listeners
  const handler = () => console.log('event');
  window.addEventListener('resize', handler);
  return () => window.removeEventListener('resize', handler);
}, []);

useEffect(() => {
  // ✅ Cancel pending requests
  const controller = new AbortController();
  
  fetch('/api/data', { signal: controller.signal })
    .then(r => r.json())
    .then(data => setData(data));
  
  return () => controller.abort();
}, []);

useEffect(() => {
  // ✅ Clear intervals/timeouts
  const interval = setInterval(() => {}, 1000);
  return () => clearInterval(interval);
}, []);
```

### Performance Debugging

```typescript
// React DevTools Profiler
import { Profiler } from 'react';

function onRenderCallback(
  id: string,
  phase: 'mount' | 'update',
  actualDuration: number,
  baseDuration: number,
  startTime: number,
  commitTime: number
) {
  console.log({ id, phase, actualDuration });
}

function App() {
  return (
    <Profiler id="App" onRender={onRenderCallback}>
      <Dashboard />
    </Profiler>
  );
}

// Performance monitoring
if ('performance' in window) {
  window.addEventListener('load', () => {
    const perfData = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
    console.log('Performance metrics:', {
      domContentLoaded: perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart,
      loadComplete: perfData.loadEventEnd - perfData.loadEventStart,
      totalTime: perfData.loadEventEnd - perfData.fetchStart,
      firstPaint: performance.getEntriesByType('paint')[0]?.startTime,
    });
  });
}

// Web Vitals
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

getCLS(console.log);
getFID(console.log);
getFCP(console.log);
getLCP(console.log);
getTTFB(console.log);
```

## Best Practices Checklist

### Before Committing

- [ ] Code passes linting (ESLint, Prettier)
- [ ] TypeScript has no errors
- [ ] All tests pass
- [ ] Tested in Chrome, Edge, and Firefox
- [ ] Responsive design works on mobile/tablet/desktop
- [ ] Performance: no unnecessary re-renders
- [ ] Performance: images optimized
- [ ] Security: no XSS vulnerabilities
- [ ] Security: proper input validation
- [ ] Security: no sensitive data in localStorage
- [ ] Documentation updated
- [ ] No console.log statements left in code
- [ ] No commented-out code
- [ ] Meaningful commit message

### Production Deployment

- [ ] Environment variables configured
- [ ] Build optimizations enabled
- [ ] Source maps generated (for debugging)
- [ ] Error tracking configured (Sentry, LogRocket, etc.)
- [ ] Analytics configured (if applicable)
- [ ] CSP headers configured
- [ ] HTTPS enabled
- [ ] Compression enabled (gzip/brotli)
- [ ] Cache headers configured
- [ ] 404 page configured
- [ ] Favicon and app icons present
- [ ] Meta tags for SEO/social sharing
- [ ] robots.txt configured
- [ ] sitemap.xml generated (if applicable)
- [ ] Performance budget defined and met
- [ ] Lighthouse score > 90

### Code Quality

- [ ] Components are small and focused (single responsibility)
- [ ] Props are typed and documented
- [ ] No prop drilling (use context or state management)
- [ ] Error boundaries in place
- [ ] Loading and error states handled
- [ ] Optimistic updates for better UX
- [ ] No magic numbers (use constants)
- [ ] Functions are pure when possible
- [ ] Side effects properly managed
- [ ] Code is DRY (Don't Repeat Yourself)

## Additional Resources

### Documentation
- **MDN Web Docs**: https://developer.mozilla.org - Comprehensive web technology documentation
- **React Documentation**: https://react.dev - Official React docs with hooks and best practices
- **Vue Documentation**: https://vuejs.org - Official Vue 3 docs with Composition API
- **TypeScript Documentation**: https://www.typescriptlang.org - TypeScript handbook and reference
- **Vite Documentation**: https://vitejs.dev - Fast build tool documentation
- **Web.dev**: https://web.dev - Google's web development best practices

### Tools
- **ESLint**: https://eslint.org - JavaScript linter
- **Prettier**: https://prettier.io - Code formatter
- **Vitest**: https://vitest.dev - Fast unit test framework
- **Playwright**: https://playwright.dev - E2E testing framework
- **React DevTools**: Browser extension for React debugging
- **Vue DevTools**: Browser extension for Vue debugging

### Browser Testing
- **Chrome DevTools**: Built-in browser developer tools
- **Firefox Developer Tools**: Built-in browser developer tools
- **Edge DevTools**: Built-in browser developer tools (Chromium-based)
- **Can I Use**: https://caniuse.com - Browser feature support tables
- **BrowserStack**: https://www.browserstack.com - Cross-browser testing platform
- **LambdaTest**: https://www.lambdatest.com - Cross-browser testing alternative

### Performance
- **Lighthouse**: Built into Chrome DevTools
- **WebPageTest**: https://www.webpagetest.org - Detailed performance analysis
- **Bundle Analyzer**: Visualize bundle size and composition
- **web-vitals**: https://github.com/GoogleChrome/web-vitals - Essential metrics library

### Accessibility
- **axe DevTools**: Browser extension for accessibility testing
- **WAVE**: https://wave.webaim.org - Web accessibility evaluation tool
- **WCAG Guidelines**: https://www.w3.org/WAI/WCAG21/quickref/ - Quick reference
- **A11y Project**: https://www.a11yproject.com - Community-driven accessibility resources

### Security
- **OWASP**: https://owasp.org - Web application security best practices
- **DOMPurify**: https://github.com/cure53/DOMPurify - XSS sanitizer
- **Content Security Policy**: https://content-security-policy.com - CSP reference

### State Management
- **Redux Toolkit**: https://redux-toolkit.js.org - Official Redux toolset
- **Zustand**: https://github.com/pmndrs/zustand - Lightweight state management
- **Jotai**: https://jotai.org - Atomic state management
- **Pinia**: https://pinia.vuejs.org - Vue state management

### UI Libraries
- **shadcn/ui**: https://ui.shadcn.com - Beautifully designed components
- **Material-UI**: https://mui.com - React component library
- **Ant Design**: https://ant.design - Enterprise-level UI design language
- **Chakra UI**: https://chakra-ui.com - Accessible component library
- **Tailwind CSS**: https://tailwindcss.com - Utility-first CSS framework

### Learning Resources
- **Frontend Masters**: https://frontendmasters.com - Expert-led courses
- **egghead.io**: https://egghead.io - Concise programming tutorials
- **JavaScript.info**: https://javascript.info - Modern JavaScript tutorial
- **CSS-Tricks**: https://css-tricks.com - CSS tips and tutorials
- **Smashing Magazine**: https://www.smashingmagazine.com - Web design and development articles

---

**This skill provides comprehensive guidance for modern web-frontend development with emphasis on cross-browser support (Chrome, Edge, Firefox), accessibility, performance, and security. Use it as a reference for building production-ready web applications with state-of-the-art technologies.**
