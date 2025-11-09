#!/bin/bash
# Home Assistant Restore Script
# Restores Home Assistant from a backup archive

set -e

BACKUP_DIR="/home/system/homeassistant/backups"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_filename>"
    echo ""
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | awk '{print $9, "(" $5 ")"}' || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    # Try relative to backup directory
    if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
        echo "Error: Backup file not found: $BACKUP_FILE"
        exit 1
    else
        BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
    fi
fi

echo "=== Home Assistant Restore ==="
echo "Backup file: $BACKUP_FILE"
echo ""

# Verify backup integrity
echo "Verifying backup integrity..."
if ! tar -tzf "$BACKUP_FILE" > /dev/null 2>&1; then
    echo "Error: Backup file is corrupted or invalid"
    exit 1
fi
echo "  ✓ Backup integrity verified"
echo ""

# Warning
echo "⚠️  WARNING: This will restore Home Assistant configuration."
echo "⚠️  This will overwrite existing configuration files."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Stop Home Assistant container
echo "Stopping Home Assistant container..."
docker stop homeassistant 2>/dev/null || echo "  Container not running"
echo "  ✓ Container stopped"
echo ""

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Extract backup
echo "Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
echo "  ✓ Backup extracted"
echo ""

# Restore configuration
echo "Restoring Home Assistant configuration..."
if [ -f "$TEMP_DIR/config.tar.gz" ]; then
    # Stop container first
    docker stop homeassistant 2>/dev/null || true
    # Restore config
    sudo rm -rf /home/system/homeassistant/config/*
    sudo tar -xzf "$TEMP_DIR/config.tar.gz" -C /home/system/homeassistant/
    sudo chown -R root:root /home/system/homeassistant/config/.storage 2>/dev/null || true
    echo "  ✓ Configuration restored"
else
    echo "  ⚠ Warning: config.tar.gz not found in backup"
fi

# Restore MQTT configuration
echo "Restoring MQTT configuration..."
if [ -d "$TEMP_DIR/mqtt" ]; then
    sudo rm -rf /home/system/homeassistant/mqtt/*
    sudo cp -r "$TEMP_DIR/mqtt"/* /home/system/homeassistant/mqtt/
    sudo chown -R 1883:1883 /home/system/homeassistant/mqtt/config 2>/dev/null || true
    sudo chmod 600 /home/system/homeassistant/mqtt/config/passwd 2>/dev/null || true
    echo "  ✓ MQTT configuration restored"
    docker restart mosquitto
else
    echo "  ⚠ Warning: mqtt directory not found in backup"
fi

# Restore docker-compose.yml
echo "Restoring docker-compose.yml..."
if [ -f "$TEMP_DIR/docker-compose.yml" ]; then
    cp "$TEMP_DIR/docker-compose.yml" /home/chief/docker-compose.yml
    echo "  ✓ docker-compose.yml restored"
else
    echo "  ⚠ Warning: docker-compose.yml not found in backup"
fi

# Start Home Assistant
echo "Starting Home Assistant container..."
cd /home/chief
docker compose up -d homeassistant
echo "  ✓ Container started"
echo ""

echo "=== Restore Complete ==="
echo "Home Assistant is starting. It may take a few minutes to initialize."
echo "Check status: docker ps | grep homeassistant"
echo "View logs: docker logs homeassistant"

