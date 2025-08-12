#!/usr/bin/env bash
set -euo pipefail

# If launched from zsh, disable history expansion (the "!" issue)
[ -n "${ZSH_VERSION-}" ] && set +H

# --- Configuration ---
RESOURCE_GROUP="dtmgroup"
TEMPLATE_FILE="main.bicep"
ADMIN_USER="${ADMIN_USER:-dteimuno}"

# Get admin password: prefer env var ADMIN_PWD; otherwise prompt securely
if [ -z "${ADMIN_PWD-}" ]; then
  read -s -p "Enter admin password: " ADMIN_PWD
  echo
fi

# Quick sanity (length only, not the value)
echo "Admin password length: $(printf %s "$ADMIN_PWD" | wc -c)"

# Validate that files exist
[ -f "$TEMPLATE_FILE" ] || { echo "ERROR: $TEMPLATE_FILE not found in $(pwd)"; exit 1; }

# Create a temporary parameters file (auto-cleaned)
PARAMS_FILE="$(mktemp)"
trap 'rm -f "$PARAMS_FILE"' EXIT

cat > "$PARAMS_FILE" <<JSON
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "adminUsername": { "value": "%s" },
    "adminPassword": { "value": "%s" }
  }
}
JSON
# Use printf to safely substitute values
tmp="$(mktemp)"
printf "$(cat "$PARAMS_FILE")" "$ADMIN_USER" "$ADMIN_PWD" > "$tmp"
mv "$tmp" "$PARAMS_FILE"

# Validate (non-interactive)
az deployment group validate \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters @"$PARAMS_FILE"

# Deploy (non-interactive)
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters @"$PARAMS_FILE" \
  --only-show-errors
