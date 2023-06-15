#!/bin/bash

set -ex

if [[ -n $TAGS ]]; then
    echo $TAGS > /tmp/tags.json

    chmod 744 /tmp/tags.json
fi