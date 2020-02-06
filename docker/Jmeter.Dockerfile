FROM openjdk:8-jre-slim

ARG JMETER_VERSION=5.2.1

RUN apt-get update && \
    apt-get install -qy \
        wget \
        iputils-ping

RUN mkdir /jmeter && \
    cd /jmeter && \
    wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \
    tar -xzf apache-jmeter-${JMETER_VERSION}.tgz && \
    rm apache-jmeter-${JMETER_VERSION}.tgz

ENV JMETER_HOME /jmeter/apache-jmeter-${JMETER_VERSION}/
ENV PATH $JMETER_HOME/bin:$PATH

COPY user.properties $JMETER_HOME/bin