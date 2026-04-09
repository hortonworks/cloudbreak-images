#!/bin/bash

# This standard reboot command causes problems with RHEL 9 ARM64 images and right now, not sure why...
echo "Rebooting before validation and cleanup"
if [[ "${OS}" != "redhat9" || "${ARCHITECTURE}" != "arm64" ]] ; then
  reboot
else
  sudo systemctl reboot --force
fi
