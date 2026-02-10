/**
 * Example React + TypeScript Application
 * 
 * This example demonstrates best practices for modern web-frontend development:
 * - TypeScript for type safety
 * - React 18 with hooks
 * - Error handling
 * - Loading states
 * - Responsive design
 * - Cross-browser compatibility
 */

import React, { useState, useEffect, useCallback, useRef } from 'react';
import './App.css';

// ============================================================================
// Types
// ============================================================================

interface User {
  id: string;
  name: string;
  email: string;
}

interface TodoItem {
  id: string;
  title: string;
  completed: boolean;
}

// ============================================================================
// API Service
// ============================================================================

class ApiService {
  private static baseURL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

  static async fetchUsers(): Promise<User[]> {
    const response = await fetch(`${this.baseURL}/api/users`);
    if (!response.ok) {
      throw new Error('Failed to fetch users');
    }
    return response.json();
  }

  static async fetchTodos(): Promise<TodoItem[]> {
    const response = await fetch(`${this.baseURL}/api/todos`);
    if (!response.ok) {
      throw new Error('Failed to fetch todos');
    }
    return response.json();
  }

  static async updateTodo(id: string, completed: boolean): Promise<TodoItem> {
    const response = await fetch(`${this.baseURL}/api/todos/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ completed }),
    });
    if (!response.ok) {
      throw new Error('Failed to update todo');
    }
    return response.json();
  }
}

// ============================================================================
// Custom Hooks
// ============================================================================

function useLocalStorage<T>(key: string, initialValue: T): [T, (value: T) => void] {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error('Error reading localStorage:', error);
      return initialValue;
    }
  });

  const setValue = useCallback((value: T) => {
    try {
      setStoredValue(value);
      window.localStorage.setItem(key, JSON.stringify(value));
    } catch (error) {
      console.error('Error writing to localStorage:', error);
    }
  }, [key]);

  return [storedValue, setValue];
}

// ============================================================================
// Components
// ============================================================================

interface ButtonProps {
  children: React.ReactNode;
  onClick?: () => void;
  variant?: 'primary' | 'secondary';
  disabled?: boolean;
}

function Button({ 
  children, 
  onClick, 
  variant = 'primary', 
  disabled = false,
}: ButtonProps) {
  return (
    <button
      className={`button button-${variant}`}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
}

interface TodoListProps {
  todos: TodoItem[];
  onToggle: (id: string) => void;
}

function TodoList({ todos, onToggle }: TodoListProps) {
  return (
    <ul className="todo-list">
      {todos.map((todo) => (
        <li key={todo.id} className="todo-item">
          <label className="todo-label">
            <input
              type="checkbox"
              checked={todo.completed}
              onChange={() => onToggle(todo.id)}
            />
            <span className={todo.completed ? 'todo-text completed' : 'todo-text'}>
              {todo.title}
            </span>
          </label>
        </li>
      ))}
    </ul>
  );
}

interface UserCardProps {
  user: User;
}

function UserCard({ user }: UserCardProps) {
  return (
    <article className="user-card">
      <h3>{user.name}</h3>
      <p>
        <a href={`mailto:${user.email}`}>{user.email}</a>
      </p>
    </article>
  );
}

// ============================================================================
// Main App Component
// ============================================================================

function App() {
  // State
  const [users, setUsers] = useState<User[]>([]);
  const [todos, setTodos] = useState<TodoItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [darkMode, setDarkMode] = useLocalStorage('darkMode', false);

  // Effects
  useEffect(() => {
    // Apply dark mode class to document
    document.documentElement.setAttribute('data-theme', darkMode ? 'dark' : 'light');
  }, [darkMode]);

  useEffect(() => {
    // Fetch initial data
    const fetchData = async () => {
      try {
        setLoading(true);
        setError(null);

        const [usersData, todosData] = await Promise.all([
          ApiService.fetchUsers(),
          ApiService.fetchTodos(),
        ]);

        setUsers(usersData);
        setTodos(todosData);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An error occurred');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  // Handlers
  const handleToggleTodo = useCallback(async (id: string) => {
    const todo = todos.find((t) => t.id === id);
    if (!todo) return;

    // Optimistic update
    setTodos((prev) =>
      prev.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t))
    );

    try {
      await ApiService.updateTodo(id, !todo.completed);
    } catch (err) {
      // Revert on error
      setTodos((prev) =>
        prev.map((t) => (t.id === id ? { ...t, completed: todo.completed } : t))
      );
      setError(err instanceof Error ? err.message : 'Failed to update todo');
    }
  }, [todos]);

  const handleToggleDarkMode = useCallback(() => {
    setDarkMode((prev) => !prev);
  }, [setDarkMode]);

  // Render loading state
  if (loading) {
    return (
      <div className="app">
        <div className="loading">
          <span className="spinner" />
          <span>Loading application data...</span>
        </div>
      </div>
    );
  }

  // Render error state
  if (error) {
    return (
      <div className="app">
        <div className="error">
          <h2>Error</h2>
          <p>{error}</p>
          <Button onClick={() => window.location.reload()}>Reload Page</Button>
        </div>
      </div>
    );
  }

  // Main render
  return (
    <div className="app">
      <header className="app-header">
        <h1>My Application</h1>
        <nav>
          <Button
            onClick={handleToggleDarkMode}
            variant="secondary"
          >
            {darkMode ? '☀️' : '🌙'} {darkMode ? 'Light' : 'Dark'} Mode
          </Button>
        </nav>
      </header>

      <main className="app-main">
        <section>
          <h2>Users</h2>
            {users.length === 0 ? (
              <p>No users found.</p>
            ) : (
              <div className="users-grid">
                {users.map((user) => (
                  <UserCard key={user.id} user={user} />
                ))}
              </div>
            )}
          </section>

        <section>
          <h2>
            Todos ({todos.filter((t) => !t.completed).length} remaining)
          </h2>
          {todos.length === 0 ? (
            <p>No todos found.</p>
          ) : (
            <TodoList todos={todos} onToggle={handleToggleTodo} />
          )}
        </section>
      </main>

      <footer className="app-footer">
        <p>&copy; 2024 My Application. All rights reserved.</p>
      </footer>
    </div>
  );
}

export default App;
