#!/bin/bash -ux
#
# Copyright (C) 2021 Cloudera, Inc.
#

if [[ "$#" -lt 10 || "$#" -gt 11 ]]; then
  echo "Wrong number of arguments passed. The script requires 10 arguments to be passed for 'BACKEND_ID', 'BACKEND_HOST', 'BACKEND_PORT', 'AGENT_KEY_PATH', 'AGENT_CERT_PATH', 'ENVIRONMENT_CRN', 'ACCESS_KEY_PATH', 'TRUSTED_BACKEND_CERT_PATH', 'TRUSTED_PROXY_CERT_PATH' and 'INVERTING_PROXY_URL'."
  echo "An optional 11th argument for 'HTTP_PROXY_URL' can be passed. If not passed, no proxy will be used."

  exit 1
fi

BACKEND_ID=$1
BACKEND_HOST=$2
BACKEND_PORT=$3
AGENT_KEY_PATH=$4
AGENT_CERT_PATH=$5
ENVIRONMENT_CRN=$6
ACCESS_KEY_PATH=$7
TRUSTED_BACKEND_CERT_PATH=$8
TRUSTED_PROXY_CERT_PATH=${9}
INVERTING_PROXY_URL=${10}

HTTP_PROXY_URL=${11:-""}

CONFIG_FILE=/etc/jumpgate/config.toml
LOG_FILE=/var/log/jumpgate/out.log

cat > ${CONFIG_FILE} <<EOF
[agent]

relayServer = "${INVERTING_PROXY_URL}"
relayServerCertificate = """$(cat $TRUSTED_PROXY_CERT_PATH)"""

backendId = "${BACKEND_ID}"

clientAuthenticationCertificate = """$(cat $AGENT_CERT_PATH)"""
clientAuthenticationKey = """$(cat $AGENT_KEY_PATH)"""

environmentCrn = "${ENVIRONMENT_CRN}"
accessKeyId = "$(grep '^CCM_V2_AGENT_ACCESS_KEY_ID=' $ACCESS_KEY_PATH | cut -d'=' -f2)"
accessKey = """$(grep '^ACCESS_KEY=' $ACCESS_KEY_PATH | cut -d'=' -f2 | base64 --decode)"""

http_proxy = "${HTTP_PROXY_URL}"

scheme = "https"
host = "${BACKEND_HOST}:${BACKEND_PORT}"
trustedBackendCertificatePath = "${TRUSTED_BACKEND_CERT_PATH}"

cdpEndpoint = "${CDP_API_ENDPOINT_URL:=}"
EOF

if [ -f "$CONFIG_FILE" ]; then
    chmod 640 ${CONFIG_FILE}
    chown jumpgate:jumpgate ${CONFIG_FILE}
fi

touch ${LOG_FILE}
chown jumpgate:jumpgate ${LOG_FILE}

systemctl restart jumpgate-agent.service
