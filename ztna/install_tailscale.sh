#!/bin/bash

###############################################################################
# Tailscale Installation Script for Oslik Server
# 
# This script installs and configures Tailscale on the Oslik server
# to enable ZTNA (Zero Trust Network Access) for remote connections.
#
# Usage:
#   ./install_tailscale.sh
#
# Prerequisites:
#   - SSH access to Oslik server (10.11.12.100)
#   - SSH key: ~/.ssh/oslik_rsa
#   - Sudo access on Oslik server
###############################################################################

set -euo pipefail

# Configuration
OSLIK_HOST="10.11.12.100"
OSLIK_USER="chief"
SSH_KEY="$HOME/.ssh/oslik_rsa"
LOCAL_NETWORK="10.11.12.0/24"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check SSH key exists
    if [ ! -f "$SSH_KEY" ]; then
        log_error "SSH key not found: $SSH_KEY"
        log_info "Please ensure SSH key exists or update SSH_KEY variable"
        exit 1
    fi
    
    # Check SSH access
    if ! ssh -i "$SSH_KEY" -o ConnectTimeout=5 -o BatchMode=yes "$OSLIK_USER@$OSLIK_HOST" "echo 'Connection test'" > /dev/null 2>&1; then
        log_error "Cannot connect to Oslik server: $OSLIK_HOST"
        log_info "Please verify:"
        log_info "  1. Server is reachable: ping $OSLIK_HOST"
        log_info "  2. SSH service is running on Oslik"
        log_info "  3. SSH key has correct permissions: chmod 600 $SSH_KEY"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Install Tailscale
install_tailscale() {
    log_info "Installing Tailscale on Oslik..."
    
    ssh -i "$SSH_KEY" "$OSLIK_USER@$OSLIK_HOST" << 'EOF'
        set -euo pipefail
        
        # Check if Tailscale is already installed
        if command -v tailscale > /dev/null 2>&1; then
            echo "Tailscale is already installed"
            tailscale version
            exit 0
        fi
        
        # Install Tailscale
        curl -fsSL https://tailscale.com/install.sh | sh
        
        echo "Tailscale installed successfully"
EOF
    
    log_success "Tailscale installation completed"
}

# Start Tailscale service
start_tailscale_service() {
    log_info "Starting Tailscale service..."
    
    ssh -i "$SSH_KEY" "$OSLIK_USER@$OSLIK_HOST" << 'EOF'
        set -euo pipefail
        
        # Enable and start Tailscale service
        sudo systemctl enable --now tailscaled
        
        # Wait for service to start
        sleep 2
        
        # Check service status
        if sudo systemctl is-active --quiet tailscaled; then
            echo "Tailscale service is running"
        else
            echo "ERROR: Tailscale service failed to start"
            sudo systemctl status tailscaled
            exit 1
        fi
EOF
    
    log_success "Tailscale service started"
}

# Authenticate Tailscale
authenticate_tailscale() {
    log_info "Authenticating Tailscale..."
    log_warning "You will need to authenticate via web browser"
    
    # Get authentication URL
    AUTH_URL=$(ssh -i "$SSH_KEY" "$OSLIK_USER@$OSLIK_HOST" "sudo tailscale up --accept-routes=false 2>&1" | grep -oP 'https://[^\s]+' | head -1 || true)
    
    if [ -z "$AUTH_URL" ]; then
        log_warning "Could not extract auth URL automatically"
        log_info "Please run manually on Oslik:"
        log_info "  ssh -i $SSH_KEY $OSLIK_USER@$OSLIK_HOST"
        log_info "  sudo tailscale up"
        log_info "Then copy the authentication URL and open in browser"
        return 1
    fi
    
    log_info "Authentication URL: $AUTH_URL"
    log_info "Please open this URL in your browser and authenticate"
    log_info "Press Enter after authentication is complete..."
    read -r
    
    log_success "Tailscale authentication completed"
}

# Get Tailscale IP
get_tailscale_ip() {
    log_info "Getting Tailscale IP address..."
    
    TAILSCALE_IP=$(ssh -i "$SSH_KEY" "$OSLIK_USER@$OSLIK_HOST" "sudo tailscale ip -4" 2>/dev/null || echo "")
    
    if [ -z "$TAILSCALE_IP" ]; then
        log_warning "Could not get Tailscale IP. Device may not be authenticated yet."
        return 1
    fi
    
    log_success "Oslik Tailscale IP: $TAILSCALE_IP"
    echo ""
    log_info "Save this IP address - you'll need it to connect from clients"
    echo ""
    
    # Save to file
    echo "$TAILSCALE_IP" > tailscale_ip.txt
    log_info "IP address saved to: tailscale_ip.txt"
}

# Check Tailscale status
check_status() {
    log_info "Checking Tailscale status..."
    
    ssh -i "$SSH_KEY" "$OSLIK_USER@$OSLIK_HOST" << 'EOF'
        echo "=== Tailscale Status ==="
        sudo tailscale status
        echo ""
        echo "=== Service Status ==="
        sudo systemctl status tailscaled --no-pager -l
EOF
}

# Optional: Enable subnet routing
enable_subnet_routing() {
    log_info "Enabling subnet routing for $LOCAL_NETWORK..."
    log_warning "This will allow access to the entire $LOCAL_NETWORK network"
    log_info "You will need to approve this in Tailscale admin console"
    
    read -p "Enable subnet routing? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping subnet routing"
        return 0
    fi
    
    ssh -i "$SSH_KEY" "$OSLIK_USER@$OSLIK_HOST" "sudo tailscale up --advertise-routes=$LOCAL_NETWORK"
    
    log_success "Subnet routing enabled"
    log_warning "IMPORTANT: Approve subnet routes in Tailscale admin console:"
    log_info "  1. Go to: https://login.tailscale.com/admin/machines"
    log_info "  2. Find Oslik machine"
    log_info "  3. Click 'Edit' → Enable 'Subnet routes'"
    log_info "  4. Save"
}

# Main installation flow
main() {
    echo ""
    log_info "=========================================="
    log_info "Tailscale Installation for Oslik Server"
    log_info "=========================================="
    echo ""
    
    check_prerequisites
    install_tailscale
    start_tailscale_service
    
    echo ""
    log_info "Next step: Authentication"
    authenticate_tailscale
    
    get_tailscale_ip
    
    echo ""
    read -p "Enable subnet routing? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        enable_subnet_routing
    fi
    
    echo ""
    log_info "=========================================="
    log_success "Installation Summary"
    log_info "=========================================="
    check_status
    
    echo ""
    log_success "Tailscale installation completed!"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Install Tailscale clients on your devices (Mac, Windows, Android, iOS)"
    log_info "  2. Authenticate clients with same Tailscale account"
    log_info "  3. Access Home Assistant: http://<tailscale-ip>:8123"
    log_info ""
    log_info "See ZTNA_QUICK_START.md for client setup instructions"
    echo ""
}

# Run main function
main
