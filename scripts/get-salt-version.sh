#!/bin/bash

source scripts/utils.sh

BASE_NAME=$1
STACK_VERSION=$2

SALT_VERSION=3006.10

if [[ $BASE_NAME == "cb" ]]; then
  if [[ ! -z "$STACK_VERSION" ]]; then # prewarm image
    compare_version $STACK_VERSION 7.2.18
    COMP_RESULT=$?
    # Stack version >= 7.2.18
    if [[ $COMP_RESULT -lt 2 ]]; then
      SALT_VERSION=3006.10
    fi
  else # base image
    SALT_VERSION=3006.10
  fi
fi

echo $SALT_VERSION
