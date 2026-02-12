# Luigi Management Frontend

**Category:** system  
**Status:** Production  
**Requires:** management-api

React-based web interface for Luigi system management. Provides an intuitive dashboard for monitoring modules, viewing logs, managing configurations, and controlling the Luigi system on Raspberry Pi Zero W.

## Overview

The management frontend is a standalone web application that communicates with the `management-api` backend via REST API. It's served using nginx as a lightweight static file server with API proxy capabilities.

**Key Features:**
- 📊 **Dashboard** - System overview with real-time metrics
- 🧩 **Module Management** - View, control, and monitor Luigi modules
- 📝 **Log Viewer** - Browse and search module logs
- ⚙️ **Configuration Editor** - Edit module configurations
- 🔐 **Secure Authentication** - HTTP Basic Auth integration
- 📱 **Responsive Design** - Mobile-friendly interface

## Architecture

```
┌─────────────────┐
│   Web Browser   │
│  (Port 80/443)  │
└────────┬────────┘
         │ HTTP
         ▼
┌─────────────────┐
│  Nginx Server   │  ← Static file serving
│  Port 80        │  ← API proxy to backend
└────────┬────────┘
         │ HTTPS (proxied)
         ▼
┌─────────────────┐
│ Management API  │  ← Backend REST API
│  Port 8443      │  ← Module operations
└─────────────────┘
```

**Separation of Concerns:**
- **Frontend** - Static React SPA served by nginx on port 80
- **Backend** - Node.js REST API on port 8443 (HTTPS)
- **Communication** - Frontend makes API calls, nginx proxies to backend

## Prerequisites

- **Required Module:** `management-api` must be installed first
- **Node.js:** v16+ (for building frontend)
- **Nginx:** Web server (automatically installed)
- **System:** Raspberry Pi Zero W or compatible ARM device

## Installation

### 1. Install Management API Backend

The frontend requires the backend to be installed first:

```bash
cd /path/to/luigi/system/management-api
sudo ./setup.sh install
```

### 2. Install Frontend

```bash
cd /path/to/luigi/system/management-frontend
sudo ./setup.sh install
```

The installation process will:
1. Check for management-api dependency
2. Install nginx and Node.js
3. Build the React frontend (if not already built)
4. Deploy static files to `/var/lib/luigi-frontend/dist`
5. Configure nginx to serve frontend and proxy API calls
6. Create and start systemd service
7. Register module in Luigi registry

### 3. Access the Interface

Open your web browser:
- **Local:** http://localhost/
- **Network:** http://\<raspberry-pi-ip\>/

**Default Credentials:**
- Username: `admin`
- Password: `changeme123`

⚠️ **Change default credentials** in `/etc/luigi/system/management-api/.env`

## Frontend Build Process

The frontend is built using Vite and optimized for ARM architecture:

### Manual Build

```bash
cd frontend
npm install
npm run type-check
npm run build
```

This creates the `frontend/dist/` directory with optimized production files.

### Build Script

The setup script includes a build-only command:

```bash
sudo ./setup.sh build
```

### Build Configuration

- **Bundler:** Vite 5 (fast, modern)
- **Minifier:** Terser (pure JS, ARM-compatible)
- **Optimization:** Code splitting, tree shaking, vendor chunks
- **Output:** Static HTML, CSS, JS files in `dist/`

## Configuration

### Nginx Configuration

**Location:** `/etc/nginx/sites-available/luigi-frontend`

Key settings:
- **Port:** 80 (HTTP)
- **Root:** `/var/lib/luigi-frontend/dist`
- **API Proxy:** `/api/*` → `https://localhost:8443`
- **Health Check:** `/health` → `https://localhost:8443`
- **SPA Routing:** All routes serve `index.html`

### Frontend API Endpoint

The frontend is configured to make API calls to:
- **Development:** `https://localhost:8443` (direct)
- **Production:** `/api/*` (proxied by nginx)

No frontend configuration needed - nginx handles the proxy.

## Service Management

### Start/Stop Services

```bash
# Frontend service (triggers nginx reload)
sudo systemctl start management-frontend.service
sudo systemctl stop management-frontend.service

# Nginx (actual web server)
sudo systemctl restart nginx
sudo systemctl reload nginx
```

### Enable/Disable Autostart

```bash
# Enable frontend on boot
sudo systemctl enable management-frontend.service

# Disable frontend autostart
sudo systemctl disable management-frontend.service
```

### Check Status

```bash
# Quick status
sudo ./setup.sh status

# Detailed service status
sudo systemctl status nginx
sudo systemctl status management-frontend.service

# View logs
sudo journalctl -u nginx -f
sudo journalctl -u management-frontend.service -f
```

## Development

### Local Development Server

For development with hot-reload:

```bash
cd frontend
npm install
npm run dev
```

Access at: http://localhost:5173

The dev server proxies API requests to `https://localhost:8443` (configured in `vite.config.ts`).

### Project Structure

```
frontend/
├── src/
│   ├── pages/              # Route pages
│   │   ├── Dashboard.tsx   # System overview
│   │   ├── Modules.tsx     # Module list
│   │   ├── ModuleDetail.tsx # Module details
│   │   ├── Logs.tsx        # Log viewer
│   │   ├── Config.tsx      # Config editor
│   │   └── Login.tsx       # Authentication
│   ├── components/         # Reusable UI components
│   │   ├── Layout.tsx      # Main layout
│   │   ├── Card.tsx        # Card component
│   │   ├── Button.tsx      # Button component
│   │   └── ...
│   ├── services/           # API integration
│   │   ├── apiService.ts   # REST API client
│   │   └── authService.ts  # Authentication
│   ├── types/              # TypeScript types
│   │   └── api.ts          # API interfaces
│   ├── App.tsx             # Main app with routing
│   └── main.tsx            # React entry point
├── package.json            # Dependencies
├── vite.config.ts          # Build configuration
├── tsconfig.json           # TypeScript config
└── index.html              # HTML template
```

### Technology Stack

- **Framework:** React 18
- **Language:** TypeScript
- **Routing:** React Router 6
- **Build Tool:** Vite 5
- **HTTP Client:** Fetch API
- **Styling:** CSS Modules

## Troubleshooting

### Frontend Not Loading

**Check nginx status:**
```bash
sudo systemctl status nginx
```

**Check frontend files:**
```bash
ls -la /var/lib/luigi-frontend/dist/
```

**Verify nginx config:**
```bash
sudo nginx -t
```

### API Calls Failing

**Check backend status:**
```bash
sudo systemctl status management-api.service
```

**Test backend directly:**
```bash
curl -k -u admin:changeme123 https://localhost:8443/health
```

**Check nginx proxy logs:**
```bash
sudo tail -f /var/log/nginx/error.log
```

### 401 Unauthorized

- Verify credentials in `/etc/luigi/system/management-api/.env`
- Clear browser cache and cookies
- Check browser console for auth errors

### Build Failures

**Install Node.js 16+:**
```bash
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Clean and rebuild:**
```bash
cd frontend
rm -rf node_modules dist
npm install
npm run build
```

## Uninstallation

```bash
sudo ./setup.sh uninstall
```

This will:
1. Stop and disable services
2. Remove nginx configuration
3. Remove deployed frontend files
4. Unregister from Luigi registry
5. Keep nginx installed (may be used by other services)

**Note:** The backend (management-api) is NOT removed. Uninstall it separately if needed.

## Security Considerations

- **Authentication:** Inherits from management-api (HTTP Basic Auth)
- **HTTPS:** Backend uses HTTPS, nginx proxies with SSL verification disabled (self-signed cert)
- **Local Network Only:** Backend restricts connections to local network (192.168.x.x, 10.x.x.x)
- **No Direct Backend Access:** Frontend users cannot bypass nginx proxy
- **Security Headers:** Nginx adds X-Frame-Options, X-Content-Type-Options, X-XSS-Protection

## Integration with Management API

The frontend communicates with management-api via these endpoints:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/modules` | GET | List all modules |
| `/api/modules/:name` | GET | Get module details |
| `/api/modules/:name/start` | POST | Start module |
| `/api/modules/:name/stop` | POST | Stop module |
| `/api/modules/:name/restart` | POST | Restart module |
| `/api/system/status` | GET | System metrics |
| `/api/logs` | GET | List log files |
| `/api/logs/:module` | GET | Read module logs |
| `/api/config` | GET | List config files |
| `/api/config/:module` | GET/PUT | Read/update config |

See `system/management-api/docs/API.md` for complete API documentation.

## Contributing

When making changes to the frontend:

1. **Develop locally** using `npm run dev`
2. **Test changes** thoroughly
3. **Build for production** with `npm run build`
4. **Test on Raspberry Pi** using `sudo ./setup.sh install`
5. **Update documentation** if adding features

## License

MIT License - Luigi Project

## Support

For issues or questions:
- GitHub Issues: https://github.com/pkathmann88/luigi/issues
- Documentation: See main project README
