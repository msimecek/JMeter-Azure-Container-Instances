#!/bin/bash

# Load config
source ./00_configure.sh

DOWNLOAD_TO=results/capacity-results.csv

echo "Downloading test results..."
az storage file download --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_ACCOUNT_KEY --share-name $STORAGE_SHARE_NAME --dest $DOWNLOAD_TO --path results/$RESULTS_FILE_NAME