#!/bin/bash
# test-api.sh - Test API endpoints

set -e

API_URL="${API_URL:-https://localhost:8443}"
AUTH_USER="${AUTH_USER:-admin}"
AUTH_PASS="${AUTH_PASS:-admin}"

echo "Luigi API Test Script"
echo "====================="
echo "API URL: $API_URL"
echo ""

# Test 1: Health check (no auth)
echo "Test 1: Health check (no auth)"
curl -k -s -w "\nHTTP Status: %{http_code}\n" "$API_URL/health"
echo ""

# Test 2: Anonymous access to protected endpoint (should fail with 401)
echo "Test 2: Anonymous access (should fail with 401)"
curl -k -s -w "\nHTTP Status: %{http_code}\n" "$API_URL/api/modules"
echo ""

# Test 3: Valid authentication
echo "Test 3: List modules (with auth)"
curl -k -s -w "\nHTTP Status: %{http_code}\n" \
  -u "$AUTH_USER:$AUTH_PASS" \
  "$API_URL/api/modules"
echo ""

# Test 4: System status
echo "Test 4: System status"
curl -k -s -w "\nHTTP Status: %{http_code}\n" \
  -u "$AUTH_USER:$AUTH_PASS" \
  "$API_URL/api/system/status"
echo ""

# Test 5: List log files
echo "Test 5: List log files"
curl -k -s -w "\nHTTP Status: %{http_code}\n" \
  -u "$AUTH_USER:$AUTH_PASS" \
  "$API_URL/api/logs"
echo ""

# Test 6: Monitoring metrics
echo "Test 6: Monitoring metrics"
curl -k -s -w "\nHTTP Status: %{http_code}\n" \
  -u "$AUTH_USER:$AUTH_PASS" \
  "$API_URL/api/monitoring/metrics"
echo ""

echo "Tests complete!"
