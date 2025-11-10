# Quick Start - Telegram Bot Setup

## 🚀 Fastest Way to Set Up

Run the interactive setup script:

```bash
cd /Users/sashab/SHome/HAssistant
./alerts/setup_telegram_bot.sh
```

This script will:
1. ✅ Guide you through creating the bot
2. ✅ Help you get your user ID
3. ✅ Find your mobile app notifier name
4. ✅ Update all configuration files automatically

## 📱 Manual Steps (If You Prefer)

### Step 1: Create Bot (2 minutes)

1. Open Telegram
2. Search for `@BotFather`
3. Send `/newbot`
4. Follow prompts to create bot
5. **Save the bot token** (looks like: `123456789:ABCdef...`)

### Step 2: Get User ID (1 minute)

1. Search for `@userinfobot` on Telegram
2. Send `/start`
3. **Save your user ID** (a number like `123456789`)

### Step 3: Run Setup Script

```bash
./alerts/setup_telegram_bot.sh
```

Enter your bot token and user ID when prompted.

### Step 4: Test Configuration

```bash
./alerts/test_telegram_bot.sh
```

This will:
- ✅ Validate your bot token
- ✅ Send a test message to Telegram
- ✅ Verify Home Assistant integration

## ✅ That's It!

After running the setup script, your configuration files are ready. Follow `INSTALLATION.md` to deploy to Home Assistant.

---

**Need help?** See `TELEGRAM_SETUP.md` for detailed instructions.

