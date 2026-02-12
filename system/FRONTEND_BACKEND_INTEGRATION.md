# Frontend-Backend Integration Guide

This document explains how the `management-frontend` and `management-api` modules work together.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        User's Browser                        │
│                      (Any Device on LAN)                     │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ HTTP (Port 80)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     Management Frontend                      │
│              nginx serving React SPA (Port 80)               │
│                                                              │
│  • Serves static files from /var/lib/luigi-frontend/dist    │
│  • Proxies /api/* requests to backend                       │
│  • Proxies /health requests to backend                      │
│  • Handles SPA routing (all routes → index.html)            │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ HTTPS (proxied to localhost:8443)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     Management API                           │
│            Node.js REST API (HTTPS Port 8443)                │
│                                                              │
│  • Validates HTTP Basic Auth credentials                    │
│  • Provides REST API endpoints                              │
│  • Manages Luigi modules and system                         │
│  • CORS enabled for localhost origins                       │
└─────────────────────────────────────────────────────────────┘
```

## Installation Order

**The backend MUST be installed before the frontend:**

1. **Install Backend First:**
   ```bash
   cd system/management-api
   sudo ./setup.sh install
   ```
   - Creates API service on port 8443
   - Generates TLS certificates
   - Sets up authentication

2. **Install Frontend Second:**
   ```bash
   cd system/management-frontend
   sudo ./setup.sh install
   ```
   - Checks for backend dependency
   - Builds React application
   - Configures nginx as reverse proxy
   - Serves frontend on port 80

## Communication Flow

### 1. User Opens Browser

User navigates to `http://<raspberry-pi-ip>/`

### 2. Nginx Serves Frontend

- Nginx serves `index.html` and static assets (JS, CSS, images)
- React SPA loads in browser
- Client-side routing handles navigation

### 3. Frontend Makes API Calls

When the frontend needs data:

```typescript
// In frontend code (apiService.ts)
const response = await fetch('/api/modules');
```

**Note:** No hostname/port specified - uses same-origin (relative URL)

### 4. Nginx Proxies to Backend

Nginx intercepts `/api/*` requests:

```nginx
location /api/ {
    proxy_pass https://localhost:8443;
    proxy_ssl_verify off;  # Backend uses self-signed cert
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### 5. Backend Processes Request

- Backend validates HTTP Basic Auth header
- Processes API request
- Returns JSON response

### 6. Frontend Receives Response

- Data flows back through nginx to browser
- React updates UI with new data

## CORS Configuration

### Backend (management-api)

**File:** `src/app.js`

```javascript
const allowedOrigins = [
  'http://localhost',
  'http://localhost:80',
  'http://localhost:5173', // Vite dev server
];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (nginx proxy)
    if (!origin) return callback(null, true);
    
    // Allow whitelisted origins
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
}));
```

**Key Points:**
- Allows requests with no `Origin` header (nginx proxy)
- Allows explicit localhost origins (development)
- Rejects other origins

### Frontend

No CORS issues because:
- Production: Same-origin requests (both served through nginx)
- Development: Vite proxy configured in `vite.config.ts`

## Authentication

### Login Flow

1. User enters credentials in login page
2. Frontend encodes credentials as Base64
3. Adds `Authorization: Basic <base64>` header
4. All subsequent API requests include this header
5. Backend validates on every request

**Storage:** Credentials stored in `sessionStorage` (cleared on tab close)

### Security Notes

- Backend uses HTTPS with TLS certificates
- Nginx proxies over localhost (no external HTTPS needed)
- HTTP Basic Auth over HTTPS is secure
- Local network only (IP filtering on backend)

## Development Workflow

### Backend Development

```bash
cd system/management-api
npm install
npm run dev  # or node server.js
```

Backend runs on `https://localhost:8443`

### Frontend Development

```bash
cd system/management-frontend/frontend
npm install
npm run dev
```

Frontend dev server runs on `http://localhost:5173` with proxy to backend.

**Vite Proxy Configuration:**

```typescript
server: {
  port: 5173,
  proxy: {
    '/api': {
      target: 'https://localhost:8443',
      changeOrigin: true,
      secure: false,  // Allow self-signed cert
    },
  },
}
```

### Full Stack Development

1. Start backend: `cd system/management-api && node server.js`
2. Start frontend dev: `cd system/management-frontend/frontend && npm run dev`
3. Open browser: `http://localhost:5173`
4. Frontend proxies API calls to backend at `https://localhost:8443`

## Production Deployment

### Build Process

1. **Build Frontend:**
   ```bash
   cd system/management-frontend/frontend
   npm install
   npm run build  # Creates dist/ directory
   ```

2. **Deploy Frontend:**
   ```bash
   sudo cp -r dist /var/lib/luigi-frontend/
   ```

3. **Configure Nginx:**
   ```bash
   sudo cp nginx-site.conf /etc/nginx/sites-available/luigi-frontend
   sudo ln -s /etc/nginx/sites-available/luigi-frontend /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

4. **Verify:**
   - Backend: `curl -k -u admin:changeme123 https://localhost:8443/health`
   - Frontend: `curl http://localhost/`

### Automated Deployment

Both modules include `setup.sh` scripts that automate the entire process:

```bash
# Install everything
cd system/management-api && sudo ./setup.sh install
cd system/management-frontend && sudo ./setup.sh install
```

## Troubleshooting

### Frontend Not Loading

**Symptom:** Blank page or 404 error

**Check:**
```bash
# Verify nginx is running
sudo systemctl status nginx

# Check frontend files exist
ls -la /var/lib/luigi-frontend/dist/

# Check nginx config
sudo nginx -t

# View nginx error logs
sudo tail -f /var/log/nginx/error.log
```

### API Calls Failing

**Symptom:** Network errors in browser console

**Check:**
```bash
# Verify backend is running
sudo systemctl status management-api

# Test backend directly
curl -k -u admin:changeme123 https://localhost:8443/api/modules

# Check nginx proxy config
grep -A 10 "location /api" /etc/nginx/sites-available/luigi-frontend

# View nginx access logs
sudo tail -f /var/log/nginx/access.log
```

### CORS Errors

**Symptom:** "Blocked by CORS policy" in browser console

**Check:**
- Verify request is going through nginx (should have no Origin header)
- Check backend CORS configuration in `src/app.js`
- Ensure `credentials: true` in frontend fetch options

### 401 Unauthorized

**Symptom:** Redirected to login page immediately

**Check:**
- Verify credentials in `/etc/luigi/system/management-api/.env`
- Check `sessionStorage` in browser dev tools (should have `authToken`)
- Test auth directly: `curl -k -u admin:password https://localhost:8443/api/modules`

## File Locations

### Frontend

- **Source:** `system/management-frontend/frontend/`
- **Built files:** `/var/lib/luigi-frontend/dist/`
- **Nginx config:** `/etc/nginx/sites-available/luigi-frontend`
- **Service:** `/etc/systemd/system/management-frontend.service`

### Backend

- **Source:** `system/management-api/`
- **Deployed:** `/var/lib/luigi-api/management-api/`
- **Config:** `/etc/luigi/system/management-api/.env`
- **Certs:** `/etc/luigi/system/management-api/certs/`
- **Service:** `/etc/systemd/system/management-api.service`

## Port Reference

- **80** - Frontend (nginx, HTTP)
- **8443** - Backend API (Node.js, HTTPS)
- **5173** - Frontend dev server (Vite, HTTP) - development only

## Security Considerations

1. **Backend uses HTTPS** - All API traffic encrypted
2. **Frontend uses HTTP** - No cert needed, served locally
3. **Nginx proxies internally** - Backend not exposed externally
4. **Local network only** - Backend rejects non-local IPs
5. **Authentication required** - All API endpoints protected
6. **Rate limiting** - Prevents brute force attacks
7. **Input validation** - All user input sanitized
8. **Audit logging** - All operations logged to `/var/log/luigi/`

## Summary

The frontend and backend are **completely decoupled**:

- Frontend is a static SPA served by nginx
- Backend is a REST API with HTTPS
- Communication via HTTP/HTTPS only
- No shared code or dependencies
- Each can be deployed, updated, or scaled independently

This follows modern best practices for web application architecture.
