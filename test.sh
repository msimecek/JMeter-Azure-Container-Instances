#!/bin/bash

USERS=400
DURATION=240
RAMP_UP=100

# Name of the JMX test file without path
TEST_FILE_NAME=sample.jmx
# Name of the output file without path (and as CSV)
RESULTS_FILE_NAME=sample-results.csv

# TODO: STORAGE_MOUNT_PATH is not reflected here

# ----------------------------

jmeter -n -f -t /load-test/${TEST_FILE_NAME} -l /load-test/results/${RESULTS_FILE_NAME} -R${AGENT_IPS} -Ghost=${TARGET_SYSTEM} -Gusers=${USERS} -Gduration=${DURATION} -Gramp_up=${RAMP_UP}