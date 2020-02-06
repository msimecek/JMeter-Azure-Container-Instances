#!/bin/bash

# Load config
source ./00_configure.sh

echo "Stopping test..."
az container exec -g $RESOURCE_GROUP -n $MASTER_NAME --exec-command "stoptest.sh"