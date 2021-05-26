#!/bin/bash -ux
#
# Copyright (C) 2021 Cloudera, Inc.
#

if [[ "$#" -lt 8 || "$#" -gt 9 ]]; then
  echo "Wrong number of arguments passed. The script requires 7 arguments to be passed for 'BACKEND_ID', 'BACKEND_HOST', 'BACKEND_PORT', 'AGENT_KEY_PATH', 'AGENT_CERT_PATH', 'TRUSTED_BACKEND_CERT_PATH', 'TRUSTED_PROXY_CERT_PATH' and 'INVERTING_PROXY_URL'."
  echo "An optional 9th argument for 'HTTP_PROXY_URL' can be passed. If not passed, no proxy will be used."
  
  exit 1
fi

BACKEND_ID=$1
BACKEND_HOST=$2
BACKEND_PORT=$3
AGENT_KEY_PATH=$4
AGENT_CERT_PATH=$5
TRUSTED_BACKEND_CERT_PATH=$6
TRUSTED_PROXY_CERT_PATH=$7
INVERTING_PROXY_URL=$8

HTTP_PROXY_URL=${9:-""}

CONFIG_FILE=/etc/jumpgate/config.toml

cat > ${CONFIG_FILE} <<EOF
[agent]

relayServer = "${INVERTING_PROXY_URL}"
relayServerCertificate = """$(cat $TRUSTED_PROXY_CERT_PATH)"""

backendId = "${BACKEND_ID}"

clientAuthenticationCertificate = """$(cat $AGENT_CERT_PATH)"""
clientAuthenticationKey = """$(cat $AGENT_KEY_PATH)"""

http_proxy = "${HTTP_PROXY_URL}"

scheme = "https"
host = "${BACKEND_HOST}:${BACKEND_PORT}"
trustedBackendCertificatePath = "${TRUSTED_BACKEND_CERT_PATH}"
EOF

if [ -f "$CONFIG_FILE" ]; then
    chmod 640 ${CONFIG_FILE}
fi

systemctl restart jumpgate-agent.service
