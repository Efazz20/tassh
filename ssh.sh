#!/bin/bash

# SSH Server Setup Script for Ubuntu/Debian
# Run with: sudo bash setup-ssh.sh

set -e  # exit on error

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)." 
   exit 1
fi

echo "Updating package list..."
apt update -qq

echo "Installing OpenSSH server..."
apt install openssh-server -y

echo "Ensuring SSH service is enabled and started..."
systemctl enable ssh
systemctl start ssh

# Configure firewall (ufw) if present
if command -v ufw &> /dev/null; then
    echo "UFW detected – allowing SSH..."
    ufw allow ssh
    ufw reload
fi

# Optional: allow SSH in firewalld (less common on Debian/Ubuntu)
if command -v firewall-cmd &> /dev/null; then
    echo "firewalld detected – allowing SSH..."
    firewall-cmd --add-service=ssh --permanent
    firewall-cmd --reload
fi

echo "SSH service status:"
systemctl status ssh --no-pager

# Display IP address(es)
echo -e "\n========================================="
echo "SSH server is now running on this machine."
echo "Use one of these IP addresses in Termius:"
echo "========================================="
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | while read ip; do
    echo "  $ip"
done

echo -e "\nDefault SSH port: 22"
echo "Login with your current username: $SUDO_USER (or the user you created)"
echo "Example Termius entry:"
echo "  Host: <IP from above>"
echo "  Port: 22"
echo "  Username: $SUDO_USER"
