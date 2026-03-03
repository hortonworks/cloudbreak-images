#!/bin/bash
set -ex -o pipefail -o errexit

BUILD_ARGS="$@"

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

if [ "$(version "$PACKER_VERSION")" -ge "$(version "1.10.0")" ]; then
  # from v1.10.0 Packer is not bundled with plugins
  if [ "$CLOUD_PROVIDER" == "AWS" ] || [ "$CLOUD_PROVIDER" == "AWS_GOV" ]; then
    PLUGIN="github.com/hashicorp/amazon"
  elif [ "$CLOUD_PROVIDER" == "Azure" ]; then
    PLUGIN="github.com/hashicorp/azure"
  elif [ "$CLOUD_PROVIDER" == "GCP" ]; then
    PLUGIN="github.com/hashicorp/googlecompute"
  fi

  if [ -n "$PLUGIN" ]; then
    packer plugins install $PLUGIN
  fi
fi

packer $BUILD_ARGS
