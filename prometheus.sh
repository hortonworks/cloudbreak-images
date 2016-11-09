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


    curl -Lks sequenceiq.s3.amazonaws.com/process_exporter-0.2.0.tar.gz | tar -xz -C /opt/
    ln -s /opt/process_exporter-0.2.0 /opt/process_exporter
    pip install -r requirements.txt
}

main() {
    : ${INSTALL_DIR:=/usr/local/bin/}

    install_tools
    install_prometheus_exporters
    install_ssm_agent
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
