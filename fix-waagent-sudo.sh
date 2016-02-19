#!/bin/bash
set -xe

if [ -e /etc/sudoers.d/waagent ]; then
  chmod +w /etc/sudoers.d/waagent
  sed -i.bak 's/=.*/= (ALL) NOPASSWD: ALL/' /etc/sudoers.d/waagent
  chmod -w /etc/sudoers.d/waagent
fi

