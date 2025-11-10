#!/bin/bash
# Find Mobile App Notifier Name (Non-Interactive)
# Automatically discovers and returns first mobile app notifier

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$SCRIPT_DIR/deployment.log"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$timestamp] [$level] $message"
}

log_info() { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }

# Load environment variables from .env file
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(cat "$PROJECT_ROOT/.env" | grep -v '^#' | xargs)
else
    log_error ".env file not found"
    exit 1
fi

# Check if token is set
if [ -z "${HA_TOKEN:-}" ] || [ -z "${HA_URL:-}" ]; then
    log_error "HA_TOKEN or HA_URL not set in .env file"
    exit 1
fi

# Check if MOBILE_APP_NOTIFIER is set in environment
if [ -n "${MOBILE_APP_NOTIFIER:-}" ]; then
    echo "$MOBILE_APP_NOTIFIER"
    log_info "Using MOBILE_APP_NOTIFIER from environment: $MOBILE_APP_NOTIFIER"
    exit 0
fi

log_info "Searching for mobile app notifiers via HA API..."

# Get all services with retry logic
response=""
for attempt in {1..3}; do
    response=$(curl -s -H "Authorization: Bearer $HA_TOKEN" \
        -H "Content-Type: application/json" \
        "$HA_URL/api/services" 2>/dev/null)

    if [ -n "$response" ] && echo "$response" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
        break
    fi

    if [ $attempt -lt 3 ]; then
        sleep $((attempt * 2))
        log_info "Retry attempt $attempt..."
    fi
done

# Extract mobile app notifiers
mobile_notifier=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # Handle array format from HA API
    if isinstance(data, list):
        for item in data:
            if item.get('domain') == 'notify':
                services = item.get('services', {})
                mobile_apps = [k for k in services.keys() if k.startswith('mobile_app_')]
                if mobile_apps:
                    print(mobile_apps[0])
                    sys.exit(0)
        sys.exit(1)
    # Handle dict format (legacy)
    elif 'notify' in data:
        mobile_apps = [k for k in data['notify'].keys() if k.startswith('mobile_app_')]
        if mobile_apps:
            print(mobile_apps[0])
            sys.exit(0)
        else:
            sys.exit(1)
    else:
        sys.exit(1)
except Exception as e:
    sys.exit(1)
" 2>/dev/null)

if [ -z "$mobile_notifier" ]; then
    log_info "No mobile app notifiers found (continuing with Telegram only)"
    exit 0  # Non-fatal, return empty
fi

# MILESTONE 1.2 VALIDATION: Verify notifier exists
log_info "MILESTONE 1.2: Verifying notifier exists in HA services..."
if echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
notifier = '$mobile_notifier'
# Check array format
if isinstance(data, list):
    for item in data:
        if item.get('domain') == 'notify':
            services = item.get('services', {})
            if notifier in services:
                sys.exit(0)
    sys.exit(1)
# Check dict format
elif 'notify' in data:
    if notifier in data.get('notify', {}):
        sys.exit(0)
    sys.exit(1)
else:
    sys.exit(1)
" 2>/dev/null; then
    log_info "Notifier verified: $mobile_notifier"
    echo "$mobile_notifier"
    exit 0
else
    log_error "Notifier verification failed"
    exit 1
fi

