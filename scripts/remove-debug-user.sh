#!/bin/bash

set -ex

if id debug &>/dev/null; then
  echo "Removing debug user"
  userdel -r debug &>/dev/null || deluser -r debug &>/dev/null
  rm -rf /etc/sudoers.d/debug
fi
