#!/bin/bash
# generate-certs.sh - Generate self-signed TLS certificates

set -e

CERTS_DIR="/etc/luigi/system/management-api/certs"
DAYS_VALID=365

echo "Generating self-signed SSL certificate..."

# Create certs directory
mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

# Generate private key
openssl genrsa -out server.key 2048

# Generate certificate signing request
openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=State/L=City/O=Luigi/CN=raspberrypi.local"

# Generate self-signed certificate
openssl x509 -req -days $DAYS_VALID -in server.csr \
  -signkey server.key -out server.crt

# Set proper permissions
# Private key: readable by owner and group (service user needs access)
chmod 640 server.key
# Certificate: world-readable (public certificate)
chmod 644 server.crt

# Set ownership to allow service user to read
# Service will run as 'luigi-api' user, so set group to 'luigi-api' for key access
chown root:luigi-api server.key server.crt

# Clean up CSR
rm server.csr

echo "Certificate generated successfully!"
echo "Certificate location: $CERTS_DIR/server.crt"
echo "Private key location: $CERTS_DIR/server.key"
echo "Valid for $DAYS_VALID days"
