#!/bin/sh

source /home/adminuser/.profile

$JMETER_HOME/bin/jmeter-server -Dserver.rmi.localport=50000 -Dserver_port=1099 -Dserver.rmi.ssl.disable=true