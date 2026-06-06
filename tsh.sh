#!/bin/bash

# Tailscale SSH Setup Script for Ubuntu/Debian
# Run with: sudo bash setup-tailscale-ssh.sh

set -e  # exit on error

# --- Helper functions ---
print_green() {
    echo -e "\e[32m$1\e[0m"
}

print_red() {
    echo -e "\e[31m$1\e[0m"
}

print_yellow() {
    echo -e "\e[33m$1\e[0m"
}

# --- Check root ---
if [[ $EUID -ne 0 ]]; then
    print_red "This script must be run as root (use sudo)."
    exit 1
fi

# --- Check if Tailscale is already installed ---
if command -v tailscale &> /dev/null; then
    print_yellow "Tailscale is already installed."
    CURRENT_STATUS=$(tailscale status 2>/dev/null || echo "not connected")
    if [[ "$CURRENT_STATUS" != "not connected" ]]; then
        print_green "Tailscale is already connected. Current status:"
        tailscale status
        echo ""
        read -p "Do you want to re-run 'tailscale up --ssh' anyway? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_yellow "Skipping. Exiting."
            exit 0
        fi
    fi
fi

# --- Install Tailscale ---
print_green "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh -o /tmp/tailscale-install.sh
sh /tmp/tailscale-install.sh
rm /tmp/tailscale-install.sh

# --- Enable and start Tailscale with SSH ---
print_green "Starting Tailscale and enabling Tailscale SSH..."
tailscale up --ssh

# --- After tailscale up, it may require web authentication ---
print_green "\nTailscale is now set up."
echo "If you saw a URL above, open it in your browser and log in with your Tailscale account."
echo "After authentication, Tailscale will connect this machine to your tailnet."

# --- Wait a moment for connection to establish ---
sleep 3

# --- Retrieve Tailscale IP ---
TS_IP=$(tailscale ip 2>/dev/null || echo "Not connected yet")
if [[ "$TS_IP" == "Not connected yet" ]]; then
    print_yellow "Tailscale not yet connected. Please complete the web authentication."
    print_yellow "Run 'tailscale up --ssh' again after logging in, or wait a moment and re-run this script."
else
    print_green "========================================="
    print_green "Tailscale SSH is ready!"
    print_green "========================================="
    echo "Tailscale IP address of this machine: $TS_IP"
    echo ""
    echo "On your phone/computer, install the Tailscale app and log into the same account."
    echo "Then, in Termius:"
    echo "  - Host: $TS_IP"
    echo "  - Port: 22"
    echo "  - Username: $(logname 2>/dev/null || echo $SUDO_USER)"
    echo "  - Authentication: Use your system user's password or an SSH key."
    echo ""
    echo "If you want passwordless SSH via Tailscale's built-in SSH, ensure your Tailscale ACL allows it."
    echo "See: https://tailscale.com/kb/1193/tailscale-ssh"
fi

# --- Extra tip ---
print_yellow "\nTo check Tailscale status anytime: tailscale status"
print_yellow "To see your Tailscale IP: tailscale ip"
print_yellow "To disable Tailscale SSH later: tailscale up --ssh=false"
