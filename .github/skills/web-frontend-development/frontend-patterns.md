# Advanced Web-Frontend Patterns

This document provides advanced patterns and techniques for modern web-frontend development, building upon the foundational concepts in SKILL.md.

## Table of Contents

- [Advanced State Management](#advanced-state-management)
- [Rendering Patterns](#rendering-patterns)
- [Data Fetching Strategies](#data-fetching-strategies)
- [Real-Time Features](#real-time-features)
- [Advanced CSS Techniques](#advanced-css-techniques)
- [Performance Patterns](#performance-patterns)
- [Micro-Frontend Architecture](#micro-frontend-architecture)
- [Progressive Enhancement](#progressive-enhancement)

## Advanced State Management

### Atomic State Management with Jotai

```typescript
import { atom, useAtom, useAtomValue, useSetAtom } from 'jotai';

// Basic atoms
const countAtom = atom(0);
const textAtom = atom('hello');

// Derived atoms
const uppercaseAtom = atom((get) => get(textAtom).toUpperCase());

// Async atoms
const userAtom = atom(async () => {
  const response = await fetch('/api/user');
  return response.json();
});

// Write-only atoms
const incrementAtom = atom(
  null,
  (get, set) => set(countAtom, get(countAtom) + 1)
);

// Component usage
function Counter() {
  const [count, setCount] = useAtom(countAtom);
  const increment = useSetAtom(incrementAtom);
  
  return (
    <button onClick={increment}>
      Count: {count}
    </button>
  );
}
```

### Redux Toolkit Pattern

```typescript
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';

interface User {
  id: string;
  name: string;
  email: string;
}

interface UserState {
  users: User[];
  loading: boolean;
  error: string | null;
}

const initialState: UserState = {
  users: [],
  loading: false,
  error: null,
};

// Async thunk
export const fetchUsers = createAsyncThunk(
  'users/fetchUsers',
  async () => {
    const response = await api.get<User[]>('/users');
    return response;
  }
);

const userSlice = createSlice({
  name: 'users',
  initialState,
  reducers: {
    addUser: (state, action: PayloadAction<User>) => {
      state.users.push(action.payload);
    },
    removeUser: (state, action: PayloadAction<string>) => {
      state.users = state.users.filter(u => u.id !== action.payload);
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchUsers.pending, (state) => {
        state.loading = true;
      })
      .addCase(fetchUsers.fulfilled, (state, action) => {
        state.loading = false;
        state.users = action.payload;
      })
      .addCase(fetchUsers.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Failed to fetch users';
      });
  },
});

export const { addUser, removeUser } = userSlice.actions;
export default userSlice.reducer;
```

## Rendering Patterns

### Server-Side Rendering (SSR) with Next.js

```tsx
// pages/products/[id].tsx
import { GetServerSideProps } from 'next';

interface Product {
  id: string;
  name: string;
  price: number;
}

interface Props {
  product: Product;
}

export const getServerSideProps: GetServerSideProps<Props> = async (context) => {
  const { id } = context.params!;
  
  const response = await fetch(`https://api.example.com/products/${id}`);
  const product = await response.json();
  
  return {
    props: {
      product,
    },
  };
};

export default function ProductPage({ product }: Props) {
  return (
    <div>
      <h1>{product.name}</h1>
      <p>Price: ${product.price}</p>
    </div>
  );
}
```

### Static Site Generation (SSG)

```tsx
// pages/blog/[slug].tsx
import { GetStaticProps, GetStaticPaths } from 'next';

interface Post {
  slug: string;
  title: string;
  content: string;
}

export const getStaticPaths: GetStaticPaths = async () => {
  const posts = await fetch('https://api.example.com/posts').then(r => r.json());
  
  return {
    paths: posts.map((post: Post) => ({
      params: { slug: post.slug },
    })),
    fallback: 'blocking', // or false, or true
  };
};

export const getStaticProps: GetStaticProps = async (context) => {
  const { slug } = context.params!;
  const post = await fetch(`https://api.example.com/posts/${slug}`).then(r => r.json());
  
  return {
    props: {
      post,
    },
    revalidate: 60, // Revalidate every 60 seconds
  };
};

export default function BlogPost({ post }: { post: Post }) {
  return (
    <article>
      <h1>{post.title}</h1>
      <div dangerouslySetInnerHTML={{ __html: post.content }} />
    </article>
  );
}
```

### Incremental Static Regeneration (ISR)

```tsx
// Combines benefits of SSG and SSR
export const getStaticProps: GetStaticProps = async () => {
  const data = await fetchData();
  
  return {
    props: {
      data,
    },
    revalidate: 10, // Regenerate page every 10 seconds
  };
};
```

### Streaming SSR with React 18

```tsx
import { Suspense } from 'react';

function ProfilePage() {
  return (
    <div>
      <h1>User Profile</h1>
      <Suspense fallback={<div>Loading comments...</div>}>
        <Comments />
      </Suspense>
    </div>
  );
}

// This component will stream to the client as it resolves
async function Comments() {
  const comments = await fetchComments(); // Server-side async
  return <CommentList comments={comments} />;
}
```

## Data Fetching Strategies

### React Query Advanced Patterns

```typescript
// Optimistic Updates
const updateTodoMutation = useMutation({
  mutationFn: updateTodo,
  onMutate: async (newTodo) => {
    // Cancel outgoing refetches
    await queryClient.cancelQueries({ queryKey: ['todos'] });

    // Snapshot previous value
    const previousTodos = queryClient.getQueryData(['todos']);

    // Optimistically update
    queryClient.setQueryData(['todos'], (old: Todo[]) => [...old, newTodo]);

    return { previousTodos };
  },
  onError: (err, newTodo, context) => {
    // Rollback on error
    queryClient.setQueryData(['todos'], context.previousTodos);
  },
  onSettled: () => {
    // Always refetch after error or success
    queryClient.invalidateQueries({ queryKey: ['todos'] });
  },
});

// Prefetching
function ProductList() {
  const queryClient = useQueryClient();
  
  const products = useQuery({
    queryKey: ['products'],
    queryFn: fetchProducts,
  });

  return (
    <div>
      {products.data?.map((product) => (
        <div
          key={product.id}
          onMouseEnter={() => {
            // Prefetch product details on hover
            queryClient.prefetchQuery({
              queryKey: ['product', product.id],
              queryFn: () => fetchProduct(product.id),
            });
          }}
        >
          {product.name}
        </div>
      ))}
    </div>
  );
}

// Infinite Queries
function InfiniteList() {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['items'],
    queryFn: ({ pageParam = 0 }) => fetchItems(pageParam),
    getNextPageParam: (lastPage, pages) => lastPage.nextCursor,
  });

  return (
    <div>
      {data?.pages.map((page, i) => (
        <div key={i}>
          {page.items.map((item) => (
            <div key={item.id}>{item.name}</div>
          ))}
        </div>
      ))}
      <button
        onClick={() => fetchNextPage()}
        disabled={!hasNextPage || isFetchingNextPage}
      >
        {isFetchingNextPage
          ? 'Loading more...'
          : hasNextPage
          ? 'Load More'
          : 'Nothing more to load'}
      </button>
    </div>
  );
}
```

### SWR (Stale-While-Revalidate)

```typescript
import useSWR from 'swr';

const fetcher = (url: string) => fetch(url).then(r => r.json());

function Profile() {
  const { data, error, isLoading, mutate } = useSWR('/api/user', fetcher, {
    revalidateOnFocus: true,
    revalidateOnReconnect: true,
    refreshInterval: 30000, // Poll every 30s
  });

  if (error) return <div>Failed to load</div>;
  if (isLoading) return <div>Loading...</div>;

  return (
    <div>
      <h1>Hello {data.name}!</h1>
      <button onClick={() => mutate()}>Refresh</button>
    </div>
  );
}

// Mutation with optimistic UI
function updateUser() {
  const { mutate } = useSWRConfig();
  
  const update = async (newName: string) => {
    await mutate(
      '/api/user',
      async (currentData) => {
        // Optimistic update
        const optimisticData = { ...currentData, name: newName };
        
        // Send request
        await api.post('/api/user', optimisticData);
        
        // Return updated data
        return optimisticData;
      },
      {
        optimisticData: { ...currentData, name: newName },
        rollbackOnError: true,
      }
    );
  };
}
```

## Real-Time Features

### Server-Sent Events (SSE)

```typescript
function useServerSentEvents(url: string) {
  const [data, setData] = useState<any[]>([]);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const eventSource = new EventSource(url);

    eventSource.onmessage = (event) => {
      const newData = JSON.parse(event.data);
      setData((prev) => [...prev, newData]);
    };

    eventSource.onerror = (error) => {
      console.error('SSE Error:', error);
      setError(new Error('Connection lost'));
      eventSource.close();
    };

    return () => {
      eventSource.close();
    };
  }, [url]);

  return { data, error };
}

// Usage
function LiveFeed() {
  const { data, error } = useServerSentEvents('/api/live-updates');

  if (error) return <div>Connection error</div>;

  return (
    <div>
      {data.map((item, i) => (
        <div key={i}>{item.message}</div>
      ))}
    </div>
  );
}
```

### WebSocket with Reconnection

```typescript
class ReliableWebSocket {
  private ws: WebSocket | null = null;
  private url: string;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;
  private messageQueue: string[] = [];
  private isConnected = false;

  constructor(url: string) {
    this.url = url;
  }

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(this.url);

      this.ws.onopen = () => {
        this.isConnected = true;
        this.reconnectAttempts = 0;
        
        // Send queued messages
        while (this.messageQueue.length > 0) {
          const message = this.messageQueue.shift();
          if (message) this.ws?.send(message);
        }
        
        resolve();
      };

      this.ws.onerror = (error) => {
        reject(error);
      };

      this.ws.onclose = () => {
        this.isConnected = false;
        this.reconnect();
      };
    });
  }

  private reconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      return;
    }

    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts);
    this.reconnectAttempts++;

    setTimeout(() => this.connect(), delay);
  }

  send(data: string): void {
    if (this.isConnected && this.ws) {
      this.ws.send(data);
    } else {
      // Queue message for later
      this.messageQueue.push(data);
    }
  }

  close(): void {
    this.ws?.close();
  }
}
```

### GraphQL Subscriptions

```typescript
import { useSubscription, gql } from '@apollo/client';

const MESSAGE_SUBSCRIPTION = gql`
  subscription OnMessageAdded($roomId: ID!) {
    messageAdded(roomId: $roomId) {
      id
      content
      user {
        id
        name
      }
      createdAt
    }
  }
`;

function ChatRoom({ roomId }: { roomId: string }) {
  const { data, loading, error } = useSubscription(MESSAGE_SUBSCRIPTION, {
    variables: { roomId },
  });

  if (loading) return <div>Connecting...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      {data && (
        <div className="message">
          <strong>{data.messageAdded.user.name}:</strong>
          {data.messageAdded.content}
        </div>
      )}
    </div>
  );
}
```

## Advanced CSS Techniques

### CSS-in-JS with Emotion

```typescript
import { css } from '@emotion/react';
import styled from '@emotion/styled';

// Object styles
const style = css({
  color: 'hotpink',
  fontSize: '16px',
  '&:hover': {
    color: 'lightpink',
  },
});

// Template literal styles
const hoverStyle = css`
  color: hotpink;
  &:hover {
    color: lightpink;
  }
`;

// Styled components
const Button = styled.button<{ primary?: boolean }>`
  background: ${props => props.primary ? '#007bff' : '#6c757d'};
  color: white;
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;

  &:hover {
    opacity: 0.8;
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
`;

// Composition
const DangerButton = styled(Button)`
  background: #dc3545;
`;
```

### Tailwind CSS Advanced Patterns

```tsx
import clsx from 'clsx';
import { twMerge } from 'tailwind-merge';

// Utility function for conditional classes
function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Component with variant system
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  children: React.ReactNode;
}

function Button({ variant = 'primary', size = 'md', children }: ButtonProps) {
  return (
    <button
      className={cn(
        // Base styles
        'font-medium rounded-lg transition-colors',
        // Variant styles
        {
          'bg-blue-500 hover:bg-blue-600 text-white': variant === 'primary',
          'bg-gray-500 hover:bg-gray-600 text-white': variant === 'secondary',
          'bg-red-500 hover:bg-red-600 text-white': variant === 'danger',
        },
        // Size styles
        {
          'px-3 py-1 text-sm': size === 'sm',
          'px-4 py-2 text-base': size === 'md',
          'px-6 py-3 text-lg': size === 'lg',
        }
      )}
    >
      {children}
    </button>
  );
}
```

### CSS Grid Advanced Layouts

```css
/* Auto-fit responsive grid */
.grid-auto-fit {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
}

/* Auto-fill (creates empty columns) */
.grid-auto-fill {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 1rem;
}

/* Named grid areas */
.layout {
  display: grid;
  grid-template-areas:
    "header header header"
    "sidebar main main"
    "footer footer footer";
  grid-template-columns: 200px 1fr 1fr;
  grid-template-rows: auto 1fr auto;
  min-height: 100vh;
  gap: 1rem;
}

.header { grid-area: header; }
.sidebar { grid-area: sidebar; }
.main { grid-area: main; }
.footer { grid-area: footer; }

/* Masonry layout (Chrome 87+) */
.masonry {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  grid-template-rows: masonry;
  gap: 1rem;
}
```

## Performance Patterns

### Web Workers

```typescript
// worker.ts
self.addEventListener('message', (event) => {
  const { data } = event;
  
  // Heavy computation
  const result = performHeavyCalculation(data);
  
  self.postMessage(result);
});

// useWorker hook
function useWorker(workerPath: string) {
  const [worker, setWorker] = useState<Worker | null>(null);
  const [result, setResult] = useState<any>(null);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const w = new Worker(workerPath);
    
    w.onmessage = (event) => {
      setResult(event.data);
    };
    
    w.onerror = (error) => {
      setError(new Error(error.message));
    };
    
    setWorker(w);
    
    return () => w.terminate();
  }, [workerPath]);

  const execute = useCallback((data: any) => {
    if (worker) {
      worker.postMessage(data);
    }
  }, [worker]);

  return { execute, result, error };
}
```

### Request Idle Callback

```typescript
function useIdleCallback(callback: IdleRequestCallback, options?: IdleRequestOptions) {
  useEffect(() => {
    if ('requestIdleCallback' in window) {
      const id = requestIdleCallback(callback, options);
      return () => cancelIdleCallback(id);
    } else {
      // Fallback for browsers without support
      const id = setTimeout(callback, 1);
      return () => clearTimeout(id);
    }
  }, [callback, options]);
}

// Usage: defer non-critical work
function DeferredAnalytics() {
  useIdleCallback(() => {
    // Track analytics when browser is idle
    trackPageView();
  });

  return null;
}
```

### Resource Hints

```html
<!-- Preconnect to required origins -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://api.example.com">

<!-- DNS prefetch for external domains -->
<link rel="dns-prefetch" href="https://analytics.example.com">

<!-- Preload critical resources -->
<link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="/styles/critical.css" as="style">

<!-- Prefetch resources for next navigation -->
<link rel="prefetch" href="/about.html">
<link rel="prefetch" href="/api/data.json">

<!-- Prerender next likely page -->
<link rel="prerender" href="/checkout.html">
```

## Micro-Frontend Architecture

### Module Federation (Webpack 5)

```javascript
// host/webpack.config.js
const ModuleFederationPlugin = require('webpack/lib/container/ModuleFederationPlugin');

module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      name: 'host',
      remotes: {
        app1: 'app1@http://localhost:3001/remoteEntry.js',
        app2: 'app2@http://localhost:3002/remoteEntry.js',
      },
      shared: {
        react: { singleton: true, requiredVersion: '^18.0.0' },
        'react-dom': { singleton: true, requiredVersion: '^18.0.0' },
      },
    }),
  ],
};

// remote/webpack.config.js
module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      name: 'app1',
      filename: 'remoteEntry.js',
      exposes: {
        './Button': './src/components/Button',
        './Header': './src/components/Header',
      },
      shared: {
        react: { singleton: true },
        'react-dom': { singleton: true },
      },
    }),
  ],
};

// Usage in host
import React, { lazy, Suspense } from 'react';

const RemoteButton = lazy(() => import('app1/Button'));

function App() {
  return (
    <Suspense fallback="Loading...">
      <RemoteButton />
    </Suspense>
  );
}
```

### Single-SPA Framework

```typescript
import { registerApplication, start } from 'single-spa';

// Register micro-frontends
registerApplication({
  name: '@org/navbar',
  app: () => System.import('@org/navbar'),
  activeWhen: '/',
});

registerApplication({
  name: '@org/dashboard',
  app: () => System.import('@org/dashboard'),
  activeWhen: '/dashboard',
});

// Start single-spa
start();
```

## Progressive Enhancement

### Feature Detection Pattern

```typescript
const features = {
  webp: (() => {
    const canvas = document.createElement('canvas');
    return canvas.toDataURL('image/webp').indexOf('data:image/webp') === 0;
  })(),
  
  intersectionObserver: 'IntersectionObserver' in window,
  
  serviceWorker: 'serviceWorker' in navigator,
  
  localStorage: (() => {
    try {
      localStorage.setItem('test', 'test');
      localStorage.removeItem('test');
      return true;
    } catch {
      return false;
    }
  })(),
};

// Usage
function ImageComponent({ src, alt }: ImageProps) {
  const imageSrc = features.webp ? `${src}.webp` : `${src}.jpg`;
  return <img src={imageSrc} alt={alt} />;
}
```

### Graceful Degradation

```typescript
function EnhancedForm() {
  const [enhanced, setEnhanced] = useState(false);

  useEffect(() => {
    // Check if all required features are available
    const canEnhance = 
      'FormData' in window &&
      'fetch' in window &&
      'Promise' in window;
    
    setEnhanced(canEnhance);
  }, []);

  const handleSubmit = enhanced
    ? async (e: React.FormEvent) => {
        e.preventDefault();
        const formData = new FormData(e.target as HTMLFormElement);
        await fetch('/api/submit', { method: 'POST', body: formData });
      }
    : undefined; // Let browser handle normally

  return (
    <form action="/api/submit" method="POST" onSubmit={handleSubmit}>
      {/* Form fields */}
      <button type="submit">
        Submit
      </button>
    </form>
  );
}
```

---

**These advanced patterns complement the foundational concepts in SKILL.md and provide solutions for complex web-frontend development scenarios.**
