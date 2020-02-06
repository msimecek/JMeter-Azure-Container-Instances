#!/bin/bash

# Load config
source ./00_configure.sh

# List containers and their IPs
az container show -g ${RESOURCE_GROUP} -n ${MASTER_NAME} -o table

az container list -g ${RESOURCE_GROUP} --query "[?contains(name, '${AGENT_BASE_NAME}')].{name: name, ip:ipAddress.ip, state: provisioningState}" -o table