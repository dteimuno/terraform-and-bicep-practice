export ADMIN_PWD='Synchrony1998!'
az deployment group create \
  --resource-group dtmgroup \
  --template-file main.bicep \
  --parameters adminUsername='{"value":"dteimuno"}' adminPassword='{"value":"'"$ADMIN_PWD"'"}'
