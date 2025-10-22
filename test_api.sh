#!/bin/bash
# SCNMS API Test Script
# Tests all major API endpoints

set -e

API_BASE="http://localhost:8000"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================"
echo "SCNMS API Test Script"
echo "================================"
echo ""

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    
    echo -n "Testing: $description... "
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$API_BASE$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X $method "$API_BASE$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $http_code)"
        echo "  Response: $body"
        return 1
    fi
}

# Check if API is running
echo "Checking if API is available..."
if ! curl -s "$API_BASE/health" > /dev/null 2>&1; then
    echo -e "${RED}Error: API is not responding at $API_BASE${NC}"
    echo "Please start the services first: ./start.sh"
    exit 1
fi
echo -e "${GREEN}✓ API is running${NC}"
echo ""

# Test Health Endpoints
echo "=== Health Checks ==="
test_endpoint "GET" "/health" "API Gateway Health"
test_endpoint "GET" "/api/v1/health/services" "All Services Health"
echo ""

# Test Device Management
echo "=== Device Management ==="
test_endpoint "GET" "/api/v1/devices" "List Devices"
test_endpoint "POST" "/api/v1/devices" "Create Device" '{
  "name": "Test-Device",
  "ip_address": "192.168.100.1",
  "snmp_enabled": true,
  "snmp_community": "public",
  "snmp_version": "2c"
}'
test_endpoint "GET" "/api/v1/devices/1" "Get Device by ID"
echo ""

# Test Metrics
echo "=== Metrics ==="
test_endpoint "GET" "/api/v1/metrics?limit=10" "Query Metrics"
test_endpoint "GET" "/api/v1/metrics/latest" "Get Latest Metrics"
echo ""

# Test Alarms
echo "=== Alarms ==="
test_endpoint "GET" "/api/v1/alarms" "List Alarms"
test_endpoint "GET" "/api/v1/alarms/stats/summary" "Alarm Statistics"
echo ""

# Test Alarm Rules
echo "=== Alarm Rules ==="
test_endpoint "GET" "/api/v1/alarm-rules" "List Alarm Rules"
test_endpoint "POST" "/api/v1/alarm-rules" "Create Alarm Rule" '{
  "name": "Test High CPU",
  "metric_name": "cpu_utilization",
  "threshold_value": 90.0,
  "comparison_operator": ">",
  "duration_seconds": 300,
  "severity": "major",
  "enabled": true
}'
echo ""

# Test Polling Jobs
echo "=== Polling Jobs ==="
test_endpoint "GET" "/api/v1/polling-jobs" "List Polling Jobs"
echo ""

# Test Dashboard
echo "=== Dashboard ==="
test_endpoint "GET" "/api/v1/dashboard/summary" "Dashboard Summary"
test_endpoint "GET" "/api/v1/dashboard/device-health" "Device Health Summary"
echo ""

echo "================================"
echo "API Test Complete!"
echo "================================"
echo ""
echo "View API Documentation: $API_BASE/docs"
echo ""
