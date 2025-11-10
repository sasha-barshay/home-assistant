# Home Assistant Alerts - Installation Guide

## 📋 Prerequisites

- ✅ Home Assistant running at `http://10.11.12.100:8123`
- ✅ Home Assistant Companion app installed and connected
- ✅ Telegram installed on your device
- ✅ API token configured (`.env` file exists)

## 🚀 Installation Steps

### Step 1: Find Your Mobile App Notifier Name

1. **Run the helper script:**
   ```bash
   cd /Users/sashab/SHome/HAssistant
   ./alerts/find_mobile_notifier.sh
   ```

2. **Or manually via Home Assistant UI:**
   - Go to `http://10.11.12.100:8123`
   - Navigate to Developer Tools → Services
   - Look for services starting with `notify.mobile_app_`
   - Note the exact name (e.g., `mobile_app_iphone`)

3. **Save the notifier name** - you'll need it in the next steps

### Step 2: Set Up Telegram Bot

1. **Follow the Telegram setup guide:**
   - See `TELEGRAM_SETUP.md` for detailed instructions
   - Create bot via @BotFather
   - Get your Telegram user ID
   - Save bot token and user ID

2. **Update `notification_config.yaml`:**
   - Open `alerts/notification_config.yaml`
   - Replace `YOUR_BOT_TOKEN_HERE` with your bot token
   - Replace `YOUR_TELEGRAM_USER_ID` with your user ID
   - Replace `mobile_app_YOUR_DEVICE` with your mobile app notifier name

### Step 3: Update Alert Configurations

1. **Update `alert_config.yaml`:**
   - Open `alerts/alert_config.yaml`
   - Replace all instances of `mobile_app_YOUR_DEVICE` with your actual notifier name
   - Update entity IDs to match your devices (if needed)

2. **Update `automation_alerts.yaml`:**
   - Open `alerts/automation_alerts.yaml`
   - Replace all instances of `mobile_app_YOUR_DEVICE` with your actual notifier name
   - Update entity IDs to match your devices (if needed)

### Step 4: Copy Files to Home Assistant Config

**Important:** Files must be copied to the Home Assistant config directory on the server.

```bash
# From your local machine, copy files to server
# (Adjust paths and use appropriate method to copy to server)

# Option 1: If you have SSH access to the server
scp alerts/notification_config.yaml chief@10.11.12.100:/tmp/
scp alerts/alert_config.yaml chief@10.11.12.100:/tmp/
scp alerts/automation_alerts.yaml chief@10.11.12.100:/tmp/

# Then on the server:
sudo cp /tmp/notification_config.yaml /home/system/homeassistant/config/
sudo cp /tmp/alert_config.yaml /home/system/homeassistant/config/
sudo cp /tmp/automation_alerts.yaml /home/system/homeassistant/config/
sudo chown root:root /home/system/homeassistant/config/*.yaml
```

**Note:** Since SSH may not be accessible, you may need to:
- Use physical access to the server
- Use alternative file transfer method
- Or manually create files on the server

### Step 5: Update configuration.yaml

On the server, edit `/home/system/homeassistant/config/configuration.yaml`:

```yaml
# Add these lines (if not already present):

# Notification services
notification_config: !include notification_config.yaml

# Alert integration
alert_config: !include alert_config.yaml

# Automation-based alerts
automation_alerts: !include automation_alerts.yaml
```

### Step 6: Restart Home Assistant

```bash
# On the server
docker restart homeassistant

# Or via docker-compose
cd /home/chief
docker compose restart homeassistant
```

### Step 7: Verify Installation

1. **Check Home Assistant logs:**
   ```bash
   docker logs homeassistant | tail -50
   ```
   - Look for any YAML syntax errors
   - Verify Telegram bot connection

2. **Test Mobile App Notification:**
   - Go to Home Assistant UI → Developer Tools → Services
   - Select `notify.mobile_app_<your_device>`
   - Click "Call Service"
   - You should receive a notification on your phone

3. **Test Telegram Notification:**
   - Go to Developer Tools → Services
   - Select `notify.telegram_notifier`
   - Click "Call Service"
   - You should receive a message on Telegram

4. **Test Multi-Channel Alert:**
   - Go to Developer Tools → Services
   - Select `notify.multi_channel_alerts`
   - Click "Call Service"
   - You should receive notifications on both mobile app and Telegram

## 🔧 Configuration Customization

### Update Entity IDs

The alert configurations use placeholder entity IDs. Update them to match your actual devices:

1. **Find your entity IDs:**
   ```bash
   ./ha_api.sh states | grep binary_sensor
   ./ha_api.sh states | grep sensor
   ```

2. **Update in configuration files:**
   - Edit `alert_config.yaml` and `automation_alerts.yaml`
   - Replace placeholder entity IDs with your actual ones

### Add Custom Alerts

1. **Edit `alert_config.yaml`** for simple state-based alerts
2. **Edit `automation_alerts.yaml`** for complex conditional alerts
3. **Restart Home Assistant** after changes

## 🐛 Troubleshooting

### YAML Syntax Errors

1. **Check logs:**
   ```bash
   docker logs homeassistant | grep -i error
   ```

2. **Validate YAML:**
   - Use online YAML validator
   - Check indentation (must use spaces, not tabs)

### Notifications Not Working

1. **Verify notifier names:**
   - Check mobile app notifier name is correct
   - Verify Telegram bot is configured correctly

2. **Test services individually:**
   - Test mobile app notification
   - Test Telegram notification
   - Test multi-channel notification

3. **Check logs:**
   ```bash
   docker logs homeassistant | grep -i notify
   docker logs homeassistant | grep -i telegram
   ```

### Telegram Bot Not Responding

1. **Verify bot token:**
   - Check token is correct in `notification_config.yaml`
   - Ensure no extra spaces

2. **Verify user ID:**
   - Check user ID is correct
   - Ensure you've started a chat with the bot

3. **Check bot status:**
   - Try sending a message to your bot
   - Verify bot is not deleted

## 📝 Post-Installation Checklist

- [ ] Mobile app notifier name identified
- [ ] Telegram bot created and configured
- [ ] Configuration files updated with credentials
- [ ] Files copied to HA config directory
- [ ] Files included in `configuration.yaml`
- [ ] Home Assistant restarted
- [ ] Mobile app notification tested
- [ ] Telegram notification tested
- [ ] Multi-channel notification tested
- [ ] Entity IDs updated (if needed)
- [ ] Custom alerts added (if needed)

## 🎯 Next Steps

1. **Monitor alerts:**
   - Check that alerts are working correctly
   - Adjust repeat intervals as needed
   - Fine-tune alert conditions

2. **Add custom alerts:**
   - Add alerts for your specific devices
   - Configure thresholds for sensors
   - Set up security alerts

3. **Extend Telegram bot:**
   - Add bot commands for HA control
   - Set up two-way communication
   - Create automation responses

## 📚 Additional Resources

- `TELEGRAM_SETUP.md` - Detailed Telegram bot setup
- `SETUP_GUIDE.md` - General setup guide
- `QUICK_REFERENCE.md` - Quick reference for common tasks
- `README.md` - Overview of notification options

---

**Last Updated:** December 2024
**Status:** Ready for installation

