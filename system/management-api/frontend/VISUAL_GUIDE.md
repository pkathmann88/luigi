# Luigi Management Frontend - Visual Guide

## Overview

The Luigi Management Frontend is a modern, responsive web application built with React and TypeScript that provides a sleek user interface for managing the Luigi system.

## Key Features

### 1. Login Page

**Design:**
- Centered login form with gradient background
- Clean, modern card-based design
- Dark theme with blue accents
- Responsive layout that works on all devices

**Features:**
- Username and password fields
- Form validation
- Error message display
- Default credentials shown for convenience
- Loading state during authentication

**Credentials:**
- Stored in `credentials.txt` file
- Default: `admin:changeme123`
- Validated against static file on login

### 2. Dashboard

**Design:**
- Grid layout with metric cards
- Real-time data updates every 10 seconds
- Color-coded progress bars (green/yellow/red)
- System action buttons

**Metrics Displayed:**
- System uptime (formatted as days/hours/minutes)
- CPU usage with temperature (if available)
- Memory usage with total/used display
- Disk usage with total/used display

**System Actions:**
- Update System
- Clean Up
- Reboot
- Shutdown

### 3. Module Management

**Design:**
- Card-based grid layout
- Status badges (Active, Inactive, Failed, Unknown)
- Module information display (PID, uptime, memory)
- Action buttons for each module

**Features:**
- Start/Stop/Restart modules
- Real-time status updates
- Loading states for actions
- Disabled buttons based on current state
- Auto-refresh capability

### 4. Log Viewer

**Design:**
- Two-panel layout (sidebar + content)
- List of available log files
- Monospace font for log content
- Full-width log display

**Features:**
- Select log file from sidebar
- View last 100 lines
- Scrollable log content
- Search capability (API support)
- Refresh button

### 5. Configuration Editor

**Design:**
- Two-panel layout (sidebar + content)
- Form-based configuration editing
- Save button with success/error feedback

**Features:**
- Select config file from sidebar
- Edit configuration key-value pairs
- Save changes with automatic backup (backend)
- Success/error notifications
- Disabled state when no config selected

## Design System

### Color Palette

**Primary Colors:**
- Primary Blue: `#3b82f6`
- Primary Blue Dark: `#2563eb`
- Primary Blue Light: `#60a5fa`

**Status Colors:**
- Success Green: `#10b981`
- Warning Orange: `#f59e0b`
- Danger Red: `#ef4444`
- Info Blue: `#3b82f6`

**Background Colors:**
- Main Background: `#0f172a` (dark blue-gray)
- Secondary Background: `#1e293b`
- Tertiary Background: `#334155`

**Text Colors:**
- Primary Text: `#f1f5f9` (light gray)
- Secondary Text: `#cbd5e1`
- Muted Text: `#94a3b8`

**Border Colors:**
- Default: `#334155`
- Light: `#475569`

### Typography

- Font Family: System fonts (-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', etc.)
- Heading Sizes: 2rem, 1.5rem, 1.25rem
- Body Size: 1rem
- Small Size: 0.875rem, 0.75rem

### Spacing

- XS: 0.25rem
- SM: 0.5rem
- MD: 1rem (base)
- LG: 1.5rem
- XL: 2rem
- 2XL: 3rem

### Components

**Button:**
- Variants: primary, secondary, success, danger, ghost
- Sizes: small, medium, large
- States: default, hover, disabled, loading
- Full-width option available

**Card:**
- Rounded corners (1rem)
- Subtle shadow
- Border
- Optional title
- Hover effect (shadow increase)

**Layout:**
- Fixed sidebar navigation (240px wide)
- Scrollable main content area
- Responsive: sidebar collapses on mobile

### Responsive Design

**Desktop (> 768px):**
- Full sidebar visible
- Grid layouts with multiple columns
- Larger text and spacing

**Tablet (768px - 480px):**
- Sidebar can be toggled
- Grid layouts collapse to fewer columns
- Adjusted spacing

**Mobile (< 480px):**
- Single column layouts
- Stacked elements
- Reduced padding and margins
- Full-width buttons

## Technical Architecture

### Frontend Stack

- **React 18** - UI framework with hooks
- **TypeScript** - Type safety
- **Vite** - Build tool and dev server
- **React Router** - Client-side routing
- **Native CSS** - No CSS framework, custom styles

### Key Services

**authService:**
- Manages authentication state
- Validates credentials against static file
- Stores credentials in localStorage
- Provides authorization headers

**apiService:**
- Handles all API communication
- Automatic authentication header injection
- Error handling and response parsing
- Support for all management-api endpoints

### Routing

- `/login` - Login page (public)
- `/dashboard` - System dashboard (protected)
- `/modules` - Module management (protected)
- `/logs` - Log viewer (protected)
- `/config` - Configuration editor (protected)
- `/` - Redirects to dashboard

Protected routes require authentication and redirect to login if not authenticated.

### State Management

- React hooks (useState, useEffect)
- No external state management library
- Local component state
- Service layer for shared logic

## Browser Compatibility

**Tested and supported:**
- Chrome/Chromium (latest + 1 previous)
- Edge (latest, Chromium-based)
- Firefox (latest + 1 previous)

**Features used:**
- CSS Grid and Flexbox
- CSS Custom Properties
- ES2020 JavaScript features
- Fetch API
- localStorage API

## Security Features

1. **Static Credentials:**
   - Stored in filesystem file
   - Validated on login
   - Not hardcoded in client code

2. **Authentication:**
   - HTTP Basic Auth for API calls
   - Credentials stored in localStorage
   - Automatic logout on 401 responses

3. **HTTPS Required:**
   - Backend requires HTTPS in production
   - Credentials sent securely

4. **Content Security Policy:**
   - Backend enforces CSP headers
   - Prevents XSS attacks

5. **Input Validation:**
   - Form validation on client
   - Backend validation as well

## Performance

**Optimizations:**
- Code splitting (React vendor bundle)
- Gzip compression
- CSS minification
- JavaScript minification
- Lazy loading of routes
- Sourcemaps for debugging

**Bundle Sizes:**
- Main bundle: ~19 KB (gzipped: ~5.4 KB)
- React vendor: ~160 KB (gzipped: ~52 KB)
- CSS: ~16 KB (gzipped: ~3 KB)
- Total: ~195 KB (gzipped: ~60 KB)

**Load Times:**
- Initial load: < 1 second on good connection
- Subsequent navigation: instant (client-side routing)
- API calls: depends on backend response time

## Development Workflow

1. **Local Development:**
   ```bash
   npm run dev
   ```
   - Hot module replacement
   - Proxy to backend API
   - Source maps

2. **Type Checking:**
   ```bash
   npm run type-check
   ```
   - TypeScript compilation check
   - No output generated

3. **Linting:**
   ```bash
   npm run lint
   ```
   - ESLint checks
   - React hooks rules
   - TypeScript rules

4. **Building:**
   ```bash
   npm run build
   ```
   - TypeScript compilation
   - Vite production build
   - Output to `dist/`

5. **Preview:**
   ```bash
   npm run preview
   ```
   - Serve production build locally
   - Test before deployment

## Deployment

The frontend is designed to be served by the management-api backend:

1. Build the frontend: `npm run build`
2. Built files are in `dist/` directory
3. Backend serves static files from `frontend/dist/`
4. SPA routing handled by backend catch-all route

No separate web server required - the Node.js backend serves everything.

## Future Enhancements

Potential improvements:
- Real-time updates via WebSocket
- Advanced log search and filtering
- Module dependency visualization
- System health alerts/notifications
- Configuration file validation
- Multi-user support with roles
- Dark/light theme toggle
- Internationalization (i18n)
- Progressive Web App (PWA) features
- Mobile app wrapper (React Native)

## Conclusion

The Luigi Management Frontend provides a modern, user-friendly interface for system administration. Built with modern web technologies and following best practices, it offers a responsive, secure, and performant experience across all devices and browsers.
