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
  // Disable esbuild optimizer for ARMv6 compatibility
  // This ensures the build works on Raspberry Pi Zero W (ARMv6 architecture)
  optimizeDeps: {
    esbuildOptions: {
      target: 'es2015',
    },
  },
})
