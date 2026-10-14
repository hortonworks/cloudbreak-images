#!/bin/bash

# Installs the Cloudera root CA certificate - provided via the CLOUDERA_ROOT_CA
# environment variable - into the RHEL system trust store. This ensures that
# package mirrors, repositories and services secured by this CA are trusted on
# the burned image.
#
# The build silently skips the installation when CLOUDERA_ROOT_CA is not set, so
# local/dev builds without the secret keep working.
#
# The certificate content is deliberately never echoed or traced: a public root
# CA is not a secret, but certificate-shaped blobs can trip secret scanners.

set -e -o pipefail
set +x

ANCHOR_DIR="/etc/pki/ca-trust/source/anchors"
CERT_PATH="${ANCHOR_DIR}/cloudera-root-ca.crt"

if [[ -z "${CLOUDERA_ROOT_CA//[[:space:]]/}" ]]; then
  echo "CLOUDERA_ROOT_CA is not set, skipping Cloudera root CA installation."
  exit 0
fi

echo "Installing Cloudera root CA into the system trust store..."
mkdir -p "${ANCHOR_DIR}"
printf '%s\n' "${CLOUDERA_ROOT_CA}" > "${CERT_PATH}"
chmod 644 "${CERT_PATH}"
update-ca-trust extract
echo "Cloudera root CA installed and system trust store updated."
