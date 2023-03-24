#!/bin/bash

echo "FIPS mode setup"

if [ "${OS}" == "redhat8" ] && [ "${CLOUD_PROVIDER}" == "AWS_GOV" ] ; then
    echo "Set FIPS enabled and then reboot..."
    fips-mode-setup --enable
    reboot
fi