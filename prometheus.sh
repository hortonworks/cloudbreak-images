#!/bin/bash

: ${HDP_VERSION:=}

set -eo pipefail
if [[ "$TRACE" ]]; then
    : ${START_TIME:=$(date +%s)}
    export START_TIME
    export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '
    set -x
fi

: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

install_tools() {
    yum -y install curl
}

install_ssm_agent() {
    cd /tmp
    curl https://amazon-ssm-eu-west-1.s3.amazonaws.com/latest/linux_amd64/amazon-ssm-agent.rpm -o amazon-ssm-agent.rpm
    yum install -y amazon-ssm-agent.rpm
}

install_prometheus_exporters() {
    curl -Lks https://github.com/prometheus/node_exporter/releases/download/0.12.0/node_exporter-0.12.0.linux-amd64.tar.gz | tar --strip-components=1 -xz -C ${INSTALL_DIR}
    curl -Lks https://github.com/deathowl/spot_expiry_collector/releases/download/1.0.1/spot_expiry_collector-1.0.1.linux-amd64.tar.gz | tar  --strip-components=1 -xz -C ${INSTALL_DIR}
    curl -s -o /opt/process_exporter-0.2.1.tar.gz  sequenceiq.s3.amazonaws.com/process_exporter-0.2.1.tar.gz
    pip install -q /opt/process_exporter-0.2.1.tar.gz
    curl -s -o /opt/jmx_http_server.rpm http://hcube-infra.s3.amazonaws.com/rpm/jmx_exporter/jmx_prometheus_httpserver-0.7-SNAPSHOT.noarch.rpm
    yum install -y /opt/jmx_http_server.rpm
}

main() {
    : ${INSTALL_DIR:=/usr/local/bin/}

    install_tools
    install_prometheus_exporters
    install_ssm_agent
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
