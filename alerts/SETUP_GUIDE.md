# Home Assistant Alerting - Setup Guide

## 📋 Prerequisites

- Home Assistant running and accessible at `http://10.11.12.100:8123`
- Access to Home Assistant web UI
- API token configured (already done - see `.env` file)
- Basic understanding of YAML syntax

## 🚀 Quick Start

### Step 1: Choose Your Notification Method

Review the options in `README.md` and `SOLUTION.md` to choose your preferred notification method(s).

### Step 2: Configure Notification Service

#### Option A: Mobile App (Easiest)

1. **Install Home Assistant Companion App:**
   - iOS: [App Store](https://apps.apple.com/app/home-assistant/id1099568401)
   - Android: [Google Play](https://play.google.com/store/apps/details?id=io.homeassistant.companion.android)

2. **Connect to Your Home Assistant:**
   - Open the app
   - Add your Home Assistant instance: `http://10.11.12.100:8123`
   - Enter your credentials
   - The notifier will automatically appear as `mobile_app_<device_name>`

3. **No additional configuration needed!** ✅

#### Option B: Email Notifications

1. **Gather SMTP Information:**
   - SMTP server address
   - SMTP port (587 for TLS, 465 for SSL)
   - Your email address
   - Email password (use app-specific password for Gmail)

2. **Edit `notification_config.yaml`:**
   ```yaml
   notify:
     - name: email_notifier
       platform: smtp
       sender: "your_email@example.com"
       recipient: "recipient@example.com"
       server: "smtp.gmail.com"
       port: 587
       username: "your_email@example.com"
       password: "your_app_password"
       encryption: starttls
   ```

3. **Include in `configuration.yaml`:**
   ```yaml
   notification_config: !include notification_config.yaml
   ```

4. **Restart Home Assistant**

#### Option C: Telegram Bot

1. **Create Telegram Bot:**
   - Open Telegram and search for `@BotFather`
   - Send `/newbot` command
   - Follow instructions to create bot
   - Save the bot token

2. **Get Your Telegram User ID:**
   - Search for `@userinfobot` on Telegram
   - Send `/start` command
   - Save your user ID

3. **Edit `notification_config.yaml`:**
   ```yaml
   telegram_bot:
     - platform: polling
       api_key: "YOUR_BOT_TOKEN"
       allowed_chat_ids:
         - YOUR_USER_ID
   
   notify:
     - name: telegram_notifier
       platform: telegram
       chat_id: YOUR_USER_ID
   ```

4. **Include in `configuration.yaml` and restart**

### Step 3: Configure Alerts

#### Method 1: Using Alert Integration

1. **Edit `alert_config.yaml`:**
   - Copy from `alert_config.yaml.template`
   - Update entity IDs to match your devices
   - Update notifier names to match your configured notifiers

2. **Include in `configuration.yaml`:**
   ```yaml
   alert_config: !include alert_config.yaml
   ```

3. **Restart Home Assistant**

#### Method 2: Using Automations

1. **Edit `automation_alerts.yaml`:**
   - Copy from `automation_alerts.yaml.template`
   - Update entity IDs and conditions
   - Update notifier names

2. **Include in `configuration.yaml`:**
   ```yaml
   automation_alerts: !include automation_alerts.yaml
   ```

3. **Restart Home Assistant**

### Step 4: Test Your Alerts

1. **Test via Developer Tools:**
   - Go to Home Assistant UI → Developer Tools → Services
   - Select `notify.mobile_app_your_device` (or your notifier)
   - Click "Call Service"
   - You should receive a notification

2. **Test Alert Integration:**
   - Go to Developer Tools → States
   - Find an entity used in your alert
   - Manually change its state to trigger the alert
   - Verify notification is received

3. **Test Automation:**
   - Go to Developer Tools → Automations
   - Find your alert automation
   - Click "Trigger" to test
   - Verify notification is received

## 📁 File Structure

After setup, your Home Assistant config directory should have:

```
/home/system/homeassistant/config/
├── configuration.yaml
├── notification_config.yaml      # Notification services
├── alert_config.yaml             # Alert integration config
└── automation_alerts.yaml        # Automation-based alerts
```

## 🔧 Configuration File Location

**Important:** Configuration files must be placed in:
```
/home/system/homeassistant/config/
```

This is the Home Assistant configuration directory mounted in the Docker container.

## 📝 Including Files in configuration.yaml

Add these lines to your `configuration.yaml`:

```yaml
# Notification services
notification_config: !include notification_config.yaml

# Alert integration
alert_config: !include alert_config.yaml

# Automation-based alerts
automation_alerts: !include automation_alerts.yaml
```

## ✅ Verification Checklist

- [ ] Notification service configured and tested
- [ ] Alert configuration files created
- [ ] Files included in `configuration.yaml`
- [ ] Home Assistant restarted
- [ ] Test notification sent successfully
- [ ] Alert triggers working correctly

## 🐛 Troubleshooting

### Notifications Not Working

1. **Check Configuration:**
   - Verify YAML syntax (use YAML validator)
   - Check entity IDs are correct
   - Verify notifier names match

2. **Check Logs:**
   ```bash
   docker logs homeassistant | grep -i notify
   docker logs homeassistant | grep -i alert
   ```

3. **Test Service:**
   - Use Developer Tools → Services
   - Try calling the notify service directly

### Mobile App Notifications Not Working

1. **Verify App Connection:**
   - Check app is connected to HA instance
   - Verify app has notification permissions

2. **Check Notifier Name:**
   - Go to Developer Tools → Services
   - Look for `notify.mobile_app_*` services
   - Use the exact name in your alerts

### Email Notifications Not Working

1. **Check SMTP Settings:**
   - Verify server and port
   - Test with email client first
   - Use app-specific password for Gmail

2. **Check Logs:**
   ```bash
   docker logs homeassistant | grep -i smtp
   ```

### Telegram Notifications Not Working

1. **Verify Bot Token:**
   - Check token is correct
   - Ensure bot is not deleted

2. **Verify User ID:**
   - Double-check user ID is correct
   - Send a message to the bot first

3. **Check Bot Permissions:**
   - Ensure bot can send messages to you

## 📚 Additional Resources

- [Home Assistant Notifications](https://www.home-assistant.io/integrations/notify/)
- [Home Assistant Alert Integration](https://www.home-assistant.io/integrations/alert/)
- [Home Assistant Automations](https://www.home-assistant.io/docs/automation/)

## 🆘 Getting Help

If you encounter issues:

1. Check Home Assistant logs
2. Verify YAML syntax
3. Test notification service independently
4. Review entity IDs and states
5. Check notification service documentation

---

**Last Updated:** December 2024

