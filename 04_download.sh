#!/bin/bash

# Load config
source ./00_configure.sh

RESULTS_FILE=capacity-test-results.csv

echo "Downloading test results..."
az storage file download --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_ACCOUNT_KEY --share-name $STORAGE_SHARE_NAME --dest $RESULTS_FILE --path results/$RESULTS_FILE
