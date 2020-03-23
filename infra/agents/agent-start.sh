#!/bin/sh

source /home/adminuser/.profile

/jmeter/apache-jmeter-5.2.1/bin/jmeter-server -Dserver.rmi.localport=50000 -Dserver_port=1099 -Dserver.rmi.ssl.disable=true