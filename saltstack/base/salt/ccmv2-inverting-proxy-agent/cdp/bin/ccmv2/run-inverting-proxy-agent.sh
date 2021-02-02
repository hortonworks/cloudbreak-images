#!/bin/bash -ux
#
# Copyright (C) 2020 Cloudera, Inc.
#

SCRIPT=`basename "$0"`
BACKEND_ID=$1
LOG_PATH="/var/log/ccmv2-inverting-proxy-agent.log"

. /cdp/bin/ccmv2/inverting-proxy-agent-values-${BACKEND_ID}.sh

exec /cdp/bin/ccmv2/inverting-proxy-agent -scheme ${SCHEME} -proxy ${INVERTING_PROXY_URL} -host ${BACKEND_ADDRESS} -backend ${BACKEND_ID} -disable-gce-vm-header=true -trusted-proxy-cert-path ${TRUSTED_PROXY_CERT_PATH} -trusted-backend-cert-path ${TRUSTED_BACKEND_CERT_PATH} -cert-path ${AGENT_CERT_PATH} -key-path ${AGENT_KEY_PATH} -http-proxy-url=${HTTP_PROXY_URL} > "$LOG_PATH" 2>&1
