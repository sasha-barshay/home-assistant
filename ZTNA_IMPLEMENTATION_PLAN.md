# ZTNA Implementation Plan for Oslik Server

## 📋 Executive Summary

This document outlines the implementation plan for a Zero Trust Network Access (ZTNA) solution on the Oslik server (`10.11.12.100`) to enable secure remote access to the home network from Mac, Android, Windows, and iOS devices.

**Target Server:** Oslik (`10.11.12.100`)  
**Network:** `10.11.12.0/24`  
**OS:** Ubuntu 24.04.3 LTS  
**Current Access:** SSH (key-based authentication)

---

## 🎯 Solution Selection

### Recommended Solution: **Tailscale**

**Why Tailscale:**
- ✅ **Free tier:** Up to 100 devices, 3 users
- ✅ **Cross-platform:** Native clients for Mac, Windows, Linux, Android, iOS
- ✅ **Zero-config VPN:** Automatic mesh networking
- ✅ **Easy setup:** Minimal configuration required
- ✅ **Well-maintained:** Active development, regular updates
- ✅ **Built on WireGuard:** Modern, fast, secure protocol
- ✅ **No port forwarding:** Works behind NAT/firewalls
- ✅ **Access control:** Built-in ACLs and policies

**Alternative: Headscale (Self-Hosted)**
- Fully self-hosted Tailscale control server
- No device/user limits
- Requires more setup and maintenance
- Recommended if you want complete control and no external dependencies

**Other Considered Options:**
- **ZeroTier:** Good alternative, but Tailscale has better UX
- **Netmaker:** Self-hosted WireGuard management, more complex setup
- **WireGuard (manual):** Requires manual configuration, no centralized management

---

## 🏗️ Architecture Overview

### Network Topology

```
Internet
   │
   ├─ Tailscale Network (100.x.x.x/7)
   │   │
   │   ├─ Oslik Server (Tailscale IP: 100.x.x.x)
   │   │   └─ Home Assistant (10.11.12.100:8123)
   │   │   └─ MQTT Broker (10.11.12.100:1883)
   │   │   └─ Other Services
   │   │
   │   ├─ Mac Client (Tailscale IP: 100.x.x.x)
   │   ├─ Windows Client (Tailscale IP: 100.x.x.x)
   │   ├─ Android Client (Tailscale IP: 100.x.x.x)
   │   └─ iOS Client (Tailscale IP: 100.x.x.x)
   │
   └─ Local Network (10.11.12.0/24)
       └─ Oslik Server (10.11.12.100)
```

### Key Components

1. **Tailscale Daemon on Oslik**
   - Runs as systemd service or Docker container
   - Creates secure tunnel to Tailscale network
   - Provides access to local network resources

2. **Tailscale Clients**
   - Native apps on Mac, Windows, Android, iOS
   - Automatic connection to Tailscale network
   - Seamless access to Oslik services

3. **Subnet Router (Optional)**
   - Allows access to entire `10.11.12.0/24` network
   - Can be enabled on Oslik if needed
   - Requires admin approval in Tailscale console

---

## 📝 Implementation Steps

### Phase 1: Server Setup (Oslik)

#### Step 1.1: Install Tailscale on Oslik

```bash
# SSH to Oslik server
ssh -i ~/.ssh/oslik_rsa chief@10.11.12.100

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start and enable Tailscale
sudo systemctl enable --now tailscaled

# Check status
sudo tailscale status
```

#### Step 1.2: Authenticate Oslik Server

```bash
# Authenticate with Tailscale account
sudo tailscale up

# This will provide a URL to authenticate via web browser
# Copy the URL and open in browser, then authenticate
```

**Note:** You'll need to create a Tailscale account (free) at https://login.tailscale.com if you don't have one.

#### Step 1.3: Verify Installation

```bash
# Check Tailscale status
sudo tailscale status

# Get Tailscale IP address
sudo tailscale ip -4

# Test connectivity
ping $(sudo tailscale ip -4)
```

#### Step 1.4: Configure Subnet Router (Optional)

If you want to access the entire `10.11.12.0/24` network (not just Oslik):

```bash
# Enable subnet routing
sudo tailscale up --advertise-routes=10.11.12.0/24

# Then approve in Tailscale admin console:
# https://login.tailscale.com/admin/machines
# Find Oslik machine → Edit → Enable subnet routes
```

#### Step 1.5: Configure Firewall Rules (if needed)

```bash
# Allow Tailscale traffic (usually not needed, but verify)
sudo ufw allow 41641/udp  # Tailscale port
sudo ufw allow 41642/udp  # Tailscale port (DERP)

# Check firewall status
sudo ufw status
```

### Phase 2: Client Setup

#### Step 2.1: Mac Setup

1. **Install Tailscale:**
   ```bash
   # Using Homebrew
   brew install tailscale
   
   # Or download from: https://tailscale.com/download
   ```

2. **Start Tailscale:**
   ```bash
   sudo tailscaled
   tailscale up
   ```

3. **Authenticate:**
   - Open browser and authenticate with same Tailscale account
   - Mac will appear in Tailscale network

4. **Access Oslik:**
   ```bash
   # Get Oslik's Tailscale IP
   tailscale status
   
   # Access Home Assistant
   # http://<oslik-tailscale-ip>:8123
   # Or use local IP if subnet routing enabled: http://10.11.12.100:8123
   ```

#### Step 2.2: Windows Setup

1. **Install Tailscale:**
   - Download from: https://tailscale.com/download/windows
   - Run installer

2. **Connect:**
   - Open Tailscale app
   - Click "Log in"
   - Authenticate with Tailscale account

3. **Access Oslik:**
   - Open browser: `http://<oslik-tailscale-ip>:8123`
   - Or use local IP if subnet routing: `http://10.11.12.100:8123`

#### Step 2.3: Android Setup

1. **Install Tailscale:**
   - Download from Google Play Store: https://play.google.com/store/apps/details?id=com.tailscale.ipn
   - Or download APK from: https://tailscale.com/download/android

2. **Connect:**
   - Open Tailscale app
   - Tap "Sign in"
   - Authenticate with Tailscale account

3. **Access Oslik:**
   - Use browser or Home Assistant mobile app
   - URL: `http://<oslik-tailscale-ip>:8123`
   - Or local IP: `http://10.11.12.100:8123`

#### Step 2.4: iOS Setup

1. **Install Tailscale:**
   - Download from App Store: https://apps.apple.com/app/tailscale/id1470499037

2. **Connect:**
   - Open Tailscale app
   - Tap "Sign in"
   - Authenticate with Tailscale account
   - Allow VPN configuration when prompted

3. **Access Oslik:**
   - Use browser or Home Assistant mobile app
   - URL: `http://<oslik-tailscale-ip>:8123`
   - Or local IP: `http://10.11.12.100:8123`

### Phase 3: Configuration & Optimization

#### Step 3.1: Access Control Lists (ACLs)

Configure in Tailscale admin console: https://login.tailscale.com/admin/acls

**Example ACL (allow all devices to access Oslik):**
```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["autogroup:members"],
      "dst": ["oslik:80,443,8123,1883"]
    }
  ]
}
```

**More restrictive ACL (specific users only):**
```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["user:your-email@example.com"],
      "dst": ["oslik:8123,1883"]
    }
  ]
}
```

#### Step 3.2: Device Naming

In Tailscale admin console, rename devices for easier identification:
- Oslik server: `oslik` or `oslik-server`
- Mac: `macbook` or `mac-<username>`
- Windows: `windows-<username>`
- Android: `android-<username>`
- iOS: `iphone-<username>`

#### Step 3.3: Enable MagicDNS (Recommended)

MagicDNS provides friendly hostnames:
- Access via: `http://oslik:8123` instead of IP address
- Enable in Tailscale admin console: Settings → MagicDNS → Enable

#### Step 3.4: Configure Home Assistant for Remote Access

Update Home Assistant configuration to allow Tailscale network:

```yaml
# configuration.yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 100.0.0.0/8  # Tailscale network range
    - 10.11.12.0/24  # Local network
```

### Phase 4: Testing & Validation

#### Step 4.1: Connectivity Tests

From each client device:

```bash
# Test ping to Oslik
ping <oslik-tailscale-ip>

# Test HTTP access
curl http://<oslik-tailscale-ip>:8123

# Test from Mac/Windows/Linux
tailscale status
tailscale ping oslik
```

#### Step 4.2: Service Access Tests

1. **Home Assistant:**
   - Open browser: `http://<oslik-tailscale-ip>:8123`
   - Verify login works
   - Test API calls

2. **MQTT Broker:**
   - Test MQTT connection from remote device
   - Use MQTT client with Oslik's Tailscale IP

3. **SSH (if needed):**
   ```bash
   ssh chief@<oslik-tailscale-ip>
   ```

#### Step 4.3: Performance Tests

```bash
# Test latency
ping <oslik-tailscale-ip>

# Test bandwidth (if iperf3 installed)
# On Oslik: iperf3 -s
# On client: iperf3 -c <oslik-tailscale-ip>
```

### Phase 5: Security Hardening

#### Step 5.1: Enable Key Expiry

In Tailscale admin console:
- Settings → Keys → Enable key expiry
- Set expiration (e.g., 90 days)

#### Step 5.2: Enable 2FA

- Settings → Account → Enable two-factor authentication
- Use authenticator app (Google Authenticator, Authy, etc.)

#### Step 5.3: Review Access Logs

- Monitor access in Tailscale admin console
- Review: https://login.tailscale.com/admin/logs

#### Step 5.4: Restrict Subnet Access (if enabled)

If subnet routing is enabled, restrict which devices can access it:
- Admin console → Machines → Oslik → Edit
- Configure subnet route access

---

## 🔄 Alternative: Headscale (Self-Hosted)

If you prefer a fully self-hosted solution without external dependencies:

### Headscale Setup

#### Step 1: Install Headscale on Oslik

```bash
# Create directory
sudo mkdir -p /opt/headscale
cd /opt/headscale

# Download Headscale
wget https://github.com/juanfont/headscale/releases/latest/download/headscale_linux_amd64
sudo mv headscale_linux_amd64 /usr/local/bin/headscale
sudo chmod +x /usr/local/bin/headscale

# Create config directory
sudo mkdir -p /etc/headscale
```

#### Step 2: Configure Headscale

```bash
# Generate config
sudo headscale generate config

# Edit config: /etc/headscale/config.yaml
# Set server_url, listen_addr, etc.
```

#### Step 3: Run Headscale

```bash
# Create systemd service
sudo nano /etc/systemd/system/headscale.service
```

Service file:
```ini
[Unit]
Description=headscale controller
After=syslog.target
After=network.target

[Service]
Type=simple
User=headscale
Group=headscale
ExecStart=/usr/local/bin/headscale serve
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
# Start service
sudo systemctl enable --now headscale
```

#### Step 4: Configure Tailscale Clients

Clients connect to Headscale instead of Tailscale:

```bash
# On Oslik
sudo tailscale up --login-server=https://headscale.yourdomain.com

# On clients (same command)
tailscale up --login-server=https://headscale.yourdomain.com
```

**Note:** Headscale requires:
- Domain name with DNS pointing to Oslik
- SSL certificate (Let's Encrypt recommended)
- More complex setup and maintenance

---

## 📊 Comparison: Tailscale vs Headscale

| Feature | Tailscale | Headscale |
|---------|-----------|-----------|
| **Setup Complexity** | ⭐ Easy | ⭐⭐⭐ Complex |
| **Maintenance** | ⭐ Minimal | ⭐⭐⭐ Regular updates needed |
| **Device Limits** | 100 devices (free) | Unlimited |
| **User Limits** | 3 users (free) | Unlimited |
| **External Dependencies** | Yes (Tailscale servers) | No (fully self-hosted) |
| **Cost** | Free (up to limits) | Free (unlimited) |
| **Support** | Official support | Community support |
| **Recommended For** | Most users | Advanced users, privacy-focused |

**Recommendation:** Start with Tailscale. Migrate to Headscale only if you need unlimited devices/users or want complete self-hosting.

---

## 🛠️ Maintenance & Operations

### Regular Tasks

1. **Update Tailscale:**
   ```bash
   # On Oslik
   sudo apt update && sudo apt upgrade tailscale
   
   # Or re-run install script
   curl -fsSL https://tailscale.com/install.sh | sh
   ```

2. **Monitor Status:**
   ```bash
   sudo tailscale status
   sudo systemctl status tailscaled
   ```

3. **View Logs:**
   ```bash
   sudo journalctl -u tailscaled -f
   ```

4. **Restart Service (if needed):**
   ```bash
   sudo systemctl restart tailscaled
   ```

### Troubleshooting

**Issue: Can't connect to Oslik from client**
- Check Tailscale status on both devices
- Verify both devices are authenticated
- Check ACLs in admin console
- Verify firewall rules

**Issue: High latency**
- Check internet connection on both ends
- Tailscale will use direct connection if possible
- Check DERP relay status in admin console

**Issue: Service not accessible**
- Verify service is running on Oslik
- Check if service binds to correct interface
- Verify Tailscale IP is correct

---

## 📋 Implementation Checklist

### Server Setup (Oslik)
- [ ] Install Tailscale on Oslik
- [ ] Authenticate Oslik with Tailscale account
- [ ] Verify Tailscale IP address
- [ ] (Optional) Enable subnet routing
- [ ] Configure firewall rules
- [ ] Test connectivity from Oslik

### Client Setup
- [ ] Install Tailscale on Mac
- [ ] Install Tailscale on Windows
- [ ] Install Tailscale on Android
- [ ] Install Tailscale on iOS
- [ ] Authenticate all clients
- [ ] Verify all devices appear in network

### Configuration
- [ ] Configure ACLs in admin console
- [ ] Rename devices for clarity
- [ ] Enable MagicDNS (optional)
- [ ] Update Home Assistant config for Tailscale network
- [ ] Configure access policies

### Testing
- [ ] Test connectivity from all clients
- [ ] Test Home Assistant access from all clients
- [ ] Test MQTT access (if needed)
- [ ] Test SSH access (if needed)
- [ ] Verify performance/latency

### Security
- [ ] Enable 2FA on Tailscale account
- [ ] Configure key expiry
- [ ] Review and restrict ACLs
- [ ] Monitor access logs
- [ ] Document access procedures

---

## 🎯 Success Criteria

Implementation is successful when:
1. ✅ All devices (Mac, Windows, Android, iOS) can connect to Tailscale network
2. ✅ All devices can access Home Assistant at `http://<oslik-ip>:8123`
3. ✅ All devices can access other Oslik services as needed
4. ✅ Connection is stable and performs well
5. ✅ Security measures are in place (2FA, ACLs, key expiry)
6. ✅ Documentation is complete and accessible

---

## 📚 Additional Resources

- **Tailscale Documentation:** https://tailscale.com/kb/
- **Tailscale Admin Console:** https://login.tailscale.com/admin
- **Headscale Documentation:** https://headscale.net/
- **WireGuard Protocol:** https://www.wireguard.com/protocol/

---

## 🔐 Security Considerations

1. **Authentication:** Use strong Tailscale account password + 2FA
2. **ACLs:** Restrict access to only necessary services and users
3. **Key Management:** Enable key expiry and rotate regularly
4. **Monitoring:** Regularly review access logs
5. **Updates:** Keep Tailscale updated on all devices
6. **Network Isolation:** Consider separate Tailscale network for sensitive services

---

**Last Updated:** December 2024  
**Status:** 📋 Planning Phase  
**Next Steps:** Begin Phase 1 implementation
