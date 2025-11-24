# Sonoff SNZB-05P Water Leak Sensor Setup Guide

## Overview

This guide covers the setup of Sonoff SNZB-05P Zigbee water leak sensors with Telegram notifications in Home Assistant.

## Current Status

- ✅ ZHA integration configured
- ✅ First sensor connected: `binary_sensor.sonoff_waterleak1`
- ✅ Telegram integration configured: `notify.telegram_notifier`
- ✅ Automation file created: `water_leak_automations.yaml`

## Installation Steps

### 1. Deploy Automation File to Home Assistant

The automation file needs to be copied to the Home Assistant configuration directory on the server:

```bash
# Copy automation file to server
scp -i ~/.ssh/oslik_rsa water_leak_automations.yaml chief@10.11.12.100:/home/system/homeassistant/config/
```

Or if you have direct access to the server:

```bash
# On the server
sudo cp water_leak_automations.yaml /home/system/homeassistant/config/
sudo chown root:root /home/system/homeassistant/config/water_leak_automations.yaml
```

### 2. Include in Home Assistant Configuration

Add the automation file to your `configuration.yaml`:

```yaml
# Water leak sensor automations
automation: !include water_leak_automations.yaml
```

Or if you already have automations included, add it to the list:

```yaml
automation:
  - !include automation_alerts.yaml
  - !include water_leak_automations.yaml
```

### 3. Restart Home Assistant

After adding the configuration:

1. Go to Settings → System → Restart
2. Or restart the container: `docker restart homeassistant`

### 4. Verify Automations

1. Go to Settings → Automations & Scenes
2. You should see the following automations:
   - "Water Leak Alert - Telegram"
   - "Water Leak Alert with Location - Telegram"
   - "Critical Water Leak Alert - Telegram"
   - "Water Leak Alert with Battery Status - Telegram"
   - "Water Leak Cleared - Telegram"

## Testing

### Test Water Leak Detection

1. **Manual Test:**
   - Briefly touch the sensor probes with a damp cloth or wet finger
   - The sensor should detect water and trigger the automation
   - Check Telegram for the alert message

2. **Via Home Assistant:**
   - Go to Developer Tools → Services
   - Select `binary_sensor.turn_on`
   - Enter entity: `binary_sensor.sonoff_waterleak1`
   - Click "Call Service"
   - Check Telegram for the alert

3. **Via API:**
   ```bash
   ./ha_api.sh call-service binary_sensor turn_on binary_sensor.sonoff_waterleak1
   ```

### Test Telegram Notification

```bash
# Test Telegram notification directly
./ha_api.sh call-service notify telegram_notifier '{"message": "Test notification from water leak system"}'
```

## Adding Additional Sensors

When you pair additional sensors, they will automatically be covered by the automations since they use the wildcard pattern `binary_sensor.sonoff_waterleak*`.

### Steps for Additional Sensors:

1. **Pair the sensor:**
   - Remove battery insulation
   - Press and hold button for 5 seconds (LED flashes slowly)
   - In Home Assistant: Settings → Devices & Services → ZHA → Configure → Add Device
   - Wait for pairing to complete

2. **Verify sensor appears:**
   ```bash
   ./ha_api.sh states | grep sonoff_waterleak
   ```

3. **Rename sensor:**
   - Go to Settings → Devices & Services
   - Find the new sensor
   - Click on it → Settings → Rename
   - Give it a descriptive name (e.g., "Kitchen Sink Water Leak")

4. **Assign to area:**
   - In the sensor settings, assign it to the appropriate room/area

5. **Test:**
   - Touch probes with damp cloth
   - Verify Telegram alert is received

## Customization

### Update Critical Sensors

Edit `water_leak_automations.yaml` and update the critical sensors list:

```yaml
- alias: "Critical Water Leak Alert - Telegram"
  trigger:
    - platform: state
      entity_id:
        - binary_sensor.sonoff_waterleak1  # Kitchen sink
        - binary_sensor.sonoff_waterleak2  # Water heater
        - binary_sensor.sonoff_waterleak3  # Sump pump
      to: 'on'
```

### Enable Low Battery Alerts

Uncomment the low battery automation in `water_leak_automations.yaml`:

```yaml
- alias: "Water Leak Sensor Low Battery - Telegram"
  id: water_leak_low_battery_telegram
  trigger:
    - platform: numeric_state
      entity_id: sensor.sonoff_waterleak*_battery
      below: 20  # Adjust threshold as needed
```

## Troubleshooting

### Automations Not Triggering

1. **Check automation status:**
   - Go to Settings → Automations & Scenes
   - Verify automations are enabled (toggle should be on)

2. **Check entity IDs:**
   ```bash
   ./ha_api.sh states | grep sonoff_waterleak
   ```
   - Verify sensor entities match the pattern `binary_sensor.sonoff_waterleak*`

3. **Check logs:**
   ```bash
   docker logs homeassistant | grep -i "water_leak\|automation"
   ```

### Telegram Notifications Not Working

1. **Verify Telegram service:**
   ```bash
   ./ha_api.sh services notify | grep telegram
   ```

2. **Test Telegram directly:**
   ```bash
   ./ha_api.sh call-service notify telegram_notifier '{"message": "Test"}'
   ```

3. **Check Telegram integration:**
   - Go to Settings → Devices & Services
   - Find Telegram integration
   - Verify it's configured and connected

### Sensor Not Detecting Water

1. **Check sensor state:**
   ```bash
   ./ha_api.sh states binary_sensor.sonoff_waterleak1
   ```

2. **Test sensor:**
   - Press button once - LED should flash twice if within range
   - Touch probes with damp cloth
   - Check if state changes to 'on'

3. **Check battery:**
   ```bash
   ./ha_api.sh states sensor.sonoff_waterleak1_battery
   ```
   - Low battery may affect sensor performance

## Entity Reference

### Current Sensors

- `binary_sensor.sonoff_waterleak1` - Main water leak sensor
- `sensor.sonoff_waterleak1_battery` - Battery level (currently 100%)
- `button.sonoff_waterleak1_identify` - Identify button
- `update.sonoff_waterleak1_firmware` - Firmware updates

### Notification Service

- `notify.telegram_notifier` - Telegram notification service

## Quick Reference Commands

```bash
# Check sensor status
./ha_api.sh states binary_sensor.sonoff_waterleak1

# Check battery level
./ha_api.sh states sensor.sonoff_waterleak1_battery

# List all water leak sensors
./ha_api.sh states | grep sonoff_waterleak

# Test Telegram notification
./ha_api.sh call-service notify telegram_notifier '{"message": "Test"}'

# Test sensor trigger (turn on)
./ha_api.sh call-service binary_sensor turn_on binary_sensor.sonoff_waterleak1

# Test sensor trigger (turn off)
./ha_api.sh call-service binary_sensor turn_off binary_sensor.sonoff_waterleak1
```

## Next Steps

1. ✅ Deploy automation file to server
2. ✅ Include in configuration.yaml
3. ✅ Restart Home Assistant
4. ✅ Test water leak detection
5. ⏳ Add additional sensors as needed
6. ⏳ Customize critical sensor list
7. ⏳ Enable low battery alerts (optional)

## Support

For issues or questions:
- Check Home Assistant logs: `docker logs homeassistant`
- Verify API access: `./test_ha_token.sh`
- Review automation logs in Home Assistant UI: Settings → Automations & Scenes → [Automation] → Logbook

