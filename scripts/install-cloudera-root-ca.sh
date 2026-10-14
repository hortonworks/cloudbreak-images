#!/bin/bash

# Installs the Cloudera root CA certificate - provided via the CLOUDERA_ROOT_CA
# environment variable - into the RHEL system trust store. This ensures that
# package mirrors, repositories and services secured by this CA are trusted on
# the burned image.
#
# The build silently skips the installation when CLOUDERA_ROOT_CA is not set, so
# local/dev builds without the secret keep working.

set -e -o pipefail

: ${DEBUG:=1}
if [[ "${DEBUG}" == "1" ]]; then
  set -x
fi

ANCHOR_DIR="/etc/pki/ca-trust/source/anchors"
CERT_PATH="${ANCHOR_DIR}/cloudera-root-ca.crt"

# Bail out early (and successfully) when no certificate was provided.
if [[ -z "$(printf '%s' "${CLOUDERA_ROOT_CA}" | tr -d '[:space:]')" ]]; then
  echo "CLOUDERA_ROOT_CA is not set, skipping Cloudera root CA installation."
  exit 0
fi

# Normalise the certificate content: this converts a single-line value that uses
# literal '\n' escapes into a real multi-line PEM, while leaving an already
# multi-line PEM unchanged (PEM content contains no backslash escapes).
CERT_CONTENT="$(printf '%b' "${CLOUDERA_ROOT_CA}")"

echo "Installing Cloudera root CA into the system trust store..."

mkdir -p "${ANCHOR_DIR}"
printf '%s\n' "${CERT_CONTENT}" > "${CERT_PATH}"
chmod 644 "${CERT_PATH}"
update-ca-trust extract

echo "Cloudera root CA installed and system trust store updated."
