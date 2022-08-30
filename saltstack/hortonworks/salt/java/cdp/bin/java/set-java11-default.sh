#!/bin/bash
#
# Copyright (C) 2022 Cloudera, Inc.
#

set -ex

alternatives --set java java-11-openjdk.x86_64
ln -sfn /etc/alternatives/java_sdk_11 /usr/lib/jvm/java
mkdir -p /etc/alternatives/java_sdk_11/jre/lib/security
ln -sfn /etc/alternatives/java_sdk_11/conf/security/java.security /etc/alternatives/java_sdk_11/jre/lib/security/java.security
ln -sfn /etc/pki/java/cacerts /etc/alternatives/java_sdk_11/jre/lib/security/cacerts
