# Home Assistant Alerts - Quick Reference

## 📱 Notification Services Quick Setup

### Mobile App (Recommended - Easiest)
```bash
# 1. Install Home Assistant Companion app
# 2. Connect to http://10.11.12.100:8123
# 3. Done! Notifier appears as: mobile_app_<device_name>
```

### Email (SMTP)
```yaml
# Add to notification_config.yaml
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

### Telegram
```yaml
# 1. Create bot via @BotFather
# 2. Get token and user ID
# Add to notification_config.yaml
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

## 🚨 Alert Configuration Examples

### Simple Alert (Alert Integration)
```yaml
alert:
  door_open:
    name: "Door Open"
    entity_id: binary_sensor.door
    state: "on"
    repeat: 30
    notifiers:
      - mobile_app_your_device
```

### Automation Alert
```yaml
automation:
  - alias: "High Temperature Alert"
    trigger:
      - platform: numeric_state
        entity_id: sensor.temperature
        above: 30
    action:
      - service: notify.mobile_app_your_device
        data:
          title: "High Temperature"
          message: "Temperature is {{ states('sensor.temperature') }}°C"
```

## 📋 Common Entity Types

| Entity Type | Example | Use Case |
|------------|---------|----------|
| `binary_sensor.*` | `binary_sensor.door` | Door/window open/closed |
| `sensor.*` | `sensor.temperature` | Temperature, humidity, etc. |
| `device_tracker.*` | `device_tracker.phone` | Device presence |
| `switch.*` | `switch.light` | Switch state |
| `binary_sensor.*_online` | `binary_sensor.device_online` | Device connectivity |

## 🔍 Finding Entity IDs

1. **Via Web UI:**
   - Go to Developer Tools → States
   - Browse all entities

2. **Via API:**
   ```bash
   ./ha_api.sh states
   ```

3. **Via Script:**
   ```bash
   # List all binary sensors
   ./ha_api.sh states | grep binary_sensor
   ```

## 🧪 Testing Notifications

### Test via Developer Tools
1. Go to Home Assistant UI
2. Developer Tools → Services
3. Select `notify.mobile_app_your_device` (or your notifier)
4. Click "Call Service"

### Test via API
```bash
# Test notification
curl -X POST http://10.11.12.100:8123/api/services/notify/mobile_app_your_device \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Test notification"}'
```

## 📁 File Locations

| File | Location |
|------|----------|
| Config Directory | `/home/system/homeassistant/config/` |
| Notification Config | `config/notification_config.yaml` |
| Alert Config | `config/alert_config.yaml` |
| Automation Alerts | `config/automation_alerts.yaml` |

## 🔄 Restart Home Assistant

After configuration changes:
```bash
# Restart container
docker restart homeassistant

# Or via docker-compose
cd /home/chief
docker compose restart homeassistant
```

## 📊 Notification Priority Levels

| Priority | Description | Use Case |
|----------|-------------|----------|
| `low` | Low priority | Informational |
| `normal` | Normal priority | Regular alerts |
| `high` | High priority | Important alerts |
| `critical` | Critical priority | Emergency alerts |

## 🎯 Common Alert Patterns

### Door/Window Open
```yaml
entity_id: binary_sensor.door
state: "on"
repeat: 30
```

### High/Low Sensor Value
```yaml
entity_id: sensor.temperature
above: 30  # or below: 10
```

### Device Offline
```yaml
entity_id: binary_sensor.device_online
state: "off"
repeat: 60
```

### Time-Based Alert
```yaml
trigger:
  - platform: state
    entity_id: binary_sensor.door
    to: "on"
condition:
  - condition: time
    after: "22:00:00"
    before: "06:00:00"
```

## 🛠️ Troubleshooting Commands

```bash
# Check Home Assistant logs
docker logs homeassistant | tail -50

# Check for notification errors
docker logs homeassistant | grep -i notify

# Check for alert errors
docker logs homeassistant | grep -i alert

# Validate YAML syntax
# (Use online YAML validator or Home Assistant UI)
```

## 📝 Configuration Checklist

- [ ] Notification service configured
- [ ] Test notification sent successfully
- [ ] Alert/automation configured
- [ ] Entity IDs verified
- [ ] Notifier names match
- [ ] Files included in configuration.yaml
- [ ] Home Assistant restarted
- [ ] Alert tested and working

---

**Quick Help:** See `SETUP_GUIDE.md` for detailed instructions

