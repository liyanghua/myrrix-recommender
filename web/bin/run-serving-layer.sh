#!/bin/bash
# Copyright Myrrix Ltd. Licensed under the Apache License, Version 2.0.
# See http://myrrix.com/legal

# This is a utility script which may be set with appropriate values, to avoid re-typing them every time
# on the command line. It illustrates usage as well.

# Set to the location of the input working dir
LOCAL_INPUT_DIR=/tmp

# Set to the port to listen for HTTP requests. This or SECURE_PORT must be set.
PORT=8080

# Set to listen for HTTPS connections on the given port. This or PORT must be set.
#SECURE_PORT=8443

# Non-default context path under which to deploy endpoint URIs
#CONTEXT_PATH=/foo/bar

#READ_ONLY=true

# Set the keystore file to enable SSL / HTTPS, and supply the password if needed.
#KEYSTORE_FILE=/path/to/keystore
#KEYSTORE_PASSWORD=password

# Set these values if the Serving Layer requires a username and password to access
#USERNAME=username
#PASSWORD=password
#CONSOLE_ONLY_PASSWORD=true

# Set to the name of a RescorerProvider if applicable, and the location of a JAR with the class
#RESCORER=org.example.foo.RescorerProvider
#RESCORER_JAR=/path/to/jar

# Set to the name of a ClientThread that should run in the server, if applicable, and the 
# location of a JAR with the class
#CLIENT_THREAD=org.example.foo.ClientRunnableCloseable
#CLIENT_THREAD_JAR=/path/to/jar

# Set any other args here
#OTHER_ARGS=

# Set any system properties here
#SYS_PROPS=-Dfoo=bar

# -------- Distributed-mode settings

# Set these to the instance and bucket from which to read a model
#INSTANCE_ID=myinstance
#BUCKET=mybucket

# When using multiple partitioned Serving Layers, set ALL_PARTITIONS describing all Serving Layers,
# and specify which partition this is with PARTITION
#PARTITION=1
#ALL_PARTITIONS=foo:80,foo2:8080;bar:8080;baz2:80,baz3:80

# Set this to the location of your license file ([subject].lic); only needed in distributed mode
#LICENSE_FILE=/path/to/license

# -------- JVM settings

# Set to a value that can be used with the -Xmx flag, like 1200m or 4G or 4g
HEAP_SIZE=2g

# -------- Apache Hadoop-specific settings

# If using an Apache Hadoop cluster, set HADOOP_CONF_DIR here (if it is not already set in the environment)
# HADOOP_HOME also works.
#export HADOOP_CONF_DIR=/path/to/hadoop/conf

# -------- Amazon EMR settings

# Set your AWS access key and secret key here
#AWS_ACCESS_KEY=...
#AWS_SECRET_KEY=...

# ----- Nothing to set below here -------

ALL_ARGS="--localInputDir=${LOCAL_INPUT_DIR}"

if [ -n "${PORT}" ]; then
  ALL_ARGS="${ALL_ARGS} --port=${PORT}"
fi
if [ -n "${SECURE_PORT}" ]; then
  ALL_ARGS="${ALL_ARGS} --securePort=${SECURE_PORT}"
fi

if [ -n "${CONTEXT_PATH}" ]; then
  ALL_ARGS="${ALL_ARGS} --contextPath=${CONTEXT_PATH}"
fi

if [ -n "${READ_ONLY}" ]; then
  ALL_ARGS="${ALL_ARGS} --readOnly"
fi

if [ -n "${KEYSTORE_FILE}" ]; then
  ALL_ARGS="${ALL_ARGS} --keystoreFile=${KEYSTORE_FILE} --keystorePassword=${KEYSTORE_PASSWORD}"
fi

if [ -n "${USERNAME}" ]; then
  ALL_ARGS="${ALL_ARGS} --userName=${USERNAME}"
fi
if [ -n "${PASSWORD}" ]; then
  ALL_ARGS="${ALL_ARGS} --password=${PASSWORD}"
fi
if [ -n "${CONSOLE_ONLY_PASSWORD}" ]; then
  ALL_ARGS="${ALL_ARGS} --consoleOnlyPassword"
fi

if [ -n "${RESCORER}" ]; then
  ALL_ARGS="${ALL_ARGS} --rescorerProviderClass=${RESCORER}"
fi
if [ -n "${CLIENT_THREAD}" ]; then
  ALL_ARGS="${ALL_ARGS} --clientThreadClass=${CLIENT_THREAD}"
fi

ADDITIONAL_CLASSPATH="";
if [ -n "${RESCORER_JAR}" ]; then
  ADDITIONAL_CLASSPATH="${ADDITIONAL_CLASSPATH}:${RESCORER_JAR}"
fi
if [ -n "${CLIENT_THREAD_JAR}" ]; then
  ADDITIONAL_CLASSPATH="${ADDITIONAL_CLASSPATH}:${CLIENT_THREAD_JAR}"
fi


if [ -n "${INSTANCE_ID}" ]; then
  ALL_ARGS="${ALL_ARGS} --instanceID=${INSTANCE_ID}"
fi

if [ -n "${BUCKET}" ]; then
  ALL_ARGS="${ALL_ARGS} --bucket=${BUCKET}"
fi

if [ -n "${PARTITION}" ]; then
  ALL_ARGS="${ALL_ARGS} --partition=${PARTITION}"
fi

if [ -n "${ALL_PARTITIONS}" ]; then
  ALL_ARGS="${ALL_ARGS} --allPartitions=${ALL_PARTITIONS}"
fi

if [ -n "${LICENSE_FILE}" ]; then
  ALL_ARGS="${ALL_ARGS} --licenseFile=${LICENSE_FILE}"
fi

if [ -n "${OTHER_ARGS}" ]; then
  ALL_ARGS="${ALL_ARGS} ${OTHER_ARGS}"
fi

ALL_SYS_PROPS="";
if [ -n "${AWS_ACCESS_KEY}" ]; then
  ALL_SYS_PROPS="${ALL_SYS_PROPS} -Dstore.aws.accessKey=${AWS_ACCESS_KEY} -Dstore.aws.secretKey=${AWS_SECRET_KEY}"
fi
if [ -n "${SYS_PROPS}" ]; then
  ALL_SYS_PROPS="${ALL_SYS_PROPS} ${SYS_PROPS}"
fi


SERVING_JAR=`ls myrrix-serving-*.jar`

java ${ALL_SYS_PROPS} -Xmx${HEAP_SIZE} -XX:NewRatio=12 -XX:+UseParallelGC -XX:+UseParallelOldGC\
 -cp ${SERVING_JAR}${ADDITIONAL_CLASSPATH} net.myrrix.web.Runner ${ALL_ARGS} $@