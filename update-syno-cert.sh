#!/bin/bash

set -euo pipefail

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Exiting."
  exit 1
fi

# Load environment variables from .env files if present
ENV_DIR="/etc/local/syno-certs"
[ -f "$ENV_DIR/default.env" ] && source "$ENV_DIR/default.env"
[ -f "$ENV_DIR/$(hostname).env" ] && source "$ENV_DIR/$(hostname).env"

# Set defaults if not set by .env
EMAIL="${EMAIL:-admin@example.com}"
LEGO_PATH="${LEGO_PATH:-/usr/local/bin/lego}"
DATA_PATH="${DATA_PATH:-/etc/local/lego}"
DNS_PROVIDER="${DNS_PROVIDER:-route53}"
CERT_TMP="${CERT_TMP:-/tmp/syno_cert_update}"
SYNO_API="${SYNO_API:-/usr/syno/bin/synowebapi}"
DAYS_LEFT="${DAYS_LEFT:-30}"

# Try to renew the certificate
$LEGO_PATH --email "$EMAIL" --path "$DATA_PATH" --dns "$DNS_PROVIDER" --domains "$DOMAIN" renew --days "$DAYS_LEFT" --reuse-key --no-bundle --run-hook=false --no-random-sleep
RENEW_EXIT_CODE=$?

if [ "$RENEW_EXIT_CODE" -eq 0 ]; then
  # Check if any certificate was actually renewed
  if grep -q "No certificate needs to be renewed" "$DATA_PATH/.lego.log" 2>/dev/null; then
    echo "Certificate is still valid – skipping import."
    exit 0
  else
    echo "Certificate was renewed – proceeding with import."
  fi
else
  echo "Certificate does not exist or could not be renewed – requesting a new certificate."
  $LEGO_PATH --email "$EMAIL" --path "$DATA_PATH" --dns "$DNS_PROVIDER" --domains "$DOMAIN" run
fi

# Prepare certificate files
mkdir -p "$CERT_TMP"
cp "$DATA_PATH/certificates/$DOMAIN.crt" "$CERT_TMP/cert.pem"
cp "$DATA_PATH/certificates/$DOMAIN.key" "$CERT_TMP/privkey.pem"
cp "$DATA_PATH/certificates/$DOMAIN.issuer.crt" "$CERT_TMP/chain.pem"
cat "$CERT_TMP/cert.pem" "$CERT_TMP/chain.pem" > "$CERT_TMP/fullchain.pem"

# Find default certificate ID
DEFAULT_CERT_ID=$($SYNO_API --exec api=SYNO.Core.Certificate.CRT list | grep -B1 '"is_default":true' | grep '"id":' | awk -F: '{print $2}' | tr -d ', ')

if [ -z "$DEFAULT_CERT_ID" ]; then
  echo "Could not find default certificate ID!"
  rm -rf "$CERT_TMP"
  exit 2
fi

# Replace certificate using Synology API
$SYNO_API --exec api=SYNO.Core.Certificate.CRT import \
  id="$DEFAULT_CERT_ID" \
  cert="$CERT_TMP/cert.pem" \
  key="$CERT_TMP/privkey.pem" \
  intermediate="$CERT_TMP/chain.pem"

# Clean up
rm -rf "$CERT_TMP"

# Reload services
/usr/syno/sbin/synoservicectl --reload nginx

echo "Certificate for $DOMAIN has been updated via Synology API."

# Notes:
# - Place your .env files in $ENV_DIR (e.g. default.env, $(hostname).env)
# - Supported variables: DOMAIN, EMAIL, LEGO_PATH, DATA_PATH, DNS_PROVIDER, CERT_TMP, SYNO_API, DAYS_LEFT
# - Default DNS provider is route53. Change DNS_PROVIDER in .env if needed.
# - Make sure DNS credentials are available as required by your DNS provider plugin
# - Script requires administrator