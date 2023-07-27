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

echo $TAGS > /tmp/tags.json

chmod 644 /tmp/tags.json