#!/bin/sh

JMETER_VERSION=5.2.1

apt-get update && \
   apt-get install -qy \
      openjdk-8-jre \
      wget \
      iputils-ping

mkdir /jmeter && \
   cd /jmeter && \
   wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \
   tar -xzf apache-jmeter-${JMETER_VERSION}.tgz && \
   rm apache-jmeter-${JMETER_VERSION}.tgz

export JMETER_HOME=/jmeter/apache-jmeter-${JMETER_VERSION}/
#export PATH=$JMETER_HOME/bin:$PATH

echo "export JMETER_HOME=/jmeter/apache-jmeter-${JMETER_VERSION}" >> ~/.profile
echo "PATH=$JMETER_HOME/bin:$PATH" >> ~/.profile

#COPY user.properties $JMETER_HOME/bin