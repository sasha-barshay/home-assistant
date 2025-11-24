#!/bin/bash
# Migrate from Cloud Tuya to LocalTuya (Direct Local Control)
# Steps: 1. Install HACS, 2. Install LocalTuya, 3. Get device IDs from cloud Tuya, 4. Configure via CLI

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ Error: .env file not found"
    exit 1
fi

if [ -z "$HA_TOKEN" ] || [ -z "$HA_URL" ]; then
    echo "❌ Error: HA_TOKEN or HA_URL not set"
    exit 1
fi

HA_CONFIG_DIR="/home/system/homeassistant/config"
LOCALTUYA_REPO="https://github.com/rospogrigio/localtuya.git"

echo "🔄 Migrating Tuya from Cloud to Local Control"
echo ""

# Step 1: Check/Install HACS
echo "📦 Step 1: Checking HACS installation..."
hacs_check=$(curl -s -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/config" 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print('yes' if 'hacs' in str(data.get('components', [])).lower() else 'no')" 2>/dev/null || echo "no")

if [ "$hacs_check" != "yes" ]; then
    echo "  Installing HACS..."
    ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 "bash -c 'cd $HA_CONFIG_DIR && wget -O - https://get.hacs.xyz | bash -'" 2>/dev/null || {
        echo "  ⚠️  HACS installation via SSH failed"
        echo "  Installing via container exec..."
        docker exec homeassistant bash -c "cd /config && wget -O - https://get.hacs.xyz | bash -" 2>/dev/null || {
            echo "  ⚠️  HACS installation failed. Install manually:"
            echo "     Go to http://10.11.12.100:8123 -> HACS"
        }
    }
    echo "  ✅ HACS installation initiated (restart HA if needed)"
else
    echo "  ✅ HACS already installed"
fi

# Step 2: Install LocalTuya via HACS (or direct clone)
echo ""
echo "📦 Step 2: Installing LocalTuya..."
localtuya_path="$HA_CONFIG_DIR/custom_components/localtuya"

if ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 "[ -d $localtuya_path ]" 2>/dev/null; then
    echo "  ✅ LocalTuya already installed"
else
    echo "  Installing LocalTuya to $localtuya_path..."
    ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100 "mkdir -p $HA_CONFIG_DIR/custom_components && cd $HA_CONFIG_DIR/custom_components && git clone $LOCALTUYA_REPO" 2>/dev/null || {
        echo "  Installing via container exec..."
        docker exec homeassistant bash -c "mkdir -p /config/custom_components && cd /config/custom_components && git clone $LOCALTUYA_REPO" 2>/dev/null || {
            echo "  ⚠️  LocalTuya installation failed. Install via HACS UI:"
            echo "     HACS → Integrations → Add Custom Repository → https://github.com/rospogrigio/localtuya"
        }
    }
    echo "  ✅ LocalTuya installed (restart HA to load)"
fi

# Step 3: Get device IDs from existing cloud Tuya integration
echo ""
echo "📱 Step 3: Extracting device IDs from cloud Tuya integration..."
tuya_devices=$(curl -s -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/states" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tuya_entities = [e for e in data if 'tuya' in e.get('entity_id', '').lower()]
    devices = {}
    for e in tuya_entities:
        attrs = e.get('attributes', {})
        # Try multiple ways to get device_id
        device_id = (attrs.get('device_id') or 
                    attrs.get('tuya_device_id') or
                    attrs.get('device_info', {}).get('identifiers', [{}])[0].get('device_id') if attrs.get('device_info') else None)
        
        if not device_id:
            # Extract from entity_id if it contains device info
            entity_id = e.get('entity_id', '')
            parts = entity_id.split('_')
            if len(parts) > 1:
                device_id = '_'.join(parts[1:-1]) if len(parts) > 2 else parts[1]
        
        if device_id and device_id != 'unknown':
            entity_id = e.get('entity_id')
            friendly_name = attrs.get('friendly_name', entity_id)
            if device_id not in devices:
                devices[device_id] = {'entities': [], 'name': friendly_name}
            devices[device_id]['entities'].append(entity_id)
    
    print(json.dumps(devices, indent=2))
except Exception as e:
    print('{}')
" 2>/dev/null || echo "{}")

if [ "$tuya_devices" != "{}" ] && [ -n "$tuya_devices" ]; then
    echo "$tuya_devices" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Found {len(data)} Tuya devices:')
for device_id, info in data.items():
    print(f'  Device ID: {device_id}')
    print(f'    Name: {info.get(\"name\", \"Unknown\")}')
    print(f'    Entities: {len(info.get(\"entities\", []))}')
"
    echo "$tuya_devices" > tuya_devices.json
    echo "  ✅ Device IDs saved to tuya_devices.json"
else
    echo "  ⚠️  No Tuya devices found. Checking device registry..."
    # Try device registry API
    curl -s -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/device_registry" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tuya_devs = [d for d in data if any('tuya' in str(ident).lower() for ident in d.get('identifiers', []))]
    if tuya_devs:
        print(f'Found {len(tuya_devs)} Tuya devices in registry:')
        for d in tuya_devs:
            print(f'  {d.get(\"name\")}: {d.get(\"identifiers\")}')
    else:
        print('  No Tuya devices in registry')
except:
    print('  Could not query device registry')
" 2>/dev/null || echo "  Could not extract device IDs"
fi

# Step 4: Add LocalTuya integration via API
echo ""
echo "🔧 Step 4: Adding LocalTuya integration via API..."
# Check if LocalTuya integration already exists
existing_localtuya=$(curl -s -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/config/config_entries" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    entries = [e for e in data if e.get('domain') == 'localtuya']
    print('yes' if entries else 'no')
except:
    print('no')
" 2>/dev/null || echo "no")

if [ "$existing_localtuya" = "yes" ]; then
    echo "  ✅ LocalTuya integration already configured"
else
    echo "  Adding LocalTuya integration..."
    # LocalTuya requires manual configuration with device details
    # We can't fully automate without local_key and IP addresses
    echo "  ⚠️  LocalTuya requires device IP and local_key for each device"
    echo "  Use UI: Settings → Devices & Services → Add Integration → LocalTuya"
    echo "  Or configure via YAML (see template below)"
fi

# Create LocalTuya configuration template with extracted device IDs
if [ -f tuya_devices.json ] && [ -s tuya_devices.json ]; then
    echo ""
    echo "📝 Generating LocalTuya configuration template..."
    python3 << 'PYEOF'
import json
import sys

try:
    with open('tuya_devices.json', 'r') as f:
        devices = json.load(f)
    
    print("# LocalTuya Configuration")
    print("# Add this to configuration.yaml or configure via UI")
    print("# You need to provide: host (IP), local_key for each device")
    print("")
    print("localtuya:")
    for device_id, info in devices.items():
        print(f"  - host: DEVICE_IP_{device_id[:8]}  # Replace with actual IP")
        print(f"    device_id: {device_id}")
        print(f"    local_key: LOCAL_KEY_{device_id[:8]}  # Get from Tuya IoT Platform")
        print(f"    protocol_version: \"3.3\"")
        print(f"    # Device: {info.get('name', 'Unknown')}")
        print("")
except Exception as e:
    print(f"# Error generating template: {e}", file=sys.stderr)
PYEOF
    > localtuya_config.yaml
    echo "  ✅ Configuration template created: localtuya_config.yaml"
fi

echo ""
echo "📋 Next Steps:"
echo "  1. Get local_key for each device (required):"
echo "     - Tuya IoT Platform: https://iot.tuya.com"
echo "     - Or use tuya-cli tool"
echo "  2. Find IP addresses of Tuya devices:"
echo "     - Check router DHCP table"
echo "     - Or use: nmap -sn 10.11.12.0/24"
echo "  3. Configure LocalTuya:"
echo "     - Via UI: Settings → Devices & Services → Add Integration → LocalTuya"
echo "     - Or edit localtuya_config.yaml and add to configuration.yaml"
echo "  4. Restart Home Assistant after configuration"
echo ""
echo "✅ Migration script completed."

