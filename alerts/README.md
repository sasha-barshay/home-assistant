# Home Assistant Alerting System

## 📋 Overview

Autonomous, non-interactive alerting and notification system for Home Assistant running on Oslik server (`10.11.12.100:8123`).

**Status:** ✅ **DEPLOYED** - Fully operational with Telegram bot (NafanyaBot) and mobile app notifications

## 🚀 Quick Start

### Autonomous Deployment

Run the full deployment script to automatically:
1. Set up Telegram bot (if credentials provided)
2. Discover mobile app notifiers
3. Discover and categorize entities
4. Generate alert configurations
5. Create system monitoring sensors
6. Deploy all configurations to Home Assistant
7. Validate and test the deployment

```bash
cd /Users/sashab/SHome/HAssistant/alerts
./run_full_deployment.sh
```

### Prerequisites

1. **Home Assistant API Token:**
   ```bash
   # Create .env file in project root
   echo "HA_TOKEN=your_token_here" > ../.env
   echo "HA_URL=http://10.11.12.100:8123" >> ../.env
   ```

2. **Telegram Bot (Optional):**
   ```bash
   export TELEGRAM_BOT_TOKEN="your_bot_token"
   export TELEGRAM_USER_ID="your_user_id"
   ```

3. **Python Dependencies:**
   ```bash
   pip3 install pyyaml
   ```

## 📁 Project Structure

```
alerts/
├── run_full_deployment.sh          # Master orchestration script
├── auto_setup_telegram.sh          # Autonomous Telegram bot setup
├── discover_entities.sh            # Entity discovery and categorization
├── create_system_monitoring.sh     # System monitoring sensors
├── deploy_alerts.sh                # SSH-based deployment
├── validate_pre_deployment.sh      # Pre-deployment validation
├── test_post_deployment.sh         # Post-deployment testing
├── find_mobile_notifier.sh         # Mobile app notifier discovery
├── generate_alert_config.py        # Alert configuration generator
│
├── notification_config.yaml        # Notification services config
├── alert_config.yaml               # Alert integration config
├── automation_alerts.yaml          # Automation-based alerts
├── system_monitoring.yaml          # System health monitoring
│
├── README.md                       # This file
├── QUICK_REFERENCE.md              # Quick reference guide
├── QUICK_START.md                  # Quick start guide
├── INSTALLATION.md                 # Detailed installation guide
├── SETUP_GUIDE.md                  # Setup instructions
└── TELEGRAM_SETUP.md               # Telegram bot setup guide
```

## 🎯 Features

### ✅ Implemented

- **Autonomous Deployment:** Fully automated, non-interactive deployment with milestone tracking
- **Telegram Bot Integration:** Automated bot setup and configuration (NafanyaBot)
- **Mobile App Notifications:** Automatic discovery and integration
- **Entity Discovery:** Automatic discovery and categorization of Home Assistant entities
- **Alert Generation:** Automatic generation of alert configurations from discovered entities
- **System Monitoring:** Template sensors for system health monitoring
- **SSH Deployment:** Secure deployment to remote Home Assistant server
- **Validation & Testing:** Comprehensive pre and post-deployment validation

### 📊 Milestone-Based Testing

The deployment system uses milestone-based testing to ensure reliability:

- **Phase 1:** Setup and configuration
- **Phase 2:** Entity discovery and categorization
- **Phase 3:** Alert configuration generation
- **Phase 4:** System monitoring setup
- **Phase 5:** Deployment and validation
- **Phase 6:** Post-deployment testing

## 🔧 Configuration

### Notification Services

The system supports multiple notification channels:

1. **Telegram Bot** (NafanyaBot)
   - Bot: `@Nafanya_HA_Bot`
   - User ID: Configured in `notification_config.yaml`
   - Auto-configured via `auto_setup_telegram.sh`

2. **Mobile App**
   - Automatically discovered via `find_mobile_notifier.sh`
   - Supports Home Assistant Companion app (iOS/Android)

### Alert Types

The system automatically generates alerts for:

- **Device Trackers:** Offline detection for device trackers
- **Binary Sensors:** Offline detection for online/available sensors
- **System Monitoring:** Template sensors for system health

### Generated Files

- `alert_config.yaml` - Alert integration configurations
- `automation_alerts.yaml` - Automation-based alert triggers
- `system_monitoring.yaml` - System health monitoring sensors
- `notification_config.yaml` - Notification service configurations

## 📝 Usage

### Full Deployment

```bash
./run_full_deployment.sh
```

This script:
- Validates prerequisites
- Sets up Telegram bot (if credentials provided)
- Discovers entities and generates alerts
- Creates system monitoring
- Deploys to Home Assistant
- Validates and tests deployment

### Individual Scripts

#### Telegram Setup
```bash
./auto_setup_telegram.sh --update-configs
```

#### Entity Discovery
```bash
./discover_entities.sh
```

#### Generate Alerts
```bash
./discover_entities.sh --generate-alerts
```

#### Deploy to Server
```bash
./deploy_alerts.sh
```

#### Validate Deployment
```bash
./validate_pre_deployment.sh
./test_post_deployment.sh
```

## 🔍 Troubleshooting

### TEST_MODE

If Telegram credentials are not set, the deployment runs in `TEST_MODE`, which:
- Skips Telegram-specific steps
- Allows deployment to proceed with mobile app notifications only
- Makes Telegram validation non-blocking

### Common Issues

1. **PyYAML not installed:**
   ```bash
   pip3 install pyyaml
   ```

2. **API Token not set:**
   ```bash
   # Check .env file exists
   cat ../.env
   ```

3. **SSH Permission Denied:**
   - Ensure SSH key is configured
   - Check remote server permissions

4. **Mobile Notifier Not Found:**
   - Ensure Home Assistant Companion app is connected
   - Check that app is registered in Home Assistant

## 📚 Documentation

- **QUICK_START.md** - Quick start guide
- **QUICK_REFERENCE.md** - Quick reference for common tasks
- **INSTALLATION.md** - Detailed installation instructions
- **SETUP_GUIDE.md** - Step-by-step setup guide
- **TELEGRAM_SETUP.md** - Telegram bot setup instructions

## 🔒 Security

- API tokens stored in `.env` file (gitignored)
- Telegram bot token stored in `notification_config.yaml` (deployed to server)
- SSH-based deployment with key authentication
- All sensitive data excluded from repository

## 📊 Deployment Status

**Last Deployment:** November 2024
**Bot Name:** NafanyaBot (`@Nafanya_HA_Bot`)
**Status:** ✅ Operational
**Notifications:** Telegram + Mobile App

---

**Last Updated:** November 2024
**Status:** ✅ Production Ready
