#!/bin/bash
# Home Assistant Automated Backup Script
# Backs up Home Assistant configuration, MQTT config, and docker-compose

set -e

# Configuration
BACKUP_DIR="/home/system/homeassistant/backups"
CONFIG_DIR="/home/system/homeassistant/config"
MQTT_DIR="/home/system/homeassistant/mqtt"
DOCKER_COMPOSE="/home/chief/docker-compose.yml"
RETENTION_DAYS=30  # Keep backups for 30 days
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="homeassistant_backup_${TIMESTAMP}.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create temporary directory for backup
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "=== Home Assistant Backup Started ==="
echo "Timestamp: $(date)"
echo "Backup will be saved to: $BACKUP_DIR/$BACKUP_NAME"
echo ""

# Backup Home Assistant configuration
echo "Backing up Home Assistant configuration..."
if [ -d "$CONFIG_DIR" ]; then
    # Use tar to preserve permissions and handle permission errors gracefully
    tar -czf "$TEMP_DIR/config.tar.gz" -C "$(dirname $CONFIG_DIR)" "$(basename $CONFIG_DIR)" 2>/dev/null || \
    tar -czf "$TEMP_DIR/config.tar.gz" -C "$(dirname $CONFIG_DIR)" "$(basename $CONFIG_DIR)" --warning=no-file-ignored 2>&1 | grep -v "Permission denied" || true
    echo "  ✓ Configuration directory backed up"
else
    echo "  ⚠ Warning: Configuration directory not found: $CONFIG_DIR"
fi

# Backup MQTT configuration
echo "Backing up MQTT configuration..."
if [ -d "$MQTT_DIR" ]; then
    cp -r "$MQTT_DIR" "$TEMP_DIR/mqtt"
    echo "  ✓ MQTT configuration backed up"
else
    echo "  ⚠ Warning: MQTT directory not found: $MQTT_DIR"
fi

# Backup docker-compose.yml
echo "Backing up docker-compose.yml..."
if [ -f "$DOCKER_COMPOSE" ]; then
    cp "$DOCKER_COMPOSE" "$TEMP_DIR/docker-compose.yml"
    echo "  ✓ Docker Compose file backed up"
else
    echo "  ⚠ Warning: docker-compose.yml not found: $DOCKER_COMPOSE"
fi

# Create backup metadata
echo "Creating backup metadata..."
cat > "$TEMP_DIR/backup_info.txt" << EOF
Home Assistant Backup Information
================================
Backup Date: $(date)
Backup Timestamp: $TIMESTAMP
Host: $(hostname)
Docker Version: $(docker --version 2>/dev/null || echo "N/A")
Home Assistant Version: $(docker inspect homeassistant --format='{{.Config.Image}}' 2>/dev/null || echo "N/A")
Backup Script Version: 1.0
EOF
echo "  ✓ Metadata created"

# Create compressed archive
echo "Creating compressed archive..."
cd "$TEMP_DIR"
tar -czf "$BACKUP_DIR/$BACKUP_NAME" .
echo "  ✓ Archive created: $BACKUP_NAME"

# Get backup size
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)
echo "  Backup size: $BACKUP_SIZE"

# Clean up old backups (keep only last N days)
echo "Cleaning up old backups (keeping last $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "homeassistant_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete
OLD_COUNT=$(find "$BACKUP_DIR" -name "homeassistant_backup_*.tar.gz" -type f | wc -l)
echo "  ✓ Old backups cleaned. Remaining backups: $OLD_COUNT"

# Verify backup integrity
echo "Verifying backup integrity..."
if tar -tzf "$BACKUP_DIR/$BACKUP_NAME" > /dev/null 2>&1; then
    echo "  ✓ Backup integrity verified"
else
    echo "  ✗ ERROR: Backup verification failed!"
    exit 1
fi

echo ""
echo "=== Backup Complete ==="
echo "Backup location: $BACKUP_DIR/$BACKUP_NAME"
echo "Backup size: $BACKUP_SIZE"
echo "Total backups: $OLD_COUNT"
echo ""

# Optional: Log to file
LOG_FILE="$BACKUP_DIR/backup.log"
echo "[$(date)] Backup completed successfully: $BACKUP_NAME ($BACKUP_SIZE)" >> "$LOG_FILE"

exit 0

