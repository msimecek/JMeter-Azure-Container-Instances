#!/bin/bash

# Global constants
# No need to run this file separately - it's included in the other scripts.

RESOURCE_GROUP=
VNET=
SUBNET=default
AGENT_BASE_NAME=loadagent
MASTER_NAME=loadmaster

REGISTRY_USERNAME=
REGISTRY_PASSWORD=
AGENT_IMAGE=
MASTER_IMAGE=

STORAGE_ACCOUNT_NAME=
STORAGE_ACCOUNT_KEY=
STORAGE_SHARE_NAME=
STORAGE_MOUNT_PATH=/load-test # don't change - so far it's hardcoded later

AGENT_COUNT=5
TARGET_SYSTEM=

TEST_FILE=./definitions/sample.jmx

echo "Configuration loaded."