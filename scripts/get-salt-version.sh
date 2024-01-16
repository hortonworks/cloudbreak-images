#!/bin/bash

compare_version () {
  if [[ $1 == $2 ]]; then
    return 0
  fi
  local IFS=.
  local i version1=($1) version2=($2)
  # Fill empty fields in version1 with zeros
  for ((i=${#version1[@]}; i<${#version2[@]}; i++))
  do
    version1[i]=0
  done
  for ((i=0; i<${#version1[@]}; i++))
  do
    # Fill empty fields in version2 with zeros
    if [[ -z ${version2[i]} ]]; then
      version2[i]=0
    fi
    if ((10#${version1[i]} > 10#${version2[i]})); then
      return 1
    fi
    if ((10#${version1[i]} < 10#${version2[i]})); then
      return 2
    fi
  done
  return 0
}

BASE_NAME=$1
STACK_VERSION=$2
CLOUD_PROVIDER=$3

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
      SALT_VERSION=3006.4
    fi
  else # base image
    if [[ ! $CLOUD_PROVIDER == "YARN" ]]; then
      SALT_VERSION=3006.4
    fi
  fi
fi

echo $SALT_VERSION
