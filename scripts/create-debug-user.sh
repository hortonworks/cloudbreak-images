#!/bin/bash

set -ex

if [ -n "${SSH_PUBLIC_KEY}" ]; then
  echo "Creating debug user"
  adduser debug &>/dev/null || useradd debug &>/dev/null

  echo "debug ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/debug
  mkdir -p /home/debug/.ssh
  echo "${SSH_PUBLIC_KEY}" >> /home/debug/.ssh/authorized_keys
  chown -R debug /home/debug/.ssh
fi
