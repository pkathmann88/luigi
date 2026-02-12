#!/bin/bash
# Test script to demonstrate startup output
# This simulates what you'll see in journalctl logs when the service starts

echo "This is what you'll see in the logs when management-api starts:"
echo ""
echo "Example output with HTTPS enabled and valid certificates:"
echo "=========================================================="
cat << 'EOF'
==========================================
Luigi Management API - Configuration Loading
==========================================
Loading configuration from: /etc/luigi/system/management-api/.env
Node Environment: production
Port: 8443
Host: 0.0.0.0
HTTPS Enabled: true
Modules Path: /home/pi/luigi
Config Path: /etc/luigi
Registry Path: /etc/luigi/modules
Log File: /var/log/luigi/management-api.log
------------------------------------------
Validating configuration...
WARNING: IP whitelist is empty. All local network IPs will be allowed.
✓ Configuration validation passed
==========================================
Loading Express application modules...
✓ All modules loaded successfully
Initializing Express application...
✓ Express application configured successfully
✓ All middleware and routes registered

==========================================
Luigi Management API - Server Startup
==========================================
[INFO] Starting Luigi Management API Server
[INFO] Environment: production
[INFO] Process ID: 12345
[INFO] Node Version: v16.20.0
[INFO] Working Directory: /home/pi/luigi/system/management-api
------------------------------------------
TLS Configuration:
[INFO] Using TLS certificates:
[INFO]   Cert: /home/pi/certs/server.crt
[INFO]   Key: /home/pi/certs/server.key
Checking certificate files...
✓ Certificate file found: /home/pi/certs/server.crt
✓ Key file found: /home/pi/certs/server.key
Reading certificate files...
✓ Certificate files loaded successfully
Creating HTTPS server...
[INFO] HTTPS enabled
✓ HTTPS server created
------------------------------------------
Starting server on 0.0.0.0:8443...
✓ Server started successfully!
==========================================
Server Information:
[INFO] Server running on https://0.0.0.0:8443
[INFO] Health check: https://0.0.0.0:8443/health
[INFO] API endpoints: https://0.0.0.0:8443/api/*
==========================================

Server is ready to accept connections.
Press Ctrl+C to stop the server.

EOF

echo ""
echo "=========================================================="
echo ""
echo "Example output when certificates are missing:"
echo "=========================================================="
cat << 'EOF'
==========================================
Luigi Management API - Configuration Loading
==========================================
Loading configuration from: /etc/luigi/system/management-api/.env
Node Environment: production
Port: 8443
Host: 0.0.0.0
HTTPS Enabled: true
Modules Path: /home/pi/luigi
Config Path: /etc/luigi
Registry Path: /etc/luigi/modules
Log File: /var/log/luigi/management-api.log
------------------------------------------
Validating configuration...
WARNING: IP whitelist is empty. All local network IPs will be allowed.
✓ Configuration validation passed
==========================================
Loading Express application modules...
✓ All modules loaded successfully
Initializing Express application...
✓ Express application configured successfully
✓ All middleware and routes registered

==========================================
Luigi Management API - Server Startup
==========================================
[INFO] Starting Luigi Management API Server
[INFO] Environment: production
[INFO] Process ID: 12345
[INFO] Node Version: v16.20.0
[INFO] Working Directory: /home/pi/luigi/system/management-api
------------------------------------------
TLS Configuration:
[INFO] Using TLS certificates:
[INFO]   Cert: /home/pi/certs/server.crt
[INFO]   Key: /home/pi/certs/server.key
Checking certificate files...
✗ Certificate file not found: /home/pi/certs/server.crt
[ERROR] SSL certificate not found!
[ERROR] Expected location: /home/pi/certs/server.crt
[ERROR] Run: bash scripts/generate-certs.sh

==========================================
✗ FATAL ERROR: Failed to start server
==========================================
EOF

echo ""
echo "=========================================================="
echo ""
echo "To view these logs in real-time:"
echo "  sudo journalctl -u management-api -f"
echo ""
echo "To view recent logs:"
echo "  sudo journalctl -u management-api -n 50"
echo ""
