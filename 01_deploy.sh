#!/bin/bash

# Load config
source ./00_configure.sh

# Helper function to flatten IP list
function join_by { local IFS="$1"; shift; echo "$*"; }

# Create agents in VNET
for ((i = 1; i <= $AGENT_COUNT; i++))
do
   # background worker version - faster, but IPs need to be captured afterwards
   echo "Starting agent $i (asynchronously)..."
   az container create \
      -g $RESOURCE_GROUP \
      -n "${AGENT_BASE_NAME}${i}" \
      --cpu 4 \
      --memory 4 \
      --image $AGENT_IMAGE \
      --restart-policy never \
      --vnet $VNET \
      --subnet $SUBNET \
      --ports 1099 50000 \
      --registry-username $REGISTRY_USERNAME \
      --registry-password $REGISTRY_PASSWORD \
      --query "ipAddress.ip" \
      -o tsv &
done
wait
echo "Agents created."

# Get agents' IPs
ips=$(az container list -g ${RESOURCE_GROUP} --query "[?contains(name, '${AGENT_BASE_NAME}') && ipAddress.ip != "None"].{ip:ipAddress.ip}" -o tsv)
agent_ips=$(join_by , ${ips[*]})
echo "Agent IPs: $agent_ips"

# Create master with storage attached and agent IPs
echo "Creating master..."
az container create \
 -g $RESOURCE_GROUP \
 -n $MASTER_NAME \
 --cpu 4 \
 --memory 8 \
 --image $MASTER_IMAGE \
 --command-line "tail -f /dev/null" \
 --restart-policy never \
 --vnet $VNET \
 --subnet $SUBNET \
 --ports 60000 \
 --registry-username $REGISTRY_USERNAME \
 --registry-password $REGISTRY_PASSWORD \
 --azure-file-volume-account-name $STORAGE_ACCOUNT_NAME \
 --azure-file-volume-account-key $STORAGE_ACCOUNT_KEY \
 --azure-file-volume-share-name $STORAGE_SHARE_NAME \
 --azure-file-volume-mount-path $STORAGE_MOUNT_PATH \
 --environment-variables AGENT_IPS=$agent_ips TARGET_SYSTEM=$TARGET_SYSTEM \
 -o table

echo "Master created."