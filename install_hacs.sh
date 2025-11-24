#!/bin/bash
# Install HACS (Home Assistant Community Store)

set -e

HA_CONFIG_DIR="/home/system/homeassistant/config"
CONTAINER_NAME="homeassistant"

echo "📦 Installing HACS..."
echo ""

# Check if HACS is already installed
echo "🔍 Checking if HACS is already installed..."
hacs_check=$(docker exec $CONTAINER_NAME bash -c "test -d /config/custom_components/hacs && echo 'yes' || echo 'no'" 2>/dev/null || echo "no")

if [ "$hacs_check" = "yes" ]; then
    echo "  ✅ HACS is already installed"
    exit 0
fi

# Install unzip if needed
echo "📦 Installing unzip (required for HACS)..."
docker exec $CONTAINER_NAME bash -c "apt-get update && apt-get install -y unzip" 2>/dev/null || {
    echo "  ⚠️  Could not install unzip via container"
    echo "  Installing via SSH..."
    ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 "sudo apt-get update && sudo apt-get install -y unzip" 2>/dev/null || {
        echo "  ⚠️  Could not install unzip. Please install manually: sudo apt-get install unzip"
    }
}

# Install HACS
echo ""
echo "📥 Downloading and installing HACS..."
# Config directory is root-owned, need sudo
ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 "sudo mkdir -p $HA_CONFIG_DIR/custom_components && cd $HA_CONFIG_DIR && sudo wget -O - https://get.hacs.xyz | sudo bash -" 2>/dev/null || {
    echo "  ❌ HACS installation failed"
    echo ""
    echo "  Manual installation steps:"
    echo "  1. SSH to server: ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100"
    echo "  2. Run: sudo mkdir -p $HA_CONFIG_DIR/custom_components && cd $HA_CONFIG_DIR && sudo wget -O - https://get.hacs.xyz | sudo bash -"
    echo "  3. Restart Home Assistant: docker restart homeassistant"
    exit 1
}

# Verify installation
echo ""
echo "✅ Verifying HACS installation..."
if docker exec $CONTAINER_NAME bash -c "test -d /config/custom_components/hacs && echo 'yes' || echo 'no'" 2>/dev/null | grep -q "yes"; then
    echo "  ✅ HACS installed successfully"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Restart Home Assistant: docker restart homeassistant"
    echo "  2. Go to http://10.11.12.100:8123"
    echo "  3. HACS should appear in the sidebar"
    echo "  4. Complete HACS setup wizard if prompted"
else
    echo "  ⚠️  HACS installation may have failed. Check logs:"
    echo "     docker logs homeassistant | grep -i hacs"
fi

