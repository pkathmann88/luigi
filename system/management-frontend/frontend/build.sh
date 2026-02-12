#!/bin/bash

# Frontend Build and Deployment Script
# Builds the React frontend and ensures it's ready for deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR"
DIST_DIR="$FRONTEND_DIR/dist"

echo "=========================================="
echo "Luigi Management Frontend - Build Script"
echo "=========================================="
echo

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    echo "Please install Node.js >= 16.0.0"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 16 ]; then
    echo "Error: Node.js version must be >= 16.0.0"
    echo "Current version: $(node --version)"
    exit 1
fi

echo "✓ Node.js version: $(node --version)"
echo

# Install dependencies if node_modules doesn't exist
if [ ! -d "$FRONTEND_DIR/node_modules" ]; then
    echo "Installing dependencies..."
    npm install
    echo "✓ Dependencies installed"
    echo
else
    echo "✓ Dependencies already installed"
    echo
fi

# Run type check
echo "Running TypeScript type check..."
npm run type-check
echo "✓ Type check passed"
echo

# Build frontend
echo "Building frontend for production..."
npm run build
echo "✓ Build completed"
echo

# Verify dist directory exists
if [ ! -d "$DIST_DIR" ]; then
    echo "Error: Build failed - dist directory not found"
    exit 1
fi

# Display build info
echo "Build Summary:"
echo "  Output directory: $DIST_DIR"
echo "  Files:"
ls -lh "$DIST_DIR" | tail -n +2 | awk '{print "    " $9 " (" $5 ")"}'
echo

echo "=========================================="
echo "Build completed successfully!"
echo "=========================================="
echo
echo "The frontend is now ready to be served by the backend."
echo "The backend will automatically serve files from: frontend/dist/"
echo
