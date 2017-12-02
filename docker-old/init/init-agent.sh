#!/bin/bash

: ${CLOUD_PLATFORM:="none"}
: ${USE_CONSUL_DNS:="false"}
AMBARI_SERVER_ADDR=$(cat /tmp/ambari_server_hostname)
PUBLIC_HOSTNAME=$(cat /tmp/public_hostname)

echo "nameserver 10.42.1.20" > /etc/resolv.conf
echo "nameserver 10.10.1.20" >> /etc/resolv.conf

[[ "TRACE" ]] && set -x

debug() {
  [[ "DEBUG" ]]  && echo "[DEBUG] $@" 1>&2
}

ambari_server_addr() {
  sed -i "s/^hostname=.*/hostname=${AMBARI_SERVER_ADDR}/" /etc/ambari-agent/conf/ambari-agent.ini
}

set_public_hostname() {
  echo $PUBLIC_HOSTNAME > /etc/public_hostname.conf
}

main() {
  sleep 60 # wait for DNS entries to be created
  ambari_server_addr
  set_public_hostname
}

main
