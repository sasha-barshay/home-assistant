# ZTNA Implementation Plan for Remote Access

## 📋 Executive Summary

This document outlines the implementation plan for a Zero Trust Network Access (ZTNA) solution on the Oslik server to enable secure remote access to the home network from Mac, Android, Windows, and iOS devices.

**Server:** Oslik (`10.11.12.100`)  
**Network:** `10.11.12.0/24`  
**Solution:** Tailscale (Free Tier)  
**Status:** 📝 Planning Phase

---

## 🎯 Objectives

1. Enable secure remote access to home network resources from anywhere
2. Support multiple platforms: Mac, Android, Windows, iOS
3. Implement Zero Trust security model (no implicit trust)
4. Use a well-known, free, and reliable solution
5. Minimal configuration and maintenance overhead
6. No requirement to open ports on router/firewall

---

## 🔍 Solution Selection: Tailscale

### Why Tailscale?

**Tailscale** is selected as the ZTNA solution because:

✅ **Well-Known & Trusted:** Used by millions, backed by Tailscale Inc.  
✅ **Free Tier:** Up to 100 devices/users, perfect for home use  
✅ **Cross-Platform:** Native apps for Mac, Windows, Linux, Android, iOS  
✅ **Zero Trust:** Built-in Zero Trust architecture  
✅ **Easy Setup:** Minimal configuration required  
✅ **NAT Traversal:** Works behind firewalls without port forwarding  
✅ **Mesh VPN:** Direct peer-to-peer connections when possible  
✅ **Subnet Routing:** Can expose entire home network subnet  
✅ **ACLs:** Fine-grained access control lists  
✅ **MagicDNS:** Automatic DNS resolution for devices  

### Alternatives Considered

| Solution | Pros | Cons | Decision |
|----------|------|------|----------|
| **Tailscale** | Easy setup, great UX, free tier | Requires Tailscale account | ✅ **Selected** |
| ZeroTier | Open source, mesh VPN | More complex setup, less polished | ❌ |
| WireGuard | Open source, fast | Manual config, no built-in management | ❌ |
| Headscale | Self-hosted Tailscale | Requires self-hosting infrastructure | ❌ |

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet / Public Network                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Tailscale Encrypted Tunnel
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼──────┐   ┌────────▼────────┐  ┌──────▼──────┐
│   Mac Client │   │ Android Client  │  │ Windows/iOS │
│  (Tailscale) │   │   (Tailscale)   │  │  (Tailscale)│
└──────────────┘   └─────────────────┘  └─────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                            │ Tailscale Network (100.x.x.x)
                            │
        ┌───────────────────▼───────────────────┐
        │         Oslik Server (Subnet Router)   │
        │         IP: 10.11.12.100              │
        │         Tailscale IP: 100.x.x.x       │
        └───────────────────┬───────────────────┘
                            │
                            │ Local Network Access
                            │
        ┌───────────────────▼───────────────────┐
        │      Home Network (10.11.12.0/24)     │
        │                                       │
        │  ┌──────────────┐  ┌──────────────┐  │
        │  │ Home         │  │ Other        │  │
        │  │ Assistant    │  │ Devices      │  │
        │  │ :8123        │  │              │  │
        │  └──────────────┘  └──────────────┘  │
        └───────────────────────────────────────┘
```

### Network Architecture Details

1. **Tailscale Network:** Creates a virtual network (typically `100.x.x.x/10`)
2. **Subnet Router:** Oslik server acts as subnet router to expose `10.11.12.0/24`
3. **Direct Connections:** Tailscale uses NAT traversal for direct P2P when possible
4. **Relay Fallback:** Uses DERP (Distributed Encrypted Relay Protocol) servers when direct connection fails
5. **Encryption:** All traffic encrypted with WireGuard protocol

---

## 📋 Implementation Steps

### Phase 1: Server Setup (Oslik)

#### Step 1.1: Install Tailscale on Oslik Server

```bash
# SSH to Oslik server
ssh user@10.11.12.100

# Install Tailscale (Ubuntu/Debian)
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale service
sudo tailscale up

# Note: This will provide a URL to authenticate
# Save this URL for authentication
```

#### Step 1.2: Authenticate and Configure Subnet Router

```bash
# After authentication, enable subnet routing
sudo tailscale up --advertise-routes=10.11.12.0/24 --accept-routes=false

# Verify status
sudo tailscale status

# Check IP assignment
sudo tailscale ip -4
```

#### Step 1.3: Enable IP Forwarding (Permanent)

```bash
# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf

# Apply immediately
sudo sysctl -p

# Verify
sysctl net.ipv4.ip_forward
# Should output: net.ipv4.ip_forward = 1
```

#### Step 1.4: Configure Firewall Rules (if using UFW)

```bash
# Allow Tailscale interface
sudo ufw allow in on tailscale0
sudo ufw allow out on tailscale0

# Allow forwarding between interfaces
sudo ufw route allow in on tailscale0 out on eth0
sudo ufw route allow in on eth0 out on tailscale0

# Reload firewall
sudo ufw reload
```

#### Step 1.5: Verify Subnet Router Status

```bash
# Check Tailscale status
sudo tailscale status

# Should show:
# - Your server with Tailscale IP
# - Subnet routes advertised: 10.11.12.0/24

# Test connectivity
ping 10.11.12.100  # Should work from Tailscale network
```

---

### Phase 2: Admin Console Configuration

#### Step 2.1: Access Tailscale Admin Console

1. Go to https://login.tailscale.com/admin
2. Log in with your Tailscale account
3. Navigate to **Machines** → Find Oslik server

#### Step 2.2: Approve Subnet Routes

1. Go to **Settings** → **Subnets**
2. Find the route `10.11.12.0/24` advertised by Oslik
3. Click **Enable** to approve the route
4. This allows Tailscale clients to access the home network

#### Step 2.3: Configure Access Control Lists (ACLs) - Optional

Create ACL rules in **Settings** → **Access Controls**:

```json
{
  "groups": {
    "group:family": ["user@example.com"],
  },
  "hosts": {
    "oslik": "100.x.x.x",
  },
  "acls": [
    {
      "action": "accept",
      "src": ["group:family"],
      "dst": ["10.11.12.0/24:*"],
    },
    {
      "action": "accept",
      "src": ["group:family"],
      "dst": ["oslik:*"],
    },
  ],
}
```

This restricts access to family group members only.

---

### Phase 3: Client Installation & Configuration

#### Step 3.1: Mac Installation

1. **Download Tailscale:**
   ```bash
   # Option 1: Homebrew
   brew install tailscale
   
   # Option 2: Download from https://tailscale.com/download
   ```

2. **Start Tailscale:**
   ```bash
   sudo tailscale up
   ```

3. **Authenticate:** Follow the URL provided to authenticate

4. **Verify Connection:**
   ```bash
   tailscale status
   ping 10.11.12.100
   ```

#### Step 3.2: Windows Installation

1. **Download:** Go to https://tailscale.com/download/windows
2. **Install:** Run the installer
3. **Start:** Launch Tailscale from Start Menu
4. **Authenticate:** Click "Log in" and follow authentication flow
5. **Verify:** Open PowerShell:
   ```powershell
   tailscale status
   ping 10.11.12.100
   ```

#### Step 3.3: Android Installation

1. **Install:** Download Tailscale from Google Play Store
2. **Open App:** Launch Tailscale
3. **Sign In:** Tap "Sign in" and authenticate
4. **Connect:** Toggle the switch to connect
5. **Verify:** Use a network tool app to ping `10.11.12.100`

#### Step 3.4: iOS Installation

1. **Install:** Download Tailscale from App Store
2. **Open App:** Launch Tailscale
3. **Sign In:** Tap "Sign in" and authenticate
4. **Connect:** Toggle the switch to connect
5. **Allow VPN:** Grant VPN permission when prompted
6. **Verify:** Use a network tool app to ping `10.11.12.100`

---

### Phase 4: Testing & Validation

#### Step 4.1: Connectivity Tests

From each client device, test:

```bash
# Test Tailscale connectivity
ping 100.x.x.x  # Oslik Tailscale IP

# Test home network access
ping 10.11.12.100  # Oslik local IP
ping 10.11.12.1    # Router/Gateway (if applicable)

# Test Home Assistant access
curl http://10.11.12.100:8123
# Or open in browser: http://10.11.12.100:8123
```

#### Step 4.2: Service Access Tests

Test access to specific services:

```bash
# Home Assistant Web UI
# Browser: http://10.11.12.100:8123

# MQTT (if needed)
# Port 1883 should be accessible

# SSH to Oslik
ssh user@10.11.12.100
```

#### Step 4.3: Performance Tests

```bash
# Test latency
ping -c 10 10.11.12.100

# Test bandwidth (if iperf3 installed)
# On Oslik: iperf3 -s
# On client: iperf3 -c 10.11.12.100
```

---

## 🔒 Security Considerations

### 1. Access Control

- **ACLs:** Use Access Control Lists to restrict who can access the subnet
- **Device Approval:** Require device approval in admin console
- **Key Expiry:** Set key expiry for additional security
- **2FA:** Enable two-factor authentication on Tailscale account

### 2. Network Segmentation

- **Subnet Isolation:** Only expose necessary subnets
- **Service Filtering:** Use firewall rules to restrict access to specific ports
- **Device Groups:** Organize devices into groups for easier management

### 3. Monitoring

- **Admin Console:** Regularly check connected devices
- **Logs:** Monitor Tailscale logs for suspicious activity
- **Alerts:** Set up alerts for new device connections (if available)

### 4. Best Practices

- ✅ Keep Tailscale client updated on all devices
- ✅ Use strong authentication (2FA enabled)
- ✅ Regularly review ACL rules
- ✅ Remove unused devices from network
- ✅ Monitor for unauthorized access
- ✅ Use separate accounts for different users (if needed)

---

## 🛠️ Maintenance & Operations

### Daily Operations

- **Monitor Status:** Check Tailscale status on server
  ```bash
  sudo tailscale status
  ```

### Weekly Maintenance

- **Review Devices:** Check admin console for connected devices
- **Update Clients:** Ensure all clients are up to date
- **Review Logs:** Check for any connection issues

### Monthly Maintenance

- **Security Review:** Review ACL rules and access permissions
- **Device Cleanup:** Remove unused devices
- **Performance Review:** Check connection speeds and latency

### Troubleshooting Commands

```bash
# Check Tailscale status
sudo tailscale status

# View Tailscale logs
sudo journalctl -u tailscaled -f

# Restart Tailscale service
sudo systemctl restart tailscaled

# Check IP forwarding
sysctl net.ipv4.ip_forward

# Test connectivity
ping 10.11.12.100
traceroute 10.11.12.100

# Check routing table
ip route show
```

---

## 📊 Expected Outcomes

### Success Criteria

✅ Remote access to Home Assistant from all platforms  
✅ Access to entire home network (10.11.12.0/24)  
✅ Low latency connections (< 50ms typical)  
✅ Automatic reconnection on network changes  
✅ No router configuration required  
✅ Secure encrypted connections  

### Performance Expectations

- **Latency:** 20-100ms depending on location
- **Bandwidth:** Limited by internet connection speeds
- **Reliability:** 99.9% uptime (Tailscale infrastructure)
- **Connection Time:** < 5 seconds to establish connection

---

## 🚨 Troubleshooting Guide

### Issue: Cannot Access Home Network

**Symptoms:** Tailscale connected but can't ping 10.11.12.x

**Solutions:**
1. Verify subnet route is approved in admin console
2. Check IP forwarding is enabled: `sysctl net.ipv4.ip_forward`
3. Verify firewall rules allow forwarding
4. Check Tailscale status: `sudo tailscale status`
5. Restart Tailscale: `sudo systemctl restart tailscaled`

### Issue: High Latency

**Symptoms:** Slow connection, high ping times

**Solutions:**
1. Check direct connection status in admin console
2. Verify NAT traversal is working
3. Check internet connection speeds
4. Try reconnecting: `sudo tailscale down && sudo tailscale up`

### Issue: Client Cannot Connect

**Symptoms:** Client app shows disconnected

**Solutions:**
1. Verify authentication completed successfully
2. Check device is approved in admin console
3. Restart Tailscale client
4. Check for firewall blocking Tailscale
5. Verify internet connectivity

### Issue: Subnet Route Not Working

**Symptoms:** Can ping Oslik Tailscale IP but not local IPs

**Solutions:**
1. Verify route is advertised: `sudo tailscale status`
2. Check route is approved in admin console
3. Verify IP forwarding: `sysctl net.ipv4.ip_forward`
4. Check firewall rules for forwarding
5. Restart Tailscale service

---

## 📚 Additional Resources

### Official Documentation

- **Tailscale Docs:** https://tailscale.com/kb/
- **Subnet Routing:** https://tailscale.com/kb/1019/subnets
- **ACLs:** https://tailscale.com/kb/1018/acls
- **Troubleshooting:** https://tailscale.com/kb/1082/cli

### Community Resources

- **Tailscale Community:** https://github.com/tailscale/tailscale/discussions
- **Reddit:** r/Tailscale

### Support

- **Free Tier Support:** Community forums
- **Paid Support:** Available with Tailscale Business plan

---

## 📝 Implementation Checklist

### Server Setup (Oslik)
- [ ] Install Tailscale on Oslik server
- [ ] Authenticate Tailscale
- [ ] Enable subnet routing (10.11.12.0/24)
- [ ] Enable IP forwarding
- [ ] Configure firewall rules
- [ ] Verify subnet route is approved in admin console

### Client Setup
- [ ] Install Tailscale on Mac
- [ ] Install Tailscale on Windows
- [ ] Install Tailscale on Android
- [ ] Install Tailscale on iOS
- [ ] Authenticate all clients
- [ ] Verify connectivity from all clients

### Testing
- [ ] Test Tailscale IP connectivity
- [ ] Test home network access (10.11.12.0/24)
- [ ] Test Home Assistant access
- [ ] Test SSH access to Oslik
- [ ] Test from different network locations
- [ ] Verify performance (latency, speed)

### Security
- [ ] Configure ACLs (if needed)
- [ ] Enable 2FA on Tailscale account
- [ ] Review device approvals
- [ ] Set up monitoring/alerts
- [ ] Document access procedures

### Documentation
- [ ] Document Tailscale IPs
- [ ] Document access procedures
- [ ] Create troubleshooting guide
- [ ] Update network documentation

---

## 🎯 Next Steps

1. **Review Plan:** Review this implementation plan
2. **Prepare:** Ensure Oslik server access and admin privileges
3. **Execute Phase 1:** Install and configure Tailscale on Oslik
4. **Execute Phase 2:** Configure admin console
5. **Execute Phase 3:** Install clients on all devices
6. **Execute Phase 4:** Test and validate
7. **Document:** Update project documentation with Tailscale details

---

**Document Version:** 1.0  
**Last Updated:** December 2024  
**Status:** 📝 Ready for Implementation  
**Estimated Implementation Time:** 2-3 hours
