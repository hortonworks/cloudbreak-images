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