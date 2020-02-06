#!/bin/bash

# Load config
source ./00_configure.sh


echo "Deleting master..."
az container delete -g $RESOURCE_GROUP -n $MASTER_NAME -y

for ((i = 1; i <= $AGENT_COUNT; i++))
do
   echo "Deleting agent $i..."
   az container delete -g $RESOURCE_GROUP -n ${AGENT_BASE_NAME}${i} -y
done

echo "All done."