#!/bin/bash
# Deploy Water Leak Automation Configuration to Home Assistant Server
# This script copies the water_leak_automations.yaml file to the server

set -e

# Configuration
SERVER="10.11.12.100"
SERVER_USER="chief"
SSH_KEY="$HOME/.ssh/oslik_rsa"
REMOTE_CONFIG_DIR="/home/system/homeassistant/config"
LOCAL_FILE="water_leak_automations.yaml"
REMOTE_FILE="$REMOTE_CONFIG_DIR/water_leak_automations.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Deploying Water Leak Automations to Home Assistant"
echo "=================================================="
echo ""

# Check if local file exists
if [ ! -f "$LOCAL_FILE" ]; then
    echo -e "${RED}❌ Error: $LOCAL_FILE not found${NC}"
    echo "Please run this script from the repository root directory"
    exit 1
fi

# Check SSH key
if [ ! -f "$SSH_KEY" ]; then
    echo -e "${YELLOW}⚠️  Warning: SSH key not found at $SSH_KEY${NC}"
    echo "Attempting to use default SSH key..."
    SSH_KEY_OPT=""
else
    SSH_KEY_OPT="-i $SSH_KEY"
fi

# Test server connectivity
echo "📡 Testing server connectivity..."
if ! ping -c 1 -W 2 "$SERVER" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Cannot reach server at $SERVER${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Server is reachable${NC}"

# Copy file to server
echo ""
echo "📤 Copying $LOCAL_FILE to server..."
if ssh $SSH_KEY_OPT "${SERVER_USER}@${SERVER}" "sudo mkdir -p $REMOTE_CONFIG_DIR" 2>/dev/null; then
    if scp $SSH_KEY_OPT "$LOCAL_FILE" "${SERVER_USER}@${SERVER}:/tmp/" 2>/dev/null; then
        if ssh $SSH_KEY_OPT "${SERVER_USER}@${SERVER}" "sudo mv /tmp/$LOCAL_FILE $REMOTE_FILE && sudo chown root:root $REMOTE_FILE && sudo chmod 644 $REMOTE_FILE" 2>/dev/null; then
            echo -e "${GREEN}✅ File copied successfully${NC}"
        else
            echo -e "${RED}❌ Error: Failed to move file to final location${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Error: Failed to copy file to server${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Error: Failed to create directory on server${NC}"
    exit 1
fi

# Verify file on server
echo ""
echo "🔍 Verifying file on server..."
if ssh $SSH_KEY_OPT "${SERVER_USER}@${SERVER}" "sudo test -f $REMOTE_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ File verified on server${NC}"
    
    # Show file info
    FILE_SIZE=$(ssh $SSH_KEY_OPT "${SERVER_USER}@${SERVER}" "sudo stat -f%z $REMOTE_FILE 2>/dev/null || sudo stat -c%s $REMOTE_FILE 2>/dev/null")
    echo "   File size: $FILE_SIZE bytes"
else
    echo -e "${RED}❌ Error: File not found on server${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Add to configuration.yaml:"
echo "   automation: !include water_leak_automations.yaml"
echo ""
echo "2. Restart Home Assistant:"
echo "   - Via UI: Settings → System → Restart"
echo "   - Via Docker: docker restart homeassistant"
echo ""
echo "3. Verify automations in Home Assistant UI:"
echo "   Settings → Automations & Scenes"
echo ""
echo "4. Test water leak detection:"
echo "   Touch sensor probes with damp cloth"
echo "   Check Telegram for alert"

