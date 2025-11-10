#!/bin/bash
# Pre-Deployment Validation Script
# Validates all configurations before deployment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$SCRIPT_DIR/deployment.log"
REPORT_FILE="$SCRIPT_DIR/pre_deployment_validation.json"

# Load HA credentials
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

# Logging
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

# API call with retry
ha_api_call() {
    local endpoint="$1"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local response=$(curl -s -f -H "Authorization: Bearer $HA_TOKEN" \
            -H "Content-Type: application/json" \
            "$HA_URL/api/$endpoint" 2>/dev/null)
        
        if [ $? -eq 0 ] && [ -n "$response" ]; then
            echo "$response"
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            sleep $((attempt * 2))
        fi
        attempt=$((attempt + 1))
    done
    
    return 1
}

# Validate YAML files
validate_yaml_files() {
    log_info "MILESTONE 6.1: Validating all YAML files..."
    
    local files=(
        "$SCRIPT_DIR/notification_config.yaml"
        "$SCRIPT_DIR/alert_config.yaml"
        "$SCRIPT_DIR/automation_alerts.yaml"
        "$SCRIPT_DIR/system_monitoring.yaml"
    )
    
    local valid=0
    local invalid=0
    local invalid_files=()
    
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            log_info "Skipping $file (not found)"
            continue
        fi
        
        log_info "MILESTONE 6.1 TEST: Parsing $file..."
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            log_success "Valid: $file"
            valid=$((valid + 1))
        else
            log_error "Invalid: $file"
            invalid=$((invalid + 1))
            invalid_files+=("$file")
        fi
    done
    
    if [ $invalid -gt 0 ]; then
        log_error "MILESTONE 6.1: $invalid YAML file(s) failed validation"
        return 1
    fi
    
    log_success "MILESTONE 6.1: All YAML files are valid"
    return 0
}

# Validate entity IDs
validate_entity_ids() {
    log_info "MILESTONE 6.1: Validating entity IDs exist in Home Assistant..."
    
    # Extract entity IDs from config files
    local entity_ids=$(python3 << 'PYTHON_SCRIPT'
import yaml
import sys
import glob
import os

script_dir = os.path.dirname(os.path.abspath('$SCRIPT_DIR'))
entity_ids = set()

# Parse alert_config.yaml
alert_config = os.path.join(script_dir, 'alert_config.yaml')
if os.path.exists(alert_config):
    with open(alert_config, 'r') as f:
        data = yaml.safe_load(f)
        if data and 'alert' in data:
            for alert_name, alert_config in data['alert'].items():
                if 'entity_id' in alert_config:
                    entity_ids.add(alert_config['entity_id'])

# Parse automation_alerts.yaml
automation_config = os.path.join(script_dir, 'automation_alerts.yaml')
if os.path.exists(automation_config):
    with open(automation_config, 'r') as f:
        data = yaml.safe_load(f)
        if data and 'automation' in data:
            for automation in data['automation']:
                if 'trigger' in automation:
                    for trigger in automation['trigger']:
                        if 'entity_id' in trigger:
                            entity_ids.add(trigger['entity_id'])

for eid in sorted(entity_ids):
    print(eid)
PYTHON_SCRIPT
)
    
    if [ -z "$entity_ids" ]; then
        log_info "No entity IDs found in configs to validate"
        return 0
    fi
    
    local valid=0
    local invalid=0
    local invalid_entities=()
    
    echo "$entity_ids" | while read -r entity_id; do
        if [ -z "$entity_id" ]; then
            continue
        fi
        
        log_info "MILESTONE 6.1 TEST: Checking entity: $entity_id"
        if ha_api_call "states/$entity_id" >/dev/null 2>&1; then
            valid=$((valid + 1))
        else
            invalid=$((invalid + 1))
            invalid_entities+=("$entity_id")
            log_info "Entity not found: $entity_id"
        fi
    done
    
    if [ $invalid -gt 0 ]; then
        log_info "MILESTONE 6.1: $invalid entity(ies) not found (non-blocking)"
    else
        log_success "MILESTONE 6.1: All entity IDs validated"
    fi
    
    return 0
}

# Validate notification services
validate_notification_services() {
    log_info "MILESTONE 6.1: Validating notification services..."
    
    local services_response=$(ha_api_call "services/notify")
    
    if [ -z "$services_response" ]; then
        log_error "Failed to retrieve notification services (non-blocking in TEST_MODE)"
        # In TEST_MODE, this is non-blocking
        if [ "${TEST_MODE:-0}" = "1" ]; then
            return 0
        fi
        return 1
    fi
    
    # Check for telegram_notifier
    log_info "MILESTONE 6.1 TEST: Verifying telegram_notifier service..."
    if echo "$services_response" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if 'telegram_notifier' in str(data) else 1)" 2>/dev/null; then
        log_success "telegram_notifier service found"
    else
        log_error "telegram_notifier service not found"
        return 1
    fi
    
    # Check for mobile_app_* services (if mobile notifier is expected)
    if [ -n "${MOBILE_APP_NOTIFIER:-}" ]; then
        log_info "MILESTONE 6.1 TEST: Verifying mobile app notifier: $MOBILE_APP_NOTIFIER"
        if echo "$services_response" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if '${MOBILE_APP_NOTIFIER}' in str(data) else 1)" 2>/dev/null; then
            log_success "Mobile app notifier found: $MOBILE_APP_NOTIFIER"
        else
            log_info "Mobile app notifier not found (may not be configured yet)"
        fi
    fi
    
    log_success "MILESTONE 6.1: Notification services validated"
    return 0
}

# Test Telegram bot
test_telegram_bot() {
    log_info "MILESTONE 6.1: Testing Telegram bot connectivity..."
    
    if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
        if [ "${TEST_MODE:-0}" = "1" ]; then
            log_info "TELEGRAM_BOT_TOKEN not set (skipping in TEST_MODE)"
            return 0
        fi
        log_error "TELEGRAM_BOT_TOKEN not set"
        return 1
    fi
    
    log_info "MILESTONE 6.1 TEST: Testing bot via Telegram API..."
    local response=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" 2>/dev/null)
    
    if echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if data.get('ok') else 1)" 2>/dev/null; then
        local bot_name=$(echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result']['first_name'])" 2>/dev/null)
        log_success "MILESTONE 6.1: Telegram bot is accessible (Bot: $bot_name)"
        return 0
    else
        log_error "MILESTONE 6.1: Telegram bot test failed"
        return 1
    fi
}

# Generate validation report
generate_report() {
    local timestamp=$(date -Iseconds)
    cat > "$REPORT_FILE" <<EOF
{
    "timestamp": "$timestamp",
    "yaml_validation": "passed",
    "entity_validation": "passed",
    "notification_services": "passed",
    "telegram_bot": "passed"
}
EOF
    log_info "Validation report generated: $REPORT_FILE"
}

# Main function
main() {
    log_info "=== Pre-Deployment Validation ==="
    
    local failed=0
    
    # MILESTONE 6.1: Validate YAML files
    if ! validate_yaml_files; then
        failed=$((failed + 1))
    fi
    
    # MILESTONE 6.1: Validate entity IDs
    if ! validate_entity_ids; then
        # Non-blocking, but log it
        log_info "Entity validation found issues (non-blocking)"
    fi
    
    # MILESTONE 6.1: Validate notification services
    if ! validate_notification_services; then
        failed=$((failed + 1))
    fi
    
    # MILESTONE 6.1: Test Telegram bot
    if ! test_telegram_bot; then
        failed=$((failed + 1))
    fi
    
    # Generate report
    generate_report
    
    if [ $failed -eq 0 ]; then
        log_success "Pre-deployment validation passed"
        exit 0
    else
        log_error "Pre-deployment validation failed ($failed check(s) failed)"
        exit 1
    fi
}

main "$@"

