#!/usr/bin/env bash
set -euo pipefail

# If you launch this from zsh, disable history expansion for safety (the "!" issue)
if [ -n "${ZSH_VERSION-}" ]; then
  set +H
fi

# Define the password (quoted; the ! is safe here)
ADMIN_PWD='Synchrony1998!'

# Sanity check (don’t print the value)
echo "Admin password length: $(printf %s "$ADMIN_PWD" | wc -c)"

# (Optional) Show az/bicep versions for troubleshooting
az --version | head -n 3 || true
az bicep version || true

#Create the resource group if it does not exist
az group create --name exampleRG --location eastus 
# Create the Bicep file
az deployment group validate \
  --resource-group dtmgroup \
  --template-file main.bicep \
  --parameters adminUsername='dteimuno' adminPassword="$ADMIN_PWD"

# Create
az deployment group create \
  --resource-group dtmgroup \
  --template-file main.bicep \
  --parameters adminUsername='dteimuno' adminPassword="$ADMIN_PWD" \
  --only-show-errors
