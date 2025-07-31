#!/bin/bash

set -euo pipefail

# 1. Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This installer must be run as root. Exiting."
  exit 1
fi

# --- ASCII ART PLACEHOLDER ---
echo "======================================"
echo "   Synology Let's Encrypt Installer   "
echo "======================================"
echo

# Prompt for domain(s)
read -rp "Enter your domain(s) (comma separated, e.g. example.com,*.example.com): " DOMAIN_INPUT
read -rp "Enter your email address: " EMAIL_INPUT

# Prompt for AWS credentials
read -rp "Enter your AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
read -rp "Enter your AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
read -rp "Enter your AWS_REGION (e.g. eu-west-1): " AWS_REGION

# Create config directory
ENV_DIR="/etc/local/syno-certs"
mkdir -p "$ENV_DIR"
chmod 700 "$ENV_DIR"

# Write .env file
tee "$ENV_DIR/default.env" >/dev/null <<EOF
DOMAIN="$DOMAIN_INPUT"
EMAIL="$EMAIL_INPUT"
DNS_PROVIDER="route53"

AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
AWS_REGION="$AWS_REGION"
EOF

chmod 600 "$ENV_DIR/default.env"

# Install lego (latest release)
LEGO_BIN="/usr/local/bin/lego"
LEGO_URL=$(curl -s https://api.github.com/repos/go-acme/lego/releases/latest | grep "browser_download_url.*linux_amd64.tar.gz" | cut -d '"' -f 4)
TMP_DIR=$(mktemp -d)
echo "Downloading lego from $LEGO_URL ..."
wget -qO "$TMP_DIR/lego.tar.gz" "$LEGO_URL"
tar -xzf "$TMP_DIR/lego.tar.gz" -C "$TMP_DIR"
mv "$TMP_DIR/lego" "$LEGO_BIN"
chmod +x "$LEGO_BIN"
rm -rf "$TMP_DIR"
echo "lego installed to $LEGO_BIN"

# Download update_syno_cert.sh from GitHub
UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/bwilczynski/syno-certs/main/update_syno_cert.sh"
UPDATE_SCRIPT_BIN="/usr/local/bin/update_syno_cert.sh"
echo "Downloading update_syno_cert.sh from $UPDATE_SCRIPT_URL ..."
wget -qO "$UPDATE_SCRIPT_BIN" "$UPDATE_SCRIPT_URL"
chmod +x "$UPDATE_SCRIPT_BIN"
echo "update_syno_cert.sh installed to $UPDATE_SCRIPT_BIN"

echo
echo "======================================"
echo "Installation summary:"
echo "lego binary:           $LEGO_BIN"
echo "update script:         $UPDATE_SCRIPT_BIN"
echo "Configuration:         $ENV_DIR/default.env"
echo
echo "You can edit your configuration at:"
echo "  $ENV_DIR/default.env"
echo
echo "To automate certificate renewal, configure a scheduled task in DSM:"
echo "  Control Panel > Task Scheduler > Create > Scheduled Task > User-defined script"
echo "and use:"
echo "  DOMAIN=\"your.domain.com\" /usr/local/bin/update_syno_cert.sh"
echo
echo "Setup complete!"