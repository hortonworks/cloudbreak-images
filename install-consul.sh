#!/bin/bash
set -eo pipefail
if [[ "$TRACE" ]]; then
    : ${START_TIME:=$(date +%s)}
    export START_TIME
    export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '
    set -x
fi

: ${DEBUG:=1}

echo "Installing dependencies..."
yum -y install curl

echo "Fetching Consul..."
cd /tmp
curl -s -L -o consul.zip https://releases.hashicorp.com/consul/0.7.1/consul_0.7.1_linux_amd64.zip

echo "Installing Consul..."
unzip consul.zip >/dev/null
sudo chmod +x consul
sudo mv consul /usr/local/bin/consul
sudo mkdir -p /etc/consul.d
sudo mkdir -p /opt/consul
sudo mkdir -p /etc/service
