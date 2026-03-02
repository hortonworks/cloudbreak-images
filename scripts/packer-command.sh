#!/bin/bash
set -ex -o pipefail -o errexit

BUILD_ARGS="$@"

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

if [[ -n "$PACKER_GITHUB_API_TOKEN" ]]; then
  echo "PACKER_GITHUB_API_TOKEN is set."
  # Retrieve the cat: it should fail on auth error.
  # Some documentation also notes that sometimes Bearer or token prefix before the actual token is required depending on the token's type.
  # For testing purposes let's start with this.
  curl -L -H "Authorization: $PACKER_GITHUB_API_TOKEN" https://api.github.com/octocat
fi

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
