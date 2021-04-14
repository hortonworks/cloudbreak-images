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

VALUES_FILE=/cdp/bin/ccmv2/inverting-proxy-agent-values-${BACKEND_ID}.sh

cat > ${VALUES_FILE} <<EOF
INVERTING_PROXY_URL=${INVERTING_PROXY_URL}
BACKEND_ID=${BACKEND_ID}
BACKEND_ADDRESS=${BACKEND_HOST}:${BACKEND_PORT}
AGENT_KEY_PATH=${AGENT_KEY_PATH}
AGENT_CERT_PATH=${AGENT_CERT_PATH}
TRUSTED_BACKEND_CERT_PATH=${TRUSTED_BACKEND_CERT_PATH}
TRUSTED_PROXY_CERT_PATH=${TRUSTED_PROXY_CERT_PATH}
SCHEME=${SCHEME}
HTTP_PROXY_URL=${HTTP_PROXY_URL}
EOF

if [ -f "$VALUES_FILE" ]; then
    chmod 740 ${VALUES_FILE}
fi

systemctl enable ccmv2-inverting-proxy-agent@${BACKEND_ID}.service
systemctl restart ccmv2-inverting-proxy-agent@${BACKEND_ID}.service
