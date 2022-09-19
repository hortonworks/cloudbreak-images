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

SALT_VERSION=3001.8

if [[ $BASE_NAME == "cb" ]]; then
  if [[ ! -z "$STACK_VERSION" ]]; then
    compare_version $STACK_VERSION 7.2.15
    COMP_RESULT=$?
    # Stack version < 7.2.15 (Lowered this temporarily from 7.2.16!)
    if [[ $COMP_RESULT == 2 ]]; then
      SALT_VERSION=3000.8
    fi
  # Missing STACK_VERSION and BASE_NAME=cb -> base image
  else
    SALT_VERSION=3000.8
  fi
fi

echo $SALT_VERSION


