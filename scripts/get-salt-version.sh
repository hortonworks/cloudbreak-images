#!/bin/bash

source scripts/utils.sh

BASE_NAME=$1
STACK_VERSION=$2

SALT_VERSION=3001.8

# Runtime or Base images
if [[ $BASE_NAME == "cb" ]]; then
  # Runtime images
  if [[ ! -z "$STACK_VERSION" ]]; then
    compare_version $STACK_VERSION 7.3.1
    COMP_RESULT=$?
    # Runtime version >= 7.3.1
    if [[ $COMP_RESULT -lt 2 ]]; then
      SALT_VERSION=3006.10
    fi
  # Base images
  else
    SALT_VERSION=3006.10
  fi
# FreeIPA images - TODO: we need to test this!
else
    SALT_VERSION=3006.10
fi

echo $SALT_VERSION
