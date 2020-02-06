#!/bin/bash

# Load config
source ./00_configure.sh

echo "Uploading test definition to share..."
az storage file upload --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_ACCOUNT_KEY --share-name $STORAGE_SHARE_NAME --source $TEST_FILE

echo "Uploading test runner to share..."
az storage file upload --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_ACCOUNT_KEY --share-name $STORAGE_SHARE_NAME --source ./test.sh

echo "Executing test..."
az container exec -g $RESOURCE_GROUP -n $MASTER_NAME --exec-command "/load-test/test.sh"