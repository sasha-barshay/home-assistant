#!/bin/bash

###############################################################################
# Tailscale ZTNA Setup Script for Oslik Server
# 
# This script automates the installation and configuration of Tailscale
# as a subnet router to enable remote access to the home network.
#
# Usage: sudo ./ztna_setup.sh
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SUBNET="10.11.12.0/24"
LOG_FILE="/var/log/tailscale_setup.log"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Check if Tailscale is already installed
check_existing() {
    if command -v tailscale &> /dev/null; then
        warning "Tailscale is already installed"
        read -p "Do you want to continue with configuration? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# Install Tailscale
install_tailscale() {
    log "Installing Tailscale..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    else
        error "Cannot detect OS version"
    fi
    
    case $OS in
        ubuntu|debian)
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        fedora|rhel|centos)
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        *)
            warning "Unsupported OS: $OS"
            info "Please install Tailscale manually from https://tailscale.com/download"
            exit 1
            ;;
    esac
    
    log "Tailscale installed successfully"
}

# Enable IP forwarding
enable_ip_forwarding() {
    log "Enabling IP forwarding..."
    
    # Check if already enabled
    if [[ $(sysctl -n net.ipv4.ip_forward) -eq 1 ]]; then
        info "IP forwarding already enabled"
    else
        # Enable temporarily
        sysctl -w net.ipv4.ip_forward=1
        
        # Enable permanently
        if ! grep -q "net.ipv4.ip_forward = 1" /etc/sysctl.conf; then
            echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
        fi
        
        if ! grep -q "net.ipv6.conf.all.forwarding = 1" /etc/sysctl.conf; then
            echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.conf
        fi
        
        log "IP forwarding enabled"
    fi
}

# Configure firewall (UFW)
configure_firewall() {
    if command -v ufw &> /dev/null; then
        log "Configuring UFW firewall rules..."
        
        # Check if UFW is active
        if ufw status | grep -q "Status: active"; then
            ufw allow in on tailscale0
            ufw allow out on tailscale0
            ufw route allow in on tailscale0 out on eth0
            ufw route allow in on eth0 out on tailscale0
            
            log "Firewall rules configured"
        else
            warning "UFW is not active, skipping firewall configuration"
        fi
    else
        info "UFW not found, skipping firewall configuration"
        info "If using another firewall, ensure Tailscale interface is allowed"
    fi
}

# Start Tailscale with subnet routing
start_tailscale() {
    log "Starting Tailscale..."
    
    # Check if already authenticated
    if tailscale status &> /dev/null; then
        info "Tailscale is already running"
        info "Current status:"
        tailscale status
        
        read -p "Do you want to reconfigure subnet routing? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    log "Starting Tailscale with subnet routing..."
    log "You will need to authenticate via the provided URL"
    
    tailscale up --advertise-routes="$SUBNET" --accept-routes=false
    
    log "Tailscale started with subnet routing"
    info "Subnet route: $SUBNET"
}

# Display status and next steps
display_status() {
    echo ""
    log "=== Setup Complete ==="
    echo ""
    
    info "Tailscale Status:"
    tailscale status
    echo ""
    
    info "Tailscale IP:"
    tailscale ip -4
    echo ""
    
    info "Subnet Route: $SUBNET"
    echo ""
    
    warning "IMPORTANT NEXT STEPS:"
    echo "1. Go to https://login.tailscale.com/admin"
    echo "2. Navigate to Settings → Subnets"
    echo "3. Find and APPROVE the route: $SUBNET"
    echo "4. Install Tailscale clients on your devices:"
    echo "   - Mac: brew install tailscale"
    echo "   - Windows: https://tailscale.com/download/windows"
    echo "   - Android: Google Play Store"
    echo "   - iOS: App Store"
    echo ""
    
    info "Test connectivity:"
    echo "  ping 10.11.12.100"
    echo "  curl http://10.11.12.100:8123"
    echo ""
}

# Main execution
main() {
    echo ""
    info "=========================================="
    info "  Tailscale ZTNA Setup for Oslik"
    info "=========================================="
    echo ""
    
    check_root
    check_existing
    
    install_tailscale
    enable_ip_forwarding
    configure_firewall
    start_tailscale
    display_status
    
    log "Setup completed successfully!"
    log "Log file: $LOG_FILE"
}

# Run main function
main "$@"
