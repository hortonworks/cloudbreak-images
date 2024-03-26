#!/bin/bash

source scripts/utils.sh

BASE_NAME=$1
STACK_VERSION=$2

SALT_VERSION=3001.8

if [[ $BASE_NAME == "cb" ]]; then
  if [[ ! -z "$STACK_VERSION" ]]; then # prewarm image
    compare_version $STACK_VERSION 7.2.6
    COMP_RESULT=$?
    # Stack version < 7.2.6 - Lowered this from 7.2.16, because we'll need Python 3.8 on older images too
    if [[ $COMP_RESULT == 2 ]]; then
      SALT_VERSION=3000.8
    fi
    compare_version $STACK_VERSION 7.2.18
    COMP_RESULT=$?
    # Stack version >= 7.2.18
    if [[ $COMP_RESULT -lt 2 ]]; then
      SALT_VERSION=3001.8 # reverted from 3006.5 until CB-21080	is fixed
    fi
  else # base image
    SALT_VERSION=3001.8 # reverted from 3006.5 until CB-21080 is fixed
  fi
fi

echo $SALT_VERSION
