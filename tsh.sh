#!/bin/bash
# ==================================================
# Tailscale Headless Setup for Ubuntu/Debian
# Usage: sudo bash setup-tailscale.sh
# ==================================================

set -e

# --- Helper function for colored output ---
print_green() {
    echo -e "\e[32m$1\e[0m"
}
print_red() {
    echo -e "\e[31m$1\e[0m"
}

# --- Root Check ---
if [[ $EUID -ne 0 ]]; then
    print_red "This script must be run as root. Please use: sudo bash setup-tailscale.sh"
    exit 1
fi

# --- 1. Install Tailscale ---
print_green "[*] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# --- 2. Securely Input the Auth Key ---
print_green "[*] Please paste your Tailscale Auth Key (will not be saved in history):"
print_green "    (Find it at https://login.tailscale.com/admin/settings/keys)"
# Read the auth key securely, without showing it on screen
read -s TS_AUTH_KEY

# Simple validation: check if the key looks like a Tailscale key (starts with 'tskey-')
if [[ ! "$TS_AUTH_KEY" =~ ^tskey- ]]; then
    print_red "Error: The provided key doesn't look like a valid Tailscale Auth Key."
    exit 1
fi

# --- 3. Start Tailscale with Auth Key and SSH ---
print_green "[*] Authenticating with Tailscale and enabling SSH..."
tailscale up --authkey="$TS_AUTH_KEY" --ssh

# Optional: Clear the variable from memory for safety
unset TS_AUTH_KEY

# --- 4. Ensure the tailscaled service is enabled and ready ---
systemctl enable tailscaled

# Wait a moment for the daemon to fully establish the connection
sleep 3

# --- 5. Final Status Check ---
print_green "[*] Setup complete!"
print_green "========================================="
tailscale status
echo ""
print_green "Your machine's Tailscale IP is: $(tailscale ip)"
echo ""
print_green "Now open Termius on your phone and create a new host with:"
print_green "  - Address: $(tailscale ip)"
print_green "  - Port: 22"
print_green "  - Username: $(logname 2>/dev/null || echo $SUDO_USER)"
