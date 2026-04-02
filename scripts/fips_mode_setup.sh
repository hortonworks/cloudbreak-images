#!/bin/bash

echo "FIPS mode setup"

if [ "${FIPS_MODE}" == "true" ]; then
    echo "Set FIPS enabled and then reboot..."
    fips-mode-setup --enable
    reboot
fi