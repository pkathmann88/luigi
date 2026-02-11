import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import os from 'os'

// Detect if running on ARMv6 (Raspberry Pi Zero W)
// ARMv6 systems report 'arm' architecture and typically have ARMv6 in CPU model
const isARMv6 = (() => {
  const arch = process.arch
  if (arch !== 'arm') {
    return false
  }
  // Check CPU model for ARMv6 indication (e.g., BCM2835 on Pi Zero W)
  try {
    const cpus = os.cpus()
    const cpuModel = (cpus[0]?.model || '').toLowerCase()
    // BCM2835 is the chip on Raspberry Pi Zero W (ARMv6)
    // Also check for explicit ARMv6 in model string (case-insensitive)
    const isV6 = cpuModel.includes('bcm2835') || cpuModel.includes('armv6')
    if (isV6) {
      console.log('[Vite] Detected ARMv6 architecture, using Terser for minification')
    }
    return isV6
  } catch (error) {
    // If we can't determine CPU model, log the error and assume ARMv6 to be safe on 'arm' architecture
    console.warn('[Vite] Unable to detect CPU model, defaulting to Terser for ARM compatibility:', error)
    return true
  }
})()

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
    // Conditionally use terser for ARMv6 compatibility (Raspberry Pi Zero W)
    // ARMv6 cannot run esbuild native binaries, so we use terser (pure JavaScript)
    // Other architectures use the default esbuild minification (faster)
    minify: isARMv6 ? 'terser' : 'esbuild',
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
  optimizeDeps: {
    esbuildOptions: {
      target: 'es2015',
    },
  },
})
