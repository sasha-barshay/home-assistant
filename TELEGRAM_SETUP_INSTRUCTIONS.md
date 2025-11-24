# Telegram Integration Setup Instructions

## Issue Identified

The Telegram integration is not currently set up in Home Assistant. The `notification_config.yaml` file exists but Telegram needs to be configured as an integration.

## Solution: Set Up Telegram Integration via UI

### Option 1: Use Home Assistant UI (Recommended)

1. **Open Home Assistant UI:**
   - Navigate to: http://10.11.12.100:8123

2. **Add Telegram Integration:**
   - Go to: **Settings** → **Devices & Services**
   - Click: **Add Integration** (bottom right)
   - Search for: **Telegram**
   - Select: **Telegram Bot**

3. **Configure Telegram Bot:**
   - **Bot Token:** `8375553299:AAG7tKD2JmXMSL7-Eh-r0ZHDwsdA8Z1i_wQ`
   - **Chat ID:** `439885937`
   - Click **Submit**

4. **Verify Integration:**
   - The Telegram integration should appear in Devices & Services
   - Status should show as "Loaded"

5. **Test Notification:**
   - Go to: **Developer Tools** → **Services**
   - Service: `notify.telegram` (or `notify.telegram_notifier` if custom name was used)
   - Service Data:
     ```json
     {
       "message": "Test notification"
     }
     ```
   - Click **Call Service**
   - Check Telegram for the message

### Option 2: Use YAML Configuration (If UI doesn't work)

The `notification_config.yaml` file is already configured with:
- Bot Token: `8375553299:AAG7tKD2JmXMSL7-Eh-r0ZHDwsdA8Z1i_wQ`
- Chat ID: `439885937`

Make sure it's included in `configuration.yaml`:
```yaml
notification_config: !include notification_config.yaml
```

Then restart Home Assistant.

## After Telegram is Set Up

Once Telegram integration is working:

1. **Verify Service Name:**
   - Check available services in Developer Tools → Services
   - Look for `notify.telegram` or `notify.telegram_notifier`

2. **Update Automations (if needed):**
   - If the service name is different, update `automations.yaml`
   - Current automations use: `notify.telegram` with `chat_id: 439885937`

3. **Test Water Leak Alert:**
   - Trigger the sensor (touch probes with damp cloth)
   - Or use API: 
     ```bash
     curl -X POST -H "Authorization: Bearer <TOKEN>" \
          -H "Content-Type: application/json" \
          -d '{"entity_id":"binary_sensor.sonoff_waterleak1"}' \
          http://10.11.12.100:8123/api/services/binary_sensor/turn_on
     ```
   - Check Telegram for the alert

## Troubleshooting

### If Telegram Service Not Found

1. **Check Integration Status:**
   - Settings → Devices & Services → Telegram
   - Verify it shows as "Loaded"

2. **Check Logs:**
   ```bash
   docker logs homeassistant | grep -i telegram
   ```

3. **Verify Bot Token:**
   - Make sure the bot token is correct
   - Test with BotFather: Send `/getme` to your bot

4. **Verify Chat ID:**
   - Make sure you've sent at least one message to the bot
   - Get chat ID from: https://api.telegram.org/bot<TOKEN>/getUpdates

### If Notifications Don't Arrive

1. **Check Bot is Running:**
   - Send a message to your bot in Telegram
   - Bot should respond (if configured)

2. **Check Service Name:**
   - The service might be `notify.telegram` (default) or `notify.telegram_notifier` (custom)
   - Update automations to match the actual service name

3. **Test Service Directly:**
   - Use Developer Tools → Services
   - Call the notify service with a test message

## Current Configuration

- **Bot Token:** `8375553299:AAG7tKD2JmXMSL7-Eh-r0ZHDwsdA8Z1i_wQ`
- **Chat ID:** `439885937`
- **Automations:** Configured to use `notify.telegram` with `chat_id: 439885937`
- **Sensor:** `binary_sensor.sonoff_waterleak1`

## Next Steps

1. Set up Telegram integration via UI (see Option 1 above)
2. Verify the service is available
3. Test a notification manually
4. Test the water leak sensor trigger
5. Verify Telegram alerts are received

