# Web-Frontend Development Skill

This Agent Skill provides comprehensive guidance for developing **modern web-frontend applications** using state-of-the-art technologies and best practices.

## What's Included

### 📘 SKILL.md (2,340 lines)
The main skill file with comprehensive documentation covering:

- **Browser Support Requirements** - Chrome, Edge, Firefox compatibility (MANDATORY)
- **Technology Stack** - React, Vue, TypeScript, Vite, modern build tools
- **Project Structure** - Recommended folder organization
- **Component Development** - React, Vue, and Web Component patterns
- **State Management** - Context API, Zustand, Redux Toolkit
- **API Integration** - Fetch, React Query, WebSocket
- **Responsive Design** - Mobile-first, CSS Grid, Flexbox, container queries
- **Performance Optimization** - Code splitting, lazy loading, memoization
- **Security Best Practices** - XSS prevention, CSP, authentication, input validation
- **Testing** - Unit tests (Vitest), integration tests (MSW), E2E tests (Playwright)
- **Build and Deployment** - Vite config, PWA, Docker, nginx
- **Common Patterns** - Error boundaries, custom hooks, dark mode
- **Troubleshooting** - Common issues and solutions
- **Best Practices Checklist** - Pre-commit and deployment checklists

### 📄 frontend-patterns.md (929 lines)
Advanced patterns and techniques:

- **Advanced State Management** - Jotai, Redux Toolkit patterns
- **Rendering Patterns** - SSR, SSG, ISR, streaming SSR
- **Data Fetching Strategies** - React Query advanced patterns, SWR
- **Real-Time Features** - SSE, WebSocket, GraphQL subscriptions
- **Advanced CSS Techniques** - CSS-in-JS, Tailwind patterns, Grid layouts
- **Performance Patterns** - Web Workers, idle callbacks, resource hints
- **Micro-Frontend Architecture** - Module Federation, Single-SPA
- **Progressive Enhancement** - Feature detection, graceful degradation

### 💻 react-example.tsx
A complete React + TypeScript example demonstrating best practices.

### 📦 package-example.json
Example package.json with all recommended dependencies and scripts for a production-ready frontend project.

## When to Use This Skill

Use this skill when you need to:

- ✅ Develop web-based user interfaces or dashboards
- ✅ Create responsive, mobile-first web applications
- ✅ Build single-page applications (SPAs)
- ✅ Implement progressive web apps (PWAs)
- ✅ Integrate frontend with backend APIs
- ✅ Optimize web application performance
- ✅ Ensure cross-browser compatibility (Chrome, Edge, Firefox)
- ✅ Set up modern build tooling and workflows
- ✅ Create component-based architectures
- ✅ Implement state management solutions
- ✅ Build real-time web applications
- ✅ Deploy frontend applications

## Browser Support Requirements

**MANDATORY:** All code generated using this skill MUST support:
- **Chrome/Chromium** - Latest stable + 1 previous major version
- **Edge** - Latest stable (Chromium-based)
- **Firefox** - Latest stable + 1 previous major version

Testing in all three browsers is required before code is considered complete.

## Key Features

### Modern Technology Stack

This skill emphasizes modern, production-ready technologies:

- **React 18+** with hooks and functional components
- **Vue 3+** with Composition API
- **TypeScript** for type safety
- **Vite** for fast development and optimized builds
- **Tailwind CSS** or CSS Modules for styling
- **React Query** or SWR for server state
- **Vitest** for unit testing
- **Playwright** for E2E testing

### Cross-Browser Compatibility

- Feature detection over browser detection
- Polyfills for missing features
- Progressive enhancement strategies
- Graceful degradation patterns

### Performance Optimized

- Code splitting and lazy loading
- Image optimization
- Virtual scrolling for large lists
- Memoization patterns
- Debouncing and throttling
- Web Workers for heavy computations

### Security Focused

- XSS prevention
- Content Security Policy
- Secure authentication patterns
- Input validation with Zod
- HTTPS requirements
- No sensitive data in localStorage

## Quick Start

1. **Read SKILL.md** - Comprehensive guide with all patterns
2. **Review frontend-patterns.md** - Advanced patterns for specific needs
3. **Study react-example.tsx** - See best practices in action
4. **Use package-example.json** - Bootstrap your own project

## Example Usage

```bash
# Create a new Vite + React + TypeScript project
npm create vite@latest my-app -- --template react-ts
cd my-app

# Install dependencies from package-example.json
npm install

# Start development server
npm run dev

# Run tests
npm run test

# Build for production
npm run build

# Preview production build
npm run preview
```

## Testing Cross-Browser Compatibility

```bash
# Install Playwright with all browsers
npx playwright install

# Run E2E tests in all browsers
npx playwright test --project=chromium --project=firefox --project=webkit
```

## Related Skills

This skill works together with other Luigi skills:

- **nodejs-backend-development** - Create backend APIs for your frontend
- **raspi-zero-w** - Deploy web UIs on Raspberry Pi
- **module-design** - Design before building
- **system-setup** - Deployment automation

## File Sizes

- SKILL.md: ~90KB (2,340 lines)
- frontend-patterns.md: ~40KB (929 lines)
- react-example.tsx: ~8KB (250+ lines)
- package-example.json: ~2KB
- **Total: ~140KB of documentation and examples**

## Architecture Overview

```
┌─────────────────────────────────────────┐
│         Browser (Chrome/Edge/Firefox)   │
└──────────────┬──────────────────────────┘
               │ HTTPS
               ▼
┌─────────────────────────────────────────┐
│         Frontend Application            │
│  ┌──────────────────────────────────┐   │
│  │ UI Layer (React/Vue)             │   │
│  │ - Components                     │   │
│  │ - Pages/Routes                   │   │
│  │ - Styles                         │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │ State Management                 │   │
│  │ - Context API/Zustand/Redux      │   │
│  │ - Local state                    │   │
│  │ - Server state (React Query)     │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │ Services Layer                   │   │
│  │ - API client                     │   │
│  │ - WebSocket manager              │   │
│  │ - Authentication                 │   │
│  └──────────────────────────────────┘   │
└──────────────┬──────────────────────────┘
               │ REST/WebSocket/GraphQL
               ▼
┌─────────────────────────────────────────┐
│         Backend APIs                    │
└─────────────────────────────────────────┘
```

## Best Practices Highlights

### Code Quality
- TypeScript strict mode enabled
- ESLint + Prettier configured
- 100% test coverage for critical paths
- Component-driven development

### Performance
- Lighthouse score > 90
- First Contentful Paint < 1.5s
- Time to Interactive < 3.5s
- Bundle size < 200KB (initial)

### Security
- No XSS vulnerabilities
- CSP headers configured
- Input validation on all forms
- HTTPS enforced

## License

MIT License - Same as the Luigi project

## Contributing

Improvements to this skill are welcome! If you find issues or have suggestions, please contribute to the Luigi project.

---

**Built for Luigi** - A modular IoT platform for Raspberry Pi Zero W
