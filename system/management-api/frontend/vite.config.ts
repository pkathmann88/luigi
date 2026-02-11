import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'https://localhost:8443',
        changeOrigin: true,
        secure: false,
      },
      '/health': {
        target: 'https://localhost:8443',
        changeOrigin: true,
        secure: false,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    // Disable esbuild minification for ARMv6 compatibility (Raspberry Pi Zero W)
    // Use terser instead, which is pure JavaScript and doesn't require native binaries
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom', 'react-router-dom'],
        },
      },
    },
  },
  // Set esbuild target for dependency optimization
  // Note: This is used during dev server startup, not the production build
  // The production build uses Terser (see minify: 'terser' above) for ARMv6 compatibility
  optimizeDeps: {
    esbuildOptions: {
      target: 'es2015',
    },
  },
})
