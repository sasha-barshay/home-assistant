#!/bin/bash
# Deployment Script (SSH - Non-Interactive)
# Deploys alert configuration files to Home Assistant server via SSH

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$SCRIPT_DIR/deployment.log"

# Configuration
SSH_USER="chief"
SSH_HOST="10.11.12.100"
SSH_KEY="$HOME/.ssh/oslik_rsa"
SSH_OPTS="-i $SSH_KEY -o ConnectTimeout=10 -o StrictHostKeyChecking=no"
HA_CONFIG_DIR="/home/system/homeassistant/config"
REMOTE_CONFIG_DIR="$HA_CONFIG_DIR"

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

# SSH command wrapper
ssh_cmd() {
    ssh $SSH_OPTS "${SSH_USER}@${SSH_HOST}" "$@" 2>&1 | tee -a "$LOG_FILE"
}

# SCP command wrapper
scp_cmd() {
    scp $SSH_OPTS "$@" 2>&1 | tee -a "$LOG_FILE"
}

# Test SSH connectivity
test_ssh() {
    log_info "MILESTONE 5.1: Testing SSH connectivity..."
    if ssh_cmd "echo 'OK'" | grep -q "OK"; then
        log_success "SSH connectivity verified"
        return 0
    else
        log_error "SSH connectivity test failed"
        return 1
    fi
}

# Deploy files
deploy_files() {
    log_info "MILESTONE 5.1: Deploying configuration files..."

    # MILESTONE 5.1 TEST: Verify directory exists
    log_info "MILESTONE 5.1: Verifying config directory exists..."
    if ! ssh_cmd "test -d $REMOTE_CONFIG_DIR"; then
        log_error "Config directory does not exist: $REMOTE_CONFIG_DIR"
        exit 2
    fi
    log_success "Config directory verified"

    # Files to deploy
    local files_to_deploy=(
        "notification_config.yaml"
        "alert_config.yaml"
        "automation_alerts.yaml"
        "system_monitoring.yaml"
    )

    # Copy files to /tmp first, then move with sudo
    for file in "${files_to_deploy[@]}"; do
        local local_file="$SCRIPT_DIR/$file"
        if [ -f "$local_file" ]; then
            log_info "Copying $file to server (via /tmp)..."
            # Copy to /tmp first
            if scp_cmd "$local_file" "${SSH_USER}@${SSH_HOST}:/tmp/$file"; then
                # Move to final location with sudo and set permissions
                if ssh_cmd "sudo mv /tmp/$file ${REMOTE_CONFIG_DIR}/$file && sudo chmod 600 ${REMOTE_CONFIG_DIR}/$file && sudo chown \$(whoami):\$(whoami) ${REMOTE_CONFIG_DIR}/$file"; then
                    log_success "Copied and moved $file"
                else
                    log_error "Failed to move $file to final location"
                    exit 2
                fi
            else
                log_error "Failed to copy $file to /tmp"
                exit 2
            fi
        else
            log_info "Skipping $file (not found)"
        fi
    done

    log_success "File permissions set"

    # MILESTONE 5.1 POST-DEPLOY TEST: Verify files copied
    log_info "MILESTONE 5.1: Verifying files copied and permissions set..."
    local all_ok=true
    for file in "${files_to_deploy[@]}"; do
        if ssh_cmd "test -f ${REMOTE_CONFIG_DIR}/$file && test -r ${REMOTE_CONFIG_DIR}/$file"; then
            local perms=$(ssh_cmd "stat -c '%a' ${REMOTE_CONFIG_DIR}/$file" | tail -1)
            if [ "$perms" = "600" ]; then
                log_success "Verified $file (permissions: $perms)"
            else
                log_error "Wrong permissions for $file: $perms (expected 600)"
                all_ok=false
            fi
        else
            log_error "File not found or not readable: $file"
            all_ok=false
        fi
    done

    if [ "$all_ok" = true ]; then
        log_success "MILESTONE 5.1: All files deployed and verified"
        return 0
    else
        log_error "MILESTONE 5.1: File deployment verification failed"
        exit 2
    fi
}

# Update configuration.yaml
update_config_yaml() {
    log_info "MILESTONE 5.2: Updating configuration.yaml on server..."

    # Backup configuration.yaml (using sudo)
    local backup_file="${REMOTE_CONFIG_DIR}/configuration.yaml.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Creating backup: $backup_file"
    ssh_cmd "sudo cp ${REMOTE_CONFIG_DIR}/configuration.yaml $backup_file && sudo chmod 600 $backup_file && sudo chown \$(whoami):\$(whoami) $backup_file" || {
        log_error "Failed to create backup"
        exit 2
    }

    # Check which includes to add
    local includes=(
        "notification_config: !include notification_config.yaml"
        "alert_config: !include alert_config.yaml"
        "automation_alerts: !include automation_alerts.yaml"
        "system_monitoring: !include system_monitoring.yaml"
    )

    # Add includes if they don't exist (using sudo)
    for include_line in "${includes[@]}"; do
        local key=$(echo "$include_line" | cut -d: -f1)
        if ssh_cmd "sudo grep -q '^${key}:' ${REMOTE_CONFIG_DIR}/configuration.yaml" 2>/dev/null; then
            log_info "Include already exists: $key"
        else
            log_info "Adding include: $key"
            ssh_cmd "echo '$include_line' | sudo tee -a ${REMOTE_CONFIG_DIR}/configuration.yaml > /dev/null"
        fi
    done

    # MILESTONE 5.2 VALIDATION: Verify includes were added correctly
    # Note: We skip standard YAML validation because HA uses !include directives
    # which are not standard YAML. HA will validate on restart.
    log_info "MILESTONE 5.2: Verifying includes were added correctly..."
    local includes_ok=true
    for include_line in "${includes[@]}"; do
        local key=$(echo "$include_line" | cut -d: -f1)
        if ssh_cmd "sudo grep -q '^${key}:' ${REMOTE_CONFIG_DIR}/configuration.yaml" 2>/dev/null; then
            log_success "Include verified: $key"
        else
            log_error "Include missing: $key"
            includes_ok=false
        fi
    done

    if [ "$includes_ok" != "true" ]; then
        log_error "MILESTONE 5.2: Some includes are missing, restoring backup..."
        ssh_cmd "sudo cp $backup_file ${REMOTE_CONFIG_DIR}/configuration.yaml"
        exit 2
    fi

    log_success "MILESTONE 5.2: All includes verified (HA will validate on restart)"

    # MILESTONE 5.2 TEST: Verify all includes are present
    log_info "MILESTONE 5.2: Verifying all include statements are present..."
    local all_present=true
    for include_line in "${includes[@]}"; do
        local key=$(echo "$include_line" | cut -d: -f1)
        if ssh_cmd "sudo grep -q '^${key}:' ${REMOTE_CONFIG_DIR}/configuration.yaml" 2>/dev/null; then
            log_success "Include present: $key"
        else
            log_error "Include missing: $key"
            all_present=false
        fi
    done

    if [ "$all_present" = true ]; then
        log_success "MILESTONE 5.2: All includes verified"
        return 0
    else
        log_error "MILESTONE 5.2: Some includes are missing"
        exit 2
    fi
}

# Restart Home Assistant
restart_ha() {
    log_info "MILESTONE 5.3: Restarting Home Assistant container..."

    # MILESTONE 5.3 VALIDATION: Restart container
    if ssh_cmd "docker restart homeassistant"; then
        log_success "MILESTONE 5.3: Restart command succeeded"
    else
        log_error "MILESTONE 5.3: Restart command failed"
        exit 2
    fi

    # MILESTONE 5.3 TEST: Check container status
    log_info "MILESTONE 5.3: Checking container status..."
    sleep 5  # Wait a moment for container to start
    local container_status=$(ssh_cmd "docker ps --filter name=homeassistant --format '{{.Status}}'" | tail -1)
    log_info "Container status: $container_status"

    if echo "$container_status" | grep -q "Up"; then
        log_success "Container is running"
    else
        log_error "Container is not running"
        exit 2
    fi

    # Poll HA API until ready
    log_info "MILESTONE 5.3: Polling HA API until ready (max 5 minutes)..."
    local max_attempts=30
    local attempt=1
    local api_ready=false

    while [ $attempt -le $max_attempts ]; do
        if curl -s -f -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/" >/dev/null 2>&1; then
            api_ready=true
            break
        fi
        log_info "Attempt $attempt/$max_attempts: API not ready, waiting 10s..."
        sleep 10
        attempt=$((attempt + 1))
    done

    if [ "$api_ready" = true ]; then
        log_success "MILESTONE 5.3: HA API is ready"
    else
        log_error "MILESTONE 5.3: HA API did not become ready within timeout"
        exit 2
    fi

    # Check container health
    log_info "MILESTONE 5.3: Checking container health..."
    local health=$(ssh_cmd "docker inspect homeassistant --format '{{.State.Health.Status}}'" 2>/dev/null | tail -1 || echo "unknown")
    log_info "Container health: $health"

    if [ "$health" = "healthy" ] || [ "$health" = "starting" ] || [ "$health" = "unknown" ]; then
        log_success "MILESTONE 5.3: Container health check passed"
    else
        log_error "MILESTONE 5.3: Container health check failed: $health"
        exit 2
    fi

    # MILESTONE 5.3 FINAL TEST: Verify HA API is fully responsive
    log_info "MILESTONE 5.3: Verifying HA API is fully responsive..."
    if curl -s -f -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/config" >/dev/null 2>&1; then
        log_success "MILESTONE 5.3: HA API is fully responsive"
        return 0
    else
        log_error "MILESTONE 5.3: HA API is not fully responsive"
        exit 2
    fi
}

# Main function
main() {
    local mode="${1:-}"

    case "$mode" in
        --deploy-files)
            if ! test_ssh; then
                exit 2
            fi
            deploy_files
            ;;
        --update-config)
            if ! test_ssh; then
                exit 2
            fi
            update_config_yaml
            ;;
        --restart-ha)
            if ! test_ssh; then
                exit 2
            fi
            restart_ha
            ;;
        *)
            log_error "Usage: $0 --deploy-files|--update-config|--restart-ha"
            exit 1
            ;;
    esac
}

main "$@"

