#!/bin/bash
# Test Home Assistant API token
# This script verifies that the token works and can access the Home Assistant API

set -e

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ Error: .env file not found"
    echo "Please create .env file with HA_TOKEN and HA_URL"
    exit 1
fi

# Check if token is set
if [ -z "$HA_TOKEN" ]; then
    echo "❌ Error: HA_TOKEN not set in .env file"
    exit 1
fi

if [ -z "$HA_URL" ]; then
    echo "❌ Error: HA_URL not set in .env file"
    exit 1
fi

echo "🔍 Testing Home Assistant API connection..."
echo "URL: $HA_URL"
echo ""

# Test API connection
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $HA_TOKEN" \
    -H "Content-Type: application/json" \
    "$HA_URL/api/")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Token is valid! API connection successful"
    echo ""
    echo "API Response:"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
else
    echo "❌ Error: API connection failed"
    echo "HTTP Status Code: $HTTP_CODE"
    echo "Response: $BODY"
    exit 1
fi

echo ""
echo "📊 Testing API endpoints..."

# Test config endpoint
echo -n "  Config endpoint: "
CONFIG_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $HA_TOKEN" \
    "$HA_URL/api/config")
[ "$CONFIG_CODE" = "200" ] && echo "✅" || echo "❌ ($CONFIG_CODE)"

# Test states endpoint
echo -n "  States endpoint: "
STATES_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $HA_TOKEN" \
    "$HA_URL/api/states")
[ "$STATES_CODE" = "200" ] && echo "✅" || echo "❌ ($STATES_CODE)"

# Test services endpoint
echo -n "  Services endpoint: "
SERVICES_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $HA_TOKEN" \
    "$HA_URL/api/services")
[ "$SERVICES_CODE" = "200" ] && echo "✅" || echo "❌ ($SERVICES_CODE)"

echo ""
echo "✅ All tests completed!"

