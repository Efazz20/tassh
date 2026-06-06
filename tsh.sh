#!/bin/bash
# ==================================================
# Tailscale Setup for environments WITHOUT /dev/net/tun
# Uses userspace networking (no TUN, no iptables)
# ==================================================

set -e

print_green() { echo -e "\e[32m$1\e[0m"; }
print_red()   { echo -e "\e[31m$1\e[0m"; }

if [[ $EUID -ne 0 ]]; then
    print_red "Run with sudo."
    exit 1
fi

# 1. Install Tailscale
print_green "[*] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# 2. Ensure service is running (ignore TUN errors for now)
systemctl enable tailscaled 2>/dev/null || true
systemctl start tailscaled || true
sleep 2

# 3. Auth key input
print_green "[*] Paste your Tailscale Auth Key (will not be shown):"
read -s TS_AUTH_KEY

if [[ ! "$TS_AUTH_KEY" =~ ^tskey- ]]; then
    print_red "Invalid key format."
    exit 1
fi

# 4. Connect with userspace networking (no TUN/iptables needed)
print_green "[*] Connecting to Tailscale using userspace networking..."
tailscale up --authkey="$TS_AUTH_KEY" --tun=userspace-networking --ssh

unset TS_AUTH_KEY

# 5. Show success
print_green "========================================="
tailscale status
echo ""
print_green "Tailscale IP (userspace mode): $(tailscale ip)"
echo ""
print_green "In Termius, use:"
print_green "  Address: $(tailscale ip)"
print_green "  Port: 22"
print_green "  Username: $(logname 2>/dev/null || echo $SUDO_USER)"
