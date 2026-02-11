# Luigi Management Frontend

Modern, responsive web frontend for the Luigi Management API.

## Features

- **Login Page** - Static credential authentication with username/password stored in filesystem
- **Dashboard** - Real-time system monitoring (CPU, memory, disk, uptime)
- **Module Management** - Start, stop, restart Luigi modules
- **Log Viewer** - Browse and view system logs
- **Configuration Editor** - View and edit module configurations
- **Responsive Design** - Works on desktop, tablet, and mobile devices
- **Modern UI** - Sleek, dark-themed interface with smooth animations

## Technology Stack

- **React 18** - Modern React with hooks
- **TypeScript** - Type-safe code
- **Vite** - Fast build tool and dev server
- **CSS3** - Custom CSS with modern features
- **React Router** - Client-side routing

## Development

### Prerequisites

- Node.js >= 16.0.0
- npm >= 8.0.0
- Luigi Management API running (backend)

### Installation

```bash
# Install dependencies
npm install
```

### Running Locally

```bash
# Start development server (with hot reload)
npm run dev
```

The frontend will be available at `http://localhost:3000`.

The dev server proxies API requests to `https://localhost:8443` (backend).

### Building for Production

```bash
# Build optimized production bundle
npm run build
```

The production files will be in the `dist/` directory.

### Type Checking

```bash
# Check TypeScript types
npm run type-check
```

### Linting

```bash
# Lint code
npm run lint
```

## Credentials

Static credentials are stored in `credentials.txt` file:

```
admin:changeme123
```

**Important:** Change the default password before deploying to production!

## Configuration

Environment variables in `.env`:

```bash
# API Base URL (leave empty to use same origin)
VITE_API_URL=
```

## Project Structure

```
frontend/
├── src/
│   ├── components/       # Reusable UI components
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   └── Layout.tsx
│   ├── pages/           # Page components
│   │   ├── Login.tsx
│   │   ├── Dashboard.tsx
│   │   ├── Modules.tsx
│   │   ├── Logs.tsx
│   │   └── Config.tsx
│   ├── services/        # API and auth services
│   │   ├── apiService.ts
│   │   └── authService.ts
│   ├── types/           # TypeScript types
│   │   └── api.ts
│   ├── styles/          # Global styles
│   │   └── globals.css
│   ├── App.tsx          # Main app with routing
│   └── main.tsx         # Entry point
├── public/              # Static assets
├── index.html           # HTML template
├── vite.config.ts       # Vite configuration
├── tsconfig.json        # TypeScript configuration
└── package.json         # Dependencies
```

## Deployment

### Option 1: Static Files (Recommended)

1. Build the frontend:
   ```bash
   npm run build
   ```

2. Copy `dist/` contents to backend's public directory:
   ```bash
   cp -r dist/* ../public/
   ```

3. Backend will serve the frontend at the root URL

### Option 2: Separate Server

1. Build the frontend:
   ```bash
   npm run build
   ```

2. Serve `dist/` with any static file server (nginx, Apache, etc.)

3. Configure CORS in backend to allow frontend origin

## Browser Support

- Chrome/Chromium (latest + 1 previous major version)
- Edge (latest, Chromium-based)
- Firefox (latest + 1 previous major version)

## Security

- Static credentials stored in plaintext file (change in production!)
- HTTP Basic Authentication used for API calls
- HTTPS required for backend API
- Credentials stored in localStorage (cleared on logout)
- CORS configured for local network access

## License

MIT
