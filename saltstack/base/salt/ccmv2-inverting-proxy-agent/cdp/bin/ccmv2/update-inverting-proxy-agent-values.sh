#!/bin/bash -ux
#
# Copyright (C) 2020 Cloudera, Inc.
#

ARG_ERR=0

if [[ "$#" -lt 7 || "$#" -gt 10 ]]; then
  echo "Wrong number of arguments passed. The script requires 7 arguments to be passed for 'BACKEND_ID', 'BACKEND_HOST', 'BACKEND_PORT', 'AGENT_KEY_PATH', 'AGENT_CERT_PATH', 'TRUSTED_BACKEND_CERT_PATH' AND 'TRUSTED_PROXY_CERT_PATH'."
  echo "An optional 8th argument for 'INVERTING_PROXY_URL' can be passed. If not passed, the environment variable INVERTING_PROXY_URL will be used."
  echo "An optional 9th argument for 'HTTP_PROXY_URL' can be passed. If not passed, no proxy will be used."
  echo "An optional 10th argument for 'SCHEME' can be passed. If not passed, the value 'https' will be used."
  ARG_ERR=1
fi

INVERTING_PROXY_URL=${8:-$INVERTING_PROXY_URL}

if [ -z "$INVERTING_PROXY_URL" ]; then
  echo "Required variable 'INVERTING_PROXY_URL' is not set to a value. The script will exit now."
  ARG_ERR=1
fi

HTTP_PROXY_URL=${9:-""}

SCHEME=${10:-https}

if [ $ARG_ERR -eq 1 ] ; then
  exit 1
fi

BACKEND_ID=$1
BACKEND_HOST=$2
BACKEND_PORT=$3
AGENT_KEY_PATH=$4
AGENT_CERT_PATH=$5
TRUSTED_BACKEND_CERT_PATH=$6
TRUSTED_PROXY_CERT_PATH=$7

CONFIG_FILE=/cdp/bin/ccmv2/config.toml

cat > ${CONFIG_FILE} <<EOF
[agent]
proxy = "${INVERTING_PROXY_URL}"
backendID = "${BACKEND_ID}"
certificatePath = "${AGENT_CERT_PATH}"
keyPath = "${AGENT_KEY_PATH}"
trustedServerCertificatePath = "${TRUSTED_PROXY_CERT_PATH}"
scheme = "${SCHEME}"
host = "${BACKEND_HOST}:${BACKEND_PORT}"
trustedBackendCertificatePath = "${TRUSTED_BACKEND_CERT_PATH}"
httpProxyURL = "${HTTP_PROXY_URL}"
EOF

if [ -f "$CONFIG_FILE" ]; then
    chmod 640 ${CONFIG_FILE}
fi

systemctl enable ccmv2-inverting-proxy-agent.service
systemctl restart ccmv2-inverting-proxy-agent.service
