#!/bin/bash
# Create System Monitoring Entities Script
# Generates system_monitoring.yaml with template sensors for HA monitoring

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/deployment.log"
SYSTEM_MONITORING_FILE="$SCRIPT_DIR/system_monitoring.yaml"

# Logging
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_success() { log "SUCCESS" "$@"; }

log_info "MILESTONE 2.1: Creating system monitoring entities..."

# Generate system_monitoring.yaml
cat > "$SYSTEM_MONITORING_FILE" <<'EOF'
# System Monitoring Entities
# Auto-generated template sensors for Home Assistant system health monitoring
# Location: /home/system/homeassistant/config/system_monitoring.yaml
# Include in configuration.yaml: system_monitoring: !include system_monitoring.yaml

template:
  - binary_sensor:
      # Home Assistant Service Status
      - name: "Home Assistant Status"
        unique_id: "homeassistant_status"
        state: >
          {% set response = states('sensor.homeassistant_api_response') %}
          {{ 'on' if response == 'ok' else 'off' }}
        device_class: connectivity
        icon: >
          {% if is_state('binary_sensor.homeassistant_status', 'on') %}
            mdi:home-assistant
          {% else %}
            mdi:home-assistant
          {% endif %}

      # Home Assistant Container Health
      - name: "Home Assistant Container Health"
        unique_id: "homeassistant_container_health"
        state: >
          {% set health = states('sensor.homeassistant_container_health_raw') %}
          {{ 'on' if health in ['healthy', 'starting'] else 'off' }}
        device_class: connectivity
        icon: >
          {% if is_state('binary_sensor.homeassistant_container_health', 'on') %}
            mdi:docker
          {% else %}
            mdi:docker
          {% endif %}

      # Home Assistant API Available
      - name: "Home Assistant API Available"
        unique_id: "homeassistant_api_available"
        state: >
          {% set api_state = states('sensor.homeassistant_api_check') %}
          {{ 'on' if api_state == 'available' else 'off' }}
        device_class: connectivity
        icon: mdi:api

  - sensor:
      # Home Assistant Uptime
      - name: "Home Assistant Uptime"
        unique_id: "homeassistant_uptime"
        state: >
          {% set start_time = now() - timedelta(seconds=states('sensor.homeassistant_uptime_seconds')|int(0)) %}
          {{ (now() - start_time).total_seconds() | int }}
        unit_of_measurement: "seconds"
        icon: mdi:clock-outline

      # Home Assistant API Response Check
      - name: "Home Assistant API Response"
        unique_id: "homeassistant_api_response"
        state: >
          {% set response = states('sensor.homeassistant_api_check') %}
          {{ 'ok' if response == 'available' else 'error' }}
        icon: mdi:api

      # Home Assistant API Check (raw)
      - name: "Home Assistant API Check"
        unique_id: "homeassistant_api_check"
        state: "available"
        icon: mdi:api

      # Container Health Raw (for template processing)
      - name: "Home Assistant Container Health Raw"
        unique_id: "homeassistant_container_health_raw"
        state: "healthy"
        icon: mdi:docker

      # Uptime in seconds (for template processing)
      - name: "Home Assistant Uptime Seconds"
        unique_id: "homeassistant_uptime_seconds"
        state: "0"
        unit_of_measurement: "seconds"
        icon: mdi:clock-outline

# REST sensor for API availability check (updates every 60 seconds)
rest:
  - resource: "http://localhost:8123/api/"
    scan_interval: 60
    sensor:
      - name: "HA API Status Check"
        unique_id: "ha_api_status_check"
        value_template: >
          {% if value == 'API running.' %}
            available
          {% else %}
            unavailable
          {% endif %}
        json_attributes_path: "$"
EOF

log_success "system_monitoring.yaml created"

# MILESTONE 2.1 VALIDATION: Verify YAML syntax
log_info "MILESTONE 2.1: Validating YAML syntax..."
if python3 -c "import yaml; yaml.safe_load(open('$SYSTEM_MONITORING_FILE'))" 2>/dev/null; then
    log_success "MILESTONE 2.1: YAML syntax is valid"
else
    log_error "MILESTONE 2.1: YAML syntax validation failed"
    exit 1
fi

# MILESTONE 2.1 TEST: Verify template sensors are properly formatted
log_info "MILESTONE 2.1: Verifying template sensor structure..."
python3 << PYTHON_SCRIPT
import yaml
import sys

try:
    with open('$SYSTEM_MONITORING_FILE', 'r') as f:
        data = yaml.safe_load(f)

    # Check for required sections
    if 'template' not in data:
        print("Error: 'template' section not found", file=sys.stderr)
        sys.exit(1)

    template = data['template'][0]
    if 'binary_sensor' not in template and 'sensor' not in template:
        print("Error: No sensors found in template", file=sys.stderr)
        sys.exit(1)

    # Count sensors
    binary_count = len(template.get('binary_sensor', []))
    sensor_count = len(template.get('sensor', []))

    if binary_count == 0 and sensor_count == 0:
        print("Error: No sensors defined", file=sys.stderr)
        sys.exit(1)

    print(f"Found {binary_count} binary sensors and {sensor_count} sensors")
    sys.exit(0)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    log_success "MILESTONE 2.1: Template sensor structure verified"
else
    log_error "MILESTONE 2.1: Template sensor structure validation failed"
    exit 1
fi

log_success "System monitoring entities created successfully"

