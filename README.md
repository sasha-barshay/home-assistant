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
├── PROJECT.md                  # Detailed project documentation
└── METHODOLOGY.md              # Problem-solving methodology
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
- ⏳ **ZHA:** Ready for configuration

### Planned Integrations

- ZHA (Zigbee Home Automation)
- Additional device integrations as needed

## 📚 Documentation

- **PROJECT.md:** Complete project documentation including installation details, configuration, and status
- **METHODOLOGY.md:** Universal problem-solving methodology for troubleshooting

## 🔒 Security Notes

- MQTT authentication is enabled (no anonymous access)
- All services run on local network (10.11.12.0/24)
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

**Last Updated:** November 9, 2025  
**Status:** ✅ Operational - Production ready

