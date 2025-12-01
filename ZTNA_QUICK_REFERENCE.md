# Tailscale ZTNA Quick Reference

## 🚀 Quick Start

### Server Setup (Oslik)

```bash
# Run automated setup script
sudo ./ztna_setup.sh

# Or manual setup:
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-routes=10.11.12.0/24 --accept-routes=false
```

**Don't forget:** Approve subnet route in admin console: https://login.tailscale.com/admin → Settings → Subnets

---

## 📱 Client Installation

### Mac
```bash
brew install tailscale
sudo tailscale up
```

### Windows
1. Download: https://tailscale.com/download/windows
2. Install and launch
3. Click "Log in"

### Android
1. Install from Google Play Store
2. Open app → Sign in
3. Toggle connection ON

### iOS
1. Install from App Store
2. Open app → Sign in
3. Toggle connection ON
4. Allow VPN permission

---

## 🔍 Common Commands

### Server (Oslik)

```bash
# Check status
sudo tailscale status

# View Tailscale IP
sudo tailscale ip -4

# Restart service
sudo systemctl restart tailscaled

# View logs
sudo journalctl -u tailscaled -f

# Disconnect
sudo tailscale down

# Reconnect
sudo tailscale up --advertise-routes=10.11.12.0/24
```

### Clients

```bash
# Check status (Mac/Linux)
tailscale status

# Check IP
tailscale ip -4

# Ping home network
ping 10.11.12.100

# Test Home Assistant
curl http://10.11.12.100:8123
```

---

## 🧪 Testing Checklist

- [ ] Tailscale connected on all devices
- [ ] Can ping Oslik Tailscale IP (100.x.x.x)
- [ ] Can ping Oslik local IP (10.11.12.100)
- [ ] Can access Home Assistant (http://10.11.12.100:8123)
- [ ] Can SSH to Oslik
- [ ] Works from different network locations

---

## 🐛 Troubleshooting

### Cannot access home network

```bash
# 1. Check subnet route is approved
# Go to: https://login.tailscale.com/admin → Settings → Subnets

# 2. Verify IP forwarding
sysctl net.ipv4.ip_forward
# Should output: net.ipv4.ip_forward = 1

# 3. Check Tailscale status
sudo tailscale status

# 4. Restart Tailscale
sudo systemctl restart tailscaled
```

### High latency

```bash
# Check connection type in admin console
# Should show "Direct" for best performance

# Reconnect
sudo tailscale down && sudo tailscale up --advertise-routes=10.11.12.0/24
```

### Client won't connect

1. Verify authentication completed
2. Check device is approved in admin console
3. Restart Tailscale client
4. Check firewall isn't blocking

---

## 🔗 Useful Links

- **Admin Console:** https://login.tailscale.com/admin
- **Documentation:** https://tailscale.com/kb/
- **Download:** https://tailscale.com/download
- **Status Page:** https://status.tailscale.com

---

## 📞 Support

- **Community:** https://github.com/tailscale/tailscale/discussions
- **Docs:** https://tailscale.com/kb/

---

**Quick Reference Version:** 1.0  
**Last Updated:** December 2024
