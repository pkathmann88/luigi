#!/bin/bash
# Pre-start validation script for management-api service
# Checks that required files and configuration exist before starting the service

set -e

# Load environment configuration
if [ -f /etc/luigi/system/management-api/.env ]; then
    # Source the .env file to get configuration
    set -a
    source /etc/luigi/system/management-api/.env
    set +a
else
    echo "ERROR: Configuration file not found: /etc/luigi/system/management-api/.env"
    exit 1
fi

# Check if HTTPS is enabled and certificates are required
if [ "${USE_HTTPS}" = "true" ]; then
    # Check if certificate files exist
    if [ ! -f "${TLS_CERT_PATH}" ]; then
        echo "ERROR: TLS certificate not found: ${TLS_CERT_PATH}"
        echo "HINT: Run the certificate generation script or disable HTTPS"
        echo "  To generate certificates: bash scripts/generate-certs.sh"
        echo "  To disable HTTPS: Set USE_HTTPS=false in /etc/luigi/system/management-api/.env"
        exit 1
    fi
    
    if [ ! -f "${TLS_KEY_PATH}" ]; then
        echo "ERROR: TLS private key not found: ${TLS_KEY_PATH}"
        echo "HINT: Run the certificate generation script or disable HTTPS"
        echo "  To generate certificates: bash scripts/generate-certs.sh"
        echo "  To disable HTTPS: Set USE_HTTPS=false in /etc/luigi/system/management-api/.env"
        exit 1
    fi
    
    # Check if certificates are readable
    if [ ! -r "${TLS_CERT_PATH}" ]; then
        echo "ERROR: TLS certificate is not readable: ${TLS_CERT_PATH}"
        echo "HINT: Check file permissions"
        exit 1
    fi
    
    if [ ! -r "${TLS_KEY_PATH}" ]; then
        echo "ERROR: TLS private key is not readable: ${TLS_KEY_PATH}"
        echo "HINT: Check file permissions"
        exit 1
    fi
    
    echo "Pre-start check passed: TLS certificates found and readable"
else
    echo "Pre-start check passed: HTTPS disabled"
fi

# Check if log directory is writable
if [ ! -w /var/log/luigi ]; then
    echo "ERROR: Log directory is not writable: /var/log/luigi"
    exit 1
fi

exit 0
