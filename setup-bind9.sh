#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIND_DIR="/etc/bind"
ZONES_DIR="$BIND_DIR/zones"
APPARMOR_FILE="/etc/apparmor.d/usr.sbin.named"

echo "[+] Starting BIND9 automated setup..."

# -------------------------
# Install BIND9 if missing
# -------------------------
if ! dpkg -l | grep -q "^ii  bind9 "; then
    echo "[+] Installing bind9..."
    sudo apt update
    sudo apt install -y bind9 bind9utils bind9-dnsutils apparmor-utils
else
    echo "[+] bind9 already installed"
fi

# -------------------------
# Detect primary interface IP
# -------------------------
DNS_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
NETWORK_PREFIX=$(echo "$DNS_IP" | awk -F. '{print $1"."$2"."$3}')
REVERSE_ZONE=$(echo "$DNS_IP" | awk -F. '{print $3"."$2"."$1}')
DNS_LAST=$(echo "$DNS_IP" | awk -F. '{print $4}')

echo "[+] DNS server IP: $DNS_IP"
echo "[+] Network: $NETWORK_PREFIX.0/24"
echo "[+] Reverse zone: $REVERSE_ZONE.in-addr.arpa"

# -------------------------
# Ask for target IPs
# -------------------------
read -rp "[?] Enter IP for target.labnet.local: " TARGET_IP
read -rp "[?] Enter IP for sliver.labnet.local: " SLIVER_IP

TARGET_LAST=$(echo "$TARGET_IP" | awk -F. '{print $4}')
SLIVER_LAST=$(echo "$SLIVER_IP" | awk -F. '{print $4}')

# -------------------------
# Prepare directories
# -------------------------
sudo mkdir -p "$ZONES_DIR"
sudo mkdir -p /var/log/bind
sudo chown bind:bind /var/log/bind

# -------------------------
# Copy template files
# -------------------------
echo "[+] Copying configuration files..."
sudo cp "$REPO_DIR/named.conf.options" "$BIND_DIR/"
sudo cp "$REPO_DIR/named.conf.local" "$BIND_DIR/"
sudo cp "$REPO_DIR/db.labnet.local" "$ZONES_DIR/"
sudo cp "$REPO_DIR/db.reverse.template" "$ZONES_DIR/db.$REVERSE_ZONE"

# -------------------------
# Replace placeholders
# -------------------------
echo "[+] Replacing placeholders..."

# named.conf.options
sudo sed -i "s/{{NETWORK_PREFIX}}/$NETWORK_PREFIX/g" "$BIND_DIR/named.conf.options"
sudo sed -i "s/{{DNS_IP}}/$DNS_IP/g" "$BIND_DIR/named.conf.options"

# named.conf.local
sudo sed -i "s/{{REVERSE_ZONE}}/$REVERSE_ZONE/g" "$BIND_DIR/named.conf.local"

# forward zone
sudo sed -i "s/{{DNS_IP}}/$DNS_IP/g" "$ZONES_DIR/db.labnet.local"
sudo sed -i "s/{{TARGET_IP}}/$TARGET_IP/g" "$ZONES_DIR/db.labnet.local"
sudo sed -i "s/{{SLIVER_IP}}/$SLIVER_IP/g" "$ZONES_DIR/db.labnet.local"

# reverse zone
sudo sed -i "s/{{DNS_LAST}}/$DNS_LAST/g" "$ZONES_DIR/db.$REVERSE_ZONE"
sudo sed -i "s/{{TARGET_LAST}}/$TARGET_LAST/g" "$ZONES_DIR/db.$REVERSE_ZONE"
sudo sed -i "s/{{SLIVER_LAST}}/$SLIVER_LAST/g" "$ZONES_DIR/db.$REVERSE_ZONE"

# -------------------------
# AppArmor update
# -------------------------
echo "[+] Updating AppArmor..."
if ! grep -q "HackScale bind9 lab logging" "$APPARMOR_FILE"; then
    cat "$REPO_DIR/usr.sbin.named" | sudo tee -a "$APPARMOR_FILE" > /dev/null
fi

sudo systemctl reload apparmor || true

# -------------------------
# Validate configs
# -------------------------
echo "[+] Validating configuration..."
sudo named-checkconf
sudo named-checkzone labnet.local "$ZONES_DIR/db.labnet.local"
sudo named-checkzone "$REVERSE_ZONE.in-addr.arpa" "$ZONES_DIR/db.$REVERSE_ZONE"

# -------------------------
# Restart bind9
# -------------------------
echo "[+] Restarting bind9..."
sudo systemctl restart bind9
sudo systemctl enable bind9

# -------------------------
# Test resolution
# -------------------------
echo "[+] Testing DNS records..."
dig @"$DNS_IP" target.labnet.local +short
dig @"$DNS_IP" sliver.labnet.local +short

echo "[+] Setup complete."
