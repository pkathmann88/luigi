import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { authService } from '../services/authService';
import { Button } from '../components/Button';
import './Login.css';

export const Login: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const success = authService.login(username, password);
      
      if (success) {
        navigate('/dashboard');
      } else {
        setError('Invalid username or password');
      }
    } catch (_err) {
      setError('Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login">
      <div className="login__container">
        <div className="login__header">
          <h1 className="login__title">Luigi Management</h1>
          <p className="login__subtitle">Sign in to manage your system</p>
        </div>

        <form onSubmit={handleSubmit} className="login__form">
          {error && (
            <div className="login__error">
              {error}
            </div>
          )}

          <div className="login__field">
            <label htmlFor="username" className="login__label">
              Username
            </label>
            <input
              id="username"
              type="text"
              className="login__input"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              autoComplete="username"
              autoFocus
            />
          </div>

          <div className="login__field">
            <label htmlFor="password" className="login__label">
              Password
            </label>
            <input
              id="password"
              type="password"
              className="login__input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              autoComplete="current-password"
            />
          </div>

          <Button
            type="submit"
            variant="primary"
            size="large"
            fullWidth
            loading={loading}
          >
            Sign In
          </Button>
        </form>

        <div className="login__footer">
          <p className="login__hint">
            Default credentials: <code>admin</code> / <code>changeme123</code>
          </p>
        </div>
      </div>
    </div>
  );
};
