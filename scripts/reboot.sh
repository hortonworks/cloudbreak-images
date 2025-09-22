#!/bin/bash

# This reboot causes problems with RHEL 9 ARM64 images and right now, not sure why...
# We need to see if we need it at all. For now, it is disabled for this combo, but further testing is required.
if [[ "${OS}" != "redhat9" && "${ARCHITECTURE}" != "arm64" ]] ; then
  echo "Rebooting before validation and cleanup"
  reboot
fi
