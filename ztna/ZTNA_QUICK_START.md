# ZTNA Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### 1. Install Tailscale on Oslik

```bash
ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled
sudo tailscale up
```

**Copy the authentication URL** and open in browser to authenticate.

### 2. Get Oslik's Tailscale IP

```bash
sudo tailscale ip -4
```

Save this IP address - you'll need it for client connections.

### 3. Install Tailscale on Clients

**Mac:**
```bash
brew install tailscale
sudo tailscaled
tailscale up
```

**Windows:**
- Download: https://tailscale.com/download/windows
- Install and run, then authenticate

**Android:**
- Play Store: Search "Tailscale"
- Install, open, authenticate

**iOS:**
- App Store: Search "Tailscale"
- Install, open, authenticate

### 4. Access Home Assistant

From any client device:
```
http://<oslik-tailscale-ip>:8123
```

Or if subnet routing is enabled:
```
http://10.11.12.100:8123
```

---

## 📱 Platform-Specific Commands

### Mac/Linux
```bash
# Check status
tailscale status

# Get IP
tailscale ip -4

# Ping Oslik
tailscale ping oslik

# Disconnect
tailscale down

# Reconnect
tailscale up
```

### Windows
- Use Tailscale GUI (system tray icon)
- Or PowerShell: `tailscale status`, `tailscale up`, etc.

### Android/iOS
- Use Tailscale app
- Toggle connection on/off in app

---

## 🔧 Common Tasks

### Enable Subnet Routing (Access entire 10.11.12.0/24 network)

On Oslik:
```bash
sudo tailscale up --advertise-routes=10.11.12.0/24
```

Then approve in Tailscale admin console:
1. Go to https://login.tailscale.com/admin/machines
2. Find Oslik machine
3. Click "Edit"
4. Enable "Subnet routes"
5. Save

### Enable MagicDNS (Use hostnames instead of IPs)

1. Go to https://login.tailscale.com/admin/settings
2. Enable "MagicDNS"
3. Access via: `http://oslik:8123` (instead of IP)

### View All Devices

```bash
tailscale status
```

Or in admin console: https://login.tailscale.com/admin/machines

---

## 🐛 Troubleshooting

### Can't connect to Oslik

1. Check both devices are online:
   ```bash
   tailscale status
   ```

2. Verify Oslik is authenticated:
   ```bash
   ssh chief@10.11.12.100
   sudo tailscale status
   ```

3. Check ACLs in admin console:
   - https://login.tailscale.com/admin/acls

4. Restart Tailscale on Oslik:
   ```bash
   sudo systemctl restart tailscaled
   ```

### High latency

- Check internet connection on both devices
- Tailscale uses direct connection when possible
- Check DERP relay status in admin console

### Service not accessible

1. Verify service is running on Oslik:
   ```bash
   docker ps  # Check Home Assistant
   ```

2. Check service binds to correct interface:
   - Home Assistant should bind to `0.0.0.0` or `10.11.12.100`

3. Verify Tailscale IP:
   ```bash
   sudo tailscale ip -4
   ```

---

## 🔗 Useful Links

- **Tailscale Admin Console:** https://login.tailscale.com/admin
- **Full Documentation:** See `ZTNA_IMPLEMENTATION_PLAN.md`
- **Tailscale KB:** https://tailscale.com/kb/

---

**Quick Reference:** Keep this file handy during setup and troubleshooting.
