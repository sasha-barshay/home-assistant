# Telegram Bot Setup Guide

## 📋 Overview

This guide will help you set up a Telegram bot for Home Assistant notifications and automation control.

## 🚀 Step-by-Step Setup

### Step 1: Create Telegram Bot

1. **Open Telegram** on your phone or desktop
2. **Search for `@BotFather`** (official Telegram bot creator)
3. **Start a chat** with BotFather
4. **Send the command:** `/newbot`
5. **Follow the prompts:**
   - Choose a name for your bot (e.g., "Home Assistant Bot")
   - Choose a username (must end with "bot", e.g., "my_ha_bot")
6. **Save the bot token** - BotFather will give you a token like:
   ```
   123456789:ABCdefGHIjklMNOpqrsTUVwxyz
   ```
   ⚠️ **Keep this token secret!**

### Step 2: Get Your Telegram User ID

1. **Search for `@userinfobot`** on Telegram
2. **Start a chat** with the bot
3. **Send `/start`** command
4. **The bot will reply with your user ID** (a number like `123456789`)
5. **Save this user ID**

### Step 3: Test Your Bot

1. **Search for your bot** using the username you created (e.g., `@my_ha_bot`)
2. **Start a chat** with your bot
3. **Send `/start`** to your bot
4. **You should receive a response** (even if it's just a default message)

### Step 4: Configure Home Assistant

1. **Edit `notification_config.yaml`:**
   ```yaml
   telegram_bot:
     - platform: polling
       api_key: "YOUR_BOT_TOKEN_HERE"  # Paste your bot token
       allowed_chat_ids:
         - YOUR_TELEGRAM_USER_ID  # Paste your user ID
   
   notify:
     - name: telegram_notifier
       platform: telegram
       chat_id: YOUR_TELEGRAM_USER_ID  # Paste your user ID
   ```

2. **Replace the placeholders:**
   - `YOUR_BOT_TOKEN_HERE` → Your bot token from Step 1
   - `YOUR_TELEGRAM_USER_ID` → Your user ID from Step 2

3. **Copy the file to Home Assistant config:**
   ```bash
   sudo cp alerts/notification_config.yaml /home/system/homeassistant/config/
   ```

4. **Include in `configuration.yaml`:**
   ```yaml
   notification_config: !include notification_config.yaml
   ```

5. **Restart Home Assistant:**
   ```bash
   docker restart homeassistant
   ```

### Step 5: Test Notifications

1. **Via Home Assistant UI:**
   - Go to Developer Tools → Services
   - Select `notify.telegram_notifier`
   - Click "Call Service"
   - You should receive a message on Telegram

2. **Via API:**
   ```bash
   ./ha_api.sh call-service notify telegram_notifier
   ```

## 🤖 Advanced: Bot Commands for HA Control

You can extend your bot to control Home Assistant. Add this to your `automation_alerts.yaml`:

```yaml
automation:
  # Handle Telegram bot commands
  - alias: "Telegram Bot - Handle Commands"
    id: telegram_bot_commands
    description: "Process commands sent to Telegram bot"
    trigger:
      - platform: event
        event_type: telegram_command
        event_data:
          command: "/status"
    action:
      - service: notify.telegram_notifier
        data:
          message: >
            Home Assistant Status:
            - Service: {{ states('binary_sensor.homeassistant_status') }}
            - Uptime: {{ states('sensor.uptime') }}
```

## 📝 Common Bot Commands

You can add these commands via BotFather:
- `/setcommands` - Set custom commands for your bot
- `/setdescription` - Set bot description
- `/setabouttext` - Set about text
- `/setuserpic` - Set bot profile picture

## 🔒 Security Notes

1. **Keep your bot token secret** - Don't share it or commit it to public repositories
2. **Use `allowed_chat_ids`** - This restricts who can interact with your bot
3. **Regular updates** - Keep Home Assistant updated for security patches

## 🐛 Troubleshooting

### Bot Not Responding

1. **Check bot token:**
   - Verify token is correct in `notification_config.yaml`
   - Ensure no extra spaces or quotes

2. **Check user ID:**
   - Verify user ID is correct (should be a number)
   - Ensure you've started a chat with the bot first

3. **Check Home Assistant logs:**
   ```bash
   docker logs homeassistant | grep -i telegram
   ```

### Notifications Not Received

1. **Verify bot is running:**
   - Check if you can see your bot in Telegram
   - Send a message to your bot

2. **Check configuration:**
   - Verify `notification_config.yaml` is included in `configuration.yaml`
   - Check YAML syntax is correct

3. **Test service:**
   - Use Developer Tools → Services
   - Try calling `notify.telegram_notifier` directly

### Bot Commands Not Working

1. **Check event trigger:**
   - Verify event type matches what Telegram sends
   - Check Home Assistant logs for incoming events

2. **Test manually:**
   - Use Developer Tools → Events
   - Listen for `telegram_command` events

## 📚 Additional Resources

- [Home Assistant Telegram Bot Integration](https://www.home-assistant.io/integrations/telegram/)
- [Telegram Bot API Documentation](https://core.telegram.org/bots/api)
- [BotFather Commands](https://core.telegram.org/bots#botfather)

## ✅ Verification Checklist

- [ ] Bot created via @BotFather
- [ ] Bot token saved securely
- [ ] User ID obtained from @userinfobot
- [ ] Bot tested (can send/receive messages)
- [ ] `notification_config.yaml` updated with credentials
- [ ] File copied to HA config directory
- [ ] Included in `configuration.yaml`
- [ ] Home Assistant restarted
- [ ] Test notification sent successfully
- [ ] Notification received on Telegram

---

**Last Updated:** December 2024

