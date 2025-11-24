#!/bin/bash
# Install LocalTuya integration

set -e

HA_CONFIG_DIR="/home/system/homeassistant/config"
CONTAINER_NAME="homeassistant"
LOCALTUYA_REPO="https://github.com/rospogrigio/localtuya.git"
LOCALTUYA_PATH="$HA_CONFIG_DIR/custom_components/localtuya"

echo "📦 Installing LocalTuya..."
echo ""

# Check if LocalTuya is already installed
echo "🔍 Checking if LocalTuya is already installed..."
localtuya_check=$(ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 "test -d $LOCALTUYA_PATH && echo 'yes' || echo 'no'" 2>/dev/null || echo "no")

if [ "$localtuya_check" = "yes" ]; then
    echo "  ✅ LocalTuya is already installed"
    echo "  Location: $LOCALTUYA_PATH"
    exit 0
fi

# Check if HACS is installed
echo "🔍 Checking HACS installation..."
hacs_check=$(ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 "test -d $HA_CONFIG_DIR/custom_components/hacs && echo 'yes' || echo 'no'" 2>/dev/null || echo "no")

if [ "$hacs_check" != "yes" ]; then
    echo "  ⚠️  HACS not found. Installing LocalTuya directly via git clone..."
    INSTALL_METHOD="git"
else
    echo "  ✅ HACS is installed"
    echo "  💡 You can install LocalTuya via HACS UI or direct git clone"
    echo "  Installing via direct git clone (faster)..."
    INSTALL_METHOD="git"
fi

# Check if git is installed
echo "🔍 Checking for git..."
git_check=$(ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 "which git > /dev/null 2>&1 && echo 'yes' || echo 'no'" 2>/dev/null || echo "no")
if [ "$git_check" != "yes" ]; then
    echo "  Installing git..."
    ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 "sudo apt-get update && sudo apt-get install -y git" 2>/dev/null || {
        echo "  ⚠️  Could not install git"
        exit 1
    }
fi

# Install LocalTuya via git clone
echo ""
echo "📥 Cloning LocalTuya repository..."
ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 "sudo mkdir -p $HA_CONFIG_DIR/custom_components && cd $HA_CONFIG_DIR/custom_components && sudo git clone $LOCALTUYA_REPO" 2>/dev/null || {
    echo "  ❌ LocalTuya installation failed"
    echo ""
    echo "  Alternative installation methods:"
    echo "  1. Via HACS UI:"
    echo "     - Go to http://10.11.12.100:8123"
    echo "     - HACS → Integrations → Add Custom Repository"
    echo "     - Repository: https://github.com/rospogrigio/localtuya"
    echo "     - Category: Integration"
    echo "     - Install LocalTuya"
    echo ""
    echo "  2. Manual installation:"
    echo "     ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100"
    echo "     sudo mkdir -p $HA_CONFIG_DIR/custom_components"
    echo "     cd $HA_CONFIG_DIR/custom_components"
    echo "     sudo git clone $LOCALTUYA_REPO"
    exit 1
}

# Verify installation
echo ""
echo "✅ Verifying LocalTuya installation..."
if ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 "test -d $LOCALTUYA_PATH && echo 'yes' || echo 'no'" 2>/dev/null | grep -q "yes"; then
    echo "  ✅ LocalTuya installed successfully"
    echo "  Location: $LOCALTUYA_PATH"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Restart Home Assistant: docker restart homeassistant"
    echo "  2. Go to http://10.11.12.100:8123"
    echo "  3. Settings → Devices & Services → Add Integration"
    echo "  4. Search for 'LocalTuya' and add it"
    echo "  5. Configure your Tuya devices with:"
    echo "     - Device IP address"
    echo "     - Device ID (from cloud Tuya integration)"
    echo "     - Local Key (from Tuya IoT Platform)"
else
    echo "  ⚠️  LocalTuya installation may have failed"
    echo "  Check: ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 'ls -la $LOCALTUYA_PATH'"
fi

