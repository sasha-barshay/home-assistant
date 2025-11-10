#!/bin/bash
# Autonomous Telegram Bot Setup Script
# Reads credentials from environment variables, validates, and updates configuration files
# Bot name: NafanyaBot

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$SCRIPT_DIR/deployment.log"

# Load HA credentials from .env
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

# Logging function
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

# Mask token in output
mask_token() {
    local token="$1"
    if [ ${#token} -gt 10 ]; then
        echo "${token:0:10}..."
    else
        echo "***"
    fi
}

# Validate bot token format
validate_token_format() {
    local token="$1"
    if [[ ! "$token" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
        log_error "Invalid bot token format"
        return 1
    fi
    return 0
}

# Test bot token via Telegram API
test_bot_token() {
    local token="$1"
    log_info "Testing bot token (masked: $(mask_token "$token"))..."
    
    local response=$(curl -s "https://api.telegram.org/bot${token}/getMe" 2>/dev/null)
    
    if echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if data.get('ok') else 1)" 2>/dev/null; then
        local bot_name=$(echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result']['first_name'])" 2>/dev/null)
        local bot_username=$(echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result']['username'])" 2>/dev/null)
        
        log_success "Bot token is valid"
        log_info "Bot Name: $bot_name"
        log_info "Bot Username: @$bot_username"
        
        # Verify bot name is NafanyaBot
        if [ "$bot_name" != "NafanyaBot" ]; then
            log_error "Bot name mismatch. Expected 'NafanyaBot', got '$bot_name'"
            return 1
        fi
        
        return 0
    else
        log_error "Bot token validation failed"
        echo "$response" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Send test message
send_test_message() {
    local token="$1"
    local user_id="$2"
    
    log_info "Sending test message to Telegram..."
    
    local message="🧪 Test message from Home Assistant alerting setup. Bot name: NafanyaBot"
    local response=$(curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d "chat_id=${user_id}" \
        -d "text=${message}" 2>/dev/null)
    
    if echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if data.get('ok') else 1)" 2>/dev/null; then
        log_success "Test message sent successfully"
        return 0
    else
        log_error "Failed to send test message"
        echo "$response" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Update notification_config.yaml
update_notification_config() {
    local bot_token="$1"
    local user_id="$2"
    local mobile_notifier="${3:-}"
    
    local config_file="$SCRIPT_DIR/notification_config.yaml"
    local backup_file="$SCRIPT_DIR/backups/$(date +%Y%m%d_%H%M%S)_notification_config.yaml"
    
    # Create backup
    if [ -f "$config_file" ]; then
        mkdir -p "$SCRIPT_DIR/backups"
        cp "$config_file" "$backup_file"
        log_info "Backup created: $backup_file"
    fi
    
    # Update configuration
    log_info "Updating notification_config.yaml..."
    
    # Create updated config
    cat > "$config_file" <<EOF
# Home Assistant Notification Configuration
# Mobile App + Telegram Bot Setup (NafanyaBot)
# Location: /home/system/homeassistant/config/notification_config.yaml
# Include in configuration.yaml: notification_config: !include notification_config.yaml

# ============================================================================
# TELEGRAM BOT CONFIGURATION (NafanyaBot)
# ============================================================================
telegram_bot:
  - platform: polling
    api_key: "${bot_token}"
    allowed_chat_ids:
      - ${user_id}

# ============================================================================
# TELEGRAM NOTIFIER
# ============================================================================
notify:
  - name: telegram_notifier
    platform: telegram
    chat_id: ${user_id}

EOF

    # Add multi-channel group if mobile notifier is available
    if [ -n "$mobile_notifier" ]; then
        cat >> "$config_file" <<EOF
# ============================================================================
# MULTI-CHANNEL NOTIFICATION GROUP
# ============================================================================
notify:
  - name: multi_channel_alerts
    platform: group
    services:
      - service: ${mobile_notifier}
      - service: telegram_notifier

EOF
    fi
    
    log_success "notification_config.yaml updated"
}

# Validate YAML syntax
validate_yaml() {
    local file="$1"
    log_info "Validating YAML syntax for $file..."
    
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        log_success "YAML syntax valid: $file"
        return 0
    else
        log_error "YAML syntax error in $file"
        return 1
    fi
}

# Main function
main() {
    local update_configs="${1:-}"
    
    log_info "=== Autonomous Telegram Bot Setup ==="
    
    # Check environment variables
    if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
        log_error "TELEGRAM_BOT_TOKEN environment variable not set"
        exit 1
    fi
    
    if [ -z "${TELEGRAM_USER_ID:-}" ]; then
        log_error "TELEGRAM_USER_ID environment variable not set"
        exit 1
    fi
    
    # MILESTONE 1.1 VALIDATION: Validate token format
    log_info "MILESTONE 1.1: Validating bot token format..."
    if ! validate_token_format "$TELEGRAM_BOT_TOKEN"; then
        exit 1
    fi
    
    # MILESTONE 1.1 TEST: Test bot token
    log_info "MILESTONE 1.1: Testing bot token via Telegram API..."
    if ! test_bot_token "$TELEGRAM_BOT_TOKEN"; then
        exit 1
    fi
    
    # Update configuration if requested
    if [ "$update_configs" = "--update-configs" ]; then
        local mobile_notifier="${MOBILE_APP_NOTIFIER:-}"
        update_notification_config "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_USER_ID" "$mobile_notifier"
        
        # MILESTONE 1.3 VALIDATION: Validate YAML
        log_info "MILESTONE 1.3: Validating YAML syntax..."
        if ! validate_yaml "$SCRIPT_DIR/notification_config.yaml"; then
            log_error "YAML validation failed, restoring backup..."
            local backup_file=$(ls -t "$SCRIPT_DIR/backups/"*"_notification_config.yaml" 2>/dev/null | head -1)
            if [ -n "$backup_file" ] && [ -f "$backup_file" ]; then
                cp "$backup_file" "$SCRIPT_DIR/notification_config.yaml"
            fi
            exit 1
        fi
    fi
    
    # MILESTONE 1.1 POST-UPDATE TEST: Send test message
    log_info "MILESTONE 1.1: Sending test message..."
    if ! send_test_message "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_USER_ID"; then
        log_error "Test message failed, but configuration is valid"
        # Don't exit - configuration is correct, just message delivery issue
    fi
    
    log_success "Telegram bot setup completed successfully"
    return 0
}

main "$@"

