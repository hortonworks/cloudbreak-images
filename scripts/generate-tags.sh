#!/bin/bash

set -ex

if [[ -z "$TAGS" ]]; then
    TAGS="{}"
fi

if [[ "$OS" == "redhat8" ]]; then
    FIPSMODE=enabled
    fips-mode-setup --is-enabled || FIPSMODE=disabled

    TAGS=$(echo $TAGS | jq --arg fipsmode $FIPSMODE -r '. + {"fips-mode": $fipsmode}')
fi

if [ -f /log/hardening ]; then
    HARDENING=$(cat /log/hardening)
    TAGS=$(echo $TAGS | jq -r --arg hardening "$HARDENING" '. + {"hardening": $hardening}')
fi

echo $TAGS > /tmp/tags.json

chmod 644 /tmp/tags.json