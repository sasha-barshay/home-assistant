# Home Assistant Project - Oslik Server

## 📋 Project Overview

**Purpose:** Home Assistant automation and control system
**Host Server:** Oslik (`10.11.12.100`)
**Status:** ✅ **INSTALLED** - Running and operational

---

## 📚 Related Documentation

### Server & Network Information
- **Server Details:** See `../Shared/home-network-overview.md` for complete Oslik server information
- **Network Devices:** See `../Shared/network-devices.md` for network device reference
- **WiFi/UniFi Setup:** See `../Wifi/README.md` for UniFi Controller documentation

### Quick Server Reference
- **Server:** Oslik (`oslik`)
- **OS:** Ubuntu 24.04.3 LTS (upgraded from 22.04.5)
- **Primary IP:** `10.11.12.100` (static, Ethernet - enp1s0)
- **Backup IP:** `10.11.12.125` (WiFi - wlp2s0, OOB/emergency only)
- **SSH:** `ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100` (⚠️ Currently not accessible - SSH service down)
- **Docker:** Version 28.1.1+1 (verified)
- **Network Status:** ✅ Server reachable via ping, ⚠️ SSH service not running

---

## 🏡 Home Assistant

### Current Status
- **Status:** ✅ **INSTALLED AND RUNNING**
- **Installation Method:** Docker Container (officially supported)
- **Container Status:** ✅ Running (healthy)
- **Access:** http://10.11.12.100:8123
- **Server Readiness:** ✅ Server configured and operational

### Installation Planning

#### Installation Method Options
1. **Docker Container** (Recommended for flexibility)
   - Easy to manage and update
   - Isolated from host system
   - Compatible with existing Docker setup

2. **Home Assistant OS (HAOS)**
   - Full operating system on dedicated hardware
   - Not suitable for Oslik (already has Ubuntu)

3. **Home Assistant Supervised**
   - Requires Docker and systemd
   - More complex setup
   - Provides supervisor functionality

#### Selected: Docker Container Installation
- ✅ Installed using officially supported method
- ✅ Uses official image: `ghcr.io/home-assistant/home-assistant:stable`
- ✅ Consistent with UniFi Controller deployment
- ✅ Easy backup and migration
- ✅ Includes Mosquitto MQTT broker for device communication

---

## 🔧 Home Assistant Configuration

### Service Details
- **Access URL:** http://10.11.12.100:8123
- **Installation Method:** Docker Container (officially supported)
- **Container Name:** `homeassistant`
- **Image:** `ghcr.io/home-assistant/home-assistant:stable`
- **Data Directory:** `/home/system/homeassistant/config` (system-managed, autonomous)
- **MQTT Broker:** Mosquitto (container: `mosquitto`)
- **MQTT Data Directory:** `/home/system/homeassistant/mqtt`
- **Docker Compose:** `/home/chief/docker-compose.yml`

### Required Ports
| Port | Protocol | Purpose | Status |
|------|----------|---------|--------|
| 8123 | TCP | Home Assistant Web UI | ✅ Listening |
| 1883 | TCP | MQTT Broker | ✅ Listening |
| 9001 | TCP | MQTT WebSocket | ✅ Listening |

### Configuration Files
- **Configuration Directory:** `/home/system/homeassistant/config`
- **Docker Compose:** `/home/chief/docker-compose.yml`
- **MQTT Config:** `/home/system/homeassistant/mqtt/config/mosquitto.conf`
- **MQTT Password File:** `/home/system/homeassistant/mqtt/config/passwd`
- **Backup Directory:** `/home/system/homeassistant/backups`

### API Access
- **Status:** ✅ **CONFIGURED**
- **Token Storage:** `.env` file (gitignored, local repository)
- **Helper Scripts:** `ha_api.sh` (API operations), `test_ha_token.sh` (token verification)
- **Token Type:** Long-lived access token
- **Access:** Token stored securely in `.env` file, not committed to repository

---

## 🔌 Integrations & Devices

### Home Assistant SkyConnect (Zigbee Coordinator)

**Status:** ✅ **VALIDATED AND OPERATIONAL**

#### Device Information
- **Manufacturer:** Nabu Casa
- **Product:** SkyConnect v1.0
- **USB ID:** `10c4:ea60`
- **Device Path:** `/dev/ttyUSB0`
- **Serial Number:** `bc268bf99491ed11ba38c3d13b20a988`
- **Firmware:** EmberZNet Zigbee 7.4.4.3 build 0 ✅ (Verified - matches expected version)

#### Validation Results
- ✅ **Hardware Detection:** Device detected and accessible
- ✅ **Firmware Version:** Correct (7.4.4.3)
- ✅ **Device Accessibility:** Available to Home Assistant container
- ✅ **Configuration:** SkyConnect entry configured in Home Assistant
- ✅ **ZHA Integration:** Configured and operational

#### ZHA vs MQTT Compatibility
- ✅ **ZHA and MQTT can coexist** - No conflicts
- ✅ **ZHA uses SkyConnect directly** - Does not use MQTT
- ✅ **MQTT remains available** - For other IoT devices/services
- **Note:** Choose either ZHA (direct) or Zigbee2MQTT (via MQTT) for Zigbee devices, not both

#### Next Steps for SkyConnect
1. Open Home Assistant UI: `http://10.11.12.100:8123`
2. Go to Settings → Devices & Services
3. Add Integration → Search for "ZHA" (Zigbee Home Automation)
4. Select SkyConnect device when prompted
5. Complete ZHA setup wizard

### MQTT Integration
- **Status:** ✅ **CONFIGURED AND RUNNING**
- **Broker:** Mosquitto (container: `mosquitto`)
- **Port:** 1883 (TCP), 9001 (WebSocket)
- **Authentication:** Enabled (anonymous disabled)
- **Usage:** Available for IoT devices, sensors, and other MQTT-based integrations

### Tuya Integration
- **Status:** ✅ **CONFIGURED** (Native Cloud Integration)
- **Type:** Official Tuya Integration (cloud-based)
- **Components Loaded:** 19 Tuya component types available
- **Configuration:** Configured via Home Assistant UI
- **Access:** Cloud-based via Tuya IoT Platform
- **Device Support:** Automatic discovery of Tuya devices
- **Status Check:** Use `./check_tuya_status.sh` to verify integration status

### Planned Integrations
- Additional device integrations as needed

### Connected Devices
- SkyConnect Zigbee Coordinator (validated, ZHA configured)
- Sonoff SNZB-05P Water Leak Sensor #1 (`binary_sensor.sonoff_waterleak1`)
  - Battery: 100% (2.8V)
  - Status: Operational
  - Additional entities: Battery sensor, Firmware update, Identify button
- Additional devices to be added via ZHA or MQTT

### Automations
- ✅ Water Leak Sensor Automations configured
  - File: `water_leak_automations.yaml`
  - Notification method: Telegram (`notify.telegram_notifier`)
  - Automations:
    - Basic water leak alert
    - Alert with location details
    - Critical areas alert (with reminders)
    - Alert with battery status
    - Water leak cleared notification
  - Documentation: `WATER_LEAK_SETUP.md`
  - Deployment script: `deploy_water_leak_automations.sh`

---

## 💾 Backup Strategy

### Backup Configuration
- **Status:** ✅ **IMPLEMENTED AND ACTIVE**
- **Backup Location:** `/home/system/homeassistant/backups`
- **Schedule:** Daily at 2:00 AM (via cron)
- **Retention:** 30 days (automated cleanup)
- **Backup Script:** `/home/chief/backup_homeassistant.sh`

### What Gets Backed Up
- Home Assistant configuration directory (`/config`)
- MQTT configuration and data
- Docker Compose file
- Backup metadata and timestamps

### Backup Management
- **Manual Backup:** `sudo /home/chief/backup_homeassistant.sh`
- **View Backups:** `ls -lh /home/system/homeassistant/backups/`
- **Backup Logs:** `/home/system/homeassistant/backups/backup.log`

### Restore Procedures
- **Restore Script:** `/home/chief/restore_homeassistant.sh`
- **Usage:** `sudo /home/chief/restore_homeassistant.sh <backup_filename>`
- **Location:** See restore script for detailed instructions

---

## 🔍 System Health (Home Assistant Specific)

| Component | Status | Notes |
|-----------|--------|-------|
| Home Assistant | ✅ Running | Container healthy, web UI accessible |
| Home Assistant Container | ✅ Running | Container: `homeassistant` (healthy) |
| Mosquitto MQTT | ✅ Running | Container: `mosquitto` (healthy) |
| Home Assistant Port (8123) | ✅ Listening | Web UI accessible |
| MQTT Port (1883) | ✅ Listening | MQTT broker operational |
| MQTT WebSocket (9001) | ✅ Listening | WebSocket support enabled |
| SkyConnect Device | ✅ Validated | Firmware 7.4.4.3, ready for ZHA |
| Server Ready | ✅ Ready | Docker installed, network configured |

---

## 🎯 Next Steps

1. **Initial Setup:**
   - ✅ Installation completed
   - ✅ Configuration documented
   - ⏳ Complete initial Home Assistant onboarding (create user account)
   - ⏳ Configure location and timezone in web UI

2. **MQTT Configuration:**
   - ✅ MQTT broker configured and running
   - ✅ Home Assistant MQTT user created (`homeassistant`)
   - ✅ MQTT integration configured in Home Assistant
   - ✅ Authentication enabled (anonymous disabled)

3. **Set Up Integrations:**
   - ✅ SkyConnect validated and ready
   - ✅ ZHA integration configured (Zigbee Home Automation)
   - ✅ Sonoff SNZB-05P Water Leak Sensor #1 connected
   - ⏳ Add additional Zigbee devices via ZHA
   - ⏳ Configure additional device integrations
   - ✅ Document connected devices (water leak sensor documented)
   - ✅ Water leak sensor automations configured
   - ✅ Automation scripts documented

4. **Security Configuration:**
   - ✅ API token configured and stored securely (`.env` file, gitignored)
   - Configure firewall rules for Home Assistant ports
   - Set up secure authentication
   - Review exposed ports
   - Consider reverse proxy setup for HTTPS

5. **Backup Setup:**
   - ✅ Automated backups configured (daily at 2 AM)
   - ✅ Backup location documented
   - ✅ Restore script created and tested
   - ✅ 30-day retention policy active

6. **Monitoring:**
   - Set up monitoring for Home Assistant service
   - Configure alerts for service failures
   - Monitor resource usage

---

## 📝 Notes

- Home Assistant is the primary service for this project
- **System Architecture:** Fully autonomous - runs independently without user login
- **Data Location:** `/home/system/homeassistant` (system-managed, root-owned)
- **Docker Environment:** Operational with Docker snap
- **Network:** All services accessible on local network (10.11.12.0/24)
- **Backups:** Automated daily backups with 30-day retention
- **Server Access:** Currently SSH not accessible (service down) - requires physical access or alternative management
- **WiFi Interface:** Configured as OOB/emergency only (10.11.12.125) - no default route
- All services are self-hosted (no cloud dependencies)

---

## 🔗 Quick Links

- **Server Details:** `../Shared/home-network-overview.md`
- **Network Devices:** `../Shared/network-devices.md`
- **WiFi/UniFi:** `../Wifi/README.md`

---

**Last Updated:** December 2024
**Status:** ✅ **INSTALLED AND OPERATIONAL** - Home Assistant running autonomously on Oslik
**Project Status:** Active - Production ready, autonomous operation configured
**Phase Status:** ✅ **ZHA Configured** - Zigbee coordinator operational, water leak sensors connected
**API Access:** ✅ **CONFIGURED** - Long-lived access token stored and verified
**Server Access:** ✅ SSH accessible - Server reachable at 10.11.12.100
**Water Leak Sensors:** ✅ **CONFIGURED** - Sonoff SNZB-05P sensor #1 connected, Telegram automations ready
