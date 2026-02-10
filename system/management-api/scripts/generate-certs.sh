#!/bin/bash
# generate-certs.sh - Generate self-signed TLS certificates

set -e

CERTS_DIR="/home/pi/certs"
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
chmod 600 server.key
chmod 644 server.crt

# Clean up CSR
rm server.csr

echo "Certificate generated successfully!"
echo "Certificate location: $CERTS_DIR/server.crt"
echo "Private key location: $CERTS_DIR/server.key"
echo "Valid for $DAYS_VALID days"
