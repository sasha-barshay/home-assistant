#!/bin/bash
# Home Assistant API Helper Script
# Provides convenient functions to interact with Home Assistant API

set -e

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ Error: .env file not found"
    exit 1
fi

# Check if token is set
if [ -z "$HA_TOKEN" ] || [ -z "$HA_URL" ]; then
    echo "❌ Error: HA_TOKEN or HA_URL not set in .env file"
    exit 1
fi

# Function to make API calls
ha_api_call() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="$3"
    
    local url="$HA_URL/api/$endpoint"
    local curl_opts=(
        -s
        -H "Authorization: Bearer $HA_TOKEN"
        -H "Content-Type: application/json"
        -X "$method"
    )
    
    if [ -n "$data" ]; then
        curl_opts+=(-d "$data")
    fi
    
    curl "${curl_opts[@]}" "$url"
}

# Function to pretty print JSON
pretty_json() {
    python3 -m json.tool 2>/dev/null || cat
}

# Main command handler
case "${1:-help}" in
    config)
        echo "📋 Home Assistant Configuration:"
        ha_api_call GET config | pretty_json
        ;;
    
    states)
        if [ -n "$2" ]; then
            echo "🔍 Entity State: $2"
            ha_api_call GET "states/$2" | pretty_json
        else
            echo "📊 All Entity States:"
            ha_api_call GET states | pretty_json
        fi
        ;;
    
    services)
        if [ -n "$2" ]; then
            echo "🔧 Service: $2"
            ha_api_call GET "services/$2" | pretty_json
        else
            echo "🔧 Available Services:"
            ha_api_call GET services | pretty_json
        fi
        ;;
    
    call-service)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 call-service <domain> <service> [entity_id]"
            echo "Example: $0 call-service light turn_on light.living_room"
            exit 1
        fi
        
        local domain="$2"
        local service="$3"
        local entity_id="$4"
        
        local payload="{"
        if [ -n "$entity_id" ]; then
            payload+="\"entity_id\": \"$entity_id\""
        fi
        payload+="}"
        
        echo "🔧 Calling service: $domain.$service"
        ha_api_call POST "services/$domain/$service" "$payload" | pretty_json
        ;;
    
    events)
        echo "📡 Available Events:"
        ha_api_call GET events | pretty_json
        ;;
    
    history)
        if [ -n "$2" ]; then
            echo "📜 History for entity: $2"
            ha_api_call GET "history/period?filter_entity_id=$2" | pretty_json
        else
            echo "📜 Recent History:"
            ha_api_call GET "history/period" | pretty_json | head -100
        fi
        ;;
    
    logbook)
        echo "📖 Logbook:"
        ha_api_call GET logbook | pretty_json | head -50
        ;;
    
    test)
        echo "🧪 Testing API connection..."
        response=$(ha_api_call GET "")
        if echo "$response" | grep -q "API running"; then
            echo "✅ API connection successful"
        else
            echo "❌ API connection failed"
            echo "$response"
            exit 1
        fi
        ;;
    
    help|*)
        echo "Home Assistant API Helper"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  config                    - Get Home Assistant configuration"
        echo "  states [entity_id]        - List all states or get specific entity state"
        echo "  services [domain]         - List all services or services for a domain"
        echo "  call-service <domain> <service> [entity_id]  - Call a service"
        echo "  events                    - List available events"
        echo "  history [entity_id]       - Get history (all or for specific entity)"
        echo "  logbook                   - Get logbook entries"
        echo "  test                      - Test API connection"
        echo "  help                      - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 config"
        echo "  $0 states"
        echo "  $0 states light.living_room"
        echo "  $0 call-service light turn_on light.living_room"
        echo "  $0 history sensor.temperature"
        ;;
esac

