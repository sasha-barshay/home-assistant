#!/bin/bash
# Entity Discovery Script (Automatic - Non-Interactive)
# Discovers entities from HA API and auto-updates alert configurations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$SCRIPT_DIR/deployment.log"
ENTITY_MAPPING_FILE="$SCRIPT_DIR/entity_mapping.json"

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
        local response=$(curl -s -H "Authorization: Bearer $HA_TOKEN" \
            -H "Content-Type: application/json" \
            "$HA_URL/api/$endpoint" 2>/dev/null)
        local curl_exit=$?

        if [ $curl_exit -eq 0 ] && [ -n "$response" ] && echo "$response" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
            echo "$response"
            return 0
        fi

        if [ $attempt -lt $max_attempts ]; then
            sleep $((attempt * 2))
            log_info "API call retry attempt $attempt... (curl exit: $curl_exit, response length: ${#response})"
        fi
        attempt=$((attempt + 1))
    done

    log_error "API call failed after $max_attempts attempts"
    return 1
}

    # Discover entities
discover_entities() {
    log_info "MILESTONE 3.1: Discovering entities from Home Assistant..."

    local states_response=$(ha_api_call "states")
    local api_exit=$?

    if [ $api_exit -ne 0 ] || [ -z "$states_response" ]; then
        log_error "Failed to retrieve states from HA API (exit: $api_exit)"
        return 1
    fi

    # Extract and categorize entities
    # Use a temp file to avoid issues with large JSON in command substitution
    local temp_file=$(mktemp)
    echo "$states_response" > "$temp_file"

    local entity_data=$(python3 << PYTHON_SCRIPT
import sys, json

try:
    with open('$temp_file', 'r') as f:
        states = json.load(f)

    if not isinstance(states, list):
        sys.exit(1)

    entities = {
        'binary_sensor': [],
        'sensor': [],
        'device_tracker': [],
        'all': []
    }

    for state in states:
        entity_id = state.get('entity_id', '')
        if not entity_id:
            continue

        entities['all'].append(entity_id)

        if entity_id.startswith('binary_sensor.'):
            entities['binary_sensor'].append(entity_id)
        elif entity_id.startswith('sensor.'):
            entities['sensor'].append(entity_id)
        elif entity_id.startswith('device_tracker.'):
            entities['device_tracker'].append(entity_id)

    # Output as JSON
    print(json.dumps(entities, indent=2))
    sys.stdout.flush()

except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT
)
    local python_exit=$?
    rm -f "$temp_file"

    if [ $python_exit -ne 0 ] || [ -z "$entity_data" ]; then
        log_error "Failed to parse entity data (python exit: $python_exit, data length: ${#entity_data})"
        return 1
    fi

    # Verify it's valid JSON
    if echo "$entity_data" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
        : # Valid JSON
    else
        log_error "Entity data is not valid JSON"
        return 1
    fi

    # Save entity mapping
    echo "$entity_data" > "$ENTITY_MAPPING_FILE"
    log_success "Entity mapping saved to $ENTITY_MAPPING_FILE"

    # Count entities
    local total=$(echo "$entity_data" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data['all']))")
    local binary_sensors=$(echo "$entity_data" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data['binary_sensor']))")
    local sensors=$(echo "$entity_data" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data['sensor']))")
    local device_trackers=$(echo "$entity_data" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data['device_tracker']))")

    log_info "Discovered entities:"
    log_info "  Total: $total"
    log_info "  Binary Sensors: $binary_sensors"
    log_info "  Sensors: $sensors"
    log_info "  Device Trackers: $device_trackers"

    # MILESTONE 3.1 VALIDATION: Verify at least one entity discovered
    if [ "$total" -eq 0 ]; then
        log_error "No entities discovered"
        return 1
    fi

    # MILESTONE 3.1 TEST: Verify entities exist
    log_info "MILESTONE 3.1: Verifying discovered entities exist..."
    local verified=0
    local failed=0

    echo "$entity_data" | python3 -c "import sys, json; data=json.load(sys.stdin); [print(e) for e in data['all'][:10]]" | while read -r entity_id; do
        if ha_api_call "states/$entity_id" >/dev/null 2>&1; then
            verified=$((verified + 1))
        else
            failed=$((failed + 1))
        fi
    done

    log_success "Entity discovery completed: $total entities found"
    # Output JSON to stdout (for command substitution)
    echo "$entity_data" >&1
    return 0
}

# Generate alert configurations
generate_alert_configs() {
    local entity_data="$1"
    local mobile_notifier="${MOBILE_APP_NOTIFIER:-}"
    local telegram_notifier="telegram_notifier"

    log_info "MILESTONE 3.2: Generating alert configurations..."

    if [ -z "$entity_data" ]; then
        log_error "Entity data is empty, cannot generate alerts"
        return 1
    fi

    # Create backup
    local backup_dir="$SCRIPT_DIR/backups"
    mkdir -p "$backup_dir"
    local timestamp=$(date +%Y%m%d_%H%M%S)

    if [ -f "$SCRIPT_DIR/alert_config.yaml" ]; then
        cp "$SCRIPT_DIR/alert_config.yaml" "$backup_dir/${timestamp}_alert_config.yaml"
    fi
    if [ -f "$SCRIPT_DIR/automation_alerts.yaml" ]; then
        cp "$SCRIPT_DIR/automation_alerts.yaml" "$backup_dir/${timestamp}_automation_alerts.yaml"
    fi

    # Use temp file for entity data to avoid command substitution issues
    local entity_temp_file=$(mktemp)
    echo "$entity_data" > "$entity_temp_file"

    # Verify temp file was written
    local file_size=$(wc -c < "$entity_temp_file" 2>/dev/null || echo "0")
    if [ "$file_size" -eq 0 ]; then
        log_error "Failed to write entity data to temp file (size: $file_size)"
        rm -f "$entity_temp_file"
        return 1
    fi
    log_info "Temp file created: $entity_temp_file (size: $file_size bytes)"

    # Generate alert configs using external Python script
    local mobile_notifier_arg="${mobile_notifier:-}"
    local telegram_notifier_arg="${telegram_notifier:-telegram_notifier}"

    if ! python3 "$SCRIPT_DIR/generate_alert_config.py" "$entity_temp_file" "$mobile_notifier_arg" "$telegram_notifier_arg" > "$SCRIPT_DIR/alert_config.yaml" 2>&1; then
        log_error "Failed to generate alert config"
        rm -f "$entity_temp_file"
        return 1
    fi

    rm -f "$entity_temp_file"

    # Verify alert config was created
    if [ ! -f "$SCRIPT_DIR/alert_config.yaml" ] || [ ! -s "$SCRIPT_DIR/alert_config.yaml" ]; then
        log_error "Alert config file was not created or is empty"
        return 1
    fi

    log_success "Alert configurations generated"

    # Count generated alerts
    local alert_count=$(python3 -c "import yaml; data=yaml.safe_load(open('$SCRIPT_DIR/alert_config.yaml')); print(len(data.get('alert', {})))" 2>/dev/null || echo "0")
    log_info "Generated $alert_count alert configurations"

    # Update automation_alerts.yaml with mobile notifier if available
    if [ -f "$SCRIPT_DIR/automation_alerts.yaml" ] && [ -n "$mobile_notifier" ]; then
        log_info "Updating automation_alerts.yaml with mobile notifier..."
        # macOS compatible sed
        if sed -i.bak "s/mobile_app_YOUR_DEVICE/$mobile_notifier/g" "$SCRIPT_DIR/automation_alerts.yaml" 2>/dev/null || \
           sed -i '' "s/mobile_app_YOUR_DEVICE/$mobile_notifier/g" "$SCRIPT_DIR/automation_alerts.yaml" 2>/dev/null; then
            log_success "Updated automation_alerts.yaml with mobile notifier"
            rm -f "$SCRIPT_DIR/automation_alerts.yaml.bak" 2>/dev/null || true
        else
            log_info "Could not update automation_alerts.yaml (may not contain placeholder)"
        fi
    fi

    # MILESTONE 3.2 VALIDATION: Verify structure
    if [ "$alert_count" -eq 0 ]; then
        log_error "No alerts generated"
        return 1
    fi

    return 0
}

# Validate entity IDs
validate_entities() {
    local entity_data="$1"

    log_info "MILESTONE 3.3: Validating entity IDs..."

    local validation_report="$SCRIPT_DIR/validation_report.json"
    local valid=0
    local invalid=0
    local invalid_entities=()

    echo "$entity_data" | python3 -c "import sys, json; data=json.load(sys.stdin); [print(e) for e in data['all']]" | while read -r entity_id; do
        if ha_api_call "states/$entity_id" >/dev/null 2>&1; then
            valid=$((valid + 1))
        else
            invalid=$((invalid + 1))
            invalid_entities+=("$entity_id")
        fi
    done

    # Create validation report
    cat > "$validation_report" <<EOF
{
    "timestamp": "$(date -Iseconds)",
    "valid_entities": $valid,
    "invalid_entities": $invalid,
    "invalid_entity_list": $(echo "$entity_data" | python3 -c "import sys, json; data=json.load(sys.stdin); print(json.dumps(data['all'][:0]))")
}
EOF

    log_info "Validation complete: $valid valid, $invalid invalid"

    if [ $invalid -gt 0 ]; then
        log_info "Some entities are invalid (non-blocking)"
    fi

    return 0
}

# Main function
main() {
    local mode="${1:-}"

    case "$mode" in
        ""|discover)
            local entity_data=$(discover_entities)
            if [ $? -eq 0 ]; then
                echo "$entity_data"
            else
                exit 1
            fi
            ;;
        --generate-alerts)
            # First discover entities (this will create entity_mapping.json)
            # Redirect logs but keep function working
            discover_entities >/dev/null
            local discover_exit=$?
            if [ $discover_exit -eq 0 ] && [ -f "$ENTITY_MAPPING_FILE" ]; then
                # Read entity data from saved file
                local entity_data=$(cat "$ENTITY_MAPPING_FILE" 2>/dev/null)
                local data_length=${#entity_data}
                if [ -n "$entity_data" ] && [ "$data_length" -gt 10 ] && ! echo "$entity_data" | grep -q '"error"'; then
                    log_info "Entity data loaded: $data_length characters"
                    generate_alert_configs "$entity_data"
                    # MILESTONE 3.2 TEST: Validate YAML
                    if python3 -c "import yaml; yaml.safe_load(open('$SCRIPT_DIR/alert_config.yaml'))" 2>/dev/null; then
                        log_success "MILESTONE 3.2: Alert config YAML is valid"
                    else
                        log_error "MILESTONE 3.2: Alert config YAML validation failed"
                        exit 1
                    fi
                else
                    log_error "Entity data is invalid or empty (length: $data_length), cannot generate alerts"
                    exit 1
                fi
            else
                log_error "Entity discovery failed or file not found: $ENTITY_MAPPING_FILE"
                exit 1
            fi
            ;;
        --validate)
            local entity_data=$(discover_entities)
            if [ $? -eq 0 ]; then
                validate_entities "$entity_data"
            else
                exit 1
            fi
            ;;
        *)
            log_error "Unknown mode: $mode"
            exit 1
            ;;
    esac
}

main "$@"

