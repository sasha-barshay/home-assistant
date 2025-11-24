# Home Assistant Automation Project

Home Assistant automation and control system running on Oslik server.

## 📋 Overview

This repository contains the configuration and management scripts for a self-hosted Home Assistant installation with MQTT broker support.

**Server:** Oslik (`10.11.12.100`)
**Status:** ✅ Operational
**Access:** http://10.11.12.100:8123

## 🏗️ Architecture

- **Home Assistant:** Docker container running the official Home Assistant image
- **MQTT Broker:** Mosquitto container for IoT device communication
- **Zigbee Coordinator:** Home Assistant SkyConnect (ZHA ready)
- **Backup System:** Automated daily backups with 30-day retention

## 📁 Repository Structure

```
.
├── docker-compose.yml          # Docker Compose configuration
├── mosquitto.conf              # MQTT broker configuration
├── backup_homeassistant.sh     # Automated backup script
├── restore_homeassistant.sh    # Restore script
├── ha_api.sh                   # Home Assistant API helper script
├── test_ha_token.sh            # Token verification script
├── push_to_github.sh           # Git push helper script
├── .env                         # Environment variables (gitignored, contains API token)
├── PROJECT.md                  # Detailed project documentation
├── METHODOLOGY.md              # Problem-solving methodology
└── alerts/                     # Alerting system (autonomous deployment)
    ├── run_full_deployment.sh  # Master orchestration script
    ├── auto_setup_telegram.sh  # Telegram bot setup
    ├── discover_entities.sh    # Entity discovery
    ├── deploy_alerts.sh        # Deployment script
    └── *.yaml                  # Configuration files
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Ubuntu 24.04+ (or compatible Linux distribution)
- Network access to server at `10.11.12.100`

### Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd HAssistant
   ```

2. Configure directories (adjust paths as needed):
   ```bash
   sudo mkdir -p /home/system/homeassistant/{config,mqtt/{config,data,log},backups}
   sudo chown -R root:root /home/system/homeassistant
   ```

3. Set up MQTT password file:
   ```bash
   # Create password file (use mosquitto_passwd)
   sudo mosquitto_passwd -c /home/system/homeassistant/mqtt/config/passwd homeassistant
   sudo chmod 600 /home/system/homeassistant/mqtt/config/passwd
   ```

4. Start services:
   ```bash
   docker compose up -d
   ```

5. Access Home Assistant:
   - Open http://10.11.12.100:8123
   - Complete initial setup wizard

6. Configure API access (optional):
   ```bash
   # Create .env file with your Home Assistant token
   # Get token from: http://10.11.12.100:8123 -> Profile -> Long-Lived Access Tokens
   cat > .env << EOF
   HA_TOKEN=your_token_here
   HA_URL=http://10.11.12.100:8123
   EOF
   chmod 600 .env

   # Test the token
   ./test_ha_token.sh
   ```

## 🔧 Configuration

### Docker Compose

The `docker-compose.yml` file defines:
- Home Assistant container with host network mode
- Mosquitto MQTT broker with WebSocket support
- Volume mounts for persistent data
- Health checks for both services

### MQTT Configuration

The `mosquitto.conf` file configures:
- TCP listener on port 1883
- WebSocket listener on port 9001
- Authentication required (no anonymous access)
- Persistent message storage

## 💾 Backup & Restore

### Automated Backups

Backups run daily at 2:00 AM via cron:
```bash
# View cron entry
crontab -l | grep backup_homeassistant
```

### Manual Backup

```bash
sudo /home/chief/backup_homeassistant.sh
```

### Restore

```bash
sudo /home/chief/restore_homeassistant.sh <backup_filename>
```

Backups include:
- Home Assistant configuration directory
- MQTT configuration and data
- Docker Compose file
- Backup metadata

## 🔌 Integrations

### Current Integrations

- ✅ **MQTT:** Mosquitto broker configured and running
- ✅ **SkyConnect:** Zigbee coordinator validated (firmware 7.4.4.3)
- ✅ **ZHA:** Configured and operational
- ✅ **Tuya:** Native cloud integration configured
- ✅ **Alerting System:** Autonomous alerting with Telegram bot and mobile app notifications

### Alerting System

The project includes a fully autonomous alerting system located in the `alerts/` directory:

- **Status:** ✅ Deployed and operational
- **Telegram Bot:** NafanyaBot (`@Nafanya_HA_Bot`)
- **Mobile App:** Automatic discovery and integration
- **Entity Discovery:** Automatic discovery and categorization
- **Alert Generation:** Automatic alert configuration generation
- **System Monitoring:** Template sensors for system health

**Quick Start:**
```bash
cd alerts
./run_full_deployment.sh
```

See `alerts/README.md` for complete documentation.

### Tuya Integration

The Tuya integration is configured and ready to use:

- **Status:** ✅ Configured (Native Cloud Integration)
- **Type:** Official Tuya Integration
- **Check Status:** Run `./check_tuya_status.sh` to see current devices and entities
- **Configuration:** Managed via Home Assistant UI (Settings → Devices & Services)

### Planned Integrations

- Additional device integrations as needed

## 📚 Documentation

- **PROJECT.md:** Complete project documentation including installation details, configuration, and status
- **METHODOLOGY.md:** Universal problem-solving methodology for troubleshooting

## 🔌 API Access

### Home Assistant API

The project includes helper scripts for interacting with the Home Assistant API:

- **`ha_api.sh`** - Main API helper script for common operations
- **`test_ha_token.sh`** - Verify API token validity

**Setup:**
1. Create a long-lived access token in Home Assistant:
   - Go to http://10.11.12.100:8123
   - Profile → Long-Lived Access Tokens → Create Token
2. Store token in `.env` file (gitignored):
   ```bash
   echo "HA_TOKEN=your_token_here" > .env
   echo "HA_URL=http://10.11.12.100:8123" >> .env
   chmod 600 .env
   ```

**Usage Examples:**
```bash
# Test API connection
./test_ha_token.sh

# Get configuration
./ha_api.sh config

# List all entity states
./ha_api.sh states

# Get specific entity state
./ha_api.sh states light.living_room

# Call a service
./ha_api.sh call-service light turn_on light.living_room

# View help
./ha_api.sh help
```

## 🔒 Security Notes

- MQTT authentication is enabled (no anonymous access)
- All services run on local network (10.11.12.0/24)
- API token stored in `.env` file (gitignored, not committed)
- Consider firewall rules for exposed ports
- Review exposed ports before exposing to internet

## 🛠️ Maintenance

### View Logs

```bash
# Home Assistant logs
docker logs homeassistant

# MQTT logs
docker logs mosquitto
```

### Update Containers

```bash
docker compose pull
docker compose up -d
```

### Check Status

```bash
docker ps | grep -E "homeassistant|mosquitto"
```

## 📝 Notes

- All services are self-hosted (no cloud dependencies)
- Data is stored in `/home/system/homeassistant/` (system-managed)
- Backups are stored in `/home/system/homeassistant/backups/`
- Server uses static IP: `10.11.12.100`

## 🔗 Related Documentation

For complete server and network information, see:
- Server details: `../Shared/home-network-overview.md`
- Network devices: `../Shared/network-devices.md`
- WiFi/UniFi setup: `../Wifi/README.md`

---

**Last Updated:** December 2024
**Status:** ✅ Operational - Production ready
**API Access:** ✅ Configured with long-lived access token

