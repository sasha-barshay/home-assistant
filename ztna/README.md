# ZTNA Implementation for Oslik Server

## 📋 Overview

This directory contains the implementation plan and scripts for setting up Zero Trust Network Access (ZTNA) on the Oslik server to enable secure remote access from Mac, Android, Windows, and iOS devices.

**Recommended Solution:** Tailscale (free tier, up to 100 devices)

---

## 📁 Files

- **`ZTNA_IMPLEMENTATION_PLAN.md`** - Complete implementation plan with detailed steps
- **`ZTNA_QUICK_START.md`** - Quick reference guide for setup and troubleshooting
- **`install_tailscale.sh`** - Automated installation script for Oslik server

---

## 🚀 Quick Start

### Option 1: Automated Installation (Recommended)

```bash
cd ztna
./install_tailscale.sh
```

The script will:
1. Check prerequisites (SSH access, etc.)
2. Install Tailscale on Oslik
3. Start Tailscale service
4. Guide you through authentication
5. Display Tailscale IP address
6. Optionally enable subnet routing

### Option 2: Manual Installation

Follow the step-by-step guide in `ZTNA_IMPLEMENTATION_PLAN.md`

---

## 📱 Client Setup

After Oslik is configured, install Tailscale on your devices:

1. **Mac:** `brew install tailscale` or download from tailscale.com
2. **Windows:** Download from https://tailscale.com/download/windows
3. **Android:** Install from Google Play Store
4. **iOS:** Install from App Store

Authenticate all clients with the same Tailscale account, then access:
- Home Assistant: `http://<oslik-tailscale-ip>:8123`
- Or with subnet routing: `http://10.11.12.100:8123`

See `ZTNA_QUICK_START.md` for detailed client setup instructions.

---

## 🎯 Solution Comparison

| Solution | Setup | Maintenance | Limits | Cost |
|----------|-------|-------------|--------|------|
| **Tailscale** | ⭐ Easy | ⭐ Minimal | 100 devices, 3 users | Free |
| **Headscale** | ⭐⭐⭐ Complex | ⭐⭐⭐ Regular | Unlimited | Free |
| **ZeroTier** | ⭐⭐ Medium | ⭐⭐ Medium | 25 devices (free) | Free |

**Recommendation:** Start with Tailscale. It's the easiest to set up and maintain, with generous free tier limits.

---

## 📚 Documentation

- **Full Plan:** See `ZTNA_IMPLEMENTATION_PLAN.md` for complete implementation details
- **Quick Reference:** See `ZTNA_QUICK_START.md` for common commands and troubleshooting
- **Tailscale Docs:** https://tailscale.com/kb/

---

## ✅ Implementation Checklist

- [ ] Install Tailscale on Oslik
- [ ] Authenticate Oslik with Tailscale account
- [ ] Get and save Tailscale IP address
- [ ] (Optional) Enable subnet routing
- [ ] Install Tailscale on Mac
- [ ] Install Tailscale on Windows
- [ ] Install Tailscale on Android
- [ ] Install Tailscale on iOS
- [ ] Test Home Assistant access from all devices
- [ ] Configure ACLs in Tailscale admin console
- [ ] Enable 2FA on Tailscale account
- [ ] Enable MagicDNS (optional)

---

## 🔗 Links

- **Tailscale Admin Console:** https://login.tailscale.com/admin
- **Tailscale Downloads:** https://tailscale.com/download
- **Tailscale Knowledge Base:** https://tailscale.com/kb/

---

**Status:** 📋 Ready for Implementation  
**Last Updated:** December 2024
